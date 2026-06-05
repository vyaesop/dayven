import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/holidays/holidays_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/http_api_client.dart';
import '../../../core/notifications/push_notification_service.dart';
import '../../../core/storage/sqlite_database.dart';
import '../../../core/storage/storage_mode.dart';
import '../data/demo_planner_repository.dart';
import '../data/neon_planner_repository.dart';
import '../data/planner_repository.dart';
import '../data/sqlite_planner_repository.dart';
import '../domain/planner_models.dart';
import '../../bootstrap/application/app_bootstrap_controller.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.current;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  return HttpApiClient(
    apiBaseUrl: config.apiBaseUrl,
    tokenProvider: () async => FirebaseAuth.instance.currentUser?.getIdToken(),
  );
});

final sqliteDatabaseFactoryProvider = Provider<SqliteDatabaseFactory>((ref) {
  return SqliteDatabaseFactory();
});

final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  final selectedStorageMode = ref.watch(selectedStorageModeProvider).asData?.value;

  if (selectedStorageMode == StorageMode.localSqlite) {
    final databaseFactory = ref.watch(sqliteDatabaseFactoryProvider);
    return SqlitePlannerRepository(databaseFactory: databaseFactory);
  }

  if (selectedStorageMode == StorageMode.cloudSync && config.hasRemoteBackend) {
    final client = ref.watch(apiClientProvider);
    return NeonPlannerRepository(apiClient: client);
  }

  return DemoPlannerRepository();
});

final plannerControllerProvider =
    AsyncNotifierProvider<PlannerController, PlannerState>(
  PlannerController.new,
);

class PlannerController extends AsyncNotifier<PlannerState> {
  PlannerRepository get _repository => ref.read(plannerRepositoryProvider);

  PushNotificationService get _notifications =>
      PushNotificationService.instance;

  @override
  Future<PlannerState> build() async {
    final initial = await _repository.loadInitialState();
    unawaited(_notifications.rescheduleAllEventReminders(initial.events));
    // Auto-load public holidays in the background; don't block startup.
    unawaited(_tryLoadHolidays(DateTime.now().year));
    return initial;
  }

  Future<void> _tryLoadHolidays(int year) async {
    final current = state.asData?.value;
    if (current == null) return;
    final result = await HolidaysService.instance
        .loadForYear(year, current.calendars);
    if (result == null) return;
    _applyHolidayResult(result.calendar, result.events);
  }

  void _applyHolidayResult(
    PlannerCalendar calendar,
    List<PlannerEvent> events,
  ) {
    final current = state.asData?.value;
    if (current == null || events.isEmpty) return;

    final alreadyHasCalendar =
        current.calendars.any((c) => c.id == calendar.id);
    final nextCalendars = alreadyHasCalendar
        ? current.calendars
        : List<PlannerCalendar>.from(current.calendars)..add(calendar);
    final nextVisible = alreadyHasCalendar
        ? current.visibleCalendarIds
        : List<String>.from(current.visibleCalendarIds)..add(calendar.id);

    // Merge: keep existing events, skip duplicates by id.
    final existingIds = current.events.map((e) => e.id).toSet();
    final newEvents = events.where((e) => !existingIds.contains(e.id)).toList();
    final nextEvents = List<PlannerEvent>.from(current.events)
      ..addAll(newEvents)
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    state = AsyncData(
      current.copyWith(
        calendars: nextCalendars,
        visibleCalendarIds: nextVisible,
        events: nextEvents,
      ),
    );
  }

  Future<void> loadHolidaysForCountry(String countryCode) async {
    final current = state.asData?.value;
    if (current == null) return;
    final result = await HolidaysService.instance.loadForCountry(
      DateTime.now().year,
      countryCode,
      current.calendars,
    );
    if (result == null) return;
    _applyHolidayResult(result.calendar, result.events);
  }

  void selectDate(DateTime date) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    final normalized = DateTime(date.year, date.month, date.day);
    state = AsyncData(
      current.copyWith(
        selectedDate: normalized,
        focusedMonth: DateTime(normalized.year, normalized.month),
      ),
    );
  }

  void jumpToToday() {
    selectDate(DateTime.now());
  }

  void toggleCalendarVisibility(String calendarId) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    final visible = List<String>.from(current.visibleCalendarIds);
    if (visible.contains(calendarId)) {
      if (visible.length == 1) {
        return;
      }
      visible.remove(calendarId);
    } else {
      visible.add(calendarId);
    }

    state = AsyncData(current.copyWith(visibleCalendarIds: visible));
  }

  void setAllCalendarsVisible() {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    state = AsyncData(
      current.copyWith(
        visibleCalendarIds:
            current.calendars.map((calendar) => calendar.id).toList(),
      ),
    );
  }

  Future<void> renameCalendar(String calendarId, String newName) async {
    final current = state.asData?.value;
    if (current == null) return;
    await _repository.renameCalendar(calendarId, newName);
    final nextCalendars = current.calendars.map((c) => c.id == calendarId
        ? PlannerCalendar(id: c.id, name: newName, color: c.color)
        : c).toList();
    state = AsyncData(current.copyWith(calendars: nextCalendars));
  }

  Future<void> createCalendar(String name, Color color) async {
    final current = state.asData?.value;
    if (current == null) return;

    final created = await _repository.createCalendar(name, color);
    final nextCalendars = List<PlannerCalendar>.from(current.calendars)
      ..add(created);
    final nextVisible = List<String>.from(current.visibleCalendarIds)
      ..add(created.id);
    state = AsyncData(
      current.copyWith(
        calendars: nextCalendars,
        visibleCalendarIds: nextVisible,
      ),
    );
  }

  Future<void> createEvent(PlannerEventDraft draft) async {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    final created = await _repository.createEvent(draft);
    await _notifications.scheduleEventReminder(created);
    final nextEvents = List<PlannerEvent>.from(current.events)..add(created);
    nextEvents.sort((a, b) => a.startAt.compareTo(b.startAt));

    state = AsyncData(
      current.copyWith(
        selectedDate: DateTime(
          created.startAt.year,
          created.startAt.month,
          created.startAt.day,
        ),
        focusedMonth: DateTime(created.startAt.year, created.startAt.month),
        events: nextEvents,
      ),
    );
  }

  Future<void> updateEvent(PlannerEvent event) async {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    final updated = await _repository.updateEvent(event);
    await _notifications.scheduleEventReminder(updated);
    final nextEvents = current.events
        .map((existing) => existing.id == updated.id ? updated : existing)
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    state = AsyncData(
      current.copyWith(
        selectedDate: DateTime(
          updated.startAt.year,
          updated.startAt.month,
          updated.startAt.day,
        ),
        focusedMonth: DateTime(updated.startAt.year, updated.startAt.month),
        events: nextEvents,
      ),
    );
  }

  /// Apply an edit to an entire recurring series. [template] carries the new
  /// field values; the series keeps its original anchor date while adopting the
  /// template's time-of-day, duration and recurrence.
  Future<void> editSeriesAll(String seriesId, PlannerEvent template) async {
    final current = state.asData?.value;
    if (current == null) return;

    PlannerEvent? base;
    for (final event in current.events) {
      if (event.id == seriesId) {
        base = event;
        break;
      }
    }
    if (base == null) return;

    final anchor = base.startAt;
    final duration = template.endAt.difference(template.startAt);
    final newStart = template.isAllDay
        ? DateTime(anchor.year, anchor.month, anchor.day)
        : DateTime(
            anchor.year,
            anchor.month,
            anchor.day,
            template.startAt.hour,
            template.startAt.minute,
          );
    final updated = base.copyWith(
      title: template.title,
      isAllDay: template.isAllDay,
      startAt: newStart,
      endAt: newStart.add(duration),
      location: template.location,
      url: template.url,
      note: template.note,
      calendarId: template.calendarId,
      reminder: template.reminder,
      repeatRule: template.recurrence.frequency,
      recurrence: template.recurrence,
      attendees: template.attendees,
    );

    await _persistBaseUpdate(current, updated, moveSelectionTo: newStart);
  }

  /// Detach a single occurrence from a series by recording it as an exception.
  /// Used both for "delete only this event" and as the first half of editing a
  /// single occurrence (the standalone override is created separately).
  Future<void> excludeOccurrence(String seriesId, DateTime date) async {
    final current = state.asData?.value;
    if (current == null) return;

    PlannerEvent? base;
    for (final event in current.events) {
      if (event.id == seriesId) {
        base = event;
        break;
      }
    }
    if (base == null) return;

    final recurrence = base.effectiveRecurrence.addException(date);
    final updated = base.copyWith(
      recurrence: recurrence,
      repeatRule: recurrence.frequency,
    );
    await _persistBaseUpdate(current, updated);
  }

  Future<void> _persistBaseUpdate(
    PlannerState current,
    PlannerEvent updated, {
    DateTime? moveSelectionTo,
  }) async {
    final saved = await _repository.updateEvent(updated);
    await _notifications.scheduleEventReminder(saved);
    final nextEvents = current.events
        .map((existing) => existing.id == saved.id ? saved : existing)
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    final selection = moveSelectionTo ?? current.selectedDate;
    state = AsyncData(
      current.copyWith(
        selectedDate: DateTime(selection.year, selection.month, selection.day),
        focusedMonth: DateTime(selection.year, selection.month),
        events: nextEvents,
      ),
    );
  }

  Future<void> deleteEvent(String eventId) async {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    await _repository.deleteEvent(eventId);
    await _notifications.cancelEventReminder(eventId);
    final nextEvents =
        current.events.where((event) => event.id != eventId).toList();

    state = AsyncData(current.copyWith(events: nextEvents));
  }
}
