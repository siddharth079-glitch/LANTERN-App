import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/glossy_button.dart';
import '../../../shared/widgets/lantern_brand.dart';

class OnboardingScreen extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onSkip;

  const OnboardingScreen({
    super.key,
    required this.onGetStarted,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LanternColors.cosmic,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background graphic
          Positioned.fill(
            child: Opacity(
              opacity: 0.28,
              child: Image.asset(
                'assets/images/hero_lantern_bg.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF1E1B2E), Color(0xFF0F0E16)],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Gradient overlay for readability
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xD9161420),
                  Colors.transparent,
                  Color(0xF0161420),
                  Color(0xFF161420),
                ],
                stops: [0.0, 0.35, 0.75, 1.0],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const LanternWordmark(fontSize: 20, emblemSize: 26),
                      TextButton(
                        onPressed: onSkip,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: LanternColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Headline
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.15,
                        letterSpacing: -0.5,
                      ),
                      children: const [
                        TextSpan(text: 'Stay Safe\nStay Connected\n'),
                        TextSpan(
                          text: 'Always.',
                          style: TextStyle(color: LanternColors.emergencyRed),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Subtitle
                  Text(
                    'Request help, get real-time updates and access essential information during disasters.',
                    style: TextStyle(
                      color: LanternColors.textSecondary,
                      fontSize: 14.5,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // CTA Button
                  GlossyButton(
                    label: 'Get Started',
                    variant: GlossyButtonVariant.blue,
                    fullWidth: true,
                    height: 52,
                    icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    onPressed: onGetStarted,
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
