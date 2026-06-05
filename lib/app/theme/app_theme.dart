import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/preferences/application/app_preferences_controller.dart';

/// Base reference colors. Anything that is genuinely brand-neutral (the
/// charcoal, parchment, dotted shadow, etc.) lives here. Accent-driven colors
/// must always come from the active [ThemeData] / [PlannerSurfaceTones] so they
/// follow the user's pick.
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

  /// Fallback gold accent. Prefer reading the live accent from
  /// `Theme.of(context).colorScheme.secondary` so the user's pick flows through.
  static const Color gold = Color(0xFFE8BB42);
}

Color parsePlannerColor(String? rawColor, {Color fallback = AppColors.lilac}) {
  if (rawColor == null) {
    return fallback;
  }

  final input = rawColor.trim();
  if (input.isEmpty) {
    return fallback;
  }

  final decimalColorMatch = RegExp(r'^Color\((\d+)\)$').firstMatch(input);
  if (decimalColorMatch != null) {
    final value = int.tryParse(decimalColorMatch.group(1)!);
    if (value != null) {
      return Color(value);
    }
  }

  final hexMatch = RegExp(
    r'(?:#|0x|0X)?([0-9a-fA-F]{8}|[0-9a-fA-F]{6})(?![0-9a-fA-F])',
  ).firstMatch(input);
  if (hexMatch == null) {
    return fallback;
  }

  final hex = hexMatch.group(1)!;
  final normalized = hex.length == 6 ? 'FF$hex' : hex;
  final value = int.tryParse(normalized, radix: 16);
  return value == null ? fallback : Color(value);
}

/// Resolved colors for a specific [PlannerThemeMode]. Held on [ThemeData] via
/// [ThemeExtension] so any widget can read `Theme.of(context).extension<PlannerSurfaceTones>()`.
class PlannerSurfaceTones extends ThemeExtension<PlannerSurfaceTones> {
  const PlannerSurfaceTones({
    required this.mode,
    required this.scaffold,
    required this.surface,
    required this.surfaceSoft,
    required this.surfaceRaised,
    required this.menuSurface,
    required this.rail,
    required this.bottomBar,
    required this.line,
    required this.ink,
    required this.mutedInk,
    required this.faintInk,
    required this.onAccent,
    required this.shadow,
    required this.isDark,
  });

  final PlannerThemeMode mode;
  final Color scaffold;
  final Color surface;
  final Color surfaceSoft;
  final Color surfaceRaised;
  final Color menuSurface;
  final Color rail;
  final Color bottomBar;
  final Color line;
  final Color ink;
  final Color mutedInk;
  final Color faintInk;
  final Color onAccent;
  final Color shadow;
  final bool isDark;

  @override
  PlannerSurfaceTones copyWith({
    PlannerThemeMode? mode,
    Color? scaffold,
    Color? surface,
    Color? surfaceSoft,
    Color? surfaceRaised,
    Color? menuSurface,
    Color? rail,
    Color? bottomBar,
    Color? line,
    Color? ink,
    Color? mutedInk,
    Color? faintInk,
    Color? onAccent,
    Color? shadow,
    bool? isDark,
  }) {
    return PlannerSurfaceTones(
      mode: mode ?? this.mode,
      scaffold: scaffold ?? this.scaffold,
      surface: surface ?? this.surface,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      menuSurface: menuSurface ?? this.menuSurface,
      rail: rail ?? this.rail,
      bottomBar: bottomBar ?? this.bottomBar,
      line: line ?? this.line,
      ink: ink ?? this.ink,
      mutedInk: mutedInk ?? this.mutedInk,
      faintInk: faintInk ?? this.faintInk,
      onAccent: onAccent ?? this.onAccent,
      shadow: shadow ?? this.shadow,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  PlannerSurfaceTones lerp(
    ThemeExtension<PlannerSurfaceTones>? other,
    double t,
  ) {
    if (other is! PlannerSurfaceTones) return this;
    return PlannerSurfaceTones(
      mode: t < 0.5 ? mode : other.mode,
      scaffold: Color.lerp(scaffold, other.scaffold, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSoft: Color.lerp(surfaceSoft, other.surfaceSoft, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      menuSurface: Color.lerp(menuSurface, other.menuSurface, t)!,
      rail: Color.lerp(rail, other.rail, t)!,
      bottomBar: Color.lerp(bottomBar, other.bottomBar, t)!,
      line: Color.lerp(line, other.line, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      mutedInk: Color.lerp(mutedInk, other.mutedInk, t)!,
      faintInk: Color.lerp(faintInk, other.faintInk, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

extension PlannerThemeAccess on BuildContext {
  /// The active accent (user pick). Use this anywhere the legacy code used
  /// `AppColors.gold`.
  Color get plannerAccent => Theme.of(this).colorScheme.secondary;

  /// The contrasting color to lay text/icons on top of [plannerAccent].
  Color get onPlannerAccent =>
      Theme.of(this).extension<PlannerSurfaceTones>()?.onAccent ?? Colors.white;

  PlannerSurfaceTones get plannerTones {
    return Theme.of(this).extension<PlannerSurfaceTones>() ??
        _tonesFor(PlannerThemeMode.mono, AppColors.gold);
  }
}

ThemeData buildAppTheme([AppPreferences? preferences]) {
  final prefs = preferences ?? AppPreferences.defaults();
  final accent = prefs.accentPalette.color;
  final tones = _tonesFor(prefs.themeMode, accent);
  final isDark = tones.isDark;

  // In Vivid mode the accent becomes the dominant primary color. In every
  // other mode the primary is the strong neutral (charcoal / parchment-on-dark)
  // while the accent rides on `secondary` so it consistently shows up in
  // back arrows, headings, day chips, etc.
  final primary = prefs.themeMode == PlannerThemeMode.vivid
      ? accent
      : (isDark ? const Color(0xFFF3EFE5) : AppColors.charcoal);
  final onPrimary = _onColorFor(primary);

  final colorScheme =
      (isDark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
        primary: primary,
        onPrimary: onPrimary,
        secondary: accent,
        onSecondary: tones.onAccent,
        surface: tones.surface,
        onSurface: tones.ink,
        surfaceContainer: tones.surfaceSoft,
        surfaceContainerHighest: tones.surfaceRaised,
        outline: tones.line,
        outlineVariant: tones.line.withValues(alpha: 0.55),
        shadow: tones.shadow,
      );

  final base = ThemeData(
    useMaterial3: true,
    brightness: isDark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: tones.scaffold,
    colorScheme: colorScheme,
    extensions: [tones],
  );

  final textTheme = GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
    displayLarge: GoogleFonts.spaceGrotesk(
      fontSize: 36,
      fontWeight: FontWeight.w600,
      color: tones.ink,
      letterSpacing: -1.2,
    ),
    displayMedium: GoogleFonts.spaceGrotesk(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: tones.ink,
      letterSpacing: -0.8,
    ),
    headlineMedium: GoogleFonts.spaceGrotesk(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: tones.ink,
      letterSpacing: -0.4,
    ),
    titleMedium: GoogleFonts.dmSans(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: tones.ink,
    ),
    bodyLarge: GoogleFonts.dmSans(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: tones.ink,
      height: 1.4,
    ),
    bodyMedium: GoogleFonts.dmSans(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: tones.mutedInk,
      height: 1.4,
    ),
    labelLarge: GoogleFonts.dmSans(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.9,
      color: tones.ink,
    ),
  );

  return base.copyWith(
    textTheme: textTheme,
    dividerColor: tones.line,
    cardTheme: CardThemeData(
      color: tones.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    iconTheme: IconThemeData(color: tones.ink),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tones.surfaceSoft,
      hintStyle: textTheme.bodyMedium,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: tones.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: tones.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: accent, width: 1.5),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: tones.surface,
      selectedColor: accent.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: tones.line),
      ),
      side: BorderSide(color: tones.line),
      labelStyle: textTheme.bodyMedium?.copyWith(color: tones.ink),
    ),
  );
}

PlannerSurfaceTones _tonesFor(PlannerThemeMode mode, Color accent) {
  switch (mode) {
    case PlannerThemeMode.mono:
      // Soft parchment, very neutral. Accent shows only as a small highlight.
      return PlannerSurfaceTones(
        mode: mode,
        scaffold: const Color(0xFFF9F8F4),
        surface: Colors.white,
        surfaceSoft: const Color(0xFFF1EFE8),
        surfaceRaised: Colors.white,
        menuSurface: AppColors.charcoal,
        rail: AppColors.charcoal,
        bottomBar: Colors.white,
        line: const Color(0xFFE6E2D8),
        ink: const Color(0xFF18171A),
        mutedInk: const Color(0xFF7A7872),
        faintInk: const Color(0xFFB8B5AC),
        onAccent: _onColorFor(accent),
        shadow: const Color(0x1A0F0E0A),
        isDark: false,
      );
    case PlannerThemeMode.vivid:
      // Warm cream, slightly stronger neutrals; accent reads as the brand color.
      return PlannerSurfaceTones(
        mode: mode,
        scaffold: const Color(0xFFF5EFE2),
        surface: const Color(0xFFFBF7EC),
        surfaceSoft: const Color(0xFFEFE9DA),
        surfaceRaised: Colors.white,
        menuSurface: AppColors.charcoal,
        rail: AppColors.charcoal,
        bottomBar: const Color(0xFFFBF7EC),
        line: const Color(0xFFE1DBC8),
        ink: const Color(0xFF1A1916),
        mutedInk: const Color(0xFF6F6C62),
        faintInk: const Color(0xFFAEA99A),
        onAccent: _onColorFor(accent),
        shadow: const Color(0x1F0F0E0A),
        isDark: false,
      );
    case PlannerThemeMode.muted:
      // Quiet warm grey background; deliberately desaturated mid-tones.
      return PlannerSurfaceTones(
        mode: mode,
        scaffold: const Color(0xFFEAE7DF),
        surface: const Color(0xFFF2EFE8),
        surfaceSoft: const Color(0xFFE2DED4),
        surfaceRaised: const Color(0xFFF7F5EE),
        menuSurface: const Color(0xFF3F3D38),
        rail: const Color(0xFF3F3D38),
        bottomBar: const Color(0xFFF2EFE8),
        line: const Color(0xFFCFCABE),
        ink: const Color(0xFF26241F),
        mutedInk: const Color(0xFF6E6B62),
        faintInk: const Color(0xFFA29E91),
        onAccent: _onColorFor(accent),
        shadow: const Color(0x1A0F0E0A),
        isDark: false,
      );
    case PlannerThemeMode.dark:
      return PlannerSurfaceTones(
        mode: mode,
        scaffold: const Color(0xFF1E1C18),
        surface: const Color(0xFF2A2823),
        surfaceSoft: const Color(0xFF35332D),
        surfaceRaised: const Color(0xFF3A3832),
        menuSurface: const Color(0xFF15140F),
        rail: const Color(0xFF15140F),
        bottomBar: const Color(0xFF2A2823),
        line: const Color(0xFF3F3D38),
        ink: const Color(0xFFEDEBE4),
        mutedInk: const Color(0xFFA8A49C),
        faintInk: const Color(0xFF6C6A62),
        onAccent: _onColorFor(accent),
        shadow: const Color(0x33000000),
        isDark: true,
      );
  }
}

Color _onColorFor(Color background) {
  final lum =
      (0.299 * background.r + 0.587 * background.g + 0.114 * background.b);
  return lum > 0.62 ? const Color(0xFF18171A) : Colors.white;
}
