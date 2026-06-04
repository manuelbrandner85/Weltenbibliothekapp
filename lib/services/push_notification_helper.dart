// Push Notification Helper (v103).
//
// Central dispatcher for production push notifications. All app-side
// services (chat, achievement, admin actions, ...) call this helper
// instead of duplicating HTTP-POST-to-Worker logic. Fire-and-forget
// pattern: every call has a 10s timeout, returns bool, never throws.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'admin_auth_service.dart';

class PushNotificationHelper {
  PushNotificationHelper._();
  static final PushNotificationHelper instance = PushNotificationHelper._();

  static const Duration _timeout = Duration(seconds: 10);

  /// AUDIT-FIX B6: Fire-and-forget mit Logging. Vorher hat jeder Caller
  /// `.ignore()` benutzt -- Fehler verschwanden silent. Jetzt: bei Failure
  /// wird debugPrint mit context geloggt damit man im Adb-Log sieht warum
  /// ein Ban-Push z.B. nicht ankam.
  void fireAndForget(Future<bool> pushFuture, {String context = 'push'}) {
    pushFuture.then((ok) {
      if (!ok && kDebugMode) {
        debugPrint('⚠️ Push fire-and-forget failed: $context');
      }
    }).catchError((e) {
      if (kDebugMode)
        debugPrint('⚠️ Push fire-and-forget error ($context): $e');
    });
  }

  /// Sends a push to a single user identified by their backend user_id
  /// (UUID) or legacy InvisibleAuth-ID ("user_<ts>_<rand>"). Worker
  /// resolves both shapes and forwards to FCM.
  Future<bool> sendToUser({
    required String targetUserId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (targetUserId.trim().isEmpty) return false;
    final url = Uri.parse('${ApiConfig.workerUrl}/api/push/send-to-user');
    final payload = {
      'target_user_id': targetUserId,
      'type': type,
      'title': title,
      'body': body,
      'data': {
        ...?data,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    };
    try {
      // AUDIT-FIX A1: HMAC-Header fuer verifyAdminCaller
      final adminHeaders = await AdminAuthService.instance.headers();
      final res = await http
          .post(url,
              headers: {
                'Content-Type': 'application/json',
                ...adminHeaders,
              },
              body: jsonEncode(payload))
          .timeout(_timeout);
      if (res.statusCode == 200) return true;
      if (kDebugMode) {
        debugPrint(
            '⚠️ PushNotificationHelper.sendToUser HTTP ${res.statusCode}: ${res.body}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ PushNotificationHelper.sendToUser: $e');
      return false;
    }
  }

  /// Sends a push to every subscriber of [topic]. Topics are configured
  /// via CloudflarePushService.subscribeTopic.
  Future<bool> sendToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (topic.trim().isEmpty) return false;
    final url = Uri.parse('${ApiConfig.workerUrl}/api/push/send-to-topic');
    final payload = {
      'topic': topic,
      'title': title,
      'body': body,
      'data': {
        ...?data,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    };
    try {
      final adminHeaders = await AdminAuthService.instance.headers();
      final res = await http
          .post(url,
              headers: {
                'Content-Type': 'application/json',
                ...adminHeaders,
              },
              body: jsonEncode(payload))
          .timeout(_timeout);
      if (res.statusCode == 200) return true;
      if (kDebugMode) {
        debugPrint(
            '⚠️ PushNotificationHelper.sendToTopic HTTP ${res.statusCode}: ${res.body}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ PushNotificationHelper.sendToTopic: $e');
      return false;
    }
  }

  /// Broadcasts a push to ALL users. Use sparingly -- admin only.
  /// adminUsername lands in admin_audit_log for traceability.
  Future<bool> sendBroadcast({
    required String title,
    required String body,
    String? adminUsername,
    Map<String, dynamic>? data,
  }) async {
    final url = Uri.parse('${ApiConfig.workerUrl}/api/push/broadcast');
    final payload = {
      'title': title,
      'body': body,
      'admin': adminUsername ?? 'system',
      'data': {
        ...?data,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    };
    try {
      final adminHeaders = await AdminAuthService.instance.headers();
      final res = await http
          .post(url,
              headers: {
                'Content-Type': 'application/json',
                ...adminHeaders,
              },
              body: jsonEncode(payload))
          .timeout(_timeout);
      if (res.statusCode == 200) return true;
      if (kDebugMode) {
        debugPrint(
            '⚠️ PushNotificationHelper.sendBroadcast HTTP ${res.statusCode}: ${res.body}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ PushNotificationHelper.sendBroadcast: $e');
      return false;
    }
  }
}
