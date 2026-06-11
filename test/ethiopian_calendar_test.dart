import 'package:flutter_test/flutter_test.dart';
import 'package:vertical_planner/core/calendars/ethiopian_calendar.dart';
import 'package:vertical_planner/core/calendars/secondary_calendar.dart';

void main() {
  group('EthiopianDate.fromGregorian', () {
    void expectEth(DateTime g, int y, int m, int d) {
      final e = EthiopianDate.fromGregorian(g);
      expect([e.year, e.month, e.day], [y, m, d],
          reason: '${g.toIso8601String()} -> $y/$m/$d');
    }

    test('known anchor dates convert correctly', () {
      expectEth(DateTime(2024, 9, 11), 2017, 1, 1); // Ethiopian New Year
      expectEth(DateTime(2025, 3, 29), 2017, 7, 20); // Megabit 20
      // Jan 7 2024 (Genna): EthYear 2016 started Sep 12 2023, so Tahsas 28.
      expectEth(DateTime(2024, 1, 7), 2016, 4, 28);
    });

    test('handles the Sep-12 New Year before a Gregorian leap year', () {
      // 2028 is a leap year, so EthYear 2020 starts on Sep 12, 2027, and the
      // day before is the leap day Pagʻume 6 of EthYear 2019.
      expectEth(DateTime(2027, 9, 12), 2020, 1, 1);
      expectEth(DateTime(2027, 9, 11), 2019, 13, 6);
    });

    test('formats month name and year', () {
      expect(EthiopianDate.fromGregorian(DateTime(2025, 3, 29)).formatted,
          'Megabit 20, 2017');
    });
  });

  group('EthiopianDate.toGregorian', () {
    test('round-trips with fromGregorian across a range of dates', () {
      for (var jdnDay = DateTime(2018, 1, 1);
          jdnDay.isBefore(DateTime(2032, 1, 1));
          jdnDay = jdnDay.add(const Duration(days: 17))) {
        final eth = EthiopianDate.fromGregorian(jdnDay);
        final back = eth.toGregorian();
        expect(back, DateTime(jdnDay.year, jdnDay.month, jdnDay.day),
            reason: 'round-trip failed for ${jdnDay.toIso8601String()}');
      }
    });

    test('New Year lands on Sep 11 or Sep 12 as appropriate', () {
      expect(EthiopianDate(2017, 1, 1).toGregorian(), DateTime(2024, 9, 11));
      expect(EthiopianDate(2020, 1, 1).toGregorian(), DateTime(2027, 9, 12));
    });
  });

  group('SecondaryCalendar', () {
    test('off produces no label, ethiopian produces the Geʼez date', () {
      final date = DateTime(2025, 3, 29);
      expect(SecondaryCalendar.none.labelFor(date), isNull);
      expect(SecondaryCalendar.ethiopian.labelFor(date), 'Megabit 20, 2017');
    });

    test('storage round-trips and is robust to junk', () {
      for (final c in SecondaryCalendar.values) {
        expect(secondaryCalendarFromStorage(c.storageValue), c);
      }
      expect(secondaryCalendarFromStorage(null), SecondaryCalendar.none);
      expect(secondaryCalendarFromStorage('garbage'), SecondaryCalendar.none);
    });
  });
}
