import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/home/domain/planner_models.dart';

class HolidayCountry {
  const HolidayCountry({required this.code, required this.name});
  final String code;
  final String name;
}

class HolidaysService {
  static const _calendarId = 'public_holidays';
  static const _calendarName = 'Public Holidays';
  static const Color _calendarColor = Color(0xFFE1C06C);
  static const _prefsPrefix = 'holidays_loaded_';
  // Bump _cacheVersion whenever the fallback list changes to invalidate
  // any previously cached country list on device.
  static const _cacheVersion = 2;
  static String get _countriesCacheKey => 'holidays_countries_cache_v$_cacheVersion';

  static HolidaysService? _instance;
  static HolidaysService get instance => _instance ??= HolidaysService._();
  HolidaysService._();

  List<HolidayCountry>? _countriesCache;

  // ── Country list ────────────────────────────────────────────────────────────

  /// Fetches available countries from Nager.Date; falls back to the built-in
  /// list on any network error. Result is cached in memory and SharedPreferences.
  Future<List<HolidayCountry>> availableCountries() async {
    if (_countriesCache != null) return _countriesCache!;

    // Try memory-less disk cache first.
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_countriesCacheKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        _countriesCache = list
            .map((e) => HolidayCountry(
                  code: e['code'] as String,
                  name: e['name'] as String,
                ))
            .toList();
        return _countriesCache!;
      }
    } catch (_) {}

    // Fetch live from Nager.Date and merge with fallback so no country
    // is ever missing (API may not include every country in the fallback).
    try {
      final res = await http
          .get(Uri.parse('https://date.nager.at/api/v3/AvailableCountries'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        final apiMap = <String, String>{};
        for (final e in list) {
          apiMap[e['countryCode'] as String] = e['name'] as String;
        }
        // Start with all fallback entries, then overlay any API names.
        final merged = <String, String>{
          for (final c in _fallbackCountries) c.code: c.name,
          ...apiMap,
        };
        _countriesCache = merged.entries
            .map((e) => HolidayCountry(code: e.key, name: e.value))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _countriesCacheKey,
          jsonEncode(_countriesCache!
              .map((c) => {'code': c.code, 'name': c.name})
              .toList()),
        );
        return _countriesCache!;
      }
    } catch (e) {
      debugPrint('HolidaysService: country list fetch failed: $e');
    }

    // Built-in fallback — comprehensive list sorted alphabetically.
    _countriesCache = _fallbackCountries;
    return _countriesCache!;
  }

  /// Returns the set of country codes whose holidays have already been loaded
  /// for [year].
  Future<Set<String>> loadedCountriesForYear(int year) async {
    final prefs = await SharedPreferences.getInstance();
    final all = prefs.getKeys();
    return all
        .where((k) => k.startsWith('$_prefsPrefix${year}_'))
        .map((k) => k.replaceFirst('$_prefsPrefix${year}_', ''))
        .toSet();
  }

  // ── Loading ──────────────────────────────────────────────────────────────────

  /// Auto-loads holidays for the device locale on first run of the year.
  Future<({PlannerCalendar calendar, List<PlannerEvent> events})?> loadForYear(
    int year,
    List<PlannerCalendar> existingCalendars,
  ) async {
    final countryCode = _detectCountryCode();
    final prefsKey = '$_prefsPrefix${year}_$countryCode';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(prefsKey) == true) return null;

    return _load(year, countryCode, existingCalendars, prefs, prefsKey);
  }

  /// Loads holidays for a specific country, always (used by manual picker).
  /// Does NOT skip already-loaded countries so users can re-add if needed.
  Future<({PlannerCalendar calendar, List<PlannerEvent> events})?> loadForCountry(
    int year,
    String countryCode,
    List<PlannerCalendar> existingCalendars,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final prefsKey = '$_prefsPrefix${year}_$countryCode';
    return _load(year, countryCode, existingCalendars, prefs, prefsKey);
  }

  Future<({PlannerCalendar calendar, List<PlannerEvent> events})?> _load(
    int year,
    String countryCode,
    List<PlannerCalendar> existingCalendars,
    SharedPreferences prefs,
    String prefsKey,
  ) async {
    final events = await _fetchHolidays(year, countryCode);
    if (events == null) return null;

    await prefs.setBool(prefsKey, true);

    return (
      calendar: const PlannerCalendar(
        id: _calendarId,
        name: _calendarName,
        color: _calendarColor,
      ),
      events: events,
    );
  }

  Future<List<PlannerEvent>?> _fetchHolidays(
      int year, String countryCode) async {
    try {
      final url = Uri.parse(
        'https://date.nager.at/api/v3/PublicHolidays/$year/$countryCode',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;

      final list = jsonDecode(res.body) as List<dynamic>;
      return list.map((item) {
        final map = item as Map<String, dynamic>;
        final date = DateTime.parse(map['date'] as String);
        final localName =
            map['localName'] as String? ?? map['name'] as String? ?? 'Holiday';
        final engName = map['name'] as String? ?? localName;
        // Include country code in id so events from different countries don't
        // collide even if they share the same date and local name.
        final id = 'holiday_${countryCode}_${date.toIso8601String()}_$localName';
        return PlannerEvent(
          id: id,
          title: localName,
          isAllDay: true,
          startAt: date,
          endAt: date,
          location: '',
          url: '',
          note: engName != localName ? engName : '',
          calendarId: _calendarId,
          reminder: PlannerReminder.none,
          repeatRule: PlannerRepeatRule.never,
          attendees: const [],
        );
      }).toList();
    } catch (e) {
      debugPrint('HolidaysService._fetchHolidays error: $e');
      return null;
    }
  }

  String _detectCountryCode() {
    try {
      final locale = Platform.localeName;
      final parts = locale.split('_');
      if (parts.length >= 2) {
        return parts[1].toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
      }
    } catch (_) {}
    return 'US';
  }

  // ── Fallback country list ────────────────────────────────────────────────────
  // Used when the network call to AvailableCountries fails.
  // Sourced from https://date.nager.at/api/v3/AvailableCountries (2024).
  static const List<HolidayCountry> _fallbackCountries = [
    HolidayCountry(code: 'AD', name: 'Andorra'),
    HolidayCountry(code: 'AE', name: 'United Arab Emirates'),
    HolidayCountry(code: 'AG', name: 'Antigua & Barbuda'),
    HolidayCountry(code: 'AI', name: 'Anguilla'),
    HolidayCountry(code: 'AL', name: 'Albania'),
    HolidayCountry(code: 'AM', name: 'Armenia'),
    HolidayCountry(code: 'AO', name: 'Angola'),
    HolidayCountry(code: 'AR', name: 'Argentina'),
    HolidayCountry(code: 'AT', name: 'Austria'),
    HolidayCountry(code: 'AU', name: 'Australia'),
    HolidayCountry(code: 'AW', name: 'Aruba'),
    HolidayCountry(code: 'AZ', name: 'Azerbaijan'),
    HolidayCountry(code: 'BA', name: 'Bosnia & Herzegovina'),
    HolidayCountry(code: 'BB', name: 'Barbados'),
    HolidayCountry(code: 'BD', name: 'Bangladesh'),
    HolidayCountry(code: 'BE', name: 'Belgium'),
    HolidayCountry(code: 'BG', name: 'Bulgaria'),
    HolidayCountry(code: 'BH', name: 'Bahrain'),
    HolidayCountry(code: 'BM', name: 'Bermuda'),
    HolidayCountry(code: 'BN', name: 'Brunei'),
    HolidayCountry(code: 'BO', name: 'Bolivia'),
    HolidayCountry(code: 'BR', name: 'Brazil'),
    HolidayCountry(code: 'BS', name: 'Bahamas'),
    HolidayCountry(code: 'BW', name: 'Botswana'),
    HolidayCountry(code: 'BY', name: 'Belarus'),
    HolidayCountry(code: 'BZ', name: 'Belize'),
    HolidayCountry(code: 'CA', name: 'Canada'),
    HolidayCountry(code: 'CH', name: 'Switzerland'),
    HolidayCountry(code: 'CL', name: 'Chile'),
    HolidayCountry(code: 'CM', name: 'Cameroon'),
    HolidayCountry(code: 'CN', name: 'China'),
    HolidayCountry(code: 'CO', name: 'Colombia'),
    HolidayCountry(code: 'CR', name: 'Costa Rica'),
    HolidayCountry(code: 'CU', name: 'Cuba'),
    HolidayCountry(code: 'CW', name: 'Curaçao'),
    HolidayCountry(code: 'CY', name: 'Cyprus'),
    HolidayCountry(code: 'CZ', name: 'Czech Republic'),
    HolidayCountry(code: 'DE', name: 'Germany'),
    HolidayCountry(code: 'DJ', name: 'Djibouti'),
    HolidayCountry(code: 'DK', name: 'Denmark'),
    HolidayCountry(code: 'DM', name: 'Dominica'),
    HolidayCountry(code: 'DO', name: 'Dominican Republic'),
    HolidayCountry(code: 'DZ', name: 'Algeria'),
    HolidayCountry(code: 'EC', name: 'Ecuador'),
    HolidayCountry(code: 'EE', name: 'Estonia'),
    HolidayCountry(code: 'EG', name: 'Egypt'),
    HolidayCountry(code: 'ES', name: 'Spain'),
    HolidayCountry(code: 'ET', name: 'Ethiopia'),
    HolidayCountry(code: 'FI', name: 'Finland'),
    HolidayCountry(code: 'FJ', name: 'Fiji'),
    HolidayCountry(code: 'FR', name: 'France'),
    HolidayCountry(code: 'GA', name: 'Gabon'),
    HolidayCountry(code: 'GB', name: 'United Kingdom'),
    HolidayCountry(code: 'GD', name: 'Grenada'),
    HolidayCountry(code: 'GE', name: 'Georgia'),
    HolidayCountry(code: 'GH', name: 'Ghana'),
    HolidayCountry(code: 'GI', name: 'Gibraltar'),
    HolidayCountry(code: 'GL', name: 'Greenland'),
    HolidayCountry(code: 'GM', name: 'Gambia'),
    HolidayCountry(code: 'GR', name: 'Greece'),
    HolidayCountry(code: 'GT', name: 'Guatemala'),
    HolidayCountry(code: 'GY', name: 'Guyana'),
    HolidayCountry(code: 'HK', name: 'Hong Kong'),
    HolidayCountry(code: 'HN', name: 'Honduras'),
    HolidayCountry(code: 'HR', name: 'Croatia'),
    HolidayCountry(code: 'HT', name: 'Haiti'),
    HolidayCountry(code: 'HU', name: 'Hungary'),
    HolidayCountry(code: 'ID', name: 'Indonesia'),
    HolidayCountry(code: 'IE', name: 'Ireland'),
    HolidayCountry(code: 'IL', name: 'Israel'),
    HolidayCountry(code: 'IM', name: 'Isle of Man'),
    HolidayCountry(code: 'IN', name: 'India'),
    HolidayCountry(code: 'IS', name: 'Iceland'),
    HolidayCountry(code: 'IT', name: 'Italy'),
    HolidayCountry(code: 'JM', name: 'Jamaica'),
    HolidayCountry(code: 'JO', name: 'Jordan'),
    HolidayCountry(code: 'JP', name: 'Japan'),
    HolidayCountry(code: 'KE', name: 'Kenya'),
    HolidayCountry(code: 'KR', name: 'South Korea'),
    HolidayCountry(code: 'KW', name: 'Kuwait'),
    HolidayCountry(code: 'KZ', name: 'Kazakhstan'),
    HolidayCountry(code: 'LA', name: 'Laos'),
    HolidayCountry(code: 'LB', name: 'Lebanon'),
    HolidayCountry(code: 'LC', name: 'Saint Lucia'),
    HolidayCountry(code: 'LI', name: 'Liechtenstein'),
    HolidayCountry(code: 'LK', name: 'Sri Lanka'),
    HolidayCountry(code: 'LR', name: 'Liberia'),
    HolidayCountry(code: 'LS', name: 'Lesotho'),
    HolidayCountry(code: 'LT', name: 'Lithuania'),
    HolidayCountry(code: 'LU', name: 'Luxembourg'),
    HolidayCountry(code: 'LV', name: 'Latvia'),
    HolidayCountry(code: 'MA', name: 'Morocco'),
    HolidayCountry(code: 'MC', name: 'Monaco'),
    HolidayCountry(code: 'MD', name: 'Moldova'),
    HolidayCountry(code: 'ME', name: 'Montenegro'),
    HolidayCountry(code: 'MG', name: 'Madagascar'),
    HolidayCountry(code: 'MK', name: 'North Macedonia'),
    HolidayCountry(code: 'MM', name: 'Myanmar'),
    HolidayCountry(code: 'MN', name: 'Mongolia'),
    HolidayCountry(code: 'MO', name: 'Macau'),
    HolidayCountry(code: 'MT', name: 'Malta'),
    HolidayCountry(code: 'MU', name: 'Mauritius'),
    HolidayCountry(code: 'MW', name: 'Malawi'),
    HolidayCountry(code: 'MX', name: 'Mexico'),
    HolidayCountry(code: 'MY', name: 'Malaysia'),
    HolidayCountry(code: 'MZ', name: 'Mozambique'),
    HolidayCountry(code: 'NA', name: 'Namibia'),
    HolidayCountry(code: 'NE', name: 'Niger'),
    HolidayCountry(code: 'NG', name: 'Nigeria'),
    HolidayCountry(code: 'NI', name: 'Nicaragua'),
    HolidayCountry(code: 'NL', name: 'Netherlands'),
    HolidayCountry(code: 'NO', name: 'Norway'),
    HolidayCountry(code: 'NP', name: 'Nepal'),
    HolidayCountry(code: 'NZ', name: 'New Zealand'),
    HolidayCountry(code: 'OM', name: 'Oman'),
    HolidayCountry(code: 'PA', name: 'Panama'),
    HolidayCountry(code: 'PE', name: 'Peru'),
    HolidayCountry(code: 'PG', name: 'Papua New Guinea'),
    HolidayCountry(code: 'PH', name: 'Philippines'),
    HolidayCountry(code: 'PK', name: 'Pakistan'),
    HolidayCountry(code: 'PL', name: 'Poland'),
    HolidayCountry(code: 'PT', name: 'Portugal'),
    HolidayCountry(code: 'PY', name: 'Paraguay'),
    HolidayCountry(code: 'QA', name: 'Qatar'),
    HolidayCountry(code: 'RO', name: 'Romania'),
    HolidayCountry(code: 'RS', name: 'Serbia'),
    HolidayCountry(code: 'RU', name: 'Russia'),
    HolidayCountry(code: 'RW', name: 'Rwanda'),
    HolidayCountry(code: 'SA', name: 'Saudi Arabia'),
    HolidayCountry(code: 'SC', name: 'Seychelles'),
    HolidayCountry(code: 'SD', name: 'Sudan'),
    HolidayCountry(code: 'SE', name: 'Sweden'),
    HolidayCountry(code: 'SG', name: 'Singapore'),
    HolidayCountry(code: 'SI', name: 'Slovenia'),
    HolidayCountry(code: 'SK', name: 'Slovakia'),
    HolidayCountry(code: 'SL', name: 'Sierra Leone'),
    HolidayCountry(code: 'SM', name: 'San Marino'),
    HolidayCountry(code: 'SO', name: 'Somalia'),
    HolidayCountry(code: 'SR', name: 'Suriname'),
    HolidayCountry(code: 'SS', name: 'South Sudan'),
    HolidayCountry(code: 'SV', name: 'El Salvador'),
    HolidayCountry(code: 'SZ', name: 'Eswatini'),
    HolidayCountry(code: 'TG', name: 'Togo'),
    HolidayCountry(code: 'TH', name: 'Thailand'),
    HolidayCountry(code: 'TJ', name: 'Tajikistan'),
    HolidayCountry(code: 'TL', name: 'Timor-Leste'),
    HolidayCountry(code: 'TM', name: 'Turkmenistan'),
    HolidayCountry(code: 'TN', name: 'Tunisia'),
    HolidayCountry(code: 'TO', name: 'Tonga'),
    HolidayCountry(code: 'TR', name: 'Turkey'),
    HolidayCountry(code: 'TT', name: 'Trinidad & Tobago'),
    HolidayCountry(code: 'TW', name: 'Taiwan'),
    HolidayCountry(code: 'TZ', name: 'Tanzania'),
    HolidayCountry(code: 'UA', name: 'Ukraine'),
    HolidayCountry(code: 'UG', name: 'Uganda'),
    HolidayCountry(code: 'US', name: 'United States'),
    HolidayCountry(code: 'UY', name: 'Uruguay'),
    HolidayCountry(code: 'UZ', name: 'Uzbekistan'),
    HolidayCountry(code: 'VA', name: 'Vatican City'),
    HolidayCountry(code: 'VE', name: 'Venezuela'),
    HolidayCountry(code: 'VN', name: 'Vietnam'),
    HolidayCountry(code: 'WS', name: 'Samoa'),
    HolidayCountry(code: 'YE', name: 'Yemen'),
    HolidayCountry(code: 'ZA', name: 'South Africa'),
    HolidayCountry(code: 'ZM', name: 'Zambia'),
    HolidayCountry(code: 'ZW', name: 'Zimbabwe'),
  ];
}
