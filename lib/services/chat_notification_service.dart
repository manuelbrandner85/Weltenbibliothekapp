import 'package:flutter/foundation.dart';
import '../models/enhanced_chat_message.dart';
import 'push_notification_helper.dart';

/// Chat Notification Service - Verwaltet Unread Counter & Mentions
class ChatNotificationService extends ChangeNotifier {
  static final ChatNotificationService _instance =
      ChatNotificationService._internal();
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
  Map<String, List<EnhancedChatMessage>> get mentions =>
      Map.unmodifiable(_mentions);
  int getTotalUnreadCount() =>
      _unreadCounts.values.fold(0, (sum, count) => sum + count);
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
    if (_currentUsername != null &&
        message.mentions.contains(_currentUsername)) {
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
      debugPrint(
          '✅ ChatNotificationService: Raum $roomId als gelesen markiert');
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
      debugPrint(
          '🔔 Neue Nachricht von ${message.username} in ${message.roomId}');
    }

    // v103 (2.1): Topic-Push -- jeder Subscriber des Raum-Topics
    // bekommt eine Notification. Fire-and-forget.
    PushNotificationHelper.instance.sendToTopic(
      topic: 'chat_${message.roomId}',
      title: '💬 Neue Nachricht in #${_roomDisplayName(message.roomId)}',
      body: '${message.username}: ${_truncate(message.message, 80)}',
      data: {
        'type': 'chat_message',
        'room_id': message.roomId,
        'sender': message.username,
      },
    ).ignore();
  }

  /// Mention Notification (Immer)
  void _showMentionNotification(EnhancedChatMessage message) {
    if (kDebugMode) {
      debugPrint(
          '📢 Du wurdest erwähnt von ${message.username}: ${message.message}');
    }

    // v103 (2.2): Mention-Push direkt an den erwaehnten User.
    final me = _currentUsername;
    if (me != null && me.isNotEmpty) {
      PushNotificationHelper.instance.sendToUser(
        targetUserId: me,
        type: 'chat_mention',
        title: '📢 Du wurdest erwähnt!',
        body:
            '${message.username} in #${_roomDisplayName(message.roomId)}: ${_truncate(message.message, 80)}',
        data: {
          'room_id': message.roomId,
          'sender': message.username,
          'mention': true,
        },
      ).ignore();
    }
  }

  /// Pretty-printed room name -- strips welt-prefix and capitalizes.
  String _roomDisplayName(String roomId) {
    final parts = roomId.split('-');
    if (parts.length < 2) return roomId;
    final tail = parts.sublist(1).join('-');
    if (tail.isEmpty) return roomId;
    return tail[0].toUpperCase() + tail.substring(1);
  }

  String _truncate(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}...';

  /// Reset Service
  void reset() {
    _unreadCounts.clear();
    _mentions.clear();
    _currentUsername = null;
    _lastNotificationTime = null;
    notifyListeners();
  }
}
