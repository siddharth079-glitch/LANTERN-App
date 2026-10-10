import 'package:flutter/material.dart';
import '../../app/theme.dart';

enum GlossyButtonVariant { primary, secondary, emergency, blue, emergencyOutline }

class GlossyButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final GlossyButtonVariant variant;
  final bool isLoading;
  final double height;
  final double? width;
  final bool fullWidth;

  const GlossyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = GlossyButtonVariant.primary,
    this.isLoading = false,
    this.height = 48,
    this.width,
    this.fullWidth = false,
  });

  @override
  State<GlossyButton> createState() => _GlossyButtonState();
}

class _GlossyButtonState extends State<GlossyButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;

    Color bg;
    Color textColor;
    Border? border;
    List<BoxShadow> shadows = [];

    switch (widget.variant) {
      case GlossyButtonVariant.primary:
        bg = enabled
            ? (_isPressed ? Colors.white.withValues(alpha: 0.9) : LanternColors.frostLavender)
            : LanternColors.frostLavender.withValues(alpha: 0.3);
        textColor = LanternColors.cosmic;
        border = Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1);
        if (enabled) {
          shadows = [
            BoxShadow(
              color: LanternColors.frostLavender.withValues(alpha: 0.28),
              blurRadius: _isPressed ? 10 : 18,
              offset: const Offset(0, 3),
            ),
          ];
        }
        break;

      case GlossyButtonVariant.secondary:
        bg = enabled
            ? (_isPressed ? LanternColors.glassHover : LanternColors.glassDefault)
            : LanternColors.glassDefault.withValues(alpha: 0.4);
        textColor = enabled ? LanternColors.textPrimary : LanternColors.textDisabled;
        border = Border.all(
          color: _isPressed ? LanternColors.glassBorderHover : LanternColors.glassBorder,
          width: 1,
        );
        break;

      case GlossyButtonVariant.emergency:
        bg = enabled
            ? (_isPressed ? LanternColors.emergencyRedPressed : LanternColors.emergencyRed)
            : LanternColors.emergencyRed.withValues(alpha: 0.35);
        textColor = Colors.white;
        border = Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.2);
        if (enabled) {
          shadows = [
            BoxShadow(
              color: LanternColors.emergencyRed.withValues(alpha: 0.4),
              blurRadius: _isPressed ? 12 : 24,
              offset: const Offset(0, 4),
            ),
          ];
        }
        break;

      case GlossyButtonVariant.blue:
        bg = enabled
            ? (_isPressed ? LanternColors.primaryBlueDark : LanternColors.primaryBlue)
            : LanternColors.primaryBlue.withValues(alpha: 0.35);
        textColor = Colors.white;
        border = Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1);
        if (enabled) {
          shadows = [
            BoxShadow(
              color: LanternColors.primaryBlue.withValues(alpha: 0.4),
              blurRadius: _isPressed ? 10 : 20,
              offset: const Offset(0, 4),
            ),
          ];
        }
        break;

      case GlossyButtonVariant.emergencyOutline:
        bg = enabled
            ? (_isPressed ? LanternColors.emergencyRed.withValues(alpha: 0.2) : Colors.transparent)
            : Colors.transparent;
        textColor = LanternColors.emergencyRed;
        border = Border.all(color: LanternColors.emergencyRed, width: 1.5);
        if (enabled && _isPressed) {
          shadows = [
            BoxShadow(
              color: LanternColors.emergencyRed.withValues(alpha: 0.25),
              blurRadius: 10,
            ),
          ];
        }
        break;
    }

    Widget content = Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (widget.icon != null) ...[
          widget.icon!,
          const SizedBox(width: 8),
        ],
        Text(
          widget.label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );

    Widget btn = GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
      onTap: enabled ? widget.onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        height: widget.height,
        width: widget.fullWidth ? double.infinity : widget.width,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(9999), // Pill shape per specification
          border: border,
          boxShadow: shadows,
          gradient: widget.variant == GlossyButtonVariant.emergency
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.22),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.18),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                )
              : null,
        ),
        alignment: Alignment.center,
        child: content,
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: btn,
    );
  }
}

class TacticalSOSButton extends StatefulWidget {
  final VoidCallback onTrigger;
  final bool isSending;

  const TacticalSOSButton({
    super.key,
    required this.onTrigger,
    this.isSending = false,
  });

  @override
  State<TacticalSOSButton> createState() => _TacticalSOSButtonState();
}

class _TacticalSOSButtonState extends State<TacticalSOSButton> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isDown = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.88, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 192.0;

    return Semantics(
      button: true,
      label: 'Emergency SOS Distress Beacon. Tap to request help.',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isDown = true),
        onTapUp: (_) {
          setState(() => _isDown = false);
          widget.onTrigger();
        },
        onTapCancel: () => setState(() => _isDown = false),
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final scale = _isDown ? 0.94 : _pulseAnimation.value;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: size + 36,
                height: size + 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    // Atmospheric ambient red glow
                    BoxShadow(
                      color: LanternColors.emergencyRed.withValues(alpha: 0.35),
                      blurRadius: 44,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outermost frosted halo ring
                    Container(
                      width: size + 28,
                      height: size + 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.03),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1.5,
                        ),
                      ),
                    ),
                    // Second concentric tactical ring
                    Container(
                      width: size + 8,
                      height: size + 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: LanternColors.emergencyRed.withValues(alpha: 0.08),
                        border: Border.all(
                          color: LanternColors.emergencyRed.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                    ),
                    // Glossy 3D Button Core
                    Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-0.25, -0.35),
                          radius: 0.85,
                          colors: [
                            const Color(0xFFFF6B6B),
                            LanternColors.emergencyRed,
                            const Color(0xFFD32F2F),
                            const Color(0xFF8B0000),
                          ],
                          stops: const [0.0, 0.35, 0.75, 1.0],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.45),
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: LanternColors.emergencyRed.withValues(alpha: 0.5),
                            blurRadius: 26,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.isSending) ...[
                            const SizedBox(
                              width: 36,
                              height: 36,
                              child: CircularProgressIndicator(
                                strokeWidth: 3.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'TRANSMITTING...',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.warning_rounded,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'SOS',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 32,
                                letterSpacing: 2.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tap to Request Help',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w500,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
