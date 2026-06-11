import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vertical_planner/features/home/data/demo_planner_repository.dart';
import 'package:vertical_planner/features/home/domain/planner_models.dart';

void main() {
  PlannerEvent holiday(String id, DateTime date) => PlannerEvent(
        id: id,
        title: 'New Year',
        isAllDay: true,
        startAt: date,
        endAt: date,
        location: '',
        url: '',
        note: '',
        calendarId: 'public_holidays',
        reminder: PlannerReminder.none,
        repeatRule: PlannerRepeatRule.never,
        attendees: const [],
      );

  const holidayCalendar = PlannerCalendar(
    id: 'public_holidays',
    name: 'Public Holidays',
    color: Color(0xFFE1C06C),
  );

  test('saved holidays appear in the loaded state', () async {
    final repo = DemoPlannerRepository();
    await repo.saveHolidays(holidayCalendar, [holiday('h1', DateTime(2026, 1, 1))]);

    final state = await repo.loadInitialState();
    expect(state.calendars.where((c) => c.id == 'public_holidays'), hasLength(1));
    expect(state.events.where((e) => e.id == 'h1'), hasLength(1));
  });

  test('re-saving the same holidays is idempotent (no duplicates)', () async {
    final repo = DemoPlannerRepository();
    final events = [holiday('h1', DateTime(2026, 1, 1))];
    await repo.saveHolidays(holidayCalendar, events);
    await repo.saveHolidays(holidayCalendar, events);

    final state = await repo.loadInitialState();
    expect(
      state.calendars.where((c) => c.id == 'public_holidays'),
      hasLength(1),
      reason: 'the holidays calendar must not be duplicated on re-add',
    );
    expect(state.events.where((e) => e.id == 'h1'), hasLength(1));
  });
}
