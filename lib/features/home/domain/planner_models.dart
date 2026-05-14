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
  for (final rule in PlannerRepeatRule.values) {
    if (rule.storageValue == value) {
      return rule;
    }
  }

  return PlannerRepeatRule.never;
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
    );
  }

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
      'repeat_rule': repeatRule.storageValue,
      'attendees': attendees,
    };
  }

  factory PlannerEvent.fromJson(Map<String, dynamic> json) {
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
      repeatRule: plannerRepeatRuleFromStorage(json['repeat_rule'] as String?),
      attendees: _attendeesFromJson(json['attendees']),
    );
  }
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
      'repeat_rule': repeatRule.storageValue,
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
    final today = _startOfDay(DateTime.now());
    return List<PlannerDay>.generate(9, (index) {
      final date = _startOfDay(selectedDate.add(Duration(days: index - 3)));
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
    final day = _startOfDay(selectedDate);
    final filtered = filteredEvents.where((event) {
      final start = event.startAt;
      return start.year == day.year &&
          start.month == day.month &&
          start.day == day.day;
    }).toList();

    filtered.sort((a, b) => a.startAt.compareTo(b.startAt));
    return filtered;
  }

  List<PlannerEvent> get filteredEvents {
    return events
        .where((event) => visibleCalendarIds.contains(event.calendarId))
        .toList();
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

    return calendars.first;
  }

  static DateTime _startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
