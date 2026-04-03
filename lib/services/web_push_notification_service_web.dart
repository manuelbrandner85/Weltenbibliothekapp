import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 🔔 WEB PUSH NOTIFICATION SERVICE
/// Browser-Benachrichtigungen für neue Chat-Messages und Tool-Aktivitäten
class WebPushNotificationService {
  // VAPID public key – set via dart-define: --dart-define=VAPID_PUBLIC_KEY=...
  static const String _vapidPublicKey = String.fromEnvironment(
    'VAPID_PUBLIC_KEY',
    defaultValue: 'BEl62iUYgUivxIkv69yViEuiBIa-Ib9-SkvMeAtA3LFgDzkrxZJjSgSnfckjBJuBkr3qBUYIHBQFLXYp5Nksh8U',
  );
  
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
  
  /// Subscription an Supabase Backend senden
  Future<void> _sendSubscriptionToBackend(html.PushSubscription subscription) async {
    try {
      final supabaseClient = Supabase.instance.client;
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('⚠️ Push: Kein eingeloggter User – Subscription nicht gespeichert');
        return;
      }

      final endpoint = subscription.endpoint ?? '';
      if (endpoint.isEmpty) {
        debugPrint('⚠️ Push: Kein Endpoint vorhanden');
        return;
      }

      // p256dh und auth über getKey() extrahieren
      String p256dh = '';
      String authKey = '';
      try {
        // getKey() returns an ArrayBuffer; wir lesen es als ByteBuffer
        final p256dhBuffer = subscription.getKey('p256dh');
        final authBuffer   = subscription.getKey('auth');
        if (p256dhBuffer != null) {
          p256dh  = _arrayBufferToBase64(p256dhBuffer);
        }
        if (authBuffer != null) {
          authKey = _arrayBufferToBase64(authBuffer);
        }
      } catch (_) {}

      debugPrint('📤 Push: Speichere Subscription in Supabase: $endpoint');

      await supabaseClient.from('push_subscriptions').upsert({
        'user_id':    userId,
        'endpoint':   endpoint,
        'p256dh':     p256dh,
        'auth_key':   authKey,
        'platform':   'web',
        'is_active':  true,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, endpoint');

      debugPrint('✅ Push: Subscription in Supabase gespeichert');
    } catch (e) {
      debugPrint('❌ Push: Backend-Registrierung fehlgeschlagen: $e');
    }
  }

  /// Push-Subscription aus Supabase entfernen (beim Logout)
  Future<void> unsubscribe() async {
    try {
      if (_pushSubscription != null) {
        await _pushSubscription!.unsubscribe();
        _pushSubscription = null;
      }

      final supabaseClient = Supabase.instance.client;
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId != null) {
        await supabaseClient
            .from('push_subscriptions')
            .update({'is_active': false})
            .eq('user_id', userId)
            .eq('platform', 'web');
        debugPrint('✅ Push: Subscription deaktiviert');
      }
    } catch (e) {
      debugPrint('❌ Push: Unsubscribe fehlgeschlagen: $e');
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

  /// ByteBuffer → Base64url String (für VAPID-Keys)
  String _arrayBufferToBase64(dynamic buffer) {
    try {
      // dart:html ArrayBuffer → Uint8List via dart:typed_data
      final byteBuffer = buffer as ByteBuffer;
      final bytes = Uint8List.view(byteBuffer);
      var base64Str = _bytesToBase64(bytes);
      // Base64 → Base64url
      return base64Str.replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');
    } catch (_) {
      return '';
    }
  }

  String _bytesToBase64(Uint8List bytes) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final buf = StringBuffer();
    for (var i = 0; i < bytes.length; i += 3) {
      final b0 = bytes[i];
      final b1 = i + 1 < bytes.length ? bytes[i + 1] : 0;
      final b2 = i + 2 < bytes.length ? bytes[i + 2] : 0;
      buf.write(chars[(b0 >> 2) & 0x3F]);
      buf.write(chars[((b0 << 4) | (b1 >> 4)) & 0x3F]);
      buf.write(i + 1 < bytes.length ? chars[((b1 << 2) | (b2 >> 6)) & 0x3F] : '=');
      buf.write(i + 2 < bytes.length ? chars[b2 & 0x3F] : '=');
    }
    return buf.toString();
  }
}
