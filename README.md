# Dayven

Android-first Flutter planner app inspired by the screenshot set in this repo.

## Current State

- startup choice between local SQLite storage and cloud-sync mode
- custom home timeline screen
- interactive month overview sheet with month browsing
- local event create, edit, and delete flow
- calendar visibility filtering
- event URL support
- reminder selection, repeat rules, and people/invitees
- event detail sheet with edit handoff
- navigable screenshot-inspired surfaces for search, RSVP, calendars, themes, preferences, smart alerts, travel, support, account, membership, and sign-in
- persisted theme palette/mode, text scaling, alert toggles, travel toggles, and layout preferences
- local account/profile save flow, communication opt-in persistence, membership preview, and redeem-code preview
- local support, feedback, and feature-request queue
- dynamic default calendar settings and all-day event support
- functional local event search and attendee-based RSVP summary
- Neon-ready mobile repository layer
- Cloudflare Worker + Neon backend scaffold
- Worker dependencies installed and typechecked

## Flutter Env Setup

1. Copy [env/app_config.example.json](env/app_config.example.json) to `env/app_config.json`.
2. Fill in your real values later.
3. Run the app with:

```bash
flutter run --dart-define-from-file=env/app_config.json
```

If you want demo mode without any backend yet, use:

```json
{
  "VP_BACKEND_MODE": "demo",
  "VP_API_BASE_URL": "",
  "VP_API_BEARER_TOKEN": "",
  "VP_ENABLE_VERBOSE_LOGS": true
}
```

If you choose `On This Device` inside the app, the planner uses SQLite and does not depend on the API base URL.
If you choose `Sync Across Devices`, the app uses the Neon-backed HTTP API when configured.

## Backend Scaffold

The backend scaffold lives in:

- [backend/sql/schema.sql](backend/sql/schema.sql)
- [backend/worker/src/index.ts](backend/worker/src/index.ts)
- [backend/worker/wrangler.toml](backend/worker/wrangler.toml)
- [backend/worker/.dev.vars.example](backend/worker/.dev.vars.example)

It is designed for:

- `Neon` as the database
- `Cloudflare Workers` as the free-tier mobile-safe API layer

Expected API routes already wired in Flutter:

- `GET /v1/planner?date=...`
- `POST /v1/events`
- `PUT /v1/events/:id`
- `DELETE /v1/events/:id`

## Useful Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --dart-define-from-file=env/app_config.json
cd backend/worker && npm install
cd backend/worker && npm run typecheck
```
