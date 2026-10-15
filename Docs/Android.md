# Build Android

## Chaîne d'outils

- Android Gradle Plugin 9.1, Gradle 9.3.1, Kotlin 2.4 (versions du modèle
  Flutter 3.47), JDK 17.
- `compileSdk = 37` : exigé par `permission_handler_android` 14
  (`android.suppressUnsupportedCompileSdk=37` dans `gradle.properties`,
  AGP 9.1 ne « recommandant » que 36).
- Chaque plugin compile avec sa propre cible JVM (l'ancien forçage de Java
  11 sur tous les sous-projets a été retiré, il n'était plus nécessaire).

## Migration vers le Kotlin intégré d'AGP 9 : bloquée

Flutter avertit que les futures versions refuseront de compiler les apps et
plugins qui appliquent encore le Kotlin Gradle Plugin (KGP) :
<https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers>

État au 16/10/2026 :

- L'app applique encore `kotlin-android` (nécessaire pour compiler
  `MainActivity.kt` tant que `android.builtInKotlin=false`).
- **Bloquant : `workmanager_android`** (dernière version 0.10.9) applique
  encore KGP. Le drapeau `android.builtInKotlin` étant global, il ne peut pas
  être activé avant la migration de ce plugin.

Quand une version de workmanager compatible sortira :

1. Mettre à jour `workmanager` dans `pubspec.yaml`.
2. Dans `android/app/build.gradle.kts`, retirer `id("kotlin-android")`
   (garder le bloc `kotlin { compilerOptions { ... } }`).
3. Dans `android/gradle.properties`, passer `android.builtInKotlin=true`.
4. `flutter build apk --release` puis tester les rappels en arrière-plan.

## Signature de la release

`android/key.properties` (non versionné) + keystore : voir le workflow
`.github/workflows/release.yml`, qui les crée depuis les secrets GitHub
`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`
et `ANDROID_KEY_PASSWORD`. Sans eux, la release est signée avec la clé de
debug (non publiable).
