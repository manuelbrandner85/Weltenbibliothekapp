/// 🎙️ RecordingService — LiveKit Egress Recording
///
/// Startet/stoppt eine Room-Composite-Aufnahme via Cloudflare Worker
/// → LiveKit Egress API. Der Worker signiert den Admin-JWT und leitet
/// die Anfrage an den LiveKit-Server weiter.
///
/// State-Flow: idle → starting → recording → stopping → idle
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/api_config.dart';

enum RecordingState { idle, starting, recording, stopping, error }

class RecordingService {
  RecordingService._();
  static final instance = RecordingService._();

  final stateNotifier = ValueNotifier<RecordingState>(RecordingState.idle);
  String? _egressId;
  String? _errorMessage;

  RecordingState get state => stateNotifier.value;
  bool get isRecording => state == RecordingState.recording;
  String? get errorMessage => _errorMessage;

  void reset() {
    _egressId = null;
    _errorMessage = null;
    stateNotifier.value = RecordingState.idle;
  }

  Future<void> startRecording(String roomName) async {
    if (state != RecordingState.idle && state != RecordingState.error) return;
    stateNotifier.value = RecordingState.starting;

    try {
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken ?? ApiConfig.supabaseAnonKey;

      final res = await http.post(
        Uri.parse('${ApiConfig.workerUrl}/api/livekit/recording/start'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'apikey': ApiConfig.supabaseAnonKey,
        },
        body: jsonEncode({'roomName': roomName}),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        _egressId = body['egressId']?.toString();
        _errorMessage = null;
        stateNotifier.value = RecordingState.recording;
      } else {
        final body = jsonDecode(res.body) as Map<String, dynamic>? ?? {};
        _errorMessage = body['error']?.toString() ?? 'Fehler ${res.statusCode}';
        stateNotifier.value = RecordingState.error;
      }
    } catch (e) {
      _errorMessage = 'Verbindungsfehler: $e';
      stateNotifier.value = RecordingState.error;
    }
  }

  Future<void> stopRecording() async {
    if (state != RecordingState.recording) return;
    stateNotifier.value = RecordingState.stopping;

    try {
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken ?? ApiConfig.supabaseAnonKey;

      final res = await http.post(
        Uri.parse('${ApiConfig.workerUrl}/api/livekit/recording/stop'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'apikey': ApiConfig.supabaseAnonKey,
        },
        body: jsonEncode({'egressId': _egressId}),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200 || res.statusCode == 204) {
        _egressId = null;
        _errorMessage = null;
        stateNotifier.value = RecordingState.idle;
      } else {
        final body = jsonDecode(res.body) as Map<String, dynamic>? ?? {};
        _errorMessage = body['error']?.toString() ?? 'Fehler ${res.statusCode}';
        stateNotifier.value = RecordingState.error;
      }
    } catch (e) {
      _errorMessage = 'Verbindungsfehler: $e';
      stateNotifier.value = RecordingState.error;
    }
  }
}
