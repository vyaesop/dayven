import { neon } from '@neondatabase/serverless';

const DATABASE_URL = process.env.NEON_DATABASE_URL;
if (!DATABASE_URL) {
  console.error('Error: NEON_DATABASE_URL env var is required');
  process.exit(1);
}

const sql = neon(DATABASE_URL);

async function migrate() {
  console.log('Creating tables...');

  await sql`
    CREATE TABLE IF NOT EXISTS calendars (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      color TEXT NOT NULL,
      position INTEGER NOT NULL DEFAULT 0,
      created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )
  `;
  console.log('  calendars table OK');

  await sql`
    CREATE TABLE IF NOT EXISTS events (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      is_all_day BOOLEAN NOT NULL DEFAULT false,
      start_at TIMESTAMPTZ NOT NULL,
      end_at TIMESTAMPTZ NOT NULL,
      location TEXT NOT NULL DEFAULT '',
      url TEXT NOT NULL DEFAULT '',
      note TEXT NOT NULL DEFAULT '',
      reminder TEXT NOT NULL DEFAULT 'none',
      repeat_rule TEXT NOT NULL DEFAULT 'never',
      attendees JSONB NOT NULL DEFAULT '[]',
      calendar_id TEXT NOT NULL REFERENCES calendars(id) ON DELETE CASCADE,
      created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )
  `;
  console.log('  events table OK');

  await sql`CREATE INDEX IF NOT EXISTS idx_events_start_at ON events(start_at)`;
  await sql`CREATE INDEX IF NOT EXISTS idx_events_calendar_id ON events(calendar_id)`;
  console.log('  indexes OK');

  await sql`
    INSERT INTO calendars (id, name, color, position) VALUES
      ('cal-calendar', 'Calendar', '#5B8CFF', 0),
      ('cal-exercise', 'Exercise', '#4CAF50', 1),
      ('cal-family',   'Family',   '#FF9800', 2),
      ('cal-friends',  'Friends',  '#E91E63', 3),
      ('cal-work',     'Work',     '#607D8B', 4)
    ON CONFLICT (id) DO NOTHING
  `;
  console.log('  default calendars seeded');

  console.log('\nMigration complete.');
}

migrate().catch((err) => {
  console.error('Migration failed:', err.message);
  process.exit(1);
});
