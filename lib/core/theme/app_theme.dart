import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';



/// Unified Modern Aesthetic Design System for LocalDrop
/// Dominant Background (60%): Midnight Blue-Gray (#0F172A) & Dark Charcoal Slate (#1E293B).
/// Structural Text & Cards (30%): Crisp Off-White (#F8FAFC) & Slate Gray (#94A3B8 / #64748B).
/// Accent & Interactive (10%): Electric Teal (#14B8A6 / #0D9488), Alert Coral (#F43F5E), Glowing Amber (#F59E0B).
class AppTheme {
  // Electric Teal (#14B8A6) & Confidence Teal (#0D9488) (10%)
  static const Color primary = Color(0xFF14B8A6); // Electric Teal
  static const Color primaryLight = Color(0xFF2DD4BF); // Teal 400
  static const Color primaryDark = Color(0xFF0D9488); // Confidence Teal
  static const Color primaryGlow = Color(0x3314B8A6); // 20% glow
  static const Color secondary = Color(0xFF0D9488); // Confidence Teal
  static const Color secondaryLight = Color(0xFF5EEAD4);
  static const Color accent = Color(0xFF14B8A6);

  // Dominant Background (60%)
  static const Color bgDark = Color(0xFF0F172A); // Midnight Blue-Gray
  static const Color surfaceDark = Color(0xFF1E293B); // Dark Charcoal Slate
  static const Color surfaceCardDark = Color(0xFF1E293B); // Card surface
  static const Color surfaceCardElevated = Color(0xFF334155); // Slate 700 raised
  static const Color surfaceHover = Color(0xFF283548);

  // Crisp 1px Subtle Borders
  static const Color borderDark = Color(0x2694A3B8); // 15% Slate border
  static const Color borderSubtle = Color(0x1494A3B8); // 8% Slate border
  static const Color borderHover = Color(0x4D14B8A6); // Teal hover border

  // Status & Telemetry
  static const Color statusOnline = Color(0xFF14B8A6); // Electric Teal online dot
  static const Color statusBusy = Color(0xFFF59E0B); // Glowing Amber
  static const Color statusError = Color(0xFFF43F5E); // Alert Coral

  // Structural Text & Cards (30%)
  static const Color textPrimary = Color(0xFFF8FAFC); // Crisp Off-White
  static const Color textSubheading = Color(0xFFE2E8F0); // Slate 200
  static const Color textSecondary = Color(0xFF94A3B8); // Slate Gray
  static const Color textMuted = Color(0xFF64748B); // Muted Cool Gray
  static const Color textInverse = Color(0xFF0F172A); // Midnight text on teal

  // Subtle clean gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF2DD4BF), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Soft 4px micro-shadows
  static List<BoxShadow> get microShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.35),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get cardElevation => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.45),
      blurRadius: 16,
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
          letterSpacing: -0.1,
          color: textPrimary,
        ),
        bodyMedium: interTextTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        labelLarge: interTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
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
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderDark, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.3,
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
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderDark, width: 1),
          backgroundColor: surfaceDark,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: borderSubtle, thickness: 1),
    );
  }
}
