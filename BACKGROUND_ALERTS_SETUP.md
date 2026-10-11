# My weather — cross-platform background weather alerts

This version uses the Flutter `workmanager` package for **Android and iOS** background execution, together with `flutter_local_notifications` for local notifications.

## Android

Android uses WorkManager. The operating system controls the exact execution time; periodic work cannot be guaranteed to run at an exact minute. The minimum periodic interval is normally 15 minutes.

## iOS

iOS also supports the background callback, but Apple controls when background work runs. It is **not** a guaranteed 15-minute timer. The iOS Runner must register the WorkManager BGProcessing task and permit its identifier in `Info.plist`.

Add the following to `ios/Runner/Info.plist` inside the main `<dict>`:

```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>be.tramckrijte.workmanager.backgroundtask</string>
</array>
```

Add the Background Modes capability in Xcode for the Runner target and enable **Background processing**.

In `ios/Runner/AppDelegate.swift`, register the WorkManager processing task before returning from `didFinishLaunchingWithOptions`:

```swift
import UIKit
import Flutter
import workmanager

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    WorkmanagerPlugin.registerBGProcessingTask(withIdentifier: "be.tramckrijte.workmanager.backgroundtask")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

If your installed `workmanager` version exposes a different iOS registration method, use the method shown by that exact package version; the source project currently uses `workmanager: ^0.9.0`.

## Important platform limitation

This gives **best-effort background alerts on Android and iOS**, not an exact always-on timer. Both operating systems may defer background work for battery, network, usage, or system scheduling reasons.

The app uses the last known coordinates rather than requesting fresh GPS from the background worker, which avoids requiring continuous background location permission.

### Web

Flutter web cannot use this mobile WorkManager implementation to reliably send weather notifications after the browser tab is closed. If you later publish a web version and want closed-browser alerts, that needs a separate web push/service-worker + server implementation.

### Windows/macOS/Linux

The current background worker is intentionally a **mobile** implementation. Desktop background scheduling requires platform-specific services and is not covered by this worker.
