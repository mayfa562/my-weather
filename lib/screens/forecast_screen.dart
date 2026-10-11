import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/weather_provider.dart';
import '../theme/app_theme.dart';
import '../theme/glass_card.dart';
import '../theme/weather_icon.dart';
import '../localization/app_strings.dart';

class ForecastScreen extends StatelessWidget {
  const ForecastScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<WeatherProvider>();
    final s = AppStrings.of(context);
    final weather = p.currentWeather;
    final locale = s.languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(s.fiveDayForecast)),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 28), children: [
          GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.fiveDayForecast, style: const TextStyle(color: AppColors.violetDark, fontSize: 24, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(weather?.cityName ?? s.dailyOutlook, style: const TextStyle(color: AppColors.textMuted, fontSize: 12))])),
          const SizedBox(height: 14),
          ...p.forecast.map((day) {
            final now = DateTime.now();
            final today = day.dateTime.year == now.year && day.dateTime.month == now.month && day.dateTime.day == now.day;
            return Padding(padding: const EdgeInsets.only(bottom: 10), child: GlassCard(padding: const EdgeInsets.all(14), child: Column(children: [
              Row(children: [
                Container(width: 66, height: 66, decoration: BoxDecoration(gradient: today ? AppGradients.primaryButton : null, color: today ? null : Colors.white.withValues(alpha: .4), borderRadius: BorderRadius.circular(18)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(today ? s.today : DateFormat('EEE', locale).format(day.dateTime).toUpperCase(), style: TextStyle(color: today ? Colors.white : AppColors.violetDeep, fontSize: 10, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(DateFormat('d MMM', locale).format(day.dateTime), style: TextStyle(color: today ? Colors.white.withValues(alpha: .8) : AppColors.textMuted, fontSize: 9))])),
                const SizedBox(width: 13), WeatherIcon(iconCode: day.iconCode, size: 64), const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.weatherDescription(day.description), style: const TextStyle(color: AppColors.violetDark, fontWeight: FontWeight.w800, fontSize: 15)), const SizedBox(height: 4), Text(s.highLow(day.tempMax.round(), day.tempMin.round()), style: const TextStyle(color: AppColors.textMuted, fontSize: 11))])),
              ]),
              const SizedBox(height: 14),
              Row(children: [Expanded(child: _Metric(icon: Icons.water_drop_outlined, label: s.humidity, value: '${day.humidity}%')), Expanded(child: _Metric(icon: Icons.air_rounded, label: s.wind, value: '${day.windSpeed.round()} km/h')), Expanded(child: _Metric(icon: Icons.thermostat_rounded, label: s.average, value: '${day.temperature.round()}°'))]),
            ])));
          }),
        ]),
      ),
    );
  }
}
class _Metric extends StatelessWidget { final IconData icon; final String label, value; const _Metric({required this.icon, required this.label, required this.value}); @override Widget build(BuildContext context) => Column(children: [Icon(icon, color: AppColors.violet, size: 18), const SizedBox(height: 4), Text(value, style: const TextStyle(color: AppColors.violetDeep, fontWeight: FontWeight.w800, fontSize: 12)), Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 9))]); }
