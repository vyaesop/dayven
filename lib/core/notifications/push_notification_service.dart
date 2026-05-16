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

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
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

    final lead = _leadDurationFor(event.reminder);
    if (lead == null) {
      return;
    }

    final fireAt = event.startAt.subtract(lead);
    if (!fireAt.isAfter(DateTime.now())) {
      // Reminder time has already passed; do not schedule.
      return;
    }

    final scheduled = tz.TZDateTime.from(fireAt, tz.local);

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
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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
    // Stable positive int derived from event id; reserve a high range to
    // avoid clashing with foreground FCM message hashCodes used by show().
    final hash = eventId.hashCode;
    return 0x40000000 | (hash & 0x3FFFFFFF);
  }

  Duration? _leadDurationFor(PlannerReminder reminder) {
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
      title: title ?? 'Vertical Planner',
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
      title: 'Vertical Planner',
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
