import 'package:flutter/material.dart';
import 'dart:async';
import '../services/hybrid_chat_service.dart';

/// 🔄 CHAT ENHANCER MIXIN
/// Fügt WebSocket-Support zu bestehenden Chat-Screens hinzu
mixin ChatEnhancerMixin<T extends StatefulWidget> on State<T> {
  final HybridChatService _hybridChat = HybridChatService();
  StreamSubscription? _messageSubscription;
  StreamSubscription? _statusSubscription;
  
  String _connectionStatus = '🔄 Verbinde...';
  bool _isHybridMode = false; // Feature-Flag
  
  /// Aktiviere Hybrid-Chat (WebSocket + HTTP Fallback)
  Future<void> enableHybridChat({
    required String roomId,
    required String username,
    required String realm,
  }) async {
    _isHybridMode = true;
    
    // Verbinde Hybrid-Service
    final success = await _hybridChat.connect(
      roomId: roomId,
      username: username,
      realm: realm,
    );
    
    if (success) {
      // Lausche auf Nachrichten
      _messageSubscription = _hybridChat.messageStream.listen(_handleHybridMessage);
      
      // Lausche auf Status-Updates
      _statusSubscription = _hybridChat.connectionStatusStream.listen((status) {
        if (mounted) {
          setState(() {
            _connectionStatus = _getStatusText(status);
          });
        }
      });
    }
  }
  
  /// Verarbeite Hybrid-Nachrichten
  void _handleHybridMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;
    
    switch (type) {
      case 'history':
        // Bulk-Update: Alle Nachrichten ersetzen
        final messages = message['messages'] as List<dynamic>?;
        if (messages != null && mounted) {
          onHybridMessagesReceived(messages.cast<Map<String, dynamic>>());
        }
        break;
        
      case 'new_message':
        // Einzelne neue Nachricht
        final newMessage = message['message'] as Map<String, dynamic>?;
        if (newMessage != null && mounted) {
          onHybridNewMessage(newMessage);
        }
        break;
        
      case 'user_joined':
      case 'user_left':
        // User-Events
        if (mounted) {
          onHybridUserEvent(message);
        }
        break;
        
      case 'user_typing':
        // Typing-Indicator
        if (mounted) {
          onHybridTyping(message);
        }
        break;
    }
  }
  
  /// Status-Text generieren
  String _getStatusText(String status) {
    switch (status) {
      case 'connecting_websocket':
        return '🔌 Verbinde WebSocket...';
      case 'connected_websocket':
        return '🟢 Echtzeit (WebSocket)';
      case 'connected_http':
        return '🟡 Polling (HTTP)';
      default:
        return '🔄 Verbinde...';
    }
  }
  
  /// Sende Nachricht via Hybrid-Service
  Future<void> sendHybridMessage(String messageText) async {
    if (_isHybridMode) {
      await _hybridChat.sendMessage(message: messageText);
    }
  }
  
  /// Sende Tool-Aktivität via Hybrid-Service
  Future<void> sendHybridToolActivity({
    required String toolName,
    required String activity,
    String? icon,
  }) async {
    if (_isHybridMode) {
      await _hybridChat.sendToolActivity(
        toolName: toolName,
        activity: activity,
        icon: icon,
      );
    }
  }
  
  /// Typing Indicator senden
  void sendHybridTyping(bool isTyping) {
    if (_isHybridMode) {
      _hybridChat.sendTypingIndicator(isTyping);
    }
  }
  
  /// Connection-Status Widget
  Widget buildConnectionStatusBadge() {
    if (!_isHybridMode) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _connectionStatus.contains('🟢') 
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _connectionStatus.contains('🟢') 
              ? Colors.green
              : Colors.orange,
        ),
      ),
      child: Text(
        _connectionStatus,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: _connectionStatus.contains('🟢') 
              ? Colors.green
              : Colors.orange,
        ),
      ),
    );
  }
  
  /// Cleanup
  void disposeHybridChat() {
    _messageSubscription?.cancel();
    _statusSubscription?.cancel();
    _hybridChat.dispose();
  }
  
  // ========================================================================
  // OVERRIDE HOOKS - Implementiere diese in deinem Chat-Screen
  // ========================================================================
  
  /// Wird aufgerufen wenn Nachrichten-History geladen wurde (bulk)
  void onHybridMessagesReceived(List<Map<String, dynamic>> messages) {
    // Override in Chat-Screen
  }
  
  /// Wird aufgerufen bei neuer Einzelnachricht (real-time)
  void onHybridNewMessage(Map<String, dynamic> message) {
    // Override in Chat-Screen
  }
  
  /// Wird aufgerufen bei User-Events (join/leave)
  void onHybridUserEvent(Map<String, dynamic> event) {
    // Override in Chat-Screen (optional)
  }
  
  /// Wird aufgerufen bei Typing-Indicator
  void onHybridTyping(Map<String, dynamic> event) {
    // Override in Chat-Screen (optional)
  }
}
