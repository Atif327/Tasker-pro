package com.fluttertaskerpro.app

import android.app.Service
import android.content.Intent
import android.content.IntentFilter
import android.os.IBinder
import android.util.Log

class ScreenMonitorService : Service() {
    private var screenOnReceiver: ScreenOnReceiver? = null
    
    companion object {
        private const val TAG = "ScreenMonitorService"
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service created")
        registerScreenReceiver()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Service started")
        return START_STICKY // Restart service if killed
    }

    private fun registerScreenReceiver() {
        try {
            screenOnReceiver = ScreenOnReceiver()
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_USER_PRESENT)
            }
            registerReceiver(screenOnReceiver, filter)
            Log.d(TAG, "Screen receiver registered in service")
        } catch (e: Exception) {
            Log.e(TAG, "Error registering receiver: ${e.message}")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            screenOnReceiver?.let {
                unregisterReceiver(it)
                Log.d(TAG, "Screen receiver unregistered")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error unregistering receiver: ${e.message}")
        }
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}
