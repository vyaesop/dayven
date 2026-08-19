import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../features/home/application/planner_controller.dart';
import '../../features/home/domain/planner_models.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';

/// Whether AI quick-capture can be offered. It needs the cloud backend that
/// proxies the model call - the API key lives only on the server, never in the
/// app, so without a remote backend there's nothing to call.
final aiCaptureAvailableProvider = Provider<bool>((ref) {
  return ref.watch(appConfigProvider).hasRemoteBackend;
});

final aiEventServiceProvider = Provider<AiEventService>((ref) {
  return AiEventService(apiClient: ref.watch(apiClientProvider));
});

/// Turns a plain-language description ("lunch with Sara Thu 1pm at Café Lima,
/// remind me 30 min before") into a reviewable [PlannerEventDraft].
///
/// The model is never called from the client - this posts to the backend
/// `/v1/ai/parse-event` proxy (Firebase-auth-gated, key held server-side) and
/// maps the normalized JSON it returns onto the same draft the editor builds.
class AiEventService {
  AiEventService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<PlannerEventDraft> parse({
    required String text,
    required List<PlannerCalendar> calendars,
    String? defaultCalendarId,
    DateTime? now,
    DateTime? fallbackDate,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const ApiException(message: 'Type a few words first.');
    }

    final when = now ?? DateTime.now();
    final response = await _apiClient.postJson('/v1/ai/parse-event', body: {
      'text': trimmed,
      'now_local': DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(when),
      'weekday': DateFormat('EEEE').format(when),
      'timezone': when.timeZoneName,
      'utc_offset_minutes': when.timeZoneOffset.inMinutes,
      'calendars': [
        for (final calendar in calendars)
          {'id': calendar.id, 'name': calendar.name},
      ],
    });

    final parsed = response['parsed'];
    if (parsed is! Map<String, dynamic>) {
      throw const ApiException(message: 'No event could be read from that.');
    }

    return _draftFromParsed(
      parsed,
      calendars: calendars,
      defaultCalendarId: defaultCalendarId,
      fallbackDate: fallbackDate ?? when,
    );
  }

  PlannerEventDraft _draftFromParsed(
    Map<String, dynamic> json, {
    required List<PlannerCalendar> calendars,
    String? defaultCalendarId,
    required DateTime fallbackDate,
  }) {
    final title = (json['title'] as String?)?.trim();
    final isAllDay = json['isAllDay'] as bool? ?? false;

    final parsedStart = _parseLocal(json['start'] as String?);
    final parsedEnd = _parseLocal(json['end'] as String?);
    final baseDate = parsedStart ?? fallbackDate;

    final DateTime startAt;
    final DateTime endAt;
    if (isAllDay) {
      // Mirror the manual editor: all-day spans [day, next day midnight).
      startAt = DateTime(baseDate.year, baseDate.month, baseDate.day);
      endAt = startAt.add(const Duration(days: 1));
    } else {
      startAt = parsedStart ??
          DateTime(baseDate.year, baseDate.month, baseDate.day, 9);
      var end = parsedEnd ?? startAt.add(const Duration(hours: 1));
      if (!end.isAfter(startAt)) {
        // An end at/before the start reads as crossing midnight (e.g. 23:00 →
        // 01:00); a missing end just gets an hour. Same as the editor.
        end = parsedEnd == null
            ? startAt.add(const Duration(hours: 1))
            : end.add(const Duration(days: 1));
      }
      endAt = end;
    }

    final recurrence = _recurrenceFromJson(json['recurrence']);

    return PlannerEventDraft(
      title: (title == null || title.isEmpty) ? 'New event' : title,
      isAllDay: isAllDay,
      startAt: startAt,
      endAt: endAt,
      location: (json['location'] as String?)?.trim() ?? '',
      url: (json['url'] as String?)?.trim() ?? '',
      note: (json['note'] as String?)?.trim() ?? '',
      calendarId: _resolveCalendar(
        (json['calendarId'] as String?)?.trim(),
        calendars: calendars,
        defaultCalendarId: defaultCalendarId,
      ),
      reminder: plannerReminderFromStorage(json['reminder'] as String?),
      repeatRule: recurrence.frequency,
      attendees: _stringList(json['attendees']),
      recurrence: recurrence,
    );
  }

  static DateTime? _parseLocal(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static List<String> _stringList(Object? value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  String _resolveCalendar(
    String? requested, {
    required List<PlannerCalendar> calendars,
    String? defaultCalendarId,
  }) {
    bool exists(String? id) =>
        id != null && calendars.any((calendar) => calendar.id == id);

    if (exists(requested)) return requested!;
    if (exists(defaultCalendarId)) return defaultCalendarId!;
    return calendars.isNotEmpty ? calendars.first.id : 'calendar';
  }

  PlannerRecurrence _recurrenceFromJson(Object? value) {
    if (value is! Map<String, dynamic>) return PlannerRecurrence.none;

    final frequency = PlannerRepeatRule.values.firstWhere(
      (rule) => rule.storageValue == (value['frequency'] as String?),
      orElse: () => PlannerRepeatRule.never,
    );
    if (frequency == PlannerRepeatRule.never) return PlannerRecurrence.none;

    // "2 weeks" is modelled as the biweekly frequency with interval 1 (the
    // editor doubles it for display), so normalize to avoid "every 4 weeks".
    final rawInterval = (value['interval'] as num?)?.toInt() ?? 1;
    final interval =
        frequency == PlannerRepeatRule.biweekly ? 1 : rawInterval.clamp(1, 999);

    final byWeekdays = <int>{
      for (final day in (value['byWeekdays'] as List? ?? const []))
        if (day is num && day >= 1 && day <= 7) day.toInt(),
    };

    final count = (value['count'] as num?)?.toInt();
    final until = _parseLocal(value['until'] as String?);

    final endMode = until != null
        ? RecurrenceEndMode.onDate
        : (count != null && count > 0)
            ? RecurrenceEndMode.afterCount
            : RecurrenceEndMode.never;

    return PlannerRecurrence(
      frequency: frequency,
      interval: interval,
      byWeekdays: byWeekdays,
      endMode: endMode,
      count: (count ?? 1).clamp(1, 999),
      until: until,
    );
  }
}
