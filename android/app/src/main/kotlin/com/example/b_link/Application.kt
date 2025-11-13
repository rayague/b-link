package com.example.b_link

import io.flutter.app.FlutterApplication
import android.util.Log

class Application : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        Log.d("b_link", "Application onCreate")
    }
}
