// Web Push Notification Manager
//
// Strategie (v5.44.3): kein FCM Service Worker (waere extra Setup mit
// VAPID-Keys + firebase-messaging-sw.js). Stattdessen pragmatischer
// Polling-Ansatz + Browser-Notification-API.
//
// Trade-offs:
// - Notifications kommen NUR an wenn der Browser-Tab offen ist
//   (echtes Push erfordert Service Worker - separater Setup)
// - Latenz = poll interval (30s default, akzeptabel fuer In-App-Events)
// - Funktioniert ohne extra Backend-Konfig (nutzt /api/push/poll Endpoint)
//
// User-Permission-Flow:
// - Beim ersten init() wird Notification.requestPermission() gerufen
// - Bei "granted" zeigt jede neue Notification eine Browser-Notification
// - Bei "denied" bleibt der in-app DeepLinkHandler weiter aktiv
//   (notifications-Stream geht intern weiter, nur kein OS-Banner)

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart' show RemoteMessage;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;

import '../config/api_config.dart';

typedef DeepLinkHandler = void Function(Map<String, dynamic> data);

// ignore: avoid_returning_null_for_void
Future<void> fcmBackgroundHandler(RemoteMessage message) async {}

class PushNotificationManager {
  PushNotificationManager._();
  static final PushNotificationManager instance = PushNotificationManager._();

  static const _pollInterval = Duration(seconds: 30);
  static const _kSeenIdsKey = 'web_push_seen_ids_v1';

  Timer? _pollTimer;
  DeepLinkHandler? _onDeepLink;
  final Set<String> _seenIds = <String>{};
  bool _initialized = false;
  bool _notifPermissionGranted = false;

  Future<void> init({DeepLinkHandler? onDeepLink}) async {
    if (_initialized) return;
    _initialized = true;
    _onDeepLink = onDeepLink;

    // Load previously-seen notification IDs (avoid double-display on reload)
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_kSeenIdsKey) ?? const [];
      _seenIds.addAll(saved);
    } catch (_) {/* non-fatal */}

    // Request browser notification permission (graceful no-op if denied)
    await _requestPermission();

    // Subscribe with the worker so dispatch knows about this client
    await _subscribe();

    // Start polling
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollOnce());
    // Initial fetch
    unawaited(_pollOnce());
  }

  Future<void> _requestPermission() async {
    try {
      final permission = web.Notification.permission;
      if (permission == 'granted') {
        _notifPermissionGranted = true;
        return;
      }
      if (permission == 'denied') return;
      final result = await web.Notification.requestPermission().toDart;
      _notifPermissionGranted = result.toDart == 'granted';
    } catch (e) {
      if (kDebugMode) debugPrint('[WebPush] permission request failed: $e');
    }
  }

  String _webDeviceId() {
    // Stabile aber anonyme Device-ID via localStorage. Eine Browser-Profile-
    // Instanz = ein Device.
    try {
      const k = 'wb_web_device_id_v1';
      final existing = web.window.localStorage.getItem(k);
      if (existing != null && existing.isNotEmpty) return existing;
      final fresh =
          'web_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond)}';
      web.window.localStorage.setItem(k, fresh);
      return fresh;
    } catch (_) {
      return 'web_anon_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<void> _subscribe() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final deviceId = _webDeviceId();
      await http
          .post(
            Uri.parse('${ApiConfig.workerUrl}/api/push/subscribe'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': uid,
              'platform': 'web',
              'endpoint': 'web-poll://$deviceId',
              'fcm_token': deviceId,
              'device_info': {
                'userAgent': web.window.navigator.userAgent,
                'language': web.window.navigator.language,
              },
            }),
          )
          .timeout(const Duration(seconds: 8));

      // v5.44.3: zusaetzlich in user_devices (per Migration v91) registrieren
      // - bekommt die Web-Subscription auch in der dedizierten Device-Tabelle
      await http
          .post(
            Uri.parse('${ApiConfig.workerUrl}/api/devices/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'fcm_token': deviceId,
              'platform': 'web',
              'profile_id': uid,
              'device_model':
                  'Browser (${web.window.navigator.userAgent.substring(0, 40)})',
            }),
          )
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      if (kDebugMode) debugPrint('[WebPush] subscribe failed: $e');
    }
  }

  Future<void> _pollOnce() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final res = await http
          .get(
            Uri.parse(
                '${ApiConfig.workerUrl}/api/push/poll?user_id=$uid&limit=20'),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;
      final body = jsonDecode(res.body);
      final items = (body is Map ? body['notifications'] : null) ?? const [];
      if (items is! List) return;
      bool anyNew = false;
      for (final item in items) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        final id = (m['id'] ?? '').toString();
        if (id.isEmpty || _seenIds.contains(id)) continue;
        _seenIds.add(id);
        anyNew = true;
        _showWebNotification(m);
      }
      if (anyNew) {
        // Cap memory: keep last 200 IDs
        if (_seenIds.length > 200) {
          final keep = _seenIds.toList().sublist(_seenIds.length - 200);
          _seenIds
            ..clear()
            ..addAll(keep);
        }
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList(_kSeenIdsKey, _seenIds.toList());
        } catch (_) {/* non-fatal */}
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[WebPush] poll failed: $e');
    }
  }

  void _showWebNotification(Map<String, dynamic> notif) {
    final title = (notif['title'] ?? 'Weltenbibliothek').toString();
    final bodyText = (notif['body'] ?? notif['message'] ?? '').toString();
    final data = (notif['data'] is Map)
        ? Map<String, dynamic>.from(notif['data'] as Map)
        : <String, dynamic>{};

    // Browser-Banner nur wenn Permission granted und Page hidden ist
    // (sonst zeigt die App-eigene Toast-UI das Event ohnehin doppelt).
    if (_notifPermissionGranted && web.document.hidden) {
      try {
        final opts = web.NotificationOptions(
          body: bodyText,
          tag: (notif['id'] ?? '').toString(),
        );
        final n = web.Notification(title, opts);
        n.onclick = ((web.Event _) {
          // Fokus zurueck zur App + DeepLink-Handler triggern
          web.window.focus();
          _onDeepLink?.call(data);
          n.close();
        }).toJS;
      } catch (e) {
        if (kDebugMode) debugPrint('[WebPush] show notification failed: $e');
      }
    }

    // Deep-link Handler immer rufen (In-App-Anzeige laeuft via App-UI)
    _onDeepLink?.call(data);
  }

  Future<void> unsubscribeCurrent() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await http
          .post(
            Uri.parse('${ApiConfig.workerUrl}/api/push/unsubscribe'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_id': uid}),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {/* non-fatal */}
  }

  Future<void> forceResubscribe() async {
    await _subscribe();
  }

  Future<void> dispose() async {
    _pollTimer?.cancel();
    _pollTimer = null;
  }
}
