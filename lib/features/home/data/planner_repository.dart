import 'package:flutter/material.dart';

import '../domain/planner_models.dart';

abstract class PlannerRepository {
  Future<PlannerState> loadInitialState();

  Future<PlannerCalendar> createCalendar(String name, Color color);

  Future<void> renameCalendar(String id, String newName);

  Future<PlannerEvent> createEvent(PlannerEventDraft draft);

  Future<PlannerEvent> updateEvent(PlannerEvent event);

  Future<void> deleteEvent(String eventId);

  /// Persist a public-holidays calendar and its events so they survive app
  /// restarts. Idempotent: re-saving the same holidays must not duplicate rows.
  ///
  /// Returns `true` when the holidays were durably stored (so the caller can
  /// remember not to re-fetch them), or `false` when this repository only holds
  /// them in memory for the current session (e.g. cloud-sync has no bulk-import
  /// endpoint). When `false`, the caller must NOT mark the year as loaded so the
  /// holidays are re-fetched on the next launch.
  Future<bool> saveHolidays(
    PlannerCalendar calendar,
    List<PlannerEvent> events,
  );
}
