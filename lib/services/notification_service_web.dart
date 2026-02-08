/// 🔔 NOTIFICATION SERVICE
/// Web Push Notifications for important events
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;
  bool _permissionGranted = false;

  bool get isInitialized => _isInitialized;
  bool get permissionGranted => _permissionGranted;

  /// Initialize and request permission
  Future<bool> initialize() async {
    if (_isInitialized) return _permissionGranted;

    try {
      // Check if notifications are supported
      if (!html.Notification.supported) {
        if (kDebugMode) {
          debugPrint('⚠️ [Notifications] Not supported in this browser');
        }
        return false;
      }

      // Check current permission
      final permission = html.Notification.permission;
      
      if (permission == 'granted') {
        _permissionGranted = true;
        _isInitialized = true;
        if (kDebugMode) {
          debugPrint('✅ [Notifications] Permission already granted');
        }
        return true;
      }

      if (permission == 'denied') {
        if (kDebugMode) {
          debugPrint('❌ [Notifications] Permission denied by user');
        }
        return false;
      }

      // Request permission (permission == 'default')
      final result = await html.Notification.requestPermission();
      _permissionGranted = (result == 'granted');
      _isInitialized = true;

      if (kDebugMode) {
        debugPrint(_permissionGranted 
          ? '✅ [Notifications] Permission granted'
          : '❌ [Notifications] Permission denied');
      }

      return _permissionGranted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Notifications] Init error: $e');
      }
      return false;
    }
  }

  /// Show notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? icon,
    String? tag,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_permissionGranted) {
      if (kDebugMode) {
        debugPrint('⚠️ [Notifications] Cannot show: Permission not granted');
      }
      return;
    }

    try {
      html.Notification(
        title,
        body: body,
        icon: icon ?? '/icons/Icon-192.png',
        tag: tag,
      );

      if (kDebugMode) {
        debugPrint('🔔 [Notifications] Showed: $title');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Notifications] Show error: $e');
      }
    }
  }

  /// Show mention notification
  Future<void> notifyMention({
    required String username,
    required String room,
    required String message,
  }) async {
    await showNotification(
      title: '@$username hat dich erwähnt',
      body: 'In $room: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}',
      tag: 'mention',
    );
  }

  /// Show reply notification
  Future<void> notifyReply({
    required String username,
    required String room,
    required String message,
  }) async {
    await showNotification(
      title: '$username hat geantwortet',
      body: 'In $room: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}',
      tag: 'reply',
    );
  }

  /// Show poll notification
  Future<void> notifyPoll({
    required String username,
    required String room,
    required String question,
  }) async {
    await showNotification(
      title: 'Neue Umfrage in $room',
      body: '$username: $question',
      tag: 'poll',
    );
  }

  /// Show voice room notification
  Future<void> notifyVoiceRoom({
    required String room,
    required int participantCount,
  }) async {
    await showNotification(
      title: 'Voice Chat aktiv',
      body: '$participantCount Teilnehmer in $room',
      tag: 'voice',
    );
  }
}
