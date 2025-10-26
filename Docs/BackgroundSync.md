Background sync (Android & iOS) — setup guide

This project includes Dart-side background registration (`lib/services/background_sync.dart`) using `workmanager` and `background_fetch`.

To complete the setup you must perform these native steps per platform.

Android (required for headless WorkManager tasks)

1. Application class
   - We added `android/app/src/main/kotlin/com/example/b_link/App.kt` and updated `AndroidManifest.xml` to reference it.

2. Permissions
   - Ensure the following permissions are present in `AndroidManifest.xml`:
     - `RECEIVE_BOOT_COMPLETED`
     - `WAKE_LOCK`

3. Gradle
   - `workmanager` and `background_fetch` native dependencies were added by pub; run:

```bash
flutter pub get
```

4. Initialize in Dart
   - The app calls `initializeBackgroundSync()` on startup in `main.dart`. This registers periodic tasks.

5. Testing
   - On Android 12+, background scheduling may be deferred. Test on device/emulator with `adb logcat` to see WorkManager runs.

iOS (Background Fetch)

1. Capabilities
   - In Xcode, open Runner > Signing & Capabilities and add Background Modes, enable "Background fetch" and "Background processing" as needed.

2. AppDelegate
   - If using Swift AppDelegate, add the `BackgroundFetch` plugin registration according to the plugin docs. For many projects, no native AppDelegate change is required — the `background_fetch` plugin handles registration when `BackgroundFetch.configure` is called in Dart.

3. Testing
   - Use Xcode Debug > Simulate Background Fetch to trigger the fetch handler.

Notes & troubleshooting
- The Dart side schedules periodic tasks; Android/iOS may throttle them aggressively depending on device battery.
- For reliable sync (e.g. immediate push after profile save) always call `SyncService.processPending()` after enqueueing (we already enqueue + rely on sync worker as fallback).

If you want, I can implement the Android WorkManager headless plugin registrant pattern (registering the Flutter engine for background execution). This requires adding a `FlutterApplication` subclass and wiring plugin registrant which I can add now.