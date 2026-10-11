/// A single city match from OpenWeatherMap's Geocoding API — used to
/// power search suggestions so the user can pick from real matches
/// instead of needing to know the exact spelling/name of a city.
class CitySuggestion {
  final String name;
  final String? state;
  final String country;
  final double lat;
  final double lon;

  CitySuggestion({
    required this.name,
    required this.state,
    required this.country,
    required this.lat,
    required this.lon,
  });

  factory CitySuggestion.fromJson(Map<String, dynamic> json) {
    return CitySuggestion(
      name: json['name'] as String,
      state: json['state'] as String?,
      country: json['country'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
    );
  }

  /// A human-friendly label disambiguating cities with the same name
  /// in different places, e.g. "Springfield, Illinois, US".
  String get displayLabel {
    final parts = [name, if (state != null && state!.isNotEmpty) state!, country];
    return parts.join(', ');
  }
}
