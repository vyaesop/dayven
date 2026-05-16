import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vertical_planner/core/notifications/push_notification_service.dart';
import 'package:vertical_planner/features/home/domain/planner_models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final svc = PushNotificationService.instance;

  setUpAll(() async {
    await svc.initialize();
  });

  testWidgets('reminder fires and is removed from the pending queue',
      (tester) async {
    // Event starts 6 seconds from now; reminder = atTime so it fires in ~6s.
    final start = DateTime.now().add(const Duration(seconds: 6));
    final event = PlannerEvent(
      id: 'evt-fire-1',
      title: 'Reminder firing test',
      isAllDay: false,
      startAt: start,
      endAt: start.add(const Duration(minutes: 30)),
      location: '',
      url: '',
      note: '',
      calendarId: 'work',
      reminder: PlannerReminder.atTime,
      repeatRule: PlannerRepeatRule.never,
      attendees: const [],
    );

    await svc.scheduleEventReminder(event);

    final before = await svc.pendingScheduledReminders();
    expect(
      before.where((p) => p.payload == 'event:${event.id}').length,
      1,
      reason: 'Reminder must be queued before fire time',
    );

    // Wait past the scheduled time. Inexact alarms can slip — give it room.
    await Future<void>.delayed(const Duration(seconds: 30));

    final after = await svc.pendingScheduledReminders();
    expect(
      after.where((p) => p.payload == 'event:${event.id}'),
      isEmpty,
      reason:
          'After fire time, the OS should have dispatched it and the pending queue should no longer contain it',
    );
  }, timeout: const Timeout(Duration(minutes: 2)));
}
