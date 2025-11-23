import 'dart:convert';
import 'auth_service.dart';

/// ═══════════════════════════════════════════════════════════════
/// DIRECT MESSAGE SERVICE - Weltenbibliothek
/// ═══════════════════════════════════════════════════════════════
/// Manages private messages between users with D1 backend
/// ═══════════════════════════════════════════════════════════════

class DirectMessage {
  final int id;
  final String fromUsername;
  final String toUsername;
  final String message;
  final int createdAt;
  final int? readAt;

  DirectMessage({
    required this.id,
    required this.fromUsername,
    required this.toUsername,
    required this.message,
    required this.createdAt,
    this.readAt,
  });

  factory DirectMessage.fromJson(Map<String, dynamic> json) {
    return DirectMessage(
      id: json['id'] as int,
      fromUsername: json['from_username'] as String,
      toUsername: json['to_username'] as String,
      message: json['message'] as String,
      createdAt: json['created_at'] as int,
      readAt: json['read_at'] as int?,
    );
  }

  DateTime get createdAtDate =>
      DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
  DateTime? get readAtDate => readAt != null
      ? DateTime.fromMillisecondsSinceEpoch(readAt! * 1000)
      : null;

  bool get isRead => readAt != null;

  /// Check if current user is sender
  bool isSentBy(String username) => fromUsername == username;

  /// Get other user in conversation
  String getOtherUser(String currentUsername) {
    return fromUsername == currentUsername ? toUsername : fromUsername;
  }
}

class Conversation {
  final String otherUsername;
  final String? lastMessage;
  final int? lastMessageTime;
  final int unreadCount;

  Conversation({
    required this.otherUsername,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
  });

  DateTime? get lastMessageDate => lastMessageTime != null
      ? DateTime.fromMillisecondsSinceEpoch(lastMessageTime! * 1000)
      : null;
}

class DirectMessageService {
  final AuthService _authService = AuthService();

  // Singleton pattern
  static final DirectMessageService _instance =
      DirectMessageService._internal();
  factory DirectMessageService() => _instance;
  DirectMessageService._internal();

  // ═══════════════════════════════════════════════════════════════
  // GET DIRECT MESSAGES
  // ═══════════════════════════════════════════════════════════════

  /// Get direct messages with specific user
  Future<List<DirectMessage>> getDirectMessages({
    required String withUsername,
    int limit = 50,
  }) async {
    try {
      final response = await _authService.authenticatedGet(
        '/api/messages/direct?with=$withUsername&limit=$limit',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final messages = data['messages'] as List<dynamic>;

        return messages
            .map((msg) => DirectMessage.fromJson(msg as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 400) {
        throw Exception('Ungültiger Benutzername');
      } else {
        throw Exception('Failed to fetch messages: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching messages: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SEND DIRECT MESSAGE
  // ═══════════════════════════════════════════════════════════════

  /// Send direct message to user
  Future<Map<String, dynamic>> sendDirectMessage({
    required String toUsername,
    required String message,
  }) async {
    try {
      final response = await _authService.authenticatedPost(
        '/api/messages/direct',
        {'to_username': toUsername, 'message': message},
      );

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': DirectMessage.fromJson(
            data['message'] as Map<String, dynamic>,
          ),
        };
      } else if (response.statusCode == 404) {
        return {'success': false, 'error': 'Benutzer nicht gefunden'};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Fehler beim Senden',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // GET CONVERSATIONS LIST
  // ═══════════════════════════════════════════════════════════════

  /// Get list of all conversations (for overview)
  /// ✅ FIX: Implemented backend endpoint integration
  Future<List<Conversation>> getConversations() async {
    try {
      final response = await _authService.authenticatedGet(
        '/api/messages/conversations',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final conversations = data['conversations'] as List<dynamic>;

        return conversations
            .map(
              (conv) => Conversation(
                otherUsername: conv['other_username'] as String,
                lastMessage: conv['last_message'] as String?,
                lastMessageTime: conv['last_message_time'] as int?,
                unreadCount: conv['unread_count'] as int? ?? 0,
              ),
            )
            .toList();
      } else if (response.statusCode == 404) {
        // No conversations yet - return empty list
        return [];
      } else {
        throw Exception(
          'Failed to fetch conversations: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching conversations: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MARK MESSAGE AS READ
  // ═══════════════════════════════════════════════════════════════

  /// Mark message as read
  /// ✅ NEW: Enables read receipts functionality
  Future<bool> markMessageAsRead(int messageId) async {
    try {
      final response = await _authService.authenticatedPost(
        '/api/messages/$messageId/read',
        {},
      );

      return response.statusCode == 200;
    } catch (e) {
      // Silent fail - not critical
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // USER STATUS
  // ═══════════════════════════════════════════════════════════════

  /// Check if user is online
  /// ✅ NEW: Online status tracking
  Future<Map<String, dynamic>> getUserStatus(String username) async {
    try {
      final response = await _authService.authenticatedGet(
        '/api/users/$username/status',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return {
          'isOnline': data['is_online'] as bool? ?? false,
          'lastSeenAt': data['last_seen_at'] as int?,
        };
      }

      return {'isOnline': false, 'lastSeenAt': null};
    } catch (e) {
      return {'isOnline': false, 'lastSeenAt': null};
    }
  }
}
