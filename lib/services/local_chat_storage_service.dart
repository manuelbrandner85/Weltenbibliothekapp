import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// LOCAL CHAT STORAGE SERVICE
/// 
/// Produktionsreife lokale Chat-Speicherung mit Hive
/// Bereitet Synchronisation mit Backend vor
/// 
/// Features:
/// - Offline-First Architektur
/// - Lokale Message-Speicherung
/// - Room-based Message Management
/// - Presence Tracking
/// - Typing Indicators
/// - Backend Sync Preparation

class LocalChatStorageService {
  static final LocalChatStorageService _instance = LocalChatStorageService._internal();
  factory LocalChatStorageService() => _instance;
  LocalChatStorageService._internal();

  // Hive Box Names
  static const String _chatMessagesBox = 'chat_messages';
  static const String _chatRoomsBox = 'chat_rooms';
  static const String _chatPresenceBox = 'chat_presence';
  static const String _pendingSyncBox = 'chat_pending_sync';

  bool _initialized = false;

  /// Initialize the local chat storage
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Open Hive boxes
      await Hive.openBox(_chatMessagesBox);
      await Hive.openBox(_chatRoomsBox);
      await Hive.openBox(_chatPresenceBox);
      await Hive.openBox(_pendingSyncBox);

      _initialized = true;

      if (kDebugMode) {
        debugPrint('✅ LocalChatStorageService initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error initializing LocalChatStorageService: $e');
      }
    }
  }

  /// Get chat messages for a room
  Future<List<Map<String, dynamic>>> getMessages(
    String roomId,
    String realm, {
    int limit = 50,
    int offset = 0,
  }) async {
    await _ensureInitialized();

    try {
      final box = Hive.box(_chatMessagesBox);
      final key = '${realm}_$roomId';
      
      final List<dynamic>? messagesData = box.get(key);
      
      if (messagesData == null || messagesData.isEmpty) {
        return _getWelcomeMessages(roomId, realm);
      }

      // Convert to List<Map<String, dynamic>>
      final messages = messagesData
          .map((msg) => Map<String, dynamic>.from(msg as Map))
          .toList();

      // Sort by timestamp (newest first)
      messages.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp'] as String);
        final bTime = DateTime.parse(b['timestamp'] as String);
        return bTime.compareTo(aTime);
      });

      // Apply pagination
      final paginatedMessages = messages.skip(offset).take(limit).toList();

      return paginatedMessages;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting messages: $e');
      }
      return _getWelcomeMessages(roomId, realm);
    }
  }

  /// Send a chat message (local-first)
  Future<Map<String, dynamic>> sendMessage({
    required String roomId,
    required String realm,
    required String userId,
    required String username,
    required String message,
    String? avatarEmoji,
    String? avatarUrl,
    String? mediaType,
    String? mediaUrl,
  }) async {
    await _ensureInitialized();

    try {
      final box = Hive.box(_chatMessagesBox);
      final key = '${realm}_$roomId';

      // Create message object
      final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}_${userId.hashCode}';
      final timestamp = DateTime.now().toIso8601String();

      final chatMessage = {
        'id': messageId,
        'roomId': roomId,
        'realm': realm,
        'userId': userId,
        'username': username,
        'message': message,
        'avatarEmoji': avatarEmoji ?? '👤',
        'avatarUrl': avatarUrl,
        'mediaType': mediaType,
        'mediaUrl': mediaUrl,
        'timestamp': timestamp,
        'edited': false,
        'deleted': false,
        'reactions': {},
        'synced': false, // Not synced with backend yet
      };

      // Get existing messages
      final List<dynamic> messages = box.get(key) ?? [];
      
      // Add new message
      messages.add(chatMessage);

      // Keep only last 500 messages per room
      if (messages.length > 500) {
        messages.removeRange(0, messages.length - 500);
      }

      // Save messages
      await box.put(key, messages);

      // Add to pending sync queue
      await _addToPendingSync(chatMessage);

      // Update room activity
      await _updateRoomActivity(realm, roomId, timestamp);

      if (kDebugMode) {
        debugPrint('💬 Message sent locally: $messageId in $roomId');
      }

      return {
        'success': true,
        'message': chatMessage,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error sending message: $e');
      }
      throw Exception('Failed to send message: $e');
    }
  }

  /// Edit a message
  Future<Map<String, dynamic>> editMessage(
    String roomId,
    String realm,
    String messageId,
    String newMessage,
    String userId,
  ) async {
    await _ensureInitialized();

    try {
      final box = Hive.box(_chatMessagesBox);
      final key = '${realm}_$roomId';

      final List<dynamic> messages = box.get(key) ?? [];
      
      final messageIndex = messages.indexWhere((m) => m['id'] == messageId);
      
      if (messageIndex == -1) {
        throw Exception('Message not found');
      }

      final message = Map<String, dynamic>.from(messages[messageIndex] as Map);
      
      // Check ownership
      if (message['userId'] != userId) {
        throw Exception('Not authorized to edit this message');
      }

      message['message'] = newMessage;
      message['edited'] = true;
      message['editedAt'] = DateTime.now().toIso8601String();
      message['synced'] = false;

      messages[messageIndex] = message;
      await box.put(key, messages);

      // Add to pending sync
      await _addToPendingSync(message);

      return {
        'success': true,
        'message': message,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error editing message: $e');
      }
      throw Exception('Failed to edit message: $e');
    }
  }

  /// Delete a message
  Future<Map<String, dynamic>> deleteMessage(
    String roomId,
    String realm,
    String messageId,
    String userId,
    bool isAdmin,
  ) async {
    await _ensureInitialized();

    try {
      final box = Hive.box(_chatMessagesBox);
      final key = '${realm}_$roomId';

      final List<dynamic> messages = box.get(key) ?? [];
      
      final messageIndex = messages.indexWhere((m) => m['id'] == messageId);
      
      if (messageIndex == -1) {
        throw Exception('Message not found');
      }

      final message = Map<String, dynamic>.from(messages[messageIndex] as Map);
      
      // Check ownership or admin
      if (message['userId'] != userId && !isAdmin) {
        throw Exception('Not authorized to delete this message');
      }

      message['deleted'] = true;
      message['message'] = '[Nachricht gelöscht]';
      message['deletedAt'] = DateTime.now().toIso8601String();
      message['synced'] = false;

      messages[messageIndex] = message;
      await box.put(key, messages);

      return {
        'success': true,
        'message': message,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting message: $e');
      }
      throw Exception('Failed to delete message: $e');
    }
  }

  /// Get room info
  Future<Map<String, dynamic>?> getRoomInfo(String realm, String roomId) async {
    await _ensureInitialized();

    try {
      final box = Hive.box(_chatRoomsBox);
      final key = '${realm}_$roomId';
      final roomData = box.get(key);
      
      if (roomData == null) return null;
      
      return Map<String, dynamic>.from(roomData as Map);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting room info: $e');
      }
      return null;
    }
  }

  /// Update presence for a user
  Future<void> updatePresence(
    String realm,
    String roomId,
    String userId,
    String username,
    String avatarEmoji,
  ) async {
    await _ensureInitialized();

    try {
      final box = Hive.box(_chatPresenceBox);
      final key = '${realm}_$roomId';

      final Map<String, dynamic> presence = 
          Map<String, dynamic>.from((box.get(key) ?? {}) as Map);

      presence[userId] = {
        'username': username,
        'avatarEmoji': avatarEmoji,
        'lastSeen': DateTime.now().toIso8601String(),
        'status': 'online',
      };

      await box.put(key, presence);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating presence: $e');
      }
    }
  }

  /// Get online users
  Future<List<Map<String, dynamic>>> getOnlineUsers(
    String realm,
    String roomId,
  ) async {
    await _ensureInitialized();

    try {
      final box = Hive.box(_chatPresenceBox);
      final key = '${realm}_$roomId';

      final Map<String, dynamic> presence =
          Map<String, dynamic>.from((box.get(key) ?? {}) as Map);

      final now = DateTime.now();
      final onlineUsers = <Map<String, dynamic>>[];

      presence.forEach((userId, data) {
        final userData = Map<String, dynamic>.from(data as Map);
        final lastSeen = DateTime.parse(userData['lastSeen'] as String);
        final diffMinutes = now.difference(lastSeen).inMinutes;

        if (diffMinutes < 5) {
          onlineUsers.add({
            'userId': userId,
            ...userData,
          });
        }
      });

      return onlineUsers;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting online users: $e');
      }
      return [];
    }
  }

  /// Clear all local chat data (for testing)
  Future<void> clearAllChatData() async {
    await _ensureInitialized();

    try {
      await Hive.box(_chatMessagesBox).clear();
      await Hive.box(_chatRoomsBox).clear();
      await Hive.box(_chatPresenceBox).clear();
      await Hive.box(_pendingSyncBox).clear();

      if (kDebugMode) {
        debugPrint('✅ All chat data cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error clearing chat data: $e');
      }
    }
  }

  // ============================================================================
  // PRIVATE HELPER METHODS
  // ============================================================================

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  Future<void> _updateRoomActivity(
    String realm,
    String roomId,
    String timestamp,
  ) async {
    try {
      final box = Hive.box(_chatRoomsBox);
      final key = '${realm}_$roomId';

      final Map<String, dynamic> roomInfo =
          Map<String, dynamic>.from((box.get(key) ?? {}) as Map);

      roomInfo['roomId'] = roomId;
      roomInfo['realm'] = realm;
      roomInfo['lastActivity'] = timestamp;
      roomInfo['messageCount'] = (roomInfo['messageCount'] ?? 0) + 1;

      await box.put(key, roomInfo);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating room activity: $e');
      }
    }
  }

  Future<void> _addToPendingSync(Map<String, dynamic> message) async {
    try {
      final box = Hive.box(_pendingSyncBox);
      final List<dynamic> pending = box.get('pending') ?? [];
      
      pending.add(message);
      
      await box.put('pending', pending);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error adding to pending sync: $e');
      }
    }
  }

  List<Map<String, dynamic>> _getWelcomeMessages(String roomId, String realm) {
    final now = DateTime.now();

    return [
      {
        'id': 'msg_welcome_$roomId',
        'message': '✨ Willkommen im ${_getRoomDisplayName(roomId, realm)} Chat!',
        'username': 'Weltenbibliothek',
        'userId': 'system',
        'timestamp': now.subtract(Duration(hours: 2)).toIso8601String(),
        'roomId': roomId,
        'realm': realm,
        'avatarEmoji': '🌟',
        'deleted': false,
        'edited': false,
        'reactions': {},
      },
      {
        'id': 'msg_voice_$roomId',
        'message': '🎤 Voice Chat ist aktiviert! Klicke auf den Voice Button oben rechts.',
        'username': 'System',
        'userId': 'system',
        'timestamp': now.subtract(Duration(hours: 1)).toIso8601String(),
        'roomId': roomId,
        'realm': realm,
        'avatarEmoji': '🔊',
        'deleted': false,
        'edited': false,
        'reactions': {},
      },
      {
        'id': 'msg_info_$roomId',
        'message': '💬 Schreibe deine erste Nachricht um den Chat zu starten!',
        'username': 'Weltenbibliothekedit',
        'userId': 'admin',
        'timestamp': now.subtract(Duration(minutes: 30)).toIso8601String(),
        'roomId': roomId,
        'realm': realm,
        'avatarEmoji': '👨‍💼',
        'deleted': false,
        'edited': false,
        'reactions': {},
      },
    ];
  }

  String _getRoomDisplayName(String roomId, String realm) {
    final roomNames = {
      // Energie Welt
      'meditation': 'Meditation & Achtsamkeit',
      'chakra': 'Chakra Heilung',
      'frequenz': 'Frequenz & Schwingung',
      'general_energie': 'Allgemeine Diskussion',

      // Materie Welt
      'politik': 'Politik & Weltgeschehen',
      'forschung': 'Forschung & Analyse',
      'ufos': 'UFOs & Phänomene',
      'general_materie': 'Allgemeine Diskussion',

      // Default
      'general': 'Allgemeiner Chat',
    };

    return roomNames[roomId] ?? roomId;
  }
}
