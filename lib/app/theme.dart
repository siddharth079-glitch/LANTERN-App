import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LanternColors {
  LanternColors._();

  // Core Brand Tokens (Matching the approved Mobile Reference)
  static const Color cosmic = Color(0xFF0B0E17); // Deep midnight canvas
  static const Color cardSurface = Color(0xFF141824); // Primary card surface
  static const Color cardSurfaceLight = Color(0xFF1B2132); // Raised card surface
  static const Color frostLavender = Color(0xFFE6E6FA); // Primary light accent

  // Emergency Crimson & SOS Tokens
  static const Color emergencyRed = Color(0xFFFF2A3C); // Vibrant red from reference
  static const Color emergencyRedDark = Color(0xFFB30D1E); // Deep red gradient stop
  static const Color emergencyRedGlow = Color(0x66FF2A3C); // Ambient outer glow
  static const Color emergencyRedHover = Color(0xFFFF4D5E);
  static const Color emergencyRedPressed = Color(0xFFCC1F30);

  // Quick Action Semantic Tiles
  static const Color actionGreen = Color(0xFF10B981); // Emergency Call
  static const Color actionBlue = Color(0xFF2563EB); // Send Message
  static const Color actionOrange = Color(0xFFF97316); // Nearby People
  static const Color actionPurple = Color(0xFF8B5CF6); // Find Shelter

  // Telemetry, Status & Radio Tokens
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color successGreen = Color(0xFF10B981);
  static const Color signalCyan = Color(0xFF00E5FF);
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryBlueHover = Color(0xFF3B82F6);
  static const Color primaryBlueDark = Color(0xFF1D4ED8);

  // Surfaces, Glass & Borders
  static const Color darkCanvas = Color(0xFF07090F);
  static const Color glassDefault = Color(0x1AFFFFFF);
  static const Color glassSecondary = Color(0x26FFFFFF);
  static const Color glassHover = Color(0x33FFFFFF);
  static const Color glassStrong = Color(0x40FFFFFF);
  static const Color glassBorder = Color(0xFF21283B); // Subtle card outline
  static const Color glassBorderHover = Color(0xFF384360);

  // Typography Tokens
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color textDisabled = Color(0xFF475569);
}

class LanternTheme {
  LanternTheme._();

  static TextStyle get wordmarkStyle => GoogleFonts.sora(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: LanternColors.textPrimary,
      );

  static TextStyle get telemetryMonoStyle => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: LanternColors.textSecondary,
      );

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: LanternColors.cosmic,
      primaryColor: LanternColors.frostLavender,
      canvasColor: LanternColors.cosmic,
      colorScheme: const ColorScheme.dark(
        primary: LanternColors.emergencyRed,
        onPrimary: Colors.white,
        surface: LanternColors.cosmic,
        onSurface: LanternColors.textPrimary,
        error: LanternColors.emergencyRed,
        onError: Colors.white,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          color: LanternColors.textPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        displayMedium: baseTextTheme.displayMedium?.copyWith(
          color: LanternColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          color: LanternColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: LanternColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          color: LanternColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: LanternColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: LanternColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: LanternColors.textPrimary,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: LanternColors.textSecondary,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: LanternColors.textMuted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
      ),
    );
  }
}
