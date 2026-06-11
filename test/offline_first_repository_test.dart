import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vertical_planner/core/storage/local_cache_store.dart';
import 'package:vertical_planner/core/storage/mutation_queue.dart';
import 'package:vertical_planner/features/home/data/offline_first_planner_repository.dart';
import 'package:vertical_planner/features/home/data/remote_planner_api.dart';
import 'package:vertical_planner/features/home/domain/planner_models.dart';

/// A controllable fake of the cloud API: it holds an in-memory store and can be
/// switched "offline" to simulate a flaky/absent connection.
class FakeRemoteApi implements RemotePlannerApi {
  final Map<String, PlannerEvent> events = {};
  final Map<String, PlannerCalendar> calendars = {};
  bool online = true;

  void _guard() {
    if (!online) throw Exception('offline');
  }

  @override
  Future<RemoteSnapshot> fetchSnapshot({DateTime? since}) async {
    _guard();
    return RemoteSnapshot(
      calendars: calendars.values.toList(),
      events: events.values.toList(),
    );
  }

  @override
  Future<void> upsertEvent(PlannerEvent event) async {
    _guard();
    events[event.id] = event;
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    _guard();
    events.remove(eventId);
  }

  @override
  Future<void> upsertCalendar(PlannerCalendar calendar) async {
    _guard();
    calendars[calendar.id] = calendar;
  }

  @override
  Future<void> renameCalendar(String id, String newName) async {
    _guard();
    final existing = calendars[id];
    if (existing != null) {
      calendars[id] = PlannerCalendar(
        id: id,
        name: newName,
        color: existing.color,
      );
    }
  }
}

PlannerEventDraft draft(String title) => PlannerEventDraft(
      title: title,
      isAllDay: false,
      startAt: DateTime(2026, 6, 1, 9),
      endAt: DateTime(2026, 6, 1, 10),
      location: '',
      url: '',
      note: '',
      calendarId: 'calendar',
      reminder: PlannerReminder.none,
      repeatRule: PlannerRepeatRule.never,
      attendees: const [],
    );

OfflineFirstPlannerRepository buildRepo(FakeRemoteApi remote) {
  return OfflineFirstPlannerRepository(
    remote: remote,
    cache: LocalCacheStore(userId: 'u1'),
    queue: MutationQueue(userId: 'u1'),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('event created while offline is queued and surfaced locally', () async {
    final remote = FakeRemoteApi()..online = false;
    final repo = buildRepo(remote);
    await repo.loadInitialState();

    final created = await repo.createEvent(draft('Offline event'));

    // Server never saw it...
    expect(remote.events, isEmpty);
    // ...but it's queued for upload...
    final queued = await MutationQueue(userId: 'u1').readAll();
    expect(queued, hasLength(1));
    expect(queued.single.kind, MutationKind.upsertEvent);
    // ...and it survives a fresh load from the durable cache.
    final reopened = buildRepo(remote);
    final state = await reopened.loadInitialState();
    expect(state.events.where((e) => e.id == created.id), hasLength(1));
  });

  test('queued mutations flush once the connection returns', () async {
    final remote = FakeRemoteApi()..online = false;
    final repo = buildRepo(remote);
    await repo.loadInitialState();
    final created = await repo.createEvent(draft('Pending'));

    // Reconnect and reload: the queue should drain to the server.
    remote.online = true;
    final state = await buildRepo(remote).loadInitialState();

    expect(remote.events.containsKey(created.id), isTrue);
    expect(await MutationQueue(userId: 'u1').isEmpty, isTrue);
    expect(state.events.where((e) => e.id == created.id), hasLength(1));
  });

  test('unsynced local edit wins over the server copy on reconcile', () async {
    final remote = FakeRemoteApi();
    final repo = buildRepo(remote);
    await repo.loadInitialState();

    // Create + sync an event.
    final created = await repo.createEvent(draft('Title v1'));
    expect(remote.events[created.id]!.title, 'Title v1');

    // Go offline, edit locally (queued), then reconnect and reload.
    remote.online = false;
    await repo.updateEvent(created.copyWith(title: 'Title v2 (local)'));
    remote.online = true;
    final state = await buildRepo(remote).loadInitialState();

    final result = state.events.firstWhere((e) => e.id == created.id);
    expect(result.title, 'Title v2 (local)');
    expect(remote.events[created.id]!.title, 'Title v2 (local)');
  });

  test('delete while offline removes locally and clears server on reconnect',
      () async {
    final remote = FakeRemoteApi();
    final repo = buildRepo(remote);
    await repo.loadInitialState();
    final created = await repo.createEvent(draft('To delete'));

    remote.online = false;
    await repo.deleteEvent(created.id);
    remote.online = true;
    final state = await buildRepo(remote).loadInitialState();

    expect(state.events.where((e) => e.id == created.id), isEmpty);
    expect(remote.events.containsKey(created.id), isFalse);
  });
}
