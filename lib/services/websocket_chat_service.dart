/// 🌐 WELTENBIBLIOTHEK - WEBSOCKET CHAT SERVICE
/// Real-time messaging with WebSocket instead of HTTP polling
/// Features: Instant delivery, typing indicators, online status
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../config/api_config.dart';

class WebSocketChatService {
  static final WebSocketChatService _instance = WebSocketChatService._internal();
  factory WebSocketChatService() => _instance;
  WebSocketChatService._internal();

  // WebSocket connection
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _messageController;
  StreamController<String>? _typingController;
  StreamController<List<String>>? _onlineUsersController;
  
  // Connection state
  bool _isConnected = false;
  String? _currentRoom;
  String? _userId;
  String? _username;
  String? _realm;
  
  // Reconnection with Exponential Backoff
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  
  // Exponential Backoff Delays: 1s, 2s, 4s, 8s, 16s (max)
  static const List<Duration> _reconnectDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 16),
  ];
  
  // Offline message queue
  final List<Map<String, dynamic>> _offlineQueue = [];
  
  // Heartbeat (keep connection alive)
  Timer? _heartbeatTimer;
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  /// Get message stream
  Stream<Map<String, dynamic>> get messageStream => 
      _messageController?.stream ?? const Stream.empty();
  
  /// Get typing indicator stream
  Stream<String> get typingStream => 
      _typingController?.stream ?? const Stream.empty();
  
  /// Get online users stream
  Stream<List<String>> get onlineUsersStream => 
      _onlineUsersController?.stream ?? const Stream.empty();
  
  /// Check if connected
  bool get isConnected => _isConnected;

  /// Connect to chat room
  Future<bool> connect({
    required String room,
    required String realm,
    String? userId,
    String? username,
  }) async {
    // Use defaults if not provided
    final effectiveUserId = userId ?? 'user_anonymous';
    final effectiveUsername = username ?? 'Anonymous';
    
    if (_isConnected && _currentRoom == room) {
      if (kDebugMode) {
        debugPrint('🌐 Already connected to room: $room');
      }
      return true;
    }

    try {
      // Disconnect if already connected to different room
      if (_isConnected) {
        await disconnect();
      }

      _currentRoom = room;
      _userId = effectiveUserId;
      _username = effectiveUsername;
      _realm = realm;
      _reconnectAttempts = 0;

      // Initialize stream controllers
      _messageController = StreamController<Map<String, dynamic>>.broadcast();
      _typingController = StreamController<String>.broadcast();
      _onlineUsersController = StreamController<List<String>>.broadcast();

      await _establishConnection();
      
      return true;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ WebSocket connection failed: $e');
      }
      _scheduleReconnect();
      return false;
    }
  }

  /// Establish WebSocket connection
  Future<void> _establishConnection() async {
    try {
      // WebSocket URL (from ApiConfig)
      final wsUrl = Uri.parse(
        '${ApiConfig.websocketUrl}/ws'
        '?room=$_currentRoom'
        '&realm=$_realm'
        '&user_id=$_userId'
        '&username=$_username'
      );

      if (kDebugMode) {
        debugPrint('🌐 Connecting to WebSocket: $wsUrl');
      }

      // Create WebSocket connection
      _channel = WebSocketChannel.connect(wsUrl);

      // Wait for connection to be established
      await _channel!.ready;

      _isConnected = true;
      _reconnectAttempts = 0;

      if (kDebugMode) {
        debugPrint('✅ WebSocket connected to room: $_currentRoom');
      }

      // Listen for messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      // Start heartbeat
      _startHeartbeat();

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ WebSocket connection error: $e');
      }
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  /// Handle incoming message
  void _handleMessage(dynamic data) {
    try {
      final message = json.decode(data as String) as Map<String, dynamic>;
      final type = message['type'] as String?;

      if (kDebugMode) {
        debugPrint('📨 WebSocket message received: $type');
      }

      switch (type) {
        case 'new_message':
          // New chat message
          final messageData = message['data'] as Map<String, dynamic>;
          _messageController?.add(messageData);
          break;

        case 'message_deleted':
          // Message was deleted
          final messageId = message['message_id'] as String;
          _messageController?.add({
            'type': 'deleted',
            'id': messageId,
          });
          break;

        case 'message_edited':
          // Message was edited
          final messageData = message['data'] as Map<String, dynamic>;
          _messageController?.add({
            'type': 'edited',
            ...messageData,
          });
          break;

        case 'typing':
          // User is typing
          final username = message['username'] as String?;
          if (username != null && username != _username) {
            _typingController?.add(username);
          }
          break;

        case 'online_users':
          // List of online users
          final users = (message['users'] as List?)
              ?.cast<String>()
              ?? [];
          _onlineUsersController?.add(users);
          break;

        case 'pong':
          // Heartbeat response
          if (kDebugMode) {
            debugPrint('💓 Heartbeat received');
          }
          break;

        default:
          if (kDebugMode) {
            debugPrint('⚠️ Unknown message type: $type');
          }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error handling message: $e');
      }
    }
  }

  /// Handle connection error
  void _handleError(error) {
    if (kDebugMode) {
      debugPrint('❌ WebSocket error: $error');
    }
    _isConnected = false;
    _scheduleReconnect();
  }

  /// Handle disconnection
  void _handleDisconnect() {
    if (kDebugMode) {
      debugPrint('⚠️ WebSocket disconnected');
    }
    _isConnected = false;
    _stopHeartbeat();
    _scheduleReconnect();
  }

  /// Send message (with named parameters for HybridChatService compatibility)
  Future<void> sendMessage({
    required String room,
    required String message,
    required String username,
    required String realm,
    String? replyToId,
    String? imageUrl,
  }) async {
    // If not connected, queue message for later
    if (!_isConnected) {
      if (kDebugMode) {
        debugPrint('📦 WebSocket not connected, queueing message...');
      }
      
      _offlineQueue.add({
        'room': room,
        'message': message,
        'username': username,
        'realm': realm,
        'reply_to_id': replyToId,
        'image_url': imageUrl,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      // Notify UI about queued message
      _messageController?.add({
        'type': 'message_queued',
        'message': message,
        'queue_size': _offlineQueue.length,
      });
      
      throw Exception('WebSocket not connected. Message queued for sending.');
    }

    try {
      final data = json.encode({
        'type': 'chat_message',
        'room_id': room,
        'message': message,
        'username': username,
        'realm': realm,
        'reply_to_id': replyToId,
        'image_url': imageUrl,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      _channel?.sink.add(data);

      if (kDebugMode) {
        debugPrint('📤 Message sent via WebSocket: $message');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to send message: $e');
      }
      
      // Queue message if send fails
      _offlineQueue.add({
        'room': room,
        'message': message,
        'username': username,
        'realm': realm,
        'reply_to_id': replyToId,
        'image_url': imageUrl,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      rethrow;
    }
  }
  
  /// Send typing indicator (with boolean parameter)
  void sendTypingIndicator(bool isTyping) {
    if (!_isConnected) return;

    try {
      final data = json.encode({
        'type': 'typing_indicator',
        'room_id': _currentRoom,
        'user_id': _userId,
        'username': _username,
        'is_typing': isTyping,
      });

      _channel?.sink.add(data);

      if (kDebugMode) {
        debugPrint('⌨️ Typing indicator sent: $isTyping');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to send typing indicator: $e');
      }
    }
  }
  
  /// Switch to different room
  Future<void> switchRoom(String newRoom) async {
    if (_currentRoom == newRoom) return;
    
    if (kDebugMode) {
      debugPrint('🔄 Switching room from $_currentRoom to $newRoom');
    }
    
    // Disconnect and reconnect to new room
    await disconnect();
    
    if (_realm != null) {
      await connect(
        room: newRoom,
        realm: _realm!,
        userId: _userId,
        username: _username,
      );
    }
  }

  /// Request online users
  void requestOnlineUsers() {
    if (!_isConnected) return;

    try {
      final data = json.encode({
        'type': 'get_online_users',
      });

      _channel?.sink.add(data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to request online users: $e');
      }
    }
  }

  /// Disconnect from chat
  Future<void> disconnect() async {
    if (kDebugMode) {
      debugPrint('🔌 Disconnecting WebSocket...');
    }

    _isConnected = false;
    _currentRoom = null;
    
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    await _channel?.sink.close(status.goingAway);
    _channel = null;

    await _messageController?.close();
    await _typingController?.close();
    await _onlineUsersController?.close();
    
    _messageController = null;
    _typingController = null;
    _onlineUsersController = null;
  }

  /// Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (_isConnected) {
        try {
          _channel?.sink.add(json.encode({'type': 'ping'}));
          if (kDebugMode) {
            debugPrint('💓 Heartbeat sent');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Heartbeat failed: $e');
          }
        }
      }
    });
  }

  /// Stop heartbeat
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Schedule reconnection attempt with Exponential Backoff
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      if (kDebugMode) {
        debugPrint('❌ Max reconnect attempts reached (${{_maxReconnectAttempts}}). Giving up.');
      }
      // Notify about connection failure
      _messageController?.add({
        'type': 'connection_failed',
        'message': 'Verbindung fehlgeschlagen. Bitte manuell neu verbinden.',
      });
      return;
    }

    if (_reconnectTimer != null && _reconnectTimer!.isActive) {
      return; // Already scheduled
    }

    _reconnectAttempts++;
    
    // Get delay with exponential backoff (max 16s)
    final delayIndex = (_reconnectAttempts - 1).clamp(0, _reconnectDelays.length - 1);
    final delay = _reconnectDelays[delayIndex];

    if (kDebugMode) {
      debugPrint('🔄 Reconnecting in ${{delay.inSeconds}}s (attempt $_reconnectAttempts/$_maxReconnectAttempts)...');
    }
    
    // Notify UI about reconnection attempt
    _messageController?.add({
      'type': 'reconnecting',
      'attempt': _reconnectAttempts,
      'max_attempts': _maxReconnectAttempts,
      'delay_seconds': delay.inSeconds,
    });

    _reconnectTimer = Timer(delay, () async {
      if (_currentRoom != null && _realm != null) {
        try {
          await connect(
            room: _currentRoom!,
            realm: _realm!,
            userId: _userId,
            username: _username,
          );
          
          // Send queued messages on successful reconnection
          if (_isConnected && _offlineQueue.isNotEmpty) {
            if (kDebugMode) {
              debugPrint('📦 Sending ${{_offlineQueue.length}} queued messages...');
            }
            
            for (final queuedMsg in _offlineQueue) {
              try {
                await sendMessage(
                  room: queuedMsg['room'],
                  message: queuedMsg['message'],
                  username: queuedMsg['username'],
                  realm: queuedMsg['realm'],
                );
              } catch (e) {
                if (kDebugMode) {
                  debugPrint('⚠️ Failed to send queued message: $e');
                }
              }
            }
            
            _offlineQueue.clear();
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Reconnection attempt failed: $e');
          }
        }
      }
    });
  }

  /// Reset reconnection counter (call on successful manual reconnect)
  void resetReconnectCounter() {
    _reconnectAttempts = 0;
  }
}
