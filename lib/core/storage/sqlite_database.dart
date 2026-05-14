import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class SqliteDatabaseFactory {
  Future<Database> open() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, 'vertical_planner.db');

    return openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          create table calendars (
            id text primary key,
            name text not null,
            color text not null,
            position integer not null default 0
          )
        ''');

        await db.execute('''
          create table events (
            id text primary key,
            title text not null,
            is_all_day integer not null default 0,
            start_at text not null,
            end_at text not null,
            location text not null default '',
            url text not null default '',
            note text not null default '',
            reminder text not null default 'none',
            repeat_rule text not null default 'never',
            attendees text not null default '[]',
            calendar_id text not null
          )
        ''');

        await db.insert('calendars', {
          'id': 'calendar',
          'name': 'Calendar',
          'color': '#D1ACEA',
          'position': 1,
        });
        await db.insert('calendars', {
          'id': 'exercise',
          'name': 'Exercise',
          'color': '#F197A6',
          'position': 2,
        });
        await db.insert('calendars', {
          'id': 'family',
          'name': 'Family',
          'color': '#F4C382',
          'position': 3,
        });
        await db.insert('calendars', {
          'id': 'friends',
          'name': 'Friends',
          'color': '#BCE58F',
          'position': 4,
        });
        await db.insert('calendars', {
          'id': 'work',
          'name': 'Work',
          'color': '#74706B',
          'position': 5,
        });
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "alter table events add column reminder text not null default 'none'",
          );
          await db.execute(
            "alter table events add column repeat_rule text not null default 'never'",
          );
        }
        if (oldVersion < 3) {
          await db.execute(
            "alter table events add column attendees text not null default '[]'",
          );
        }
        if (oldVersion < 4) {
          await db.execute(
            "alter table events add column is_all_day integer not null default 0",
          );
        }
      },
    );
  }
}
