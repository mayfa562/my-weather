import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/weather_provider.dart';
import 'services/weather_service.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'services/background_weather_service.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

const _weatherApiBaseUrl =
    String.fromEnvironment('WEATHER_API_BASE_URL', defaultValue: '');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const WeatherApp(apiBaseUrl: _weatherApiBaseUrl));

  // Do not hold the first Flutter frame behind platform services. Android
  // keeps its native launch window visible until that frame is drawn.
  unawaited(_initializeServices(_weatherApiBaseUrl));
}

Future<void> _initializeServices(String apiBaseUrl) async {
  // Remove API keys saved by older app versions. The worker URL is public,
  // but the OpenWeatherMap credential must remain on the server.
  await BackgroundWeatherService.removeLegacyApiKey();

  // Schedule cross-platform mobile background weather checks.
  // Android uses WorkManager; iOS uses its background task scheduler.
  if (apiBaseUrl.isNotEmpty) {
    await BackgroundWeatherService.initialize(apiBaseUrl);
  }

  // Set up local notifications and ask for permission after the UI is ready.
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermission();
}

class WeatherApp extends StatelessWidget {
  final String apiBaseUrl;

  const WeatherApp({super.key, required this.apiBaseUrl});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WeatherProvider(
        weatherService: WeatherService(apiBaseUrl: apiBaseUrl),
        locationService: LocationService(),
      ),
      child: Builder(
        builder: (context) {
          final provider = context.watch<WeatherProvider>();

          return MaterialApp(
            title: 'My weather',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            locale: provider.locale,
            supportedLocales: const [
              Locale('en'),
              Locale('es'),
              Locale('fr'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
