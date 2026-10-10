import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/sync/outbox_sync_engine.dart';
import '../domain/models.dart';
import 'sos_success_screen.dart';

class SosSendingScreen extends StatefulWidget {
  final String incidentId;
  final IncidentModel incident;
  final OutboxSyncEngine syncEngine;

  const SosSendingScreen({
    super.key,
    required this.incidentId,
    required this.incident,
    required this.syncEngine,
  });

  @override
  State<SosSendingScreen> createState() => _SosSendingScreenState();
}

class _SosSendingScreenState extends State<SosSendingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  int _currentStep = 1; // 0: Location, 1: Nearby, 2: Server, 3: Teams

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _executeSendingSequence();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  Future<void> _executeSendingSequence() async {
    // Step 1: Location confirmed
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _currentStep = 2);

    // Step 2: Sharing with nearby devices & trigger sync
    widget.syncEngine.triggerSyncCycle();
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) setState(() => _currentStep = 3);

    // Step 3: Server reception
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _currentStep = 4);

    // Transition to SOS Sent Success Screen
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SosSuccessScreen(
          incidentId: widget.incidentId,
          incident: widget.incident,
          syncEngine: widget.syncEngine,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E17),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // Title: Sending SOS...
              Text(
                'Sending SOS...',
                style: GoogleFonts.manrope(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Your location and emergency details\nare being shared',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Tri-Nodal Transmission Radar Graphic (Matching Reference Screen 4)
              Expanded(
                flex: 5,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _radarController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(320, 260),
                        painter: _TriNodeRadarPainter(animationValue: _radarController.value),
                        child: SizedBox(
                          width: 320,
                          height: 260,
                          child: Stack(
                            children: [
                              // Top Node: Server Cloud
                              Align(
                                alignment: const Alignment(0, -0.95),
                                child: _buildSatelliteNode(
                                  icon: Icons.cloud_upload_rounded,
                                  label: 'Sending to Server\n(When available)',
                                  isActive: _currentStep >= 3,
                                  color: const Color(0xFF38BDF8),
                                ),
                              ),

                              // Bottom-Left Node: Nearby Devices Bluetooth
                              Align(
                                alignment: const Alignment(-0.95, 0.70),
                                child: _buildSatelliteNode(
                                  icon: Icons.bluetooth_rounded,
                                  label: 'Sharing with\nNearby Devices',
                                  isActive: _currentStep >= 2,
                                  color: const Color(0xFF2563EB),
                                ),
                              ),

                              // Bottom-Right Node: Wi-Fi
                              Align(
                                alignment: const Alignment(0.95, 0.70),
                                child: _buildSatelliteNode(
                                  icon: Icons.wifi_rounded,
                                  label: 'Using Wi-Fi\n(If available)',
                                  isActive: _currentStep >= 2,
                                  color: const Color(0xFF10B981),
                                ),
                              ),

                              // Center Node: SOS Beacon
                              Align(
                                alignment: const Alignment(0, 0.15),
                                child: Container(
                                  width: 66,
                                  height: 66,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const RadialGradient(
                                      colors: [
                                        Color(0xFFFF3B4E),
                                        Color(0xFFB30D1E),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF2A3C).withValues(alpha: 0.6),
                                        blurRadius: 24,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'SOS',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Step Checklist Card (Matching Reference Screen 4)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF141824),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF21283B), width: 1.2),
                ),
                child: Column(
                  children: [
                    _buildChecklistRow(
                      label: 'Getting your location...',
                      isDone: _currentStep >= 1,
                      isLoading: _currentStep == 0,
                    ),
                    const SizedBox(height: 14),
                    _buildChecklistRow(
                      label: 'Sharing with nearby devices...',
                      isDone: _currentStep >= 2,
                      isLoading: _currentStep == 1,
                    ),
                    const SizedBox(height: 14),
                    _buildChecklistRow(
                      label: 'Sending to server...',
                      isDone: _currentStep >= 3,
                      isLoading: _currentStep == 2,
                    ),
                    const SizedBox(height: 14),
                    _buildChecklistRow(
                      label: 'Notifying rescue teams...',
                      isDone: _currentStep >= 4,
                      isLoading: _currentStep == 3,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSatelliteNode({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF141824),
            border: Border.all(
              color: isActive ? color : const Color(0xFF2A344A),
              width: 1.8,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Icon(icon, color: isActive ? color : const Color(0xFF64748B), size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF94A3B8),
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistRow({
    required String label,
    required bool isDone,
    required bool isLoading,
  }) {
    return Row(
      children: [
        if (isDone)
          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20)
        else if (isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: Color(0xFF38BDF8),
            ),
          )
        else
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF475569), width: 1.8),
            ),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDone ? Colors.white : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ],
    );
  }
}

class _TriNodeRadarPainter extends CustomPainter {
  final double animationValue;

  _TriNodeRadarPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final center = Offset(w * 0.5, h * 0.56);
    final top = Offset(w * 0.5, h * 0.16);
    final left = Offset(w * 0.18, h * 0.72);
    final right = Offset(w * 0.82, h * 0.72);

    final linePaint = Paint()
      ..color = const Color(0xFFFF2A3C).withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Outer subtle boundary triangle
    final path = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    canvas.drawPath(path, linePaint);

    // Radiating dashed transmission lines from center to nodes
    _drawDashedLine(canvas, center, top, const Color(0xFF38BDF8).withValues(alpha: 0.7));
    _drawDashedLine(canvas, center, left, const Color(0xFF2563EB).withValues(alpha: 0.7));
    _drawDashedLine(canvas, center, right, const Color(0xFF10B981).withValues(alpha: 0.7));

    // Concentric ambient radar pulses from center
    final pulsePaint = Paint()
      ..color = const Color(0xFFFF2A3C).withValues(alpha: (1.0 - animationValue) * 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, 40 + (animationValue * 45), pulsePaint);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0;

    final distance = (p2 - p1).distance;
    final dashLength = 5.0;
    final dashSpace = 4.0;
    final unitVector = (p2 - p1) / distance;

    double currentDistance = 0.0;
    while (currentDistance < distance) {
      final start = p1 + unitVector * currentDistance;
      final end = p1 + unitVector * (currentDistance + dashLength).clamp(0.0, distance);
      canvas.drawLine(start, end, paint);
      currentDistance += dashLength + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _TriNodeRadarPainter oldDelegate) => true;
}
