import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NearbyDevicesScreen extends StatefulWidget {
  const NearbyDevicesScreen({super.key});

  @override
  State<NearbyDevicesScreen> createState() => _NearbyDevicesScreenState();
}

class _NearbyDevicesScreenState extends State<NearbyDevicesScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E17),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nearby Devices',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Subtitle: Scanning for nearby LANTERN devices...
              Text(
                'Scanning for nearby LANTERN devices...',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 24),

              // Dynamic Radar Scanner Graphic (Matching Reference Screen 7)
              Expanded(
                flex: 4,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _scannerController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(260, 260),
                        painter: _RadarScannerPainter(angle: _scannerController.value * 2 * 3.14159),
                        child: SizedBox(
                          width: 260,
                          height: 260,
                          child: Stack(
                            children: [
                              // Center Bluetooth Badge
                              Align(
                                alignment: Alignment.center,
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF2563EB),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2563EB).withValues(alpha: 0.5),
                                        blurRadius: 18,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.bluetooth_rounded, color: Colors.white, size: 26),
                                ),
                              ),

                              // Satellite Device Nodes on Radar Rings
                              Align(
                                alignment: const Alignment(-0.80, -0.60),
                                child: _buildOrbitDevice(const Color(0xFF10B981)), // Connected Phone
                              ),
                              Align(
                                alignment: const Alignment(0.75, -0.55),
                                child: _buildOrbitDevice(const Color(0xFF38BDF8)), // Peer Phone
                              ),
                              Align(
                                alignment: const Alignment(0.0, 0.85),
                                child: _buildOrbitDevice(const Color(0xFF38BDF8)), // Peer Phone
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Discovered Peer Device Cards
              Expanded(
                flex: 5,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildDeviceCard(
                      name: 'LANTERN-User-01',
                      distance: '2 m away',
                      status: 'Connected',
                      statusColor: const Color(0xFF10B981), // Green
                      iconColor: const Color(0xFF10B981),
                    ),
                    const SizedBox(height: 12),
                    _buildDeviceCard(
                      name: 'LANTERN-User-02',
                      distance: '8 m away',
                      status: 'Available',
                      statusColor: const Color(0xFF38BDF8), // Blue
                      iconColor: const Color(0xFF38BDF8),
                    ),
                    const SizedBox(height: 12),
                    _buildDeviceCard(
                      name: 'LANTERN-User-03',
                      distance: '15 m away',
                      status: 'Available',
                      statusColor: const Color(0xFF38BDF8), // Blue
                      iconColor: const Color(0xFF38BDF8),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrbitDevice(Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF141824),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 8,
          ),
        ],
      ),
      child: Icon(Icons.phone_android_rounded, color: color, size: 16),
    );
  }

  Widget _buildDeviceCard({
    required String name,
    required String distance,
    required String status,
    required Color statusColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF141824),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF21283B), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.15),
              border: Border.all(color: iconColor.withValues(alpha: 0.3)),
            ),
            child: Icon(Icons.phone_android_rounded, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.manrope(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  distance,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              status,
              style: GoogleFonts.manrope(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarScannerPainter extends CustomPainter {
  final double angle;

  _RadarScannerPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final radius = size.width * 0.5;

    // Draw concentric radar rings
    final ringPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.18)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius * 0.35, ringPaint);
    canvas.drawCircle(center, radius * 0.65, ringPaint);
    canvas.drawCircle(center, radius * 0.95, ringPaint);

    // Crosshairs
    final linePaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.10)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(center.dx, center.dy - radius), Offset(center.dx, center.dy + radius), linePaint);
    canvas.drawLine(Offset(center.dx - radius, center.dy), Offset(center.dx + radius, center.dy), linePaint);

    // Sweeping Radar Beam (Conic Gradient)
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0.0,
        endAngle: 3.14159 * 2,
        colors: [
          const Color(0xFF00E5FF).withValues(alpha: 0.0),
          const Color(0xFF00E5FF).withValues(alpha: 0.3),
        ],
        stops: const [0.75, 1.0],
        transform: GradientRotation(angle),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.95, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarScannerPainter oldDelegate) => true;
}
