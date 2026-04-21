/// 🔔 Push Notification Manager (FCM + In-App Polling)
///
/// Koordiniert den kompletten Push-Stack der App:
///   1. Firebase Cloud Messaging für **Background-Delivery** (App geschlossen):
///      - initialisiert Firebase, holt FCM-Token, registriert ihn auf
///        `push_subscriptions` via Worker `/api/push/subscribe`.
///      - Top-Level Background-Handler `_fcmBackgroundHandler` wird vor dem
///        `runApp()` registriert (Pflicht laut FlutterFire) und zeigt eingehende
///        FCM-Pushes als lokale Notification.
///      - Foreground: `FirebaseMessaging.onMessage` → lokale Notification (iOS
///        zeigt FCM-Pushes sonst nicht an wenn App im Vordergrund).
///   2. In-App Polling als Fallback (App offen, FCM ausgefallen oder nicht
///      konfiguriert): alle 30s `/api/push/pending?user_id=UUID`, zeigt neue
///      Einträge als lokale Notifications.
///   3. Auto-Register: reagiert auf `onAuthStateChange.signedIn` und
///      registriert die Subscription sobald ein User eingeloggt ist.
///   4. Deep-Link: Tap auf Notification ruft `_deepLinkHandler` auf und öffnet
///      `/chat/:world/:room` oder `/post/:id` via globalem NavigatorKey.
///
/// Graceful Degradation: Wenn Firebase fehlschlägt (keine google-services.json,
/// kein Play Services, etc.), überspringen wir den FCM-Teil und polling läuft
/// als einziger Kanal weiter — App crasht nie an fehlender Firebase-Config.
library;

import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/api_config.dart';

/// Callback for deep-link navigation. Registered by the app shell after routes
/// are set up. Receives the raw `data` map from the notification payload.
typedef DeepLinkHandler = void Function(Map<String, dynamic> data);

/// Shared local-notifications plugin instance — wird sowohl vom Manager als
/// auch vom Top-Level FCM-Background-Handler benutzt.
final FlutterLocalNotificationsPlugin _localPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'weltenbibliothek_push',
  'Benachrichtigungen',
  description: 'Chat-Nachrichten, Erwähnungen & Updates',
  importance: Importance.high,
);

const NotificationDetails _notifDetails = NotificationDetails(
  android: AndroidNotificationDetails(
    'weltenbibliothek_push',
    'Benachrichtigungen',
    channelDescription: 'Chat-Nachrichten, Erwähnungen & Updates',
    importance: Importance.high,
    priority: Priority.high,
  ),
  iOS: DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  ),
);

/// Top-Level Background-Handler für FCM (wird von Flutter Isolate aufgerufen
/// wenn App geschlossen ist). MUSS eine Top-Level-Funktion sein und mit
/// `@pragma('vm:entry-point')` annotiert, damit die AOT-Compilation sie behält.
@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  // Firebase muss im Background-Isolate erneut initialisiert werden.
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Already initialized or config missing — weiter versuchen.
  }
  // Android zeigt Notifications mit `notification`-Payload automatisch in der
  // System-Tray an; nur wenn kein Notification-Block da ist (data-only Push)
  // müssen wir selbst zeichnen.
  if (message.notification == null) {
    final data = message.data;
    final title = data['title']?.toString() ?? 'Weltenbibliothek';
    final body = data['body']?.toString() ?? '';
    final id = (message.messageId?.hashCode) ??
        DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
    try {
      await _localPlugin.show(id, title, body, _notifDetails,
          payload: jsonEncode(data));
    } catch (_) {
      // BG isolate darf lokale Notifications ohne init kaum zeichnen;
      // fehlt init, fällt FCM trotzdem auf Android-System-Tray zurück.
    }
  }
}

class PushNotificationManager with WidgetsBindingObserver {
  PushNotificationManager._();
  static final PushNotificationManager instance = PushNotificationManager._();

  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<RemoteMessage>? _fcmForegroundSub;
  StreamSubscription<RemoteMessage>? _fcmOpenedSub;
  StreamSubscription<String>? _fcmTokenSub;
  Timer? _pollTimer;
  bool _initialized = false;
  bool _firebaseReady = false;
  String? _fcmToken;
  DeepLinkHandler? _deepLinkHandler;
  final Set<String> _seenIds = <String>{};

  static const Duration _pollInterval = Duration(seconds: 30);

  Future<void> init({DeepLinkHandler? onDeepLink}) async {
    if (_initialized) {
      if (onDeepLink != null) _deepLinkHandler = onDeepLink;
      return;
    }
    _initialized = true;
    _deepLinkHandler = onDeepLink;

    // Local notifications plugin — platform channels, deep-link tap callback.
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localPlugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Android 8+ verlangt einen Notification-Channel bevor `show()` läuft.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _localPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);

      final status = await Permission.notification.status;
      if (status.isDenied) {
        await Permission.notification.request();
      }
    }

    // Firebase (FCM) — fail-safe: App läuft weiter auch ohne Config.
    await _initFirebase();

    // Immediate-register + Polling, falls bereits ein User eingeloggt ist.
    final client = Supabase.instance.client;
    if (client.auth.currentUser != null) {
      unawaited(_registerSubscription(client.auth.currentUser!.id));
      _startPolling();
    }
    _authSub = client.auth.onAuthStateChange.listen((state) {
      final user = state.session?.user;
      if (user != null) {
        unawaited(_registerSubscription(user.id));
        _startPolling();
      } else {
        _stopPolling();
      }
    });

    WidgetsBinding.instance.addObserver(this);

    // War die App aus einer Notification geöffnet worden? Dann Deep-Link jetzt
    // verfolgen (getInitialMessage gibt die Message zurück, die die App
    // gestartet hat).
    if (_firebaseReady) {
      unawaited(_handleInitialFcmMessage());
    }
  }

  Future<void> _initFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      final fcm = FirebaseMessaging.instance;

      // iOS / Android 13+ Permission via FCM-Flow (zusätzlich zu
      // permission_handler, falls auf iOS gelaufen).
      await fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Wichtig für iOS: erst nach `requestPermission` kommt APNs-Token + FCM.
      await fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _fcmForegroundSub = FirebaseMessaging.onMessage.listen(_onFcmForeground);
      _fcmOpenedSub =
          FirebaseMessaging.onMessageOpenedApp.listen(_onFcmOpenedApp);
      _fcmTokenSub = fcm.onTokenRefresh.listen((token) {
        _fcmToken = token;
        final uid = Supabase.instance.client.auth.currentUser?.id;
        if (uid != null) unawaited(_registerSubscription(uid));
      });

      _fcmToken = await fcm.getToken();
      _firebaseReady = _fcmToken != null;
      if (kDebugMode) {
        debugPrint(
            '🔔 FCM ready=${_firebaseReady} token=${_fcmToken?.substring(0, 16) ?? "null"}…');
      }
    } catch (e) {
      _firebaseReady = false;
      if (kDebugMode) {
        debugPrint('⚠️ Firebase init skipped: $e');
      }
    }
  }

  Future<void> _handleInitialFcmMessage() async {
    try {
      final msg = await FirebaseMessaging.instance.getInitialMessage();
      if (msg != null) _onFcmOpenedApp(msg);
    } catch (_) {
      // No-op.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Drain the queue immediately on resume — users expect to see new messages
    // that piled up while the app was backgrounded.
    if (state == AppLifecycleState.resumed) {
      _pollOnce();
    }
  }

  Future<void> _registerSubscription(String userId) async {
    try {
      final payload = <String, dynamic>{
        'user_id': userId,
        'platform':
            defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      };
      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        payload['fcm_token'] = _fcmToken;
        payload['endpoint'] = 'fcm:$_fcmToken';
      } else {
        payload['endpoint'] = 'inapp-poll-$userId';
      }
      final res = await http
          .post(
            Uri.parse('${ApiConfig.workerUrl}/api/push/subscribe'),
            headers: const {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 10));
      if (kDebugMode) {
        debugPrint(
            '🔔 push subscribe → ${res.statusCode} fcm=${_fcmToken != null}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ push subscribe failed: $e');
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollOnce());
    _pollOnce(); // immediate first drain
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _pollOnce() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.workerUrl}/api/push/pending?user_id=$userId'),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;
      final body = json.decode(res.body);
      final list = body is Map
          ? (body['notifications'] as List? ?? const [])
          : (body is List ? body : const []);
      for (final item in list) {
        if (item is! Map) continue;
        final id = item['id']?.toString();
        if (id == null || !_seenIds.add(id)) continue;
        await _showLocal(Map<String, dynamic>.from(item));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ push poll failed: $e');
    }
  }

  Future<void> _showLocal(Map<String, dynamic> queueItem) async {
    final title = queueItem['title']?.toString() ?? 'Weltenbibliothek';
    final body = queueItem['body']?.toString() ?? '';
    final data = queueItem['data'];
    final payload = data is Map ? json.encode(data) : null;
    // Stable hash: queue UUID → 32-bit int
    final stableId = queueItem['id']?.toString().hashCode ??
        DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
    try {
      await _localPlugin.show(
        stableId,
        title,
        body,
        _notifDetails,
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ local notif show failed: $e');
    }
  }

  void _onFcmForeground(RemoteMessage message) {
    // FCM mit `notification`-Block rendert iOS / Android-System-Tray nicht wenn
    // App im Vordergrund ist → immer lokal zeichnen.
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'Weltenbibliothek';
    final body = message.notification?.body ??
        message.data['body']?.toString() ??
        '';
    final id = message.messageId?.hashCode ??
        DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
    final payload = message.data.isNotEmpty ? jsonEncode(message.data) : null;
    _localPlugin.show(id, title, body, _notifDetails, payload: payload);
  }

  void _onFcmOpenedApp(RemoteMessage message) {
    // User hat eine FCM-Notification getappt und die App dadurch geöffnet.
    if (message.data.isNotEmpty) {
      _deepLinkHandler?.call(Map<String, dynamic>.from(message.data));
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final data = json.decode(payload);
      if (data is Map) {
        _deepLinkHandler?.call(Map<String, dynamic>.from(data));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ notif tap payload parse failed: $e');
    }
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _authSub?.cancel();
    await _fcmForegroundSub?.cancel();
    await _fcmOpenedSub?.cancel();
    await _fcmTokenSub?.cancel();
    _stopPolling();
  }
}
