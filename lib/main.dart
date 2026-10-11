import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'providers/weather_provider.dart';
import 'services/weather_service.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'services/background_weather_service.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Loads OPENWEATHER_API_KEY from the .env file (see .env.example).
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // The app can still start so the user can see the UI before adding a key.
  }
  final apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';

  runApp(WeatherApp(apiKey: apiKey));

  // Do not hold the first Flutter frame behind platform services. Android
  // keeps its native launch window visible until that frame is drawn.
  unawaited(_initializeServices(apiKey));
}

Future<void> _initializeServices(String apiKey) async {
  // Schedule cross-platform mobile background weather checks.
  // Android uses WorkManager; iOS uses its background task scheduler.
  if (apiKey.isNotEmpty) {
    await BackgroundWeatherService.initialize(apiKey);
  }

  // Set up local notifications and ask for permission after the UI is ready.
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermission();
}

class WeatherApp extends StatelessWidget {
  final String apiKey;

  const WeatherApp({super.key, required this.apiKey});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WeatherProvider(
        weatherService: WeatherService(apiKey: apiKey),
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
