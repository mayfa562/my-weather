import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/city_suggestion.dart';
import '../providers/weather_provider.dart';
import '../theme/app_theme.dart';
import '../theme/soft_card.dart';
import '../localization/app_strings.dart';

/// Full-screen city search, reached via the "+" button in the app
/// bar. Shows live suggestions as the user types (so they don't need
/// to know a city's exact name/spelling) via OpenWeatherMap's
/// Geocoding API. Picking a suggestion fetches weather for its exact
/// coordinates; pressing enter on free text falls back to a plain
/// name search.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<CitySuggestion> _suggestions = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();

    if (query.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }

    // Wait for a short pause in typing before hitting the API, so we
    // don't fire a request on every single keystroke.
    _debounce =
        Timer(const Duration(milliseconds: 400), () => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    setState(() => _isSearching = true);

    final results =
        await context.read<WeatherProvider>().searchCitySuggestions(query);

    if (!mounted) return;
    setState(() {
      _suggestions = results;
      _isSearching = false;
    });
  }

  void _selectSuggestion(CitySuggestion suggestion) {
    context
        .read<WeatherProvider>()
        .fetchWeatherForCoordinates(suggestion.lat, suggestion.lon);
    Navigator.of(context).pop();
  }

  void _searchFreeText() {
    final city = _controller.text.trim();
    if (city.isEmpty) return;
    context.read<WeatherProvider>().fetchWeatherForCity(city);
    Navigator.of(context).pop();
  }

  void _useCurrentLocation() {
    context.read<WeatherProvider>().fetchWeatherForCurrentLocation();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.violetPale,
      appBar: AppBar(title: Text(strings.searchCity)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                hintText: strings.searchCityHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onSubmitted: (_) => _searchFreeText(),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: ElevatedButton.icon(
                onPressed: _useCurrentLocation,
                icon: const Icon(Icons.my_location, size: 18),
                label: Text(strings.useCurrentLocation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.violet,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: AppColors.violetDeep.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl)),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_suggestions.isNotEmpty)
              Expanded(
                child: ListView.separated(
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final suggestion = _suggestions[index];
                    return SoftCard(
                      borderRadius: AppRadius.lg,
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        leading: const Icon(Icons.location_on_outlined,
                            color: AppColors.violetDeep),
                        title: Text(
                          suggestion.displayLabel,
                          style: const TextStyle(
                              color: AppColors.violetDeep,
                              fontWeight: FontWeight.w600),
                        ),
                        onTap: () => _selectSuggestion(suggestion),
                      ),
                    );
                  },
                ),
              )
            else if (_controller.text.trim().length >= 2 && !_isSearching)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: Text(
                  strings.noMatchingCities,
                  style: const TextStyle(color: AppColors.violetDeep, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
