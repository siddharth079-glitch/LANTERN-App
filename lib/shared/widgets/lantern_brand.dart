import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// The official LANTERN Flame Lighthouse Emblem matching the approved reference
class LanternEmblem extends StatelessWidget {
  final double size;
  final bool glow;

  const LanternEmblem({
    super.key,
    this.size = 32,
    this.glow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: glow
            ? [
                BoxShadow(
                  color: const Color(0xFFFF4D00).withValues(alpha: 0.35),
                  blurRadius: size * 0.4,
                  spreadRadius: size * 0.05,
                ),
              ]
            : null,
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: _FlameLighthousePainter(),
      ),
    );
  }
}

class _FlameLighthousePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Draw Outer Flame Silhouette with Orange -> Crimson Gradient
    final flamePath = Path();
    flamePath.moveTo(w * 0.5, h * 0.04);
    flamePath.cubicTo(
      w * 0.72, h * 0.28,
      w * 0.95, h * 0.52,
      w * 0.92, h * 0.74,
    );
    flamePath.cubicTo(
      w * 0.88, h * 0.94,
      w * 0.68, h * 0.98,
      w * 0.5, h * 0.98,
    );
    flamePath.cubicTo(
      w * 0.32, h * 0.98,
      w * 0.12, h * 0.94,
      w * 0.08, h * 0.74,
    );
    flamePath.cubicTo(
      w * 0.05, h * 0.52,
      w * 0.28, h * 0.28,
      w * 0.5, h * 0.04,
    );
    flamePath.close();

    final flamePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFF7A00), // Vibrant amber/orange
          Color(0xFFFF2A3C), // Crimson red
          Color(0xFFB30D1E), // Deep ruby
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(flamePath, flamePaint);

    // 2. Interior Dark Window Cutout / Negative Space
    final innerPath = Path();
    innerPath.moveTo(w * 0.5, h * 0.20);
    innerPath.cubicTo(
      w * 0.68, h * 0.38,
      w * 0.82, h * 0.56,
      w * 0.78, h * 0.76,
    );
    innerPath.cubicTo(
      w * 0.74, h * 0.88,
      w * 0.62, h * 0.90,
      w * 0.5, h * 0.90,
    );
    innerPath.cubicTo(
      w * 0.38, h * 0.90,
      w * 0.26, h * 0.88,
      w * 0.22, h * 0.76,
    );
    innerPath.cubicTo(
      w * 0.18, h * 0.56,
      w * 0.32, h * 0.38,
      w * 0.5, h * 0.20,
    );
    innerPath.close();

    final innerDarkPaint = Paint()
      ..color = const Color(0xFF0D101A)
      ..style = PaintingStyle.fill;

    canvas.drawPath(innerPath, innerDarkPaint);

    // 3. Draw Lighthouse Silhouette (Creamy warm white)
    final lighthousePaint = Paint()
      ..color = const Color(0xFFFAF0E6)
      ..style = PaintingStyle.fill;

    // Beacon Dome
    final domePath = Path();
    domePath.moveTo(w * 0.44, h * 0.36);
    domePath.cubicTo(w * 0.44, h * 0.30, w * 0.56, h * 0.30, w * 0.56, h * 0.36);
    domePath.close();
    canvas.drawPath(domePath, lighthousePaint);

    // Beacon Room (Light room)
    canvas.drawRect(
      Rect.fromLTWH(w * 0.43, h * 0.36, w * 0.14, h * 0.07),
      lighthousePaint,
    );

    // Glowing warm yellow beacon center
    final lightPaint = Paint()..color = const Color(0xFFFFD54F);
    canvas.drawCircle(Offset(w * 0.5, h * 0.395), w * 0.035, lightPaint);

    // Gallery Balcony
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.39, h * 0.43, w * 0.22, h * 0.035),
        const Radius.circular(1),
      ),
      lighthousePaint,
    );

    // Tower Body (Tapered trapezoid)
    final towerPath = Path();
    towerPath.moveTo(w * 0.42, h * 0.465);
    towerPath.lineTo(w * 0.58, h * 0.465);
    towerPath.lineTo(w * 0.63, h * 0.78);
    towerPath.lineTo(w * 0.37, h * 0.78);
    towerPath.close();
    canvas.drawPath(towerPath, lighthousePaint);

    // Dark Architectural Bands / Stripes on Tower
    final stripePaint = Paint()
      ..color = const Color(0xFF0D101A)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(w * 0.40, h * 0.54, w * 0.20, h * 0.045), stripePaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.38, h * 0.66, w * 0.24, h * 0.045), stripePaint);

    // Foundation Base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.33, h * 0.78, w * 0.34, h * 0.05),
        const Radius.circular(2),
      ),
      lighthousePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LanternWordmark extends StatelessWidget {
  final double fontSize;
  final bool showEmblem;
  final double emblemSize;

  const LanternWordmark({
    super.key,
    this.fontSize = 20,
    this.showEmblem = true,
    this.emblemSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showEmblem) ...[
          LanternEmblem(size: emblemSize),
          const SizedBox(width: 8),
        ],
        Text(
          'LANTERN',
          style: LanternTheme.wordmarkStyle.copyWith(
            fontSize: fontSize,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
