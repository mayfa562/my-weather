import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_weather/services/weather_service.dart';

void main() {
  const workerBaseUrl = 'https://weather-api.example.workers.dev';

  test('sends city weather requests to the worker without a provider key',
      () async {
    late Uri requestedUri;
    final client = MockClient((request) async {
      requestedUri = request.url;
      return http.Response(
        jsonEncode({
          'name': 'Kampala',
          'sys': {'country': 'UG'},
          'coord': {'lat': 0.3, 'lon': 32.5},
          'main': {
            'temp': 25,
            'feels_like': 26,
            'temp_min': 24,
            'temp_max': 27,
            'humidity': 70,
          },
          'wind': {'speed': 3},
          'weather': [
            {
              'main': 'Clouds',
              'description': 'scattered clouds',
              'icon': '03d',
            }
          ],
          'dt': 1,
        }),
        200,
      );
    });
    final service = WeatherService(apiBaseUrl: workerBaseUrl, client: client);

    final weather = await service.getWeatherByCity('Kampala & Entebbe');

    expect(requestedUri.origin, Uri.parse(workerBaseUrl).origin);
    expect(requestedUri.path, '/data/2.5/weather');
    expect(requestedUri.queryParameters['q'], 'Kampala & Entebbe');
    expect(requestedUri.queryParameters['units'], 'metric');
    expect(requestedUri.queryParameters.containsKey('appid'), isFalse);
    expect(weather.cityName, 'Kampala');
    client.close();
  });

  test('rejects a missing or non-HTTPS worker URL before making a request',
      () async {
    var requestsMade = 0;
    final client = MockClient((_) async {
      requestsMade++;
      return http.Response('{}', 200);
    });

    for (final url in ['', 'http://weather-api.example.workers.dev']) {
      final service = WeatherService(apiBaseUrl: url, client: client);
      await expectLater(
        service.getWeatherByLocation(0.3, 32.5),
        throwsA(isA<WeatherException>()),
      );
    }

    expect(requestsMade, 0);
    client.close();
  });

  test('reports Worker rate limiting without exposing provider credentials',
      () async {
    final client = MockClient(
      (_) async => http.Response('{"error":"Too many requests"}', 429),
    );
    final service = WeatherService(apiBaseUrl: workerBaseUrl, client: client);

    await expectLater(
      service.getWeatherByLocation(0.3, 32.5),
      throwsA(
        isA<WeatherException>().having(
          (exception) => exception.message,
          'message',
          'Weather service rate limit reached. Try again shortly.',
        ),
      ),
    );

    client.close();
  });
}
