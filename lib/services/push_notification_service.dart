import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// 🔔 Push Notification Service für Weltenbibliothek
///
/// Verwaltet Web Push Notifications mit Cloudflare Worker Backend
class PushNotificationService {
  static const String _boxName = 'push_notifications';
  static const String _subscriptionKey = 'push_subscription';
  static const String _apiBaseUrl = 'https://your-worker.workers.dev/api';

  late Box _box;
  bool _isInitialized = false;
  String? _subscriptionId;

  /// Initialisiere Hive Box
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _box = await Hive.openBox(_boxName);
      _isInitialized = true;

      // Lade gespeicherte Subscription
      final savedSub = _box.get(_subscriptionKey);
      if (savedSub != null) {
        _subscriptionId = savedSub as String;
      }

      if (kDebugMode) {
        debugPrint('✅ PushNotificationService initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to initialize PushNotificationService: $e');
      }
    }
  }

  /// Prüfe ob Notifications unterstützt werden
  bool isSupported() {
    // Web Push API ist nur im Web verfügbar
    return kIsWeb;
  }

  /// Prüfe ob User bereits subscribed ist
  bool isSubscribed() {
    return _subscriptionId != null;
  }

  /// Subscribe zu Push Notifications
  Future<bool> subscribe({
    required String userId,
    List<String> topics = const [],
  }) async {
    if (!isSupported()) {
      if (kDebugMode) {
        debugPrint('⚠️ Push Notifications not supported on this platform');
      }
      return false;
    }

    try {
      // In einer echten Implementierung würde hier die Web Push API verwendet
      // Für die Demonstration simulieren wir eine Subscription

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/push/subscribe'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'topics': topics,
          'platform': 'web',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _subscriptionId = data['subscription_id'] as String;

        // Speichere Subscription lokal
        await _box.put(_subscriptionKey, _subscriptionId);

        if (kDebugMode) {
          debugPrint('✅ Successfully subscribed to push notifications');
          debugPrint('   Subscription ID: $_subscriptionId');
        }

        return true;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Failed to subscribe: ${response.statusCode}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error subscribing to push notifications: $e');
      }
      return false;
    }
  }

  /// Unsubscribe von Push Notifications
  Future<bool> unsubscribe() async {
    if (_subscriptionId == null) return true;

    try {
      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/push/unsubscribe'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'subscription_id': _subscriptionId}),
      );

      if (response.statusCode == 200) {
        _subscriptionId = null;
        await _box.delete(_subscriptionKey);

        if (kDebugMode) {
          debugPrint('✅ Successfully unsubscribed from push notifications');
        }

        return true;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Failed to unsubscribe: ${response.statusCode}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error unsubscribing from push notifications: $e');
      }
      return false;
    }
  }

  /// Subscribe zu einem Topic (z.B. "new_events", "chat_messages")
  Future<bool> subscribeToTopic(String topic) async {
    if (_subscriptionId == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/push/topics/subscribe'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'subscription_id': _subscriptionId, 'topic': topic}),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('✅ Subscribed to topic: $topic');
        }
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error subscribing to topic: $e');
      }
      return false;
    }
  }

  /// Unsubscribe von einem Topic
  Future<bool> unsubscribeFromTopic(String topic) async {
    if (_subscriptionId == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/push/topics/unsubscribe'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'subscription_id': _subscriptionId, 'topic': topic}),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('✅ Unsubscribed from topic: $topic');
        }
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error unsubscribing from topic: $e');
      }
      return false;
    }
  }

  /// Hole aktuelle Subscription-Einstellungen
  Future<Map<String, dynamic>?> getSubscriptionSettings() async {
    if (_subscriptionId == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/push/subscription/$_subscriptionId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting subscription settings: $e');
      }
      return null;
    }
  }

  /// Sende Test-Notification
  Future<bool> sendTestNotification() async {
    if (_subscriptionId == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/push/test'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'subscription_id': _subscriptionId,
          'title': 'Test Notification',
          'body':
              'Dies ist eine Test-Benachrichtigung von Weltenbibliothek! 🔮',
          'icon': '/icons/Icon-192.png',
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error sending test notification: $e');
      }
      return false;
    }
  }

  /// Cleanup
  Future<void> dispose() async {
    if (_isInitialized) {
      await _box.close();
      _isInitialized = false;
    }
  }
}

/// Notification Topics für Weltenbibliothek
enum NotificationTopic {
  newEvents('new_events', 'Neue Events', '🗺️'),
  chatMessages('chat_messages', 'Chat-Nachrichten', '💬'),
  liveStreams('live_streams', 'Live-Streams', '📹'),
  systemUpdates('system_updates', 'System-Updates', '🔔'),
  communityNews('community_news', 'Community-News', '📰');

  final String id;
  final String label;
  final String emoji;

  const NotificationTopic(this.id, this.label, this.emoji);
}
