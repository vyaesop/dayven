import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vertical_planner/features/home/domain/planner_models.dart';

void main() {
  group('PlannerRecurrence.occurrenceDates', () {
    test('daily with count stops after N occurrences', () {
      const rec = PlannerRecurrence(
        frequency: PlannerRepeatRule.daily,
        endMode: RecurrenceEndMode.afterCount,
        count: 3,
      );
      final anchor = DateTime(2026, 6, 1);
      final dates = rec.occurrenceDates(anchor, DateTime(2026, 12, 31)).toList();
      expect(dates, [
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 2),
        DateTime(2026, 6, 3),
      ]);
    });

    test('weekly on specific weekdays', () {
      // Anchor Mon 2026-06-01; repeat weekly on Mon+Wed, 4 occurrences.
      const rec = PlannerRecurrence(
        frequency: PlannerRepeatRule.weekly,
        byWeekdays: {DateTime.monday, DateTime.wednesday},
        endMode: RecurrenceEndMode.afterCount,
        count: 4,
      );
      final dates =
          rec.occurrenceDates(DateTime(2026, 6, 1), DateTime(2026, 7, 1)).toList();
      expect(dates, [
        DateTime(2026, 6, 1), // Mon
        DateTime(2026, 6, 3), // Wed
        DateTime(2026, 6, 8), // Mon
        DateTime(2026, 6, 10), // Wed
      ]);
    });

    test('biweekly steps two weeks', () {
      const rec = PlannerRecurrence(frequency: PlannerRepeatRule.biweekly);
      final dates =
          rec.occurrenceDates(DateTime(2026, 6, 1), DateTime(2026, 7, 1)).toList();
      expect(dates, [
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 15),
        DateTime(2026, 6, 29),
      ]);
    });

    test('monthly clamps to short months', () {
      const rec = PlannerRecurrence(frequency: PlannerRepeatRule.monthly);
      final dates =
          rec.occurrenceDates(DateTime(2026, 1, 31), DateTime(2026, 3, 31)).toList();
      expect(dates, [
        DateTime(2026, 1, 31),
        DateTime(2026, 2, 28), // clamped
        DateTime(2026, 3, 31),
      ]);
    });

    test('until date bounds the series', () {
      final rec = PlannerRecurrence(
        frequency: PlannerRepeatRule.daily,
        endMode: RecurrenceEndMode.onDate,
        until: DateTime(2026, 6, 3),
      );
      final dates =
          rec.occurrenceDates(DateTime(2026, 6, 1), DateTime(2026, 12, 31)).toList();
      expect(dates, [
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 2),
        DateTime(2026, 6, 3),
      ]);
    });

    test('exceptions are skipped but still count toward the limit', () {
      final rec = PlannerRecurrence(
        frequency: PlannerRepeatRule.daily,
        endMode: RecurrenceEndMode.afterCount,
        count: 3,
        exceptions: {DateTime(2026, 6, 2)},
      );
      final dates =
          rec.occurrenceDates(DateTime(2026, 6, 1), DateTime(2026, 12, 31)).toList();
      expect(dates, [DateTime(2026, 6, 1), DateTime(2026, 6, 3)]);
    });
  });

  group('encode/parse round-trip', () {
    test('rich rule survives a round trip', () {
      final rec = PlannerRecurrence(
        frequency: PlannerRepeatRule.weekly,
        interval: 2,
        byWeekdays: {DateTime.tuesday, DateTime.thursday},
        endMode: RecurrenceEndMode.onDate,
        until: DateTime(2026, 9, 1),
        exceptions: {DateTime(2026, 6, 16)},
      );
      final parsed = PlannerRecurrence.parse(rec.encode());
      expect(parsed.frequency, PlannerRepeatRule.weekly);
      expect(parsed.interval, 2);
      expect(parsed.byWeekdays, {DateTime.tuesday, DateTime.thursday});
      expect(parsed.endMode, RecurrenceEndMode.onDate);
      expect(parsed.until, DateTime(2026, 9, 1));
      expect(parsed.exceptions, {DateTime(2026, 6, 16)});
    });

    test('legacy plain frequency token still parses', () {
      final parsed = PlannerRecurrence.parse('weekly');
      expect(parsed.frequency, PlannerRepeatRule.weekly);
      expect(parsed.interval, 1);
      expect(parsed.endMode, RecurrenceEndMode.never);
    });

    test('never encodes/parses as no recurrence', () {
      expect(PlannerRecurrence.none.encode(), 'never');
      expect(PlannerRecurrence.parse('never').repeats, isFalse);
      expect(PlannerRecurrence.parse(null).repeats, isFalse);
    });
  });

  group('PlannerState occurrence expansion', () {
    PlannerState stateWith(PlannerEvent event) {
      return PlannerState(
        selectedDate: DateTime(2026, 6, 1),
        focusedMonth: DateTime(2026, 6),
        calendars: const [
          PlannerCalendar(id: 'c', name: 'Cal', color: Color(0xFF000000)),
        ],
        visibleCalendarIds: const ['c'],
        events: [event],
      );
    }

    PlannerEvent weeklyEvent() {
      return PlannerEvent(
        id: 'e1',
        title: 'Standup',
        isAllDay: false,
        startAt: DateTime(2026, 6, 1, 9, 0),
        endAt: DateTime(2026, 6, 1, 9, 30),
        location: '',
        url: '',
        note: '',
        calendarId: 'c',
        reminder: PlannerReminder.none,
        repeatRule: PlannerRepeatRule.weekly,
        recurrence: const PlannerRecurrence(frequency: PlannerRepeatRule.weekly),
        attendees: const [],
      );
    }

    test('a weekly series appears on each matching day as an instance', () {
      final state = stateWith(weeklyEvent());
      final day8 = state.occurrencesInRange(
        DateTime(2026, 6, 8),
        DateTime(2026, 6, 8),
      );
      expect(day8, hasLength(1));
      expect(day8.single.isRecurringInstance, isTrue);
      expect(day8.single.seriesId, 'e1');
      expect(day8.single.startAt, DateTime(2026, 6, 8, 9, 0));
      expect(day8.single.endAt, DateTime(2026, 6, 8, 9, 30));
    });

    test('the whole month is expanded (5 Mondays in June 2026)', () {
      final state = stateWith(weeklyEvent());
      final june = state.eventsInMonth(2026, 6);
      // Mondays in June 2026: 1, 8, 15, 22, 29.
      expect(june, hasLength(5));
    });

    test('an excepted occurrence is not produced', () {
      final base = weeklyEvent().copyWith(
        recurrence: const PlannerRecurrence(
          frequency: PlannerRepeatRule.weekly,
        ).addException(DateTime(2026, 6, 8)),
      );
      final state = stateWith(base);
      final day8 = state.occurrencesInRange(
        DateTime(2026, 6, 8),
        DateTime(2026, 6, 8),
      );
      expect(day8, isEmpty);
    });
  });

  group('long-running series fast-forward', () {
    test('a years-old daily series still yields a far-future window', () {
      const rec = PlannerRecurrence(frequency: PlannerRepeatRule.daily);
      final dates = rec
          .occurrenceDates(
            DateTime(2005, 1, 1),
            DateTime(2026, 6, 3),
            rangeStart: DateTime(2026, 6, 1),
          )
          .toList();
      // Without fast-forward the ~11-year iteration cap would stop long before
      // 2026; with it the requested window is still produced.
      expect(dates, contains(DateTime(2026, 6, 1)));
      expect(dates, contains(DateTime(2026, 6, 3)));
    });

    test('fast-forward does not change which dates fall in the window', () {
      const rec = PlannerRecurrence(frequency: PlannerRepeatRule.monthly);
      final dates = rec
          .occurrenceDates(
            DateTime(2020, 1, 15),
            DateTime(2026, 7, 31),
            rangeStart: DateTime(2026, 6, 1),
          )
          .where((d) => !d.isBefore(DateTime(2026, 6, 1)))
          .toList();
      expect(dates, [DateTime(2026, 6, 15), DateTime(2026, 7, 15)]);
    });

    test('fast-forward is never applied to count-limited rules', () {
      const rec = PlannerRecurrence(
        frequency: PlannerRepeatRule.daily,
        endMode: RecurrenceEndMode.afterCount,
        count: 2,
      );
      final dates = rec
          .occurrenceDates(
            DateTime(2026, 6, 1),
            DateTime(2030, 1, 1),
            rangeStart: DateTime(2027, 1, 1),
          )
          .toList();
      // Counting must begin at the anchor regardless of rangeStart.
      expect(dates, [DateTime(2026, 6, 1), DateTime(2026, 6, 2)]);
    });
  });

  group('multi-day / all-day occurrence membership', () {
    PlannerState stateWith(List<PlannerEvent> events) => PlannerState(
          selectedDate: DateTime(2026, 6, 1),
          focusedMonth: DateTime(2026, 6),
          calendars: const [
            PlannerCalendar(id: 'c', name: 'Cal', color: Color(0xFF000000)),
          ],
          visibleCalendarIds: const ['c'],
          events: events,
        );

    PlannerEvent ev({
      required bool allDay,
      required DateTime start,
      required DateTime end,
    }) =>
        PlannerEvent(
          id: 'm1',
          title: 'X',
          isAllDay: allDay,
          startAt: start,
          endAt: end,
          location: '',
          url: '',
          note: '',
          calendarId: 'c',
          reminder: PlannerReminder.none,
          repeatRule: PlannerRepeatRule.never,
          attendees: const [],
        );

    test('a single all-day event appears only on its day', () {
      final state = stateWith([
        ev(allDay: true, start: DateTime(2026, 6, 10), end: DateTime(2026, 6, 11)),
      ]);
      expect(
        state.occurrencesInRange(DateTime(2026, 6, 10), DateTime(2026, 6, 10)),
        hasLength(1),
      );
      expect(
        state.occurrencesInRange(DateTime(2026, 6, 11), DateTime(2026, 6, 11)),
        isEmpty,
      );
    });

    test('a multi-day event appears on every covered day', () {
      final state = stateWith([
        ev(allDay: true, start: DateTime(2026, 6, 10), end: DateTime(2026, 6, 13)),
      ]);
      for (final day in [10, 11, 12]) {
        expect(
          state.occurrencesInRange(
            DateTime(2026, 6, day),
            DateTime(2026, 6, day),
          ),
          hasLength(1),
          reason: 'should cover June $day',
        );
      }
      expect(
        state.occurrencesInRange(DateTime(2026, 6, 13), DateTime(2026, 6, 13)),
        isEmpty,
      );
    });

    test('a cross-midnight timed event appears on both days', () {
      final state = stateWith([
        ev(
          allDay: false,
          start: DateTime(2026, 6, 10, 23, 0),
          end: DateTime(2026, 6, 11, 1, 0),
        ),
      ]);
      expect(
        state.occurrencesInRange(DateTime(2026, 6, 10), DateTime(2026, 6, 10)),
        hasLength(1),
      );
      expect(
        state.occurrencesInRange(DateTime(2026, 6, 11), DateTime(2026, 6, 11)),
        hasLength(1),
      );
    });
  });
}
