# Vertical Planner Flutter App Implementation Plan

## Goal
Build an Android-first Flutter app that faithfully recreates the screenshot-driven "Timepage"-style experience in this repo while making it production-ready for Play Store release.

This plan assumes:

- Flutter is the primary app framework.
- Android is the only shipping target for phase 1.
- We are recreating the visual language and product flow from the screenshots, but we will adapt clearly iOS-specific behavior to strong Android-native equivalents.

## Implementation Tracker

- [x] Review repo screenshots and extract core product flows
- [x] Choose Flutter for the Android-first app foundation
- [x] Switch backend plan from Supabase to Neon-first architecture
- [x] Scaffold the Flutter project in this repo
- [x] Set up an initial feature-based Flutter folder structure
- [x] Replace the default counter app with a custom planner home screen
- [x] Add a custom theme foundation closer to the screenshot style
- [x] Add a repository abstraction so UI is not coupled to storage details
- [x] Add month view foundation from the bottom planner bar
- [x] Add Flutter env/config scaffolding for later secret injection
- [x] Add local planner state with create, edit, delete, and day switching
- [x] Scaffold Neon-backed remote data layer and Worker API contract
- [x] Add calendar visibility filtering
- [x] Add URL support to events across app and backend scaffold
- [x] Validate Worker scaffold with installed dependencies and typecheck
- [x] Add user-selectable storage mode between local SQLite and cloud sync
- [x] Implement a SQLite-backed local repository
- [x] Add reminder and repeat-rule foundations across app and backend scaffold
- [x] Add people/invitee event data across app, SQLite, and Neon scaffold
- [x] Add event detail sheet inspired by the screenshot inspect flow
- [x] Re-audit all 25 screenshot strips and expand the missing screen map
- [x] Add navigable screenshot-inspired menu surfaces for search, RSVP, calendars, themes, preferences, smart alerts, travel, support, account, membership, and sign-in
- [x] Add persisted local preferences controller with SharedPreferences
- [x] Make theme palette/mode selection update the app theme and survive restarts
- [x] Make text sizing preference update the app with persisted scaling
- [x] Add functional event search over loaded planner data
- [x] Add functional RSVP attendee summary from event invitees
- [x] Persist smart-alert and travel preference toggles locally
- [x] Add local account, profile, and membership preview state
- [x] Add local support, feedback, and feature-request queue state
- [x] Add dynamic calendar settings with default calendar persistence
- [x] Add all-day event support across app, SQLite, and backend scaffold
- [x] Make timeline density, layout, shading, visibility, and color settings persist and affect the planner locally
- [x] Add offline daily briefing / forecast / travel preview cards from local event data
- [x] Add local RSVP response persistence and status controls
- [x] Add offline map-style and forecast-style event detail cards
- [x] Add persisted travel mode, directions app, rain alert, daily briefing, and app icon preview settings
- [x] Add local profile sign-in, passcode unlock, and local passcode reset flow
- [x] Add Firebase Cloud Messaging client scaffolding, Android notification permissions, default channel, foreground display, and status surface
- [x] Generate and install production-style Android launcher icon assets
- [ ] Add auth flow
- [ ] Expand month view interactions beyond current browsing/filtering
- [ ] Add advanced event editing flows
- [x] Add preferences, themes, account, paywall, and alerts UI scaffolds
- [x] Connect preferences, themes, and alert/travel toggles to local persistence
- [ ] Connect account, paywall, auth, and notifications to live services
- [ ] Prepare production Android release setup

## Product Summary
The app is a premium vertical planner and calendar experience with:

- a vertically scrolling day timeline
- a month heatmap / calendar overview
- event creation and editing
- category-based calendars with colors
- reminders, repeats, people, notes, URLs, and locations
- theme customization
- subscription / paywall flows
- account management
- smart alerts and weather-aware reminders
- search, RSVP, onboarding, help, and preferences

## Recommended Stack

### App
- `Flutter`
- `Dart`
- `Material 3` with a custom design system to match the screenshots rather than default Material widgets

### State Management
- `flutter_riverpod`

### Routing
- `go_router`

### Local Persistence
- `drift` for structured local storage
- `flutter_secure_storage` for sensitive tokens
- `shared_preferences` for lightweight flags
- `SQLite` local-first mode with persisted user choice

### Backend
- `Neon` for the database
- a thin free-tier API layer in front of Neon for mobile-safe access

Why this architecture:

- Neon gives us the Postgres database on a free tier
- mobile apps should not ship raw database credentials
- the app can talk to a small HTTP layer backed by Neon Data API or a free serverless edge function
- the current Flutter implementation already uses a repository boundary so we can swap demo data for Neon-backed APIs without rewriting the screens

### Notifications and Scheduling
- `firebase_messaging` for remote notifications
- `flutter_local_notifications` for local reminders
- `workmanager` for background jobs where needed

### Maps and Places
- `google_maps_flutter`
- `geolocator`
- `google_places_flutter` or direct Places API integration

### Weather
- Prefer `Open-Meteo` for forecast data initially
- Abstract behind a weather repository so we can swap providers later

### Search
- server-side indexed search in Neon-backed tables for events, people, and locations

### Payments / Subscriptions
- `RevenueCat`

Why RevenueCat:

- easier subscription lifecycle handling
- Android Play Billing support
- easier restore, entitlement checks, trials, and paywall logic

### Crash / Analytics / Quality
- `Firebase Crashlytics`
- `Firebase Analytics`
- optional `Sentry` if deeper tracing is needed

## Design Direction from the Screenshots

### Core Visual Traits
- soft neutral backgrounds
- muted greys with selective accent colors
- minimal top chrome
- rounded cards and floating panels
- typography-led information hierarchy
- very airy spacing
- vertical date rail on the left
- elegant, almost editorial layout rather than standard Android productivity UI

### Second Screenshot Audit Notes
- 25 screenshot strips cover many chained screens, not only the home planner
- repeated dark grey settings stacks use pill tabs, white rounded rows, gold check states, and quiet toggles
- theme screens use circular palette constellations, mono/vivid/dark modes, and long color lists
- event screens include inspect-first detail, people, reminders, repeats, URL/notes, countdown, weather, map, and delete confirmation
- account and billing screens include trial education, membership cards, restore/redeem/delete-account paths, and sign-in forms
- support and release screens include help, feedback, feature request, and what's-new flows

### Android Adaptation Rules
- replace Apple sign-in with Google sign-in plus email auth
- replace Siri shortcuts with Android app shortcuts and optional Assistant intents later
- replace iOS-style sheets with custom bottom sheets / dialogs that preserve the look
- keep the overall visual identity as close as possible even when interaction components are Android-native under the hood

## Full Feature Inventory

## 1. App Shell and Navigation
- splash / launch flow
- onboarding carousel
- authenticated and unauthenticated app states
- left side slide-out menu
- bottom action bar for day views
- modal sheets for editors, pickers, and confirmations

## 2. Authentication
- sign in with email
- sign up with email
- Google sign-in
- password reset
- lightweight onboarding sequence for account details
- email communication opt-in screen

## 3. Timeline / Planner Experience
- vertical day timeline as the primary home screen
- left date rail with day labels and month marker
- timeline cards for events
- floating add button
- compact and expanded day states
- alternate day shading / week shading options
- "days at a glance" density controls
- busy-day event cycling animation
- optional hidden sections such as birthdays / all-day items

## 4. Month / Heatmap View
- month grid view
- event density visualization by day
- quick jump between month and day
- "today" summary panel
- calendar filter colors reflected in the month view

## 5. Event Creation
- title entry
- calendar selection
- date selection
- start and end time
- all-day mode
- event color/category association
- save / cancel flow

## 6. Event Editing
- notes
- URL
- location
- people / invitees
- reminders
- repeat rules
- countdown display
- delete event
- delete repeating instance vs all future events

## 7. Calendars
- default calendar selection
- visible calendars toggles
- per-calendar color identity
- built-in groups such as calendar, exercise, family, friends, work, birthdays, holidays
- match timeline colors toggle

## 8. Search
- global event search
- person-based search
- past / all time / future scopes
- empty states

## 9. RSVP / Invite Flow
- invitee-based event list
- RSVP screen
- attendee display in event details

## 10. Theme System
- mono / vivid / dark-style variants reflected in screenshots
- selectable accent palettes
- custom app icon color matching
- dynamic text sizing
- layout-specific theme tuning

## 11. Preferences
- general preferences
- calendar preferences
- timeline preferences
- weeks and day density preferences
- event display preferences
- weather preferences
- sounds preferences
- travel and directions settings
- app icon settings
- time settings
- text size settings
- actions and flow settings

## 12. Smart Alerts
- rain alerts
- daily briefing
- follow-up reminders
- time-to-leave reminders
- upcoming reminders
- configurable lead time
- severe-weather mode options

## 13. Travel and Directions
- default travel mode
- advanced travel modes toggle
- directions app preference
- travel icon selection

## 14. Account and Membership
- account overview
- sign out
- update email / password
- restore purchases
- membership status
- membership FAQ
- manage subscriptions
- redeem code
- delete account

## 15. Paywall / Subscription Flow
- free trial screens
- bundle / membership education screens
- subscription confirmation
- restore purchase flow
- success state
- manage subscription entry points

## 16. Help and Support
- contact support
- feature request
- how-to / FAQ entry points
- feedback form

## 17. What's New / Release Notes
- changelog screen
- onboarding-style showcase cards

## 18. Android-First Production Features
- offline-first local caching
- sync conflict handling
- loading / empty / error states
- accessibility support
- analytics events
- crash reporting
- privacy policy and terms screens

## Screen Map from the Repo Screenshots

Observed flows in the screenshots include:

- timeline home and variants
- slide-out menu
- month overview
- sign-in and sign-up
- email opt-in
- paywall and membership education
- account area
- event create flow
- event details
- reminders setup
- repeat rules builder
- people / invitees
- URL and notes editing
- countdown screen and sharing
- layout settings
- calendar settings
- theme selection
- preferences sections
- travel settings and travel icons
- app icon customization
- text sizing
- smart alerts, rain alerts, daily briefing
- Siri shortcuts equivalent feature area
- what's new
- help, feedback, feature request
- redeem code
- delete account

## Architecture Plan

### Feature Modules
- `core`
- `design_system`
- `auth`
- `onboarding`
- `timeline`
- `calendar`
- `events`
- `search`
- `alerts`
- `preferences`
- `themes`
- `account`
- `billing`
- `support`

### Data Layers
- presentation
- application/state
- domain
- data

### Main Entities
- `User`
- `Profile`
- `Calendar`
- `Event`
- `Reminder`
- `RepeatRule`
- `Location`
- `Invitee`
- `Membership`
- `ThemePreset`
- `PreferenceSet`
- `WeatherForecast`

## Suggested Neon Schema

### Tables
- `profiles`
- `calendars`
- `calendar_members`
- `events`
- `event_reminders`
- `event_repeat_rules`
- `event_invitees`
- `event_notes`
- `saved_locations`
- `preferences`
- `theme_settings`
- `memberships`
- `feature_flags`
- `feedback_tickets`

### Important Considerations
- row-level security from day one
- soft deletes for sync safety
- timestamps on all mutable records
- recurrence stored in a normalized structure plus generated occurrences
- keep the mobile app on HTTP APIs rather than direct Postgres connections

## Play Store Worthy Requirements

### Product Quality
- polished animations and transitions
- no placeholder UI in release
- robust form validation
- graceful offline behavior
- clear upgrade and restore purchase flows

### Technical Quality
- startup time targets
- stable scroll performance on large event lists
- no jank in timeline and month view
- test coverage for critical logic
- crash-free auth, billing, and reminder flows

### Compliance
- privacy policy
- terms of service
- account deletion path
- subscription disclosure compliance
- notification permission messaging
- location permission messaging

### Accessibility
- scalable text
- semantic labels
- touch targets
- contrast checks
- screen-reader-friendly event cards and controls

## Delivery Plan

## Phase 0. Discovery and Foundation
- [x] catalog every screenshot into a screen-by-screen checklist
- [x] define initial design tokens: colors, spacing, radii, typography, shadows
- [x] create the first component inventory through the home screen build
- [x] set up Flutter app and baseline architecture
- [x] add boot flow for storage mode selection
- [ ] add CI, flavors, and stricter linting

## Phase 1. Design System and App Shell
- [x] build initial theme engine
- [x] build first app shell and slide-out menu
- [x] build reusable first-pass timeline rail and event cards
- [x] build first dialogs, sheets, selectors, and chips
- [x] build settings controls

## Phase 2. Auth and Onboarding
- [x] email auth UI scaffold
- [x] Google sign-in UI scaffold
- [x] local profile save/edit flow
- [x] local communication opt-in persistence
- [ ] live email auth
- [ ] live Google sign-in
- [ ] profile setup
- [ ] communication opt-in

## Phase 3. Core Planner
- [x] timeline day view foundation
- [x] month overview foundation
- [x] month-to-day switching foundation
- [x] calendar filtering
- [x] local event CRUD
- [x] SQLite-backed on-device persistence mode

## Phase 4. Event Editor
- [x] title, date, time, calendar
- [x] all-day events
- [x] notes, location, and URL
- [x] reminder and repeat rule foundations
- [x] delete event handling
- [x] people
- [ ] advanced reminder behaviors and notification scheduling
- [ ] advanced repeat behaviors
- [ ] recurring-event handling

## Phase 5. Preferences and Themes
- [x] layout preferences UI scaffold
- [x] calendar preferences UI scaffold
- [x] dynamic default calendar persistence
- [x] theme selection UI scaffold
- [x] persisted theme selection
- [x] persisted text size
- [ ] app icon customization

## Phase 6. Alerts and Smart Features
- [x] rain alerts UI scaffold
- [x] daily briefing UI scaffold
- [x] upcoming reminders UI scaffold
- [x] time-to-leave UI scaffold
- [x] persisted alert/travel toggles
- [ ] live alert scheduling
- [ ] live time-to-leave logic

## Phase 7. Billing and Account
- [x] paywall UI scaffold
- [x] free trial UI scaffold
- [x] local membership preview state
- [ ] entitlement gating
- [x] account area UI scaffold
- [ ] redeem code
- [x] restore purchases UI scaffold
- [ ] live purchases

## Phase 8. Support and Polish
- [x] help and support UI scaffold
- [x] feature request flow UI scaffold
- [x] what's new UI scaffold
- [x] functional local event search
- [x] attendee-based RSVP summary
- [x] local support/feedback queue
- [ ] analytics
- [ ] crash reporting
- [ ] accessibility sweep
- [ ] performance tuning

## Phase 9. Release Preparation
- [ ] Play Store assets
- [ ] internal testing
- [ ] closed testing
- [ ] bug bash
- [ ] policy review

## Acceptance Criteria by Core Area

### Timeline
- smooth vertical scroll
- event cards render accurately for different durations
- day switching is fluid

### Calendar / Month
- month grid matches design tone
- day selection updates timeline context

### Event Editing
- all event attributes round-trip correctly
- recurring event editing supports single-instance and future-series choices

### Themes
- changing palette and mode updates the whole app without broken contrast

### Billing
- trial and subscription states are reflected correctly in UI
- restore purchases works reliably

### Alerts
- notification schedules survive app restarts
- weather-triggered alerts degrade gracefully if network is unavailable

## Biggest Risks
- matching the screenshot polish without building a strong custom design system first
- recurring event logic becoming brittle if rushed
- notification accuracy across local and remote scheduling
- subscription UX complexity
- location, travel-time, and weather integrations expanding scope

## Recommended Build Strategy
Do not try to build every screen one by one in isolation first.

Instead:

1. build the design system and app shell
2. build the timeline and month core
3. build the event domain and editor
4. add preferences and themes
5. add billing, account, and smart alerts
6. finish support, onboarding, analytics, and release polish

## Immediate Next Steps

1. [x] Create the Flutter project structure in this repo.
2. [x] Extract the screenshot flows into an implementation checklist.
3. [x] Implement the first design system foundation.
4. [ ] Add denser month heatmap behavior and deeper month interactions.
5. [ ] Connect the Flutter repository to the Worker-backed Neon API with live API responses.
6. [ ] Continue with live auth, subscription, notification scheduling, richer recurrence, and release preparation.

## Definition of Done for V1
- users can sign in
- users can view a timeline and month overview
- users can create, edit, repeat, and delete events
- users can manage calendars and preferences
- users can receive basic reminders and smart alert variants
- users can purchase / restore a subscription
- users can manage their account and delete it
- app is performant, tested, and compliant for Play Store submission
