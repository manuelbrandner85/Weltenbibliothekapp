/// 🔔 Push Notification Manager
///
/// Koordiniert den kompletten In-App-Push-Stack:
///   1. Auto-Register auf Supabase `push_subscriptions` sobald ein User eingeloggt
///      ist (onAuthStateChange.signedIn / initialSession).
///   2. Periodisches Polling von `/api/push/pending?user_id=UUID` während die App
///      offen ist, konsumiert die Queue-Einträge und zeigt sie als lokale
///      `flutter_local_notifications` an.
///   3. Deep-Link-Handler: Tap auf eine Notification öffnet
///      `/chat/:world/:room` oder `/post/:id` via globalem NavigatorKey.
///
/// Background-Zustellung (App komplett zu) liegt außerhalb dieser Klasse — dafür
/// braucht es einen echten FCM-Push-Sender. Solange der Dispatcher auf dem Worker
/// noch `sent`-markiert ohne FCM-Call, sieht der User Queue-Einträge erst beim
/// nächsten App-Öffnen. Das ist bewusst so (D3 "Phase C reicht").
library;

import 'dart:async';
import 'dart:convert';
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

class PushNotificationManager with WidgetsBindingObserver {
  PushNotificationManager._();
  static final PushNotificationManager instance = PushNotificationManager._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<AuthState>? _authSub;
  Timer? _pollTimer;
  bool _initialized = false;
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
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Runtime permission (Android 13+). iOS asks via init() already.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.status;
      if (status.isDenied) {
        await Permission.notification.request();
      }
    }

    // Register immediately if we already have a session, then react to future
    // auth changes (login/logout on a fresh install or token refresh).
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
      final res = await http.post(
        Uri.parse('${ApiConfig.workerUrl}/api/push/subscribe'),
        headers: const {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'endpoint': 'inapp-poll-$userId',
          'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        }),
      ).timeout(const Duration(seconds: 10));
      if (kDebugMode) {
        debugPrint('🔔 push subscribe → ${res.statusCode}');
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
    final stableId =
        queueItem['id']?.toString().hashCode ??
            DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
    try {
      await _plugin.show(
        stableId,
        title,
        body,
        const NotificationDetails(
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
        ),
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ local notif show failed: $e');
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
    _stopPolling();
  }
}
