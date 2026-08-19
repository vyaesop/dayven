import '../calendars/ethiopian_calendar.dart';

/// Built-in public holidays for Ethiopia.
///
/// Nager.Date (our online holiday source) does not cover Ethiopia, so these are
/// curated/computed in-app. There are three kinds:
///
///  * **Fixed civil/solar holidays** - published every year on the same
///    Gregorian date (e.g. Adwa Victory Day, Ethiopian Christmas). The Ethiopian
///    Orthodox fixed feasts (Christmas Jan 7, Timkat Jan 19, New Year Sep 11,
///    Meskel Sep 27) track the Julian↔Gregorian offset, which is constant for
///    1900–2099, so they are emitted as fixed dates here.
///  * **Movable Orthodox feasts** - Good Friday and Easter (Fasika) are computed
///    from the Orthodox (Julian) Easter computus, so they are exact for any year.
///  * **Movable Islamic holidays** - Eid al-Fitr, Eid al-Adha and Mawlid follow
///    the lunar Hijri calendar and depend on local moon sighting, so they cannot
///    be computed reliably. They are provided from a curated table for the years
///    below and may differ by a day from the officially announced date.
class EthiopianHoliday {
  const EthiopianHoliday({required this.date, required this.name});
  final DateTime date;
  final String name;
}

class EthiopianHolidays {
  EthiopianHolidays._();

  static const String countryCode = 'ET';
  static const String countryName = 'Ethiopia';

  static bool supports(String code) => code.toUpperCase() == countryCode;

  /// The range of years for which the (table-based) Islamic holidays are
  /// available. Solar and Orthodox feasts are produced for any year.
  static const int islamicTableFirstYear = 2024;
  static const int islamicTableLastYear = 2030;

  /// All Ethiopian public holidays that fall within the Gregorian [year].
  static List<EthiopianHoliday> forYear(int year) {
    final holidays = <EthiopianHoliday>[
      // Christmas and Timkat track the Julian Nativity/Epiphany, which map to a
      // constant Gregorian Jan 7 / Jan 19 for 1900–2099 (their *Ethiopian* day
      // number shifts between Tahsas 28/29, but the Gregorian date does not).
      EthiopianHoliday(date: DateTime(year, 1, 7), name: 'Ethiopian Christmas (Genna)'),
      EthiopianHoliday(date: DateTime(year, 1, 19), name: 'Timkat (Epiphany)'),
      // ── Fixed civil holidays ──
      EthiopianHoliday(date: DateTime(year, 3, 2), name: 'Adwa Victory Day'),
      EthiopianHoliday(date: DateTime(year, 5, 1), name: 'International Labour Day'),
      EthiopianHoliday(date: DateTime(year, 5, 5), name: "Patriots' Victory Day"),
      EthiopianHoliday(date: DateTime(year, 5, 28), name: 'Downfall of the Derg'),
      // New Year and Meskel are tied to the Ethiopian calendar, so their
      // Gregorian date shifts (Sep 11/12, Sep 27/28). Compute them from the
      // calendar conversion so they stay exact and consistent with the
      // secondary-calendar date shown in the UI. They belong to the Ethiopian
      // year that starts this September (year - 7).
      EthiopianHoliday(
        date: EthiopianDate(year - 7, 1, 1).toGregorian(),
        name: 'Ethiopian New Year (Enkutatash)',
      ),
      EthiopianHoliday(
        date: EthiopianDate(year - 7, 1, 17).toGregorian(),
        name: 'Finding of the True Cross (Meskel)',
      ),
    ];

    // ── Movable Orthodox feasts (exact) ──
    final easter = _orthodoxEaster(year);
    holidays.add(EthiopianHoliday(
      date: easter.subtract(const Duration(days: 2)),
      name: 'Ethiopian Good Friday (Siklet)',
    ));
    holidays.add(EthiopianHoliday(date: easter, name: 'Ethiopian Easter (Fasika)'));

    // ── Movable Islamic holidays (curated table, approximate) ──
    final fitr = _eidAlFitr[year];
    if (fitr != null) {
      holidays.add(EthiopianHoliday(
        date: DateTime(year, fitr.$1, fitr.$2),
        name: 'Eid al-Fitr',
      ));
    }
    final adha = _eidAlAdha[year];
    if (adha != null) {
      holidays.add(EthiopianHoliday(
        date: DateTime(year, adha.$1, adha.$2),
        name: 'Eid al-Adha (Arefa)',
      ));
    }
    final mawlid = _mawlid[year];
    if (mawlid != null) {
      holidays.add(EthiopianHoliday(
        date: DateTime(year, mawlid.$1, mawlid.$2),
        name: "Mawlid (Prophet's Birthday)",
      ));
    }

    holidays.sort((a, b) => a.date.compareTo(b.date));
    return holidays;
  }

  /// Orthodox (Julian) Easter Sunday expressed as a Gregorian date. Uses Meeus's
  /// Julian algorithm, then applies the Julian→Gregorian offset of 13 days,
  /// which is constant for all years 1900–2099.
  static DateTime _orthodoxEaster(int year) {
    final a = year % 4;
    final b = year % 7;
    final c = year % 19;
    final d = (19 * c + 15) % 30;
    final e = (2 * a + 4 * b - d + 34) % 7;
    final month = (d + e + 114) ~/ 31; // 3 = March, 4 = April (Julian)
    final day = ((d + e + 114) % 31) + 1;
    // Treat the Julian Easter date as Gregorian and shift by the 13-day offset.
    return DateTime(year, month, day).add(const Duration(days: 13));
  }

  // Islamic holiday dates as (month, day) per Gregorian year. These are
  // estimates based on the Umm al-Qura calendar; the date observed in Ethiopia
  // can differ by ±1 day depending on the local moon sighting.
  static const Map<int, (int, int)> _eidAlFitr = {
    2024: (4, 10),
    2025: (3, 31),
    2026: (3, 20),
    2027: (3, 10),
    2028: (2, 26),
    2029: (2, 14),
    2030: (2, 5),
  };

  static const Map<int, (int, int)> _eidAlAdha = {
    2024: (6, 16),
    2025: (6, 6),
    2026: (5, 27),
    2027: (5, 16),
    2028: (5, 5),
    2029: (4, 24),
    2030: (4, 13),
  };

  static const Map<int, (int, int)> _mawlid = {
    2024: (9, 15),
    2025: (9, 4),
    2026: (8, 25),
    2027: (8, 14),
    2028: (8, 3),
    2029: (7, 24),
    2030: (7, 13),
  };
}
