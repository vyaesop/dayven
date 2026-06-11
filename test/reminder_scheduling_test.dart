import 'package:flutter_test/flutter_test.dart';
import 'package:vertical_planner/core/notifications/push_notification_service.dart';
import 'package:vertical_planner/features/home/domain/planner_models.dart';

PlannerEvent event({
  required DateTime start,
  required DateTime end,
  bool isAllDay = false,
  PlannerReminder reminder = PlannerReminder.atTime,
  PlannerRecurrence recurrence = PlannerRecurrence.none,
}) {
  return PlannerEvent(
    id: 'e1',
    title: 'Test',
    isAllDay: isAllDay,
    startAt: start,
    endAt: end,
    location: '',
    url: '',
    note: '',
    calendarId: 'c',
    reminder: reminder,
    repeatRule: recurrence.frequency,
    recurrence: recurrence,
    attendees: const [],
  );
}

void main() {
  group('reminderFireTime', () {
    test('no reminder yields no fire time', () {
      final e = event(
        start: DateTime(2026, 6, 10, 9),
        end: DateTime(2026, 6, 10, 10),
        reminder: PlannerReminder.none,
      );
      expect(
        PushNotificationService.reminderFireTime(e, DateTime(2026, 6, 1)),
        isNull,
      );
    });

    test('fires lead time before a future timed event', () {
      final e = event(
        start: DateTime(2026, 6, 10, 9),
        end: DateTime(2026, 6, 10, 10),
        reminder: PlannerReminder.fifteenMinutesBefore,
      );
      final fire =
          PushNotificationService.reminderFireTime(e, DateTime(2026, 6, 1));
      expect(fire, DateTime(2026, 6, 10, 8, 45));
    });

    test('past one-off event yields no fire time', () {
      final e = event(
        start: DateTime(2026, 6, 1, 9),
        end: DateTime(2026, 6, 1, 10),
        reminder: PlannerReminder.atTime,
      );
      expect(
        PushNotificationService.reminderFireTime(e, DateTime(2026, 6, 2)),
        isNull,
      );
    });

    test('all-day reminder anchors at 09:00, not midnight', () {
      final e = event(
        start: DateTime(2026, 6, 10),
        end: DateTime(2026, 6, 10),
        isAllDay: true,
        reminder: PlannerReminder.atTime,
      );
      final fire =
          PushNotificationService.reminderFireTime(e, DateTime(2026, 6, 1));
      expect(fire, DateTime(2026, 6, 10, 9));
    });

    test('all-day "1 day before" fires at 09:00 the previous day', () {
      final e = event(
        start: DateTime(2026, 6, 10),
        end: DateTime(2026, 6, 10),
        isAllDay: true,
        reminder: PlannerReminder.oneDayBefore,
      );
      final fire =
          PushNotificationService.reminderFireTime(e, DateTime(2026, 6, 1));
      expect(fire, DateTime(2026, 6, 9, 9));
    });

    test('recurring daily event reminds for the next future occurrence', () {
      final e = event(
        start: DateTime(2026, 1, 1, 9),
        end: DateTime(2026, 1, 1, 10),
        reminder: PlannerReminder.atTime,
        recurrence: const PlannerRecurrence(frequency: PlannerRepeatRule.daily),
      );
      // "Now" is mid-June; the next daily occurrence is the same day at 09:00
      // (now is before 09:00) — keeps the same wall-clock hour regardless of
      // how far the anchor is in the past.
      final fire = PushNotificationService.reminderFireTime(
          e, DateTime(2026, 6, 15, 7));
      expect(fire, DateTime(2026, 6, 15, 9));
      expect(fire!.hour, 9, reason: 'wall-clock hour is DST-stable');
    });

    test('recurring weekly event reminds on the next matching weekday', () {
      // Anchor Thursday 2026-01-01 09:00, weekly.
      final e = event(
        start: DateTime(2026, 1, 1, 9),
        end: DateTime(2026, 1, 1, 10),
        reminder: PlannerReminder.atTime,
        recurrence: const PlannerRecurrence(
          frequency: PlannerRepeatRule.weekly,
        ),
      );
      // 2026-06-15 is a Monday; next Thursday is 2026-06-18.
      final fire = PushNotificationService.reminderFireTime(
          e, DateTime(2026, 6, 15, 7));
      expect(fire, DateTime(2026, 6, 18, 9));
      expect(fire!.weekday, DateTime.thursday);
    });
  });
}
