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
- Node.js 20+ and a Cloudflare account to deploy the API proxy

## Configure the API proxy

The OpenWeatherMap key belongs in the Cloudflare Worker secret, **not** in the
Flutter app or this repository. The proxy restricts upstream paths and request
parameters and rate-limits each Cloudflare client IP to 100 requests per minute.
The endpoint is still public: this rate limit is an abuse deterrent, not user
authentication or a guarantee against quota exhaustion. Monitor your
OpenWeatherMap usage and Cloudflare Worker analytics.
Wrangler currently labels Worker rate-limit bindings experimental; verify the
limit is active in Cloudflare after deployment.

If an earlier APK contained your OpenWeatherMap key, assume that key is
compromised: revoke it and create a new key before continuing. Removing it from
the new app cannot remove it from APKs that were already distributed.

1. Create a Cloudflare Worker and select `worker/` as its project directory, or
   deploy from a local clone using Wrangler:

   ```powershell
   cd worker
   npm install
   npx wrangler login
   ```

2. Add the provider key as an encrypted Worker secret and deploy:

   ```powershell
   npx wrangler secret put OPENWEATHER_API_KEY
   npm run deploy
   ```

   Enter the key only at Wrangler's prompt. Do not put it in `wrangler.toml`,
   source code, command history, or Flutter build arguments.
3. Copy the deployed Worker URL (for example,
   `https://my-weather-api.<your-account>.workers.dev`) and configure Flutter
   with that **public URL**, which is not a secret:

   ```sh
   flutter run --dart-define=WEATHER_API_BASE_URL=https://my-weather-api.<your-account>.workers.dev
   ```

To test the Worker locally, copy `worker/.dev.vars.example` to
`worker/.dev.vars`, enter a development API key there, and run `npm run dev`
from `worker/`. The `.dev.vars` file is ignored by Git.
`worker/wrangler.toml` configures a per-client-IP limit of 100 requests per
minute. The public Worker URL cannot authenticate app users; set appropriate
Cloudflare protections and billing/usage alerts before wider distribution.

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

## Sign an Android release

Create and securely back up a **new** upload keystore. Never commit the
keystore or its passwords. From `android/`, create the keystore with:

```sh
keytool -genkey -v -keystore app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Copy `android/key.properties.example` to `android/key.properties` and replace
the example values with the keystore path, alias, and passwords. Both local
files are ignored by Git. Keep a backup of this upload key: app updates signed
with a different key cannot replace an existing installation (unless Google
Play's app signing key-recovery process applies).

Set the public Worker URL, then build:

```sh
flutter build appbundle --release --dart-define=WEATHER_API_BASE_URL=https://my-weather-api.<your-account>.workers.dev
```

For a locally sideloaded APK, use `flutter build apk --release` with the same
`--dart-define`. Release builds now fail if the upload keystore is not
configured; the debug signing key is never used as a release fallback.
