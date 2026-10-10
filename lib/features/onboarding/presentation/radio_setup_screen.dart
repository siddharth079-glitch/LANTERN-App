import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

class RadioSetupScreen extends StatefulWidget {
  final VoidCallback onSetupComplete;
  final bool isStandalone;

  const RadioSetupScreen({
    super.key,
    required this.onSetupComplete,
    this.isStandalone = false,
  });

  @override
  State<RadioSetupScreen> createState() => _RadioSetupScreenState();
}

class _RadioSetupScreenState extends State<RadioSetupScreen> with WidgetsBindingObserver {
  bool _locGranted = false;
  bool _btGranted = false;
  bool _wifiEnabled = false;
  bool _notifGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    // 1. Location
    final locStatus = await Geolocator.checkPermission();
    final isLoc = locStatus == LocationPermission.always || locStatus == LocationPermission.whileInUse;

    // 2. Bluetooth
    final btScan = await Permission.bluetoothScan.status;
    final btConnect = await Permission.bluetoothConnect.status;
    final bt = await Permission.bluetooth.status;
    final isBt = (btScan.isGranted && btConnect.isGranted) || bt.isGranted;

    // 3. Wi-Fi / Local Networking
    final isWifi = true; // Wi-Fi interfaces active on Android

    // 4. Notifications
    final notifStatus = await Permission.notification.status;
    final isNotif = notifStatus.isGranted;

    if (mounted) {
      setState(() {
        _locGranted = isLoc;
        _btGranted = isBt;
        _wifiEnabled = isWifi;
        _notifGranted = isNotif;
      });
    }
  }

  Future<void> _requestLocation() async {
    final status = await Geolocator.requestPermission();
    if (status == LocationPermission.deniedForever) {
      openAppSettings();
    }
    _checkPermissions();
  }

  Future<void> _requestBluetooth() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.bluetooth,
    ].request();

    if (statuses.values.any((s) => s.isPermanentlyDenied)) {
      openAppSettings();
    }
    _checkPermissions();
  }

  Future<void> _requestNotifications() async {
    final status = await Permission.notification.request();
    if (status.isPermanentlyDenied) {
      openAppSettings();
    }
    _checkPermissions();
  }

  Future<void> _grantAllPermissions() async {
    await Geolocator.requestPermission();
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.bluetooth,
      Permission.notification,
    ].request();

    await _checkPermissions();
    widget.onSetupComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E17),
      appBar: widget.isStandalone
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Permissions & Radios',
                style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // Title: Let's get you ready
              Text(
                "Let's get you ready",
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'LANTERN needs a few permissions to keep you safe and connected during emergencies.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 4 Permission Cards Matching Reference
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildPermissionCard(
                      icon: Icons.location_on_rounded,
                      iconBgColor: const Color(0xFF10B981), // Green
                      title: 'Location',
                      description: 'To share your real-time location during an emergency.',
                      isGranted: _locGranted,
                      onTap: _requestLocation,
                    ),
                    const SizedBox(height: 14),

                    _buildPermissionCard(
                      icon: Icons.bluetooth_rounded,
                      iconBgColor: const Color(0xFF2563EB), // Blue
                      title: 'Bluetooth',
                      description: 'To connect with nearby devices offline.',
                      isGranted: _btGranted,
                      onTap: _requestBluetooth,
                    ),
                    const SizedBox(height: 14),

                    _buildPermissionCard(
                      icon: Icons.wifi_rounded,
                      iconBgColor: const Color(0xFF0284C7), // Cyan/Blue
                      title: 'Wi-Fi',
                      description: 'To enable local communication and share data.',
                      isGranted: _wifiEnabled,
                      onTap: () {
                        // Wi-Fi contextual informational tap
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Wi-Fi radio is active for local offline mesh transfer.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    _buildPermissionCard(
                      icon: Icons.notifications_rounded,
                      iconBgColor: const Color(0xFFF59E0B), // Amber/Yellow
                      title: 'Notifications',
                      description: 'To alert you about SOS updates and rescue messages.',
                      isGranted: _notifGranted,
                      onTap: _requestNotifications,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Grant All Permissions Button (Glossy Red Pill)
              GestureDetector(
                onTap: _grantAllPermissions,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFF3B4E), // Vibrant coral red
                        Color(0xFFE50914), // Deep crimson
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF2A3C).withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Grant All Permissions',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Skip for now Text Link
              GestureDetector(
                onTap: widget.onSetupComplete,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Text(
                    'Skip for now',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF141824), // Slate-navy card surface
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isGranted ? iconBgColor.withValues(alpha: 0.5) : const Color(0xFF222A3C),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            // Colored Square Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),

            // Title & Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: GoogleFonts.manrope(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Chevron Right in Circle
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isGranted ? iconBgColor.withValues(alpha: 0.15) : const Color(0xFF1E2536),
              ),
              child: Icon(
                isGranted ? Icons.check_rounded : Icons.chevron_right_rounded,
                color: isGranted ? iconBgColor : const Color(0xFF94A3B8),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
