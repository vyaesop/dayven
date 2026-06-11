import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/home/domain/planner_models.dart';

/// A durable on-device snapshot of the planner so the app opens instantly with
/// the last-known data even before (or without) a network round-trip.
///
/// This replaces the old SQLite store: in the cloud-only model the backend is
/// the source of truth, and this cache is a fast, throwaway mirror that is
/// re-hydrated from the cloud whenever connectivity allows. It is namespaced
/// per signed-in user so switching accounts on one device never leaks data.
class LocalCacheStore {
  LocalCacheStore({String? userId}) : _userId = userId ?? 'anon';

  final String _userId;

  String get _key => 'planner_cache_v1_$_userId';

  Future<PlannerCacheSnapshot?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return PlannerCacheSnapshot.fromJson(decoded);
    } catch (_) {
      // Corrupt cache — drop it rather than crash on launch.
      await prefs.remove(_key);
      return null;
    }
  }

  Future<void> write(PlannerCacheSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(snapshot.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

/// The persisted shape of the cache: calendars, the user's visible-calendar
/// selection, and the raw (unexpanded) events.
class PlannerCacheSnapshot {
  const PlannerCacheSnapshot({
    required this.calendars,
    required this.visibleCalendarIds,
    required this.events,
  });

  final List<PlannerCalendar> calendars;
  final List<String> visibleCalendarIds;
  final List<PlannerEvent> events;

  Map<String, dynamic> toJson() => {
        'calendars': calendars.map((c) => c.toJson()).toList(),
        'visible_calendar_ids': visibleCalendarIds,
        'events': events.map((e) => e.toJson()).toList(),
      };

  factory PlannerCacheSnapshot.fromJson(Map<String, dynamic> json) {
    return PlannerCacheSnapshot(
      calendars: (json['calendars'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(PlannerCalendar.fromJson)
          .toList(),
      visibleCalendarIds: (json['visible_calendar_ids'] as List<dynamic>? ??
              const [])
          .map((e) => e.toString())
          .toList(),
      events: (json['events'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(PlannerEvent.fromJson)
          .toList(),
    );
  }
}
