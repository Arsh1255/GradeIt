import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
  static int _stringToHash(String s) {
    int hash = 0;
    for (int i = 0; i < s.length; i++) {
      hash = s.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return hash;
  }

  static final List<String> _presetCodes = ['ADA', 'OS', 'SE', 'LAO', 'CRP', 'TFC', 'MAD', 'NPTEL'];

  static String _resolveCode(String code, [String? name]) {
    final cleaned = code.trim().toUpperCase();
    if (_presetCodes.contains(cleaned)) return cleaned;

    // Keyword-based preset resolution from subject name
    final lowerName = (name ?? '').toLowerCase();
    if (lowerName.contains('algorithm') || lowerName.contains('design') || lowerName.contains('analysis')) return 'ADA';
    if (lowerName.contains('operat') || lowerName.contains('unix') || lowerName.contains('linux') || lowerName.contains('network')) return 'OS';
    if (lowerName.contains('softw') || lowerName.contains('engineer') || lowerName.contains('test')) return 'SE';
    if (lowerName.contains('math') || lowerName.contains('calculus') || lowerName.contains('algebra') || lowerName.contains('linear') || lowerName.contains('statist')) return 'LAO';
    if (lowerName.contains('constitution') || lowerName.contains('law') || lowerName.contains('cyber') || lowerName.contains('security') || lowerName.contains('ethic')) return 'CRP';
    if (lowerName.contains('physic') || lowerName.contains('chem') || lowerName.contains('scien') || lowerName.contains('bio')) return 'TFC';
    if (lowerName.contains('web') || lowerName.contains('app') || lowerName.contains('mobil') || lowerName.contains('android') || lowerName.contains('flutter')) return 'MAD';
    if (lowerName.contains('english') || lowerName.contains('kannada') || lowerName.contains('hindi') || lowerName.contains('french') || lowerName.contains('language')) return 'NPTEL';
    if (lowerName.contains('program') || lowerName.contains('code') || lowerName.contains('java') || lowerName.contains('python') || lowerName.contains('data struct')) return 'ADA';
    if (lowerName.contains('databas') || lowerName.contains('dbms') || lowerName.contains('sql')) return 'SE';
    if (lowerName.contains('finan') || lowerName.contains('econ') || lowerName.contains('busin') || lowerName.contains('manag') || lowerName.contains('account')) return 'OS';

    if (cleaned.isEmpty) return 'NPTEL';
    final index = _stringToHash(cleaned).abs() % 7;
    return _presetCodes[index];
  }

  // Subject Calm Pastel Palettes
  static Color subjectBgColor(String code, [String? name]) {
    final resolved = _resolveCode(code, name);
    if (isDark) {
      return subjectTextColor(resolved).withOpacity(0.15);
    }
    switch (resolved) {
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

  static Color subjectTextColor(String code, [String? name]) {
    final resolved = _resolveCode(code, name);
    if (isDark) {
      switch (resolved) {
        case 'ADA':
          return const Color(0xFF8AB4F8); // Dark Blue
        case 'OS':
          return const Color(0xFFFDD663); // Dark Amber
        case 'SE':
          return const Color(0xFF81C995); // Dark Green
        case 'LAO':
          return const Color(0xFFD7AEFB); // Dark Purple
        case 'CRP':
          return const Color(0xFF80CBC4); // Dark Teal
        case 'TFC':
          return const Color(0xFFF28B82); // Dark Red
        case 'MAD':
          return const Color(0xFF24B6F7); // Dark Cyan
        case 'NPTEL':
          return const Color(0xFFDADCE0); // Dark Gray
        default:
          return textColorPrimary;
      }
    } else {
      switch (resolved) {
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
  }
  static IconData subjectIcon(String code, [String? name]) {
    final lowerName = (name ?? '').toLowerCase();
    final lowerCode = code.toLowerCase();

    // 1. Languages / Communication
    if (lowerName.contains('english') ||
        lowerName.contains('kannada') ||
        lowerName.contains('hindi') ||
        lowerName.contains('sanskrit') ||
        lowerName.contains('french') ||
        lowerName.contains('lang') ||
        lowerName.contains('comm') ||
        lowerCode.contains('eng') ||
        lowerCode.contains('kan')) {
      return LucideIcons.languages;
    }

    // 2. Math / Calculations
    if (lowerName.contains('math') ||
        lowerName.contains('calculus') ||
        lowerName.contains('algebra') ||
        lowerName.contains('statist') ||
        lowerName.contains('probab') ||
        lowerName.contains('linear') ||
        lowerCode.contains('lao') ||
        lowerCode.contains('mat')) {
      return LucideIcons.sigma;
    }

    // 3. Physics (atom/photon)
    if (lowerName.contains('physic') ||
        lowerName.contains('quant') ||
        lowerName.contains('mechan') ||
        lowerCode.contains('phy')) {
      return LucideIcons.atom;
    }

    // 4. Chemistry (flask reaction)
    if (lowerName.contains('chem') ||
        lowerCode.contains('che')) {
      return LucideIcons.flaskConical;
    }

    // 5. Biology / Biotech / Life Sciences
    if (lowerName.contains('bio') ||
        lowerName.contains('life') ||
        lowerName.contains('scien')) {
      return LucideIcons.microscope;
    }

    // 6. Lab / Practical
    if (lowerName.contains('lab') ||
        lowerName.contains('practic') ||
        lowerCode.contains('lab')) {
      return LucideIcons.testTubes;
    }

    // 7. Programming / Algorithms / Data Structures
    if (lowerName.contains('program') ||
        lowerName.contains('code') ||
        lowerName.contains('coding') ||
        lowerName.contains('algorithm') ||
        lowerName.contains('struct') ||
        lowerName.contains('java') ||
        lowerName.contains('python') ||
        lowerName.contains('c prog') ||
        lowerCode.contains('ada') ||
        lowerCode.contains('cse')) {
      return LucideIcons.braces;
    }

    // 8. Software Engineering / Development
    if (lowerName.contains('softw') ||
        lowerName.contains('develop') ||
        lowerName.contains('agile') ||
        lowerCode.contains('se')) {
      return LucideIcons.cog;
    }

    // 9. Mobile / Web / App Development
    if (lowerName.contains('web') ||
        lowerName.contains('mobil') ||
        lowerName.contains('android') ||
        lowerName.contains('ios') ||
        lowerName.contains('flutter') ||
        lowerName.contains('app dev') ||
        lowerCode.contains('mad')) {
      return LucideIcons.smartphone;
    }

    // 10. Database / Storage / Big Data
    if (lowerName.contains('dbms') ||
        lowerName.contains('databas') ||
        lowerName.contains('storage') ||
        lowerName.contains('sql') ||
        lowerName.contains('analyt') ||
        lowerCode.contains('db')) {
      return LucideIcons.database;
    }

    // 11. Networks / OS
    if (lowerName.contains('network') ||
        lowerName.contains('operat') ||
        lowerName.contains('unix') ||
        lowerName.contains('linux') ||
        lowerCode.contains('os') ||
        lowerCode.contains('cn')) {
      return LucideIcons.cpu;
    }

    // 12. Security / Cyber / Law / Constitution / Ethics
    if (lowerName.contains('security') ||
        lowerName.contains('cyber') ||
        lowerName.contains('crypt') ||
        lowerName.contains('law') ||
        lowerName.contains('constitut') ||
        lowerName.contains('ethic') ||
        lowerCode.contains('crp') ||
        lowerCode.contains('sec')) {
      return LucideIcons.shieldCheck;
    }

    // 13. Finance / Business / Economics / Management
    if (lowerName.contains('finan') ||
        lowerName.contains('econ') ||
        lowerName.contains('manag') ||
        lowerName.contains('busin') ||
        lowerName.contains('account') ||
        lowerName.contains('market')) {
      return LucideIcons.trendingUp;
    }

    // 14. Design / Graphics / UI / UX / Arts
    if (lowerName.contains('design') ||
        lowerName.contains('graph') ||
        lowerName.contains('ui') ||
        lowerName.contains('ux') ||
        lowerName.contains('cad') ||
        lowerName.contains('art')) {
      return LucideIcons.palette;
    }

    // 15. Physical Education / Sports
    if (lowerName.contains('physical edu') ||
        lowerName.contains('sport') ||
        lowerName.contains('yoga') ||
        lowerName.contains('fitness')) {
      return LucideIcons.dumbbell;
    }

    // 16. General Academics / NPTEL / Projects / Seminars
    if (lowerName.contains('nptel') ||
        lowerName.contains('project') ||
        lowerName.contains('seminar') ||
        lowerName.contains('intern') ||
        lowerCode.contains('nptel')) {
      return LucideIcons.graduationCap;
    }

    // 17. Electronics / Electrical / Circuits
    if (lowerName.contains('electron') ||
        lowerName.contains('electr') ||
        lowerName.contains('circuit') ||
        lowerName.contains('vlsi') ||
        lowerName.contains('signal') ||
        lowerCode.contains('tfc') ||
        lowerCode.contains('ece')) {
      return LucideIcons.circuitBoard;
    }

    // 18. Environmental / Civil
    if (lowerName.contains('environ') ||
        lowerName.contains('civil') ||
        lowerName.contains('sustain')) {
      return LucideIcons.leaf;
    }

    // Fallback: Use resolved preset icon or general book icon
    final resolved = _resolveCode(code, name);
    switch (resolved) {
      case 'ADA':
        return LucideIcons.braces;
      case 'OS':
        return LucideIcons.cpu;
      case 'SE':
        return LucideIcons.cog;
      case 'LAO':
        return LucideIcons.sigma;
      case 'CRP':
        return LucideIcons.shieldCheck;
      case 'TFC':
        return LucideIcons.circuitBoard;
      case 'MAD':
        return LucideIcons.smartphone;
      case 'NPTEL':
        return LucideIcons.graduationCap;
      default:
        return LucideIcons.bookOpen;
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
