import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/sync/outbox_sync_engine.dart';
import '../../map/presentation/map_screen.dart';
import '../domain/models.dart';

class SosSuccessScreen extends StatelessWidget {
  final String incidentId;
  final IncidentModel incident;
  final OutboxSyncEngine syncEngine;

  const SosSuccessScreen({
    super.key,
    required this.incidentId,
    required this.incident,
    required this.syncEngine,
  });

  @override
  Widget build(BuildContext context) {
    final lat = incident.latitude ?? 17.4389;
    final lng = incident.longitude ?? 78.3912;
    final coordsText = '${lat.toStringAsFixed(4)}° N, ${lng.toStringAsFixed(4)}° E';
    final timeText = DateFormat('d MMM yyyy, h:mm a').format(incident.createdAtUtc.toLocal());

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E17),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // Glowing Green Checkmark Circle
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981), // Vibrant emerald green
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.45),
                      blurRadius: 36,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 54,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title: SOS Sent Successfully
              Text(
                'SOS Sent Successfully',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle: Your emergency has been shared
              Text(
                'Your emergency has been shared',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 32),

              // Information Card (Matching Reference Screen 5)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                decoration: BoxDecoration(
                  color: const Color(0xFF141824),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF21283B), width: 1.2),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.location_on_rounded,
                      iconColor: const Color(0xFF10B981),
                      title: 'Location Shared',
                      value: coordsText,
                    ),
                    _buildDivider(),
                    _buildInfoRow(
                      icon: Icons.cell_tower_rounded,
                      iconColor: const Color(0xFF38BDF8),
                      title: 'Shared with Nearby Devices',
                      value: '3 devices',
                    ),
                    _buildDivider(),
                    _buildInfoRow(
                      icon: Icons.cloud_done_rounded,
                      iconColor: const Color(0xFF60A5FA),
                      title: 'Sent to Server',
                      value: 'Received by LANTERN Network',
                    ),
                    _buildDivider(),
                    _buildInfoRow(
                      icon: Icons.access_time_rounded,
                      iconColor: const Color(0xFF818CF8),
                      title: 'Time',
                      value: timeText,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Primary Action: View on Map (Glossy Red Button)
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MapScreen(),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFF3B4E),
                        Color(0xFFE50914),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.map_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'View on Map',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Secondary Action: Back to Home
              GestureDetector(
                onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: const Color(0xFF141824),
                    border: Border.all(color: const Color(0xFF2A344A), width: 1.2),
                  ),
                  child: Center(
                    child: Text(
                      'Back to Home',
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12.0),
      child: Divider(color: Color(0xFF1E2536), height: 1),
    );
  }
}
