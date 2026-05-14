import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/preferences/application/app_preferences_controller.dart';

class AppColors {
  static const Color background = Color(0xFFF7F5F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF18171A);
  static const Color mutedInk = Color(0xFF7A7872);
  static const Color line = Color(0xFFE6E2D8);
  static const Color shadow = Color(0x1A0F0E0A);
  static const Color charcoal = Color(0xFF35332E);
  static const Color teal = Color(0xFF2DC0CA);
  static const Color coral = Color(0xFFF5AB4E);
  static const Color lilac = Color(0xFFBD93E6);
  static const Color sage = Color(0xFF96D84A);
  static const Color graphite = Color(0xFF58554E);
  static const Color gold = Color(0xFFE8BB42);
}

ThemeData buildAppTheme([AppPreferences? preferences]) {
  final prefs = preferences ?? AppPreferences.defaults();
  final accent = prefs.accentPalette.color;
  final background = switch (prefs.themeMode) {
    PlannerThemeMode.mono => const Color(0xFFF9F8F5),
    PlannerThemeMode.vivid => const Color(0xFFF5EFE2),
    PlannerThemeMode.dark => const Color(0xFF26241F),
  };
  final primary = prefs.themeMode == PlannerThemeMode.vivid
      ? accent
      : AppColors.charcoal;

  final surfaceColor = prefs.themeMode == PlannerThemeMode.dark
      ? const Color(0xFF302E29)
      : AppColors.surface;
  final onSurfaceColor = prefs.themeMode == PlannerThemeMode.dark
      ? const Color(0xFFEDEBE4)
      : AppColors.ink;

  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.light(
      primary: primary,
      secondary: accent,
      surface: surfaceColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: onSurfaceColor,
    ),
  );

  final textTheme = GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
    displayLarge: GoogleFonts.spaceGrotesk(
      fontSize: 36,
      fontWeight: FontWeight.w600,
      color: onSurfaceColor,
      letterSpacing: -1.2,
    ),
    displayMedium: GoogleFonts.spaceGrotesk(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: onSurfaceColor,
      letterSpacing: -0.8,
    ),
    headlineMedium: GoogleFonts.spaceGrotesk(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: onSurfaceColor,
      letterSpacing: -0.4,
    ),
    titleMedium: GoogleFonts.dmSans(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: onSurfaceColor,
    ),
    bodyLarge: GoogleFonts.dmSans(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: onSurfaceColor,
      height: 1.4,
    ),
    bodyMedium: GoogleFonts.dmSans(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: prefs.themeMode == PlannerThemeMode.dark
          ? const Color(0xFFA8A49C)
          : AppColors.mutedInk,
      height: 1.4,
    ),
    labelLarge: GoogleFonts.dmSans(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.9,
      color: onSurfaceColor,
    ),
  );

  final inputFill = prefs.themeMode == PlannerThemeMode.dark
      ? const Color(0xFF3A3832)
      : Colors.white;
  final inputBorder = prefs.themeMode == PlannerThemeMode.dark
      ? const Color(0xFF504D46)
      : AppColors.line;

  return base.copyWith(
    textTheme: textTheme,
    dividerColor: prefs.themeMode == PlannerThemeMode.dark
        ? const Color(0xFF3F3D38)
        : AppColors.line,
    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputFill,
      hintStyle: textTheme.bodyMedium,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: accent, width: 1.5),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: surfaceColor,
      selectedColor: accent.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: inputBorder),
      ),
      side: BorderSide(color: inputBorder),
      labelStyle: textTheme.bodyMedium?.copyWith(color: onSurfaceColor),
    ),
  );
}
