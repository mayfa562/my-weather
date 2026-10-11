import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/weather_provider.dart';
import '../theme/app_theme.dart';
import '../theme/glass_card.dart';
import '../theme/weather_icon.dart';
import '../localization/app_strings.dart';

class CurrentWeatherCard extends StatefulWidget {
  const CurrentWeatherCard({super.key});
  @override
  State<CurrentWeatherCard> createState() => _CurrentWeatherCardState();
}

class _CurrentWeatherCardState extends State<CurrentWeatherCard> {
  late DateTime _now;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeatherProvider>();
    final strings = AppStrings.of(context);
    final weather = provider.currentWeather!;
    final selected = provider.selectedDay;
    final today = selected == null;
    final temperature = today ? weather.temperature : selected.temperature;
    final humidity = today ? weather.humidity : selected.humidity;
    final wind = today ? weather.windSpeed : selected.windSpeed;
    final description = today ? weather.description : selected.description;
    final iconCode = today ? weather.iconCode : selected.iconCode;
    final locale = strings.languageCode;

    return GlassCard(
      strong: true,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      child: Column(children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.violet.withValues(alpha: .10),
                  shape: BoxShape.circle),
              child: const Icon(Icons.location_on_rounded,
                  color: AppColors.violetDeep, size: 20)),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(weather.cityName,
                    style: const TextStyle(
                        color: AppColors.violetDark,
                        fontSize: 19,
                        fontWeight: FontWeight.w800)),
                Text(
                    today
                        ? DateFormat('EEE, d MMM • h:mm a', locale).format(_now)
                        : DateFormat('EEEE, d MMMM', locale)
                            .format(selected.dateTime),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ])),
          IconButton(
              tooltip: strings.useMyLocation,
              onPressed: () => provider.fetchWeatherForCurrentLocation(),
              icon: const Icon(Icons.my_location_rounded,
                  color: AppColors.violetDeep)),
          IconButton(
              tooltip: strings.saveCity,
              onPressed: () => provider.toggleCurrentCityFavorite(),
              icon: Icon(
                  provider.isCurrentCityFavorite
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: provider.isCurrentCityFavorite
                      ? AppColors.gold
                      : AppColors.violetDeep)),
        ]),
        if (!today)
          Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                  onPressed: provider.selectToday,
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: Text(strings.backToToday))),
        const SizedBox(height: 4),
        LayoutBuilder(builder: (context, constraints) {
          final heroWidth = constraints.maxWidth.clamp(280.0, 450.0).toDouble();
          // Deliberately large so the illustration has the same visual
          // importance as the oversized temperature in the inspiration.
          return SizedBox(
            width: heroWidth,
            height: 174,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Transform.scale(
                      scaleX: 1.25,
                      scaleY: 1.45,
                      alignment: Alignment.centerLeft,
                      child: Stack(
                        children: [
                          Text(
                            '${temperature.round()}°',
                            style: TextStyle(
                              fontSize: 140,
                              height: .88,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -6,
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 2
                                ..color = const Color(0x99FFFFFF),
                            ),
                          ),
                          Text(
                            '${temperature.round()}°',
                            style: TextStyle(
                              fontSize: 140,
                              height: .88,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -6,
                              foreground: Paint()
                                ..shader = const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFFF7F4FF),
                                    Color(0xFFCBB9FF),
                                    Color(0xFF7B4BE5),
                                    Color(0xFF4520A8),
                                  ],
                                ).createShader(
                                  const Rect.fromLTWH(0, 0, 400, 140),
                                ),
                              shadows: const [
                                Shadow(
                                  color: Color(0x556B3BE8),
                                  blurRadius: 18,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: constraints.maxWidth < 360 ? 35 : 25,
                  bottom: -22,
                  child: WeatherIcon(
                    iconCode: iconCode,
                    size: constraints.maxWidth < 360 ? 165 : 205,
                    hero: true,
                  ),
                ),
              ],
            ),
          );
        }),
        Transform.translate(
            offset: const Offset(0, -4),
            child: Text(strings.weatherDescription(description),
                style: const TextStyle(
                    color: AppColors.violetDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w800))),
        const SizedBox(height: 6),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
                color: AppColors.violet.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(30)),
            child: Text(
                '${strings.feelsLike} ${today ? weather.feelsLike.round() : selected.temperature.round()}°',
                style: const TextStyle(
                    color: AppColors.violetDeep,
                    fontWeight: FontWeight.w700,
                    fontSize: 12))),
        const SizedBox(height: AppSpacing.lg),
        Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 6),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .38),
                borderRadius: BorderRadius.circular(AppRadius.xxl)),
            child: Row(children: [
              Expanded(
                  child: _InfoStat(
                      icon: Icons.water_drop_outlined,
                      label: strings.humidity,
                      value: '$humidity%')),
              _StatDivider(),
              Expanded(
                  child: _InfoStat(
                      icon: Icons.air_rounded,
                      label: strings.windSpeed,
                      value: '${wind.round()} km/h')),
              _StatDivider(),
              Expanded(
                  child: _InfoStat(
                      icon: Icons.thermostat_rounded,
                      label: strings.temperatureRange,
                      value:
                          '${weather.tempMin.round()}° / ${weather.tempMax.round()}°')),
            ])),
      ]),
    );
  }
}

class _InfoStat extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoStat(
      {required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(children: [
        Icon(icon, color: AppColors.violet, size: 20),
        const SizedBox(height: 6),
        Text(value,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.violetDeep,
                fontWeight: FontWeight.w800,
                fontSize: 12)),
        const SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 9))
      ]);
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 1, height: 38, color: AppColors.violetDeep.withValues(alpha: .12));
}
