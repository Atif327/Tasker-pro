package com.fluttertaskerpro.app

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.fluttertaskerpro.app/screen_state"
    private val TAG = "MainActivity"
    private lateinit var prefs: SharedPreferences

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        
        // Start the screen monitor service
        startScreenMonitorService()
        
        Log.d(TAG, "MainActivity created")
    }

    private fun startScreenMonitorService() {
        val serviceIntent = Intent(this, ScreenMonitorService::class.java)
        try {
            startService(serviceIntent)
            Log.d(TAG, "Screen monitor service started from MainActivity")
        } catch (e: Exception) {
            Log.e(TAG, "Error starting service: ${e.message}")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableScreenOnNotifications" -> {
                    val enable = call.argument<Boolean>("enable") ?: true
                    prefs.edit().putBoolean("flutter.screen_on_notifications_enabled", enable).apply()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        
        Log.d(TAG, "Method channel configured")
    }
}
