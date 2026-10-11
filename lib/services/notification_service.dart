import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Wraps `flutter_local_notifications` so the rest of the app just
/// calls [init], [requestPermission], and [showWeatherAlert] without
/// touching platform-specific notification APIs directly.
///
/// Fires from two contexts: a normal foreground refresh, and the
/// background task in `background_service.dart` (which checks
/// current location + starred cities on a schedule, even when the
/// app is closed — see that file for the platform limits on this).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'weather_alerts';
  static const _channelName = 'Weather Alerts';
  static const _channelDescription =
      'Notifies you when there is a sudden change in the weather';

  /// Sets up the plugin. Safe to call more than once — only runs once.
  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_stat_weather');
    const iosSettings = DarwinInitializationSettings();
    const settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(settings: settings);

    // Create the Android channel explicitly so background notifications
    // use the same high-importance channel as foreground notifications.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.high,
          ),
        );

    _initialized = true;
  }

  /// Requests notification permission. Required at runtime on Android
  /// 13+ and iOS; a no-op (auto-granted) on older Android versions.
  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Shows a weather-change alert. [id] defaults to 0 (a new alert
  /// replaces any previous one) — pass a distinct id per location
  /// when multiple places might alert in the same check (e.g. the
  /// background task checking several starred cities at once), or
  /// they'd silently overwrite each other instead of each showing.
  Future<void> showWeatherAlert(
      {required String title, required String body, int id = 0}) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_stat_weather',
      color: Color(0xFF5B35D5),
    );
    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}
