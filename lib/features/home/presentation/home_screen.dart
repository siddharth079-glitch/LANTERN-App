import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/location/location_service.dart';
import '../../../core/sync/outbox_sync_engine.dart';
import '../../../shared/widgets/lantern_brand.dart';
import '../../contacts/presentation/emergency_contacts_screen.dart';
import '../../shelters/presentation/nearby_shelters_screen.dart';
import '../../sos/domain/models.dart';
import '../../sos/presentation/sos_sending_screen.dart';
import '../../../shared/widgets/status_chip.dart';

class HomeScreen extends StatefulWidget {
  final OutboxSyncEngine syncEngine;
  final Function(int) onNavigateTab;

  const HomeScreen({
    super.key,
    required this.syncEngine,
    required this.onNavigateTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  late AnimationController _pulseController;
  bool _isTriggeringSos = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _triggerEmergencySos() async {
    if (_isTriggeringSos) return;
    setState(() => _isTriggeringSos = true);

    try {
      final locResult = await _locationService.getCurrentLocation();
      final nowUtc = DateTime.now().toUtc();
      final incidentId = 'SOS-${const Uuid().v4()}';
      final idempotencyKey = incidentId;

      final incident = IncidentModel(
        incidentId: incidentId,
        category: IncidentCategory.other,
        createdAtUtc: nowUtc,
        latitude: locResult.status == LocationStatus.success ? locResult.data?.latitude : 17.4389,
        longitude: locResult.status == LocationStatus.success ? locResult.data?.longitude : 78.3912,
        locationAccuracyM: locResult.data?.accuracy ?? 10.0,
        peopleAffected: 1,
        description: 'Distress beacon activated from Home Screen.',
        localState: IncidentDeliveryState.queuedLocal,
      );

      final outbox = OutboxRecord(
        outboxId: const Uuid().v4(),
        incidentId: incidentId,
        payloadVersion: 1,
        idempotencyKey: idempotencyKey,
        state: 'queued',
        attemptCount: 0,
      );

      final initialEvent = IncidentEventRecord(
        eventId: 'EVT-${nowUtc.millisecondsSinceEpoch}',
        incidentId: incidentId,
        eventType: 'SAVED_LOCAL_FIRST',
        occurredAtUtc: nowUtc,
        source: 'HOME_SOS_BUTTON',
        verified: true,
        safeSummary: 'Immediate SOS beacon activated by citizen from Home Screen.',
      );

      await DatabaseHelper.instance.createIncidentTransactional(
        incident: incident,
        outbox: outbox,
        initialEvent: initialEvent,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SosSendingScreen(
            incidentId: incidentId,
            incident: incident,
            syncEngine: widget.syncEngine,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isTriggeringSos = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E17),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Top Header Bar Matching Reference Screen 3
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Profile Avatar
                  GestureDetector(
                    onTap: () => widget.onNavigateTab(4), // Profile Tab
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF141824),
                        border: Border.all(color: const Color(0xFF263045), width: 1.2),
                      ),
                      child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 22),
                    ),
                  ),

                  // Center LANTERN Wordmark + Ready to help
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const LanternEmblem(size: 20, glow: false),
                          const SizedBox(width: 6),
                          Text(
                            'LANTERN',
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF10B981), // Green ready dot
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Ready to help',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Notification Bell with Red Indicator
                  GestureDetector(
                    onTap: () => widget.onNavigateTab(2), // Alerts Tab
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF141824),
                        border: Border.all(color: const Color(0xFF263045), width: 1.2),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                          Positioned(
                            top: 9,
                            right: 9,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFF2A3C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 2. Alert Banner: "You are not alone / Help is just one tap away"
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1318), // Deep warm tinted card
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF45181E), width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFDC2626), // Alert red badge
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You are not alone',
                            style: GoogleFonts.manrope(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Help is just one tap away',
                            style: GoogleFonts.manrope(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFFCA5A5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 3. Huge Central 3D Convex Glossy Red SOS Button (Matching Screen 3 Reference)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Concentric Ambient Pulse Rings
                      Container(
                        width: 270,
                        height: 270,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFF2A3C).withValues(
                              alpha: 0.15 + (_pulseController.value * 0.10),
                            ),
                            width: 1.5,
                          ),
                        ),
                      ),
                      Container(
                        width: 245,
                        height: 245,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFF2A3C).withValues(
                              alpha: 0.30 + (_pulseController.value * 0.15),
                            ),
                            width: 2.0,
                          ),
                        ),
                      ),

                      // Outer Crimson Ambient Halo
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF2A3C).withValues(alpha: 0.40),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),

                      // Central 3D Convex Glossy Red Sphere
                      GestureDetector(
                        onTap: _triggerEmergencySos,
                        onLongPress: _triggerEmergencySos,
                        child: Container(
                          width: 210,
                          height: 210,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              center: Alignment(-0.2, -0.3),
                              radius: 0.9,
                              colors: [
                                Color(0xFFFF5264), // Bright top specular highlight
                                Color(0xFFFF2A3C), // Vibrant crimson body
                                Color(0xFFD00018), // Rich ruby core
                                Color(0xFF880010), // Deep bottom shade
                              ],
                              stops: [0.0, 0.45, 0.80, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: const Color(0xFFFF5264).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(-2, -3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Radio Broadcast Beacon Icon ((•))
                              const Icon(
                                Icons.podcasts_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                              const SizedBox(height: 2),

                              // SOS Text
                              Text(
                                'SOS',
                                style: GoogleFonts.manrope(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              // Subtitle: Tap and hold to send SOS
              RichText(
                text: TextSpan(
                  style: GoogleFonts.manrope(
                    fontSize: 13.5,
                    color: const Color(0xFF94A3B8),
                  ),
                  children: const [
                    TextSpan(text: 'Tap and '),
                    TextSpan(
                      text: 'hold',
                      style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    TextSpan(text: ' to send SOS'),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // 4. Quick Action Tiles Row (Matching Reference Screen 3)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickActionTile(
                    icon: Icons.phone_rounded,
                    iconBgColor: const Color(0xFF10B981), // Green
                    label: 'Emergency\nCall',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()),
                      );
                    },
                  ),
                  _buildQuickActionTile(
                    icon: Icons.chat_bubble_rounded,
                    iconBgColor: const Color(0xFF2563EB), // Blue
                    label: 'Send\nMessage',
                    onTap: () => widget.onNavigateTab(2), // Alerts/Messages tab
                  ),
                  _buildQuickActionTile(
                    icon: Icons.people_alt_rounded,
                    iconBgColor: const Color(0xFFF97316), // Orange
                    label: 'Nearby\nPeople',
                    onTap: () => widget.onNavigateTab(3), // Community tab
                  ),
                  _buildQuickActionTile(
                    icon: Icons.holiday_village_rounded,
                    iconBgColor: const Color(0xFF8B5CF6), // Purple
                    label: 'Find\nShelter',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NearbySheltersScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required Color iconBgColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF141824), // Slate-navy card surface
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF21283B), width: 1.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBgColor,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF94A3B8),
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
