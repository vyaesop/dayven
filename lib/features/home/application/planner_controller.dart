import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/http_api_client.dart';
import '../../../core/storage/sqlite_database.dart';
import '../../../core/storage/storage_mode.dart';
import '../data/demo_planner_repository.dart';
import '../data/neon_planner_repository.dart';
import '../data/planner_repository.dart';
import '../data/sqlite_planner_repository.dart';
import '../domain/planner_models.dart';
import '../../bootstrap/application/app_bootstrap_controller.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.current;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  return HttpApiClient(config: config);
});

final sqliteDatabaseFactoryProvider = Provider<SqliteDatabaseFactory>((ref) {
  return SqliteDatabaseFactory();
});

final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  final selectedStorageMode = ref.watch(selectedStorageModeProvider).asData?.value;

  if (selectedStorageMode == StorageMode.localSqlite) {
    final databaseFactory = ref.watch(sqliteDatabaseFactoryProvider);
    return SqlitePlannerRepository(databaseFactory: databaseFactory);
  }

  if (selectedStorageMode == StorageMode.cloudSync && config.hasRemoteBackend) {
    final client = ref.watch(apiClientProvider);
    return NeonPlannerRepository(apiClient: client);
  }

  return DemoPlannerRepository();
});

final plannerControllerProvider =
    AsyncNotifierProvider<PlannerController, PlannerState>(
  PlannerController.new,
);

class PlannerController extends AsyncNotifier<PlannerState> {
  PlannerRepository get _repository => ref.read(plannerRepositoryProvider);

  @override
  Future<PlannerState> build() {
    return _repository.loadInitialState();
  }

  void selectDate(DateTime date) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    final normalized = DateTime(date.year, date.month, date.day);
    state = AsyncData(
      current.copyWith(
        selectedDate: normalized,
        focusedMonth: DateTime(normalized.year, normalized.month),
      ),
    );
  }

  void jumpToToday() {
    selectDate(DateTime.now());
  }

  void toggleCalendarVisibility(String calendarId) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    final visible = List<String>.from(current.visibleCalendarIds);
    if (visible.contains(calendarId)) {
      if (visible.length == 1) {
        return;
      }
      visible.remove(calendarId);
    } else {
      visible.add(calendarId);
    }

    state = AsyncData(current.copyWith(visibleCalendarIds: visible));
  }

  void setAllCalendarsVisible() {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    state = AsyncData(
      current.copyWith(
        visibleCalendarIds:
            current.calendars.map((calendar) => calendar.id).toList(),
      ),
    );
  }

  Future<void> createEvent(PlannerEventDraft draft) async {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    final created = await _repository.createEvent(draft);
    final nextEvents = List<PlannerEvent>.from(current.events)..add(created);
    nextEvents.sort((a, b) => a.startAt.compareTo(b.startAt));

    state = AsyncData(
      current.copyWith(
        selectedDate: DateTime(
          created.startAt.year,
          created.startAt.month,
          created.startAt.day,
        ),
        focusedMonth: DateTime(created.startAt.year, created.startAt.month),
        events: nextEvents,
      ),
    );
  }

  Future<void> updateEvent(PlannerEvent event) async {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    final updated = await _repository.updateEvent(event);
    final nextEvents = current.events
        .map((existing) => existing.id == updated.id ? updated : existing)
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    state = AsyncData(
      current.copyWith(
        selectedDate: DateTime(
          updated.startAt.year,
          updated.startAt.month,
          updated.startAt.day,
        ),
        focusedMonth: DateTime(updated.startAt.year, updated.startAt.month),
        events: nextEvents,
      ),
    );
  }

  Future<void> deleteEvent(String eventId) async {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    await _repository.deleteEvent(eventId);
    final nextEvents =
        current.events.where((event) => event.id != eventId).toList();

    state = AsyncData(current.copyWith(events: nextEvents));
  }
}
