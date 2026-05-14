create table if not exists calendars (
  id text primary key,
  name text not null,
  color text not null,
  position integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists events (
  id text primary key,
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

alter table events
  add column if not exists url text not null default '';
alter table events
  add column if not exists reminder text not null default 'none';
alter table events
  add column if not exists repeat_rule text not null default 'never';
alter table events
  add column if not exists attendees jsonb not null default '[]'::jsonb;
alter table events
  add column if not exists is_all_day boolean not null default false;

create index if not exists idx_events_start_at on events(start_at);
create index if not exists idx_events_calendar_id on events(calendar_id);

insert into calendars (id, name, color, position)
values
  ('calendar', 'Calendar', '#D1ACEA', 1),
  ('exercise', 'Exercise', '#F197A6', 2),
  ('family', 'Family', '#F4C382', 3),
  ('friends', 'Friends', '#BCE58F', 4),
  ('work', 'Work', '#74706B', 5)
on conflict (id) do update set
  name = excluded.name,
  color = excluded.color,
  position = excluded.position,
  updated_at = now();
