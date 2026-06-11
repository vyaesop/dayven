import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

/// Thin wrapper over Firebase Analytics for the handful of funnel events we
/// care about. All calls are best-effort and never throw into the UI (analytics
/// must never break a user action). No-op on web/unsupported platforms.
class AnalyticsService {
  FirebaseAnalytics? get _analytics {
    if (kIsWeb) return null;
    try {
      return FirebaseAnalytics.instance;
    } catch (_) {
      return null;
    }
  }

  Future<void> _safe(Future<void> Function(FirebaseAnalytics a) body) async {
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      await body(analytics);
    } catch (_) {
      // Swallow: analytics is non-essential.
    }
  }

  /// Onboarding completed via account creation.
  Future<void> logSignUp(String method) =>
      _safe((a) => a.logSignUp(signUpMethod: method));

  /// Onboarding completed via sign-in (returning user).
  Future<void> logLogin(String method) =>
      _safe((a) => a.logLogin(loginMethod: method));

  /// A planner event was created.
  Future<void> logEventCreated({
    required bool isRecurring,
    required bool hasReminder,
  }) =>
      _safe((a) => a.logEvent(
            name: 'event_created',
            parameters: {
              'is_recurring': isRecurring ? 1 : 0,
              'has_reminder': hasReminder ? 1 : 0,
            },
          ));

  /// A secondary (native) calendar was enabled, e.g. Hijri/Hebrew.
  Future<void> logSecondaryCalendarSelected(String calendar) => _safe(
      (a) => a.logEvent(name: 'secondary_calendar_selected', parameters: {
            'calendar': calendar,
          }));
}
