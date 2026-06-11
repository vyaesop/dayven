import '../../../core/network/api_client.dart';
import '../domain/planner_models.dart';
import 'remote_planner_api.dart';

/// [RemotePlannerApi] backed by the Neon-on-Cloudflare HTTP API.
///
/// Writes use client-generated ids via idempotent upserts (`PUT .../:id`) so
/// the offline queue can replay them safely.
class NeonPlannerApi implements RemotePlannerApi {
  NeonPlannerApi({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<RemoteSnapshot> fetchSnapshot({DateTime? since}) async {
    final response = await _apiClient.getJson(
      '/v1/planner',
      queryParameters: {
        'date': DateTime.now().toIso8601String(),
        if (since != null) 'since': since.toUtc().toIso8601String(),
      },
    );

    final calendarsJson = (response['calendars'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final eventsJson =
        (response['events'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    return RemoteSnapshot(
      calendars: calendarsJson.map(PlannerCalendar.fromJson).toList(),
      events: eventsJson.map(PlannerEvent.fromJson).toList(),
    );
  }

  @override
  Future<void> upsertEvent(PlannerEvent event) async {
    // PUT by id is an upsert on the backend, so the same call covers both
    // create and update and is safe to replay from the offline queue.
    await _apiClient.putJson('/v1/events/${event.id}', body: event.toJson());
  }

  @override
  Future<void> deleteEvent(String eventId) {
    return _apiClient.delete('/v1/events/$eventId');
  }

  @override
  Future<void> upsertCalendar(PlannerCalendar calendar) async {
    await _apiClient.putJson('/v1/calendars/${calendar.id}', body: {
      'name': calendar.name,
      'color': PlannerCalendar.colorToHex(calendar.color),
    });
  }

  @override
  Future<void> renameCalendar(String id, String newName) async {
    await _apiClient.putJson('/v1/calendars/$id', body: {'name': newName});
  }
}
