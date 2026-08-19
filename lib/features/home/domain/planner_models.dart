import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum PlannerReminder {
  none,
  atTime,
  fiveMinutesBefore,
  tenMinutesBefore,
  fifteenMinutesBefore,
  thirtyMinutesBefore,
  oneHourBefore,
  twoHoursBefore,
  oneDayBefore,
  oneWeekBefore,
}

extension PlannerReminderX on PlannerReminder {
  String get storageValue {
    switch (this) {
      case PlannerReminder.none:
        return 'none';
      case PlannerReminder.atTime:
        return 'at_time';
      case PlannerReminder.fiveMinutesBefore:
        return '5_min_before';
      case PlannerReminder.tenMinutesBefore:
        return '10_min_before';
      case PlannerReminder.fifteenMinutesBefore:
        return '15_min_before';
      case PlannerReminder.thirtyMinutesBefore:
        return '30_min_before';
      case PlannerReminder.oneHourBefore:
        return '1_hour_before';
      case PlannerReminder.twoHoursBefore:
        return '2_hours_before';
      case PlannerReminder.oneDayBefore:
        return '1_day_before';
      case PlannerReminder.oneWeekBefore:
        return '1_week_before';
    }
  }

  String get label {
    switch (this) {
      case PlannerReminder.none:
        return 'No reminder';
      case PlannerReminder.atTime:
        return 'When event starts';
      case PlannerReminder.fiveMinutesBefore:
        return '5 minutes before';
      case PlannerReminder.tenMinutesBefore:
        return '10 minutes before';
      case PlannerReminder.fifteenMinutesBefore:
        return '15 minutes before';
      case PlannerReminder.thirtyMinutesBefore:
        return '30 minutes before';
      case PlannerReminder.oneHourBefore:
        return '1 hour before';
      case PlannerReminder.twoHoursBefore:
        return '2 hours before';
      case PlannerReminder.oneDayBefore:
        return '1 day before';
      case PlannerReminder.oneWeekBefore:
        return '1 week before';
    }
  }
}

PlannerReminder plannerReminderFromStorage(String? value) {
  for (final reminder in PlannerReminder.values) {
    if (reminder.storageValue == value) {
      return reminder;
    }
  }

  return PlannerReminder.none;
}

enum PlannerRepeatRule { never, daily, weekly, biweekly, monthly, yearly }

extension PlannerRepeatRuleX on PlannerRepeatRule {
  String get storageValue {
    switch (this) {
      case PlannerRepeatRule.never:
        return 'never';
      case PlannerRepeatRule.daily:
        return 'daily';
      case PlannerRepeatRule.weekly:
        return 'weekly';
      case PlannerRepeatRule.biweekly:
        return 'biweekly';
      case PlannerRepeatRule.monthly:
        return 'monthly';
      case PlannerRepeatRule.yearly:
        return 'yearly';
    }
  }

  String get label {
    switch (this) {
      case PlannerRepeatRule.never:
        return 'Never';
      case PlannerRepeatRule.daily:
        return 'Every day';
      case PlannerRepeatRule.weekly:
        return 'Every week';
      case PlannerRepeatRule.biweekly:
        return 'Every 2 weeks';
      case PlannerRepeatRule.monthly:
        return 'Every month';
      case PlannerRepeatRule.yearly:
        return 'Every year';
    }
  }
}

PlannerRepeatRule plannerRepeatRuleFromStorage(String? value) {
  // Back-compat: the column historically stored just the frequency token
  // ("weekly"). It now stores a full encoded recurrence; if a caller only
  // wants the base frequency we parse the recurrence and read its frequency.
  for (final rule in PlannerRepeatRule.values) {
    if (rule.storageValue == value) {
      return rule;
    }
  }
  return PlannerRecurrence.parse(value).frequency;
}

/// How a recurring series stops repeating.
enum RecurrenceEndMode { never, afterCount, onDate }

/// A full recurrence specification: base frequency plus interval, the weekdays
/// it lands on (for weekly/biweekly), an end condition, and per-occurrence
/// exceptions (dates the user has detached or deleted from the series).
///
/// Persisted inside the existing `repeat_rule` string column as a compact,
/// back-compatible token, e.g. `freq=weekly;int=2;by=1,3;end=count:10`.
class PlannerRecurrence {
  const PlannerRecurrence({
    this.frequency = PlannerRepeatRule.never,
    this.interval = 1,
    this.byWeekdays = const <int>{},
    this.endMode = RecurrenceEndMode.never,
    this.count = 1,
    this.until,
    this.exceptions = const <DateTime>{},
  });

  /// Base frequency. `never` means the event does not repeat.
  final PlannerRepeatRule frequency;

  /// Repeat every [interval] units of [frequency]. Always >= 1.
  final int interval;

  /// Weekdays (DateTime.monday..DateTime.sunday, i.e. 1..7) the event lands on
  /// for weekly/biweekly rules. Empty means "use the anchor's weekday".
  final Set<int> byWeekdays;

  final RecurrenceEndMode endMode;

  /// Number of occurrences when [endMode] is [RecurrenceEndMode.afterCount].
  final int count;

  /// Last allowed date (inclusive) when [endMode] is [RecurrenceEndMode.onDate].
  final DateTime? until;

  /// Date-only occurrences that have been detached/deleted from the series.
  final Set<DateTime> exceptions;

  static const PlannerRecurrence none = PlannerRecurrence();

  bool get repeats => frequency != PlannerRepeatRule.never;
  bool get isNone => frequency == PlannerRepeatRule.never;

  PlannerRecurrence copyWith({
    PlannerRepeatRule? frequency,
    int? interval,
    Set<int>? byWeekdays,
    RecurrenceEndMode? endMode,
    int? count,
    DateTime? until,
    Set<DateTime>? exceptions,
  }) {
    return PlannerRecurrence(
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      byWeekdays: byWeekdays ?? this.byWeekdays,
      endMode: endMode ?? this.endMode,
      count: count ?? this.count,
      until: until ?? this.until,
      exceptions: exceptions ?? this.exceptions,
    );
  }

  PlannerRecurrence addException(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return copyWith(exceptions: {...exceptions, normalized});
  }

  /// Human-readable summary for the editor row, e.g. "Every 2 weeks on Mon, Wed".
  String get summary {
    if (!repeats) return 'Never';
    final unit = switch (frequency) {
      PlannerRepeatRule.daily => 'day',
      PlannerRepeatRule.weekly => 'week',
      PlannerRepeatRule.biweekly => 'week',
      PlannerRepeatRule.monthly => 'month',
      PlannerRepeatRule.yearly => 'year',
      PlannerRepeatRule.never => '',
    };
    final effectiveInterval =
        frequency == PlannerRepeatRule.biweekly ? interval * 2 : interval;
    final every = effectiveInterval == 1
        ? 'Every $unit'
        : 'Every $effectiveInterval ${unit}s';
    final parts = <String>[every];
    if ((frequency == PlannerRepeatRule.weekly ||
            frequency == PlannerRepeatRule.biweekly) &&
        byWeekdays.isNotEmpty) {
      const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final days = (byWeekdays.toList()..sort())
          .map((d) => names[(d - 1).clamp(0, 6)])
          .join(', ');
      parts.add('on $days');
    }
    switch (endMode) {
      case RecurrenceEndMode.never:
        break;
      case RecurrenceEndMode.afterCount:
        parts.add('· $count times');
      case RecurrenceEndMode.onDate:
        if (until != null) {
          parts.add('· until ${DateFormat('d MMM yyyy').format(until!)}');
        }
    }
    return parts.join(' ');
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
  static String _dateToken(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

  static DateTime? _parseDate(String raw) {
    final parts = raw.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  /// Encode to the compact string stored in `repeat_rule`.
  String encode() {
    if (!repeats) return PlannerRepeatRule.never.storageValue;
    final parts = <String>['freq=${frequency.storageValue}', 'int=$interval'];
    if (byWeekdays.isNotEmpty) {
      parts.add('by=${(byWeekdays.toList()..sort()).join(',')}');
    }
    switch (endMode) {
      case RecurrenceEndMode.never:
        break;
      case RecurrenceEndMode.afterCount:
        parts.add('end=count:$count');
      case RecurrenceEndMode.onDate:
        if (until != null) parts.add('end=until:${_dateToken(until!)}');
    }
    if (exceptions.isNotEmpty) {
      final sorted = exceptions.toList()..sort();
      parts.add('ex=${sorted.map(_dateToken).join(',')}');
    }
    return parts.join(';');
  }

  /// Parse from storage. Accepts both the legacy plain frequency token
  /// ("weekly") and the rich `key=value;...` format.
  static PlannerRecurrence parse(String? raw) {
    final input = raw?.trim() ?? '';
    if (input.isEmpty) return none;
    if (!input.contains('=')) {
      // Legacy plain frequency token.
      final freq = PlannerRepeatRule.values.firstWhere(
        (r) => r.storageValue == input,
        orElse: () => PlannerRepeatRule.never,
      );
      return freq == PlannerRepeatRule.never
          ? none
          : PlannerRecurrence(frequency: freq);
    }

    var frequency = PlannerRepeatRule.never;
    var interval = 1;
    final weekdays = <int>{};
    var endMode = RecurrenceEndMode.never;
    var count = 1;
    DateTime? until;
    final exceptions = <DateTime>{};

    for (final pair in input.split(';')) {
      final idx = pair.indexOf('=');
      if (idx <= 0) continue;
      final key = pair.substring(0, idx).trim();
      final value = pair.substring(idx + 1).trim();
      switch (key) {
        case 'freq':
          frequency = PlannerRepeatRule.values.firstWhere(
            (r) => r.storageValue == value,
            orElse: () => PlannerRepeatRule.never,
          );
        case 'int':
          interval = (int.tryParse(value) ?? 1).clamp(1, 999);
        case 'by':
          for (final d in value.split(',')) {
            final wd = int.tryParse(d.trim());
            if (wd != null && wd >= 1 && wd <= 7) weekdays.add(wd);
          }
        case 'end':
          if (value.startsWith('count:')) {
            endMode = RecurrenceEndMode.afterCount;
            count = (int.tryParse(value.substring(6)) ?? 1).clamp(1, 999);
          } else if (value.startsWith('until:')) {
            final parsed = _parseDate(value.substring(6));
            if (parsed != null) {
              endMode = RecurrenceEndMode.onDate;
              until = parsed;
            }
          }
        case 'ex':
          for (final token in value.split(',')) {
            final parsed = _parseDate(token.trim());
            if (parsed != null) exceptions.add(parsed);
          }
      }
    }

    if (frequency == PlannerRepeatRule.never) return none;
    return PlannerRecurrence(
      frequency: frequency,
      interval: interval,
      byWeekdays: weekdays,
      endMode: endMode,
      count: count,
      until: until,
      exceptions: exceptions,
    );
  }

  /// Yields the date-only occurrence dates of this series, starting at
  /// [anchorDate] (the series' first day) and stopping at [rangeEnd]
  /// (inclusive) or when the end condition is reached. Exceptions are skipped
  /// in the output but still count toward an "after N times" limit.
  ///
  /// [rangeStart] is an optional lower bound: for open-ended rules (no "after N
  /// times" limit) iteration fast-forwards to near [rangeStart] so a very old
  /// anchor (e.g. a daily event created years ago) doesn't exhaust the safety
  /// cap before reaching the requested window. It never affects which dates are
  /// produced - only how far ahead iteration begins. "After N times" rules are
  /// not fast-forwarded because every occurrence must be counted from the
  /// anchor (and such rules are already bounded by [count]).
  Iterable<DateTime> occurrenceDates(
    DateTime anchorDate,
    DateTime rangeEnd, {
    DateTime? rangeStart,
  }) sync* {
    if (!repeats) {
      if (!anchorDate.isAfter(rangeEnd)) yield anchorDate;
      return;
    }

    final anchor = DateTime(anchorDate.year, anchorDate.month, anchorDate.day);
    final hardEnd = endMode == RecurrenceEndMode.onDate ? until : null;
    var produced = 0;
    const safetyCap = 4000;

    // Fast-forwarding is only safe when we don't need to count occurrences from
    // the anchor. We deliberately under-skip (truncating division) so we never
    // jump past a real occurrence - at worst a few extra iterations run.
    final canSkip = endMode != RecurrenceEndMode.afterCount;
    final lowerBound = (rangeStart != null &&
            rangeStart.isAfter(anchor))
        ? DateTime(rangeStart.year, rangeStart.month, rangeStart.day)
        : null;

    bool limitReached() => endMode == RecurrenceEndMode.afterCount && produced >= count;

    switch (frequency) {
      case PlannerRepeatRule.never:
        return;
      case PlannerRepeatRule.daily:
        var d = anchor;
        if (canSkip && lowerBound != null) {
          final steps = lowerBound.difference(anchor).inDays ~/ interval;
          if (steps > 0) d = anchor.add(Duration(days: steps * interval));
        }
        for (var i = 0; i < safetyCap; i++) {
          if (limitReached()) return;
          if (hardEnd != null && d.isAfter(hardEnd)) return;
          if (d.isAfter(rangeEnd)) return;
          if (!exceptions.contains(d)) yield d;
          produced++;
          d = d.add(Duration(days: interval));
        }
      case PlannerRepeatRule.weekly:
      case PlannerRepeatRule.biweekly:
        final weekdays = byWeekdays.isEmpty
            ? <int>[anchor.weekday]
            : (byWeekdays.toList()..sort());
        final weekStep = frequency == PlannerRepeatRule.biweekly
            ? interval * 2
            : interval;
        var weekStart =
            anchor.subtract(Duration(days: anchor.weekday - DateTime.monday));
        if (canSkip && lowerBound != null) {
          final cycles =
              (lowerBound.difference(weekStart).inDays ~/ 7) ~/ weekStep;
          if (cycles > 0) {
            weekStart = weekStart.add(Duration(days: 7 * weekStep * cycles));
          }
        }
        for (var i = 0; i < safetyCap; i++) {
          for (final wd in weekdays) {
            final d = weekStart.add(Duration(days: wd - DateTime.monday));
            if (d.isBefore(anchor)) continue;
            if (limitReached()) return;
            if (hardEnd != null && d.isAfter(hardEnd)) return;
            if (d.isAfter(rangeEnd)) return;
            if (!exceptions.contains(d)) yield d;
            produced++;
          }
          weekStart = weekStart.add(Duration(days: 7 * weekStep));
        }
      case PlannerRepeatRule.monthly:
        var year = anchor.year;
        var month = anchor.month;
        final dom = anchor.day;
        if (canSkip && lowerBound != null) {
          final monthsDiff =
              (lowerBound.year - anchor.year) * 12 + (lowerBound.month - anchor.month);
          final cycles = monthsDiff ~/ interval;
          if (cycles > 0) {
            final base = (anchor.month - 1) + interval * cycles;
            year = anchor.year + base ~/ 12;
            month = base % 12 + 1;
          }
        }
        for (var i = 0; i < safetyCap; i++) {
          final dim = DateUtils.getDaysInMonth(year, month);
          final d = DateTime(year, month, dom.clamp(1, dim));
          if (limitReached()) return;
          if (hardEnd != null && d.isAfter(hardEnd)) return;
          if (d.isAfter(rangeEnd)) return;
          if (!d.isBefore(anchor) && !exceptions.contains(d)) yield d;
          produced++;
          month += interval;
          while (month > 12) {
            month -= 12;
            year++;
          }
        }
      case PlannerRepeatRule.yearly:
        var year = anchor.year;
        final month = anchor.month;
        final dom = anchor.day;
        if (canSkip && lowerBound != null && lowerBound.year > anchor.year) {
          final cycles = (lowerBound.year - anchor.year) ~/ interval;
          if (cycles > 0) year = anchor.year + interval * cycles;
        }
        for (var i = 0; i < safetyCap; i++) {
          final dim = DateUtils.getDaysInMonth(year, month);
          final d = DateTime(year, month, dom.clamp(1, dim));
          if (limitReached()) return;
          if (hardEnd != null && d.isAfter(hardEnd)) return;
          if (d.isAfter(rangeEnd)) return;
          if (!d.isBefore(anchor) && !exceptions.contains(d)) yield d;
          produced++;
          year += interval;
        }
    }
  }
}

class PlannerDay {
  const PlannerDay({
    required this.date,
    required this.label,
    required this.dayNumber,
    required this.isToday,
  });

  final DateTime date;
  final String label;
  final int dayNumber;
  final bool isToday;
}

class PlannerCalendar {
  const PlannerCalendar({
    required this.id,
    required this.name,
    required this.color,
  });

  final String id;
  final String name;
  final Color color;

  /// Encode the colour as an uppercase `#RRGGBB` hex string for storage.
  static String colorToHex(Color color) {
    String channel(double c) =>
        (c * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    return '#${channel(color.r)}${channel(color.g)}${channel(color.b)}'
        .toUpperCase();
  }

  /// Parse a `#RRGGBB`/`RRGGBB` hex string, falling back to a neutral grey.
  static Color colorFromHex(String? hex) {
    final raw = (hex ?? '').replaceAll('#', '').trim();
    if (raw.length == 6) {
      final value = int.tryParse(raw, radix: 16);
      if (value != null) return Color(0xFF000000 | value);
    }
    return const Color(0xFF74706B);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': colorToHex(color),
      };

  factory PlannerCalendar.fromJson(Map<String, dynamic> json) {
    return PlannerCalendar(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Calendar',
      color: colorFromHex(json['color'] as String?),
    );
  }
}

class PlannerEvent {
  const PlannerEvent({
    required this.id,
    required this.title,
    required this.isAllDay,
    required this.startAt,
    required this.endAt,
    required this.location,
    required this.url,
    required this.note,
    required this.calendarId,
    required this.reminder,
    required this.repeatRule,
    required this.attendees,
    this.recurrence = PlannerRecurrence.none,
    this.seriesId,
    this.occurrenceDate,
    this.updatedAt,
  });

  final String id;
  final String title;
  final bool isAllDay;
  final DateTime startAt;
  final DateTime endAt;
  final String location;
  final String url;
  final String note;
  final String calendarId;
  final PlannerReminder reminder;
  final PlannerRepeatRule repeatRule;
  final List<String> attendees;

  /// Last time this event was modified (UTC). Drives last-write-wins conflict
  /// resolution when reconciling the local cache with the cloud backend. Null
  /// for legacy/demo data; treated as the epoch (always loses) during merge.
  final DateTime? updatedAt;

  /// Full recurrence spec. When [PlannerRecurrence.isNone] the event falls back
  /// to a simple rule derived from [repeatRule] (covers legacy/demo data that
  /// only set the frequency enum).
  final PlannerRecurrence recurrence;

  /// Set on virtual occurrences produced by expanding a recurring series. Holds
  /// the id of the stored base event. Null for standalone stored events.
  final String? seriesId;

  /// The date this occurrence falls on (date-only). Null for stored events.
  final DateTime? occurrenceDate;

  /// The authoritative recurrence for this event: the explicit [recurrence] if
  /// set, otherwise one derived from the legacy [repeatRule] frequency.
  PlannerRecurrence get effectiveRecurrence => recurrence.isNone
      ? (repeatRule == PlannerRepeatRule.never
          ? PlannerRecurrence.none
          : PlannerRecurrence(frequency: repeatRule))
      : recurrence;

  /// True when this event is a generated occurrence of a recurring series.
  bool get isRecurringInstance => seriesId != null;

  /// Build the occurrence of this (base) event that lands on [date], preserving
  /// time-of-day and duration.
  PlannerEvent instanceOn(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final newStart = isAllDay
        ? day
        : DateTime(day.year, day.month, day.day, startAt.hour, startAt.minute);
    final duration = endAt.difference(startAt);
    return copyWith(
      id: '$id::${PlannerRecurrence._dateToken(day)}',
      startAt: newStart,
      endAt: newStart.add(duration),
      seriesId: id,
      occurrenceDate: day,
    );
  }

  PlannerEvent copyWith({
    String? id,
    String? title,
    bool? isAllDay,
    DateTime? startAt,
    DateTime? endAt,
    String? location,
    String? url,
    String? note,
    String? calendarId,
    PlannerReminder? reminder,
    PlannerRepeatRule? repeatRule,
    List<String>? attendees,
    PlannerRecurrence? recurrence,
    String? seriesId,
    DateTime? occurrenceDate,
    DateTime? updatedAt,
  }) {
    return PlannerEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      isAllDay: isAllDay ?? this.isAllDay,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      location: location ?? this.location,
      url: url ?? this.url,
      note: note ?? this.note,
      calendarId: calendarId ?? this.calendarId,
      reminder: reminder ?? this.reminder,
      repeatRule: repeatRule ?? this.repeatRule,
      attendees: attendees ?? this.attendees,
      recurrence: recurrence ?? this.recurrence,
      seriesId: seriesId ?? this.seriesId,
      occurrenceDate: occurrenceDate ?? this.occurrenceDate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Effective modification time for conflict resolution; never null.
  DateTime get sortableUpdatedAt =>
      updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  String get timeRange {
    final formatter = DateFormat('h:mm a');
    if (isAllDay) {
      return 'All day';
    }
    return '${formatter.format(startAt)} - ${formatter.format(endAt)}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'is_all_day': isAllDay,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt.toIso8601String(),
      'location': location,
      'url': url,
      'note': note,
      'calendar_id': calendarId,
      'reminder': reminder.storageValue,
      'repeat_rule': effectiveRecurrence.encode(),
      'attendees': attendees,
      'updated_at': (updatedAt ?? DateTime.now()).toUtc().toIso8601String(),
    };
  }

  factory PlannerEvent.fromJson(Map<String, dynamic> json) {
    final recurrence = PlannerRecurrence.parse(json['repeat_rule'] as String?);
    return PlannerEvent(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      isAllDay: json['is_all_day'] as bool? ?? false,
      startAt: DateTime.parse(json['start_at'] as String),
      endAt: DateTime.parse(json['end_at'] as String),
      location: json['location'] as String? ?? '',
      url: json['url'] as String? ?? '',
      note: json['note'] as String? ?? '',
      calendarId: json['calendar_id'] as String? ?? 'calendar',
      reminder: plannerReminderFromStorage(json['reminder'] as String?),
      repeatRule: recurrence.frequency,
      recurrence: recurrence,
      attendees: _attendeesFromJson(json['attendees']),
      updatedAt: _parseUpdatedAt(json['updated_at']),
    );
  }
}

DateTime? _parseUpdatedAt(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toUtc();
  }
  return null;
}

class PlannerEventDraft {
  const PlannerEventDraft({
    required this.title,
    required this.isAllDay,
    required this.startAt,
    required this.endAt,
    required this.location,
    required this.url,
    required this.note,
    required this.calendarId,
    required this.reminder,
    required this.repeatRule,
    required this.attendees,
    this.recurrence = PlannerRecurrence.none,
  });

  final String title;
  final bool isAllDay;
  final DateTime startAt;
  final DateTime endAt;
  final String location;
  final String url;
  final String note;
  final String calendarId;
  final PlannerReminder reminder;
  final PlannerRepeatRule repeatRule;
  final List<String> attendees;
  final PlannerRecurrence recurrence;

  PlannerRecurrence get effectiveRecurrence => recurrence.isNone
      ? (repeatRule == PlannerRepeatRule.never
          ? PlannerRecurrence.none
          : PlannerRecurrence(frequency: repeatRule))
      : recurrence;

  PlannerEventDraft copyWith({
    String? title,
    bool? isAllDay,
    DateTime? startAt,
    DateTime? endAt,
    String? location,
    String? url,
    String? note,
    String? calendarId,
    PlannerReminder? reminder,
    PlannerRepeatRule? repeatRule,
    List<String>? attendees,
    PlannerRecurrence? recurrence,
  }) {
    return PlannerEventDraft(
      title: title ?? this.title,
      isAllDay: isAllDay ?? this.isAllDay,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      location: location ?? this.location,
      url: url ?? this.url,
      note: note ?? this.note,
      calendarId: calendarId ?? this.calendarId,
      reminder: reminder ?? this.reminder,
      repeatRule: repeatRule ?? this.repeatRule,
      attendees: attendees ?? this.attendees,
      recurrence: recurrence ?? this.recurrence,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'is_all_day': isAllDay,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt.toIso8601String(),
      'location': location,
      'url': url,
      'note': note,
      'calendar_id': calendarId,
      'reminder': reminder.storageValue,
      'repeat_rule': effectiveRecurrence.encode(),
      'attendees': attendees,
    };
  }
}

List<String> _attendeesFromJson(Object? value) {
  if (value is List) {
    return value
        .whereType<Object>()
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  if (value is String && value.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      return _attendeesFromJson(decoded);
    } catch (_) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
  }

  return const [];
}

class PlannerState {
  const PlannerState({
    required this.selectedDate,
    required this.focusedMonth,
    required this.calendars,
    required this.visibleCalendarIds,
    required this.events,
  });

  final DateTime selectedDate;
  final DateTime focusedMonth;
  final List<PlannerCalendar> calendars;
  final List<String> visibleCalendarIds;
  final List<PlannerEvent> events;

  PlannerState copyWith({
    DateTime? selectedDate,
    DateTime? focusedMonth,
    List<PlannerCalendar>? calendars,
    List<String>? visibleCalendarIds,
    List<PlannerEvent>? events,
  }) {
    return PlannerState(
      selectedDate: selectedDate ?? this.selectedDate,
      focusedMonth: focusedMonth ?? this.focusedMonth,
      calendars: calendars ?? this.calendars,
      visibleCalendarIds: visibleCalendarIds ?? this.visibleCalendarIds,
      events: events ?? this.events,
    );
  }

  List<PlannerDay> get railDays {
    return railDaysFor(9);
  }

  List<PlannerDay> railDaysFor(int count) {
    final safeCount = count.clamp(3, 10);
    final today = _startOfDay(DateTime.now());
    final selectedOffset = safeCount ~/ 2;
    return List<PlannerDay>.generate(safeCount, (index) {
      final date = _startOfDay(
        selectedDate.add(Duration(days: index - selectedOffset)),
      );
      return PlannerDay(
        date: date,
        label: DateFormat('EEE').format(date).toUpperCase(),
        dayNumber: date.day,
        isToday: date == today,
      );
    });
  }

  /// A wide, scrollable run of days centred on [selectedDate]: [radius] days
  /// reach back and forward from the selection (so the selected day sits in the
  /// middle at index [radius]). Used by the scrollable rail, which shows only a
  /// window of these at a time and lets the user scroll to the rest.
  List<PlannerDay> railRangeDays({int radius = 45}) {
    final safeRadius = radius.clamp(7, 180);
    final today = _startOfDay(DateTime.now());
    return List<PlannerDay>.generate(safeRadius * 2 + 1, (index) {
      final date = _startOfDay(
        selectedDate.add(Duration(days: index - safeRadius)),
      );
      return PlannerDay(
        date: date,
        label: DateFormat('EEE').format(date).toUpperCase(),
        dayNumber: date.day,
        isToday: date == today,
      );
    });
  }

  String get monthLabel =>
      DateFormat('yyyy MMM').format(selectedDate).toUpperCase();

  String get selectedDateHeadline =>
      DateFormat('EEEE').format(selectedDate).toUpperCase();

  String get selectedDateSubhead =>
      DateFormat('d MMM').format(selectedDate).toUpperCase();

  List<PlannerEvent> get selectedDayEvents {
    return occurrencesInRange(selectedDate, selectedDate);
  }

  List<PlannerEvent> get filteredEvents {
    return events
        .where((event) => visibleCalendarIds.contains(event.calendarId))
        .toList();
  }

  /// All event occurrences (expanding recurring series) that fall on a day in
  /// the inclusive range [startInclusive]..[endInclusive], sorted by start time.
  List<PlannerEvent> occurrencesInRange(
    DateTime startInclusive,
    DateTime endInclusive,
  ) {
    final rangeStart = _startOfDay(startInclusive);
    final rangeEnd = _startOfDay(endInclusive);
    final result = <PlannerEvent>[];

    for (final event in filteredEvents) {
      final recurrence = event.effectiveRecurrence;
      if (!recurrence.repeats) {
        final startDay = _startOfDay(event.startAt);
        var endDay = _startOfDay(event.endAt);
        // An end exactly at midnight finishes on the day boundary, so the
        // previous day is the last covered day (all-day events store their end
        // as the next day's midnight). This keeps single all-day events on one
        // day while letting genuinely multi-day / cross-midnight events span.
        if (event.endAt == endDay && endDay.isAfter(startDay)) {
          endDay = endDay.subtract(const Duration(days: 1));
        }
        // Include the event when its [startDay, endDay] span intersects range.
        if (!startDay.isAfter(rangeEnd) && !endDay.isBefore(rangeStart)) {
          result.add(event);
        }
        continue;
      }

      final anchor = _startOfDay(event.startAt);
      for (final date
          in recurrence.occurrenceDates(anchor, rangeEnd, rangeStart: rangeStart)) {
        if (date.isBefore(rangeStart)) continue;
        result.add(event.instanceOn(date));
      }
    }

    result.sort((a, b) => a.startAt.compareTo(b.startAt));
    return result;
  }

  /// Occurrences within a calendar month (expands recurring series).
  List<PlannerEvent> eventsInMonth(int year, int month) {
    final first = DateTime(year, month, 1);
    final last = DateTime(year, month, DateUtils.getDaysInMonth(year, month));
    return occurrencesInRange(first, last);
  }

  bool isCalendarVisible(String calendarId) {
    return visibleCalendarIds.contains(calendarId);
  }

  PlannerCalendar calendarById(String calendarId) {
    for (final calendar in calendars) {
      if (calendar.id == calendarId) {
        return calendar;
      }
    }

    // Fall back to the first calendar, or a neutral placeholder when there are
    // none (avoids a `.first` StateError if calendars haven't loaded yet).
    if (calendars.isEmpty) {
      return const PlannerCalendar(
        id: 'calendar',
        name: 'Calendar',
        color: Color(0xFF74706B),
      );
    }
    return calendars.first;
  }

  static DateTime _startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
