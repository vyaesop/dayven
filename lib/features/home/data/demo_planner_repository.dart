import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../domain/planner_models.dart';
import 'planner_repository.dart';

class DemoPlannerRepository implements PlannerRepository {
  DemoPlannerRepository()
    : _calendars = [
        const PlannerCalendar(id: 'calendar', name: 'Calendar', color: AppColors.lilac),
        const PlannerCalendar(id: 'exercise', name: 'Exercise', color: Color(0xFFF197A6)),
        const PlannerCalendar(id: 'family', name: 'Family', color: AppColors.coral),
        const PlannerCalendar(id: 'friends', name: 'Friends', color: AppColors.sage),
        const PlannerCalendar(id: 'work', name: 'Work', color: AppColors.graphite),
      ],
      _events = [
        PlannerEvent(
          id: '1',
          title: 'Weekly stand-up',
          isAllDay: false,
          startAt: DateTime(2026, 5, 14, 8, 30),
          endAt: DateTime(2026, 5, 14, 9, 0),
          location: 'Remote',
          url: 'https://meet.google.com/demo-standup',
          note: 'Keep it tight and focus on blockers.',
          calendarId: 'friends',
          reminder: PlannerReminder.fifteenMinutesBefore,
          repeatRule: PlannerRepeatRule.weekly,
          attendees: const ['Alex', 'Mina'],
        ),
        PlannerEvent(
          id: '2',
          title: 'Catch-up with Jane',
          isAllDay: false,
          startAt: DateTime(2026, 5, 14, 10, 0),
          endAt: DateTime(2026, 5, 14, 10, 45),
          location: 'Menza, 3rd Street',
          url: '',
          note: 'Review travel plans and open RSVP items.',
          calendarId: 'family',
          reminder: PlannerReminder.atTime,
          repeatRule: PlannerRepeatRule.never,
          attendees: const ['Jane'],
        ),
        PlannerEvent(
          id: '3',
          title: 'Design review',
          isAllDay: false,
          startAt: DateTime(2026, 5, 14, 11, 30),
          endAt: DateTime(2026, 5, 14, 12, 30),
          location: 'Studio boardroom',
          url: 'https://figma.com/file/design-review',
          note: 'Approve Android motion and menu states.',
          calendarId: 'work',
          reminder: PlannerReminder.thirtyMinutesBefore,
          repeatRule: PlannerRepeatRule.never,
          attendees: const ['Nora', 'Lee'],
        ),
        PlannerEvent(
          id: '4',
          title: 'Pilates',
          isAllDay: false,
          startAt: DateTime(2026, 5, 14, 19, 0),
          endAt: DateTime(2026, 5, 14, 20, 0),
          location: 'North Park Club',
          url: '',
          note: 'Bring towel and update reminders afterward.',
          calendarId: 'exercise',
          reminder: PlannerReminder.oneHourBefore,
          repeatRule: PlannerRepeatRule.weekly,
          attendees: const [],
        ),
        PlannerEvent(
          id: '5',
          title: 'Breakfast with sister',
          isAllDay: false,
          startAt: DateTime(2026, 5, 16, 9, 15),
          endAt: DateTime(2026, 5, 16, 10, 0),
          location: 'North Park Cafe',
          url: '',
          note: 'Talk through summer plans.',
          calendarId: 'family',
          reminder: PlannerReminder.fifteenMinutesBefore,
          repeatRule: PlannerRepeatRule.monthly,
          attendees: const ['Sofia'],
        ),
        PlannerEvent(
          id: '6',
          title: 'Walk and feed Buddy',
          isAllDay: false,
          startAt: DateTime(2026, 5, 18, 18, 0),
          endAt: DateTime(2026, 5, 18, 18, 45),
          location: 'North Loop',
          url: '',
          note: 'Take the longer park route if weather holds.',
          calendarId: 'friends',
          reminder: PlannerReminder.fiveMinutesBefore,
          repeatRule: PlannerRepeatRule.daily,
          attendees: const ['Buddy'],
        ),
      ];

  final List<PlannerCalendar> _calendars;
  final List<PlannerEvent> _events;

  @override
  Future<PlannerState> loadInitialState() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));

    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    return PlannerState(
      selectedDate: todayNorm,
      focusedMonth: DateTime(todayNorm.year, todayNorm.month),
      calendars: List<PlannerCalendar>.from(_calendars),
      visibleCalendarIds: _calendars.map((calendar) => calendar.id).toList(),
      events: List<PlannerEvent>.from(_events),
    );
  }

  @override
  Future<PlannerCalendar> createCalendar(String name, Color color) async {
    final calendar = PlannerCalendar(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      color: color,
    );
    _calendars.add(calendar);
    return calendar;
  }

  @override
  Future<void> renameCalendar(String id, String newName) async {
    final index = _calendars.indexWhere((c) => c.id == id);
    if (index >= 0) {
      _calendars[index] = PlannerCalendar(
        id: id,
        name: newName,
        color: _calendars[index].color,
      );
    }
  }

  @override
  Future<PlannerEvent> createEvent(PlannerEventDraft draft) async {
    final created = PlannerEvent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: draft.title,
      isAllDay: draft.isAllDay,
      startAt: draft.startAt,
      endAt: draft.endAt,
      location: draft.location,
      url: draft.url,
      note: draft.note,
      calendarId: draft.calendarId,
      reminder: draft.reminder,
      repeatRule: draft.effectiveRecurrence.frequency,
      recurrence: draft.effectiveRecurrence,
      attendees: draft.attendees,
    );

    _events.add(created);
    return created;
  }

  @override
  Future<PlannerEvent> updateEvent(PlannerEvent event) async {
    final index = _events.indexWhere((item) => item.id == event.id);
    if (index >= 0) {
      _events[index] = event;
    }

    return event;
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    _events.removeWhere((event) => event.id == eventId);
  }
}
