import 'package:hive_flutter/hive_flutter.dart';
import '../models/chat_room_model.dart';
import '../models/message.dart';

/// Lokaler Chat-Service mit Hive (Fallback wenn Cloudflare nicht verfügbar)
class LocalChatService {
  static const String _chatRoomsBoxName = 'chat_rooms';
  static const String _messagesBoxName = 'messages';

  Box<dynamic>? _chatRoomsBox;
  Box<dynamic>? _messagesBox;

  /// Initialisiert Hive Boxes
  Future<void> initialize() async {
    try {
      _chatRoomsBox = await Hive.openBox(_chatRoomsBoxName);
      _messagesBox = await Hive.openBox(_messagesBoxName);

      // Fixe Chat-Räume initialisieren, falls noch nicht vorhanden
      await _initializeFixedChatRooms();
    } catch (e) {
      print('❌ [ERROR] Hive initialization failed: $e');
    }
  }

  /// Initialisiert fixe Chat-Räume
  Future<void> _initializeFixedChatRooms() async {
    final fixedRooms = ChatRoom.getFixedChatRooms();

    for (final room in fixedRooms) {
      // Nur hinzufügen, wenn noch nicht vorhanden
      if (_chatRoomsBox?.get(room.id) == null) {
        await _chatRoomsBox?.put(room.id, room.toJson());
      }
    }
  }

  /// Holt alle Chat-Räume (lokal)
  Future<List<ChatRoom>> getChatRooms() async {
    try {
      if (_chatRoomsBox == null) {
        await initialize();
      }

      final rooms = <ChatRoom>[];

      for (var key in _chatRoomsBox!.keys) {
        try {
          final roomData = _chatRoomsBox!.get(key) as Map<dynamic, dynamic>;
          final roomMap = Map<String, dynamic>.from(roomData);
          rooms.add(ChatRoom.fromJson(roomMap));
        } catch (e) {
          print('⚠️ [WARNING] Could not parse chat room $key: $e');
        }
      }

      // Nach lastMessageTime sortieren (neueste zuerst)
      rooms.sort((a, b) {
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });

      print('✅ [DEBUG] Loaded ${rooms.length} chat rooms from local storage');
      return rooms;
    } catch (e) {
      print('❌ [ERROR] getChatRooms failed: $e');
      return ChatRoom.getFixedChatRooms();
    }
  }

  /// Erstellt einen neuen Chat-Raum (lokal)
  Future<String> createChatRoom({
    required String name,
    required String description,
    required String createdBy,
    String emoji = '💬',
    String? customId, // Optional: Verwende Cloudflare-ID wenn verfügbar
  }) async {
    try {
      if (_chatRoomsBox == null) {
        await initialize();
      }

      // Verwende customId (von Cloudflare) oder generiere neue
      final id = customId ?? 'chat_${DateTime.now().millisecondsSinceEpoch}';

      final chatRoom = ChatRoom(
        id: id,
        name: name,
        description: description,
        type: 'user_created',
        emoji: emoji,
        memberCount: 1,
        isFixed: false,
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );

      await _chatRoomsBox?.put(id, chatRoom.toJson());

      print('✅ [DEBUG] Created chat room locally: $name ($id)');
      return id;
    } catch (e) {
      print('❌ [ERROR] createChatRoom failed: $e');
      throw Exception('Chat-Raum konnte nicht erstellt werden: $e');
    }
  }

  /// Holt Nachrichten eines Chat-Raums (lokal)
  Future<List<Message>> getMessages(String chatRoomId) async {
    try {
      if (_messagesBox == null) {
        await initialize();
      }

      final messagesKey = 'messages_$chatRoomId';
      final messagesData = _messagesBox?.get(messagesKey) as List<dynamic>?;

      if (messagesData == null) {
        return [];
      }

      final messages = messagesData.map((msgData) {
        final msgMap = Map<String, dynamic>.from(msgData as Map);
        return Message.fromJson(msgMap);
      }).toList();

      print(
        '✅ [DEBUG] Loaded ${messages.length} messages for room $chatRoomId',
      );
      return messages;
    } catch (e) {
      print('❌ [ERROR] getMessages failed: $e');
      return [];
    }
  }

  /// Sendet eine Nachricht (lokal)
  Future<void> sendMessage({
    required String chatRoomId,
    required String content,
    required String senderId,
    required String senderName,
  }) async {
    try {
      if (_messagesBox == null) {
        await initialize();
      }

      final message = Message(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        content: content,
        senderId: senderId,
        senderName: senderName,
        timestamp: DateTime.now(),
      );

      // Nachrichten für diesen Raum laden
      final messagesKey = 'messages_$chatRoomId';
      List<dynamic> messages =
          (_messagesBox?.get(messagesKey) as List<dynamic>?) ?? [];

      // Neue Nachricht hinzufügen
      messages.add(message.toJson());

      // Speichern
      await _messagesBox?.put(messagesKey, messages);

      // Chat-Raum aktualisieren (letzte Nachricht-Zeit)
      await _updateChatRoomLastMessage(chatRoomId);

      print('✅ [DEBUG] Message sent to room $chatRoomId');
    } catch (e) {
      print('❌ [ERROR] sendMessage failed: $e');
      throw Exception('Fehler beim Senden: $e');
    }
  }

  /// Aktualisiert die letzte Nachrichten-Zeit eines Chat-Raums
  Future<void> _updateChatRoomLastMessage(String chatRoomId) async {
    try {
      final roomData = _chatRoomsBox?.get(chatRoomId) as Map<dynamic, dynamic>?;

      if (roomData != null) {
        final roomMap = Map<String, dynamic>.from(roomData);
        roomMap['last_message_time'] = DateTime.now().toIso8601String();
        await _chatRoomsBox?.put(chatRoomId, roomMap);
      }
    } catch (e) {
      print('⚠️ [WARNING] Could not update last message time: $e');
    }
  }

  /// Löscht einen Chat-Raum (lokal)
  Future<void> deleteChatRoom(String chatRoomId) async {
    try {
      if (_chatRoomsBox == null) {
        await initialize();
      }

      // Chat-Raum löschen
      await _chatRoomsBox?.delete(chatRoomId);

      // Zugehörige Nachrichten löschen
      final messagesKey = 'messages_$chatRoomId';
      await _messagesBox?.delete(messagesKey);

      print('✅ [DEBUG] Deleted chat room: $chatRoomId');
    } catch (e) {
      print('❌ [ERROR] deleteChatRoom failed: $e');
      throw Exception('Fehler beim Löschen: $e');
    }
  }

  /// Bearbeitet eine Nachricht (lokal)
  Future<void> updateMessage({
    required String chatRoomId,
    required String messageId,
    required String newContent,
  }) async {
    try {
      if (_messagesBox == null) {
        await initialize();
      }

      final messagesKey = 'messages_$chatRoomId';
      List<dynamic> messages =
          (_messagesBox?.get(messagesKey) as List<dynamic>?) ?? [];

      // Finde und aktualisiere die Nachricht
      bool found = false;
      for (int i = 0; i < messages.length; i++) {
        final msgMap = messages[i] as Map<dynamic, dynamic>;
        if (msgMap['id'] == messageId) {
          msgMap['content'] = newContent;
          msgMap['is_edited'] = true;
          msgMap['edited_at'] = DateTime.now().toIso8601String();
          messages[i] = msgMap;
          found = true;
          break;
        }
      }

      if (found) {
        await _messagesBox?.put(messagesKey, messages);
        print('✅ [DEBUG] Message updated locally: $messageId');
      } else {
        print('⚠️ [WARNING] Message not found: $messageId');
      }
    } catch (e) {
      print('❌ [ERROR] updateMessage failed: $e');
      throw Exception('Fehler beim Bearbeiten: $e');
    }
  }

  /// Löscht eine Nachricht (lokal)
  Future<void> deleteMessage({
    required String chatRoomId,
    required String messageId,
  }) async {
    try {
      if (_messagesBox == null) {
        await initialize();
      }

      final messagesKey = 'messages_$chatRoomId';
      List<dynamic> messages =
          (_messagesBox?.get(messagesKey) as List<dynamic>?) ?? [];

      // Filtere die zu löschende Nachricht heraus
      final filteredMessages = messages.where((msg) {
        final msgMap = msg as Map<dynamic, dynamic>;
        return msgMap['id'] != messageId;
      }).toList();

      await _messagesBox?.put(messagesKey, filteredMessages);
      print('✅ [DEBUG] Message deleted locally: $messageId');
    } catch (e) {
      print('❌ [ERROR] deleteMessage failed: $e');
      throw Exception('Fehler beim Löschen: $e');
    }
  }

  /// Räumt Ressourcen auf
  void dispose() {
    // Hive Boxes werden automatisch geschlossen
  }
}
