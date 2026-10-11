/// Represents one 3-hour forecast entry from OpenWeatherMap's
/// "5 Day / 3 Hour Forecast" endpoint. The provider groups these
/// into daily buckets for display.
class ForecastDay {
  final DateTime dateTime;
  final double temperature;
  final double tempMin;
  final double tempMax;
  final int humidity;
  final double windSpeed;
  final String mainCondition;
  final String description;
  final String iconCode;

  ForecastDay({
    required this.dateTime,
    required this.temperature,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.windSpeed,
    required this.mainCondition,
    required this.description,
    required this.iconCode,
  });

  factory ForecastDay.fromJson(Map<String, dynamic> json) {
    return ForecastDay(
      dateTime: DateTime.fromMillisecondsSinceEpoch(
        (json['dt'] as int) * 1000,
      ),
      temperature: (json['main']['temp'] as num).toDouble(),
      tempMin: (json['main']['temp_min'] as num).toDouble(),
      tempMax: (json['main']['temp_max'] as num).toDouble(),
      humidity: json['main']['humidity'] as int,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      mainCondition: json['weather'][0]['main'] as String,
      description: json['weather'][0]['description'] as String,
      iconCode: json['weather'][0]['icon'] as String,
    );
  }

  String get iconUrl => 'https://openweathermap.org/img/wn/$iconCode@2x.png';
}
