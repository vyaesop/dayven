import 'package:flutter/material.dart';

import '../domain/planner_models.dart';

abstract class PlannerRepository {
  Future<PlannerState> loadInitialState();

  Future<PlannerCalendar> createCalendar(String name, Color color);

  Future<void> renameCalendar(String id, String newName);

  Future<PlannerEvent> createEvent(PlannerEventDraft draft);

  Future<PlannerEvent> updateEvent(PlannerEvent event);

  Future<void> deleteEvent(String eventId);
}
