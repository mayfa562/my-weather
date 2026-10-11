import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather.dart';
import '../models/forecast_day.dart';
import '../models/city_suggestion.dart';
import '../models/favorite_city.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/background_weather_service.dart';
import '../services/weather_change_detector.dart';
import '../localization/app_strings.dart';

enum WeatherStatus { initial, loading, loaded, error }

/// Tracks how the currently-displayed weather was fetched, so
/// [WeatherProvider.refresh] knows how to repeat it: re-search the
/// last city name, re-check the device's GPS, or re-fetch the same
/// lat/lon (used when a city was picked from search suggestions,
/// where the exact coordinates are already known and more reliable
/// than re-searching by name).
enum WeatherSource { none, city, location, coordinates }

/// Groups a raw 3-hour-step forecast list into one entry per day.
/// The icon/description come from the reading closest to midday
/// (the best single snapshot of that day's general conditions), but
/// the high/low are computed across *all* of that day's readings —
/// using a single reading's own temp_min/temp_max would give a "low"
/// that's nearly identical to its own temperature, not a real daily
/// range.
List<ForecastDay> groupForecastByDay(List<ForecastDay> raw) {
  final Map<String, List<ForecastDay>> byDay = {};

  for (final entry in raw) {
    final key =
        '${entry.dateTime.year}-${entry.dateTime.month}-${entry.dateTime.day}';
    byDay.putIfAbsent(key, () => []).add(entry);
  }

  final result = <ForecastDay>[];

  for (final entries in byDay.values) {
    // The representative entry for icon/description/time — closest
    // to noon.
    ForecastDay representative = entries.first;
    var bestDistance = (representative.dateTime.hour - 12).abs();
    for (final entry in entries) {
      final distance = (entry.dateTime.hour - 12).abs();
      if (distance < bestDistance) {
        representative = entry;
        bestDistance = distance;
      }
    }

    // The real daily range, across every reading for that day — not
    // just the representative entry's own (nearly-identical) min/max.
    final temps = entries.map((e) => e.temperature);
    final dailyHigh = temps.reduce((a, b) => a > b ? a : b);
    final dailyLow = temps.reduce((a, b) => a < b ? a : b);

    result.add(ForecastDay(
      dateTime: representative.dateTime,
      temperature: representative.temperature,
      tempMin: dailyLow,
      tempMax: dailyHigh,
      humidity: representative.humidity,
      windSpeed: representative.windSpeed,
      mainCondition: representative.mainCondition,
      description: representative.description,
      iconCode: representative.iconCode,
    ));
  }

  result.sort((a, b) => a.dateTime.compareTo(b.dateTime));
  return result;
}

class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService;
  final LocationService _locationService;
  final NotificationService _notificationService;

  /// Resolves once favorites and the user's name have been loaded
  /// from disk. Anything that needs to make a decision based on that
  /// loaded state — like whether to show the first-launch name
  /// prompt — should await this first. Without it, a check running
  /// right after the app starts could see the still-default
  /// `userName == null` / `hasPromptedForName == false` and show the
  /// prompt again even though a name was already saved in a previous
  /// session; the load just hadn't finished yet.
  late final Future<void> initialLoad;

  WeatherProvider({
    required WeatherService weatherService,
    required LocationService locationService,
    NotificationService? notificationService,
  })  : _weatherService = weatherService,
        _locationService = locationService,
        _notificationService =
            notificationService ?? NotificationService.instance {
    initialLoad = Future.wait(
        [_loadFavorites(), _loadUserName(), _loadLanguagePreferences()]);
  }

  static const String _languagePrefsKey = 'app_language';
  static const String _languagePromptSeenPrefsKey = 'app_language_prompt_seen';

  String _languageCode = 'en';
  bool hasSelectedLanguage = false;

  String get languageCode => _languageCode;
  Locale get locale => Locale(_languageCode);

  Future<void> _loadLanguagePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _languageCode = prefs.getString(_languagePrefsKey) ?? 'en';
    hasSelectedLanguage = prefs.getBool(_languagePromptSeenPrefsKey) ?? false;
    notifyListeners();
  }

  Future<void> setAppLanguage(String code) async {
    final normalized = code.trim();
    if (normalized.isEmpty) return;

    _languageCode = normalized;
    hasSelectedLanguage = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languagePrefsKey, normalized);
    await prefs.setBool(_languagePromptSeenPrefsKey, true);
  }

  WeatherStatus status = WeatherStatus.initial;
  Weather? currentWeather;
  List<ForecastDay> forecast = [];

  /// The next ~24 hours of forecast at OpenWeatherMap's native 3-hour
  /// step (unlike [forecast], which is collapsed to one entry per day).
  List<ForecastDay> hourlyForecast = [];

  String? errorMessage;

  // --- Pull-to-refresh support ---
  // Remembers the last successful search so `refresh()` can repeat it
  // without the caller needing to pass the city/location again.
  WeatherSource _lastSource = WeatherSource.none;
  String? _lastCity;
  double? _lastLat;
  double? _lastLon;

  /// True while a pull-to-refresh is in flight. Unlike [status], this
  /// doesn't blank the screen — existing weather stays visible while
  /// the refresh spinner shows.
  bool isRefreshing = false;

  /// Set when a refresh fails, so the UI can show a small banner
  /// without discarding the weather still on screen. Cleared by
  /// [clearRefreshError] or the next successful fetch/refresh.
  String? refreshErrorMessage;

  /// Set when the user taps a day in the forecast list — the UI shows
  /// that day's conditions instead of live "today" data until this is
  /// cleared via [selectToday]. Reset to null on every fresh fetch,
  /// since a new location's forecast list makes any previous
  /// selection meaningless.
  ForecastDay? selectedDay;

  /// Whether the currently-displayed weather is live "today" data
  /// (true) or a tapped-on forecast day (false). The UI uses this to
  /// decide whether to show a ticking clock (only makes sense for
  /// "now") and whether to show a "back to today" control.
  bool get isViewingToday => selectedDay == null;

  /// Shows [day]'s forecast instead of live current weather.
  void selectDay(ForecastDay day) {
    selectedDay = day;
    notifyListeners();
  }

  /// Returns to showing live current weather.
  void selectToday() {
    selectedDay = null;
    notifyListeners();
  }

  /// Exposes the public proxy URL so screens (e.g. the radar map) can
  /// load weather tiles without putting the provider key in the app.
  String get weatherApiBaseUrl => _weatherService.apiBaseUrl;

  /// Fetches current weather + forecast for a searched city name.
  Future<void> fetchWeatherForCity(String cityName) async {
    if (cityName.trim().isEmpty) return;
    _lastSource = WeatherSource.city;
    _lastCity = cityName;
    _setLoading();

    try {
      final weather = await _weatherService.getWeatherByCity(cityName);
      final rawForecast = await _weatherService.getForecastByCity(cityName);
      _setLoaded(weather, rawForecast);
      unawaited(BackgroundWeatherService.recordForegroundSnapshot(weather));
    } on WeatherException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Something went wrong. Please try again.');
    }
  }

  /// Fetches current weather + forecast for an exact lat/lon — used
  /// when the user picks a city from search suggestions, where the
  /// coordinates are already known precisely (avoids the ambiguity of
  /// re-searching by name, e.g. two different "Springfield"s).
  Future<void> fetchWeatherForCoordinates(double lat, double lon) async {
    _lastSource = WeatherSource.coordinates;
    _lastLat = lat;
    _lastLon = lon;
    _setLoading();

    try {
      final weather = await _weatherService.getWeatherByLocation(lat, lon);
      final rawForecast = await _weatherService.getForecastByLocation(lat, lon);
      _setLoaded(weather, rawForecast);
      unawaited(BackgroundWeatherService.recordForegroundSnapshot(weather));
    } on WeatherException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Something went wrong. Please try again.');
    }
  }

  /// Looks up city name matches for search-as-you-type suggestions.
  /// Never throws — returns an empty list on failure, since this
  /// backs an autocomplete list, not a user-facing fetch.
  Future<List<CitySuggestion>> searchCitySuggestions(String query) {
    return _weatherService.searchCities(query);
  }

  // --- Starred cities ---

  static const String _favoritesPrefsKey = 'favorite_cities';

  /// Cities the user has starred. Loaded from disk on startup and
  /// kept in sync with [SharedPreferences] on every change.
  List<FavoriteCity> favorites = [];

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_favoritesPrefsKey);
    if (raw == null) return;

    try {
      final List decoded = jsonDecode(raw);
      favorites = decoded
          .map((e) => FavoriteCity.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      // Corrupted/old-format data — start fresh rather than crash.
      favorites = [];
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(favorites.map((f) => f.toJson()).toList());
    await prefs.setString(_favoritesPrefsKey, encoded);
  }

  /// Whether the currently-displayed weather's city is starred.
  bool get isCurrentCityFavorite {
    if (currentWeather == null) return false;
    final candidate = FavoriteCity(
      name: currentWeather!.cityName,
      country: currentWeather!.country,
      lat: currentWeather!.latitude,
      lon: currentWeather!.longitude,
    );
    return favorites.contains(candidate);
  }

  /// Stars or un-stars the currently-displayed city.
  void toggleCurrentCityFavorite() {
    if (currentWeather == null) return;

    final candidate = FavoriteCity(
      name: currentWeather!.cityName,
      country: currentWeather!.country,
      lat: currentWeather!.latitude,
      lon: currentWeather!.longitude,
    );

    if (favorites.contains(candidate)) {
      favorites.remove(candidate);
    } else {
      favorites.add(candidate);
    }

    notifyListeners();
    _saveFavorites();
  }

  void removeFavorite(FavoriteCity city) {
    favorites.remove(city);
    notifyListeners();
    _saveFavorites();
  }

  /// Fetches a lightweight weather snapshot for display in the
  /// favorites list — deliberately doesn't touch [currentWeather] or
  /// any of the "what's on screen" state, since this is just for
  /// showing a glance of each starred city, not switching to it.
  Future<Weather> fetchFavoriteSnapshot(FavoriteCity city) {
    return _weatherService.getWeatherByLocation(city.lat, city.lon);
  }

  // --- User's name (for the home screen greeting) ---

  static const String _userNamePrefsKey = 'user_name';
  static const String _hasPromptedNamePrefsKey = 'has_prompted_name';

  /// The name the user entered, or null if they haven't set one yet.
  String? userName;

  /// Whether the one-time first-launch name prompt has already been
  /// shown. Tracked separately from [userName] so skipping the
  /// prompt doesn't cause it to nag again on every subsequent launch.
  bool hasPromptedForName = false;

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    userName = prefs.getString(_userNamePrefsKey);
    hasPromptedForName = prefs.getBool(_hasPromptedNamePrefsKey) ?? false;
    notifyListeners();
  }

  /// Saves the user's name (from the first-launch prompt or the
  /// Settings screen — same storage either way).
  Future<void> setUserName(String name) async {
    final trimmed = name.trim();
    userName = trimmed.isEmpty ? null : trimmed;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (userName == null) {
      await prefs.remove(_userNamePrefsKey);
    } else {
      await prefs.setString(_userNamePrefsKey, userName!);
    }
  }

  /// Marks the first-launch prompt as shown, whether the user entered
  /// a name or skipped — either way, don't ask again automatically.
  Future<void> markNamePromptShown() async {
    hasPromptedForName = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasPromptedNamePrefsKey, true);
  }

  /// Fetches current weather + forecast for the device's current GPS location.
  Future<void> fetchWeatherForCurrentLocation() async {
    _lastSource = WeatherSource.location;
    _setLoading();

    try {
      final position = await _locationService.getCurrentPosition();
      final weather = await _weatherService.getWeatherByLocation(
        position.latitude,
        position.longitude,
      );
      final rawForecast = await _weatherService.getForecastByLocation(
        position.latitude,
        position.longitude,
      );
      _setLoaded(weather, rawForecast);
      unawaited(BackgroundWeatherService.recordForegroundSnapshot(weather));
    } on LocationException catch (e) {
      _setError(e.message);
    } on WeatherException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Something went wrong. Please try again.');
    }
  }

  /// Re-runs the last successful fetch (same city, or current location
  /// again). Used by pull-to-refresh. Unlike [fetchWeatherForCity] and
  /// [fetchWeatherForCurrentLocation], this does NOT flip [status] to
  /// `loading` — the existing weather stays on screen the whole time,
  /// only [isRefreshing] toggles, so the UI doesn't flash/blank out.
  Future<void> refresh() async {
    if (_lastSource == WeatherSource.none) return;

    // Captured before the fetch overwrites `currentWeather`, so we can
    // compare "before" vs "after" once the new data lands.
    final previousWeather = currentWeather;

    isRefreshing = true;
    refreshErrorMessage = null;
    notifyListeners();

    try {
      late final Weather weather;
      late final List<ForecastDay> rawForecast;

      if (_lastSource == WeatherSource.city && _lastCity != null) {
        weather = await _weatherService.getWeatherByCity(_lastCity!);
        rawForecast = await _weatherService.getForecastByCity(_lastCity!);
      } else if (_lastSource == WeatherSource.coordinates &&
          _lastLat != null &&
          _lastLon != null) {
        weather =
            await _weatherService.getWeatherByLocation(_lastLat!, _lastLon!);
        rawForecast =
            await _weatherService.getForecastByLocation(_lastLat!, _lastLon!);
      } else {
        final position = await _locationService.getCurrentPosition();
        weather = await _weatherService.getWeatherByLocation(
          position.latitude,
          position.longitude,
        );
        rawForecast = await _weatherService.getForecastByLocation(
          position.latitude,
          position.longitude,
        );
      }

      _setLoaded(weather, rawForecast);

      if (previousWeather != null) {
        _checkForSignificantChange(previousWeather, weather);
      }
      unawaited(BackgroundWeatherService.recordForegroundSnapshot(weather));
    } on LocationException catch (e) {
      _setRefreshError(e.message);
    } on WeatherException catch (e) {
      _setRefreshError(e.message);
    } catch (e) {
      _setRefreshError('Refresh failed. Showing last known weather.');
    }
  }

  /// Dismisses the refresh-error banner without affecting the
  /// weather data still shown on screen.
  void clearRefreshError() {
    refreshErrorMessage = null;
    notifyListeners();
  }

  void _setRefreshError(String message) {
    isRefreshing = false;
    refreshErrorMessage = message;
    notifyListeners();
  }

  void _setLoading() {
    status = WeatherStatus.loading;
    errorMessage = null;
    notifyListeners();
  }

  void _setLoaded(Weather weather, List<ForecastDay> rawForecast) {
    currentWeather = weather;
    forecast = groupForecastByDay(rawForecast);
    // OpenWeatherMap's forecast endpoint returns steps every 3 hours;
    // 8 of them covers the next 24 hours, which is the useful window
    // for an "hourly" strip (further out, day-level detail is enough).
    hourlyForecast = rawForecast.take(8).toList();
    // A new fetch means a new forecast list — any previously-selected
    // day belongs to the old data and no longer makes sense to show.
    selectedDay = null;
    status = WeatherStatus.loaded;
    isRefreshing = false;
    refreshErrorMessage = null;
    notifyListeners();

    // If this was a GPS-based fetch, remember the coordinates so the
    // background task (which can't request a fresh GPS fix without a
    // much heavier background-location permission) has a reasonable
    // "last known location" to check against instead.
    if (_lastSource == WeatherSource.location) {
      _persistLastKnownLocation(weather.latitude, weather.longitude);
    }
  }

  Future<void> _persistLastKnownLocation(double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('last_location_lat', lat);
    await prefs.setDouble('last_location_lon', lon);
  }

  void _setError(String message) {
    status = WeatherStatus.error;
    errorMessage = message;
    notifyListeners();
  }

  // --- Sudden weather-change notifications ---

  /// Compares the weather from before and after a refresh, and fires
  /// a local notification if [WeatherChangeDetector] considers it
  /// significant. The actual thresholds/rules live there, shared with
  /// the background task, so foreground and background checks can
  /// never quietly drift apart.
  void _checkForSignificantChange(Weather previous, Weather updated) {
    final changeDescription = WeatherChangeDetector.describeChange(
      previousTemp: previous.temperature,
      previousCondition: previous.mainCondition,
      newTemp: updated.temperature,
      newCondition: updated.mainCondition,
      newDescription: updated.description,
    );

    if (changeDescription == null) return;

    _notificationService.showWeatherAlert(
      title: AppStrings(_languageCode).weatherUpdateTitle(updated.cityName),
      body: AppStrings(_languageCode)
          .localizeChangeDescription(changeDescription),
    );
  }
}
