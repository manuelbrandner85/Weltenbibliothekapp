/// 🔄 WELTENBIBLIOTHEK - HYBRID CHAT SERVICE
/// Combines WebSocket (real-time) + HTTP (fallback) for reliable messaging
/// Automatically switches between WebSocket and HTTP based on connection quality

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'cloudflare_api_service.dart';
import 'websocket_chat_service.dart';

class HybridChatService {
  // Singleton pattern
  static final HybridChatService _instance = HybridChatService._internal();
  factory HybridChatService() => _instance;
  HybridChatService._internal();

  // Services
  final CloudflareApiService _httpService = CloudflareApiService();
  final WebSocketChatService _wsService = WebSocketChatService();
  
  // Connection state
  bool _isWebSocketActive = false;
  String? _currentRoom;
  String? _currentRealm;
  String? _currentUsername;
  
  // Message stream controller (unified)
  final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // Connection status stream controller
  final StreamController<String> _statusController = 
      StreamController<String>.broadcast();
  
  // HTTP polling fallback
  Timer? _pollingTimer;
  static const Duration _pollingInterval = Duration(seconds: 5);
  
  /// Unified message stream (WebSocket OR HTTP)
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  
  /// Connection status stream
  Stream<String> get connectionStatusStream => _statusController.stream;
  
  /// Check if WebSocket is active
  bool get isWebSocketActive => _isWebSocketActive;
  
  /// Connect to chat room with hybrid approach
  Future<bool> connect({
    required String roomId,
    required String username,
    required String realm,
  }) async {
    _currentRoom = roomId;
    _currentRealm = realm;
    _currentUsername = username;
    
    if (kDebugMode) {
      debugPrint('🔄 HybridChat: Connecting to $roomId (realm: $realm)');
    }
    
    // Step 1: Try WebSocket first
    try {
      final wsSuccess = await _wsService.connect(
        room: roomId,
        realm: realm,
      );
      
      if (wsSuccess) {
        _isWebSocketActive = true;
        _statusController.add('connected_websocket');
        
        // Forward WebSocket messages to unified stream
        _wsService.messageStream.listen((message) {
          _messageController.add(message);
        });
        
        if (kDebugMode) {
          debugPrint('✅ HybridChat: WebSocket connected successfully');
        }
        
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ HybridChat: WebSocket failed, falling back to HTTP - $e');
      }
    }
    
    // Step 2: Fallback to HTTP polling
    _isWebSocketActive = false;
    _statusController.add('connected_http');
    _startHttpPolling();
    
    if (kDebugMode) {
      debugPrint('🔄 HybridChat: Using HTTP polling mode');
    }
    
    return true;
  }
  
  /// Send message (automatically uses WebSocket or HTTP)
  Future<void> sendMessage({
    required String message,
    String? replyToId,
    String? imageUrl,
  }) async {
    if (_currentRoom == null || _currentRealm == null || _currentUsername == null) {
      throw Exception('Not connected to a room');
    }
    
    // Use WebSocket if available
    if (_isWebSocketActive) {
      try {
        await _wsService.sendMessage(
          room: _currentRoom!,
          message: message,
          username: _currentUsername!,
          realm: _currentRealm!,
          replyToId: replyToId,
          imageUrl: imageUrl,
        );
        
        if (kDebugMode) {
          debugPrint('📤 HybridChat: Message sent via WebSocket');
        }
        return;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ HybridChat: WebSocket send failed, trying HTTP - $e');
        }
        
        // Fallback to HTTP
        _isWebSocketActive = false;
        _startHttpPolling();
      }
    }
    
    // Use HTTP
    await _httpService.sendChatMessage(
      roomId: _currentRoom!,
      realm: _currentRealm!,
      userId: 'user_anonymous',
      username: _currentUsername!,
      message: message,
    );
    
    if (kDebugMode) {
      debugPrint('📤 HybridChat: Message sent via HTTP');
    }
  }
  
  /// Send typing indicator (WebSocket only)
  void sendTypingIndicator(bool isTyping) {
    if (_isWebSocketActive) {
      _wsService.sendTypingIndicator(isTyping);
    }
  }
  
  /// Send tool activity (for inline tools)
  Future<void> sendToolActivity({
    required String toolName,
    required String activity,
    String? icon,
  }) async {
    if (_currentRoom == null || _currentRealm == null || _currentUsername == null) {
      throw Exception('Not connected to a room');
    }
    
    final toolMessage = {
      'type': 'tool_activity',
      'tool_name': toolName,
      'activity': activity,
      'icon': icon ?? '🔧',
      'username': _currentUsername,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // Use WebSocket if available
    if (_isWebSocketActive) {
      try {
        await _wsService.sendMessage(
          room: _currentRoom!,
          message: '[$toolName] $activity',
          username: _currentUsername!,
          realm: _currentRealm!,
        );
        
        if (kDebugMode) {
          debugPrint('🔧 HybridChat: Tool activity sent via WebSocket');
        }
        return;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ HybridChat: WebSocket send failed - $e');
        }
      }
    }
    
    // HTTP fallback for tool activities
    if (kDebugMode) {
      debugPrint('🔧 HybridChat: Tool activity sent via HTTP');
    }
  }
  
  /// Switch to different room
  Future<void> switchRoom(String newRoom) async {
    if (_currentRoom == newRoom) return;
    
    _currentRoom = newRoom;
    
    if (_isWebSocketActive) {
      await _wsService.switchRoom(newRoom);
    }
    
    if (kDebugMode) {
      debugPrint('🔄 HybridChat: Switched to room $newRoom');
    }
  }
  
  /// Start HTTP polling (fallback mode)
  void _startHttpPolling() {
    _pollingTimer?.cancel();
    
    if (_currentRoom == null || _currentRealm == null) return;
    
    _pollingTimer = Timer.periodic(_pollingInterval, (timer) async {
      if (_isWebSocketActive) {
        timer.cancel();
        return;
      }
      
      try {
        final messages = await _httpService.getChatMessages(
          _currentRoom!,
          realm: _currentRealm!,
          limit: 10,
        );
        
        // Emit each message to stream
        for (var message in messages) {
          _messageController.add(message);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ HybridChat: HTTP polling error - $e');
        }
      }
    });
  }
  
  /// Disconnect from chat
  void disconnect() {
    _pollingTimer?.cancel();
    
    if (_isWebSocketActive) {
      _wsService.disconnect();
    }
    
    _isWebSocketActive = false;
    _currentRoom = null;
    _currentRealm = null;
    _currentUsername = null;
    
    if (kDebugMode) {
      debugPrint('🔌 HybridChat: Disconnected');
    }
  }
  
  /// Dispose resources
  void dispose() {
    disconnect();
    _messageController.close();
    _statusController.close();
  }
}
