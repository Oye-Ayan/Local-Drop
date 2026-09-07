import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ethereal Obsidian Design System for LocalDrop
class AppTheme {
  // Ethereal Obsidian & Kinetic Cyan Palette
  static const Color primary = Color(0xFF00E5FF); // Electric Cyan
  static const Color primaryLight = Color(0xFF38EFFF); // Cyan glow
  static const Color secondary = Color(0xFF6366F1); // Royal Indigo
  static const Color secondaryLight = Color(0xFF818CF8);
  static const Color accent = Color(0xFFA855F7); // Purple accent

  // Deep Obsidian Surfaces
  static const Color bgDark = Color(0xFF07090E); // Deepest OLED black
  static const Color surfaceDark = Color(0xFF0E131F); // Machine container
  static const Color surfaceCardDark = Color(0xFF131B2B); // Nested core
  static const Color surfaceCardElevated = Color(0xFF1A2337);
  static const Color borderDark = Color(0xFF222E42); // Distinct outer hairline
  static const Color borderSubtle = Color(0xFF161E2E); // Inner hairline

  // Status & Haptic Accents
  static const Color statusOnline = Color(0xFF10B981); // Emerald pulse
  static const Color statusBusy = Color(0xFFF59E0B); // Amber warning
  static const Color statusError = Color(0xFFEF4444); // Crimson error

  // Typography Semantic Colors
  static const Color textPrimary = Colors.white;
  static const Color textSubheading = Color(0xFFCBD5E1); // Slate 300
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color textInverse = Color(0xFF04101A); // Dark on primary

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF0072FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;
    final jakartaTextTheme = GoogleFonts.plusJakartaSansTextTheme(
      baseTextTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: primary,
      textTheme: jakartaTextTheme.copyWith(
        headlineMedium: jakartaTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
          color: textPrimary,
        ),
        titleLarge: jakartaTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: textPrimary,
        ),
        titleMedium: jakartaTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: textPrimary,
        ),
        bodyLarge: jakartaTextTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: jakartaTextTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        labelLarge: jakartaTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surfaceDark,
        error: statusError,
        onPrimary: textInverse,
        onSecondary: textPrimary,
        onSurface: textPrimary,
      ),
      cardTheme: CardThemeData(
        color: surfaceCardDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderDark, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -0.4,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textInverse,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderDark, width: 1.2),
          backgroundColor: surfaceDark.withValues(alpha: 0.8),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: borderSubtle, thickness: 1),
    );
  }
}
