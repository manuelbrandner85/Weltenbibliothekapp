import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

/// ═══════════════════════════════════════════════════════════════
/// WEBSOCKET SERVICE - Weltenbibliothek
/// ═══════════════════════════════════════════════════════════════
/// Real-Time WebSocket-Verbindung zu Cloudflare Durable Objects
/// Features:
/// - Live Chat-Nachrichten
/// - Typing-Indicators
/// - Online-Status
/// - Auto-Reconnect
/// - Heartbeat/Ping-Pong
/// ═══════════════════════════════════════════════════════════════

enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class ChatMessage {
  final String messageId;
  final String username;
  final String message;
  final int timestamp;
  final String? avatarUrl;

  ChatMessage({
    required this.messageId,
    required this.username,
    required this.message,
    required this.timestamp,
    this.avatarUrl,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['message_id'] as String? ?? '',
      username: json['username'] as String,
      message: json['message'] as String,
      timestamp: json['timestamp'] as int,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);
}

class WebSocketService {
  final AuthService _authService = AuthService();

  // Singleton pattern
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  // WebSocket connection
  WebSocketChannel? _channel;
  WebSocketConnectionState _state = WebSocketConnectionState.disconnected;

  // Room information
  String? _currentRoomId;
  String? _currentUsername;

  // Stream controllers
  final _messageController = StreamController<ChatMessage>.broadcast();
  final _stateController =
      StreamController<WebSocketConnectionState>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _onlineUsersController = StreamController<List<String>>.broadcast();

  // Reconnection
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  // Getters
  Stream<ChatMessage> get messageStream => _messageController.stream;
  Stream<WebSocketConnectionState> get stateStream => _stateController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Stream<List<String>> get onlineUsersStream => _onlineUsersController.stream;
  WebSocketConnectionState get state => _state;
  bool get isConnected => _state == WebSocketConnectionState.connected;

  // ═══════════════════════════════════════════════════════════════
  // CONNECT TO ROOM
  // ═══════════════════════════════════════════════════════════════

  Future<void> connectToRoom(String roomId) async {
    try {
      // Get current user
      final user = await _authService.getCurrentUser();
      if (user == null) {
        throw Exception('Nicht authentifiziert');
      }

      _currentUsername = user['username'] as String;
      _currentRoomId = roomId;

      _updateState(WebSocketConnectionState.connecting);

      // WebSocket URL: wss://weltenbibliothek-backend.brandy13062.workers.dev/ws/ROOM_ID
      final wsUrl = AuthService.baseUrl.replaceFirst('https://', 'wss://');
      final uri = Uri.parse('$wsUrl/ws/$roomId');

      if (kDebugMode) {
        debugPrint('🔌 Connecting to WebSocket: $uri');
      }

      _channel = WebSocketChannel.connect(uri);

      // Listen to messages
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDisconnect,
        cancelOnError: false,
      );

      // Send join message
      _sendMessage({
        'type': 'join',
        'username': _currentUsername,
        'room_id': roomId,
      });

      // Start heartbeat
      _startHeartbeat();

      _updateState(WebSocketConnectionState.connected);
      _reconnectAttempts = 0;

      if (kDebugMode) {
        debugPrint('✅ WebSocket connected to room: $roomId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ WebSocket connection error: $e');
      }
      _updateState(WebSocketConnectionState.error);
      _scheduleReconnect();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // DISCONNECT
  // ═══════════════════════════════════════════════════════════════

  void disconnect() {
    if (kDebugMode) {
      debugPrint('🔌 Disconnecting WebSocket...');
    }

    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();

    if (_currentRoomId != null && _currentUsername != null) {
      _sendMessage({
        'type': 'leave',
        'username': _currentUsername,
        'room_id': _currentRoomId,
      });
    }

    _channel?.sink.close();
    _channel = null;
    _currentRoomId = null;
    _currentUsername = null;

    _updateState(WebSocketConnectionState.disconnected);
  }

  // ═══════════════════════════════════════════════════════════════
  // SEND CHAT MESSAGE
  // ═══════════════════════════════════════════════════════════════

  void sendChatMessage(String message) {
    if (!isConnected) {
      throw Exception('Nicht verbunden');
    }

    _sendMessage({
      'type': 'message',
      'username': _currentUsername,
      'message': message,
      'room_id': _currentRoomId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // TYPING INDICATOR
  // ═══════════════════════════════════════════════════════════════

  void sendTypingIndicator(bool isTyping) {
    if (!isConnected) return;

    _sendMessage({
      'type': 'typing',
      'username': _currentUsername,
      'is_typing': isTyping,
      'room_id': _currentRoomId,
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // PRIVATE METHODS
  // ═══════════════════════════════════════════════════════════════

  void _sendMessage(Map<String, dynamic> message) {
    try {
      final jsonMessage = json.encode(message);
      _channel?.sink.add(jsonMessage);

      if (kDebugMode) {
        debugPrint('📤 Sent: ${message['type']}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error sending message: $e');
      }
    }
  }

  void _onMessage(dynamic data) {
    try {
      final message = json.decode(data as String) as Map<String, dynamic>;
      final type = message['type'] as String?;

      if (kDebugMode) {
        debugPrint('📥 Received: $type');
      }

      switch (type) {
        case 'message':
          _handleChatMessage(message);
          break;
        case 'typing':
          _handleTypingIndicator(message);
          break;
        case 'user_joined':
        case 'user_left':
          _handleUserEvent(message);
          break;
        case 'online_users':
          _handleOnlineUsers(message);
          break;
        case 'pong':
          // Heartbeat response
          break;
        default:
          if (kDebugMode) {
            debugPrint('⚠️ Unknown message type: $type');
          }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error processing message: $e');
      }
    }
  }

  void _handleChatMessage(Map<String, dynamic> message) {
    try {
      final chatMessage = ChatMessage.fromJson(message);
      _messageController.add(chatMessage);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error parsing chat message: $e');
      }
    }
  }

  void _handleTypingIndicator(Map<String, dynamic> message) {
    _typingController.add({
      'username': message['username'] as String,
      'is_typing': message['is_typing'] as bool,
    });
  }

  void _handleUserEvent(Map<String, dynamic> message) {
    // Could be used for notifications
    if (kDebugMode) {
      debugPrint('👤 User event: ${message['type']} - ${message['username']}');
    }
  }

  void _handleOnlineUsers(Map<String, dynamic> message) {
    final users = (message['users'] as List<dynamic>)
        .map((u) => u as String)
        .toList();
    _onlineUsersController.add(users);
  }

  void _onError(dynamic error) {
    if (kDebugMode) {
      debugPrint('❌ WebSocket error: $error');
    }
    _updateState(WebSocketConnectionState.error);
    _scheduleReconnect();
  }

  void _onDisconnect() {
    if (kDebugMode) {
      debugPrint('🔌 WebSocket disconnected');
    }

    if (_state != WebSocketConnectionState.disconnected) {
      _updateState(WebSocketConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      if (kDebugMode) {
        debugPrint('❌ Max reconnect attempts reached');
      }
      return;
    }

    if (_currentRoomId == null) {
      return; // Don't reconnect if manually disconnected
    }

    _reconnectTimer?.cancel();
    _reconnectAttempts++;

    if (kDebugMode) {
      debugPrint(
        '🔄 Scheduling reconnect attempt $_reconnectAttempts/$_maxReconnectAttempts',
      );
    }

    _updateState(WebSocketConnectionState.reconnecting);

    _reconnectTimer = Timer(_reconnectDelay, () {
      if (_currentRoomId != null) {
        connectToRoom(_currentRoomId!);
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (isConnected) {
        _sendMessage({
          'type': 'ping',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
    });
  }

  void _updateState(WebSocketConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  // ═══════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════

  void dispose() {
    disconnect();
    _messageController.close();
    _stateController.close();
    _typingController.close();
    _onlineUsersController.close();
  }
}
