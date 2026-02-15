/// 🎤 DEDICATED WEBRTC SIGNALING SERVICE
/// 
/// Cloudflare Worker Backend v3.2 Integration
/// Dedizierter WebSocket-Kanal für WebRTC Signaling
/// 
/// Features:
/// - WebSocket-basierte WebRTC Signaling
/// - Auto-Reconnect
/// - Heartbeat System
/// - Room Management
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';

class WebRTCSignalingService {
  static final WebRTCSignalingService _instance = WebRTCSignalingService._internal();
  factory WebRTCSignalingService() => _instance;
  WebRTCSignalingService._internal();

  // ═══════════════════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════════════════

  WebSocketChannel? _channel;
  bool _isConnected = false;
  String? _currentRoomId;
  String? _currentUserId;

  // Reconnect
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const List<int> _reconnectDelays = [1, 2, 4, 8, 16]; // seconds
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  // Stream Controllers
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  // ═══════════════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════════════

  bool get isConnected => _isConnected;
  String? get currentRoomId => _currentRoomId;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  // ═══════════════════════════════════════════════════════════════════════
  // CONNECTION
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> connect() async {
    if (_isConnected) {
      if (kDebugMode) print('✅ WebRTC Signaling already connected');
      return;
    }

    try {
      if (kDebugMode) {
        print('🔌 Connecting to WebRTC Signaling...');
        print('📍 URL: ${ApiConfig.webrtcSignalingUrl}');
      }

      _channel = WebSocketChannel.connect(
        Uri.parse(ApiConfig.webrtcSignalingUrl),
      );

      // Listen to messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      _isConnected = true;
      _reconnectAttempts = 0;

      if (kDebugMode) print('✅ WebRTC Signaling connected');

      // Start heartbeat
      _startHeartbeat();
    } catch (e) {
      if (kDebugMode) print('❌ Failed to connect to WebRTC Signaling: $e');
      _scheduleReconnect();
    }
  }

  void disconnect() {
    if (kDebugMode) print('🔌 Disconnecting WebRTC Signaling...');

    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    _currentRoomId = null;
    _currentUserId = null;

    if (kDebugMode) print('✅ WebRTC Signaling disconnected');
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ROOM MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════

  void joinRoom(String roomId, String userId, String username) {
    _currentRoomId = roomId;
    _currentUserId = userId;

    sendMessage({
      'type': 'join',
      'roomId': roomId,
      'userId': userId,
      'username': username,
    });

    if (kDebugMode) {
      print('🎤 Joining WebRTC room: $roomId as $userId ($username)');
    }
  }

  void leaveRoom() {
    if (_currentRoomId == null) return;

    sendMessage({
      'type': 'leave',
    });

    if (kDebugMode) print('🚪 Leaving WebRTC room: $_currentRoomId');

    _currentRoomId = null;
    _currentUserId = null;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MESSAGE HANDLING
  // ═══════════════════════════════════════════════════════════════════════

  void sendMessage(Map<String, dynamic> message) {
    if (!_isConnected || _channel == null) {
      if (kDebugMode) print('⚠️ Cannot send message: not connected');
      return;
    }

    try {
      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);

      if (kDebugMode && message['type'] != 'pong') {
        print('📤 Sent: ${message['type']}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Failed to send message: $e');
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      if (kDebugMode && type != 'ping') {
        print('📥 Received: $type');
      }

      // Handle ping/pong
      if (type == 'ping') {
        sendMessage({'type': 'pong'});
        return;
      }

      // Broadcast to listeners
      _messageController.add(data);
    } catch (e) {
      if (kDebugMode) print('❌ Error handling message: $e');
    }
  }

  void _handleError(error) {
    if (kDebugMode) print('❌ WebRTC Signaling error: $error');
    _isConnected = false;
    _scheduleReconnect();
  }

  void _handleDisconnect() {
    if (kDebugMode) print('🔌 WebRTC Signaling disconnected');
    _isConnected = false;
    _scheduleReconnect();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // RECONNECT
  // ═══════════════════════════════════════════════════════════════════════

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      if (kDebugMode) {
        print('❌ Max reconnect attempts reached. Giving up.');
      }
      return;
    }

    _reconnectTimer?.cancel();

    final delayIndex = _reconnectAttempts < _reconnectDelays.length
        ? _reconnectAttempts
        : _reconnectDelays.length - 1;
    final delay = Duration(seconds: _reconnectDelays[delayIndex]);

    if (kDebugMode) {
      print('🔄 Scheduling reconnect in ${delay.inSeconds}s (attempt ${_reconnectAttempts + 1}/$_maxReconnectAttempts)');
    }

    _reconnectTimer = Timer(delay, () async {
      _reconnectAttempts++;
      await connect();

      // Re-join room if we were in one
      if (_isConnected && _currentRoomId != null && _currentUserId != null) {
        if (kDebugMode) print('🔄 Re-joining room: $_currentRoomId');
        joinRoom(_currentRoomId!, _currentUserId!, 'User'); // TODO: Store username
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HEARTBEAT
  // ═══════════════════════════════════════════════════════════════════════

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();

    // Server sends ping every 15s, we just respond with pong
    // No need to send our own pings
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════════════

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
