import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/storage/sqlite_database.dart';
import '../domain/planner_models.dart';
import 'planner_repository.dart';

class SqlitePlannerRepository implements PlannerRepository {
  SqlitePlannerRepository({required SqliteDatabaseFactory databaseFactory})
    : _databaseFactory = databaseFactory;

  final SqliteDatabaseFactory _databaseFactory;
  Database? _database;

  Future<Database> get _db async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    final opened = await _databaseFactory.open();
    _database = opened;
    return opened;
  }

  @override
  Future<PlannerState> loadInitialState() async {
    final db = await _db;
    await _seedIfNeeded(db);

    final calendarsRows = await db.query(
      'calendars',
      orderBy: 'position asc, name asc',
    );
    final eventsRows = await db.query('events', orderBy: 'start_at asc');
    final calendars = calendarsRows.map(_calendarFromRow).toList();
    final events = eventsRows.map(_eventFromRow).toList();
    final now = DateTime.now();
    final selectedDate = DateTime(now.year, now.month, now.day);

    return PlannerState(
      selectedDate: selectedDate,
      focusedMonth: DateTime(selectedDate.year, selectedDate.month),
      calendars: calendars,
      visibleCalendarIds: calendars.map((calendar) => calendar.id).toList(),
      events: events,
    );
  }

  @override
  Future<PlannerEvent> createEvent(PlannerEventDraft draft) async {
    final db = await _db;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final event = PlannerEvent(
      id: id,
      title: draft.title,
      isAllDay: draft.isAllDay,
      startAt: draft.startAt,
      endAt: draft.endAt,
      location: draft.location,
      url: draft.url,
      note: draft.note,
      calendarId: draft.calendarId,
      reminder: draft.reminder,
      repeatRule: draft.effectiveRecurrence.frequency,
      recurrence: draft.effectiveRecurrence,
      attendees: draft.attendees,
    );

    await db.insert('events', _eventToRow(event));
    return event;
  }

  @override
  Future<PlannerEvent> updateEvent(PlannerEvent event) async {
    final db = await _db;
    await db.update(
      'events',
      _eventToRow(event),
      where: 'id = ?',
      whereArgs: [event.id],
    );
    return event;
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    final db = await _db;
    await db.delete('events', where: 'id = ?', whereArgs: [eventId]);
  }

  Future<void> _seedIfNeeded(Database db) async {
    final countResult = Sqflite.firstIntValue(
      await db.rawQuery('select count(*) from events'),
    );
    if ((countResult ?? 0) > 0) {
      return;
    }

    final seedEvents = [
      PlannerEvent(
        id: 'sqlite-1',
        title: 'Weekly stand-up',
        isAllDay: false,
        startAt: DateTime(2026, 5, 14, 8, 30),
        endAt: DateTime(2026, 5, 14, 9, 0),
        location: 'Remote',
        url: 'https://meet.google.com/demo-standup',
        note: 'Keep it tight and focus on blockers.',
        calendarId: 'friends',
        reminder: PlannerReminder.fifteenMinutesBefore,
        repeatRule: PlannerRepeatRule.weekly,
        attendees: const ['Alex', 'Mina'],
      ),
      PlannerEvent(
        id: 'sqlite-2',
        title: 'Design review',
        isAllDay: false,
        startAt: DateTime(2026, 5, 14, 11, 30),
        endAt: DateTime(2026, 5, 14, 12, 30),
        location: 'Studio boardroom',
        url: 'https://figma.com/file/design-review',
        note: 'Approve Android motion and menu states.',
        calendarId: 'work',
        reminder: PlannerReminder.thirtyMinutesBefore,
        repeatRule: PlannerRepeatRule.never,
        attendees: const ['Nora', 'Lee'],
      ),
      PlannerEvent(
        id: 'sqlite-3',
        title: 'Pilates',
        isAllDay: false,
        startAt: DateTime(2026, 5, 14, 19, 0),
        endAt: DateTime(2026, 5, 14, 20, 0),
        location: 'North Park Club',
        url: '',
        note: 'Bring towel and update reminders afterward.',
        calendarId: 'exercise',
        reminder: PlannerReminder.oneHourBefore,
        repeatRule: PlannerRepeatRule.weekly,
        attendees: const [],
      ),
    ];

    final batch = db.batch();
    for (final event in seedEvents) {
      batch.insert('events', _eventToRow(event));
    }
    await batch.commit(noResult: true);
  }

  PlannerCalendar _calendarFromRow(Map<String, Object?> row) {
    return PlannerCalendar(
      id: row['id'] as String,
      name: row['name'] as String,
      color: _parseColor(row['color'] as String?),
    );
  }

  PlannerEvent _eventFromRow(Map<String, Object?> row) {
    final recurrence = PlannerRecurrence.parse(row['repeat_rule'] as String?);
    return PlannerEvent(
      id: row['id'] as String,
      title: row['title'] as String? ?? '',
      isAllDay: (row['is_all_day'] as int? ?? 0) == 1,
      startAt: DateTime.parse(row['start_at'] as String),
      endAt: DateTime.parse(row['end_at'] as String),
      location: row['location'] as String? ?? '',
      url: row['url'] as String? ?? '',
      note: row['note'] as String? ?? '',
      calendarId: row['calendar_id'] as String? ?? 'calendar',
      reminder: plannerReminderFromStorage(row['reminder'] as String?),
      repeatRule: recurrence.frequency,
      recurrence: recurrence,
      attendees: _decodeAttendees(row['attendees']),
    );
  }

  Map<String, Object?> _eventToRow(PlannerEvent event) {
    return {
      'id': event.id,
      'title': event.title,
      'is_all_day': event.isAllDay ? 1 : 0,
      'start_at': event.startAt.toIso8601String(),
      'end_at': event.endAt.toIso8601String(),
      'location': event.location,
      'url': event.url,
      'note': event.note,
      'calendar_id': event.calendarId,
      'reminder': event.reminder.storageValue,
      'repeat_rule': event.effectiveRecurrence.encode(),
      'attendees': jsonEncode(event.attendees),
    };
  }

  List<String> _decodeAttendees(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return decoded
            .whereType<Object>()
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
    } catch (_) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return const [];
  }

  @override
  Future<void> renameCalendar(String id, String newName) async {
    final db = await _db;
    await db.update('calendars', {'name': newName},
        where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<PlannerCalendar> createCalendar(String name, Color color) async {
    final db = await _db;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final hex = _colorToHex(color);
    final countResult = Sqflite.firstIntValue(
      await db.rawQuery('select count(*) from calendars'),
    );
    final position = (countResult ?? 0) + 1;
    await db.insert('calendars', {
      'id': id,
      'name': name,
      'color': hex,
      'position': position,
    });
    return PlannerCalendar(id: id, name: name, color: color);
  }

  Color _parseColor(String? hex) => parsePlannerColor(hex);

  String _colorToHex(Color c) {
    final r = (c.r * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    final g = (c.g * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    final b = (c.b * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }
}
