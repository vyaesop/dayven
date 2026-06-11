import 'package:flutter/material.dart';

import '../../../core/storage/local_cache_store.dart';
import '../../../core/storage/mutation_queue.dart';
import '../../../core/util/id_generator.dart';
import '../domain/planner_models.dart';
import 'planner_repository.dart';
import 'remote_planner_api.dart';

/// Cloud-only, offline-resilient planner repository.
///
/// The cloud backend is the source of truth, but every read is served instantly
/// from a durable on-device cache and every write is applied optimistically and
/// queued for upload. This keeps the app fully usable on a flaky or absent
/// connection; queued mutations are flushed on the next successful network call.
///
/// Conflict resolution is last-write-wins: a remote fetch is treated as the new
/// base, then any still-unsynced local mutations are overlaid on top (they are
/// by definition newer than what the server has seen).
class OfflineFirstPlannerRepository implements PlannerRepository {
  OfflineFirstPlannerRepository({
    required RemotePlannerApi remote,
    required LocalCacheStore cache,
    required MutationQueue queue,
  })  : _remote = remote,
        _cache = cache,
        _queue = queue;

  final RemotePlannerApi _remote;
  final LocalCacheStore _cache;
  final MutationQueue _queue;

  // In-memory working set. Holidays are tracked separately so they are never
  // pushed to the cloud (there is no bulk-import endpoint) but still cached.
  List<PlannerCalendar> _calendars = [];
  List<PlannerEvent> _events = [];
  List<String> _visibleIds = [];

  @override
  Future<PlannerState> loadInitialState() async {
    // 1. Hydrate from the durable cache so the UI has data immediately.
    final cached = await _cache.read();
    if (cached != null) {
      _calendars = List.of(cached.calendars);
      _events = List.of(cached.events);
      _visibleIds = cached.visibleCalendarIds.isEmpty
          ? _calendars.map((c) => c.id).toList()
          : List.of(cached.visibleCalendarIds);
    }

    // 2. Best-effort sync with the cloud (flush queued writes, then pull).
    await _trySync();

    return _buildState();
  }

  /// Flush any queued mutations and pull the latest snapshot. Silently tolerates
  /// being offline — the cache already backs the UI.
  Future<void> _trySync() async {
    try {
      await _flushQueue();
      final snapshot = await _remote.fetchSnapshot();
      await _reconcile(snapshot);
    } catch (_) {
      // Offline or backend unreachable: keep serving the cache.
    }
  }

  /// Replay queued mutations in order, stopping at the first failure so order
  /// is preserved for the next attempt.
  Future<void> _flushQueue() async {
    final pending = await _queue.readAll();
    for (final mutation in pending) {
      switch (mutation.kind) {
        case MutationKind.upsertEvent:
          await _remote.upsertEvent(PlannerEvent.fromJson(mutation.payload));
        case MutationKind.deleteEvent:
          await _remote.deleteEvent(mutation.entityId);
        case MutationKind.upsertCalendar:
          await _remote.upsertCalendar(
            PlannerCalendar.fromJson(mutation.payload),
          );
        case MutationKind.renameCalendar:
          await _remote.renameCalendar(
            mutation.entityId,
            mutation.payload['name'] as String? ?? '',
          );
      }
      await _queue.remove(mutation.id);
    }
  }

  /// Merge a freshly fetched server snapshot with still-pending local writes.
  Future<void> _reconcile(RemoteSnapshot snapshot) async {
    final pending = await _queue.readAll();

    // Preserve locally-held holidays (calendar id `public_holidays`) that the
    // server does not know about.
    final holidayCalendars =
        _calendars.where((c) => c.id == 'public_holidays').toList();
    final holidayEvents =
        _events.where((e) => e.calendarId == 'public_holidays').toList();

    // Events: server is the base, then overlay unsynced local mutations.
    final eventsById = <String, PlannerEvent>{
      for (final event in snapshot.events) event.id: event,
    };
    for (final mutation in pending) {
      switch (mutation.kind) {
        case MutationKind.upsertEvent:
          final local = PlannerEvent.fromJson(mutation.payload);
          eventsById[local.id] = local;
        case MutationKind.deleteEvent:
          eventsById.remove(mutation.entityId);
        case MutationKind.upsertCalendar:
        case MutationKind.renameCalendar:
          break;
      }
    }

    // Calendars: server base + locally-pending calendar writes.
    final calendarsById = <String, PlannerCalendar>{
      for (final calendar in snapshot.calendars) calendar.id: calendar,
    };
    for (final mutation in pending) {
      if (mutation.kind == MutationKind.upsertCalendar) {
        final local = PlannerCalendar.fromJson(mutation.payload);
        calendarsById[local.id] = local;
      } else if (mutation.kind == MutationKind.renameCalendar) {
        final existing = calendarsById[mutation.entityId];
        if (existing != null) {
          calendarsById[mutation.entityId] = PlannerCalendar(
            id: existing.id,
            name: mutation.payload['name'] as String? ?? existing.name,
            color: existing.color,
          );
        }
      }
    }

    final mergedCalendars = [
      ...calendarsById.values,
      ...holidayCalendars.where((c) => !calendarsById.containsKey(c.id)),
    ];
    final mergedEvents = [
      ...eventsById.values,
      ...holidayEvents.where((e) => !eventsById.containsKey(e.id)),
    ]..sort((a, b) => a.startAt.compareTo(b.startAt));

    // Keep the user's visibility choices for calendars that survived; show any
    // newly-discovered calendars by default.
    final survivingVisible =
        _visibleIds.where((id) => mergedCalendars.any((c) => c.id == id));
    final knownVisible = survivingVisible.toSet();
    final nextVisible = [
      ...survivingVisible,
      for (final c in mergedCalendars)
        if (!knownVisible.contains(c.id)) c.id,
    ];

    _calendars = mergedCalendars;
    _events = mergedEvents;
    _visibleIds = nextVisible.isEmpty
        ? mergedCalendars.map((c) => c.id).toList()
        : nextVisible;

    await _persistCache();
  }

  Future<void> _persistCache() async {
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
      visibleCalendarIds: _visibleIds.isEmpty
          ? _calendars.map((c) => c.id).toList()
          : List.of(_visibleIds),
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
    return updateEvent(event);
  }

  @override
  Future<PlannerEvent> updateEvent(PlannerEvent event) async {
    // Stamp every write so last-write-wins reconciliation can order edits.
    final stamped = event.copyWith(updatedAt: DateTime.now().toUtc());
    _events = [
      ..._events.where((e) => e.id != stamped.id),
      stamped,
    ]..sort((a, b) => a.startAt.compareTo(b.startAt));
    await _persistCache();
    await _queue.enqueue(
      kind: MutationKind.upsertEvent,
      entityId: stamped.id,
      payload: stamped.toJson(),
    );
    await _pushSoon();
    return stamped;
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    _events = _events.where((e) => e.id != eventId).toList();
    await _persistCache();
    await _queue.enqueue(
      kind: MutationKind.deleteEvent,
      entityId: eventId,
      payload: const {},
    );
    await _pushSoon();
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
    await _persistCache();
    await _queue.enqueue(
      kind: MutationKind.upsertCalendar,
      entityId: calendar.id,
      payload: calendar.toJson(),
    );
    await _pushSoon();
    return calendar;
  }

  @override
  Future<void> renameCalendar(String id, String newName) async {
    _calendars = _calendars
        .map((c) => c.id == id
            ? PlannerCalendar(id: c.id, name: newName, color: c.color)
            : c)
        .toList();
    await _persistCache();
    await _queue.enqueue(
      kind: MutationKind.renameCalendar,
      entityId: id,
      payload: {'name': newName},
    );
    await _pushSoon();
  }

  @override
  Future<bool> saveHolidays(
    PlannerCalendar calendar,
    List<PlannerEvent> events,
  ) async {
    // Holidays are a local convenience and are not synced to the cloud (there
    // is no bulk-import endpoint). Unlike the old cloud repo, we now persist
    // them to the durable cache, so they survive restarts and need not be
    // re-fetched — hence we report `true`.
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
    await _persistCache();
    return true;
  }

  /// Attempt to flush the queue immediately so writes propagate while online,
  /// but never let a network failure surface to the optimistic caller.
  Future<void> _pushSoon() async {
    try {
      await _flushQueue();
    } catch (_) {
      // Stay queued; will retry on the next sync.
    }
  }
}
