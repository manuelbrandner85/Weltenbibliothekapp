/// 🔔 Web Push Notification Service
/// Handles notification permissions, subscriptions, and display
library;

import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'cloudflare_api_service.dart';

class WebNotificationService extends ChangeNotifier {
  static final WebNotificationService _instance = WebNotificationService._internal();
  factory WebNotificationService() => _instance;
  WebNotificationService._internal();

  final String _baseUrl = CloudflareApiService.chatFeaturesApiUrl;
  
  bool _isSupported = false;
  bool _isPermissionGranted = false;
  String? _subscriptionEndpoint;

  bool get isSupported => _isSupported;
  bool get isPermissionGranted => _isPermissionGranted;
  String? get subscriptionEndpoint => _subscriptionEndpoint;

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      // Check if notifications are supported (Web only)
      if (kIsWeb) {
        _isSupported = html.Notification.supported;
        
        if (_isSupported) {
          // Check current permission
          final permission = html.Notification.permission;
          _isPermissionGranted = permission == 'granted';
          
          if (kDebugMode) {
            debugPrint('🔔 [Notifications] Supported: $_isSupported');
            debugPrint('🔔 [Notifications] Permission: $permission');
          }
          
          // Register service worker
          if (_isPermissionGranted) {
            await _registerServiceWorker();
          }
        }
      }
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Notifications] Initialization error: $e');
      }
    }
  }

  /// Request notification permission
  Future<bool> requestPermission() async {
    try {
      if (!_isSupported) {
        if (kDebugMode) {
          debugPrint('❌ [Notifications] Not supported in this browser');
        }
        return false;
      }

      final permission = await html.Notification.requestPermission();
      _isPermissionGranted = permission == 'granted';
      
      if (kDebugMode) {
        debugPrint('🔔 [Notifications] Permission: $permission');
      }

      if (_isPermissionGranted) {
        await _registerServiceWorker();
      }

      notifyListeners();
      return _isPermissionGranted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Notifications] Permission request error: $e');
      }
      return false;
    }
  }

  /// Register service worker for push notifications
  Future<void> _registerServiceWorker() async {
    try {
      // Check if service worker is available
      if (html.window.navigator.serviceWorker == null) {
        if (kDebugMode) {
          debugPrint('❌ [Notifications] Service Worker not supported');
        }
        return;
      }

      // Register service worker
      final registration = await html.window.navigator.serviceWorker!
          .register('/firebase-messaging-sw.js');

      if (kDebugMode) {
        debugPrint('✅ [Notifications] Service Worker registered');
      }

      // Subscribe to push notifications
      await _subscribeToPush(registration);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Notifications] Service Worker registration error: $e');
      }
    }
  }

  /// Subscribe to push notifications
  Future<void> _subscribeToPush(html.ServiceWorkerRegistration registration) async {
    try {
      // Get push subscription
      final subscription = await registration.pushManager!.subscribe({
        'userVisibleOnly': true,
        'applicationServerKey': _urlBase64ToUint8Array(_vapidPublicKey),
      });

      _subscriptionEndpoint = subscription.endpoint;
      
      if (kDebugMode) {
        debugPrint('✅ [Notifications] Push subscription created');
        debugPrint('🔔 [Notifications] Endpoint: $_subscriptionEndpoint');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Notifications] Push subscription error: $e');
      }
    }
  }

  /// Send notification to backend
  Future<bool> sendNotification({
    required String userId,
    required String title,
    required String body,
    String? roomId,
    String? messageId,
    String? world,
  }) async {
    try {
      if (!_isPermissionGranted) {
        if (kDebugMode) {
          debugPrint('⚠️ [Notifications] Permission not granted');
        }
        return false;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/notifications/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'title': title,
          'body': body,
          'roomId': roomId,
          'messageId': messageId,
          'world': world,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('✅ [Notifications] Notification sent');
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('❌ [Notifications] Send failed: ${response.statusCode}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Notifications] Send error: $e');
      }
      return false;
    }
  }

  /// Show local notification (for testing)
  void showLocalNotification({
    required String title,
    required String body,
    String? icon,
  }) {
    if (!_isPermissionGranted) {
      if (kDebugMode) {
        debugPrint('⚠️ [Notifications] Permission not granted');
      }
      return;
    }

    html.Notification(
      title,
      body: body,
      icon: icon ?? '/icons/Icon-192.png',
    );
  }

  /// Convert VAPID key to Uint8Array
  List<int> _urlBase64ToUint8Array(String base64String) {
    const padding = '=';
    var base64 = base64String.replaceAll('-', '+').replaceAll('_', '/');
    
    while (base64.length % 4 != 0) {
      base64 += padding;
    }

    return base64Decode(base64);
  }

  // VAPID Public Key (replace with your own from Cloudflare/Firebase)
  static const String _vapidPublicKey = 
      'BKx7V0JGLqQxJPUVxVqGQj5ZKqVQdZj3KOKj5qXDdZj3KO'; // Placeholder
}
