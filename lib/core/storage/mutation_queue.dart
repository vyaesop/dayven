import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../util/id_generator.dart';

/// The kind of change a queued mutation represents.
enum MutationKind {
  upsertEvent,
  deleteEvent,
  upsertCalendar,
  renameCalendar,
}

MutationKind _kindFromString(String value) {
  return MutationKind.values.firstWhere(
    (k) => k.name == value,
    orElse: () => MutationKind.upsertEvent,
  );
}

/// A single change made locally that still needs to be pushed to the cloud.
///
/// Mutations are designed to be idempotent so replaying them after a crash or
/// reconnect is safe: event/calendar writes are upserts keyed by a
/// client-generated id, and deletes are no-ops if the row is already gone.
class PendingMutation {
  PendingMutation({
    required this.id,
    required this.kind,
    required this.entityId,
    required this.payload,
    required this.queuedAt,
  });

  /// Unique id of this queue entry (not the entity).
  final String id;
  final MutationKind kind;

  /// The id of the event/calendar this mutation targets. Used to collapse
  /// superseded mutations (a newer edit of the same entity replaces an older
  /// pending one).
  final String entityId;
  final Map<String, dynamic> payload;
  final DateTime queuedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'entity_id': entityId,
        'payload': payload,
        'queued_at': queuedAt.toUtc().toIso8601String(),
      };

  factory PendingMutation.fromJson(Map<String, dynamic> json) {
    return PendingMutation(
      id: json['id'] as String,
      kind: _kindFromString(json['kind'] as String? ?? ''),
      entityId: json['entity_id'] as String? ?? '',
      payload: (json['payload'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
      queuedAt:
          DateTime.tryParse(json['queued_at'] as String? ?? '')?.toUtc() ??
              DateTime.now().toUtc(),
    );
  }
}

/// A durable FIFO queue of mutations awaiting upload, namespaced per user.
class MutationQueue {
  MutationQueue({String? userId}) : _userId = userId ?? 'anon';

  final String _userId;

  String get _key => 'planner_mutation_queue_v1_$_userId';

  Future<List<PendingMutation>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .cast<Map<String, dynamic>>()
          .map(PendingMutation.fromJson)
          .toList();
    } catch (_) {
      await prefs.remove(_key);
      return [];
    }
  }

  Future<void> _writeAll(List<PendingMutation> mutations) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(mutations.map((m) => m.toJson()).toList()),
    );
  }

  /// Append a mutation. Any earlier *pending* mutation of the same kind for the
  /// same entity is dropped first, so we only upload the latest intent (e.g.
  /// editing an event three times offline uploads once). Deletes also clear
  /// any pending upserts for that entity.
  Future<void> enqueue({
    required MutationKind kind,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    final current = await readAll();
    current.removeWhere((m) {
      if (m.entityId != entityId) return false;
      if (kind == MutationKind.deleteEvent) {
        // A delete supersedes any queued upsert/rename for the same entity.
        return true;
      }
      return m.kind == kind;
    });
    current.add(
      PendingMutation(
        id: IdGenerator.uuidV4(),
        kind: kind,
        entityId: entityId,
        payload: payload,
        queuedAt: DateTime.now().toUtc(),
      ),
    );
    await _writeAll(current);
  }

  Future<void> remove(String mutationId) async {
    final current = await readAll();
    current.removeWhere((m) => m.id == mutationId);
    await _writeAll(current);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<bool> get isEmpty async => (await readAll()).isEmpty;
}
