import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/calendars/secondary_calendar.dart';

export '../../../core/calendars/secondary_calendar.dart'
    show SecondaryCalendar, SecondaryCalendarX;

enum PlannerThemeMode { mono, vivid, muted, dark }

extension PlannerThemeModeX on PlannerThemeMode {
  String get storageValue => name;
  String get label => switch (this) {
    PlannerThemeMode.mono => 'Mono',
    PlannerThemeMode.vivid => 'Vivid',
    PlannerThemeMode.muted => 'Muted',
    PlannerThemeMode.dark => 'Dark',
  };
}

enum PlannerAccentPalette {
  white,
  polarWhite,
  cordilianGrey,
  steelGrey,
  hawkingBlack,
  brilliantViolet,
  royalBlue,
  antwerpBlue,
  skyBlue,
  underwaterBlue,
  bamboGreen,
  oxideGreen,
  kiwiGreen,
  sunflowerYellow,
  orangeYellow,
  mustardYellow,
  amberOrange,
  crimsonRed,
  burgundyRed,
  plumPurple,
  deepPurple,
  darkIndigo,
  midnightBlue,
  sapphireBlue,
  kingfisherBlue,
  pineGrey,
  lotusGreen,
  forestGreen,
  lunaBlack,
}

extension PlannerAccentPaletteX on PlannerAccentPalette {
  String get storageValue => name;

  String get label => switch (this) {
    PlannerAccentPalette.white => 'White',
    PlannerAccentPalette.polarWhite => 'Polar White',
    PlannerAccentPalette.cordilianGrey => 'Cordilian Grey',
    PlannerAccentPalette.steelGrey => 'Steel Grey',
    PlannerAccentPalette.hawkingBlack => 'Hawking Black',
    PlannerAccentPalette.brilliantViolet => 'Brilliant Violet',
    PlannerAccentPalette.royalBlue => 'Royal Blue',
    PlannerAccentPalette.antwerpBlue => 'Antwerp Blue',
    PlannerAccentPalette.skyBlue => 'Sky Blue',
    PlannerAccentPalette.underwaterBlue => 'Underwater Blue',
    PlannerAccentPalette.bamboGreen => 'Bambo Green',
    PlannerAccentPalette.oxideGreen => 'Oxide Green',
    PlannerAccentPalette.kiwiGreen => 'Kiwi Green',
    PlannerAccentPalette.sunflowerYellow => 'Sunflower Yellow',
    PlannerAccentPalette.orangeYellow => 'Orange Yellow',
    PlannerAccentPalette.mustardYellow => 'Mustard Yellow',
    PlannerAccentPalette.amberOrange => 'Amber Orange',
    PlannerAccentPalette.crimsonRed => 'Crimson Red',
    PlannerAccentPalette.burgundyRed => 'Burgundy Red',
    PlannerAccentPalette.plumPurple => 'Plum Purple',
    PlannerAccentPalette.deepPurple => 'Deep Purple',
    PlannerAccentPalette.darkIndigo => 'Dark Indigo',
    PlannerAccentPalette.midnightBlue => 'Midnight Blue',
    PlannerAccentPalette.sapphireBlue => 'Sapphire Blue',
    PlannerAccentPalette.kingfisherBlue => 'Kingfisher Blue',
    PlannerAccentPalette.pineGrey => 'Pine Grey',
    PlannerAccentPalette.lotusGreen => 'Lotus Green',
    PlannerAccentPalette.forestGreen => 'Forest Green',
    PlannerAccentPalette.lunaBlack => 'Luna Black',
  };

  Color get color => switch (this) {
    PlannerAccentPalette.white => const Color(0xFFF4F1EA),
    PlannerAccentPalette.polarWhite => const Color(0xFFE6E2D8),
    PlannerAccentPalette.cordilianGrey => const Color(0xFFB7B2A8),
    PlannerAccentPalette.steelGrey => const Color(0xFF8C8A82),
    PlannerAccentPalette.hawkingBlack => const Color(0xFF2A2925),
    PlannerAccentPalette.brilliantViolet => const Color(0xFF7C6CD8),
    PlannerAccentPalette.royalBlue => const Color(0xFF4880D4),
    PlannerAccentPalette.antwerpBlue => const Color(0xFF3D6CB0),
    PlannerAccentPalette.skyBlue => const Color(0xFF5AB6E0),
    PlannerAccentPalette.underwaterBlue => const Color(0xFF2A88B5),
    PlannerAccentPalette.bamboGreen => const Color(0xFF7AB07A),
    PlannerAccentPalette.oxideGreen => const Color(0xFF4E9E8C),
    PlannerAccentPalette.kiwiGreen => const Color(0xFF9CBE4A),
    PlannerAccentPalette.sunflowerYellow => const Color(0xFFE8C030),
    PlannerAccentPalette.orangeYellow => const Color(0xFFE89F3A),
    PlannerAccentPalette.mustardYellow => const Color(0xFFD4A72C),
    PlannerAccentPalette.amberOrange => const Color(0xFFD27042),
    PlannerAccentPalette.crimsonRed => const Color(0xFFC84050),
    PlannerAccentPalette.burgundyRed => const Color(0xFF8E3040),
    PlannerAccentPalette.plumPurple => const Color(0xFFAA4080),
    PlannerAccentPalette.deepPurple => const Color(0xFF5B2D8E),
    PlannerAccentPalette.darkIndigo => const Color(0xFF3D3580),
    PlannerAccentPalette.midnightBlue => const Color(0xFF1B3A6E),
    PlannerAccentPalette.sapphireBlue => const Color(0xFF2558A8),
    PlannerAccentPalette.kingfisherBlue => const Color(0xFF0D8CA8),
    PlannerAccentPalette.pineGrey => const Color(0xFF5A7068),
    PlannerAccentPalette.lotusGreen => const Color(0xFF4A9A58),
    PlannerAccentPalette.forestGreen => const Color(0xFF2D6E48),
    PlannerAccentPalette.lunaBlack => const Color(0xFF1F1E1B),
  };

  // True when the swatch is so light it needs a dark check/outline for legibility.
  bool get isLight {
    final c = color;
    final lum = (0.299 * c.r + 0.587 * c.g + 0.114 * c.b);
    return lum > 0.72;
  }
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
    required this.timelineInvites,
    required this.shadeAlternateDays,
    required this.shadePastDays,
    required this.shadeWeekends,
    required this.shadeToday,
    required this.heavyShading,
    required this.cycleBusyDayEvents,
    required this.daysAtAGlance,
    required this.timelineLayoutMode,
    required this.dailyBriefing,
    required this.dailyBriefingHour,
    required this.dailyBriefingMinute,
    required this.rainAlerts,
    required this.rainAlertMode,
    required this.rainNoticeMinutes,
    required this.severeWeatherAlerts,
    required this.upcomingReminders,
    required this.travelAlerts,
    required this.travelMode,
    required this.directionsApp,
    required this.appIconBadge,
    required this.appIconMatchTheme,
    required this.textScale,
    required this.secondaryCalendar,
  });

  factory AppPreferences.defaults() {
    return const AppPreferences(
      themeMode: PlannerThemeMode.mono,
      accentPalette: PlannerAccentPalette.mustardYellow,
      defaultCalendarId: 'calendar',
      matchTimelineColors: false,
      showWeather: true,
      showActions: true,
      showBirthdays: false,
      showAllDay: true,
      timelineInvites: true,
      shadeAlternateDays: true,
      shadePastDays: true,
      shadeWeekends: false,
      shadeToday: true,
      heavyShading: true,
      cycleBusyDayEvents: true,
      daysAtAGlance: 9,
      timelineLayoutMode: 'Traditional',
      dailyBriefing: true,
      dailyBriefingHour: 8,
      dailyBriefingMinute: 0,
      rainAlerts: true,
      rainAlertMode: 'Any rain',
      rainNoticeMinutes: 15,
      severeWeatherAlerts: true,
      upcomingReminders: true,
      travelAlerts: true,
      travelMode: 'Driving',
      directionsApp: 'Google Maps',
      appIconBadge: 'None',
      appIconMatchTheme: true,
      textScale: 1,
      secondaryCalendar: SecondaryCalendar.none,
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
  final bool timelineInvites;
  final bool shadeAlternateDays;
  final bool shadePastDays;
  final bool shadeWeekends;
  final bool shadeToday;
  final bool heavyShading;
  final bool cycleBusyDayEvents;
  final int daysAtAGlance;
  final String timelineLayoutMode;
  final bool dailyBriefing;
  final int dailyBriefingHour;
  final int dailyBriefingMinute;
  final bool rainAlerts;
  final String rainAlertMode;
  final int rainNoticeMinutes;
  final bool severeWeatherAlerts;
  final bool upcomingReminders;
  final bool travelAlerts;
  final String travelMode;
  final String directionsApp;
  final String appIconBadge;
  final bool appIconMatchTheme;
  final double textScale;
  final SecondaryCalendar secondaryCalendar;

  AppPreferences copyWith({
    PlannerThemeMode? themeMode,
    PlannerAccentPalette? accentPalette,
    String? defaultCalendarId,
    bool? matchTimelineColors,
    bool? showWeather,
    bool? showActions,
    bool? showBirthdays,
    bool? showAllDay,
    bool? timelineInvites,
    bool? shadeAlternateDays,
    bool? shadePastDays,
    bool? shadeWeekends,
    bool? shadeToday,
    bool? heavyShading,
    bool? cycleBusyDayEvents,
    int? daysAtAGlance,
    String? timelineLayoutMode,
    bool? dailyBriefing,
    int? dailyBriefingHour,
    int? dailyBriefingMinute,
    bool? rainAlerts,
    String? rainAlertMode,
    int? rainNoticeMinutes,
    bool? severeWeatherAlerts,
    bool? upcomingReminders,
    bool? travelAlerts,
    String? travelMode,
    String? directionsApp,
    String? appIconBadge,
    bool? appIconMatchTheme,
    double? textScale,
    SecondaryCalendar? secondaryCalendar,
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
      timelineInvites: timelineInvites ?? this.timelineInvites,
      shadeAlternateDays: shadeAlternateDays ?? this.shadeAlternateDays,
      shadePastDays: shadePastDays ?? this.shadePastDays,
      shadeWeekends: shadeWeekends ?? this.shadeWeekends,
      shadeToday: shadeToday ?? this.shadeToday,
      heavyShading: heavyShading ?? this.heavyShading,
      cycleBusyDayEvents: cycleBusyDayEvents ?? this.cycleBusyDayEvents,
      daysAtAGlance: daysAtAGlance ?? this.daysAtAGlance,
      timelineLayoutMode: timelineLayoutMode ?? this.timelineLayoutMode,
      dailyBriefing: dailyBriefing ?? this.dailyBriefing,
      dailyBriefingHour: dailyBriefingHour ?? this.dailyBriefingHour,
      dailyBriefingMinute: dailyBriefingMinute ?? this.dailyBriefingMinute,
      rainAlerts: rainAlerts ?? this.rainAlerts,
      rainAlertMode: rainAlertMode ?? this.rainAlertMode,
      rainNoticeMinutes: rainNoticeMinutes ?? this.rainNoticeMinutes,
      severeWeatherAlerts: severeWeatherAlerts ?? this.severeWeatherAlerts,
      upcomingReminders: upcomingReminders ?? this.upcomingReminders,
      travelAlerts: travelAlerts ?? this.travelAlerts,
      travelMode: travelMode ?? this.travelMode,
      directionsApp: directionsApp ?? this.directionsApp,
      appIconBadge: appIconBadge ?? this.appIconBadge,
      appIconMatchTheme: appIconMatchTheme ?? this.appIconMatchTheme,
      textScale: textScale ?? this.textScale,
      secondaryCalendar: secondaryCalendar ?? this.secondaryCalendar,
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
  static const _timelineInvitesKey = 'pref_timeline_invites';
  static const _shadeAlternateDaysKey = 'pref_shade_alternate_days';
  static const _shadePastDaysKey = 'pref_shade_past_days';
  static const _shadeWeekendsKey = 'pref_shade_weekends';
  static const _shadeTodayKey = 'pref_shade_today';
  static const _heavyShadingKey = 'pref_heavy_shading';
  static const _cycleBusyDayEventsKey = 'pref_cycle_busy_day_events';
  static const _daysAtAGlanceKey = 'pref_days_at_a_glance';
  static const _timelineLayoutModeKey = 'pref_timeline_layout_mode';
  static const _dailyBriefingKey = 'pref_daily_briefing';
  static const _dailyBriefingHourKey = 'pref_daily_briefing_hour';
  static const _dailyBriefingMinuteKey = 'pref_daily_briefing_minute';
  static const _rainAlertsKey = 'pref_rain_alerts';
  static const _rainAlertModeKey = 'pref_rain_alert_mode';
  static const _rainNoticeMinutesKey = 'pref_rain_notice_minutes';
  static const _severeWeatherAlertsKey = 'pref_severe_weather_alerts';
  static const _upcomingRemindersKey = 'pref_upcoming_reminders';
  static const _travelAlertsKey = 'pref_travel_alerts';
  static const _travelModeKey = 'pref_travel_mode';
  static const _directionsAppKey = 'pref_directions_app';
  static const _appIconBadgeKey = 'pref_app_icon_badge';
  static const _appIconMatchThemeKey = 'pref_app_icon_match_theme';
  static const _textScaleKey = 'pref_text_scale';
  static const _secondaryCalendarKey = 'pref_secondary_calendar';

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
      timelineInvites:
          prefs.getBool(_timelineInvitesKey) ?? defaults.timelineInvites,
      shadeAlternateDays:
          prefs.getBool(_shadeAlternateDaysKey) ?? defaults.shadeAlternateDays,
      shadePastDays:
          prefs.getBool(_shadePastDaysKey) ?? defaults.shadePastDays,
      shadeWeekends: prefs.getBool(_shadeWeekendsKey) ?? defaults.shadeWeekends,
      shadeToday: prefs.getBool(_shadeTodayKey) ?? defaults.shadeToday,
      heavyShading: prefs.getBool(_heavyShadingKey) ?? defaults.heavyShading,
      cycleBusyDayEvents:
          prefs.getBool(_cycleBusyDayEventsKey) ?? defaults.cycleBusyDayEvents,
      daysAtAGlance:
          prefs.getInt(_daysAtAGlanceKey) ?? defaults.daysAtAGlance,
      timelineLayoutMode:
          prefs.getString(_timelineLayoutModeKey) ??
          defaults.timelineLayoutMode,
      dailyBriefing: prefs.getBool(_dailyBriefingKey) ?? defaults.dailyBriefing,
      dailyBriefingHour:
          prefs.getInt(_dailyBriefingHourKey) ?? defaults.dailyBriefingHour,
      dailyBriefingMinute:
          prefs.getInt(_dailyBriefingMinuteKey) ??
          defaults.dailyBriefingMinute,
      rainAlerts: prefs.getBool(_rainAlertsKey) ?? defaults.rainAlerts,
      rainAlertMode:
          prefs.getString(_rainAlertModeKey) ?? defaults.rainAlertMode,
      rainNoticeMinutes:
          prefs.getInt(_rainNoticeMinutesKey) ?? defaults.rainNoticeMinutes,
      severeWeatherAlerts:
          prefs.getBool(_severeWeatherAlertsKey) ??
          defaults.severeWeatherAlerts,
      upcomingReminders:
          prefs.getBool(_upcomingRemindersKey) ?? defaults.upcomingReminders,
      travelAlerts: prefs.getBool(_travelAlertsKey) ?? defaults.travelAlerts,
      travelMode: prefs.getString(_travelModeKey) ?? defaults.travelMode,
      directionsApp:
          prefs.getString(_directionsAppKey) ?? defaults.directionsApp,
      appIconBadge:
          prefs.getString(_appIconBadgeKey) ?? defaults.appIconBadge,
      appIconMatchTheme:
          prefs.getBool(_appIconMatchThemeKey) ?? defaults.appIconMatchTheme,
      textScale: prefs.getDouble(_textScaleKey) ?? defaults.textScale,
      secondaryCalendar: secondaryCalendarFromStorage(
        prefs.getString(_secondaryCalendarKey),
      ),
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
        case PreferenceKeys.timelineInvites:
          return current.copyWith(timelineInvites: value);
        case PreferenceKeys.shadeAlternateDays:
          return current.copyWith(shadeAlternateDays: value);
        case PreferenceKeys.shadePastDays:
          return current.copyWith(shadePastDays: value);
        case PreferenceKeys.shadeWeekends:
          return current.copyWith(shadeWeekends: value);
        case PreferenceKeys.shadeToday:
          return current.copyWith(shadeToday: value);
        case PreferenceKeys.heavyShading:
          return current.copyWith(heavyShading: value);
        case PreferenceKeys.cycleBusyDayEvents:
          return current.copyWith(cycleBusyDayEvents: value);
        case PreferenceKeys.dailyBriefing:
          return current.copyWith(dailyBriefing: value);
        case PreferenceKeys.rainAlerts:
          return current.copyWith(rainAlerts: value);
        case PreferenceKeys.severeWeatherAlerts:
          return current.copyWith(severeWeatherAlerts: value);
        case PreferenceKeys.upcomingReminders:
          return current.copyWith(upcomingReminders: value);
        case PreferenceKeys.travelAlerts:
          return current.copyWith(travelAlerts: value);
        case PreferenceKeys.appIconMatchTheme:
          return current.copyWith(appIconMatchTheme: value);
      }

      return current;
    });
  }

  Future<void> setIntPreference(String key, int value) {
    return _update((current) {
      switch (key) {
        case PreferenceKeys.daysAtAGlance:
          return current.copyWith(daysAtAGlance: value.clamp(3, 10));
        case PreferenceKeys.dailyBriefingHour:
          return current.copyWith(dailyBriefingHour: value.clamp(0, 23));
        case PreferenceKeys.dailyBriefingMinute:
          return current.copyWith(dailyBriefingMinute: value.clamp(0, 59));
        case PreferenceKeys.rainNoticeMinutes:
          return current.copyWith(rainNoticeMinutes: value.clamp(5, 60));
      }

      return current;
    });
  }

  Future<void> setStringPreference(String key, String value) {
    return _update((current) {
      switch (key) {
        case PreferenceKeys.timelineLayoutMode:
          return current.copyWith(timelineLayoutMode: value);
        case PreferenceKeys.rainAlertMode:
          return current.copyWith(rainAlertMode: value);
        case PreferenceKeys.travelMode:
          return current.copyWith(travelMode: value);
        case PreferenceKeys.directionsApp:
          return current.copyWith(directionsApp: value);
        case PreferenceKeys.appIconBadge:
          return current.copyWith(appIconBadge: value);
      }

      return current;
    });
  }

  Future<void> setTextScale(double value) {
    return _update((current) => current.copyWith(textScale: value));
  }

  Future<void> setSecondaryCalendar(SecondaryCalendar value) {
    return _update((current) => current.copyWith(secondaryCalendar: value));
  }

  Future<void> resetPreferences() async {
    final defaults = AppPreferences.defaults();
    state = AsyncData(defaults);
    await _save(defaults);
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
    await prefs.setBool(_timelineInvitesKey, preferences.timelineInvites);
    await prefs.setBool(
      _shadeAlternateDaysKey,
      preferences.shadeAlternateDays,
    );
    await prefs.setBool(_shadePastDaysKey, preferences.shadePastDays);
    await prefs.setBool(_shadeWeekendsKey, preferences.shadeWeekends);
    await prefs.setBool(_shadeTodayKey, preferences.shadeToday);
    await prefs.setBool(_heavyShadingKey, preferences.heavyShading);
    await prefs.setBool(
      _cycleBusyDayEventsKey,
      preferences.cycleBusyDayEvents,
    );
    await prefs.setInt(_daysAtAGlanceKey, preferences.daysAtAGlance);
    await prefs.setString(
      _timelineLayoutModeKey,
      preferences.timelineLayoutMode,
    );
    await prefs.setBool(_dailyBriefingKey, preferences.dailyBriefing);
    await prefs.setInt(_dailyBriefingHourKey, preferences.dailyBriefingHour);
    await prefs.setInt(
      _dailyBriefingMinuteKey,
      preferences.dailyBriefingMinute,
    );
    await prefs.setBool(_rainAlertsKey, preferences.rainAlerts);
    await prefs.setString(_rainAlertModeKey, preferences.rainAlertMode);
    await prefs.setInt(_rainNoticeMinutesKey, preferences.rainNoticeMinutes);
    await prefs.setBool(
      _severeWeatherAlertsKey,
      preferences.severeWeatherAlerts,
    );
    await prefs.setBool(_upcomingRemindersKey, preferences.upcomingReminders);
    await prefs.setBool(_travelAlertsKey, preferences.travelAlerts);
    await prefs.setString(_travelModeKey, preferences.travelMode);
    await prefs.setString(_directionsAppKey, preferences.directionsApp);
    await prefs.setString(_appIconBadgeKey, preferences.appIconBadge);
    await prefs.setBool(_appIconMatchThemeKey, preferences.appIconMatchTheme);
    await prefs.setDouble(_textScaleKey, preferences.textScale);
    await prefs.setString(
      _secondaryCalendarKey,
      preferences.secondaryCalendar.storageValue,
    );
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
  static const timelineInvites = AppPreferencesController._timelineInvitesKey;
  static const shadeAlternateDays =
      AppPreferencesController._shadeAlternateDaysKey;
  static const shadePastDays = AppPreferencesController._shadePastDaysKey;
  static const shadeWeekends = AppPreferencesController._shadeWeekendsKey;
  static const shadeToday = AppPreferencesController._shadeTodayKey;
  static const heavyShading = AppPreferencesController._heavyShadingKey;
  static const cycleBusyDayEvents =
      AppPreferencesController._cycleBusyDayEventsKey;
  static const daysAtAGlance = AppPreferencesController._daysAtAGlanceKey;
  static const timelineLayoutMode =
      AppPreferencesController._timelineLayoutModeKey;
  static const dailyBriefing = AppPreferencesController._dailyBriefingKey;
  static const dailyBriefingHour =
      AppPreferencesController._dailyBriefingHourKey;
  static const dailyBriefingMinute =
      AppPreferencesController._dailyBriefingMinuteKey;
  static const rainAlerts = AppPreferencesController._rainAlertsKey;
  static const rainAlertMode = AppPreferencesController._rainAlertModeKey;
  static const rainNoticeMinutes =
      AppPreferencesController._rainNoticeMinutesKey;
  static const severeWeatherAlerts =
      AppPreferencesController._severeWeatherAlertsKey;
  static const upcomingReminders =
      AppPreferencesController._upcomingRemindersKey;
  static const travelAlerts = AppPreferencesController._travelAlertsKey;
  static const travelMode = AppPreferencesController._travelModeKey;
  static const directionsApp = AppPreferencesController._directionsAppKey;
  static const appIconBadge = AppPreferencesController._appIconBadgeKey;
  static const appIconMatchTheme =
      AppPreferencesController._appIconMatchThemeKey;
}
