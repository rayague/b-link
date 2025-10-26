Steps to add Firebase to Android app (Kotlin DSL)

1) Register app in Firebase Console
   - Package name: com.rayague.b_link
   - App nickname: B-Link
   - Download the generated `google-services.json` file.

2) Place the `google-services.json`
   - Copy the downloaded `google-services.json` into `android/app/` (path: `android/app/google-services.json`).

3) Gradle setup (already applied in this repo)
   - Project-level `android/build.gradle.kts` contains a `buildscript` dependency for `com.google.gms:google-services:4.3.15`.
   - Module-level `android/app/build.gradle.kts` already applies the plugin and includes the Firebase BoM and `firebase-analytics` dependency.

4) Sync & build
   - From Android Studio: click "Sync Project with Gradle Files" or run from command line:
     ```bash
     cd android
     ./gradlew assembleDebug
     ```

5) Verify
   - After a successful build and when the app runs, check the Firebase console (Analytics / DebugView) or use the Admin tools to verify data arrives.

Notes
- If you prefer the plugins {} Kotlin DSL for the project-level plugin declaration, you may instead add:
  ```kotlin
  plugins {
    id("com.google.gms.google-services") version "4.4.4" apply false
  }
  ```
  and then in the module plugins block include `id("com.google.gms.google-services")`.

- For Flutter apps, many Firebase features are exposed through FlutterFire plugins. Adding native SDKs here is optional if you use only FlutterFire packages, but the `google-services.json` and google-services plugin are still required for the native build.

- If your CI runs on different agents, make sure `google-services.json` is provided securely (e.g., via CI secrets) and not committed to the repository.
