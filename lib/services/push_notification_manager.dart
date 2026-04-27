/// 🔔 Push Notification Manager — High-End (FCM + In-App Polling)
///
/// High-End Features (v2):
///   • 3 Android-Channels: wb_chat (HIGH), wb_social (DEFAULT), wb_system (LOW)
///   • BigTextStyleInformation — voller Text im Expanded-View
///   • Notification-Grouping per Raum (Chat) / Typ (Social)
///   • Stabile Notification-IDs: gleicher Raum = gleicher Slot (kein Stapeln)
///   • Zusammenfassungs-Notification wenn ≥ 2 aus gleichem Raum
///   • FCM + 30s-Polling Fallback
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

typedef DeepLinkHandler = void Function(Map<String, dynamic> data);

final FlutterLocalNotificationsPlugin _localPlugin =
    FlutterLocalNotificationsPlugin();

// ── Notification Channels ────────────────────────────────────────────────────

const _chatChannel = AndroidNotificationChannel(
  'wb_chat',
  'Chat & Erwähnungen',
  description: 'Nachrichten, Antworten und @Erwähnungen',
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
);

const _socialChannel = AndroidNotificationChannel(
  'wb_social',
  'Social',
  description: 'Likes, Kommentare und neue Follower',
  importance: Importance.defaultImportance,
  playSound: true,
);

const _systemChannel = AndroidNotificationChannel(
  'wb_system',
  'System & Achievements',
  description: 'Achievements, Updates und Systembenachrichtigungen',
  importance: Importance.low,
  playSound: false,
);

// ── Hilfsfunktionen für styled NotificationDetails ───────────────────────────

NotificationDetails _chatDetails({
  required String body,
  String? groupKey,
  String? summaryText,
  bool isGroupSummary = false,
}) {
  return NotificationDetails(
    android: AndroidNotificationDetails(
      'wb_chat',
      'Chat & Erwähnungen',
      channelDescription: 'Nachrichten, Antworten und @Erwähnungen',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: null,
        summaryText: summaryText,
      ),
      groupKey: groupKey,
      setAsGroupSummary: isGroupSummary,
      autoCancel: true,
      enableLights: true,
      color: const Color(0xFF7C4DFF),
    ),
    iOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      threadIdentifier: 'chat',
    ),
  );
}

NotificationDetails _socialDetails({
  required String body,
  bool isGroupSummary = false,
}) {
  return NotificationDetails(
    android: AndroidNotificationDetails(
      'wb_social',
      'Social',
      channelDescription: 'Likes, Kommentare und neue Follower',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      styleInformation: BigTextStyleInformation(body),
      groupKey: 'wb_social_group',
      setAsGroupSummary: isGroupSummary,
      autoCancel: true,
      color: const Color(0xFFE91E63),
    ),
    iOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
      threadIdentifier: 'social',
    ),
  );
}

NotificationDetails _systemDetails({required String body}) {
  return NotificationDetails(
    android: AndroidNotificationDetails(
      'wb_system',
      'System & Achievements',
      channelDescription: 'Achievements, Updates und Systembenachrichtigungen',
      importance: Importance.low,
      priority: Priority.low,
      styleInformation: BigTextStyleInformation(body),
      autoCancel: true,
      color: const Color(0xFFFFC107),
    ),
    iOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
      threadIdentifier: 'system',
    ),
  );
}

// ── FCM Background Handler (Top-Level, AOT-sicher) ───────────────────────────

@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    if (kDebugMode) debugPrint('⚠️ fcmBackgroundHandler Firebase.initializeApp: $e');
  }
  if (message.notification == null) {
    final data = message.data;
    final title = data['title']?.toString() ?? 'Weltenbibliothek';
    final body = data['body']?.toString() ?? '';
    final id = message.messageId?.hashCode ??
        DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
    final type = data['type']?.toString() ?? '';
    try {
      await _localPlugin.show(
        id,
        title,
        body,
        _notifDetailsForType(type, body),
        payload: jsonEncode(data),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ fcmBackgroundHandler localPlugin.show: $e');
    }
  }
}

NotificationDetails _notifDetailsForType(String type, String body) {
  switch (type) {
    case 'chat_message':
    case 'mention':
    case 'reply':
      return _chatDetails(body: body);
    case 'achievement':
    case 'system':
      return _systemDetails(body: body);
    default:
      return _socialDetails(body: body);
  }
}

// ── PushNotificationManager ──────────────────────────────────────────────────

class PushNotificationManager with WidgetsBindingObserver {
  PushNotificationManager._();
  static final PushNotificationManager instance = PushNotificationManager._();

  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<RemoteMessage>? _fcmForegroundSub;
  StreamSubscription<RemoteMessage>? _fcmOpenedSub;
  StreamSubscription<String>? _fcmTokenSub;
  Timer? _pollTimer;
  Timer? _healthCheckTimer;
  bool _initialized = false;
  bool _firebaseReady = false;
  bool _subscribed = false;
  String? _fcmToken;
  DeepLinkHandler? _deepLinkHandler;
  final Set<String> _seenIds = <String>{};

  // Gruppen-Zähler: roomId/type → Anzahl angezeigter Notifications
  final Map<String, int> _groupCounts = {};

  static const Duration _pollInterval = Duration(seconds: 30);

  Future<void> init({DeepLinkHandler? onDeepLink}) async {
    if (_initialized) {
      if (onDeepLink != null) _deepLinkHandler = onDeepLink;
      return;
    }
    _initialized = true;
    _deepLinkHandler = onDeepLink;

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

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final impl = _localPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await impl?.createNotificationChannel(_chatChannel);
      await impl?.createNotificationChannel(_socialChannel);
      await impl?.createNotificationChannel(_systemChannel);

      final status = await Permission.notification.status;
      if (status.isDenied) await Permission.notification.request();
    }

    await _initFirebase();

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

    if (_firebaseReady) unawaited(_handleInitialFcmMessage());
  }

  Future<void> _initFirebase() async {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      final fcm = FirebaseMessaging.instance;
      await fcm.requestPermission(alert: true, badge: true, sound: true);
      await fcm.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true,
      );
      _fcmForegroundSub = FirebaseMessaging.onMessage.listen(_onFcmForeground);
      _fcmOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(_onFcmOpenedApp);
      _fcmTokenSub = fcm.onTokenRefresh.listen((token) {
        _fcmToken = token;
        final uid = Supabase.instance.client.auth.currentUser?.id;
        if (uid != null) unawaited(_registerSubscription(uid));
      });
      _fcmToken = await fcm.getToken();
      _firebaseReady = _fcmToken != null;
      if (kDebugMode) {
        debugPrint('🔔 FCM ready=$_firebaseReady token=${_fcmToken?.substring(0, 16) ?? "null"}…');
      }
    } catch (e) {
      _firebaseReady = false;
      if (kDebugMode) debugPrint('⚠️ Firebase init skipped: $e');
    }
  }

  Future<void> _handleInitialFcmMessage() async {
    try {
      final msg = await FirebaseMessaging.instance.getInitialMessage();
      if (msg != null) _onFcmOpenedApp(msg);
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _pollOnce();
      // Falls Subscribe initial gescheitert ist → beim Resume nochmal versuchen.
      if (!_subscribed) {
        final uid = Supabase.instance.client.auth.currentUser?.id;
        if (uid != null) unawaited(_registerSubscription(uid));
      }
    }
  }

  Future<void> _registerSubscription(String userId, {int retry = 0}) async {
    try {
      final payload = <String, dynamic>{
        'user_id': userId,
        'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      };
      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        payload['fcm_token'] = _fcmToken;
        payload['endpoint'] = 'fcm:$_fcmToken';
      } else {
        payload['endpoint'] = 'inapp-poll-$userId';
      }
      final res = await http.post(
        Uri.parse('${ApiConfig.workerUrl}/api/push/subscribe'),
        headers: const {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 10));
      if (kDebugMode) {
        debugPrint('🔔 push subscribe → ${res.statusCode} fcm=${_fcmToken != null} retry=$retry');
      }
      if (res.statusCode >= 200 && res.statusCode < 300) {
        _subscribed = true;
        return;
      }
      // Server-Fehler → Retry mit exponentiellem Backoff (max. 3 Versuche)
      if (retry < 3) {
        final delay = Duration(seconds: 2 << retry); // 2s, 4s, 8s
        await Future.delayed(delay);
        return _registerSubscription(userId, retry: retry + 1);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ push subscribe failed (retry=$retry): $e');
      if (retry < 3) {
        final delay = Duration(seconds: 2 << retry);
        await Future.delayed(delay);
        return _registerSubscription(userId, retry: retry + 1);
      }
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollOnce());
    _pollOnce();

    // Health-Check: alle 5 Minuten verifizieren dass die Subscription
    // beim Worker registriert ist. Heilt automatisch wenn Subscribe
    // beim Login-Time fehlgeschlagen war (Netzwerk/DNS/Timeout).
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _verifyAndHealSubscription(),
    );
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    _subscribed = false;
  }

  /// Verifiziert via /api/push/debug ob eine aktive Subscription existiert.
  /// Falls nicht → erneute Registrierung. Schützt vor "Push silent broken"-
  /// Fällen (z.B. wenn Subscribe beim ersten App-Start gefailt ist).
  Future<void> _verifyAndHealSubscription() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.workerUrl}/api/push/debug?user_id=$uid'),
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return;
      final body = json.decode(res.body);
      final subs = body is Map ? (body['subscriptions'] as List? ?? []) : [];
      final hasActive = subs.any((s) => s is Map && s['is_active'] == true);
      if (!hasActive) {
        if (kDebugMode) debugPrint('🩹 push: keine aktive Subscription → re-register');
        _subscribed = false;
        await _registerSubscription(uid);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ push health-check failed: $e');
    }
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

  // ── High-End Notification anzeigen ──────────────────────────────────────────

  Future<void> _showLocal(Map<String, dynamic> item) async {
    final title = item['title']?.toString() ?? 'Weltenbibliothek';
    final body = item['body']?.toString() ?? '';
    final dataRaw = item['data'];
    final data = dataRaw is Map ? Map<String, dynamic>.from(dataRaw) : <String, dynamic>{};
    final type = data['type']?.toString() ?? '';
    final roomId = data['room_id']?.toString();
    final payload = data.isNotEmpty ? json.encode(data) : null;

    try {
      switch (type) {
        case 'chat_message':
        case 'mention':
        case 'reply':
          await _showChatNotification(title, body, roomId, data, payload);
          break;
        case 'achievement':
        case 'system':
          await _showSystemNotification(title, body, data, payload);
          break;
        default:
          await _showSocialNotification(title, body, data, payload);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ local notif show failed: $e');
    }
  }

  Future<void> _showChatNotification(
    String title,
    String body,
    String? roomId,
    Map<String, dynamic> data,
    String? payload,
  ) async {
    // Stabile ID: gleicher Raum → gleicher Notification-Slot
    final groupKey = 'wb_chat_${roomId ?? "general"}';
    final notifId = groupKey.hashCode & 0x7FFFFFFF;
    final count = (_groupCounts[groupKey] ?? 0) + 1;
    _groupCounts[groupKey] = count;

    // Einzelne Notification
    await _localPlugin.show(
      notifId,
      title,
      body,
      _chatDetails(
        body: body,
        groupKey: groupKey,
        summaryText: count > 1 ? '$count neue Nachrichten' : null,
      ),
      payload: payload,
    );

    // Gruppen-Zusammenfassung ab 2 Nachrichten (Android)
    if (count >= 2 && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final summaryId = (groupKey + '_summary').hashCode & 0x7FFFFFFF;
      await _localPlugin.show(
        summaryId,
        'Weltenbibliothek · Chat',
        '$count neue Nachrichten',
        _chatDetails(body: '$count neue Nachrichten', groupKey: groupKey, isGroupSummary: true),
        payload: payload,
      );
    }
  }

  Future<void> _showSocialNotification(
    String title,
    String body,
    Map<String, dynamic> data,
    String? payload,
  ) async {
    final type = data['type']?.toString() ?? 'social';
    final notifId = (data['article_id']?.toString() ?? type).hashCode & 0x7FFFFFFF;
    final count = (_groupCounts['wb_social'] ?? 0) + 1;
    _groupCounts['wb_social'] = count;

    await _localPlugin.show(
      notifId,
      title,
      body,
      _socialDetails(body: body),
      payload: payload,
    );

    if (count >= 3 && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _localPlugin.show(
        'wb_social_summary'.hashCode & 0x7FFFFFFF,
        'Weltenbibliothek',
        '$count neue Aktivitäten',
        _socialDetails(body: '$count neue Aktivitäten', isGroupSummary: true),
        payload: payload,
      );
    }
  }

  Future<void> _showSystemNotification(
    String title,
    String body,
    Map<String, dynamic> data,
    String? payload,
  ) async {
    final notifId = (data['achievement_id']?.toString() ?? 'system_${DateTime.now().millisecondsSinceEpoch}')
        .hashCode & 0x7FFFFFFF;
    await _localPlugin.show(notifId, title, body, _systemDetails(body: body), payload: payload);
  }

  // ── FCM Foreground / Opened ──────────────────────────────────────────────────

  void _onFcmForeground(RemoteMessage message) {
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'Weltenbibliothek';
    final body = message.notification?.body ??
        message.data['body']?.toString() ??
        '';
    final type = message.data['type']?.toString() ?? '';
    final roomId = message.data['room_id']?.toString();
    final payload = message.data.isNotEmpty ? jsonEncode(message.data) : null;
    final data = Map<String, dynamic>.from(message.data);

    switch (type) {
      case 'chat_message':
      case 'mention':
      case 'reply':
        _showChatNotification(title, body, roomId, data, payload);
        break;
      case 'achievement':
      case 'system':
        _showSystemNotification(title, body, data, payload);
        break;
      default:
        _showSocialNotification(title, body, data, payload);
    }
  }

  void _onFcmOpenedApp(RemoteMessage message) {
    if (message.data.isNotEmpty) {
      _deepLinkHandler?.call(Map<String, dynamic>.from(message.data));
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final data = json.decode(payload);
      if (data is Map) _deepLinkHandler?.call(Map<String, dynamic>.from(data));
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

  /// Public API: erlaubt UI (z.B. Profile-Settings) eine sofortige
  /// Re-Registrierung anzustoßen, falls der User Push-Probleme meldet.
  Future<void> forceResubscribe() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    _subscribed = false;
    await _registerSubscription(uid);
  }
}
