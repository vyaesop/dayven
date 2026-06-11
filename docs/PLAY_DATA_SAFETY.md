# Dayven — Google Play Data Safety mapping

This document maps Dayven's actual data handling to the Google Play **Data
Safety** form so the store listing is accurate. Keep it in sync with the code
when data flows change. (Last reviewed: 2026-06-11.)

## Architecture summary

- **Storage is cloud-only + offline-first.** The source of truth is the
  Firebase-authenticated Vercel API (`/api`) backed by Neon Postgres. The device
  keeps a durable local cache (`SharedPreferences`) and an offline mutation
  queue so the app works without a connection; these mirror the cloud and are
  cleared on sign-out/account deletion.
- **Auth:** Firebase Authentication (email/password and Google Sign-In).

## Data collected & shared

| Data type | Collected? | Purpose | Shared w/ 3rd parties | Processor |
|---|---|---|---|---|
| Email address | Yes | Account creation & sign-in | No | Firebase Auth (Google) |
| Name (display name) | Yes (optional, via Google) | Account personalization | No | Firebase Auth (Google) |
| Calendar events (title, time, location, notes, attendees) | Yes | Core app function (the planner) | No | Neon (DB), Vercel (API) |
| App interactions / analytics | Yes (if enabled) | Analytics, app improvement | No | Firebase Analytics |
| Crash logs & diagnostics | Yes | Stability / crash reporting | No | Firebase Crashlytics |
| Push token (FCM) | Yes | Push notifications | No | Firebase Cloud Messaging |
| Device/local cache (events mirror) | On-device only | Offline availability | No | Local (`SharedPreferences`) |

Notes for the form:
- **"Is all user data encrypted in transit?"** → Yes (HTTPS/TLS to Vercel,
  Firebase, Neon).
- **Data is NOT sold.** No advertising SDKs are integrated.
- "Attendees" are free-text names/emails the user types; treat as user content,
  not contact-list access (the app does not read the device contacts).

## Account & data deletion (Play requirement)

Users can delete their account in-app: **Menu → My Account → Delete Account**.
This calls `DELETE /v1/auth/user`, which:

1. Hard-deletes all of the user's `events` and `calendars` rows from Neon
   (`api/v1/auth/user.ts`).
2. Deletes the Firebase Auth account via the Identity Toolkit REST API.

The client then clears the local cache + mutation queue for that user and signs
out. If the server is unreachable the client aborts and tells the user, so they
are never told their cloud data was deleted when it was not.

- **In-app deletion path:** present and functional.
- **Web/off-device deletion URL (Play also wants this):** TODO — host a public
  page describing the deletion process and a contact/web route, then add its URL
  to the Play Console "Data deletion" field. (Privacy policy is at
  `public/privacy-policy.html`; ensure it is publicly hosted and linked.)

## Pre-submission checklist

- [ ] Privacy policy publicly hosted and URL added to Play Console.
- [ ] Data Safety form filled to match the table above.
- [ ] Data-deletion URL (web) created and added to Play Console.
- [ ] Confirm Firebase Analytics collection state matches what's declared
      (analytics events are wired in `core/analytics`).
