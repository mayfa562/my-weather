import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/favorite_city.dart';
import '../models/weather.dart';
import '../providers/weather_provider.dart';
import '../theme/app_theme.dart';
import '../theme/glass_card.dart';
import '../theme/weather_icon.dart';
import '../localization/app_strings.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final Map<FavoriteCity, Weather?> _snapshots = {};
  final Set<FavoriteCity> _failed = {};

  @override
  void initState() { super.initState(); _loadSnapshots(); }

  void _loadSnapshots() {
    final provider = context.read<WeatherProvider>();
    for (final city in provider.favorites) {
      provider.fetchFavoriteSnapshot(city).then((weather) {
        if (mounted) setState(() => _snapshots[city] = weather);
      }).catchError((_) {
        if (mounted) setState(() => _failed.add(city));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<WeatherProvider>().favorites;
    final strings = AppStrings.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(8, 8, 16, 12), child: Row(children: [
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded, color: AppColors.violetDeep)),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(strings.savedCities, style: const TextStyle(color: AppColors.violetDark, fontSize: 23, fontWeight: FontWeight.w900)), Text(strings.savedLocationsAtGlance, style: const TextStyle(color: AppColors.textMuted, fontSize: 11))])),
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .55), shape: BoxShape.circle), child: Text('${favorites.length}', style: const TextStyle(color: AppColors.violetDeep, fontWeight: FontWeight.w800))),
          ])),
          Expanded(child: favorites.isEmpty
            ? Center(child: Padding(padding: const EdgeInsets.all(AppSpacing.xl), child: GlassCard(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.star_border_rounded, size: 48, color: AppColors.violet), const SizedBox(height: 12), Text(strings.noStarredCities, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.violetDark, fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text(strings.starCityHint, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted, fontSize: 12))]))))
            : ListView.separated(padding: const EdgeInsets.fromLTRB(AppSpacing.md, 4, AppSpacing.md, AppSpacing.xl), itemCount: favorites.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (context, index) {
                final city = favorites[index]; final snapshot = _snapshots[city]; final failed = _failed.contains(city);
                return GlassCard(padding: EdgeInsets.zero, borderRadius: AppRadius.xxl, child: InkWell(borderRadius: BorderRadius.circular(AppRadius.xxl), onTap: () { context.read<WeatherProvider>().fetchWeatherForCoordinates(city.lat, city.lon); Navigator.pop(context); }, child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [
                  Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.violet.withValues(alpha: .10), shape: BoxShape.circle), child: snapshot == null ? const Icon(Icons.location_city_rounded, color: AppColors.violetDeep) : WeatherIcon(iconCode: snapshot.iconCode, size: 48)),
                  const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(city.displayLabel, style: const TextStyle(color: AppColors.violetDark, fontSize: 16, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(failed ? strings.couldntLoad : snapshot == null ? strings.updatingWeather : strings.weatherDescription(snapshot.description), style: const TextStyle(color: AppColors.textMuted, fontSize: 11))])),
                  if (snapshot != null) Text('${snapshot.temperature.round()}°', style: const TextStyle(color: AppColors.violetDeep, fontSize: 21, fontWeight: FontWeight.w900)),
                  IconButton(onPressed: () => context.read<WeatherProvider>().removeFavorite(city), icon: const Icon(Icons.star_rounded, color: AppColors.gold)),
                ]))));
              })),
        ])),
      ),
    );
  }
}
