package com.example.b_link

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.android.FlutterApplication
import io.flutter.plugins.GeneratedPluginRegistrant
import android.util.Log

class Application : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        Log.d("b_link", "Application onCreate: initializing Flutter engine for background tasks")
        // Pre-warm a FlutterEngine for potential background execution if needed
        val flutterEngine = FlutterEngine(this)
        flutterEngine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        // Note: workmanager plugin uses its own registrant mechanism; ensure plugin supports background handling.
    }
}
