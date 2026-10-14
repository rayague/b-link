import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load release signing config from android/key.properties (git-ignored).
// If the file is absent (e.g. CI or fresh checkout), release falls back to
// the debug signing config so the build still succeeds.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

// Apply the Google Services plugin to enable reading google-services.json.
// In Groovy Gradle you would add "apply plugin: 'com.google.gms.google-services'",
// in Kotlin DSL we use the plugin id here as well if the classpath is available.
apply(plugin = "com.google.gms.google-services")

android {
    namespace = "com.example.b_link"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Enable core library desugaring (required by flutter_local_notifications v19+)
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.rayague.b_link"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            // Use the release keystore when configured, otherwise fall back to
            // debug signing so local/CI builds keep working.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

// Firebase SDKs via BoM
dependencies {
    // Core library desugaring dependency (required by flutter_local_notifications v19+)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    // Import the Firebase BoM to manage versions
    implementation(platform("com.google.firebase:firebase-bom:34.4.0"))

    // Add the Firebase products you want to use. When using the BoM, don't specify versions.
    implementation("com.google.firebase:firebase-analytics")

    // Add other Firebase SDKs as needed, for example:
    // implementation("com.google.firebase:firebase-auth")
    // implementation("com.google.firebase:firebase-firestore")
}
