import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/forecast_day.dart';
import '../providers/weather_provider.dart';
import '../theme/app_theme.dart';
import '../theme/weather_icon.dart';
import '../localization/app_strings.dart';

class ForecastList extends StatelessWidget {
  final List<ForecastDay> forecast;
  const ForecastList({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) {
    if (forecast.isEmpty) return const SizedBox.shrink();
    final now = DateTime.now();
    final strings = AppStrings.of(context);
    final locale = strings.languageCode;
    final selectedDay = context.watch<WeatherProvider>().selectedDay;
    return SizedBox(
      height: 178,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: forecast.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final day = forecast[index];
          final isToday = day.dateTime.year == now.year && day.dateTime.month == now.month && day.dateTime.day == now.day;
          final selected = selectedDay?.dateTime == day.dateTime;
          return GestureDetector(
            onTap: () => isToday ? context.read<WeatherProvider>().selectToday() : context.read<WeatherProvider>().selectDay(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 86,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                gradient: isToday ? AppGradients.primaryButton : null,
                color: isToday ? null : Colors.white.withValues(alpha: .48),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: selected ? AppColors.violet : Colors.white.withValues(alpha: .58), width: selected ? 2 : 1),
                boxShadow: [BoxShadow(color: AppColors.violetDeep.withValues(alpha: isToday ? .22 : .08), blurRadius: 15, offset: const Offset(0, 7))],
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(isToday ? strings.today : DateFormat('EEE', locale).format(day.dateTime).toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isToday ? Colors.white : AppColors.violetDeep)),
                WeatherIcon(iconCode: day.iconCode, size: 42),
                Text('${day.tempMax.round()}°', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isToday ? Colors.white : AppColors.violetDark)),
                Text('${day.tempMin.round()}°', style: TextStyle(fontSize: 12, color: isToday ? Colors.white.withValues(alpha: .72) : AppColors.textMuted)),
                Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.water_drop_outlined, size: 11, color: isToday ? Colors.white : AppColors.violet), const SizedBox(width: 2), Text('${day.humidity}%', style: TextStyle(fontSize: 10, color: isToday ? Colors.white.withValues(alpha: .78) : AppColors.textMuted))]),
              ]),
            ),
          );
        },
      ),
    );
  }
}
