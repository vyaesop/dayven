flutter run \
  --dart-define=VP_BACKEND_MODE=neon \
  --dart-define=VP_API_BASE_URL=https://vplanner.vercel.app \
  --dart-define=VP_API_BEARER_TOKEN=vp_556a13da512e4ec1828fa2b269370d9e

# Play Store Readiness - Vertical Planner
> PM Analysis · Last updated: 2026-06-03

---

## Overall Status: 91% Production-Ready

Auth, cloud sync, notifications, crash reporting, release signing, privacy policy, app icons, and account deletion are all done. The only remaining gaps before submission are Play Store listing assets (screenshots, description, feature graphic) and the billing decision.

---

## Critical Blockers (App will be rejected or break user trust)

- [x] **Release signing** - keystore generated (`android/upload-keystore.jks`), `build.gradle.kts` configured with `signingConfigs.release`. Both files gitignored. Credentials stored in `android/key.properties` (local only, never committed).
- [x] **Privacy Policy / Terms of Service** - hosted on Vercel at `vplanner.vercel.app/privacy-policy.html` and `/terms.html`. Use these URLs in Play Store submission.
- [x] **Auth** - Firebase Auth wired: email/password + Google Sign-In. Real sign-in/sign-up, password reset, token-based API auth.
- [ ] **Subscription billing** - paywall **hidden from drawer for v1** to avoid policy violation. Implement RevenueCat before re-enabling.
- [x] **Account deletion** - `DELETE /v1/auth/user` endpoint wipes NeonDB rows and deletes Firebase account. Flutter delete button calls it in cloud sync mode with confirmation dialog.
- [x] **App icon variants** - generated with `flutter_launcher_icons` (all mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi + adaptive icon with charcoal `#35332E` background).

---

## High-Priority Issues (Will hurt ratings and retention)

- [x] **"Sync Across Devices" mode** - Vercel + NeonDB backend live at `vplanner.vercel.app`. Full CRUD wired. Auth gating still needed for multi-user production use.
- [x] **Notifications** - `scheduleEventReminder` / `cancelEventReminder` wired in `planner_controller.dart` at create, update, delete, and cold-start reschedule.
- [ ] **Smart Alerts are UI-only** - toggles persist but weather delivery and push scheduling need v1.1 integration. **Coming Soon banner added** to the screen.
- [ ] **Travel section is UI-only** - preferences persist but live directions/time-to-leave need map integration in v1.1. **Coming Soon banner added** to the screen.
- [x] **Empty states** - `_EmptyDayState` in `home_screen.dart` covers the timeline; search falls back to "No matches" row.
- [x] **Error states** - `_HomeError` in `home_screen.dart` shows the error with a **Retry button** that invalidates the provider.

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
| Event CRUD - local SQLite | Ready |
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
| Auth / Account | Ready | Firebase Auth: email/password + Google Sign-In |
| Subscription / Paywall | Hidden | Paywall removed from drawer for v1; RevenueCat for v1.1 |
| Notifications / Reminders | Ready | Scheduling wired in planner_controller at save/delete/boot |
| Sync / Cloud | Ready | Vercel + NeonDB live; auth gating needed for multi-user |
| Onboarding | UI only | Carousel scaffolded, not complete |
| App Icon customization | UI only | No actual icon variants |

---

## Recommended Launch Phases

### Phase 1 - Internal Testing (Week 1–2)
- [x] Release signing - keystore + `build.gradle.kts` configured
- [x] App icon variants - all densities + adaptive (charcoal background)
- [x] Privacy policy + ToS - live at `vplanner.vercel.app/privacy-policy.html` and `/terms.html`
- [x] Wire notification scheduling at event save time
- [x] Smart Alerts and Travel show "Coming Soon" banners
- [x] Cloud sync live - Vercel + NeonDB + Firebase Auth
- [x] Firebase Auth wired - email/password + Google Sign-In
- [x] Account deletion - full wipe (NeonDB + Firebase) with confirmation dialog
- [x] Firebase Crashlytics wired
- [ ] **Decide: free launch for v1 vs. RevenueCat** - paywall currently hidden
- [x] Empty states for timeline and search results

### Phase 2 - Closed Testing (Week 3–4)
- [ ] Recruit 20–50 testers via Play Store internal/closed track
- [ ] Monitor: onboarding drop-off, crash rate, most-used features
- [ ] Fix anything surfaced from real usage

### Phase 3 - Open Testing / Production
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

**Recommendation:** Launch free or one-time purchase for v1. Cloud sync and notifications are now working, but billing integration (RevenueCat) still needs 1+ week of work. Introduce the subscription in v1.1 once the paywall is gated by real entitlements.

---

## Competitive Context

**Gap you fill:** No polished Timepage-equivalent exists on Android. The vertical timeline + accent palette system is a genuine differentiator.

**Risks:**
- Fantastical (Android) - well-funded, established
- Structured - growing fast in same aesthetic niche
- Google Calendar improving with Material You

**Target user:** Power users who find Google Calendar cluttered. Likely overlaps with Notion users, iOS Timepage users who switched to Android, productivity enthusiasts.

---

## Technical Debt to Track

- [ ] No unit tests - no widget tests - no integration tests
- [ ] No CI/CD pipeline
- [x] Crash reporting - Firebase Crashlytics wired in `main.dart` (Flutter + platform errors)
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
- [x] Smart Alerts and Travel - "Coming Soon" banners added (v1.1 scope)
- [x] Cloud sync live - Vercel + NeonDB backend wired end-to-end
- [x] `flutter_local_notifications` scheduling wired at event save/update/delete
- [x] Empty state widget on home timeline (`_EmptyDayState`)
- [x] Retry button on error state (`_HomeError`)
