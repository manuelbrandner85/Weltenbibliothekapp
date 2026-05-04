/// 🎤 VoiceSessionService — Tracking aktiver LiveKit-Anrufe
///
/// Meldet Join/Leave-Events an den Cloudflare Worker.
/// Andere Chat-Screens können via Supabase Realtime die aktiven
/// Sessions abonnieren und einen Live-Banner zeigen.
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/api_config.dart';

class VoiceSessionService {
  VoiceSessionService._();
  static final instance = VoiceSessionService._();

  String? _currentSessionId;

  String? get currentSessionId => _currentSessionId;

  Future<void> joinSession({
    required String roomName,
    required String world,
    String? userId,
    String? username,
    String? displayName,
  }) async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken ?? ApiConfig.supabaseAnonKey;

      final res = await http
          .post(
            Uri.parse('${ApiConfig.workerUrl}/api/voice/session/join'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'roomName': roomName,
              'world': world,
              'userId': userId,
              'username': username ?? 'Unbekannt',
              'displayName': displayName ?? username ?? 'Unbekannt',
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body) as Map<String, dynamic>? ?? {};
        _currentSessionId = body['id']?.toString();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ VoiceSession join error: $e');
    }
  }

  Future<void> leaveSession({String? roomName, String? userId}) async {
    if (_currentSessionId == null && (roomName == null || userId == null)) return;
    try {
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken ?? ApiConfig.supabaseAnonKey;

      await http
          .post(
            Uri.parse('${ApiConfig.workerUrl}/api/voice/session/leave'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              if (_currentSessionId != null) 'sessionId': _currentSessionId,
              if (userId != null) 'userId': userId,
              if (roomName != null) 'roomName': roomName,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ VoiceSession leave error: $e');
    } finally {
      _currentSessionId = null;
    }
  }

  /// Gibt aktive Sessions für eine Welt zurück, gruppiert nach Raum.
  /// Format: { 'materie-politik': [{ username, displayName, joined_at }] }
  Future<Map<String, List<Map<String, dynamic>>>> getActiveSessions(
      String world) async {
    try {
      final anonKey = ApiConfig.supabaseAnonKey;
      final res = await http
          .get(
            Uri.parse(
                '${ApiConfig.workerUrl}/api/voice/sessions?world=${Uri.encodeComponent(world)}'),
            headers: {'Authorization': 'Bearer $anonKey'},
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) return {};
      final list = (jsonDecode(res.body) as List? ?? [])
          .cast<Map<String, dynamic>>();

      final result = <String, List<Map<String, dynamic>>>{};
      for (final s in list) {
        final room = s['room_name']?.toString() ?? '';
        result.putIfAbsent(room, () => []).add(s);
      }
      return result;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ VoiceSession list error: $e');
      return {};
    }
  }
}
