import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/home/domain/planner_models.dart';
import 'ethiopian_holidays.dart';

class HolidayCountry {
  const HolidayCountry({required this.code, required this.name});
  final String code;
  final String name;
}

/// The outcome of loading public holidays: the calendar they belong to, the
/// events, and which country/year they were fetched for (so the caller can mark
/// the year loaded only after persisting them).
typedef HolidayLoadResult = ({
  PlannerCalendar calendar,
  List<PlannerEvent> events,
  String countryCode,
  int year,
});

class HolidaysService {
  static const _calendarId = 'public_holidays';
  static const _calendarName = 'Public Holidays';
  static const Color _calendarColor = Color(0xFFE1C06C);
  static const _prefsPrefix = 'holidays_loaded_';
  // Bump _cacheVersion whenever the fallback list changes to invalidate
  // any previously cached country list on device.
  static const _cacheVersion = 4;
  static String get _countriesCacheKey => 'holidays_countries_cache_v$_cacheVersion';
  // Refresh the cached country list at most this often so new Nager.Date
  // countries eventually show up without a fetch on every launch.
  static const _countriesCacheTtl = Duration(days: 30);

  // Countries we serve from a built-in/computed source rather than Nager.Date.
  // These are always offered in the picker, regardless of the online list.
  static const List<HolidayCountry> _builtInCountries = [
    HolidayCountry(
      code: EthiopianHolidays.countryCode,
      name: EthiopianHolidays.countryName,
    ),
  ];

  static HolidaysService? _instance;
  static HolidaysService get instance => _instance ??= HolidaysService._();
  HolidaysService._();

  List<HolidayCountry>? _countriesCache;

  /// Adds the built-in countries to [base] (deduping by code) and sorts by name,
  /// so locally-supported countries always appear in the picker.
  List<HolidayCountry> _withBuiltIns(List<HolidayCountry> base) {
    final byCode = {for (final c in base) c.code: c};
    for (final c in _builtInCountries) {
      byCode.putIfAbsent(c.code, () => c);
    }
    return byCode.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  // ── Country list ────────────────────────────────────────────────────────────

  /// Fetches available countries from Nager.Date; falls back to the built-in
  /// list on any network error. Result is cached in memory and SharedPreferences.
  Future<List<HolidayCountry>> availableCountries() async {
    if (_countriesCache != null) return _countriesCache!;

    // Try memory-less disk cache first, but only if it's still fresh.
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_countriesCacheKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final fetchedAt = decoded['fetched_at'] as int? ?? 0;
        final age = DateTime.now().millisecondsSinceEpoch - fetchedAt;
        if (age >= 0 && age < _countriesCacheTtl.inMilliseconds) {
          final list = decoded['countries'] as List<dynamic>;
          _countriesCache = _withBuiltIns(list
              .map((e) => HolidayCountry(
                    code: e['code'] as String,
                    name: e['name'] as String,
                  ))
              .toList());
          return _countriesCache!;
        }
      }
    } catch (_) {}

    // Fetch the live list from Nager.Date. This is the AUTHORITATIVE set of
    // countries that actually have holiday data — we must NOT union it with the
    // built-in fallback, or we'd offer countries the provider can't serve (e.g.
    // Ethiopia), whose holiday endpoint returns 204/empty so nothing appears.
    try {
      final res = await http
          .get(Uri.parse('https://date.nager.at/api/v3/AvailableCountries'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        final live = list
            .map((e) => HolidayCountry(
                  code: e['countryCode'] as String,
                  name: e['name'] as String,
                ))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        // Cache the pure live list; built-ins are layered in on every read.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _countriesCacheKey,
          jsonEncode({
            'fetched_at': DateTime.now().millisecondsSinceEpoch,
            'countries':
                live.map((c) => {'code': c.code, 'name': c.name}).toList(),
          }),
        );
        _countriesCache = _withBuiltIns(live);
        return _countriesCache!;
      }
    } catch (e) {
      debugPrint('HolidaysService: country list fetch failed: $e');
    }

    // Offline fallback — the built-in supported list plus local countries.
    _countriesCache = _withBuiltIns(_fallbackCountries);
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
  Future<HolidayLoadResult?> loadForYear(
    int year,
    List<PlannerCalendar> existingCalendars,
  ) async {
    final countryCode = _detectCountryCode();
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('$_prefsPrefix${year}_$countryCode') == true) return null;

    return _load(year, countryCode);
  }

  /// Loads holidays for a specific country, always (used by manual picker).
  /// Does NOT skip already-loaded countries so users can re-add if needed.
  Future<HolidayLoadResult?> loadForCountry(
    int year,
    String countryCode,
    List<PlannerCalendar> existingCalendars,
  ) async {
    return _load(year, countryCode);
  }

  Future<HolidayLoadResult?> _load(int year, String countryCode) async {
    final events = await _fetchHolidays(year, countryCode);
    if (events == null) return null;

    // NOTE: we intentionally do NOT mark the year as loaded here. The "loaded"
    // flag must only be set once the events have been durably persisted (see
    // [markYearLoaded]); otherwise — e.g. in cloud-sync mode where saving is a
    // no-op — the holidays would vanish on restart yet never be re-fetched.
    return (
      calendar: const PlannerCalendar(
        id: _calendarId,
        name: _calendarName,
        color: _calendarColor,
      ),
      events: events,
      countryCode: countryCode,
      year: year,
    );
  }

  /// Records that [countryCode]'s holidays for [year] have been durably stored,
  /// so auto-load won't re-fetch them on the next launch.
  Future<void> markYearLoaded(int year, String countryCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefsPrefix${year}_$countryCode', true);
  }

  Future<List<PlannerEvent>?> _fetchHolidays(
      int year, String countryCode) async {
    // Countries Nager.Date can't serve are produced from a built-in source.
    if (EthiopianHolidays.supports(countryCode)) {
      return EthiopianHolidays.forYear(year)
          .map((h) => _holidayEvent(countryCode, h.date, h.name, h.name))
          .toList();
    }

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
        return _holidayEvent(countryCode, date, localName, engName);
      }).toList();
    } catch (e) {
      debugPrint('HolidaysService._fetchHolidays error: $e');
      return null;
    }
  }

  PlannerEvent _holidayEvent(
    String countryCode,
    DateTime date,
    String localName,
    String engName,
  ) {
    final day = DateTime(date.year, date.month, date.day);
    // Include country code in id so events from different countries don't
    // collide even if they share the same date and local name.
    final id = 'holiday_${countryCode}_${day.toIso8601String()}_$localName';
    return PlannerEvent(
      id: id,
      title: localName,
      isAllDay: true,
      startAt: day,
      endAt: day,
      location: '',
      url: '',
      note: engName != localName ? engName : '',
      calendarId: _calendarId,
      reminder: PlannerReminder.none,
      repeatRule: PlannerRepeatRule.never,
      attendees: const [],
    );
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
  // The exact set of countries Nager.Date supports, used when the live call to
  // AvailableCountries fails. This must stay limited to countries the provider
  // actually serves — listing unsupported ones (e.g. Ethiopia) only offers
  // choices whose holiday endpoint returns 204/empty, so nothing would appear.
  // Names are ASCII-normalised; the live list may show localised spellings.
  // Sourced from https://date.nager.at/api/v3/AvailableCountries.
  static const List<HolidayCountry> _fallbackCountries = [
    HolidayCountry(code: "AX", name: "Aland Islands"),
    HolidayCountry(code: "AL", name: "Albania"),
    HolidayCountry(code: "AD", name: "Andorra"),
    HolidayCountry(code: "AO", name: "Angola"),
    HolidayCountry(code: "AR", name: "Argentina"),
    HolidayCountry(code: "AM", name: "Armenia"),
    HolidayCountry(code: "AU", name: "Australia"),
    HolidayCountry(code: "AT", name: "Austria"),
    HolidayCountry(code: "BS", name: "Bahamas"),
    HolidayCountry(code: "BD", name: "Bangladesh"),
    HolidayCountry(code: "BB", name: "Barbados"),
    HolidayCountry(code: "BY", name: "Belarus"),
    HolidayCountry(code: "BE", name: "Belgium"),
    HolidayCountry(code: "BZ", name: "Belize"),
    HolidayCountry(code: "BJ", name: "Benin"),
    HolidayCountry(code: "BO", name: "Bolivia"),
    HolidayCountry(code: "BA", name: "Bosnia and Herzegovina"),
    HolidayCountry(code: "BW", name: "Botswana"),
    HolidayCountry(code: "BR", name: "Brazil"),
    HolidayCountry(code: "BG", name: "Bulgaria"),
    HolidayCountry(code: "CA", name: "Canada"),
    HolidayCountry(code: "CL", name: "Chile"),
    HolidayCountry(code: "CN", name: "China"),
    HolidayCountry(code: "CO", name: "Colombia"),
    HolidayCountry(code: "CG", name: "Congo"),
    HolidayCountry(code: "CR", name: "Costa Rica"),
    HolidayCountry(code: "HR", name: "Croatia"),
    HolidayCountry(code: "CU", name: "Cuba"),
    HolidayCountry(code: "CY", name: "Cyprus"),
    HolidayCountry(code: "CZ", name: "Czechia"),
    HolidayCountry(code: "CD", name: "DR Congo"),
    HolidayCountry(code: "DK", name: "Denmark"),
    HolidayCountry(code: "DO", name: "Dominican Republic"),
    HolidayCountry(code: "EC", name: "Ecuador"),
    HolidayCountry(code: "EG", name: "Egypt"),
    HolidayCountry(code: "SV", name: "El Salvador"),
    HolidayCountry(code: "EE", name: "Estonia"),
    HolidayCountry(code: "FO", name: "Faroe Islands"),
    HolidayCountry(code: "FI", name: "Finland"),
    HolidayCountry(code: "FR", name: "France"),
    HolidayCountry(code: "GA", name: "Gabon"),
    HolidayCountry(code: "GM", name: "Gambia"),
    HolidayCountry(code: "GE", name: "Georgia"),
    HolidayCountry(code: "DE", name: "Germany"),
    HolidayCountry(code: "GH", name: "Ghana"),
    HolidayCountry(code: "GI", name: "Gibraltar"),
    HolidayCountry(code: "GR", name: "Greece"),
    HolidayCountry(code: "GL", name: "Greenland"),
    HolidayCountry(code: "GD", name: "Grenada"),
    HolidayCountry(code: "GT", name: "Guatemala"),
    HolidayCountry(code: "GG", name: "Guernsey"),
    HolidayCountry(code: "GY", name: "Guyana"),
    HolidayCountry(code: "HT", name: "Haiti"),
    HolidayCountry(code: "HN", name: "Honduras"),
    HolidayCountry(code: "HK", name: "Hong Kong"),
    HolidayCountry(code: "HU", name: "Hungary"),
    HolidayCountry(code: "IS", name: "Iceland"),
    HolidayCountry(code: "ID", name: "Indonesia"),
    HolidayCountry(code: "IE", name: "Ireland"),
    HolidayCountry(code: "IM", name: "Isle of Man"),
    HolidayCountry(code: "IT", name: "Italy"),
    HolidayCountry(code: "JM", name: "Jamaica"),
    HolidayCountry(code: "JP", name: "Japan"),
    HolidayCountry(code: "JE", name: "Jersey"),
    HolidayCountry(code: "KZ", name: "Kazakhstan"),
    HolidayCountry(code: "KE", name: "Kenya"),
    HolidayCountry(code: "LV", name: "Latvia"),
    HolidayCountry(code: "LS", name: "Lesotho"),
    HolidayCountry(code: "LI", name: "Liechtenstein"),
    HolidayCountry(code: "LT", name: "Lithuania"),
    HolidayCountry(code: "LU", name: "Luxembourg"),
    HolidayCountry(code: "MG", name: "Madagascar"),
    HolidayCountry(code: "MT", name: "Malta"),
    HolidayCountry(code: "MX", name: "Mexico"),
    HolidayCountry(code: "MD", name: "Moldova"),
    HolidayCountry(code: "MC", name: "Monaco"),
    HolidayCountry(code: "MN", name: "Mongolia"),
    HolidayCountry(code: "ME", name: "Montenegro"),
    HolidayCountry(code: "MS", name: "Montserrat"),
    HolidayCountry(code: "MA", name: "Morocco"),
    HolidayCountry(code: "MZ", name: "Mozambique"),
    HolidayCountry(code: "NA", name: "Namibia"),
    HolidayCountry(code: "NL", name: "Netherlands"),
    HolidayCountry(code: "NZ", name: "New Zealand"),
    HolidayCountry(code: "NI", name: "Nicaragua"),
    HolidayCountry(code: "NE", name: "Niger"),
    HolidayCountry(code: "NG", name: "Nigeria"),
    HolidayCountry(code: "MK", name: "North Macedonia"),
    HolidayCountry(code: "NO", name: "Norway"),
    HolidayCountry(code: "PA", name: "Panama"),
    HolidayCountry(code: "PG", name: "Papua New Guinea"),
    HolidayCountry(code: "PY", name: "Paraguay"),
    HolidayCountry(code: "PE", name: "Peru"),
    HolidayCountry(code: "PH", name: "Philippines"),
    HolidayCountry(code: "PL", name: "Poland"),
    HolidayCountry(code: "PT", name: "Portugal"),
    HolidayCountry(code: "PR", name: "Puerto Rico"),
    HolidayCountry(code: "RO", name: "Romania"),
    HolidayCountry(code: "RU", name: "Russia"),
    HolidayCountry(code: "SM", name: "San Marino"),
    HolidayCountry(code: "RS", name: "Serbia"),
    HolidayCountry(code: "SC", name: "Seychelles"),
    HolidayCountry(code: "SG", name: "Singapore"),
    HolidayCountry(code: "SK", name: "Slovakia"),
    HolidayCountry(code: "SI", name: "Slovenia"),
    HolidayCountry(code: "ZA", name: "South Africa"),
    HolidayCountry(code: "KR", name: "South Korea"),
    HolidayCountry(code: "ES", name: "Spain"),
    HolidayCountry(code: "SR", name: "Suriname"),
    HolidayCountry(code: "SJ", name: "Svalbard and Jan Mayen"),
    HolidayCountry(code: "SE", name: "Sweden"),
    HolidayCountry(code: "CH", name: "Switzerland"),
    HolidayCountry(code: "TN", name: "Tunisia"),
    HolidayCountry(code: "TR", name: "Turkiye"),
    HolidayCountry(code: "UG", name: "Uganda"),
    HolidayCountry(code: "UA", name: "Ukraine"),
    HolidayCountry(code: "GB", name: "United Kingdom"),
    HolidayCountry(code: "US", name: "United States"),
    HolidayCountry(code: "UY", name: "Uruguay"),
    HolidayCountry(code: "VA", name: "Vatican City"),
    HolidayCountry(code: "VE", name: "Venezuela"),
    HolidayCountry(code: "VN", name: "Vietnam"),
    HolidayCountry(code: "ZW", name: "Zimbabwe"),
  ];
}
