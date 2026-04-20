import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import '../core/db/app_database.dart';

/// LOCAL CHAT STORAGE SERVICE (SQLite)
///
/// Offline-First Chat-Speicherung — ersetzt Hive-Boxen.
class LocalChatStorageService {
  static final LocalChatStorageService _instance = LocalChatStorageService._internal();
  factory LocalChatStorageService() => _instance;
  LocalChatStorageService._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await AppDatabase.instance.db;
    _initialized = true;
    if (kDebugMode) debugPrint('✅ LocalChatStorageService initialized');
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) await initialize();
  }

  // ──────────────────────────────────────────────────────
  // MESSAGES
  // ──────────────────────────────────────────────────────

  /// Get chat messages for a room (newest first, paginated)
  Future<List<Map<String, dynamic>>> getMessages(
    String roomId,
    String realm, {
    int limit = 50,
    int offset = 0,
  }) async {
    await _ensureInitialized();
    try {
      final db = await AppDatabase.instance.db;
      final key = '${realm}_$roomId';
      final rows = await db.query(
        'chat_messages',
        where: 'room_id = ?',
        whereArgs: [key],
        orderBy: 'created_at DESC',
        limit: limit,
        offset: offset,
      );
      if (rows.isEmpty) return _getWelcomeMessages(roomId, realm);
      return rows
          .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getting messages: $e');
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
    final db = await AppDatabase.instance.db;
    final key = '${realm}_$roomId';
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
      'synced': false,
    };

    // Keep only last 500 messages – delete oldest if over limit
    final count = (await db.rawQuery(
      'SELECT COUNT(*) as c FROM chat_messages WHERE room_id = ?', [key],
    )).first['c'] as int? ?? 0;
    if (count >= 500) {
      await db.rawDelete(
        '''DELETE FROM chat_messages WHERE room_id = ? AND id IN
           (SELECT id FROM chat_messages WHERE room_id = ? ORDER BY created_at ASC LIMIT ?)''',
        [key, key, count - 499],
      );
    }

    await db.insert('chat_messages', {
      'id': messageId,
      'room_id': key,
      'data': jsonEncode(chatMessage),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });

    await _addToPendingSync(chatMessage);
    await _updateRoomActivity(realm, roomId, timestamp);

    if (kDebugMode) debugPrint('💬 Message sent locally: $messageId in $roomId');
    return {'success': true, 'message': chatMessage};
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
    final db = await AppDatabase.instance.db;
    final key = '${realm}_$roomId';

    final rows = await db.query('chat_messages',
        where: 'id = ? AND room_id = ?', whereArgs: [messageId, key]);
    if (rows.isEmpty) throw Exception('Message not found');

    final msg = jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
    if (msg['userId'] != userId) throw Exception('Not authorized to edit this message');

    msg['message'] = newMessage;
    msg['edited'] = true;
    msg['editedAt'] = DateTime.now().toIso8601String();
    msg['synced'] = false;

    await db.update('chat_messages', {'data': jsonEncode(msg)},
        where: 'id = ? AND room_id = ?', whereArgs: [messageId, key]);
    await _addToPendingSync(msg);

    return {'success': true, 'message': msg};
  }

  /// Delete a message (hard delete)
  Future<Map<String, dynamic>> deleteMessage(
    String roomId,
    String realm,
    String messageId,
    String userId,
    bool isAdmin,
  ) async {
    await _ensureInitialized();
    final db = await AppDatabase.instance.db;
    final key = '${realm}_$roomId';

    final rows = await db.query('chat_messages',
        where: 'id = ? AND room_id = ?', whereArgs: [messageId, key]);
    if (rows.isEmpty) throw Exception('Message not found');

    final msg = jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
    if (msg['userId'] != userId && !isAdmin) {
      throw Exception('Not authorized to delete this message');
    }

    await db.delete('chat_messages',
        where: 'id = ? AND room_id = ?', whereArgs: [messageId, key]);
    return {'success': true, 'messageId': messageId};
  }

  // ──────────────────────────────────────────────────────
  // ROOMS
  // ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getRoomInfo(String realm, String roomId) async {
    await _ensureInitialized();
    final db = await AppDatabase.instance.db;
    final rows = await db.query('chat_rooms',
        where: 'room_id = ?', whereArgs: ['${realm}_$roomId']);
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
  }

  // ──────────────────────────────────────────────────────
  // PRESENCE
  // ──────────────────────────────────────────────────────

  Future<void> updatePresence(
    String realm,
    String roomId,
    String userId,
    String username,
    String avatarEmoji,
  ) async {
    await _ensureInitialized();
    final db = await AppDatabase.instance.db;
    await db.insert('chat_presence', {
      'user_id': userId,
      'room_id': '${realm}_$roomId',
      'data': jsonEncode({
        'username': username,
        'avatarEmoji': avatarEmoji,
        'lastSeen': DateTime.now().toIso8601String(),
        'status': 'online',
      }),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getOnlineUsers(String realm, String roomId) async {
    await _ensureInitialized();
    final db = await AppDatabase.instance.db;
    final rows = await db.query('chat_presence',
        where: 'room_id = ?', whereArgs: ['${realm}_$roomId']);
    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];
    for (final r in rows) {
      final data = jsonDecode(r['data'] as String) as Map<String, dynamic>;
      final lastSeen = DateTime.tryParse(data['lastSeen'] as String? ?? '');
      if (lastSeen != null && now.difference(lastSeen).inMinutes < 5) {
        result.add({'userId': r['user_id'], ...data});
      }
    }
    return result;
  }

  // ──────────────────────────────────────────────────────
  // MANAGEMENT
  // ──────────────────────────────────────────────────────

  Future<void> clearAllChatData() async {
    await _ensureInitialized();
    final db = await AppDatabase.instance.db;
    await db.delete('chat_messages');
    await db.delete('chat_rooms');
    await db.delete('chat_presence');
    await db.delete('chat_pending_sync');
    if (kDebugMode) debugPrint('✅ All chat data cleared');
  }

  // ──────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ──────────────────────────────────────────────────────

  Future<void> _updateRoomActivity(String realm, String roomId, String timestamp) async {
    try {
      final db = await AppDatabase.instance.db;
      final key = '${realm}_$roomId';
      final rows = await db.query('chat_rooms', where: 'room_id = ?', whereArgs: [key]);
      final info = rows.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
      info['roomId'] = roomId;
      info['realm'] = realm;
      info['lastActivity'] = timestamp;
      info['messageCount'] = ((info['messageCount'] as int?) ?? 0) + 1;
      await db.insert('chat_rooms', {'room_id': key, 'data': jsonEncode(info)},
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error updating room activity: $e');
    }
  }

  Future<void> _addToPendingSync(Map<String, dynamic> message) async {
    try {
      final db = await AppDatabase.instance.db;
      await db.insert('chat_pending_sync', {
        'id': message['id'] as String,
        'data': jsonEncode(message),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error adding to pending sync: $e');
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
        'timestamp': now.subtract(const Duration(hours: 2)).toIso8601String(),
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
        'timestamp': now.subtract(const Duration(hours: 1)).toIso8601String(),
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
        'username': 'Weltenbibliothek',
        'userId': 'admin',
        'timestamp': now.subtract(const Duration(minutes: 30)).toIso8601String(),
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
    const roomNames = {
      'meditation': 'Meditation & Achtsamkeit',
      'chakra': 'Chakra Heilung',
      'frequenz': 'Frequenz & Schwingung',
      'general_energie': 'Allgemeine Diskussion',
      'politik': 'Politik & Weltgeschehen',
      'forschung': 'Forschung & Analyse',
      'ufos': 'UFOs & Phänomene',
      'general_materie': 'Allgemeine Diskussion',
      'general': 'Allgemeiner Chat',
    };
    return roomNames[roomId] ?? roomId;
  }
}
