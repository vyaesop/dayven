import '../domain/planner_models.dart';

/// A point-in-time view of the user's planner as held by the cloud backend.
class RemoteSnapshot {
  const RemoteSnapshot({required this.calendars, required this.events});

  final List<PlannerCalendar> calendars;
  final List<PlannerEvent> events;
}

/// The cloud backend operations the offline-first repository drives.
///
/// Every write is an idempotent **upsert keyed by a client-generated id**, so
/// the offline mutation queue can replay safely after a crash or reconnect
/// without creating duplicates. Deletes are no-ops when the row is already
/// gone. Implementations should throw on transport/HTTP failure so the caller
/// can keep the mutation queued and retry later.
abstract class RemotePlannerApi {
  /// Fetch the full snapshot. [since] enables a future delta sync; null means
  /// "everything".
  Future<RemoteSnapshot> fetchSnapshot({DateTime? since});

  /// Create or replace an event by its id.
  Future<void> upsertEvent(PlannerEvent event);

  /// Delete an event by id (idempotent).
  Future<void> deleteEvent(String eventId);

  /// Create or replace a calendar by its id.
  Future<void> upsertCalendar(PlannerCalendar calendar);

  /// Rename a calendar.
  Future<void> renameCalendar(String id, String newName);
}
