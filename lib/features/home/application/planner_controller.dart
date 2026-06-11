import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/config/app_config.dart';
import '../../../core/holidays/holidays_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/http_api_client.dart';
import '../../../core/notifications/push_notification_service.dart';
import '../../../core/storage/local_cache_store.dart';
import '../../../core/storage/mutation_queue.dart';
import '../data/demo_planner_repository.dart';
import '../data/neon_planner_api.dart';
import '../data/offline_first_planner_repository.dart';
import '../data/planner_repository.dart';
import '../domain/planner_models.dart';

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

/// Cloud-only with an offline-first cache + mutation queue. When no remote
/// backend is configured (local dev/preview), falls back to in-memory demo
/// data so the UI is still explorable.
final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  final config = ref.watch(appConfigProvider);

  if (config.hasRemoteBackend) {
    final client = ref.watch(apiClientProvider);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return OfflineFirstPlannerRepository(
      remote: NeonPlannerApi(apiClient: client),
      cache: LocalCacheStore(userId: userId),
      queue: MutationQueue(userId: userId),
    );
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
    await _applyHolidayResult(result);
  }

  Future<void> _applyHolidayResult(HolidayLoadResult result) async {
    final calendar = result.calendar;
    final events = result.events;
    final current = state.asData?.value;
    if (current == null || events.isEmpty) return;

    // Persist so the holidays survive app restarts (the previous behaviour only
    // updated in-memory state, so they vanished on the next launch). Only mark
    // the year as loaded once persistence actually succeeded — otherwise (e.g.
    // cloud-sync, which holds them in memory only) we re-fetch next launch.
    final persisted = await _repository.saveHolidays(calendar, events);
    if (persisted) {
      await HolidaysService.instance
          .markYearLoaded(result.year, result.countryCode);
    }

    final alreadyHasCalendar =
        current.calendars.any((c) => c.id == calendar.id);
    final nextCalendars = alreadyHasCalendar
        ? current.calendars
        : [...current.calendars, calendar];
    final nextVisible = current.visibleCalendarIds.contains(calendar.id)
        ? current.visibleCalendarIds
        : [...current.visibleCalendarIds, calendar.id];

    // Merge: keep existing events, skip duplicates by id.
    final existingIds = current.events.map((e) => e.id).toSet();
    final newEvents = events.where((e) => !existingIds.contains(e.id)).toList();
    final nextEvents = [...current.events, ...newEvents]
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    state = AsyncData(
      current.copyWith(
        calendars: nextCalendars,
        visibleCalendarIds: nextVisible,
        events: nextEvents,
      ),
    );
  }

  /// Loads and persists holidays for [countryCode]. Returns true on success,
  /// false when the holidays could not be fetched (e.g. no connection) so the
  /// UI can tell the user instead of silently doing nothing.
  Future<bool> loadHolidaysForCountry(String countryCode) async {
    final current = state.asData?.value;
    if (current == null) return false;
    final result = await HolidaysService.instance.loadForCountry(
      DateTime.now().year,
      countryCode,
      current.calendars,
    );
    if (result == null) return false;
    await _applyHolidayResult(result);
    return true;
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
    unawaited(ref.read(analyticsServiceProvider).logEventCreated(
          isRecurring: created.effectiveRecurrence.repeats,
          hasReminder: created.reminder != PlannerReminder.none,
        ));
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

  PlannerEvent? _findById(PlannerState current, String id) {
    for (final event in current.events) {
      if (event.id == id) return event;
    }
    return null;
  }

  /// "Delete this and following": end the series the day before [date]. If that
  /// would remove the anchor occurrence too, the whole series is deleted.
  Future<void> truncateSeriesFrom(String seriesId, DateTime date) async {
    final current = state.asData?.value;
    if (current == null) return;
    final base = _findById(current, seriesId);
    if (base == null) return;

    final day = DateTime(date.year, date.month, date.day);
    final anchorDay =
        DateTime(base.startAt.year, base.startAt.month, base.startAt.day);
    if (!day.isAfter(anchorDay)) {
      // Truncating from the first occurrence removes everything.
      await deleteEvent(base.id);
      return;
    }

    final newUntil = day.subtract(const Duration(days: 1));
    final recurrence = base.effectiveRecurrence.copyWith(
      endMode: RecurrenceEndMode.onDate,
      until: newUntil,
    );
    final updated = base.copyWith(
      recurrence: recurrence,
      repeatRule: recurrence.frequency,
    );
    await _persistBaseUpdate(current, updated);
  }

  /// "Edit this and following": split the series. The original series is ended
  /// the day before [fromDate], and a new series is created starting at
  /// [fromDate] carrying the [template]'s values and recurrence.
  Future<void> editSeriesFollowing(
    String seriesId,
    DateTime fromDate,
    PlannerEvent template,
  ) async {
    final current = state.asData?.value;
    if (current == null) return;
    final base = _findById(current, seriesId);
    if (base == null) return;

    final day = DateTime(fromDate.year, fromDate.month, fromDate.day);
    final anchorDay =
        DateTime(base.startAt.year, base.startAt.month, base.startAt.day);

    // 1. Truncate (or remove) the original series so it stops before fromDate.
    if (day.isAfter(anchorDay)) {
      final newUntil = day.subtract(const Duration(days: 1));
      final truncated = base.copyWith(
        recurrence: base.effectiveRecurrence.copyWith(
          endMode: RecurrenceEndMode.onDate,
          until: newUntil,
        ),
        repeatRule: base.effectiveRecurrence.frequency,
      );
      await _repository.updateEvent(truncated);
    } else {
      // Editing from the first occurrence: the whole original series is replaced.
      await _repository.deleteEvent(base.id);
      await _notifications.cancelEventReminder(base.id);
    }

    // 2. Create the new series starting at fromDate.
    final duration = template.endAt.difference(template.startAt);
    final newStart = template.isAllDay
        ? day
        : DateTime(day.year, day.month, day.day, template.startAt.hour,
            template.startAt.minute);
    final draft = PlannerEventDraft(
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
    final created = await _repository.createEvent(draft);
    await _notifications.scheduleEventReminder(created);

    // 3. Rebuild state from the repository's authoritative view.
    final refreshed = await _repository.loadInitialState();
    state = AsyncData(
      refreshed.copyWith(
        selectedDate: DateTime(newStart.year, newStart.month, newStart.day),
        focusedMonth: DateTime(newStart.year, newStart.month),
        visibleCalendarIds: current.visibleCalendarIds,
      ),
    );
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
