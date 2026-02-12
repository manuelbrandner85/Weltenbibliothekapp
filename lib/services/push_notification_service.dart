import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// 🔔 WELTENBIBLIOTHEK - PUSH NOTIFICATION SERVICE
/// Cloudflare-based Push Notifications (No Firebase needed!)

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;
  String? _userId;
  String? _pushToken;

  /// Initialize push notification service
  Future<void> initialize(String userId) async {
    if (_initialized) return;

    _userId = userId;
    
    // Initialize local notifications
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Generate push token (device-specific)
    _pushToken = await _generatePushToken();
    
    // Register token with backend
    await registerPushToken(_pushToken!);

    // Start polling for notifications
    _startNotificationPolling();

    _initialized = true;
    
    if (kDebugMode) {
      print('✅ Push Notifications initialized for user: $userId');
    }
  }

  /// Generate unique push token for device
  Future<String> _generatePushToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('push_token');
    
    if (token == null) {
      token = 'token_${DateTime.now().millisecondsSinceEpoch}_$_userId';
      await prefs.setString('push_token', token);
    }
    
    return token;
  }

  /// Register push token with backend
  Future<bool> registerPushToken(String token) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.v2ApiUrl}/push/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': _userId,
          'token': token,
          'platform': 'android',
        }),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ Push token registered: $token');
        }
        return true;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Push token registration failed: $e');
      }
      return false;
    }
  }

  /// Update notification settings for a room
  Future<bool> updateSettings({
    required String roomId,
    bool enabled = true,
    String? quietHoursStart,
    String? quietHoursEnd,
    List<String> categories = const ['messages', 'mentions', 'replies'],
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.v2ApiUrl}/push/settings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': _userId,
          'roomId': roomId,
          'settings': {
            'enabled': enabled,
            'quietHoursStart': quietHoursStart,
            'quietHoursEnd': quietHoursEnd,
            'categories': categories,
          },
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Update settings failed: $e');
      }
      return false;
    }
  }

  /// Get notification settings for a room
  Future<Map<String, dynamic>> getSettings(String roomId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.v2ApiUrl}/push/settings?userId=$_userId&roomId=$roomId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      
      return {
        'enabled': true,
        'quietHoursStart': null,
        'quietHoursEnd': null,
        'categories': ['messages', 'mentions', 'replies'],
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Get settings failed: $e');
      }
      return {
        'enabled': true,
        'quietHoursStart': null,
        'quietHoursEnd': null,
        'categories': ['messages', 'mentions', 'replies'],
      };
    }
  }

  /// Poll for pending notifications
  void _startNotificationPolling() {
    Future.delayed(const Duration(seconds: 30), () async {
      if (_initialized) {
        await _checkPendingNotifications();
        _startNotificationPolling(); // Continue polling
      }
    });
  }

  /// Check and display pending notifications
  Future<void> _checkPendingNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.v2ApiUrl}/push/pending?userId=$_userId'),
      );

      if (response.statusCode == 200) {
        final notifications = jsonDecode(response.body) as List;
        
        for (final notification in notifications) {
          await _showLocalNotification(
            notification['id'],
            notification['title'],
            notification['body'],
            notification,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Check notifications failed: $e');
      }
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(
    int id,
    String title,
    String body,
    Map<String, dynamic> payload,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'weltenbibliothek_channel',
      'Weltenbibliothek',
      channelDescription: 'Benachrichtigungen von Weltenbibliothek',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: jsonEncode(payload),
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final payload = jsonDecode(response.payload!);
      
      if (kDebugMode) {
        print('📱 Notification tapped: ${payload['roomId']}');
      }
      
      // Navigate to room (implement in main app)
      // NavigationService.navigateToRoom(payload['roomId']);
    }
  }

  /// Send test notification
  Future<void> sendTestNotification() async {
    await _showLocalNotification(
      999,
      'Test Notification',
      'Dies ist eine Test-Benachrichtigung!',
      {'type': 'test'},
    );
  }

  /// Get notification stats
  Future<Map<String, int>> getStats() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.v2ApiUrl}/push/stats?userId=$_userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'total': data['total'],
          'delivered': data['delivered'],
          'pending': data['pending'],
        };
      }
      
      return {'total': 0, 'delivered': 0, 'pending': 0};
    } catch (e) {
      return {'total': 0, 'delivered': 0, 'pending': 0};
    }
  }

  /// Dispose service
  void dispose() {
    _initialized = false;
  }
}
