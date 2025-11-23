import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chat_room_model.dart';
import '../models/message.dart';
import 'auth_service.dart';

/// Cloudflare D1 Chat Service - Echte Datenbank-Integration
class CloudflareChatService {
  // ✅ Cloudflare Workers Chat API URL (UPDATED!)
  static const String _baseUrl = String.fromEnvironment(
    'CLOUDFLARE_API_URL',
    defaultValue: 'https://weltenbibliothek.brandy13062.workers.dev',
  );

  final http.Client _client = http.Client();

  /// Holt alle Chat-Räume von Cloudflare D1
  Future<List<ChatRoom>> getChatRooms() async {
    try {
      print('🔍 [DEBUG] Lade Chat-Räume von: $_baseUrl/chat-rooms');

      final response = await _client.get(
        Uri.parse('$_baseUrl/chat-rooms'),
        headers: {'Content-Type': 'application/json'},
      );

      print('🔍 [DEBUG] GET /chat-rooms - Status: ${response.statusCode}');
      print('🔍 [DEBUG] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final rawRooms = data['chat_rooms'] as List;

        if (kDebugMode) debugPrint('🔍 Raw Rooms Count: ${rawRooms.length}');

        final rooms = rawRooms
            .map((room) {
              try {
                print(
                  '🔍 [DEBUG] Parsing room: ${room['name']} (is_fixed: ${room['is_fixed']}, type: ${room['is_fixed'].runtimeType})',
                );
                return ChatRoom.fromJson(room as Map<String, dynamic>);
              } catch (e) {
                print('❌ [ERROR] Failed to parse room: $e');
                print('    Room data: $room');
                return null;
              }
            })
            .where((room) => room != null)
            .cast<ChatRoom>()
            .toList();

        print('✅ [DEBUG] Erfolgreich geparste Chat-Räume: ${rooms.length}');
        for (final room in rooms) {
          print(
            '  - ${room.emoji} ${room.name} (${room.id}, isFixed: ${room.isFixed})',
          );
        }

        return rooms;
      } else {
        print('❌ [ERROR] API Error: ${response.statusCode} - ${response.body}');
        // Fallback auf fixe Räume bei Fehler
        return ChatRoom.getFixedChatRooms();
      }
    } catch (e, stackTrace) {
      print('❌ [ERROR] Exception in getChatRooms: $e');
      print('❌ [ERROR] Stack Trace: $stackTrace');
      // Bei Netzwerkfehler: Fixe Räume zurückgeben
      return ChatRoom.getFixedChatRooms();
    }
  }

  /// Erstellt einen neuen Chat-Raum
  Future<String> createChatRoom({
    required String name,
    required String description,
    required String createdBy,
    String emoji = '💬',
  }) async {
    try {
      print('📝 [SERVICE] Erstelle Chat-Raum: $name');
      print('   URL: $_baseUrl/chat-rooms');

      final requestBody = {
        'name': name,
        'description': description,
        'created_by': createdBy,
        'emoji': emoji,
      };

      print('   Body: $requestBody');

      final response = await _client.post(
        Uri.parse('$_baseUrl/chat-rooms'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print('📝 [SERVICE] Create Response: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final chatId = data['id'] as String;
        print('✅ [SERVICE] Chat-Raum erfolgreich erstellt! ID: $chatId');
        return chatId;
      } else {
        print('❌ [SERVICE] Fehler: ${response.statusCode} - ${response.body}');
        throw Exception(
          'Fehler beim Erstellen des Chat-Raums: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      print('❌ [SERVICE] Exception beim Erstellen: $e');
      print('   Stack: $stackTrace');
      throw Exception('Chat-Raum konnte nicht erstellt werden: $e');
    }
  }

  /// Holt Nachrichten eines Chat-Raums (mit JWT Auth)
  Future<List<Message>> getMessages(String chatRoomId) async {
    try {
      // JWT Token holen
      final authService = AuthService();
      final token = authService.token;

      if (token == null) {
        print(
          '⚠️ [WARNING] Kein JWT Token vorhanden - Nutzer nicht authentifiziert',
        );
        return [];
      }

      final response = await _client.get(
        Uri.parse('$_baseUrl/messages/$chatRoomId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final messages = (data['messages'] as List)
            .map((msg) => Message.fromJson(msg as Map<String, dynamic>))
            .toList();
        print('✅ [DEBUG] ${messages.length} Nachrichten geladen');
        return messages;
      } else {
        print('❌ [ERROR] getMessages failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ [ERROR] getMessages exception: $e');
      return [];
    }
  }

  /// Sendet eine Nachricht (mit JWT Auth - Username wird automatisch aus Token extrahiert)
  Future<void> sendMessage({
    required String chatRoomId,
    required String content,
    String type = 'text',
  }) async {
    try {
      // JWT Token holen
      final authService = AuthService();
      final token = authService.token;

      if (token == null) {
        throw Exception('Nicht authentifiziert - bitte anmelden');
      }

      final url = '$_baseUrl/messages/$chatRoomId';
      print('📤 [DEBUG] Sende Nachricht an: $url');
      print('🔍 [DEBUG] Body: {content: $content, type: $type}');

      final response = await _client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'content': content, 'type': type}),
      );

      print('🔍 [DEBUG] Response status: ${response.statusCode}');
      print('🔍 [DEBUG] Response body: ${response.body}');

      if (response.statusCode != 201) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      print('✅ [DEBUG] Nachricht erfolgreich gesendet!');
    } catch (e) {
      print('❌ [ERROR] sendMessage failed: $e');
      throw Exception('Fehler beim Senden: $e');
    }
  }

  /// Löscht einen Chat-Raum (auch aus Cloudflare!)
  Future<void> deleteChatRoom(String chatRoomId) async {
    try {
      print('🗑️ [DEBUG] Lösche Chat-Raum: $chatRoomId');

      final response = await _client.delete(
        Uri.parse('$_baseUrl/chat-rooms/$chatRoomId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('🔍 [DEBUG] Delete Response: ${response.statusCode}');
      print('🔍 [DEBUG] Delete Body: ${response.body}');

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['error'] ?? 'Chat-Raum konnte nicht gelöscht werden',
        );
      }

      print('✅ [DEBUG] Chat-Raum erfolgreich gelöscht!');
    } catch (e) {
      print('❌ [ERROR] deleteChatRoom failed: $e');
      throw Exception('Fehler beim Löschen: $e');
    }
  }

  /// Löscht eine Nachricht (mit JWT Auth - nur eigene Nachrichten!)
  Future<void> deleteMessage({
    required String chatRoomId,
    required String messageId,
  }) async {
    try {
      // JWT Token holen
      final authService = AuthService();
      final token = authService.token;

      if (token == null) {
        throw Exception('Nicht authentifiziert - bitte anmelden');
      }

      print('🗑️ [DEBUG] Lösche Nachricht: $messageId in Raum: $chatRoomId');

      final response = await _client.delete(
        Uri.parse('$_baseUrl/messages/$chatRoomId/$messageId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔍 [DEBUG] Delete Message Response: ${response.statusCode}');

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['error'] ?? 'Nachricht konnte nicht gelöscht werden',
        );
      }

      print('✅ [DEBUG] Nachricht erfolgreich gelöscht!');
    } catch (e) {
      print('❌ [ERROR] deleteMessage failed: $e');
      throw Exception('Fehler beim Löschen der Nachricht: $e');
    }
  }

  /// Bearbeitet eine Nachricht (mit JWT Auth - nur eigene Nachrichten!)
  Future<void> updateMessage({
    required String chatRoomId,
    required String messageId,
    required String newContent,
  }) async {
    try {
      // JWT Token holen
      final authService = AuthService();
      final token = authService.token;

      if (token == null) {
        throw Exception('Nicht authentifiziert - bitte anmelden');
      }

      print('📝 [DEBUG] Bearbeite Nachricht: $messageId in Raum: $chatRoomId');

      final response = await _client.put(
        Uri.parse('$_baseUrl/messages/$chatRoomId/$messageId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'content': newContent}),
      );

      print('🔍 [DEBUG] Update Message Response: ${response.statusCode}');
      print('🔍 [DEBUG] Update Message Body: ${response.body}');

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['error'] ?? 'Nachricht konnte nicht bearbeitet werden',
        );
      }

      print('✅ [DEBUG] Nachricht erfolgreich bearbeitet!');
    } catch (e) {
      print('❌ [ERROR] updateMessage failed: $e');
      throw Exception('Fehler beim Bearbeiten der Nachricht: $e');
    }
  }

  /// Initialisiert fixe Chat-Räume in Cloudflare D1
  Future<void> initializeFixedChatRooms() async {
    try {
      await _client.post(
        Uri.parse('$_baseUrl/initialize-fixed-rooms'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      // Fehler ignorieren - fixe Räume existieren bereits lokal
    }
  }

  void dispose() {
    _client.close();
  }
}
