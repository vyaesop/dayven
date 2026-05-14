import '../domain/planner_models.dart';

abstract class PlannerRepository {
  Future<PlannerState> loadInitialState();

  Future<PlannerEvent> createEvent(PlannerEventDraft draft);

  Future<PlannerEvent> updateEvent(PlannerEvent event);

  Future<void> deleteEvent(String eventId);
}
