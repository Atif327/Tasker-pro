package com.fluttertaskerpro.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d(TAG, "Boot completed - starting screen monitor service")
            
            // Create notification channel
            TaskNotificationHelper.createNotificationChannel(context)
            
            // Start the screen monitor service
            val serviceIntent = Intent(context, ScreenMonitorService::class.java)
            try {
                context.startService(serviceIntent)
                Log.d(TAG, "Screen monitor service started")
            } catch (e: Exception) {
                Log.e(TAG, "Error starting service: ${e.message}")
            }
        }
    }
}
