// LiveKit-Moderation — Mute/Kick via Worker.
//
// Sends authenticated requests to the Worker which holds the LiveKit
// API secret. The Worker re-validates the caller's role against
// profiles.role server-side, so the client cannot escalate.
//
// Allowed roles: root_admin | admin | moderator.

import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

enum LiveKitModerationAction { mute, unmute, kick }

// Result-Klasse statt Named-Record (dart2js-Bug mit nullable named records).
class LiveKitModerationResult {
  final bool ok;
  final String? error;
  const LiveKitModerationResult(this.ok, this.error);
}

class LiveKitModerationService {
  static const _timeout = Duration(seconds: 10);

  static Future<LiveKitModerationResult> moderate({
    required String roomName,
    required String identity,
    required LiveKitModerationAction action,
    required String adminUsername,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.workerUrl}/api/livekit/moderate'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'roomName': roomName,
              'identity': identity,
              'action': action.name,
              'adminUsername': adminUsername,
            }),
          )
          .timeout(_timeout);

      final body = jsonDecode(res.body) as Map<String, dynamic>? ?? const {};
      if (res.statusCode == 200 && body['success'] == true) {
        return const LiveKitModerationResult(true, null);
      }
      final msg = (body['error'] as String?) ?? 'HTTP ${res.statusCode}';
      if (kDebugMode) debugPrint('⚠️ LiveKit moderate failed: $msg');
      return LiveKitModerationResult(false, msg);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ LiveKit moderate exception: $e');
      return LiveKitModerationResult(false, e.toString());
    }
  }
}
