import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../theme/app_theme.dart';
import '../localization/app_strings.dart';

/// "Good morning, Fahad ☀️" — shown above the weather card once a
/// name has been set. Renders nothing at all if no name is on file
/// yet, so there's no awkward "Good morning, " with a blank where a
/// name should be.
class GreetingBanner extends StatelessWidget {
  const GreetingBanner({super.key});

  /// Same family grouping as [WeatherIcon] (first two digits of
  /// OpenWeatherMap's icon code), mapped to an emoji instead of an
  /// image asset.
  static String? _emojiForIconCode(String? iconCode) {
    if (iconCode == null || iconCode.length < 2) return null;
    final isNight = iconCode.endsWith('n');

    switch (iconCode.substring(0, 2)) {
      case '01':
        return isNight ? '🌙' : '☀️';
      case '02':
      case '03':
        return '⛅';
      case '04':
        return '☁️';
      case '09':
      case '10':
        return '🌧️';
      case '11':
        return '⛈️';
      case '13':
        return '❄️';
      case '50':
        return '🌫️';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeatherProvider>();
    final name = provider.userName;
    if (name == null || name.isEmpty) return const SizedBox.shrink();

    final strings = AppStrings.of(context);
    final greeting = strings.greetingForHour(DateTime.now().hour, name);
    final emoji = _emojiForIconCode(provider.currentWeather?.iconCode);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SizedBox(
        width: double.infinity,
        child: Text(
          emoji != null ? '$greeting $emoji' : greeting,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.violetDeep,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
