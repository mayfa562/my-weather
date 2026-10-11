import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import '../localization/app_strings.dart';
import '../models/weather.dart';
import 'weather_change_detector.dart';

const String weatherBackgroundTask = 'my_weather_background_check';

/// Cross-platform mobile background worker for periodic weather checks.
///
/// WorkManager uses Android WorkManager on Android and BGTaskScheduler on iOS.
///
/// This is intentionally a background worker rather than a foreground
/// service: weather polling does not need a permanent status-bar notification.
/// Android WorkManager decides the exact execution time and may delay work
/// because of battery/data-saving policies.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != weatherBackgroundTask &&
        task != Workmanager.iOSBackgroundTask) {
      return true;
    }

    try {
      await BackgroundWeatherService.checkNow();
      return true;
    } catch (_) {
      // Returning true prevents WorkManager from retrying indefinitely for
      // transient API/permission failures. The next scheduled check will run.
      return true;
    }
  });
}

class BackgroundWeatherService {
  BackgroundWeatherService._();

  static const _apiBaseUrlKey = 'weather_api_base_url';
  static const _legacyApiKeyKey = 'background_weather_api_key';
  static const _languageKey = 'app_language';
  static const _locationLatKey = 'last_location_lat';
  static const _locationLonKey = 'last_location_lon';
  static const _snapshotsKey = 'background_weather_snapshots';
  static const _notificationsEnabledKey = 'weather_notifications_enabled';

  static const _channelId = 'weather_alerts';
  static const _channelName = 'Weather Alerts';
  static const _channelDescription =
      'Notifies you when there is a sudden change in the weather';

  static Future<void> removeLegacyApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyApiKeyKey);
  }

  static Future<void> initialize(String apiBaseUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyApiKeyKey);
    if (apiBaseUrl.trim().isNotEmpty) {
      await prefs.setString(_apiBaseUrlKey, apiBaseUrl.trim());
    }

    final enabled = prefs.getBool(_notificationsEnabledKey) ?? true;
    if (enabled) {
      await Workmanager().initialize(callbackDispatcher);
      await Workmanager().registerPeriodicTask(
        'my-weather-weather-check',
        weatherBackgroundTask,
        frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        constraints: Constraints(networkType: NetworkType.connected),
      );
    }
  }

  /// Stores a fresh foreground reading so the next background run has a
  /// real baseline to compare against.
  static Future<void> recordForegroundSnapshot(Weather weather) async {
    final prefs = await SharedPreferences.getInstance();
    final snapshots = _readSnapshots(prefs);
    final key =
        '${weather.latitude.toStringAsFixed(3)},${weather.longitude.toStringAsFixed(3)}';
    snapshots[key] = {
      'temperature': weather.temperature,
      'condition': weather.mainCondition,
      'description': weather.description,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await prefs.setString(_snapshotsKey, jsonEncode(snapshots));
  }

  static Future<void> checkNow() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_notificationsEnabledKey) ?? true;
    if (!enabled) return;

    final apiBaseUrl = prefs.getString(_apiBaseUrlKey) ?? '';
    if (apiBaseUrl.isEmpty) return;

    final language = prefs.getString(_languageKey) ?? 'en';
    final locations = <_CheckLocation>[];
    final locationKeys = <String>{};

    void addLocation(String name, double lat, double lon) {
      // Use rounded coordinates to avoid checking/notifying the same city twice
      // when it is both the current location and a starred city.
      final key = '${lat.toStringAsFixed(3)},${lon.toStringAsFixed(3)}';
      if (locationKeys.add(key)) {
        locations.add(_CheckLocation(name, lat, lon));
      }
    }

    final lat = prefs.getDouble(_locationLatKey);
    final lon = prefs.getDouble(_locationLonKey);
    if (lat != null && lon != null) {
      addLocation('Current location', lat, lon);
    }

    final rawFavorites = prefs.getString('favorite_cities');
    if (rawFavorites != null) {
      try {
        final decoded = jsonDecode(rawFavorites) as List;
        for (final item in decoded) {
          final map = item as Map<String, dynamic>;
          final cityLat = (map['lat'] as num?)?.toDouble();
          final cityLon = (map['lon'] as num?)?.toDouble();
          final cityName = map['name'] as String? ?? 'Saved city';
          if (cityLat != null && cityLon != null) {
            addLocation(cityName, cityLat, cityLon);
          }
        }
      } catch (_) {}
    }

    if (locations.isEmpty) return;

    final notifications = FlutterLocalNotificationsPlugin();
    const initialization = InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_stat_weather'),
      iOS: DarwinInitializationSettings(),
    );
    await notifications.initialize(settings: initialization);

    final snapshots = _readSnapshots(prefs);
    var changed = false;

    for (final location in locations) {
      final weather = await _fetch(location.lat, location.lon, apiBaseUrl);
      if (weather == null) continue;

      final key =
          '${location.lat.toStringAsFixed(3)},${location.lon.toStringAsFixed(3)}';
      final previous = snapshots[key];

      if (previous != null) {
        final description = WeatherChangeDetector.describeChange(
          previousTemp: (previous['temperature'] as num).toDouble(),
          previousCondition: previous['condition'] as String,
          newTemp: (weather['temperature'] as num).toDouble(),
          newCondition: weather['condition'] as String,
          newDescription: weather['description'] as String,
        );

        if (description != null) {
          final strings = AppStrings(language);
          final title = strings.weatherUpdateTitle(weather['city']);
          final body = strings.localizeChangeDescription(description);
          final id = key.hashCode & 0x7fffffff;

          const androidDetails = AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_stat_weather',
            color: Color(0xFF5B35D5),
          );
          const details = NotificationDetails(
            android: androidDetails,
            iOS: DarwinNotificationDetails(),
          );

          await notifications.show(
            id: id,
            title: title,
            body: body,
            notificationDetails: details,
          );
        }
      }

      snapshots[key] = {
        'temperature': weather['temperature'],
        'condition': weather['condition'],
        'description': weather['description'],
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      changed = true;
    }

    if (changed) {
      await prefs.setString(_snapshotsKey, jsonEncode(snapshots));
    }
  }

  static Map<String, dynamic> _readSnapshots(SharedPreferences prefs) {
    final raw = prefs.getString(_snapshotsKey);
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  static Future<Map<String, dynamic>?> _fetch(
      double lat, double lon, String apiBaseUrl) async {
    final baseUri = Uri.tryParse(apiBaseUrl);
    if (baseUri == null ||
        baseUri.scheme != 'https' ||
        !baseUri.hasAuthority ||
        baseUri.userInfo.isNotEmpty ||
        (baseUri.path.isNotEmpty && baseUri.path != '/') ||
        baseUri.hasQuery ||
        baseUri.hasFragment) {
      return null;
    }
    final uri = baseUri.replace(
      path: '/data/2.5/weather',
      queryParameters: {
        'lat': '$lat',
        'lon': '$lon',
        'units': 'metric',
      },
    );
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final weather = (data['weather'] as List).first as Map<String, dynamic>;
      return {
        'city': data['name'] as String? ?? 'Weather',
        'temperature': (data['main']['temp'] as num).toDouble(),
        'condition': weather['main'] as String? ?? 'Clear',
        'description': weather['description'] as String? ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
    if (enabled) {
      final apiBaseUrl = prefs.getString(_apiBaseUrlKey) ?? '';
      if (apiBaseUrl.isNotEmpty) await initialize(apiBaseUrl);
    } else {
      await Workmanager().cancelByUniqueName('my-weather-weather-check');
    }
  }
}

class _CheckLocation {
  final String name;
  final double lat;
  final double lon;
  const _CheckLocation(this.name, this.lat, this.lon);
}
