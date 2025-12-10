import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class ScreenStateService with WidgetsBindingObserver {
  static final ScreenStateService instance = ScreenStateService._init();
  ScreenStateService._init();

  static const platform = MethodChannel('com.fluttertaskerpro.app/screen_state');
  int? _currentUserId;
  bool _isInitialized = false;

  void initialize(int userId) {
    if (!_isInitialized) {
      _currentUserId = userId;
      WidgetsBinding.instance.addObserver(this);
      _setupMethodChannel();
      _isInitialized = true;
    } else {
      _currentUserId = userId;
    }
  }

  void _setupMethodChannel() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onScreenOn') {
        print('Received onScreenOn from native Android'); // Debug log
        // Native Android already sends the summary notification
        // No need to send detailed notifications from Flutter side
      }
    });
    print('Method channel setup complete');
  }

  void dispose() {
    if (_isInitialized) {
      WidgetsBinding.instance.removeObserver(this);
      _isInitialized = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    print('App lifecycle state changed to: $state'); // Debug log
    
    // Don't send notifications on app resume
    // The native Android receiver handles screen-on notifications
  }

  Future<void> _onScreenTurnedOn() async {
    print('_onScreenTurnedOn called, userId: $_currentUserId'); // Debug log
    // Native Android side handles the notification
    // No action needed here
  }

  // Manual trigger for testing/debugging
  Future<void> triggerNotificationsNow() async {
    await _onScreenTurnedOn();
  }

  // Method to enable/disable the feature
  Future<void> setNotifyOnScreenOn(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notify_on_screen_on', enabled);
  }

  // Method to check if the feature is enabled
  Future<bool> isNotifyOnScreenOnEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notify_on_screen_on') ?? true;
  }
}
