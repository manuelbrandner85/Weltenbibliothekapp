/// 🎤 WEBRTC SIGNALING SERVICE – Supabase Realtime Broadcast
///
/// Entscheidung: Supabase Realtime statt Cloudflare Worker WebSocket
/// Begründung:
///   - Cloudflare Workers unterstützen kein persistentes WebSocket-Server-Protokoll
///     für WebRTC Signaling (kein Durable Objects in diesem Plan)
///   - Supabase Realtime Broadcast ist kostenlos, stabil und bereits im Projekt aktiv
///   - Kein zusätzlicher Infrastrukturaufwand
///
/// Architektur:
///   - Channel: 'voice_signal:{roomId}'
///   - Events: 'offer', 'answer', 'ice-candidate', 'join', 'leave', 'mute'
///   - Presence: Teilnehmerliste live über Supabase Presence
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class WebRTCSignalingService {
  static final WebRTCSignalingService _instance = WebRTCSignalingService._internal();
  factory WebRTCSignalingService() => _instance;
  WebRTCSignalingService._internal();

  // ═══════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════

  RealtimeChannel? _signalingChannel;
  bool _isConnected = false;
  String? _currentRoomId;
  String? _currentUserId;
  String? _currentUsername;

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  bool get isConnected => _isConnected;
  String? get currentRoomId => _currentRoomId;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  // ═══════════════════════════════════════════════════════════
  // CONNECT – via Supabase Realtime Broadcast
  // ═══════════════════════════════════════════════════════════

  Future<void> connect() async {
    // Supabase Realtime ist immer "verbunden" wenn Supabase initialisiert ist
    _isConnected = true;
    if (kDebugMode) print('✅ WebRTC Signaling: Supabase Realtime bereit');
  }

  void disconnect() {
    _signalingChannel?.unsubscribe();
    _signalingChannel = null;
    _isConnected = false;
    _currentRoomId = null;
    _currentUserId = null;
    if (kDebugMode) print('🔌 WebRTC Signaling: getrennt');
  }

  // ═══════════════════════════════════════════════════════════
  // ROOM MANAGEMENT
  // ═══════════════════════════════════════════════════════════

  void joinRoom(String roomId, String userId, String username) {
    _currentRoomId = roomId;
    _currentUserId = userId;
    _currentUsername = username;

    // Alten Kanal schließen
    _signalingChannel?.unsubscribe();

    // Neuen Broadcast-Kanal für diesen Raum öffnen
    _signalingChannel = supabase
        .channel('voice_signal:$roomId')
        .onBroadcast(
          event: 'signal',
          callback: (payload) {
            final data = Map<String, dynamic>.from(payload);
            // Nur fremde Nachrichten verarbeiten
            if (data['senderId'] != userId) {
              if (kDebugMode) print('📥 Signal erhalten: ${data['type']} von ${data['senderId']}');
              _messageController.add(data);
            }
          },
        )
        .subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            _isConnected = true;
            if (kDebugMode) print('✅ Voice Signaling Kanal aktiv: $roomId');
            // Join-Event senden
            _broadcastSignal({'type': 'join', 'username': username});
          } else if (status == RealtimeSubscribeStatus.channelError) {
            _isConnected = false;
            if (kDebugMode) print('❌ Voice Signaling Fehler: $error');
          }
        });

    if (kDebugMode) print('🎤 Voice Signaling: Raum $roomId beigetreten als $username');
  }

  void leaveRoom() {
    if (_currentRoomId == null) return;
    _broadcastSignal({'type': 'leave'});
    _signalingChannel?.unsubscribe();
    _signalingChannel = null;
    _currentRoomId = null;
    _currentUserId = null;
    if (kDebugMode) print('🚪 Voice Signaling: Raum verlassen');
  }

  // ═══════════════════════════════════════════════════════════
  // SENDEN
  // ═══════════════════════════════════════════════════════════

  void sendMessage(Map<String, dynamic> message) {
    _broadcastSignal(message);
  }

  Future<void> _broadcastSignal(Map<String, dynamic> payload) async {
    if (_signalingChannel == null) return;
    try {
      await _signalingChannel!.sendBroadcastMessage(
        event: 'signal',
        payload: {
          ...payload,
          'senderId': _currentUserId ?? 'unknown',
          'senderName': _currentUsername ?? 'Anonym',
          'roomId': _currentRoomId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      if (kDebugMode) print('❌ Broadcast Fehler: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SDP / ICE HELPERS (für WebRTCVoiceService)
  // ═══════════════════════════════════════════════════════════

  void sendOffer(String targetUserId, Map<String, dynamic> sdp) {
    _broadcastSignal({'type': 'offer', 'targetId': targetUserId, 'sdp': sdp});
  }

  void sendAnswer(String targetUserId, Map<String, dynamic> sdp) {
    _broadcastSignal({'type': 'answer', 'targetId': targetUserId, 'sdp': sdp});
  }

  void sendIceCandidate(String targetUserId, Map<String, dynamic> candidate) {
    _broadcastSignal({'type': 'ice-candidate', 'targetId': targetUserId, 'candidate': candidate});
  }

  void sendMuteState(bool isMuted) {
    _broadcastSignal({'type': 'mute', 'isMuted': isMuted});
  }

  // ═══════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
