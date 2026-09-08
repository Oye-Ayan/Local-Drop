import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Industrial-Standard Minimalist Design System for LocalDrop
/// Inspired by the calm, high-clarity aesthetics of Linear and Apple AirDrop.
class AppTheme {
  // Brand & Accent Colors
  static const Color primary = Color(0xFF10B981); // Emerald 500
  static const Color primaryLight = Color(0xFF34D399); // Emerald 400
  static const Color primaryDark = Color(0xFF059669); // Emerald 600
  static const Color accent = Color(0xFF38BDF8); // Sky 400
  static const Color secondary = Color(0xFF38BDF8); // Sky 400
  static const Color textInverse = Color(0xFF090A0F); // Inverse text on bright buttons

  // Matte Backgrounds & Surfaces
  static const Color bgDark = Color(0xFF090A0F); // Deep Onyx
  static const Color surfaceDark = Color(0xFF11141D); // Matte Slate
  static const Color surfaceCardDark = Color(0xFF151924); // Card Surface
  static const Color surfaceCardElevated = Color(0xFF1E2332); // Raised Card
  static const Color surfaceHover = Color(0xFF252C3E);

  // Hairline Structural Borders
  static const Color borderDark = Color(0xFF222738); // Crisp 1px border
  static const Color borderSubtle = Color(0xFF181C29); // Subtle inner divider
  static const Color borderHover = Color(0xFF333B54);

  // Status Colors
  static const Color statusOnline = Color(0xFF10B981);
  static const Color statusBusy = Color(0xFFF59E0B);
  static const Color statusError = Color(0xFFEF4444);

  // Typography Palette
  static const Color textPrimary = Color(0xFFF8FAFC); // Crisp Off-White
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted = Color(0xFF64748B); // Slate 500

  // Soft Minimalist Shadows
  static List<BoxShadow> get microShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get cardElevation => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];

  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;
    final interTextTheme = GoogleFonts.interTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: primary,
      textTheme: interTextTheme.copyWith(
        headlineMedium: interTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: textPrimary,
        ),
        titleLarge: interTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: textPrimary,
        ),
        titleMedium: interTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: textPrimary,
        ),
        bodyLarge: interTextTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: interTextTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: const Color(0xFF090A0F),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderDark),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
