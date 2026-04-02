/// 📲 PUSH NOTIFICATION SERVICE V2
/// 
/// Cloudflare Workers-basierter Push Service
/// Features:
/// - Token Registration & Management
/// - Category-based Notifications
/// - Do-Not-Disturb Settings
/// - Rate Limiting (100 req/min)
/// - Offline Queue
library;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class PushNotificationServiceV2 {
  static final PushNotificationServiceV2 _instance = PushNotificationServiceV2._internal();
  factory PushNotificationServiceV2() => _instance;
  PushNotificationServiceV2._internal();

  String? _currentToken;
  final List<Map<String, dynamic>> _notificationQueue = [];
  bool _isInitialized = false;

  // ==========================================================================
  // INITIALIZATION
  // ==========================================================================

  /// Initialize Push Notification Service
  Future<void> initialize({
    required String userId,
    Map<String, dynamic>? deviceInfo,
  }) async {
    if (_isInitialized) return;

    try {
      // Get stored token
      final prefs = await SharedPreferences.getInstance();
      _currentToken = prefs.getString('push_token_$userId');

      if (_currentToken != null) {
        // Re-register token on startup
        await registerToken(
          userId: userId,
          token: _currentToken!,
          deviceInfo: deviceInfo,
        );
      }

      _isInitialized = true;
      print('✅ Push Notification Service initialized');
    } catch (e) {
      print('❌ Push Notification init error: $e');
    }
  }

  // ==========================================================================
  // TOKEN MANAGEMENT
  // ==========================================================================

  /// Register Push Token
  Future<bool> registerToken({
    required String userId,
    required String token,
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.pushRegisterUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'token': token,
          'device_info': deviceInfo ?? {
            'platform': 'flutter',
            'model': 'unknown',
            'os_version': 'unknown',
          },
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Store token locally
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('push_token_$userId', token);
          _currentToken = token;
          
          print('✅ Push token registered: $token');
          return true;
        }
      }

      print('❌ Token registration failed: ${response.statusCode}');
      return false;
    } catch (e) {
      print('❌ Token registration error: $e');
      return false;
    }
  }

  /// Unregister Push Token
  Future<bool> unregisterToken({required String userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('push_token_$userId');
      _currentToken = null;
      
      print('✅ Push token unregistered');
      return true;
    } catch (e) {
      print('❌ Token unregister error: $e');
      return false;
    }
  }

  // ==========================================================================
  // NOTIFICATION SETTINGS
  // ==========================================================================

  /// Update Notification Settings
  Future<void> updateSettings({
    required String userId,
    bool? enableMessages,
    bool? enableMentions,
    bool? enableReplies,
    bool? enableSystemAlerts,
    bool? dndEnabled,
    int? dndStartHour,
    int? dndEndHour,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = {
        'enable_messages': enableMessages ?? true,
        'enable_mentions': enableMentions ?? true,
        'enable_replies': enableReplies ?? true,
        'enable_system_alerts': enableSystemAlerts ?? true,
        'dnd_enabled': dndEnabled ?? false,
        'dnd_start_hour': dndStartHour ?? 22,
        'dnd_end_hour': dndEndHour ?? 8,
      };

      await prefs.setString('push_settings_$userId', jsonEncode(settings));
      print('✅ Notification settings updated');
    } catch (e) {
      print('❌ Settings update error: $e');
    }
  }

  /// Get Notification Settings
  Future<Map<String, dynamic>> getSettings({required String userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('push_settings_$userId');
      
      if (settingsJson != null) {
        return jsonDecode(settingsJson);
      }
    } catch (e) {
      print('❌ Settings get error: $e');
    }

    // Default settings
    return {
      'enable_messages': true,
      'enable_mentions': true,
      'enable_replies': true,
      'enable_system_alerts': true,
      'dnd_enabled': false,
      'dnd_start_hour': 22,
      'dnd_end_hour': 8,
    };
  }

  // ==========================================================================
  // SEND NOTIFICATIONS
  // ==========================================================================

  /// Send Push Notification
  Future<String?> sendNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String category = 'message',
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.pushSendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'title': title,
          'body': body,
          'data': data ?? {},
          'category': category,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          print('✅ Push notification sent: ${result['notification_id']}');
          return result['notification_id'];
        }
      } else if (response.statusCode == 429) {
        print('⚠️ Rate limit exceeded, queueing notification');
        _queueNotification(userId, title, body, data, category);
      }

      print('❌ Push send failed: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ Push send error: $e');
      _queueNotification(userId, title, body, data, category);
      return null;
    }
  }

  /// Queue Notification (for offline or rate-limited scenarios)
  void _queueNotification(
    String userId,
    String title,
    String body,
    Map<String, dynamic>? data,
    String category,
  ) {
    _notificationQueue.add({
      'user_id': userId,
      'title': title,
      'body': body,
      'data': data,
      'category': category,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Auto-process queue after delay
    Future.delayed(const Duration(seconds: 30), _processQueue);
  }

  /// Process Queued Notifications
  Future<void> _processQueue() async {
    if (_notificationQueue.isEmpty) return;

    print('📤 Processing ${_notificationQueue.length} queued notifications...');

    final toProcess = List<Map<String, dynamic>>.from(_notificationQueue);
    _notificationQueue.clear();

    for (final notification in toProcess) {
      await sendNotification(
        userId: notification['user_id'],
        title: notification['title'],
        body: notification['body'],
        data: notification['data'],
        category: notification['category'],
      );

      // Rate limiting: wait 600ms between requests (100 req/min)
      await Future.delayed(const Duration(milliseconds: 600));
    }

    print('✅ Queue processed');
  }

  // ==========================================================================
  // UTILITY METHODS
  // ==========================================================================

  /// Check if notifications are enabled for category
  Future<bool> isNotificationEnabled({
    required String userId,
    required String category,
  }) async {
    final settings = await getSettings(userId: userId);
    
    switch (category) {
      case 'message':
        return settings['enable_messages'] ?? true;
      case 'mention':
        return settings['enable_mentions'] ?? true;
      case 'reply':
        return settings['enable_replies'] ?? true;
      case 'system':
        return settings['enable_system_alerts'] ?? true;
      default:
        return true;
    }
  }

  /// Check if Do-Not-Disturb is active
  Future<bool> isDndActive({required String userId}) async {
    final settings = await getSettings(userId: userId);
    
    if (settings['dnd_enabled'] != true) return false;

    final now = DateTime.now();
    final currentHour = now.hour;
    final startHour = settings['dnd_start_hour'] ?? 22;
    final endHour = settings['dnd_end_hour'] ?? 8;

    // Handle overnight DND (e.g., 22:00 - 08:00)
    if (startHour > endHour) {
      return currentHour >= startHour || currentHour < endHour;
    } else {
      return currentHour >= startHour && currentHour < endHour;
    }
  }

  /// Get Current Token
  String? get currentToken => _currentToken;

  /// Is Initialized
  bool get isInitialized => _isInitialized;

  /// Get Queue Length
  int get queueLength => _notificationQueue.length;
}
