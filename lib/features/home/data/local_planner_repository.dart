import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/storage/local_cache_store.dart';
import '../../../core/util/id_generator.dart';
import '../domain/planner_models.dart';
import 'planner_repository.dart';

/// On-device-only planner used when no cloud backend is configured (local
/// dev/preview or an unconfigured build).
///
/// Unlike the old demo repository this starts **empty** (no sample events) and
/// **persists** to [LocalCacheStore], so creates/edits/deletes survive an app
/// restart. A small set of default calendars is seeded on first run so events
/// always have somewhere to live.
class LocalPlannerRepository implements PlannerRepository {
  LocalPlannerRepository({LocalCacheStore? cache})
      : _cache = cache ?? LocalCacheStore(userId: 'local');

  final LocalCacheStore _cache;

  List<PlannerCalendar> _calendars = [];
  List<PlannerEvent> _events = [];
  List<String> _visibleIds = [];
  bool _loaded = false;

  static const List<PlannerCalendar> _defaultCalendars = [
    PlannerCalendar(id: 'calendar', name: 'Calendar', color: AppColors.lilac),
    PlannerCalendar(id: 'family', name: 'Family', color: AppColors.coral),
    PlannerCalendar(id: 'work', name: 'Work', color: AppColors.graphite),
  ];

  @override
  Future<PlannerState> loadInitialState() async {
    final cached = await _cache.read();
    if (cached != null) {
      _calendars = List.of(cached.calendars);
      _events = List.of(cached.events);
      _visibleIds = cached.visibleCalendarIds.isEmpty
          ? _calendars.map((c) => c.id).toList()
          : List.of(cached.visibleCalendarIds);
    } else {
      // First run: seed calendars only — never any sample events.
      _calendars = List.of(_defaultCalendars);
      _events = [];
      _visibleIds = _calendars.map((c) => c.id).toList();
      await _persist();
    }
    _loaded = true;
    return _buildState();
  }

  Future<void> _persist() async {
    await _cache.write(
      PlannerCacheSnapshot(
        calendars: _calendars,
        visibleCalendarIds: _visibleIds,
        events: _events,
      ),
    );
  }

  PlannerState _buildState() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return PlannerState(
      selectedDate: today,
      focusedMonth: DateTime(today.year, today.month),
      calendars: List.of(_calendars),
      visibleCalendarIds: List.of(_visibleIds),
      events: List.of(_events),
    );
  }

  @override
  Future<PlannerEvent> createEvent(PlannerEventDraft draft) async {
    final event = PlannerEvent(
      id: IdGenerator.uuidV4(),
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
      updatedAt: DateTime.now().toUtc(),
    );
    _events = [..._events, event];
    await _persist();
    return event;
  }

  @override
  Future<PlannerEvent> updateEvent(PlannerEvent event) async {
    final stamped = event.copyWith(updatedAt: DateTime.now().toUtc());
    _events = _events.map((e) => e.id == stamped.id ? stamped : e).toList();
    await _persist();
    return stamped;
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    _events = _events.where((e) => e.id != eventId).toList();
    await _persist();
  }

  @override
  Future<PlannerCalendar> createCalendar(String name, Color color) async {
    final calendar = PlannerCalendar(
      id: IdGenerator.uuidV4(),
      name: name,
      color: color,
    );
    _calendars = [..._calendars, calendar];
    _visibleIds = [..._visibleIds, calendar.id];
    await _persist();
    return calendar;
  }

  @override
  Future<void> renameCalendar(String id, String newName) async {
    _calendars = _calendars
        .map((c) => c.id == id
            ? PlannerCalendar(id: c.id, name: newName, color: c.color)
            : c)
        .toList();
    await _persist();
  }

  @override
  Future<bool> saveHolidays(
    PlannerCalendar calendar,
    List<PlannerEvent> events,
  ) async {
    if (!_loaded) await loadInitialState();
    if (!_calendars.any((c) => c.id == calendar.id)) {
      _calendars = [..._calendars, calendar];
      if (!_visibleIds.contains(calendar.id)) {
        _visibleIds = [..._visibleIds, calendar.id];
      }
    }
    final existingIds = _events.map((e) => e.id).toSet();
    _events = [
      ..._events,
      ...events.where((e) => !existingIds.contains(e.id)),
    ]..sort((a, b) => a.startAt.compareTo(b.startAt));
    await _persist();
    return true;
  }
}
