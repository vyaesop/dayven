import 'package:flutter_test/flutter_test.dart';
import 'package:vertical_planner/core/holidays/ethiopian_holidays.dart';

void main() {
  group('EthiopianHolidays', () {
    DateTime? dateOf(List<EthiopianHoliday> hs, String namePart) {
      for (final h in hs) {
        if (h.name.toLowerCase().contains(namePart.toLowerCase())) return h.date;
      }
      return null;
    }

    test('supports only Ethiopia, case-insensitively', () {
      expect(EthiopianHolidays.supports('ET'), isTrue);
      expect(EthiopianHolidays.supports('et'), isTrue);
      expect(EthiopianHolidays.supports('US'), isFalse);
    });

    test('emits the fixed civil and Orthodox solar holidays', () {
      final hs = EthiopianHolidays.forYear(2026);
      expect(dateOf(hs, 'Genna'), DateTime(2026, 1, 7));
      expect(dateOf(hs, 'Timkat'), DateTime(2026, 1, 19));
      expect(dateOf(hs, 'Adwa'), DateTime(2026, 3, 2));
      expect(dateOf(hs, 'Labour'), DateTime(2026, 5, 1));
      expect(dateOf(hs, 'Enkutatash'), DateTime(2026, 9, 11));
      expect(dateOf(hs, 'Meskel'), DateTime(2026, 9, 27));
    });

    test('New Year/Meskel shift to Sep 12/28 before a Gregorian leap year', () {
      // 2028 is a leap year, so EthYear 2020 begins Sep 12, 2027.
      final hs = EthiopianHolidays.forYear(2027);
      expect(dateOf(hs, 'Enkutatash'), DateTime(2027, 9, 12));
      expect(dateOf(hs, 'Meskel'), DateTime(2027, 9, 28));
    });

    test('computes Orthodox Easter (Fasika) and Good Friday correctly', () {
      // Known Orthodox Easter Sundays.
      expect(dateOf(EthiopianHolidays.forYear(2024), 'Fasika'), DateTime(2024, 5, 5));
      expect(dateOf(EthiopianHolidays.forYear(2025), 'Fasika'), DateTime(2025, 4, 20));
      expect(dateOf(EthiopianHolidays.forYear(2026), 'Fasika'), DateTime(2026, 4, 12));
      // Good Friday is two days before Easter.
      expect(dateOf(EthiopianHolidays.forYear(2026), 'Good Friday'),
          DateTime(2026, 4, 10));
    });

    test('includes Islamic holidays for table years only', () {
      final inRange = EthiopianHolidays.forYear(2026);
      expect(dateOf(inRange, 'Eid al-Fitr'), isNotNull);
      expect(dateOf(inRange, 'Eid al-Adha'), isNotNull);
      expect(dateOf(inRange, 'Mawlid'), isNotNull);

      // Outside the curated table the lunar holidays are simply omitted, but the
      // deterministic (solar/Orthodox) ones are still produced.
      final outOfRange = EthiopianHolidays.forYear(2040);
      expect(dateOf(outOfRange, 'Eid al-Fitr'), isNull);
      expect(dateOf(outOfRange, 'Genna'), DateTime(2040, 1, 7));
    });

    test('holidays are returned sorted by date', () {
      final hs = EthiopianHolidays.forYear(2026);
      for (var i = 1; i < hs.length; i++) {
        expect(hs[i].date.isBefore(hs[i - 1].date), isFalse);
      }
    });
  });
}
