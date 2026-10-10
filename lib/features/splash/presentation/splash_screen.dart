import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/lantern_brand.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const SplashScreen({super.key, required this.onFinish});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward().then((_) => widget.onFinish());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07090F),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Lighthouse Artwork (from assets)
          Positioned.fill(
            child: Image.asset(
              'assets/images/hero_lantern_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0F1424), Color(0xFF07090F)],
                  ),
                ),
              ),
            ),
          ),

          // Deep Cinematic Dark Vignette & Gradient Overlays
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.35, 0.70, 1.0],
                  colors: [
                    Color(0xEE07090F), // Top dark shade
                    Color(0x7707090F), // Transparent window showing artwork
                    Color(0xBB07090F),
                    Color(0xFF07090F), // Solid bottom for typography
                  ],
                ),
              ),
            ),
          ),

          // Content Layer matching Screen 1 Reference
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 36),

                  // 1. Glowing Flame Lighthouse Logo Emblem
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5500).withValues(alpha: 0.45),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                        BoxShadow(
                          color: LanternColors.emergencyRed.withValues(alpha: 0.3),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: LanternEmblem(size: 84, glow: true),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Bold Brand Title: LANTERN
                  Text(
                    'LANTERN',
                    style: GoogleFonts.manrope(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // 3. Subtitle Motto: LIGHTING THE WAY IN DARK TIMES
                  Text(
                    'LIGHTING THE WAY\nIN DARK TIMES',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.2,
                      color: const Color(0xFF94A3B8), // Cool slate
                      height: 1.4,
                    ),
                  ),

                  const Spacer(),

                  // 4. Bottom Taglines: Stay Safe • Stay Connected
                  Text(
                    'Stay Safe • Stay Connected',
                    style: GoogleFonts.manrope(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 5. Disaster Response for a Safer Tomorrow
                  Text(
                    'Disaster Response for a Safer Tomorrow',
                    style: GoogleFonts.manrope(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
