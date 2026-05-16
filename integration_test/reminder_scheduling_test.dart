import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vertical_planner/core/notifications/push_notification_service.dart';
import 'package:vertical_planner/features/home/domain/planner_models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final svc = PushNotificationService.instance;

  setUpAll(() async {
    // Initialize the service end-to-end — this initialises timezone db,
    // creates the Android channel, and requests POST_NOTIFICATIONS.
    await svc.initialize();
    // Clear any reminders left over from previous app runs / tests.
    await FlutterLocalNotificationsPlugin().cancelAll();
  });

  PlannerEvent makeEvent({
    required String id,
    required Duration startsIn,
    PlannerReminder reminder = PlannerReminder.atTime,
  }) {
    final start = DateTime.now().add(startsIn);
    return PlannerEvent(
      id: id,
      title: 'Test event $id',
      isAllDay: false,
      startAt: start,
      endAt: start.add(const Duration(minutes: 30)),
      location: 'Test lab',
      url: '',
      note: '',
      calendarId: 'work',
      reminder: reminder,
      repeatRule: PlannerRepeatRule.never,
      attendees: const [],
    );
  }

  testWidgets('scheduleEventReminder posts a pending notification',
      (tester) async {
    final event = makeEvent(
      id: 'evt-future-1',
      startsIn: const Duration(minutes: 10),
      reminder: PlannerReminder.fiveMinutesBefore,
    );

    await svc.scheduleEventReminder(event);
    final pending = await svc.pendingScheduledReminders();

    expect(
      pending.where((req) => req.payload == 'event:${event.id}').length,
      1,
      reason: 'Expected exactly one pending reminder for the event',
    );

    await svc.cancelEventReminder(event.id);
  });

  testWidgets('updating an event replaces (does not duplicate) the reminder',
      (tester) async {
    final event = makeEvent(
      id: 'evt-update-1',
      startsIn: const Duration(hours: 2),
      reminder: PlannerReminder.thirtyMinutesBefore,
    );

    await svc.scheduleEventReminder(event);
    // Move event later; reschedule.
    final later = event.copyWith(
      startAt: DateTime.now().add(const Duration(hours: 3)),
      endAt: DateTime.now().add(const Duration(hours: 4)),
      reminder: PlannerReminder.oneHourBefore,
    );
    await svc.scheduleEventReminder(later);

    final pending = await svc.pendingScheduledReminders();
    expect(
      pending.where((req) => req.payload == 'event:${event.id}').length,
      1,
      reason: 'Re-scheduling must replace, not duplicate',
    );

    await svc.cancelEventReminder(event.id);
  });

  testWidgets('cancelEventReminder removes the pending notification',
      (tester) async {
    final event = makeEvent(
      id: 'evt-cancel-1',
      startsIn: const Duration(hours: 1),
      reminder: PlannerReminder.tenMinutesBefore,
    );

    await svc.scheduleEventReminder(event);
    await svc.cancelEventReminder(event.id);

    final pending = await svc.pendingScheduledReminders();
    expect(
      pending.where((req) => req.payload == 'event:${event.id}'),
      isEmpty,
    );
  });

  testWidgets('past reminders are skipped (no schedule)', (tester) async {
    final event = makeEvent(
      id: 'evt-past-1',
      startsIn: const Duration(seconds: 30),
      reminder: PlannerReminder.oneHourBefore, // lead > startsIn => in the past
    );

    await svc.scheduleEventReminder(event);
    final pending = await svc.pendingScheduledReminders();
    expect(
      pending.where((req) => req.payload == 'event:${event.id}'),
      isEmpty,
    );
  });

  testWidgets('reminder=none cancels existing schedule and does not re-add',
      (tester) async {
    final event = makeEvent(
      id: 'evt-none-1',
      startsIn: const Duration(hours: 2),
      reminder: PlannerReminder.fifteenMinutesBefore,
    );

    await svc.scheduleEventReminder(event);
    final cleared = event.copyWith(reminder: PlannerReminder.none);
    await svc.scheduleEventReminder(cleared);

    final pending = await svc.pendingScheduledReminders();
    expect(
      pending.where((req) => req.payload == 'event:${event.id}'),
      isEmpty,
    );
  });

  testWidgets('rescheduleAllEventReminders schedules every event with a reminder',
      (tester) async {
    final events = [
      makeEvent(
        id: 'evt-bulk-1',
        startsIn: const Duration(hours: 4),
        reminder: PlannerReminder.fiveMinutesBefore,
      ),
      makeEvent(
        id: 'evt-bulk-2',
        startsIn: const Duration(hours: 6),
        reminder: PlannerReminder.oneDayBefore, // lead > startsIn => skipped
      ),
      makeEvent(
        id: 'evt-bulk-3',
        startsIn: const Duration(hours: 8),
        reminder: PlannerReminder.thirtyMinutesBefore,
      ),
    ];

    await svc.rescheduleAllEventReminders(events);
    final pending = await svc.pendingScheduledReminders();

    final payloads = pending.map((p) => p.payload).toSet();
    expect(payloads, containsAll(['event:evt-bulk-1', 'event:evt-bulk-3']));
    expect(payloads, isNot(contains('event:evt-bulk-2')));

    for (final e in events) {
      await svc.cancelEventReminder(e.id);
    }
  });
}
