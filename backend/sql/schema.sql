-- Dayven cloud schema (multi-tenant).
--
-- Every row is scoped to a Firebase user via `user_id`. The canonical backend is
-- the Vercel API under /api (Firebase-authenticated, per-user). Default calendars
-- are seeded per-user by the API on first sign-in (see api/v1/planner.ts), so this
-- file intentionally does NOT seed any global calendars.

create table if not exists calendars (
  id text primary key,
  user_id text not null,
  name text not null,
  color text not null,
  position integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists events (
  id text primary key,
  user_id text not null,
  title text not null,
  is_all_day boolean not null default false,
  start_at timestamptz not null,
  end_at timestamptz not null,
  location text not null default '',
  url text not null default '',
  note text not null default '',
  reminder text not null default 'none',
  repeat_rule text not null default 'never',
  attendees jsonb not null default '[]'::jsonb,
  calendar_id text not null references calendars(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Idempotent backfill for databases created before multi-tenancy / before these
-- columns existed. `user_id` is added nullable here so the migration succeeds on
-- existing rows; new inserts always supply it.
alter table calendars add column if not exists user_id text;
alter table events    add column if not exists user_id text;
alter table events    add column if not exists url text not null default '';
alter table events    add column if not exists reminder text not null default 'none';
alter table events    add column if not exists repeat_rule text not null default 'never';
alter table events    add column if not exists attendees jsonb not null default '[]'::jsonb;
alter table events    add column if not exists is_all_day boolean not null default false;

-- Soft-delete tombstones. Deletes set `deleted_at` instead of removing the row,
-- so the change can propagate to other devices via delta sync (a `since` query
-- returns tombstoned rows too) and so an accidental delete is recoverable.
alter table events    add column if not exists deleted_at timestamptz;
alter table calendars add column if not exists deleted_at timestamptz;

create index if not exists idx_calendars_user_id on calendars(user_id);
create index if not exists idx_events_user_id     on events(user_id);
create index if not exists idx_events_user_start  on events(user_id, start_at);
create index if not exists idx_events_calendar_id on events(calendar_id);
-- Delta-sync support: fetch rows changed since a client's last sync watermark.
create index if not exists idx_events_user_updated    on events(user_id, updated_at);
create index if not exists idx_calendars_user_updated on calendars(user_id, updated_at);
