import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/navigation_shell.dart';
import 'app/theme.dart';
import 'core/database/database_helper.dart';
import 'core/relay/peer_relay_service.dart';
import 'core/sync/outbox_sync_engine.dart';
import 'features/map/data/places_repository.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/onboarding/presentation/radio_setup_screen.dart';
import 'features/sos/domain/models.dart';
import 'features/splash/presentation/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline SQLite tables
  await DatabaseHelper.instance.database;

  // Pre-seed offline emergency relief places if empty
  final placesRepo = PlacesRepository();
  await placesRepo.seedDefaultPlacesIfEmpty();

  // Initialize durable outbox synchronization engine
  final syncEngine = OutboxSyncEngine();
  syncEngine.startListening(Connectivity());

  // Initialize peer relay service for direct nearby-device offline transport
  final peerRelayService = PeerRelayService(syncEngine: syncEngine);
  await peerRelayService.init();

  syncEngine.onFallbackPeerRelay = ({
    required IncidentModel incident,
    required String idempotencyKey,
  }) async {
    return await peerRelayService.relayIncidentToNearbyPeers(
      incident: incident,
      idempotencyKey: idempotencyKey,
    );
  };

  // Restore configured backend server URL if custom preference saved
  final prefs = await SharedPreferences.getInstance();
  final savedUrl = prefs.getString('lantern_server_url');
  if (savedUrl != null && savedUrl.isNotEmpty) {
    if (syncEngine.transport is LiveHttpIncidentTransport) {
      (syncEngine.transport as LiveHttpIncidentTransport).updateBaseUrl(savedUrl);
    }
  }

  syncEngine.startPeriodicSync();

  runApp(LanternApp(
    syncEngine: syncEngine,
    peerRelayService: peerRelayService,
  ));
}

class LanternApp extends StatefulWidget {
  final OutboxSyncEngine syncEngine;
  final PeerRelayService peerRelayService;

  const LanternApp({
    super.key,
    required this.syncEngine,
    required this.peerRelayService,
  });

  @override
  State<LanternApp> createState() => _LanternAppState();
}

class _LanternAppState extends State<LanternApp> {
  bool _showSplash = true;
  bool _hasSeenOnboarding = false;
  bool _showRadioSetup = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _hasSeenOnboarding = prefs.getBool('has_completed_onboarding') ?? false;
      });
    }
  }

  void _onOnboardingAdvance() {
    setState(() {
      _showRadioSetup = true;
    });
  }

  Future<void> _completeAllSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', true);
    if (mounted) {
      setState(() {
        _hasSeenOnboarding = true;
        _showRadioSetup = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget activeScreen;

    if (_showSplash) {
      activeScreen = SplashScreen(onFinish: () => setState(() => _showSplash = false));
    } else if (!_hasSeenOnboarding) {
      if (_showRadioSetup) {
        activeScreen = RadioSetupScreen(
          onSetupComplete: _completeAllSetup,
          isStandalone: false,
        );
      } else {
        activeScreen = OnboardingScreen(
          onGetStarted: _onOnboardingAdvance,
          onSkip: _onOnboardingAdvance,
        );
      }
    } else {
      activeScreen = NavigationShell(syncEngine: widget.syncEngine);
    }

    return MaterialApp(
      title: 'LANTERN',
      debugShowCheckedModeBanner: false,
      theme: LanternTheme.darkTheme,
      home: activeScreen,
    );
  }
}
