import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LocalRsvpStatus { awaiting, accepted, maybe, declined }

extension LocalRsvpStatusX on LocalRsvpStatus {
  String get label {
    return switch (this) {
      LocalRsvpStatus.awaiting => 'Awaiting',
      LocalRsvpStatus.accepted => 'Accepted',
      LocalRsvpStatus.maybe => 'Maybe',
      LocalRsvpStatus.declined => 'Declined',
    };
  }
}

final localRsvpControllerProvider =
    AsyncNotifierProvider<LocalRsvpController, Map<String, LocalRsvpStatus>>(
      LocalRsvpController.new,
    );

class LocalRsvpController extends AsyncNotifier<Map<String, LocalRsvpStatus>> {
  static const _responsesKey = 'local_rsvp_responses';

  @override
  Future<Map<String, LocalRsvpStatus>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_responsesKey);
    if (raw == null || raw.trim().isEmpty) {
      return const {};
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((eventId, status) {
        return MapEntry(eventId, _parseStatus(status?.toString()));
      });
    } catch (_) {
      return const {};
    }
  }

  Future<void> setStatus(String eventId, LocalRsvpStatus status) async {
    final current = state.asData?.value ?? const <String, LocalRsvpStatus>{};
    final next = Map<String, LocalRsvpStatus>.from(current);
    if (status == LocalRsvpStatus.awaiting) {
      next.remove(eventId);
    } else {
      next[eventId] = status;
    }
    state = AsyncData(next);
    await _save(next);
  }

  Future<void> clearAll() async {
    state = const AsyncData({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_responsesKey);
  }

  Future<void> _save(Map<String, LocalRsvpStatus> responses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _responsesKey,
      jsonEncode(
        responses.map((eventId, status) => MapEntry(eventId, status.name)),
      ),
    );
  }

  LocalRsvpStatus _parseStatus(String? value) {
    return LocalRsvpStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => LocalRsvpStatus.awaiting,
    );
  }
}
