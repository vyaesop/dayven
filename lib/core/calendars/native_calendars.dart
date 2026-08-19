/// Conversions from the Gregorian calendar to the other native calendar systems
/// Dayven supports as a secondary date. Each type exposes `fromGregorian` and a
/// `formatted` label. Algorithms are standard/arithmetic (no astronomical
/// observation), which is the convention for civil calendar display.
///
/// See also [EthiopianDate] in `ethiopian_calendar.dart`.
library;

int _floorDiv(int a, int b) => (a - ((a % b) + b) % b) ~/ b;

/// Julian Day Number for a proleptic-Gregorian date (midnight).
int gregorianToJdn(int y, int m, int d) {
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

// ─── Hijri (tabular / civil Islamic) ─────────────────────────────────────────

/// Tabular ("civil", Kuwaiti algorithm) Islamic calendar. This is an arithmetic
/// approximation - it can differ from observed/Umm al-Qura dates by ±1 day - but
/// it is deterministic and standard for civil display.
class HijriDate {
  const HijriDate(this.year, this.month, this.day);

  final int year;
  final int month; // 1..12
  final int day; // 1..30

  static const List<String> monthNames = <String>[
    'Muharram',
    'Safar',
    "Rabi' al-awwal",
    "Rabi' al-thani",
    'Jumada al-awwal',
    'Jumada al-thani',
    'Rajab',
    "Sha'ban",
    'Ramadan',
    'Shawwal',
    "Dhu al-Qi'dah",
    'Dhu al-Hijjah',
  ];

  String get monthName => monthNames[month - 1];

  /// e.g. "Ramadan 12, 1447 AH".
  String get formatted => '$monthName $day, $year AH';

  factory HijriDate.fromGregorian(DateTime date) {
    final jdn = gregorianToJdn(date.year, date.month, date.day);
    // Kuwaiti algorithm (tabular civil epoch JDN 1948440 = 1 Muharram 1 AH).
    var l = jdn - 1948440 + 10632;
    final n = (l - 1) ~/ 10631;
    l = l - 10631 * n + 354;
    final j = ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) +
        (l ~/ 5670) * ((43 * l) ~/ 15238);
    l = l -
        ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
        (j ~/ 16) * ((15238 * j) ~/ 43) +
        29;
    final month = (24 * l) ~/ 709;
    final day = l - (709 * month) ~/ 24;
    final year = 30 * n + j - 30;
    return HijriDate(year, month, day);
  }
}

// ─── Persian (Solar Hijri / Jalali) ──────────────────────────────────────────

/// Solar Hijri (Jalali) calendar used in Iran and Afghanistan. Arithmetic
/// algorithm (Jalaali), accurate for the supported civil range.
class PersianDate {
  const PersianDate(this.year, this.month, this.day);

  final int year;
  final int month; // 1..12
  final int day; // 1..31

  static const List<String> monthNames = <String>[
    'Farvardin',
    'Ordibehesht',
    'Khordad',
    'Tir',
    'Mordad',
    'Shahrivar',
    'Mehr',
    'Aban',
    'Azar',
    'Dey',
    'Bahman',
    'Esfand',
  ];

  String get monthName => monthNames[month - 1];

  /// e.g. "Farvardin 1, 1403".
  String get formatted => '$monthName $day, $year';

  factory PersianDate.fromGregorian(DateTime date) {
    final gy = date.year;
    final gm = date.month;
    final gd = date.day;
    const gDaysInMonth = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    final gy2 = (gm > 2) ? gy + 1 : gy;
    var days = 355666 +
        365 * gy +
        ((gy2 + 3) ~/ 4) -
        ((gy2 + 99) ~/ 100) +
        ((gy2 + 399) ~/ 400) +
        gd +
        gDaysInMonth[gm - 1];
    var jy = -1595 + 33 * (days ~/ 12053);
    days %= 12053;
    jy += 4 * (days ~/ 1461);
    days %= 1461;
    if (days > 365) {
      jy += (days - 1) ~/ 365;
      days = (days - 1) % 365;
    }
    final int jm;
    final int jd;
    if (days < 186) {
      jm = 1 + (days ~/ 31);
      jd = 1 + (days % 31);
    } else {
      jm = 7 + ((days - 186) ~/ 30);
      jd = 1 + ((days - 186) % 30);
    }
    return PersianDate(jy, jm, jd);
  }
}

// ─── Buddhist (Thai solar) ───────────────────────────────────────────────────

/// Thai Buddhist calendar: identical month/day to Gregorian, year + 543 (the
/// Buddhist Era).
class BuddhistDate {
  const BuddhistDate(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  static const List<String> monthNames = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String get monthName => monthNames[month - 1];

  /// e.g. "March 29, 2569 BE".
  String get formatted => '$monthName $day, $year BE';

  factory BuddhistDate.fromGregorian(DateTime date) =>
      BuddhistDate(date.year + 543, date.month, date.day);
}

// ─── Hebrew ──────────────────────────────────────────────────────────────────

/// Hebrew (Jewish) calendar via the arithmetic rules in Dershowitz & Reingold's
/// "Calendrical Calculations", using RD (Rata Die: RD 1 = proleptic Gregorian
/// 0001-01-01).
class HebrewDate {
  const HebrewDate(this.year, this.month, this.day);

  final int year;

  /// Reingold month numbering: 1 = Nisan … 7 = Tishri … up to 12 (common) or 13
  /// (leap, Adar II).
  final int month;
  final int day;

  /// RD of 1 Tishri, Hebrew year 1.
  static const int _epoch = -1373427;

  static bool _leapYear(int year) => ((7 * year + 1) % 19) < 7;

  static int _monthsInYear(int year) => _leapYear(year) ? 13 : 12;

  static int _elapsedDays(int year) {
    final monthsElapsed = (235 * year - 234) ~/ 19;
    final partsElapsed = 12084 + 13753 * monthsElapsed;
    var day = monthsElapsed * 29 + partsElapsed ~/ 25920;
    if ((3 * (day + 1)) % 7 < 3) day += 1;
    return day;
  }

  static int _newYearDelay(int year) {
    final ny0 = _elapsedDays(year - 1);
    final ny1 = _elapsedDays(year);
    final ny2 = _elapsedDays(year + 1);
    if (ny2 - ny1 == 356) return 2;
    if (ny1 - ny0 == 382) return 1;
    return 0;
  }

  /// RD of Rosh Hashanah (1 Tishri) of [year].
  static int _newYear(int year) =>
      _epoch + _elapsedDays(year) + _newYearDelay(year);

  static int _yearLength(int year) => _newYear(year + 1) - _newYear(year);

  static bool _longHeshvan(int year) => _yearLength(year) % 10 == 5;
  static bool _shortKislev(int year) => _yearLength(year) % 10 == 3;

  static int _lastDayOfMonth(int month, int year) {
    if (const [2, 4, 6, 10, 13].contains(month) ||
        (month == 12 && !_leapYear(year)) ||
        (month == 8 && !_longHeshvan(year)) ||
        (month == 9 && _shortKislev(year))) {
      return 29;
    }
    return 30;
  }

  static int _fixedFromHebrew(int year, int month, int day) {
    var result = _newYear(year) + day - 1;
    if (month < 7) {
      // Nisan..Elul fall after Tishri-based new year, so add Tishri..year-end
      // then the months from Nisan up to (month-1).
      for (var m = 7; m <= _monthsInYear(year); m++) {
        result += _lastDayOfMonth(m, year);
      }
      for (var m = 1; m < month; m++) {
        result += _lastDayOfMonth(m, year);
      }
    } else {
      for (var m = 7; m < month; m++) {
        result += _lastDayOfMonth(m, year);
      }
    }
    return result;
  }

  static const List<int> _gCumDays = [
    0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334,
  ];

  static bool _gregorianLeap(int y) =>
      (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;

  /// RD from a Gregorian date.
  static int _rdFromGregorian(int y, int m, int d) {
    var n = 365 * (y - 1) +
        _floorDiv(y - 1, 4) -
        _floorDiv(y - 1, 100) +
        _floorDiv(y - 1, 400) +
        _gCumDays[m - 1] +
        d;
    if (m > 2 && _gregorianLeap(y)) n += 1;
    return n;
  }

  static const List<String> monthNamesCommon = <String>[
    '', // 0 unused
    'Nisan',
    'Iyyar',
    'Sivan',
    'Tammuz',
    'Av',
    'Elul',
    'Tishri',
    'Heshvan',
    'Kislev',
    'Tevet',
    'Shevat',
    'Adar',
  ];

  String get monthName {
    if (_leapYear(year)) {
      if (month == 12) return 'Adar I';
      if (month == 13) return 'Adar II';
    }
    return monthNamesCommon[month];
  }

  /// e.g. "23 Tevet 5760".
  String get formatted => '$day $monthName $year';

  factory HebrewDate.fromGregorian(DateTime date) {
    final rd = _rdFromGregorian(date.year, date.month, date.day);
    // Estimate the Hebrew year, then correct.
    var year = ((rd - _epoch) * 98496) ~/ 35975351;
    while (_newYear(year + 1) <= rd) {
      year++;
    }
    while (_newYear(year) > rd) {
      year--;
    }
    // Months are ordered from Tishri (7); if the date is before this year's
    // Nisan it lies in the Tishri..end span, otherwise from Nisan.
    var month = (rd < _fixedFromHebrew(year, 1, 1)) ? 7 : 1;
    while (rd > _fixedFromHebrew(year, month, _lastDayOfMonth(month, year))) {
      month++;
    }
    final day = rd - _fixedFromHebrew(year, month, 1) + 1;
    return HebrewDate(year, month, day);
  }
}
