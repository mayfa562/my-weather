import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';
import '../models/forecast_day.dart';
import '../models/city_suggestion.dart';

/// Thrown when a weather API call fails (network error, bad city name,
/// invalid API key, etc). The message is safe to show to the user.
class WeatherException implements Exception {
  final String message;
  WeatherException(this.message);

  @override
  String toString() => message;
}

class WeatherService {
  final String apiBaseUrl;
  final http.Client _client;

  WeatherService({
    required this.apiBaseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Uri _workerUri(String path, [Map<String, String> queryParameters = const {}]) {
    final baseUri = Uri.tryParse(apiBaseUrl.trim());
    if (baseUri == null ||
        baseUri.scheme != 'https' ||
        !baseUri.hasAuthority ||
        baseUri.userInfo.isNotEmpty ||
        (baseUri.path.isNotEmpty && baseUri.path != '/') ||
        baseUri.hasQuery ||
        baseUri.hasFragment) {
      throw WeatherException(
        'Weather service is not configured. Set WEATHER_API_BASE_URL to your Cloudflare Worker URL.',
      );
    }

    return baseUri.replace(path: path, queryParameters: queryParameters);
  }

  WeatherException _httpError(int statusCode, String resource) {
    return switch (statusCode) {
      401 || 403 => WeatherException('Weather service authorization failed.'),
      404 => WeatherException('City not found. Check the spelling and try again.'),
      429 => WeatherException('Weather service rate limit reached. Try again shortly.'),
      _ => WeatherException(
          'Failed to load $resource (code $statusCode).',
        ),
    };
  }

  /// Looks up cities matching [query] for search-as-you-type
  /// suggestions, via OpenWeatherMap's Geocoding API (a different
  /// endpoint from the weather/forecast ones, but same API key/tier).
  /// Returns an empty list on any failure rather than throwing —
  /// suggestions are a nice-to-have while typing, not something that
  /// should show an error banner if one lookup hiccups.
  Future<List<CitySuggestion>> searchCities(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    try {
      final uri = _workerUri(
        '/geo/1.0/direct',
        {'q': trimmed, 'limit': '5'},
      );
      final response = await _client.get(uri);
      if (response.statusCode != 200) return [];

      final List data = jsonDecode(response.body);
      return data
          .map((e) => CitySuggestion.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Current weather for a city name, e.g. "Kampala".
  Future<Weather> getWeatherByCity(String cityName) async {
    final uri = _workerUri(
      '/data/2.5/weather',
      {'q': cityName, 'units': 'metric'},
    );
    return _fetchWeather(uri);
  }

  /// Current weather for a lat/lon pair (used with device GPS location).
  Future<Weather> getWeatherByLocation(double lat, double lon) async {
    final uri = _workerUri(
      '/data/2.5/weather',
      {'lat': '$lat', 'lon': '$lon', 'units': 'metric'},
    );
    return _fetchWeather(uri);
  }

  Future<Weather> _fetchWeather(Uri uri) async {
    try {
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        return Weather.fromJson(jsonDecode(response.body));
      }
      throw _httpError(response.statusCode, 'weather');
    } on WeatherException {
      rethrow;
    } catch (e) {
      throw WeatherException('Network error: could not reach the weather service.');
    }
  }

  /// 5-day forecast (3-hour steps) for a city name.
  Future<List<ForecastDay>> getForecastByCity(String cityName) async {
    final uri = _workerUri(
      '/data/2.5/forecast',
      {'q': cityName, 'units': 'metric'},
    );
    return _fetchForecast(uri);
  }

  /// 5-day forecast (3-hour steps) for a lat/lon pair.
  Future<List<ForecastDay>> getForecastByLocation(double lat, double lon) async {
    final uri = _workerUri(
      '/data/2.5/forecast',
      {'lat': '$lat', 'lon': '$lon', 'units': 'metric'},
    );
    return _fetchForecast(uri);
  }

  Future<List<ForecastDay>> _fetchForecast(Uri uri) async {
    try {
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['list'] as List;
        return list.map((item) => ForecastDay.fromJson(item)).toList();
      }
      throw _httpError(response.statusCode, 'forecast');
    } on WeatherException {
      rethrow;
    } catch (e) {
      throw WeatherException('Network error: could not reach the weather service.');
    }
  }
}
