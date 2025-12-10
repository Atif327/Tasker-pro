package com.fluttertaskerpro.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

object TaskNotificationHelper {
    private const val TAG = "TaskNotificationHelper"
    private const val CHANNEL_ID = "screen_on_task_summary"
    private const val NOTIFICATION_ID = 99999

    fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Task Summary"
            val descriptionText = "Summary of incomplete tasks"
            val importance = NotificationManager.IMPORTANCE_DEFAULT
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
                enableVibration(false)
                enableLights(false)
            }
            
            val notificationManager: NotificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "Notification channel created")
        }
    }

    fun sendTaskSummaryNotification(context: Context) {
        try {
            createNotificationChannel(context)
            
            val incompleteCount = getIncompleteTaskCount(context)
            
            if (incompleteCount > 0) {
                val message = "You still have $incompleteCount task${if (incompleteCount > 1) "s" else ""} to complete"
                
                // Create an intent to launch the app
                val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                intent?.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                
                val builder = NotificationCompat.Builder(context, CHANNEL_ID)
                    .setSmallIcon(android.R.drawable.ic_dialog_info)
                    .setContentTitle("Task Reminder")
                    .setContentText(message)
                    .setStyle(NotificationCompat.BigTextStyle().bigText(message))
                    .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                    .setAutoCancel(true)
                    .setOnlyAlertOnce(true)
                    .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                    .setContentIntent(pendingIntent)
                
                with(NotificationManagerCompat.from(context)) {
                    notify(NOTIFICATION_ID, builder.build())
                }
                
                Log.d(TAG, "Task summary notification sent: $incompleteCount tasks")
            } else {
                Log.d(TAG, "No incomplete tasks found")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error sending notification: ${e.message}", e)
        }
    }

    private fun getIncompleteTaskCount(context: Context): Int {
        var count = 0
        var database: SQLiteDatabase? = null
        
        try {
            val dbPath = context.getDatabasePath("task_manager.db")
            Log.d(TAG, "Database path: ${dbPath.absolutePath}")
            
            if (!dbPath.exists()) {
                Log.w(TAG, "Database file does not exist")
                return 0
            }
            
            database = SQLiteDatabase.openDatabase(
                dbPath.absolutePath,
                null,
                SQLiteDatabase.OPEN_READONLY
            )
            
            val cursor = database.rawQuery(
                "SELECT COUNT(*) FROM tasks WHERE isCompleted = 0",
                null
            )
            
            if (cursor.moveToFirst()) {
                count = cursor.getInt(0)
            }
            cursor.close()
            
            Log.d(TAG, "Found $count incomplete tasks")
        } catch (e: Exception) {
            Log.e(TAG, "Error reading database: ${e.message}", e)
        } finally {
            database?.close()
        }
        
        return count
    }
}
