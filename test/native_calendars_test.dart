import 'package:flutter_test/flutter_test.dart';
import 'package:vertical_planner/core/calendars/native_calendars.dart';

void main() {
  group('Buddhist', () {
    test('is Gregorian year + 543', () {
      final d = BuddhistDate.fromGregorian(DateTime(2024, 3, 29));
      expect(d.year, 2567);
      expect(d.month, 3);
      expect(d.day, 29);
      expect(d.formatted, 'March 29, 2567 BE');
    });
  });

  group('Persian (Jalali)', () {
    test('Nowruz 2024-03-20 is Farvardin 1, 1403', () {
      final d = PersianDate.fromGregorian(DateTime(2024, 3, 20));
      expect(d.year, 1403);
      expect(d.month, 1);
      expect(d.day, 1);
    });

    test('day before Nowruz is end of Esfand 1402', () {
      final d = PersianDate.fromGregorian(DateTime(2024, 3, 19));
      expect(d.year, 1402);
      expect(d.month, 12);
    });
  });

  group('Hebrew', () {
    test('2000-01-01 is 23 Tevet 5760', () {
      final d = HebrewDate.fromGregorian(DateTime(2000, 1, 1));
      expect(d.year, 5760);
      expect(d.monthName, 'Tevet');
      expect(d.day, 23);
    });

    test('Rosh Hashanah 5784 falls on 2023-09-16 (1 Tishri)', () {
      final d = HebrewDate.fromGregorian(DateTime(2023, 9, 16));
      expect(d.year, 5784);
      expect(d.monthName, 'Tishri');
      expect(d.day, 1);
    });
  });

  group('Hijri (tabular civil)', () {
    test('produces a plausible year for a modern date', () {
      final d = HijriDate.fromGregorian(DateTime(2025, 1, 1));
      // Gregorian 2025-01-01 sits in 1446 AH.
      expect(d.year, 1446);
      expect(d.month, inInclusiveRange(1, 12));
      expect(d.day, inInclusiveRange(1, 30));
    });

    test('month and day are always within range across a year', () {
      var date = DateTime(2026, 1, 1);
      for (var i = 0; i < 366; i++) {
        final h = HijriDate.fromGregorian(date);
        expect(h.month, inInclusiveRange(1, 12));
        expect(h.day, inInclusiveRange(1, 30));
        date = date.add(const Duration(days: 1));
      }
    });
  });
}
