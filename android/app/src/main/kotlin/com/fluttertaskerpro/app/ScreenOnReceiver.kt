package com.fluttertaskerpro.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class ScreenOnReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "ScreenOnReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Screen ON event received: ${intent.action}")
        
        when (intent.action) {
            Intent.ACTION_SCREEN_ON -> {
                Log.d(TAG, "Screen turned ON - sending task summary notification")
                TaskNotificationHelper.sendTaskSummaryNotification(context)
            }
            Intent.ACTION_USER_PRESENT -> {
                Log.d(TAG, "User unlocked device - sending task summary notification")
                TaskNotificationHelper.sendTaskSummaryNotification(context)
            }
        }
    }
}
