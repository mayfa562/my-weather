import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../theme/app_theme.dart';
import '../theme/glass_card.dart';
import '../localization/app_strings.dart';
import 'radar_screen.dart';
import 'favorites_screen.dart';

class WeatherToolsScreen extends StatelessWidget {
  const WeatherToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<WeatherProvider>();
    final s = AppStrings.of(context);
    final w = p.currentWeather;
    return Scaffold(
      appBar: AppBar(title: Text(s.weatherTools)),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
          GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.weatherTools, style: const TextStyle(color: AppColors.violetDark, fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(s.weatherToolsSubtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ])),
          const SizedBox(height: AppSpacing.md),
          _Tool(context, icon: Icons.radar_rounded, title: s.liveRadar, subtitle: s.liveRadarSubtitle, enabled: w != null, onTap: w == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => RadarScreen(latitude: w.latitude, longitude: w.longitude, cityName: w.cityName, apiKey: p.apiKey)))),
          const SizedBox(height: AppSpacing.sm),
          _Tool(context, icon: Icons.star_rounded, title: s.savedCities, subtitle: s.savedLocationsCount(p.favorites.length), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()))),
          const SizedBox(height: AppSpacing.sm),
          _Tool(context, icon: Icons.notifications_active_outlined, title: s.weatherAlerts, subtitle: s.significantChanges, onTap: () => _showAlerts(context, s)),
        ]),
      ),
    );
  }

  void _showAlerts(BuildContext context, AppStrings s) {
    showDialog(context: context, builder: (_) => AlertDialog(title: Text(s.weatherAlerts), content: Text(s.weatherAlertMessage), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(s.gotIt))]));
  }
}

class _Tool extends StatelessWidget {
  final BuildContext context;
  final IconData icon; final String title, subtitle; final bool enabled; final VoidCallback? onTap;
  const _Tool(this.context, {required this.icon, required this.title, required this.subtitle, this.enabled = true, this.onTap});
  @override Widget build(BuildContext context) => GlassCard(padding: EdgeInsets.zero, child: InkWell(onTap: enabled ? onTap : null, borderRadius: BorderRadius.circular(AppRadius.xxl), child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.violet.withValues(alpha: .12), shape: BoxShape.circle), child: Icon(icon, color: enabled ? AppColors.violetDeep : AppColors.textMuted)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: AppColors.violetDark, fontWeight: FontWeight.w800, fontSize: 15)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11))])), const Icon(Icons.chevron_right_rounded, color: AppColors.violetDeep)]))));
}
