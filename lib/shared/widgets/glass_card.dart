import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/theme.dart';

enum GlassVariant { defaultSurface, secondary, strong, alert, warning, success }

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final GlassVariant variant;
  final VoidCallback? onTap;
  final Border? customBorder;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 16,
    this.variant = GlassVariant.defaultSurface,
    this.onTap,
    this.customBorder,
  });

  Color _getBackgroundColor() {
    switch (variant) {
      case GlassVariant.defaultSurface:
        return LanternColors.glassDefault;
      case GlassVariant.secondary:
        return LanternColors.glassSecondary;
      case GlassVariant.strong:
        return LanternColors.glassStrong;
      case GlassVariant.alert:
        return LanternColors.emergencyRed.withValues(alpha: 0.12);
      case GlassVariant.warning:
        return LanternColors.warningAmber.withValues(alpha: 0.12);
      case GlassVariant.success:
        return LanternColors.successGreen.withValues(alpha: 0.12);
    }
  }

  Border _getBorder() {
    if (customBorder != null) return customBorder!;

    switch (variant) {
      case GlassVariant.alert:
        return Border.all(color: LanternColors.emergencyRed.withValues(alpha: 0.35), width: 1.2);
      case GlassVariant.warning:
        return Border.all(color: LanternColors.warningAmber.withValues(alpha: 0.35), width: 1.2);
      case GlassVariant.success:
        return Border.all(color: LanternColors.successGreen.withValues(alpha: 0.35), width: 1.2);
      case GlassVariant.strong:
        return Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1);
      default:
        return Border.all(color: LanternColors.glassBorder, width: 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(borderRadius),
            border: _getBorder(),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: LanternColors.frostLavender.withValues(alpha: 0.1),
        highlightColor: Colors.white.withValues(alpha: 0.05),
        child: card,
      );
    }

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    return card;
  }
}
