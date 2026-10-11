import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../theme/app_theme.dart';
import 'radar_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';
import '../localization/app_strings.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeatherProvider>();
    final weather = provider.currentWeather;
    final strings = AppStrings.of(context);
    return Drawer(
      width: 310,
      backgroundColor: AppColors.violetPale,
      child: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(gradient: AppGradients.primaryButton, borderRadius: BorderRadius.circular(AppRadius.xxl), boxShadow: [BoxShadow(color: AppColors.violetDeep.withValues(alpha: .2), blurRadius: 22, offset: const Offset(0, 10))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), shape: BoxShape.circle), child: const Icon(Icons.wb_sunny_rounded, color: AppColors.gold, size: 24)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(strings.appName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900))),
                ]),
                const SizedBox(height: 14),
                Text(weather?.cityName ?? strings.dailyForecast, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 3),
                Text(weather == null ? strings.stayPrepared : '${weather.temperature.round()}° • ${weather.description}', style: TextStyle(color: Colors.white.withValues(alpha: .75), fontSize: 12)),
              ]),
            ),
          ),
          Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 10), children: [
            _DrawerItem(icon: Icons.home_rounded, label: strings.home, selected: true, onTap: () => Navigator.pop(context)),
            _DrawerItem(icon: Icons.star_rounded, label: strings.starredCities, onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())); }),
            _DrawerItem(icon: Icons.radar_rounded, label: strings.radar, enabled: weather != null, onTap: weather == null ? null : () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => RadarScreen(latitude: weather.latitude, longitude: weather.longitude, cityName: weather.cityName, weatherApiBaseUrl: provider.weatherApiBaseUrl))); }),
            _DrawerItem(icon: Icons.notifications_active_outlined, label: strings.weatherAlerts, onTap: () => _showAlerts(context)),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10), child: Divider(color: Color(0x33705AD6))),
            _DrawerItem(icon: Icons.settings_rounded, label: strings.settings, onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())); }),
          ])),
          Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Text('${strings.appName} • ${strings.stayPreparedShort}', style: TextStyle(color: AppColors.textMuted.withValues(alpha: .8), fontSize: 11))),
        ])),
      ),
    );
  }

  void _showAlerts(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(AppStrings.of(context).weatherAlerts),
      content: Text(AppStrings.of(context).weatherAlertMessage),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.of(context).gotIt))],
    ));
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback? onTap; final bool selected; final bool enabled;
  const _DrawerItem({required this.icon, required this.label, this.onTap, this.selected = false, this.enabled = true});
  @override
  Widget build(BuildContext context) {
    final active = enabled ? AppColors.violetDeep : AppColors.textMuted.withValues(alpha: .4);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(color: selected ? Colors.white.withValues(alpha: .5) : Colors.transparent, borderRadius: BorderRadius.circular(16), child: InkWell(
        borderRadius: BorderRadius.circular(16), onTap: enabled ? onTap : null,
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13), child: Row(children: [
          Icon(icon, color: active, size: 21), const SizedBox(width: 14), Expanded(child: Text(label, style: TextStyle(color: active, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, fontSize: 14))), if (selected) const Icon(Icons.chevron_right_rounded, color: AppColors.violetDeep, size: 19),
        ])),
      )),
    );
  }
}
