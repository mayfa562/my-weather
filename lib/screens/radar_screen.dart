import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';
import '../localization/app_strings.dart';

/// Which OpenWeatherMap map layer to overlay on the base map. These
/// tile layers are included in the same free API tier as the current
/// weather / forecast endpoints — no separate signup needed.
/// See: https://openweathermap.org/api/weathermaps
enum RadarLayer {
  precipitation(
    'precipitation_new',
    'Precipitation',
    Icons.grain,
    [
      Color(0x00E1C864),
      Color(0xFF7878C6),
      Color(0xFF3232C8),
      Color(0xFF14145A)
    ],
    'Light',
    'Heavy',
  ),
  clouds(
    'clouds_new',
    'Clouds',
    Icons.cloud_outlined,
    [Color(0x00FFFFFF), Color(0xFFDDDDDD), Color(0xFF888888)],
    'Clear',
    'Overcast',
  ),
  temperature(
    'temp_new',
    'Temperature',
    Icons.thermostat,
    [
      Color(0xFF8216A0),
      Color(0xFF208CEC),
      Color(0xFF23DDDD),
      Color(0xFFFFF028),
      Color(0xFFFC8014)
    ],
    'Cold',
    'Hot',
  ),
  wind(
    'wind_new',
    'Wind',
    Icons.air,
    [Color(0xFF66C266), Color(0xFFEEE066), Color(0xFFE05C5C)],
    'Calm',
    'Strong',
  );

  final String tileId;
  final String label;
  final IconData icon;

  /// Approximate colors matching OpenWeatherMap's documented default
  /// palette for this layer — used to draw a small legend gradient so
  /// the tile colors on the map actually mean something to whoever's
  /// looking at it, instead of being an unexplained color wash.
  final List<Color> legendColors;
  final String legendLowLabel;
  final String legendHighLabel;

  const RadarLayer(
    this.tileId,
    this.label,
    this.icon,
    this.legendColors,
    this.legendLowLabel,
    this.legendHighLabel,
  );
}

/// Shows a map centered on the current weather location, with a
/// switchable OpenWeatherMap layer (precipitation, clouds, etc.)
/// overlaid on an OpenStreetMap base.
///
/// This is real tile data from OpenWeatherMap's map layers, but it's
/// worth being upfront about what it isn't: OpenWeatherMap's free
/// tier doesn't provide live Doppler radar imagery the way a
/// dedicated radar service does — these are model-derived overlays
/// (precipitation/cloud/temperature/wind), updated periodically
/// rather than in true real time.
class RadarScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String cityName;
  final String weatherApiBaseUrl;

  const RadarScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.cityName,
    required this.weatherApiBaseUrl,
  });

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  RadarLayer _selectedLayer = RadarLayer.precipitation;

  @override
  Widget build(BuildContext context) {
    final center = LatLng(widget.latitude, widget.longitude);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
          title: Text('${AppStrings.of(context).radar} · ${widget.cityName}')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 7,
              minZoom: 3,
              maxZoom: 12,
            ),
            children: [
              // Base map. OpenStreetMap's public tile servers require
              // a descriptive User-Agent (userAgentPackageName below)
              // or requests can get rate-limited/blocked.
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.weather_app',
              ),
              // Weather overlay from OpenWeatherMap, switchable below.
              // Wrapped in Opacity — without this it renders fully
              // opaque and can completely hide the base map wherever
              // there's data, making it hard to tell where the
              // weather actually is relative to geography.
              Opacity(
                opacity: 0.65,
                child: TileLayer(
                  urlTemplate:
                      '${widget.weatherApiBaseUrl.replaceFirst(RegExp(r'/+$'), '')}/map/${_selectedLayer.tileId}/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.weather_app',
                ),
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: center,
                    width: 36,
                    height: 36,
                    child: Icon(
                      Icons.location_on,
                      color: colorScheme.primary,
                      size: 36,
                    ),
                  ),
                ],
              ),
              // Required attribution for using OpenStreetMap's tiles.
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                  TextSourceAttribution('Weather layer © OpenWeatherMap'),
                ],
              ),
            ],
          ),
          Positioned(
            top: AppSpacing.md,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: _LayerSelector(
              selected: _selectedLayer,
              onSelect: (layer) => setState(() => _selectedLayer = layer),
            ),
          ),
          Positioned(
            bottom: AppSpacing.md,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: _LayerLegend(layer: _selectedLayer),
          ),
        ],
      ),
    );
  }
}

/// A small color-scale key explaining what the overlay's colors mean
/// for the currently selected layer — raw tile colors alone don't
/// tell you whether blue means "light rain" or "heavy rain" without
/// this.
class _LayerLegend extends StatelessWidget {
  final RadarLayer layer;

  const _LayerLegend({required this.layer});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            strings.radarLayerLabel(layer),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.violetDeep,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            strings.radarLegendLow(layer),
            style: TextStyle(
                fontSize: 10,
                color: AppColors.violetDeep.withValues(alpha: 0.6)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(colors: layer.legendColors),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            strings.radarLegendHigh(layer),
            style: TextStyle(
                fontSize: 10,
                color: AppColors.violetDeep.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

/// A horizontal row of pill buttons for switching the overlay layer.
class _LayerSelector extends StatelessWidget {
  final RadarLayer selected;
  final ValueChanged<RadarLayer> onSelect;

  const _LayerSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: RadarLayer.values.map((layer) {
          final isSelected = layer == selected;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: () => onSelect(layer),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  children: [
                    Icon(
                      layer.icon,
                      size: 18,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      layer.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
