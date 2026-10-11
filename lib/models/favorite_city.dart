/// A city the user has starred to keep track of, persisted locally
/// so it survives app restarts.
class FavoriteCity {
  final String name;
  final String country;
  final double lat;
  final double lon;

  FavoriteCity({
    required this.name,
    required this.country,
    required this.lat,
    required this.lon,
  });

  factory FavoriteCity.fromJson(Map<String, dynamic> json) {
    return FavoriteCity(
      name: json['name'] as String,
      country: json['country'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'country': country,
        'lat': lat,
        'lon': lon,
      };

  String get displayLabel => country.isEmpty ? name : '$name, $country';

  // Coordinates are rounded before comparing — the same city fetched
  // twice can come back with tiny floating-point differences (e.g.
  // 0.34750001 vs 0.3475), which would otherwise make it look like a
  // "different" location and break duplicate detection.
  @override
  bool operator ==(Object other) =>
      other is FavoriteCity &&
      lat.toStringAsFixed(2) == other.lat.toStringAsFixed(2) &&
      lon.toStringAsFixed(2) == other.lon.toStringAsFixed(2);

  @override
  int get hashCode => Object.hash(lat.toStringAsFixed(2), lon.toStringAsFixed(2));
}
