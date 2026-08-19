/// Bidirectional conversion between the Gregorian and Ethiopian (Geʼez)
/// calendars, via the Julian Day Number (JDN).
///
/// The Ethiopian calendar has 12 months of 30 days plus a 13th month, Pagumē,
/// of 5 days (6 in a leap year - every year where `year % 4 == 3`). Its New Year
/// (Meskerem 1) lands on Gregorian Sep 11, or Sep 12 in the year before a
/// Gregorian leap year; this conversion handles that shift automatically because
/// it works purely in JDN space.
///
/// Verified anchors: Meskerem 1, 2017 = 2024-09-11; Megabit 20, 2017 =
/// 2025-03-29; Meskerem 1, 2020 = 2027-09-12 (a Sep-12 year).
class EthiopianDate {
  const EthiopianDate(this.year, this.month, this.day);

  /// Amete Mihret year.
  final int year;

  /// 1..13 (13 = Pagumē).
  final int month;

  /// 1..30 (1..5 or 1..6 for Pagumē).
  final int day;

  /// JDN of Meskerem 1, year 1 (Amete Mihret).
  static const int _epochJdn = 1724221;

  static const List<String> monthNames = <String>[
    'Meskerem',
    'Tikimt',
    'Hidar',
    'Tahsas',
    'Tir',
    'Yekatit',
    'Megabit',
    'Miyazya',
    'Ginbot',
    'Sene',
    'Hamle',
    'Nehase',
    'Pagʻume', // Pag'ume
  ];

  String get monthName => monthNames[month - 1];

  /// e.g. "Megabit 20, 2017".
  String get formatted => '$monthName $day, $year';

  /// True when [year] carries the leap day (Pagumē 6).
  bool get isLeapYear => year % 4 == 3;

  /// The JDN at the start (Meskerem 1) of Ethiopian [year].
  static int _yearStartJdn(int year) =>
      _epochJdn + 365 * (year - 1) + _floorDiv(year, 4);

  /// Convert a Gregorian calendar date (its year/month/day, ignoring time) to
  /// the Ethiopian calendar.
  factory EthiopianDate.fromGregorian(DateTime date) {
    final jdn = _gregorianToJdn(date.year, date.month, date.day);
    final days = jdn - _epochJdn; // 0-based day index from Meskerem 1, year 1

    // Estimate the year, then correct for the leap-day phase.
    var year = _floorDiv(days * 4, 1461) + 1;
    while (_yearStartJdn(year) - _epochJdn > days) {
      year--;
    }
    while (_yearStartJdn(year + 1) - _epochJdn <= days) {
      year++;
    }

    final dayOfYear = days - (_yearStartJdn(year) - _epochJdn); // 0-based
    final month = dayOfYear ~/ 30 + 1;
    final day = dayOfYear % 30 + 1;
    return EthiopianDate(year, month, day);
  }

  /// The Gregorian [DateTime] (at midnight) for this Ethiopian date.
  DateTime toGregorian() {
    final jdn = _yearStartJdn(year) + 30 * (month - 1) + (day - 1);
    return _jdnToGregorian(jdn);
  }

  // ── JDN helpers (standard Gregorian algorithms) ──────────────────────────────

  static int _floorDiv(int a, int b) => (a - ((a % b) + b) % b) ~/ b;

  static int _gregorianToJdn(int y, int m, int d) {
    final a = (14 - m) ~/ 12;
    final yy = y + 4800 - a;
    final mm = m + 12 * a - 3;
    return d +
        (153 * mm + 2) ~/ 5 +
        365 * yy +
        yy ~/ 4 -
        yy ~/ 100 +
        yy ~/ 400 -
        32045;
  }

  static DateTime _jdnToGregorian(int jdn) {
    final a = jdn + 32044;
    final b = (4 * a + 3) ~/ 146097;
    final c = a - (146097 * b) ~/ 4;
    final d = (4 * c + 3) ~/ 1461;
    final e = c - (1461 * d) ~/ 4;
    final m = (5 * e + 2) ~/ 153;
    final day = e - (153 * m + 2) ~/ 5 + 1;
    final month = m + 3 - 12 * (m ~/ 10);
    final year = 100 * b + d - 4800 + m ~/ 10;
    return DateTime(year, month, day);
  }
}
