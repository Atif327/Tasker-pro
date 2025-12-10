import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import '../database/database_helper.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  NotificationService._init();

  Future<String> _getNotificationSound() async {
    final prefs = await SharedPreferences.getInstance();
    final sound = prefs.getString('notification_sound') ?? 'default';
    return sound;
  }

  // Removed unused _shouldPlaySound function

  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null,
      [
        // Silent channel
        NotificationChannel(
          channelKey: 'task_channel_silent',
          channelName: 'Task Notifications (Silent)',
          channelDescription: 'Silent notifications without sound or vibration',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: false,
          enableVibration: false,
        ),
        // Default sound channel
        NotificationChannel(
          channelKey: 'task_channel_default',
          channelName: 'Task Notifications (Default)',
          channelDescription: 'Notifications with system default sound',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          channelShowBadge: true,
          playSound: true,
          criticalAlerts: true,
          enableVibration: false,
          enableLights: true,
          vibrationPattern: null,
          defaultRingtoneType: DefaultRingtoneType.Notification,
        ),
        // Bell sound channel
        NotificationChannel(
          channelKey: 'task_channel_bell',
          channelName: 'Task Notifications (Bell)',
          channelDescription: 'Notifications with bell sound',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          channelShowBadge: true,
          playSound: true,
          soundSource: 'resource://raw/res_notification_bell',
          criticalAlerts: true,
          enableVibration: false,
          enableLights: true,
          vibrationPattern: null,
          defaultRingtoneType: DefaultRingtoneType.Notification,
        ),
        // Chime sound channel
        NotificationChannel(
          channelKey: 'task_channel_chime',
          channelName: 'Task Notifications (Chime)',
          channelDescription: 'Notifications with chime sound',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          channelShowBadge: true,
          playSound: true,
          soundSource: 'resource://raw/res_notification_chime',
          criticalAlerts: true,
          enableVibration: false,
          enableLights: true,
          vibrationPattern: null,
          defaultRingtoneType: DefaultRingtoneType.Notification,
        ),
        // Alert sound channel
        NotificationChannel(
          channelKey: 'task_channel_alert',
          channelName: 'Task Notifications (Alert)',
          channelDescription: 'Notifications with alert sound',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          channelShowBadge: true,
          playSound: true,
          soundSource: 'resource://raw/res_notification_alert',
          criticalAlerts: true,
          enableVibration: false,
          enableLights: true,
          vibrationPattern: null,
          defaultRingtoneType: DefaultRingtoneType.Notification,
        ),
      ],
      debug: true,
    );

    // Request permission
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });

    // Listen for foreground action buttons (e.g., Snooze)
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: (ReceivedAction action) async {
        await handleAction(action);
      },
    );
  }
  
  String _getChannelKey(String soundPreference) {
    switch (soundPreference) {
      case 'silent':
        return 'task_channel_silent';
      case 'notification_bell':
        return 'task_channel_bell';
      case 'notification_chime':
        return 'task_channel_chime';
      case 'notification_alert':
        return 'task_channel_alert';
      case 'default':
      default:
        return 'task_channel_default';
    }
  }
  
  // Call this method to reinitialize when sound preference changes
  Future<void> updateNotificationSettings() async {
    // No need to reinitialize - channels are already created
  }

  Future<void> scheduleTaskNotification(
    Task task, {
    int? notificationId,
    String? titleOverride,
  }) async {
    if (task.dueTime == null) return;

    final soundPreference = await _getNotificationSound();
    final channelKey = _getChannelKey(soundPreference);
    
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId ?? task.id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: channelKey,
        title: titleOverride ?? task.title,
        body: "Don't forget to complete this task as soon as possible",
        notificationLayout: NotificationLayout.BigText,
        payload: {'taskId': task.id.toString()},
        wakeUpScreen: true,
        fullScreenIntent: true,
        criticalAlert: true,
        category: NotificationCategory.Alarm,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'COMPLETE_TASK',
          label: 'Done',
          autoDismissible: true,
          actionType: ActionType.Default,
          color: Colors.green,
        ),
        NotificationActionButton(key: 'SNOOZE_5', label: '5 min', autoDismissible: true),
        NotificationActionButton(key: 'SNOOZE_10', label: '10 min', autoDismissible: true),
        NotificationActionButton(key: 'SNOOZE_15', label: '15 min', autoDismissible: true),
      ],
      schedule: NotificationCalendar(
        year: task.dueTime!.year,
        month: task.dueTime!.month,
        day: task.dueTime!.day,
        hour: task.dueTime!.hour,
        minute: task.dueTime!.minute,
        second: 0,
        millisecond: 0,
      ),
    );
  }

  Future<void> scheduleRepeatingTaskNotification(
    Task task, {
    int? notificationId,
    String? titleOverride,
  }) async {
    if (task.dueTime == null || !task.isRepeating) return;

    final soundPreference = await _getNotificationSound();
    final channelKey = _getChannelKey(soundPreference);

    if (task.repeatType == 'daily') {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId ?? task.id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: channelKey,
          title: titleOverride ?? task.title,
          body: "Don't forget to complete this task as soon as possible",
          notificationLayout: NotificationLayout.BigText,
          payload: {'taskId': task.id.toString()},
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          category: NotificationCategory.Alarm,
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'COMPLETE_TASK',
            label: 'Done',
            autoDismissible: true,
            actionType: ActionType.Default,
            color: Colors.green,
          ),
          NotificationActionButton(key: 'SNOOZE_5', label: '5 min', autoDismissible: true),
          NotificationActionButton(key: 'SNOOZE_10', label: '10 min', autoDismissible: true),
        ],
        schedule: NotificationCalendar(
          hour: task.dueTime!.hour,
          minute: task.dueTime!.minute,
          second: 0,
          millisecond: 0,
          repeats: true,
        ),
      );
    }
  }

  Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }

  // Cancel potential IDs used for a task's notifications (reminder, due, repeating)
  Future<void> cancelTaskNotifications(int taskId) async {
    // Old scheme (single id)
    await AwesomeNotifications().cancel(taskId);
    // New scheme (distinct IDs per purpose)
    final base = taskId * 1000;
    await AwesomeNotifications().cancel(base + 1); // reminder
    await AwesomeNotifications().cancel(base + 2); // due time
    await AwesomeNotifications().cancel(base + 3); // repeating
  }

  Future<void> showInstantNotification(String title, String body) async {
    final soundPreference = await _getNotificationSound();
    final channelKey = _getChannelKey(soundPreference);
    
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: channelKey,
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  Future<void> sendNotificationsForIncompleteTasks(int userId) async {
    final db = DatabaseHelper.instance;
    final incompleteTasks = await db.getIncompleteTasks(userId);
    
    final soundPreference = await _getNotificationSound();
    final channelKey = _getChannelKey(soundPreference);
    
    // Cancel all previous screen-on notifications first to avoid duplicates
    for (int i = 0; i < 100; i++) {
      await AwesomeNotifications().cancel(100000 + i);
    }
    
    int notificationIndex = 0;
    for (final task in incompleteTasks) {
      final notificationId = 100000 + notificationIndex; // Use unique range for screen-on notifications
      notificationIndex++;
      
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: channelKey,
          title: task.title,
          body: "Don't forget to complete this task as soon as possible",
          notificationLayout: NotificationLayout.BigText,
          payload: {'taskId': task.id.toString()},
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          category: NotificationCategory.Alarm,
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'COMPLETE_TASK',
            label: 'Complete Task',
            autoDismissible: true,
            actionType: ActionType.Default,
            color: Colors.green,
          ),
          NotificationActionButton(key: 'SNOOZE_5', label: 'Snooze 5m', autoDismissible: true),
          NotificationActionButton(key: 'SNOOZE_10', label: 'Snooze 10m', autoDismissible: true),
          NotificationActionButton(key: 'SNOOZE_15', label: 'Snooze 15m', autoDismissible: true),
        ],
      );
      
      // Small delay to avoid overwhelming the notification system
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> handleAction(ReceivedAction action) async {
    final key = action.buttonKeyPressed;
    if (key.isEmpty) return;

    final payload = action.payload ?? {};
    final taskIdStr = payload['taskId'];
    if (taskIdStr == null) return;
    final taskId = int.tryParse(taskIdStr);
    if (taskId == null) return;

    final db = DatabaseHelper.instance;
    final task = await db.getTaskById(taskId);
    if (task == null) return;

    final originalNotificationId = action.id ?? (task.id ?? 0);

    // Handle Complete Task button
    if (key == 'COMPLETE_TASK') {
      // Mark task as completed with timestamp
      await db.updateTask(task.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      ));
      // Cancel the notification
      await AwesomeNotifications().cancel(originalNotificationId);
      // Show confirmation notification
      await showInstantNotification(
        '✓ Task Completed',
        '${task.title} has been marked as complete!',
      );
      return;
    }

    // Handle snooze buttons
    int? minutes;
    if (key == 'SNOOZE_5') minutes = 5;
    if (key == 'SNOOZE_10') minutes = 10;
    if (key == 'SNOOZE_15') minutes = 15;
    if (minutes == null) return;

    // Cancel the specific notification that was snoozed
    await AwesomeNotifications().cancel(originalNotificationId);

    // Use a unique ID for snoozed notifications (200000 range to avoid conflicts)
    final snoozeNotificationId = 200000 + (task.id ?? 0);
    
    // Reschedule with a unique snooze notification ID
    final snoozeTime = DateTime.now().add(Duration(minutes: minutes));
    await scheduleTaskNotification(
      task.copyWith(dueTime: snoozeTime),
      notificationId: snoozeNotificationId,
      titleOverride: '🔔 Snoozed: ${task.title}',
    );
  }
}
