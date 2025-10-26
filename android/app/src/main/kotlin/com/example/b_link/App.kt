package com.example.b_link

import android.app.Application
import android.util.Log

class App : Application() {
    override fun onCreate() {
        super.onCreate()
        // No heavy native init here; Dart side will initialize Workmanager.
        Log.d("b_link", "App.onCreate: Application started")
    }
}
