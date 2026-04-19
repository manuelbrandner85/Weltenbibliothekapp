// 📱 MOBILE-SPECIFIC NOTIFICATION SERVICE (Android-kompatibel)
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NotificationType {
  achievementUnlock,
  streakReminder,
  dailyPractice,
  syncComplete,
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _permissionGranted = false;
  bool _notificationsEnabled = false;

  bool get permissionGranted => _permissionGranted;
  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    
    // 📱 Android: Assume permission granted (can be extended with permission_handler)
    _permissionGranted = true;
  }

  Future<bool> requestPermission() async {
    // 📱 Android: Return true (can be extended with permission_handler plugin)
    _permissionGranted = true;
    return true;
  }

  void showNotification(
    String title,
    String body, {
    NotificationType? type,
  }) {
    if (!_notificationsEnabled || !_permissionGranted) return;
    
    // 📱 Android: Silently log (can be extended with local_notifications plugin)
    debugPrint('📱 [Android] Notification: $title - $body');
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
  }

  Future<void> scheduleDailyReminder(DateTime time) async {
    // 📱 Android: Log scheduled time (can be extended with local_notifications)
    if (_notificationsEnabled && _permissionGranted) {
      debugPrint('📱 [Android] Daily reminder scheduled: $time');
    }
  }

  Future<void> notifyAchievementUnlock(String title, String message) async {
    // 📱 Android: Show achievement notification
    showNotification(title, message, type: NotificationType.achievementUnlock);
  }
}
