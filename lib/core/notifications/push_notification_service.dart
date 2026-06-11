import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../features/home/domain/planner_models.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    return;
  }
  await PushNotificationService.recordBackgroundMessage(message);
}

class PushNotificationSnapshot {
  const PushNotificationSnapshot({
    required this.enabled,
    required this.permissionStatus,
    required this.fcmToken,
    required this.lastTitle,
    required this.lastBody,
    required this.lastReceivedAt,
    required this.error,
  });

  final bool enabled;
  final String permissionStatus;
  final String fcmToken;
  final String lastTitle;
  final String lastBody;
  final DateTime? lastReceivedAt;
  final String error;
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const channelId = 'planner_reminders';
  static const _channelName = 'Planner Reminders';
  static const _channelDescription =
      'Remote planner updates and reminder notifications.';
  static const _tokenKey = 'push_fcm_token';
  static const _enabledKey = 'push_enabled';
  static const _permissionStatusKey = 'push_permission_status';
  static const _lastTitleKey = 'push_last_title';
  static const _lastBodyKey = 'push_last_body';
  static const _lastReceivedAtKey = 'push_last_received_at';
  static const _lastErrorKey = 'push_last_error';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _timezoneReady = false;
  // Whether the OS currently lets us schedule exact alarms. On Android 13+ this
  // is auto-granted via USE_EXACT_ALARM; on Android 12 (API 31-32) the user can
  // revoke it, so we detect it and fall back to inexact scheduling rather than
  // throwing (a slightly-late reminder beats no reminder).
  bool _exactAlarmsAllowed = true;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      return;
    }
    _initialized = true;

    try {
      await _initializeTimezone();
      await _initializeLocalNotifications();
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await _savePermission(settings.authorizationStatus.name);

      await _requestAndroidRuntimePermission();

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _saveToken(token);
        if (kDebugMode) {
          debugPrint('[push] FCM token: $token');
        }
      }
      FirebaseMessaging.instance.onTokenRefresh.listen((value) async {
        await _saveToken(value);
        if (kDebugMode) {
          debugPrint('[push] FCM token refreshed: $value');
        }
      });

      FirebaseMessaging.onMessage.listen((message) async {
        await recordBackgroundMessage(message);
        await _showForegroundMessage(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen(recordBackgroundMessage);
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        await recordBackgroundMessage(initialMessage);
      }

      await _saveEnabled(true);
      await _saveError('');
    } catch (error) {
      await _saveEnabled(false);
      await _saveError(error.toString());
    }
  }

  Future<PushNotificationSnapshot> snapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final rawReceivedAt = prefs.getString(_lastReceivedAtKey);
    return PushNotificationSnapshot(
      enabled: prefs.getBool(_enabledKey) ?? false,
      permissionStatus: prefs.getString(_permissionStatusKey) ?? 'unknown',
      fcmToken: prefs.getString(_tokenKey) ?? '',
      lastTitle: prefs.getString(_lastTitleKey) ?? '',
      lastBody: prefs.getString(_lastBodyKey) ?? '',
      lastReceivedAt:
          rawReceivedAt == null ? null : DateTime.tryParse(rawReceivedAt),
      error: prefs.getString(_lastErrorKey) ?? '',
    );
  }

  static Future<void> recordBackgroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastTitleKey, notification?.title ?? '');
    await prefs.setString(_lastBodyKey, notification?.body ?? '');
    await prefs.setString(
      _lastReceivedAtKey,
      DateTime.now().toIso8601String(),
    );
  }

  Future<void> _initializeLocalNotifications() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotifications.initialize(settings: initializationSettings);

    const androidChannel = AndroidNotificationChannel(
      channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    final android = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(androidChannel);

    // Resolve whether exact alarms are permitted, requesting the permission on
    // Android 12 where it is user-grantable. Cache the result so scheduling can
    // gracefully degrade to inexact mode instead of throwing.
    try {
      var allowed = await android?.canScheduleExactNotifications() ?? true;
      if (!allowed) {
        allowed = await android?.requestExactAlarmsPermission() ?? false;
      }
      _exactAlarmsAllowed = allowed;
    } catch (_) {
      _exactAlarmsAllowed = true;
    }
  }

  Future<void> _initializeTimezone() async {
    if (_timezoneReady) {
      return;
    }
    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[push] failed to resolve local timezone: $error');
      }
      tz.setLocalLocation(tz.UTC);
    }
    _timezoneReady = true;
  }

  Future<void> scheduleEventReminder(PlannerEvent event) async {
    if (kIsWeb) {
      return;
    }
    await _initializeTimezone();

    await cancelEventReminder(event.id);

    if (event.reminder == PlannerReminder.none) {
      return;
    }

    final fireAt = reminderFireTime(event, DateTime.now());
    if (fireAt == null) {
      // No upcoming occurrence whose reminder is still in the future.
      return;
    }

    final scheduled = tz.TZDateTime.from(fireAt, tz.local);

    // For simple, open-ended recurrences we let Android repeat the notification
    // natively so subsequent occurrences still fire even if the app is never
    // reopened. Rules that can't be expressed as a single repeating component
    // (intervals > 1, biweekly, monthly/yearly, multiple weekdays, or a count/
    // until limit) fall back to a one-shot that is re-armed on the next launch.
    final matchComponent = _repeatComponentFor(event);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notification',
      ),
    );

    try {
      await _localNotifications.zonedSchedule(
        id: _eventNotificationId(event.id),
        title: event.title.isEmpty ? 'Reminder' : event.title,
        body: _reminderBody(event),
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: _exactAlarmsAllowed
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: matchComponent,
        payload: 'event:${event.id}',
      );
      if (kDebugMode) {
        debugPrint(
          '[push] scheduled reminder for "${event.title}" at $scheduled',
        );
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[push] failed to schedule reminder: $error');
      }
    }
  }

  Future<void> cancelEventReminder(String eventId) async {
    if (kIsWeb) {
      return;
    }
    try {
      await _localNotifications.cancel(id: _eventNotificationId(eventId));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[push] failed to cancel reminder: $error');
      }
    }
  }

  Future<void> rescheduleAllEventReminders(Iterable<PlannerEvent> events) async {
    if (kIsWeb) {
      return;
    }
    await _initializeTimezone();
    for (final event in events) {
      await scheduleEventReminder(event);
    }
  }

  Future<List<PendingNotificationRequest>> pendingScheduledReminders() async {
    if (kIsWeb) {
      return const [];
    }
    return _localNotifications.pendingNotificationRequests();
  }

  int _eventNotificationId(String eventId) {
    // Deterministic positive int derived from the event id. We use FNV-1a rather
    // than String.hashCode because hashCode is not guaranteed stable across app
    // restarts/builds — and the OS-scheduled notification id must match on a
    // later launch for cancel/reschedule to work. The high bit is reserved to
    // keep these out of the range used by foreground FCM show() ids.
    var hash = 0x811c9dc5;
    for (final unit in eventId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return 0x40000000 | (hash & 0x3FFFFFFF);
  }

  /// All-day events have no clock time, so anchor their reminders at this local
  /// hour on the event day — otherwise "at time" would fire at midnight.
  static const int allDayReminderHour = 9;

  /// Pure, testable computation of when [event]'s reminder should fire, in local
  /// wall-clock time, or null when there is no upcoming reminder.
  ///
  /// Occurrences are built with wall-clock construction (`DateTime(y, m, d, h,
  /// min)`), so a recurring event keeps the same local time across DST
  /// transitions (a 9:00 daily event stays 9:00, not 8:00/10:00). The absolute
  /// instant is resolved for the device's current zone by the caller via
  /// `tz.TZDateTime.from`.
  @visibleForTesting
  static DateTime? reminderFireTime(PlannerEvent event, DateTime now) {
    final lead = _leadDurationFor(event.reminder);
    if (lead == null) return null;
    final start = _nextReminderStart(event, lead, now);
    if (start == null) return null;
    return start.subtract(lead);
  }

  /// The wall-clock start used for reminders on a given [date]. Timed events use
  /// their own hour/minute; all-day events anchor at [allDayReminderHour].
  static DateTime _reminderStartOnDate(PlannerEvent event, DateTime date) {
    if (event.isAllDay) {
      return DateTime(date.year, date.month, date.day, allDayReminderHour);
    }
    return DateTime(date.year, date.month, date.day, event.startAt.hour,
        event.startAt.minute);
  }

  /// The start time of the next occurrence whose reminder fire time is still in
  /// the future. For non-repeating events this is the event start (if its
  /// reminder hasn't passed). For recurring events we walk forward through the
  /// series to find the next occurrence to remind about.
  static DateTime? _nextReminderStart(
      PlannerEvent event, Duration lead, DateTime now) {
    final recurrence = event.effectiveRecurrence;
    if (!recurrence.repeats) {
      final start = _reminderStartOnDate(event, event.startAt);
      return start.subtract(lead).isAfter(now) ? start : null;
    }

    final anchor = DateTime(
      event.startAt.year,
      event.startAt.month,
      event.startAt.day,
    );
    // Look ahead far enough to cover sparse rules (e.g. yearly). Pass today as
    // the lower bound so a long-running series (e.g. a years-old daily event)
    // fast-forwards to upcoming occurrences instead of exhausting the cap.
    final horizon = DateTime(now.year + 2, now.month, now.day);
    final today = DateTime(now.year, now.month, now.day);
    for (final date
        in recurrence.occurrenceDates(anchor, horizon, rangeStart: today)) {
      final start = _reminderStartOnDate(event, date);
      if (start.subtract(lead).isAfter(now)) {
        return start;
      }
    }
    return null;
  }

  /// The native repeat component for an event's recurrence, or null when the
  /// rule can't be represented by a single repeating notification (in which case
  /// we schedule a one-shot and rely on re-arming at the next app launch).
  ///
  /// We only map open-ended (no count/until) rules: a daily-every-1-day rule
  /// repeats at the same time each day; a weekly-every-1-week rule on a single
  /// weekday repeats on that weekday. The constant lead time is baked into the
  /// scheduled fire time, so repeating on the fire instant stays correct.
  DateTimeComponents? _repeatComponentFor(PlannerEvent event) {
    final rec = event.effectiveRecurrence;
    if (!rec.repeats || rec.endMode != RecurrenceEndMode.never) return null;
    if (rec.interval != 1) return null;
    switch (rec.frequency) {
      case PlannerRepeatRule.daily:
        return DateTimeComponents.time;
      case PlannerRepeatRule.weekly:
        // A single weekday (or the anchor's own weekday) maps cleanly; multiple
        // weekdays would need several notifications, so fall back to one-shot.
        return rec.byWeekdays.length <= 1
            ? DateTimeComponents.dayOfWeekAndTime
            : null;
      case PlannerRepeatRule.biweekly:
      case PlannerRepeatRule.monthly:
      case PlannerRepeatRule.yearly:
      case PlannerRepeatRule.never:
        return null;
    }
  }

  static Duration? _leadDurationFor(PlannerReminder reminder) {
    switch (reminder) {
      case PlannerReminder.none:
        return null;
      case PlannerReminder.atTime:
        return Duration.zero;
      case PlannerReminder.fiveMinutesBefore:
        return const Duration(minutes: 5);
      case PlannerReminder.tenMinutesBefore:
        return const Duration(minutes: 10);
      case PlannerReminder.fifteenMinutesBefore:
        return const Duration(minutes: 15);
      case PlannerReminder.thirtyMinutesBefore:
        return const Duration(minutes: 30);
      case PlannerReminder.oneHourBefore:
        return const Duration(hours: 1);
      case PlannerReminder.twoHoursBefore:
        return const Duration(hours: 2);
      case PlannerReminder.oneDayBefore:
        return const Duration(days: 1);
      case PlannerReminder.oneWeekBefore:
        return const Duration(days: 7);
    }
  }

  String _reminderBody(PlannerEvent event) {
    final pieces = <String>[];
    if (event.isAllDay) {
      pieces.add('All day');
    } else {
      pieces.add(event.timeRange);
    }
    if (event.location.isNotEmpty) {
      pieces.add(event.location);
    }
    return pieces.join(' · ');
  }

  Future<void> _requestAndroidRuntimePermission() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> _showForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();
    if (title == null && body == null) {
      return;
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notification',
      ),
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: title ?? 'Dayven',
      body: body ?? '',
      notificationDetails: details,
      payload: message.data['route']?.toString(),
    );
  }

  Future<void> sendTestLocalNotification() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notification',
      ),
    );
    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: 'Dayven',
      body: 'Test notification — channel and permissions are working.',
      notificationDetails: details,
    );
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> _saveEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  Future<void> _savePermission(String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_permissionStatusKey, status);
  }

  Future<void> _saveError(String error) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastErrorKey, error);
  }
}
