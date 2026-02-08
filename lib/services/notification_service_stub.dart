/// 🔔 Notification Service - STUB for Non-Web Platforms
/// Provides empty implementations for Android/iOS builds
library;

import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final bool _isPermissionGranted = false;
  bool get isPermissionGranted => _isPermissionGranted;

  /// Check if notifications are supported (always false on non-web)
  bool get isSupported => false;

  /// Request notification permission (stub - does nothing on non-web)
  Future<bool> requestPermission() async {
    if (kDebugMode) {
      debugPrint('⚠️ [Notification] Not supported on this platform');
    }
    return false;
  }

  /// Show notification (stub - does nothing on non-web)
  void showNotification({
    required String title,
    required String body,
    String? icon,
    String? tag,
  }) {
    if (kDebugMode) {
      debugPrint('⚠️ [Notification] Show not supported on this platform');
      debugPrint('   Title: $title');
      debugPrint('   Body: $body');
    }
  }

  /// Show typing notification (stub - does nothing on non-web)
  void showTypingNotification(String username, String room) {
    if (kDebugMode) {
      debugPrint('⚠️ [Notification] Typing notification not supported');
    }
  }

  /// Show message notification (stub - does nothing on non-web)
  void showMessageNotification(String username, String message, String room) {
    if (kDebugMode) {
      debugPrint('⚠️ [Notification] Message notification not supported');
    }
  }

  /// Show voice join notification (stub - does nothing on non-web)
  void showVoiceJoinNotification(String username, String room) {
    if (kDebugMode) {
      debugPrint('⚠️ [Notification] Voice join notification not supported');
    }
  }
}
