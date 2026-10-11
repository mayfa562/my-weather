/// Decides whether a weather change is "sudden" enough to notify
/// about, and builds the notification text. Pulled out as a standalone
/// pure-logic class (no dependency on Weather/Provider) so the exact
/// same rules apply whether the check happens during a normal
/// foreground refresh or inside the background task's separate
/// isolate — those two contexts can't easily share a class instance,
/// but they can both call these static methods.
class WeatherChangeDetector {
  WeatherChangeDetector._();

  /// A temperature swing of this many °C between checks counts as
  /// "sudden".
  static const double significantTempChangeCelsius = 5.0;

  /// Conditions worth alerting on if they *newly* appear. Ordinary
  /// conditions like "Clear" or "Clouds" don't trigger an alert on
  /// their own.
  static const Set<String> alertWorthyConditions = {
    'Thunderstorm',
    'Tornado',
    'Squall',
    'Extreme',
    'Snow',
    'Rain',
    'Drizzle',
  };

  /// Returns a human-readable description of the change if it's
  /// significant, or null if nothing notable happened.
  static String? describeChange({
    required double previousTemp,
    required String previousCondition,
    required double newTemp,
    required String newCondition,
    required String newDescription,
  }) {
    final tempDelta = (newTemp - previousTemp).abs();
    final tempChanged = tempDelta >= significantTempChangeCelsius;

    final conditionChanged =
        newCondition != previousCondition && alertWorthyConditions.contains(newCondition);

    if (!tempChanged && !conditionChanged) return null;

    final parts = <String>[];
    if (tempChanged) {
      final direction = newTemp > previousTemp ? 'jumped to' : 'dropped to';
      parts.add('Temperature $direction ${newTemp.round()}°C');
    }
    if (conditionChanged) {
      parts.add('Now $newDescription');
    }

    return parts.join('. ');
  }
}
