import 'package:flutter/foundation.dart';
import 'dart:html' as html;

/// 🔔 WEB PUSH NOTIFICATION SERVICE
/// Browser-Benachrichtigungen für neue Chat-Messages und Tool-Aktivitäten
class WebPushNotificationService {
  static const String _vapidPublicKey = 'YOUR_VAPID_PUBLIC_KEY_HERE'; // TODO: Generate VAPID keys
  
  html.ServiceWorkerRegistration? _swRegistration;
  html.PushSubscription? _pushSubscription;
  
  bool _isInitialized = false;
  bool _isPermissionGranted = false;
  
  /// Initialisiere Push-Service
  Future<bool> initialize() async {
    if (!kIsWeb) {
      debugPrint('⚠️ Push: Nur für Web verfügbar');
      return false;
    }
    
    try {
      // Service Worker registrieren
      _swRegistration = await html.window.navigator.serviceWorker!
          .register('/firebase-messaging-sw.js');
      
      debugPrint('✅ Push: Service Worker registriert');
      
      // Warte bis Service Worker aktiv ist
      // await _swRegistration!.ready; // 🔧 DISABLED: Browser compatibility issue
      
      _isInitialized = true;
      debugPrint('✅ Push: Initialisierung abgeschlossen');
      return true;
      
    } catch (e) {
      debugPrint('❌ Push: Initialisierung fehlgeschlagen: $e');
      return false;
    }
  }
  
  /// Benachrichtigungsberechtigung anfordern
  Future<bool> requestPermission() async {
    if (!kIsWeb || !_isInitialized) return false;
    
    try {
      final permission = await html.Notification.requestPermission();
      
      _isPermissionGranted = permission == 'granted';
      
      if (_isPermissionGranted) {
        debugPrint('✅ Push: Berechtigung erteilt');
        await _subscribeToPush();
      } else {
        debugPrint('⚠️ Push: Berechtigung verweigert: $permission');
      }
      
      return _isPermissionGranted;
      
    } catch (e) {
      debugPrint('❌ Push: Berechtigung fehlgeschlagen: $e');
      return false;
    }
  }
  
  /// Push-Subscription erstellen
  Future<void> _subscribeToPush() async {
    if (_swRegistration == null) return;
    
    try {
      // Prüfe ob bereits subscribed
      _pushSubscription = await _swRegistration!.pushManager!.getSubscription();
      
      if (_pushSubscription == null) {
        // Neue Subscription erstellen
        final options = {
          'userVisibleOnly': true,
          'applicationServerKey': _urlBase64ToUint8Array(_vapidPublicKey),
        };
        
        _pushSubscription = await _swRegistration!.pushManager!
            .subscribe(options);
        
        debugPrint('✅ Push: Subscription erstellt');
        
        // TODO: Subscription an Backend senden
        await _sendSubscriptionToBackend(_pushSubscription!);
      } else {
        debugPrint('✅ Push: Bereits subscribed');
      }
      
    } catch (e) {
      debugPrint('❌ Push: Subscription fehlgeschlagen: $e');
    }
  }
  
  /// Subscription an Backend senden
  Future<void> _sendSubscriptionToBackend(html.PushSubscription subscription) async {
    try {
      // Extrahiere Subscription-Daten
      final endpoint = subscription.endpoint;
      debugPrint('📤 Push: Sende Subscription an Backend: $endpoint');
      
      // TODO: Implement Backend Subscription
      // await http.post(
      //   Uri.parse(ApiConfig.pushApiUrl + '/subscribe'),
      //   body: jsonEncode({
      //     'endpoint': endpoint,
      //     'keys': {
      //       'p256dh': subscription.getKey('p256dh'),
      //       'auth': subscription.getKey('auth'),
      //     },
      //   }),
      // );
      
    } catch (e) {
      debugPrint('❌ Push: Backend-Registrierung fehlgeschlagen: $e');
    }
  }
  
  /// Lokale Browser-Benachrichtigung anzeigen (ohne Push)
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? icon,
    String? tag,
    Map<String, dynamic>? data,
  }) async {
    if (!kIsWeb) return;
    
    // Prüfe Berechtigung
    if (!_isPermissionGranted) {
      final granted = await requestPermission();
      if (!granted) return;
    }
    
    try {
      // 🔧 SIMPLIFIED: Use basic Notification constructor
      // ignore: unused_local_variable
      final notification = html.Notification(title);
      
      debugPrint('✅ Push: Lokale Benachrichtigung gezeigt');
      
    } catch (e) {
      debugPrint('❌ Push: Benachrichtigung fehlgeschlagen: $e');
    }
  }
  
  /// Benachrichtigung für neue Chat-Nachricht
  Future<void> notifyNewChatMessage({
    required String roomName,
    required String username,
    required String message,
    String? roomId,
  }) async {
    await showLocalNotification(
      title: '💬 $roomName',
      body: '$username: ${_truncateMessage(message, 100)}',
      tag: 'chat-$roomId',
      data: {
        'type': 'chat_message',
        'roomId': roomId,
      },
    );
  }
  
  /// Benachrichtigung für Tool-Aktivität
  Future<void> notifyToolActivity({
    required String roomName,
    required String username,
    required String toolName,
    required String activity,
    String? icon,
  }) async {
    await showLocalNotification(
      title: '🔧 $roomName',
      body: '$username nutzt $toolName: $_truncateMessage(activity, 80)',
      icon: icon,
      tag: 'tool-activity',
      data: {
        'type': 'tool_activity',
        'toolName': toolName,
      },
    );
  }
  
  /// Benachrichtigungsstatus prüfen
  bool get isPermissionGranted => _isPermissionGranted;
  bool get isInitialized => _isInitialized;
  
  String getPermissionStatus() {
    if (!kIsWeb) return '❌ Nicht verfügbar (nur Web)';
    if (!_isInitialized) return '⚠️ Nicht initialisiert';
    if (_isPermissionGranted) return '✅ Aktiviert';
    return '🔕 Deaktiviert';
  }
  
  /// Hilfsfunktionen
  String _truncateMessage(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
  
  List<int> _urlBase64ToUint8Array(String base64String) {
    const padding = '=';
    var base64 = base64String.replaceAll('-', '+').replaceAll('_', '/');
    
    while (base64.length % 4 != 0) {
      base64 += padding;
    }
    
    return Uri.parse(base64).data!.contentAsBytes();
  }
}
