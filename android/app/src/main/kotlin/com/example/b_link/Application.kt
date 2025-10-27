package com.example.b_link

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.android.FlutterApplication
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugins.GeneratedPluginRegistrant
import android.util.Log
import be.tramckrijte.workmanager.WorkmanagerPlugin

class Application : FlutterApplication(), PluginRegistry.PluginRegistrantCallback {
    override fun onCreate() {
        super.onCreate()
        Log.d("b_link", "Application onCreate: initializing Flutter engine for background tasks")
        // Pre-warm a FlutterEngine for potential background execution if needed
        val flutterEngine = FlutterEngine(this)
        flutterEngine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        // Register the plugin registrant callback for WorkManager headless execution
        try {
            WorkmanagerPlugin.setPluginRegistrantCallback(this)
        } catch (e: Exception) {
            Log.w("b_link", "Workmanager plugin not available or failed to set registrant callback: $e")
        }
    }

    // This will be invoked by the Workmanager plugin when running headless.
    override fun registerWith(registry: PluginRegistry) {
        try {
            GeneratedPluginRegistrant.registerWith(registry)
        } catch (e: Exception) {
            Log.w("b_link", "Failed to register plugins in headless mode: $e")
        }
    }
}
