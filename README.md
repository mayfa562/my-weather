# My Weather

A multilingual Flutter weather app with current conditions, forecasts, saved
cities, weather maps, and best-effort local weather-change notifications.

## Features

- Current weather and a five-day forecast for searched cities or your location
- Hourly forecast, saved cities, and weather radar layers
- English, Spanish, and French interface
- Local alerts for significant weather changes while the app is open, and
  best-effort periodic checks in the background on Android and iOS

Background work is controlled by the operating system. It may be delayed or
skipped due to battery, network, or platform scheduling policies; it is not a
real-time severe-weather warning service.

## Requirements

- Flutter SDK
- An OpenWeatherMap API key for current weather and forecast data

## Run locally

1. Clone this repository and change into the project directory.
2. Create the local environment file from the example:

   ```sh
   cp .env.example .env
   ```

   On Windows PowerShell, use `Copy-Item .env.example .env`.
3. Put your OpenWeatherMap key in `.env`:

   ```text
   OPENWEATHER_API_KEY=your_api_key_here
   ```
4. Fetch dependencies and run the app:

   ```sh
   flutter pub get
   flutter run
   ```

The `.env` file is intentionally ignored by Git. Never commit a real API key.
Because this is a client app, a key bundled into a release can be extracted;
use an appropriately restricted key and monitor its usage.

## Notifications

Allow notifications when prompted (or enable them in the phone's app settings).
The app only alerts on a detected significant change, such as a temperature
swing of at least 5°C or newly occurring rain, snow, or thunderstorm conditions.
The first successful reading establishes the comparison baseline, so it does
not immediately generate an alert.

Background checks use the last location loaded by the app and saved cities.
Android WorkManager and iOS background scheduling do not guarantee an exact
check interval or delivery time. See
[BACKGROUND_ALERTS_SETUP.md](BACKGROUND_ALERTS_SETUP.md) for platform details.

## Build an Android APK

With `.env` configured, build a release APK with:

```sh
flutter build apk --release
```

The APK is generated under `build/app/outputs/flutter-apk/` and is not tracked
in this source repository.
