import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static bool isDark = false;

  // Google Material 3 Calm Color Palette (Responsive getters)
  static Color get bgColor => isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
  static Color get cardColor => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  static Color get borderColor => isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E4EC);
  static Color get textColorPrimary => isDark ? const Color(0xFFE3E3E3) : const Color(0xFF202124);
  static Color get textColorSecondary => isDark ? const Color(0xFF9AA0A6) : const Color(0xFF5F6368);

  // Google Brand Accents
  static const Color primaryBlue = Color(0xFF0B57D0);  // M3 Google Blue
  static const Color accentGreen = Color(0xFF137333);  // Calm M3 Green
  static const Color accentYellow = Color(0xFFB06000); // Calm M3 Amber
  static const Color accentRed = Color(0xFFC5221F);    // Calm M3 Red
  static const Color accentTeal = Color(0xFF00796B);   // M3 Teal

  // Soft Card Shadows (Material 3 style)
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  // Subject Calm Pastel Palettes
  static Color subjectBgColor(String code) {
    switch (code) {
      case 'ADA':
        return const Color(0xFFE8F0FE); // Soft Blue tint
      case 'OS':
        return const Color(0xFFFEF7E0); // Soft Amber tint
      case 'SE':
        return const Color(0xFFE6F4EA); // Soft Green tint
      case 'LAO':
        return const Color(0xFFF3E8FF); // Soft Purple tint
      case 'CRP':
        return const Color(0xFFE0F2F1); // Soft Teal tint
      case 'TFC':
        return const Color(0xFFFCE8E6); // Soft Red tint
      case 'MAD':
        return const Color(0xFFE0F7FA); // Soft Cyan tint
      case 'NPTEL':
        return const Color(0xFFF1F3F4); // Soft Gray tint
      default:
        return const Color(0xFFF1F3F4);
    }
  }

  static Color subjectTextColor(String code) {
    switch (code) {
      case 'ADA':
        return const Color(0xFF1A73E8);
      case 'OS':
        return const Color(0xFFB06000);
      case 'SE':
        return const Color(0xFF137333);
      case 'LAO':
        return const Color(0xFF681DA8);
      case 'CRP':
        return const Color(0xFF00796B);
      case 'TFC':
        return const Color(0xFFC5221F);
      case 'MAD':
        return const Color(0xFF006064);
      case 'NPTEL':
        return const Color(0xFF3C4043);
      default:
        return textColorPrimary;
    }
  }

  static IconData subjectIcon(String code) {
    switch (code) {
      case 'ADA':
        return Icons.analytics_outlined;
      case 'OS':
        return Icons.developer_board;
      case 'SE':
        return Icons.auto_awesome_mosaic_outlined;
      case 'LAO':
        return Icons.calculate_outlined;
      case 'CRP':
        return Icons.verified_user_outlined;
      case 'TFC':
        return Icons.device_hub_outlined;
      case 'MAD':
        return Icons.smartphone_outlined;
      case 'NPTEL':
        return Icons.school_outlined;
      default:
        return Icons.book_outlined;
    }
  }

  // Google Sans/Lexend styled theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: bgColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        background: bgColor,
        surface: cardColor,
      ),
      textTheme: GoogleFonts.lexendTextTheme().copyWith(
        displayLarge: GoogleFonts.lexend(
          color: textColorPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: -1.0,
        ),
        headlineLarge: GoogleFonts.lexend(
          color: textColorPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.lexend(
          color: textColorPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.lexend(
          color: textColorPrimary,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: GoogleFonts.lexend(
          color: textColorSecondary,
          fontWeight: FontWeight.normal,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryBlue,
        inactiveTrackColor: primaryBlue.withOpacity(0.12),
        thumbColor: primaryBlue,
        overlayColor: primaryBlue.withOpacity(0.12),
        trackHeight: 4,
        valueIndicatorTextStyle: GoogleFonts.lexend(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.dark,
        background: const Color(0xFF121212),
        surface: const Color(0xFF1E1E1E),
      ),
      textTheme: GoogleFonts.lexendTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.lexend(
          color: const Color(0xFFE3E3E3),
          fontWeight: FontWeight.bold,
          letterSpacing: -1.0,
        ),
        headlineLarge: GoogleFonts.lexend(
          color: const Color(0xFFE3E3E3),
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.lexend(
          color: const Color(0xFFE3E3E3),
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.lexend(
          color: const Color(0xFFE3E3E3),
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: GoogleFonts.lexend(
          color: const Color(0xFF9AA0A6),
          fontWeight: FontWeight.normal,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryBlue,
        inactiveTrackColor: primaryBlue.withOpacity(0.24),
        thumbColor: primaryBlue,
        overlayColor: primaryBlue.withOpacity(0.24),
        trackHeight: 4,
        valueIndicatorTextStyle: GoogleFonts.lexend(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
