import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/forecast_day.dart';
import '../theme/app_theme.dart';
import '../theme/weather_icon.dart';
import '../localization/app_strings.dart';

class HourlyForecastList extends StatelessWidget {
  final List<ForecastDay> hourly;
  const HourlyForecastList({super.key, required this.hourly});

  @override
  Widget build(BuildContext context) {
    if (hourly.isEmpty) return const SizedBox.shrink();
    final strings = AppStrings.of(context);
    final locale = strings.languageCode;
    return Column(children: [
      SizedBox(
        height: 118,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          itemCount: hourly.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final item = hourly[i];
            final selected = i == 0;
            return Container(
              width: 66,
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 5),
              decoration: BoxDecoration(
                gradient: selected ? AppGradients.primaryButton : null,
                color: selected ? null : Colors.white.withValues(alpha: .42),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: .55)),
                boxShadow: selected ? [BoxShadow(color: AppColors.violet.withValues(alpha: .20), blurRadius: 12, offset: const Offset(0, 6))] : null,
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(selected ? strings.now : DateFormat('h a', locale).format(item.dateTime), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: selected ? Colors.white : AppColors.violetDeep)),
                WeatherIcon(iconCode: item.iconCode, size: 38),
                Text('${item.temperature.round()}°', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: selected ? Colors.white : AppColors.violetDark)),
              ]),
            );
          },
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 150,
        child: LineChart(LineChartData(
          minY: _minTemp - _padding,
          maxY: _maxTemp + _padding,
          gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 2, getDrawingHorizontalLine: (_) => FlLine(color: AppColors.violetDeep.withValues(alpha: .07), strokeWidth: 1)),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, interval: 1, getTitlesWidget: (value, meta) {
              final i = value.round();
              if (i < 0 || i >= hourly.length) return const SizedBox.shrink();
              return Padding(padding: const EdgeInsets.only(top: 5), child: Text(DateFormat('H:mm', locale).format(hourly[i].dateTime), style: const TextStyle(fontSize: 9, color: AppColors.textMuted)));
            })),
          ),
          lineBarsData: [LineChartBarData(
            spots: [for (var i = 0; i < hourly.length; i++) FlSpot(i.toDouble(), hourly[i].temperature)],
            isCurved: true,
            curveSmoothness: .28,
            color: AppColors.violet,
            barWidth: 3,
            belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [AppColors.violet.withValues(alpha: .18), AppColors.violet.withValues(alpha: .01)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            dotData: FlDotData(show: true, getDotPainter: (spot, _, __, index) => FlDotCirclePainter(radius: index == 0 ? 5 : 3, color: AppColors.violet, strokeWidth: index == 0 ? 3 : 1, strokeColor: Colors.white)),
          )],
        )),
      ),
    ]);
  }

  double get _minTemp => hourly.map((e) => e.temperature).reduce((a, b) => a < b ? a : b);
  double get _maxTemp => hourly.map((e) => e.temperature).reduce((a, b) => a > b ? a : b);
  double get _padding => ((_maxTemp - _minTemp).abs() * .35).clamp(2, 5);
}
