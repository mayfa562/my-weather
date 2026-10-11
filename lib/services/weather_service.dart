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
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _geoUrl = 'https://api.openweathermap.org/geo/1.0';
  final String apiKey;

  WeatherService({required this.apiKey});

  /// Looks up cities matching [query] for search-as-you-type
  /// suggestions, via OpenWeatherMap's Geocoding API (a different
  /// endpoint from the weather/forecast ones, but same API key/tier).
  /// Returns an empty list on any failure rather than throwing —
  /// suggestions are a nice-to-have while typing, not something that
  /// should show an error banner if one lookup hiccups.
  Future<List<CitySuggestion>> searchCities(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    final uri = Uri.parse(
      '$_geoUrl/direct?q=${Uri.encodeQueryComponent(trimmed)}&limit=5&appid=$apiKey',
    );

    try {
      final response = await http.get(uri);
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
    final uri = Uri.parse(
      '$_baseUrl/weather?q=$cityName&units=metric&appid=$apiKey',
    );
    return _fetchWeather(uri);
  }

  /// Current weather for a lat/lon pair (used with device GPS location).
  Future<Weather> getWeatherByLocation(double lat, double lon) async {
    final uri = Uri.parse(
      '$_baseUrl/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey',
    );
    return _fetchWeather(uri);
  }

  Future<Weather> _fetchWeather(Uri uri) async {
    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return Weather.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        throw WeatherException('City not found. Check the spelling and try again.');
      } else if (response.statusCode == 401) {
        throw WeatherException('Invalid API key. Check your .env file.');
      } else {
        throw WeatherException('Failed to load weather (code ${response.statusCode}).');
      }
    } on WeatherException {
      rethrow;
    } catch (e) {
      throw WeatherException('Network error: could not reach the weather service.');
    }
  }

  /// 5-day forecast (3-hour steps) for a city name.
  Future<List<ForecastDay>> getForecastByCity(String cityName) async {
    final uri = Uri.parse(
      '$_baseUrl/forecast?q=$cityName&units=metric&appid=$apiKey',
    );
    return _fetchForecast(uri);
  }

  /// 5-day forecast (3-hour steps) for a lat/lon pair.
  Future<List<ForecastDay>> getForecastByLocation(double lat, double lon) async {
    final uri = Uri.parse(
      '$_baseUrl/forecast?lat=$lat&lon=$lon&units=metric&appid=$apiKey',
    );
    return _fetchForecast(uri);
  }

  Future<List<ForecastDay>> _fetchForecast(Uri uri) async {
    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['list'] as List;
        return list.map((item) => ForecastDay.fromJson(item)).toList();
      } else if (response.statusCode == 404) {
        throw WeatherException('City not found. Check the spelling and try again.');
      } else if (response.statusCode == 401) {
        throw WeatherException('Invalid API key. Check your .env file.');
      } else {
        throw WeatherException('Failed to load forecast (code ${response.statusCode}).');
      }
    } on WeatherException {
      rethrow;
    } catch (e) {
      throw WeatherException('Network error: could not reach the weather service.');
    }
  }
}
