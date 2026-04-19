import 'package:flutter/foundation.dart';
import '../models/enhanced_chat_message.dart';

/// Chat Notification Service - Verwaltet Unread Counter & Mentions
class ChatNotificationService extends ChangeNotifier {
  static final ChatNotificationService _instance = ChatNotificationService._internal();
  factory ChatNotificationService() => _instance;
  ChatNotificationService._internal();
  
  // 🔔 Unread Messages per Room
  final Map<String, int> _unreadCounts = {};
  
  // 📌 Mentions für aktuellen User
  final Map<String, List<EnhancedChatMessage>> _mentions = {};
  
  // 🔊 Letzte Benachrichtigungszeit (Throttling)
  DateTime? _lastNotificationTime;
  
  // 👤 Aktueller Username
  String? _currentUsername;
  
  // Getters
  Map<String, int> get unreadCounts => Map.unmodifiable(_unreadCounts);
  Map<String, List<EnhancedChatMessage>> get mentions => Map.unmodifiable(_mentions);
  int getTotalUnreadCount() => _unreadCounts.values.fold(0, (sum, count) => sum + count);
  int getUnreadCount(String roomId) => _unreadCounts[roomId] ?? 0;
  
  /// Username setzen
  void setCurrentUsername(String username) {
    _currentUsername = username;
    if (kDebugMode) {
      debugPrint('💬 ChatNotificationService: Username gesetzt: $username');
    }
  }
  
  /// Neue Nachricht verarbeiten
  void processNewMessage(EnhancedChatMessage message, String currentRoomId) {
    // Ignoriere eigene Nachrichten
    if (message.username == _currentUsername) return;
    
    // Unread Count erhöhen (nur wenn nicht in diesem Raum)
    if (message.roomId != currentRoomId) {
      _unreadCounts[message.roomId] = (_unreadCounts[message.roomId] ?? 0) + 1;
      notifyListeners();
    }
    
    // Prüfe auf Mentions
    if (_currentUsername != null && message.mentions.contains(_currentUsername)) {
      _mentions.putIfAbsent(message.roomId, () => []);
      _mentions[message.roomId]!.add(message);
      
      // Mention Notification
      _showMentionNotification(message);
      notifyListeners();
    }
    
    // Standard Notification (throttled)
    if (message.roomId != currentRoomId) {
      _showNewMessageNotification(message);
    }
  }
  
  /// Raum als gelesen markieren
  void markRoomAsRead(String roomId) {
    _unreadCounts[roomId] = 0;
    notifyListeners();
    
    if (kDebugMode) {
      debugPrint('✅ ChatNotificationService: Raum $roomId als gelesen markiert');
    }
  }
  
  /// Mention als gelesen markieren
  void clearMentions(String roomId) {
    _mentions.remove(roomId);
    notifyListeners();
  }
  
  /// Alle als gelesen markieren
  void markAllAsRead() {
    _unreadCounts.clear();
    _mentions.clear();
    notifyListeners();
  }
  
  /// Notification anzeigen (Throttled)
  void _showNewMessageNotification(EnhancedChatMessage message) {
    final now = DateTime.now();
    
    // Throttle: Max 1 Notification pro 3 Sekunden
    if (_lastNotificationTime != null && 
        now.difference(_lastNotificationTime!) < const Duration(seconds: 3)) {
      return;
    }
    
    _lastNotificationTime = now;
    
    if (kDebugMode) {
      debugPrint('🔔 Neue Nachricht von ${message.username} in ${message.roomId}');
    }
    
    // TODO: System Notification anzeigen (wenn implementiert)
  }
  
  /// Mention Notification (Immer)
  void _showMentionNotification(EnhancedChatMessage message) {
    if (kDebugMode) {
      debugPrint('📢 Du wurdest erwähnt von ${message.username}: ${message.message}');
    }
    
    // TODO: System Notification anzeigen (wenn implementiert)
  }
  
  /// Reset Service
  void reset() {
    _unreadCounts.clear();
    _mentions.clear();
    _currentUsername = null;
    _lastNotificationTime = null;
    notifyListeners();
  }
}
