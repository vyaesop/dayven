# Play Store Readiness — Vertical Planner
> PM Analysis · Last updated: 2026-06-02

---

## Overall Status: 65% Production-Ready

The UI and core feature set are differentiated and strong. Backend integrations (auth, billing, notifications, smart alerts) are scaffolded but non-functional. The app is **not ready to submit today** — estimated **3–4 focused weeks** to a shippable v1.

---

## Critical Blockers (App will be rejected or break user trust)

- [ ] **Release signing not configured** — debug key cannot be submitted to Play Store. Need keystore + `key.properties` + `build.gradle` signing config.
- [ ] **No Privacy Policy / Terms of Service URL** — required by Play Store for any app with accounts, Firebase, or subscriptions.
- [ ] **Auth is fake** — sign-in/sign-up writes only to SharedPreferences. Either remove for v1 or wire Firebase Auth (email + Google).
- [ ] **Subscription billing is non-functional** — paywall UI exists but no RevenueCat, no Google Play Billing, no entitlement enforcement. Showing a paywall without billing = policy violation.
- [ ] **Account deletion has no backend** — Google Play mandates in-app account deletion that removes server-side data. Cloud sync path has no delete endpoint.
- [ ] **App icon variants missing** — need mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi + adaptive icon layers. Generic icon signals unfinished product.

---

## High-Priority Issues (Will hurt ratings and retention)

- [ ] **"Sync Across Devices" mode is broken** — Neon/Cloudflare backend exists architecturally but auth is not wired. Users selecting this path will hit dead requests. Hide behind "Coming Soon" or auth gate.
- [ ] **Notifications never fire** — `flutter_local_notifications` is imported and reminder field is wired in the data model, but scheduling is never called at event save. Users setting reminders will get nothing.
- [ ] **Smart Alerts are 100% UI scaffolding** — rain alerts, daily briefings, time-to-leave are toggles with no logic. Remove from v1 or implement.
- [ ] **Travel section is 100% UI scaffolding** — directions app toggle, travel icon, advanced travel mode — no actions wired. Remove from v1 or implement.
- [ ] **No empty states** — no "No events today" or "No results" screens. First-run and empty-day UX is undefined.
- [ ] **No error states** — SQLite failure, network failure, and invalid state have no graceful handling.

---

## Play Store Listing Assets

- [ ] App icon (all density variants + adaptive)
- [ ] Feature graphic (1024×500 px)
- [ ] Phone screenshots (minimum 2, recommended 8)
- [ ] Short description (≤80 chars)
- [ ] Full description
- [ ] Privacy policy (hosted URL)
- [ ] Terms of service (hosted URL)
- [ ] Content rating questionnaire completed
- [ ] Category set: **Productivity**

---

## What's Working (Ship-Ready)

| Feature | Status |
|---|---|
| Vertical timeline / day view | Ready |
| Month overview with heatmap | Ready |
| Event CRUD — local SQLite | Ready |
| Calendar filtering + colors | Ready |
| Theme system (4 modes, 27 palettes) | Ready |
| Text scaling | Ready |
| RSVP tracking (local) | Ready |
| Event search | Ready |
| Preferences persistence | Ready |
| Firebase/FCM client setup | Ready |
| Storage mode selection screen | Ready |

---

## Feature Status by Section

| Section | Status | Notes |
|---|---|---|
| Timeline home | Ready | Core differentiator |
| Month overview | Ready | Heatmap is a nice touch |
| Event editor | Ready | All fields functional |
| Calendar management | Ready | 5 default calendars, color filtering |
| Themes | Ready | 4 modes, 27 palettes |
| Search | Ready | Local SQLite search |
| RSVP | Ready | Local SharedPreferences |
| Preferences | Ready | Persisted correctly |
| Smart Alerts | UI only | No weather API wired |
| Travel | UI only | No maps/directions wired |
| Auth / Account | UI only | No backend |
| Subscription / Paywall | UI only | No RevenueCat |
| Notifications / Reminders | Partial | Infrastructure exists, scheduling not called |
| Sync / Cloud | UI only | Neon backend ready but not auth-gated |
| Onboarding | UI only | Carousel scaffolded, not complete |
| App Icon customization | UI only | No actual icon variants |

---

## Recommended Launch Phases

### Phase 1 — Internal Testing (Week 1–2)
- [ ] Configure release signing
- [ ] Add app icon variants (all densities + adaptive)
- [ ] Write and host privacy policy + ToS
- [ ] Wire notification scheduling at event save time
- [ ] Hide or stub: Smart Alerts, Travel, Sync Across Devices
- [ ] Decide: **free launch** vs. **RevenueCat integration** before proceeding
- [ ] Decide: **remove auth** for v1 vs. **wire Firebase Auth**
- [ ] Add empty states for timeline and search results

### Phase 2 — Closed Testing (Week 3–4)
- [ ] Recruit 20–50 testers via Play Store internal/closed track
- [ ] Monitor: onboarding drop-off, crash rate, most-used features
- [ ] Fix anything surfaced from real usage

### Phase 3 — Open Testing / Production
- [ ] Only after auth is real (if offering accounts)
- [ ] Only after billing is wired (if showing paywall)
- [ ] Weather + maps integration (v1.1 target)
- [ ] Analytics + crash reporting (Firebase Crashlytics)

---

## Monetization Decision (Required Before Submission)

**Current state:** 7-day free trial → subscription, but billing is non-functional and the strongest subscription hook (sync across devices) doesn't work.

**Options:**

| Option | Effort | Risk |
|---|---|---|
| Launch free, no paywall | Low | Delays revenue |
| One-time purchase (no subscription) | Medium | Simpler billing, less recurring revenue |
| Full subscription with RevenueCat | High | Correct long-term model, 1+ week to implement |

**Recommendation:** Launch free or one-time purchase for v1. Introduce subscription in v1.1 once sync, notifications, and smart alerts are functional. Trial-to-paid conversion will be very low if the subscription's key value props don't work yet.

---

## Competitive Context

**Gap you fill:** No polished Timepage-equivalent exists on Android. The vertical timeline + accent palette system is a genuine differentiator.

**Risks:**
- Fantastical (Android) — well-funded, established
- Structured — growing fast in same aesthetic niche
- Google Calendar improving with Material You

**Target user:** Power users who find Google Calendar cluttered. Likely overlaps with Notion users, iOS Timepage users who switched to Android, productivity enthusiasts.

---

## Technical Debt to Track

- [ ] No unit tests — no widget tests — no integration tests
- [ ] No CI/CD pipeline
- [ ] No crash reporting (Sentry / Firebase Crashlytics)
- [ ] No analytics events wired
- [ ] Recurring event editing (single instance vs. all future) not implemented
- [ ] Sync conflict resolution not designed
- [ ] Accessibility: semantic labels incomplete, screen reader not optimized
- [ ] Performance: no benchmarking on large event lists

---

## Quick-Win Checklist (Can do this week)

- [ ] Release signing keystore
- [ ] App icon variants
- [ ] Privacy policy (use a generator, host on GitHub Pages)
- [ ] Hide Smart Alerts and Travel from menu (comment out drawer items)
- [ ] Stub "Sync Across Devices" with a "Coming Soon" dialog
- [ ] Wire `flutter_local_notifications` scheduling at event save
- [ ] Add empty state widget to home timeline
