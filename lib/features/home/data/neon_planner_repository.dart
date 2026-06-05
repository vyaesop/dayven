import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../domain/planner_models.dart';
import 'planner_repository.dart';

class NeonPlannerRepository implements PlannerRepository {
  NeonPlannerRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<PlannerState> loadInitialState() async {
    final response = await _apiClient.getJson(
      '/v1/planner',
      queryParameters: {'date': DateTime.now().toIso8601String()},
    );

    final calendarsJson = (response['calendars'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final eventsJson = (response['events'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    return PlannerState(
      selectedDate: DateTime.parse(
        response['selected_date'] as String? ??
            DateTime.now().toIso8601String(),
      ),
      focusedMonth: DateTime.parse(
        response['focused_month'] as String? ??
            DateTime.now().toIso8601String(),
      ),
      calendars: calendarsJson.map(_calendarFromJson).toList(),
      visibleCalendarIds: calendarsJson
          .map((calendar) => calendar['id'] as String)
          .toList(),
      events: eventsJson.map(PlannerEvent.fromJson).toList(),
    );
  }

  @override
  Future<PlannerEvent> createEvent(PlannerEventDraft draft) async {
    final response = await _apiClient.postJson(
      '/v1/events',
      body: draft.toJson(),
    );
    return PlannerEvent.fromJson(response['event'] as Map<String, dynamic>);
  }

  @override
  Future<PlannerEvent> updateEvent(PlannerEvent event) async {
    final response = await _apiClient.putJson(
      '/v1/events/${event.id}',
      body: event.toJson(),
    );
    return PlannerEvent.fromJson(response['event'] as Map<String, dynamic>);
  }

  @override
  Future<void> renameCalendar(String id, String newName) async {
    await _apiClient.putJson('/v1/calendars/$id', body: {'name': newName});
  }

  @override
  Future<PlannerCalendar> createCalendar(String name, Color color) async {
    final r = (color.r * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    final hex = '#$r$g$b'.toUpperCase();
    final response = await _apiClient.postJson(
      '/v1/calendars',
      body: {'name': name, 'color': hex},
    );
    return _calendarFromJson(response['calendar'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteEvent(String eventId) {
    return _apiClient.delete('/v1/events/$eventId');
  }

  PlannerCalendar _calendarFromJson(Map<String, dynamic> json) {
    return PlannerCalendar(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Calendar',
      color: _parseColor(json['color'] as String?),
    );
  }

  Color _parseColor(String? hex) {
    return parsePlannerColor(hex);
  }
}
