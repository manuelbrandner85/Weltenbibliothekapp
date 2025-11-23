import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MusicChatIntegrationService {
  // ✅ Cloudflare Workers URL - User hat die URL bereits konfiguriert
  static const String _cloudflareApiUrl =
      'https://weltenbibliothek.brandy13062.workers.dev';

  final http.Client _httpClient = http.Client();
  String? _currentUserId;
  String? _currentUserName;
  String? _currentRoomId;
  DateTime? _lastMessageTime;

  // Constructor mit optionalen Parametern
  MusicChatIntegrationService({
    String? chatRoomId,
    String? senderId,
    String? senderName,
  }) {
    if (chatRoomId != null && senderId != null && senderName != null) {
      setUserInfo(userId: senderId, userName: senderName, roomId: chatRoomId);
    }
  }

  void setUserInfo({
    required String userId,
    required String userName,
    required String roomId,
  }) {
    _currentUserId = userId;
    _currentUserName = userName;
    _currentRoomId = roomId;

    if (kDebugMode) {
      debugPrint('🎵 [MusicChat] User: $userName in room $roomId');
    }
  }

  Future<void> sendNowPlayingMessage({
    required String trackTitle,
    String? artistName,
  }) async {
    if (_currentUserId == null || _currentRoomId == null) {
      if (kDebugMode) {
        debugPrint('⚠️ [MusicChat] User info not set');
      }
      return;
    }

    if (!_canSendMessage()) {
      if (kDebugMode) {
        debugPrint('⚠️ [MusicChat] Rate limited (30s cooldown)');
      }
      return;
    }

    if (_cloudflareApiUrl == 'YOUR_CLOUDFLARE_WORKERS_URL_HERE') {
      if (kDebugMode) {
        debugPrint('⚠️ [MusicChat] Cloudflare URL not configured');
      }
      _logMessageLocally(trackTitle, artistName);
      return;
    }

    try {
      final messageText = _buildMessageText(trackTitle, artistName);

      final requestBody = {
        'roomId': _currentRoomId,
        'userId': _currentUserId,
        'userName': _currentUserName ?? 'Musik-Bot',
        'message': messageText,
        'type': 'music',
        'metadata': {'trackTitle': trackTitle, 'artistName': artistName},
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (kDebugMode) {
        debugPrint('📤 Sending: $messageText');
      }

      final response = await _httpClient.post(
        Uri.parse(_cloudflareApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _lastMessageTime = DateTime.now();
        if (kDebugMode) {
          debugPrint('✅ Message sent: $messageText');
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ API Error: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Network error: $e');
      }
    }
  }

  Future<void> sendMusicStoppedMessage() async {
    await _sendSystemMessage('⏸️ Musik gestoppt');
  }

  Future<void> sendLivestreamPausedMessage() async {
    await _sendSystemMessage(
      '🎥 Livestream gestartet - Musik automatisch pausiert',
    );
  }

  Future<void> _sendSystemMessage(String message) async {
    if (_currentUserId == null || _currentRoomId == null) return;

    if (_cloudflareApiUrl == 'YOUR_CLOUDFLARE_WORKERS_URL_HERE') {
      if (kDebugMode) {
        debugPrint('📝 System: $message');
      }
      return;
    }

    try {
      final requestBody = {
        'roomId': _currentRoomId,
        'userId': _currentUserId,
        'userName': _currentUserName ?? 'System',
        'message': message,
        'type': 'system',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await _httpClient.post(
        Uri.parse(_cloudflareApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          debugPrint('✅ System message sent');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to send: $e');
      }
    }
  }

  String _buildMessageText(String trackTitle, String? artistName) {
    if (artistName != null && artistName.isNotEmpty) {
      return '🎵 Jetzt läuft: $trackTitle von $artistName';
    } else {
      return '🎵 Jetzt läuft: $trackTitle';
    }
  }

  bool _canSendMessage() {
    if (_lastMessageTime == null) return true;
    final now = DateTime.now();
    final difference = now.difference(_lastMessageTime!);
    return difference.inSeconds >= 30;
  }

  void _logMessageLocally(String trackTitle, String? artistName) {
    final message = _buildMessageText(trackTitle, artistName);
    if (kDebugMode) {
      debugPrint('🎵 Would send: $message');
      debugPrint('   (Cloudflare not configured)');
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
