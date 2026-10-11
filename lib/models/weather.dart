/// Represents current weather conditions for a single location.
class Weather {
  final String cityName;
  final String country;
  final double latitude;
  final double longitude;
  final double temperature;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final int humidity;
  final double windSpeed;
  final String mainCondition; // e.g. "Clouds", "Rain"
  final String description;   // e.g. "scattered clouds"
  final String iconCode;      // e.g. "04d" -> used to build icon URL
  final DateTime dateTime;

  Weather({
    required this.cityName,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.temperature,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.windSpeed,
    required this.mainCondition,
    required this.description,
    required this.iconCode,
    required this.dateTime,
  });

  /// Builds a [Weather] from OpenWeatherMap's "Current Weather" endpoint JSON.
  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      cityName: json['name'] as String? ?? 'Unknown',
      country: json['sys']?['country'] as String? ?? '',
      latitude: (json['coord']['lat'] as num).toDouble(),
      longitude: (json['coord']['lon'] as num).toDouble(),
      temperature: (json['main']['temp'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      tempMin: (json['main']['temp_min'] as num).toDouble(),
      tempMax: (json['main']['temp_max'] as num).toDouble(),
      humidity: json['main']['humidity'] as int,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      mainCondition: json['weather'][0]['main'] as String,
      description: json['weather'][0]['description'] as String,
      iconCode: json['weather'][0]['icon'] as String,
      dateTime: DateTime.fromMillisecondsSinceEpoch(
        (json['dt'] as int) * 1000,
      ),
    );
  }

  /// Full URL for the weather icon PNG served by OpenWeatherMap.
  String get iconUrl => 'https://openweathermap.org/img/wn/$iconCode@2x.png';
}
