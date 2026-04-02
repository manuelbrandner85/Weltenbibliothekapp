import 'dart:convert';
import 'dart:async';
import 'dart:io';
import '../config/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Cloudflare-basierte Push-Benachrichtigungen
/// Ersetzt Firebase Cloud Messaging
class CloudflarePushService {
  static String get baseUrl => ApiConfig.pushApiUrl;
  
  // Singleton
  static final CloudflarePushService _instance = CloudflarePushService._internal();
  factory CloudflarePushService() => _instance;
  CloudflarePushService._internal();

  String? _userId;
  List<String> _subscribedTopics = [];

  /// Initialize push service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    
    if (_userId == null) {
      // Generate user ID
      _userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('user_id', _userId!);
    }

    // Load subscribed topics
    final topics = prefs.getStringList('push_topics');
    if (topics != null) {
      _subscribedTopics = topics;
    }

    debugPrint('✅ Cloudflare Push Service initialized for user: $_userId');
  }

  /// Subscribe to push notifications
  Future<bool> subscribe() async {
    if (_userId == null) await initialize();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/push/subscribe'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': _userId,
          'endpoint': 'cloudflare-push',
          'keys': {},
          'topics': _subscribedTopics,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Push-Subscribe Timeout (15s)');
        },
      );

      if (response.statusCode == 201) {
        debugPrint('✅ Subscribed to push notifications');
        return true;
      }
    } on SocketException {
      debugPrint('❌ Push subscribe: Keine Internetverbindung');
    } on TimeoutException catch (e) {
      debugPrint('❌ Push subscribe: $e');
    } catch (e) {
      debugPrint('⚠️ Push subscription error: $e');
    }
    return false;
  }

  /// Unsubscribe from push notifications
  Future<void> unsubscribe() async {
    if (_userId == null) return;

    try {
      await http.delete(
        Uri.parse('$baseUrl/api/push/unsubscribe/$_userId'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Push-Unsubscribe Timeout (10s)');
        },
      );
      debugPrint('✅ Unsubscribed from push notifications');
    } on SocketException {
      debugPrint('❌ Push unsubscribe: Keine Internetverbindung');
    } on TimeoutException catch (e) {
      debugPrint('❌ Push unsubscribe: $e');
    } catch (e) {
      debugPrint('⚠️ Push unsubscribe error: $e');
    }
  }

  /// Subscribe to topics
  Future<void> subscribeToTopics(List<String> topics) async {
    if (_userId == null) await initialize();

    _subscribedTopics = [..._subscribedTopics, ...topics];
    _subscribedTopics = _subscribedTopics.toSet().toList(); // Remove duplicates

    try {
      await http.post(
        Uri.parse('$baseUrl/api/push/topics/subscribe'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': _userId,
          'topics': topics,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Topic-Subscribe Timeout (15s)');
        },
      );

      // Save locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('push_topics', _subscribedTopics);

      debugPrint('✅ Subscribed to topics: $topics');
    } on SocketException {
      debugPrint('❌ Topic subscribe: Keine Internetverbindung');
    } on TimeoutException catch (e) {
      debugPrint('❌ Topic subscribe: $e');
    } catch (e) {
      debugPrint('⚠️ Topic subscription error: $e');
    }
  }

  /// Send test notification
  Future<void> sendTestNotification() async {
    if (_userId == null) await initialize();

    try {
      await http.post(
        Uri.parse('$baseUrl/api/push/send'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': _userId,
          'type': 'test',
          'title': '🔔 Test-Benachrichtigung',
          'body': 'Cloudflare Push-Benachrichtigungen funktionieren!',
          'data': {
            'test': true,
            'timestamp': DateTime.now().toIso8601String(),
          },
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Test-Notification Timeout (10s)');
        },
      );
      debugPrint('✅ Test notification sent');
    } on SocketException {
      debugPrint('❌ Test notification: Keine Internetverbindung');
    } on TimeoutException catch (e) {
      debugPrint('❌ Test notification: $e');
    } catch (e) {
      debugPrint('⚠️ Test notification error: $e');
    }
  }

  /// Schedule notification
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledFor,
    String type = 'scheduled',
    Map<String, dynamic>? data,
  }) async {
    if (_userId == null) await initialize();

    try {
      await http.post(
        Uri.parse('$baseUrl/api/push/schedule'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': _userId,
          'title': title,
          'body': body,
          'scheduled_for': scheduledFor.millisecondsSinceEpoch,
          'type': type,
          'data': data ?? {},
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Schedule-Notification Timeout (15s)');
        },
      );
      debugPrint('✅ Notification scheduled for $scheduledFor');
    } on SocketException {
      debugPrint('❌ Schedule notification: Keine Internetverbindung');
    } on TimeoutException catch (e) {
      debugPrint('❌ Schedule notification: $e');
    } catch (e) {
      debugPrint('⚠️ Schedule notification error: $e');
    }
  }

  /// Get notification history
  Future<List<Map<String, dynamic>>> getNotifications() async {
    if (_userId == null) await initialize();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/$_userId'),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Get-Notifications Timeout (15s)');
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } on SocketException {
      debugPrint('❌ Get notifications: Keine Internetverbindung');
    } on TimeoutException catch (e) {
      debugPrint('❌ Get notifications: $e');
    } catch (e) {
      debugPrint('⚠️ Get notifications error: $e');
    }
    return [];
  }

  /// Available topics for subscription
  static const Map<String, String> availableTopics = {
    'materie_breaking': '🔥 Materie Breaking News',
    'materie_research': '🔍 Materie Neue Recherchen',
    'energie_meditation': '🧘 Energie Meditation Updates',
    'energie_astral': '✨ Energie Astralreisen',
    'daily_wisdom': '💡 Tägliche Weisheit',
    'weekly_summary': '📊 Wöchentliche Zusammenfassung',
  };

  /// Get subscribed topics
  List<String> getSubscribedTopics() => _subscribedTopics;

  /// Get user ID
  String? getUserId() => _userId;
}
