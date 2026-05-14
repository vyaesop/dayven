import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PlannerThemeMode { mono, vivid, dark }

extension PlannerThemeModeX on PlannerThemeMode {
  String get storageValue => name;
  String get label => switch (this) {
    PlannerThemeMode.mono => 'Mono',
    PlannerThemeMode.vivid => 'Vivid',
    PlannerThemeMode.dark => 'Dark',
  };
}

enum PlannerAccentPalette {
  white,
  brilliantViolet,
  deepPurple,
  darkIndigo,
  royalBlue,
  midnightBlue,
  navyBlue,
  sapphireBlue,
  skyBlue,
  kingfisherBlue,
  azureBlue,
  tealGreen,
  lotusGreen,
  forestGreen,
  sageGreen,
  eucalyptus,
  pineGrey,
  sunflowerYellow,
  mustardYellow,
  goldYellow,
  amberOrange,
  terracotta,
  coralPink,
  crimsonRed,
  burgundyRed,
  rosePink,
  blushPink,
  mauvePurple,
  plumPurple,
  lunaBlack,
}

extension PlannerAccentPaletteX on PlannerAccentPalette {
  String get storageValue => name;

  String get label => switch (this) {
    PlannerAccentPalette.white => 'White',
    PlannerAccentPalette.brilliantViolet => 'Brilliant Violet',
    PlannerAccentPalette.deepPurple => 'Deep Purple',
    PlannerAccentPalette.darkIndigo => 'Dark Indigo',
    PlannerAccentPalette.royalBlue => 'Royal Blue',
    PlannerAccentPalette.midnightBlue => 'Midnight Blue',
    PlannerAccentPalette.navyBlue => 'Navy Blue',
    PlannerAccentPalette.sapphireBlue => 'Sapphire Blue',
    PlannerAccentPalette.skyBlue => 'Sky Blue',
    PlannerAccentPalette.kingfisherBlue => 'Kingfisher Blue',
    PlannerAccentPalette.azureBlue => 'Azure',
    PlannerAccentPalette.tealGreen => 'Teal',
    PlannerAccentPalette.lotusGreen => 'Lotus Green',
    PlannerAccentPalette.forestGreen => 'Forest Green',
    PlannerAccentPalette.sageGreen => 'Sage Green',
    PlannerAccentPalette.eucalyptus => 'Eucalyptus',
    PlannerAccentPalette.pineGrey => 'Pine Grey',
    PlannerAccentPalette.sunflowerYellow => 'Sunflower',
    PlannerAccentPalette.mustardYellow => 'Mustard Yellow',
    PlannerAccentPalette.goldYellow => 'Gold',
    PlannerAccentPalette.amberOrange => 'Amber Orange',
    PlannerAccentPalette.terracotta => 'Terracotta',
    PlannerAccentPalette.coralPink => 'Coral',
    PlannerAccentPalette.crimsonRed => 'Crimson Red',
    PlannerAccentPalette.burgundyRed => 'Burgundy',
    PlannerAccentPalette.rosePink => 'Rose',
    PlannerAccentPalette.blushPink => 'Blush',
    PlannerAccentPalette.mauvePurple => 'Mauve',
    PlannerAccentPalette.plumPurple => 'Plum Purple',
    PlannerAccentPalette.lunaBlack => 'Luna Black',
  };

  Color get color => switch (this) {
    PlannerAccentPalette.white => const Color(0xFFE8E5DE),
    PlannerAccentPalette.brilliantViolet => const Color(0xFF6C62CC),
    PlannerAccentPalette.deepPurple => const Color(0xFF5B2D8E),
    PlannerAccentPalette.darkIndigo => const Color(0xFF3D3580),
    PlannerAccentPalette.royalBlue => const Color(0xFF4880D4),
    PlannerAccentPalette.midnightBlue => const Color(0xFF1B3A6E),
    PlannerAccentPalette.navyBlue => const Color(0xFF253F6B),
    PlannerAccentPalette.sapphireBlue => const Color(0xFF2558A8),
    PlannerAccentPalette.skyBlue => const Color(0xFF2AAFD8),
    PlannerAccentPalette.kingfisherBlue => const Color(0xFF0D8CA8),
    PlannerAccentPalette.azureBlue => const Color(0xFF3498C8),
    PlannerAccentPalette.tealGreen => const Color(0xFF2DC0A8),
    PlannerAccentPalette.lotusGreen => const Color(0xFF4A9A58),
    PlannerAccentPalette.forestGreen => const Color(0xFF2D6E48),
    PlannerAccentPalette.sageGreen => const Color(0xFF6FAE7A),
    PlannerAccentPalette.eucalyptus => const Color(0xFF4E9E8C),
    PlannerAccentPalette.pineGrey => const Color(0xFF5A7068),
    PlannerAccentPalette.sunflowerYellow => const Color(0xFFE8C030),
    PlannerAccentPalette.mustardYellow => const Color(0xFFD4A72C),
    PlannerAccentPalette.goldYellow => const Color(0xFFE8BB42),
    PlannerAccentPalette.amberOrange => const Color(0xFFD07050),
    PlannerAccentPalette.terracotta => const Color(0xFFBE6050),
    PlannerAccentPalette.coralPink => const Color(0xFFF5714A),
    PlannerAccentPalette.crimsonRed => const Color(0xFFC84050),
    PlannerAccentPalette.burgundyRed => const Color(0xFF882840),
    PlannerAccentPalette.rosePink => const Color(0xFFD45880),
    PlannerAccentPalette.blushPink => const Color(0xFFE88098),
    PlannerAccentPalette.mauvePurple => const Color(0xFF9870A8),
    PlannerAccentPalette.plumPurple => const Color(0xFFAA3E82),
    PlannerAccentPalette.lunaBlack => const Color(0xFF3A3D42),
  };
}

class AppPreferences {
  const AppPreferences({
    required this.themeMode,
    required this.accentPalette,
    required this.defaultCalendarId,
    required this.matchTimelineColors,
    required this.showWeather,
    required this.showActions,
    required this.showBirthdays,
    required this.showAllDay,
    required this.dailyBriefing,
    required this.rainAlerts,
    required this.upcomingReminders,
    required this.travelAlerts,
    required this.textScale,
  });

  factory AppPreferences.defaults() {
    return const AppPreferences(
      themeMode: PlannerThemeMode.dark,
      accentPalette: PlannerAccentPalette.mustardYellow,
      defaultCalendarId: 'calendar',
      matchTimelineColors: false,
      showWeather: true,
      showActions: true,
      showBirthdays: false,
      showAllDay: true,
      dailyBriefing: true,
      rainAlerts: true,
      upcomingReminders: true,
      travelAlerts: true,
      textScale: 1,
    );
  }

  final PlannerThemeMode themeMode;
  final PlannerAccentPalette accentPalette;
  final String defaultCalendarId;
  final bool matchTimelineColors;
  final bool showWeather;
  final bool showActions;
  final bool showBirthdays;
  final bool showAllDay;
  final bool dailyBriefing;
  final bool rainAlerts;
  final bool upcomingReminders;
  final bool travelAlerts;
  final double textScale;

  AppPreferences copyWith({
    PlannerThemeMode? themeMode,
    PlannerAccentPalette? accentPalette,
    String? defaultCalendarId,
    bool? matchTimelineColors,
    bool? showWeather,
    bool? showActions,
    bool? showBirthdays,
    bool? showAllDay,
    bool? dailyBriefing,
    bool? rainAlerts,
    bool? upcomingReminders,
    bool? travelAlerts,
    double? textScale,
  }) {
    return AppPreferences(
      themeMode: themeMode ?? this.themeMode,
      accentPalette: accentPalette ?? this.accentPalette,
      defaultCalendarId: defaultCalendarId ?? this.defaultCalendarId,
      matchTimelineColors: matchTimelineColors ?? this.matchTimelineColors,
      showWeather: showWeather ?? this.showWeather,
      showActions: showActions ?? this.showActions,
      showBirthdays: showBirthdays ?? this.showBirthdays,
      showAllDay: showAllDay ?? this.showAllDay,
      dailyBriefing: dailyBriefing ?? this.dailyBriefing,
      rainAlerts: rainAlerts ?? this.rainAlerts,
      upcomingReminders: upcomingReminders ?? this.upcomingReminders,
      travelAlerts: travelAlerts ?? this.travelAlerts,
      textScale: textScale ?? this.textScale,
    );
  }
}

final appPreferencesControllerProvider =
    AsyncNotifierProvider<AppPreferencesController, AppPreferences>(
      AppPreferencesController.new,
    );

class AppPreferencesController extends AsyncNotifier<AppPreferences> {
  static const _themeModeKey = 'pref_theme_mode';
  static const _accentPaletteKey = 'pref_accent_palette';
  static const _defaultCalendarIdKey = 'pref_default_calendar_id';
  static const _matchTimelineColorsKey = 'pref_match_timeline_colors';
  static const _showWeatherKey = 'pref_show_weather';
  static const _showActionsKey = 'pref_show_actions';
  static const _showBirthdaysKey = 'pref_show_birthdays';
  static const _showAllDayKey = 'pref_show_all_day';
  static const _dailyBriefingKey = 'pref_daily_briefing';
  static const _rainAlertsKey = 'pref_rain_alerts';
  static const _upcomingRemindersKey = 'pref_upcoming_reminders';
  static const _travelAlertsKey = 'pref_travel_alerts';
  static const _textScaleKey = 'pref_text_scale';

  @override
  Future<AppPreferences> build() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = AppPreferences.defaults();

    return AppPreferences(
      themeMode: _parseThemeMode(
        prefs.getString(_themeModeKey),
        defaults.themeMode,
      ),
      accentPalette: _parseAccentPalette(
        prefs.getString(_accentPaletteKey),
        defaults.accentPalette,
      ),
      defaultCalendarId:
          prefs.getString(_defaultCalendarIdKey) ?? defaults.defaultCalendarId,
      matchTimelineColors:
          prefs.getBool(_matchTimelineColorsKey) ??
          defaults.matchTimelineColors,
      showWeather: prefs.getBool(_showWeatherKey) ?? defaults.showWeather,
      showActions: prefs.getBool(_showActionsKey) ?? defaults.showActions,
      showBirthdays: prefs.getBool(_showBirthdaysKey) ?? defaults.showBirthdays,
      showAllDay: prefs.getBool(_showAllDayKey) ?? defaults.showAllDay,
      dailyBriefing: prefs.getBool(_dailyBriefingKey) ?? defaults.dailyBriefing,
      rainAlerts: prefs.getBool(_rainAlertsKey) ?? defaults.rainAlerts,
      upcomingReminders:
          prefs.getBool(_upcomingRemindersKey) ?? defaults.upcomingReminders,
      travelAlerts: prefs.getBool(_travelAlertsKey) ?? defaults.travelAlerts,
      textScale: prefs.getDouble(_textScaleKey) ?? defaults.textScale,
    );
  }

  Future<void> setThemeMode(PlannerThemeMode value) {
    return _update((current) => current.copyWith(themeMode: value));
  }

  Future<void> setAccentPalette(PlannerAccentPalette value) {
    return _update((current) => current.copyWith(accentPalette: value));
  }

  Future<void> setDefaultCalendarId(String value) {
    return _update((current) => current.copyWith(defaultCalendarId: value));
  }

  Future<void> setBoolPreference(String key, bool value) {
    return _update((current) {
      switch (key) {
        case PreferenceKeys.matchTimelineColors:
          return current.copyWith(matchTimelineColors: value);
        case PreferenceKeys.showWeather:
          return current.copyWith(showWeather: value);
        case PreferenceKeys.showActions:
          return current.copyWith(showActions: value);
        case PreferenceKeys.showBirthdays:
          return current.copyWith(showBirthdays: value);
        case PreferenceKeys.showAllDay:
          return current.copyWith(showAllDay: value);
        case PreferenceKeys.dailyBriefing:
          return current.copyWith(dailyBriefing: value);
        case PreferenceKeys.rainAlerts:
          return current.copyWith(rainAlerts: value);
        case PreferenceKeys.upcomingReminders:
          return current.copyWith(upcomingReminders: value);
        case PreferenceKeys.travelAlerts:
          return current.copyWith(travelAlerts: value);
      }

      return current;
    });
  }

  Future<void> setTextScale(double value) {
    return _update((current) => current.copyWith(textScale: value));
  }

  Future<void> _update(
    AppPreferences Function(AppPreferences current) next,
  ) async {
    final current = state.asData?.value ?? AppPreferences.defaults();
    final updated = next(current);
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> _save(AppPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, preferences.themeMode.storageValue);
    await prefs.setString(
      _accentPaletteKey,
      preferences.accentPalette.storageValue,
    );
    await prefs.setString(_defaultCalendarIdKey, preferences.defaultCalendarId);
    await prefs.setBool(
      _matchTimelineColorsKey,
      preferences.matchTimelineColors,
    );
    await prefs.setBool(_showWeatherKey, preferences.showWeather);
    await prefs.setBool(_showActionsKey, preferences.showActions);
    await prefs.setBool(_showBirthdaysKey, preferences.showBirthdays);
    await prefs.setBool(_showAllDayKey, preferences.showAllDay);
    await prefs.setBool(_dailyBriefingKey, preferences.dailyBriefing);
    await prefs.setBool(_rainAlertsKey, preferences.rainAlerts);
    await prefs.setBool(_upcomingRemindersKey, preferences.upcomingReminders);
    await prefs.setBool(_travelAlertsKey, preferences.travelAlerts);
    await prefs.setDouble(_textScaleKey, preferences.textScale);
  }

  PlannerThemeMode _parseThemeMode(String? value, PlannerThemeMode fallback) {
    return PlannerThemeMode.values.firstWhere(
      (mode) => mode.storageValue == value,
      orElse: () => fallback,
    );
  }

  PlannerAccentPalette _parseAccentPalette(
    String? value,
    PlannerAccentPalette fallback,
  ) {
    return PlannerAccentPalette.values.firstWhere(
      (palette) => palette.storageValue == value,
      orElse: () => fallback,
    );
  }
}

class PreferenceKeys {
  const PreferenceKeys._();

  static const matchTimelineColors =
      AppPreferencesController._matchTimelineColorsKey;
  static const showWeather = AppPreferencesController._showWeatherKey;
  static const showActions = AppPreferencesController._showActionsKey;
  static const showBirthdays = AppPreferencesController._showBirthdaysKey;
  static const showAllDay = AppPreferencesController._showAllDayKey;
  static const dailyBriefing = AppPreferencesController._dailyBriefingKey;
  static const rainAlerts = AppPreferencesController._rainAlertsKey;
  static const upcomingReminders =
      AppPreferencesController._upcomingRemindersKey;
  static const travelAlerts = AppPreferencesController._travelAlertsKey;
}
