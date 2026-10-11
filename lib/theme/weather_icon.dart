import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Branded animated weather artwork using the Meteocons Lottie set.
/// The first two digits of an OpenWeatherMap icon code identify the
/// condition family and the d/n suffix selects day/night artwork.
class WeatherIcon extends StatelessWidget {
  final String iconCode;
  final double size;
  final bool hero;

  const WeatherIcon({
    super.key,
    required this.iconCode,
    this.size = 64,
    this.hero = false,
  });

  static String _assetFor(String code) {
    final family = code.length >= 2 ? code.substring(0, 2) : '01';
    final night = code.endsWith('n');

    return switch (family) {
      // 01 = clear sky
      '01' => night
          ? 'assets/weather_icons/clear_night.json'
          : 'assets/weather_icons/clear_day.json',

      // 02 = few clouds / partly cloudy
      '02' => night
          ? 'assets/weather_icons/partly_cloudy_night.json'
          : 'assets/weather_icons/partly_cloudy_day.json',

      // 03 = scattered clouds — use the dedicated cloudy artwork,
      // rather than treating it as partly cloudy.
      '03' => 'assets/weather_icons/cloudy.json',

      // 04 = broken/overcast cloud cover
      '04' => night
          ? 'assets/weather_icons/overcast_night.json'
          : 'assets/weather_icons/overcast_day.json',

      // 09 = shower rain. Rain is a better semantic match than drizzle.
      '09' => 'assets/weather_icons/rain.json',

      // 10 = rain
      '10' => 'assets/weather_icons/rain.json',

      // 11 = thunderstorm
      '11' => night
          ? 'assets/weather_icons/thunderstorms_night.json'
          : 'assets/weather_icons/thunderstorms_day.json',

      // 13 = snow
      '13' => 'assets/weather_icons/snow.json',

      // 50 = mist/fog/atmosphere
      '50' => night
          ? 'assets/weather_icons/fog_night.json'
          : 'assets/weather_icons/fog_day.json',

      _ => night
          ? 'assets/weather_icons/clear_night.json'
          : 'assets/weather_icons/clear_day.json',
    };
  }

  @override
  Widget build(BuildContext context) {
    final shadowBlur = hero ? size * .18 : size * .12;
    final shadowSpread = hero ? size * .015 : size * .01;
    final shadowOpacity = hero ? .18 : .14;

    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // A soft circular shadow/halo makes the transparent artwork
            // remain distinct against the glass cards and gradient.
            Container(
              width: size * .70,
              height: size * .70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: shadowOpacity),
                    blurRadius: shadowBlur,
                    spreadRadius: shadowSpread,
                    offset: Offset(0, hero ? size * .055 : size * .035),
                  ),
                ],
              ),
            ),
            Lottie.asset(
              _assetFor(iconCode),
              width: size,
              height: size,
              fit: BoxFit.contain,
              repeat: true,
              animate: true,
              errorBuilder: (_, __, ___) => Icon(
                Icons.cloud_rounded,
                size: size * .65,
                color: const Color(0xFF6650D9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
