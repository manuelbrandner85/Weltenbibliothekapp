/// 🎙️ MENTOR LIVEKIT SERVICE — Audio-only LiveKit rooms for mentor sessions.
///
/// Provides a simplified LiveKit wrapper for one-on-one mentor audio sessions.
/// Token fetch reuses the same Cloudflare Worker endpoint as group calls
/// ([ApiConfig.livekitTokenUrl] = /api/livekit/token).
///
/// Room naming convention: `mentor-{world}-{guestId}` — ensures each user
/// gets a private room so mentor responses stay isolated.
///
/// State is exposed via [ChangeNotifier] so the session screen can rebuild on
/// connect/disconnect/error without heavy Provider setup.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' show Random;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/api_config.dart';

/// Connection states for the mentor LiveKit session.
enum MentorLiveKitState { disconnected, connecting, connected, error }

class MentorLiveKitService extends ChangeNotifier {
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  MentorLiveKitState _state = MentorLiveKitState.disconnected;
  String? _errorMessage;
  bool _micMuted = false;
  String? _currentRoomName;

  MentorLiveKitState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get micMuted => _micMuted;
  bool get isConnected => _state == MentorLiveKitState.connected;
  String? get currentRoomName => _currentRoomName;

  // ── Connect ────────────────────────────────────────────────────────────────

  /// Joins an audio-only mentor room for [world].
  /// Throws a German-language exception on failure.
  Future<void> connect(String world) async {
    if (!ApiConfig.isLivekitEnabled) {
      throw Exception(
        'Sprach-Verbindung nicht konfiguriert (LIVEKIT_URL fehlt).',
      );
    }
    if (_state == MentorLiveKitState.connected ||
        _state == MentorLiveKitState.connecting) {
      return;
    }

    _setState(MentorLiveKitState.connecting);
    _errorMessage = null;

    try {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        throw Exception(
          'Mikrofon-Berechtigung fehlt. Bitte in den App-Einstellungen erlauben.',
        );
      }

      final guestId = await _getOrCreateGuestId();
      final roomName = 'mentor-$world-$guestId';
      _currentRoomName = roomName;

      final token = await _fetchToken(roomName, 'Mentor-Session');

      final room = Room(
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          defaultAudioCaptureOptions: AudioCaptureOptions(
            noiseSuppression: true,
            echoCancellation: true,
            autoGainControl: true,
            highPassFilter: true,
          ),
        ),
      );

      final listener = room.createListener();
      listener
        ..on<RoomDisconnectedEvent>((_) {
          if (_state != MentorLiveKitState.disconnected) {
            _setState(MentorLiveKitState.disconnected);
          }
        })
        ..on<RoomReconnectedEvent>((_) {
          _setState(MentorLiveKitState.connected);
        });

      await room.connect(ApiConfig.livekitUrl, token);
      // Enable mic after connect (audio-only session).
      await room.localParticipant?.setMicrophoneEnabled(true);

      _room = room;
      _listener = listener;
      _micMuted = false;
      _setState(MentorLiveKitState.connected);
    } catch (e) {
      _errorMessage = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : e.toString();
      _setState(MentorLiveKitState.error);
      rethrow;
    }
  }

  // ── Disconnect ─────────────────────────────────────────────────────────────

  Future<void> disconnect() async {
    await _listener?.dispose();
    _listener = null;
    await _room?.disconnect();
    _room = null;
    _currentRoomName = null;
    _micMuted = false;
    _setState(MentorLiveKitState.disconnected);
  }

  // ── Mic toggle ─────────────────────────────────────────────────────────────

  Future<void> toggleMic() async {
    final room = _room;
    if (room == null || _state != MentorLiveKitState.connected) return;
    _micMuted = !_micMuted;
    await room.localParticipant?.setMicrophoneEnabled(!_micMuted);
    notifyListeners();
  }

  // ── Token fetch ────────────────────────────────────────────────────────────

  Future<String> _fetchToken(String roomName, String displayName) async {
    final session = Supabase.instance.client.auth.currentSession;
    final bearerToken = session?.accessToken ?? ApiConfig.supabaseAnonKey;

    final res = await http
        .post(
          Uri.parse(ApiConfig.livekitTokenUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $bearerToken',
            'apikey': ApiConfig.supabaseAnonKey,
          },
          body: jsonEncode({
            'roomName': roomName,
            'displayName': displayName,
            'clientGuestId': await _getOrCreateGuestId(),
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      String msg = 'Token-Fehler (${res.statusCode})';
      try {
        final body = jsonDecode(res.body);
        if (body is Map && body['error'] is String) {
          msg = body['error'] as String;
        }
      } catch (_) {}
      throw Exception(msg);
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Server lieferte kein gueltiges Token.');
    }
    return token;
  }

  // ── Guest ID ──────────────────────────────────────────────────────────────

  Future<String> _getOrCreateGuestId() async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'mentor_lk_guest_id';
    var id = prefs.getString(key);
    if (id == null || id.isEmpty) {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final rnd = Random().nextInt(0x10000).toRadixString(16).padLeft(4, '0');
      id = 'mlk-$ts-$rnd';
      await prefs.setString(key, id);
    }
    return id;
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _setState(MentorLiveKitState s) {
    if (_state == s) return;
    _state = s;
    if (kDebugMode) debugPrint('[MentorLiveKit] state -> $s');
    notifyListeners();
  }

  @override
  void dispose() {
    _listener?.dispose();
    _room?.disconnect();
    super.dispose();
  }
}
