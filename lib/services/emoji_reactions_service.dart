/// 🎨 EMOJI REACTIONS SERVICE
/// Handle emoji reactions on messages
library;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class EmojiReactionsService {
  static final EmojiReactionsService _instance = EmojiReactionsService._internal();
  factory EmojiReactionsService() => _instance;
  EmojiReactionsService._internal();

  final String _baseUrl = 'https://chat-features-weltenbibliothek.brandy13062.workers.dev';

  /// Add or Remove Reaction (Toggle)
  Future<Map<String, dynamic>?> toggleReaction({
    required String messageId,
    required String userId,
    required String username,
    required String emoji,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/messages/$messageId/react'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'username': username,
          'emoji': emoji,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (kDebugMode) {
          debugPrint('✅ [Reactions] Toggled $emoji on message $messageId');
        }
        return data;
      } else {
        if (kDebugMode) {
          debugPrint('❌ [Reactions] Failed: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Reactions] Error: $e');
      }
      return null;
    }
  }

  /// Get Reactions for Message
  Future<Map<String, dynamic>?> getReactions(String messageId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/messages/$messageId/reactions'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Reactions] Get error: $e');
      }
      return null;
    }
  }

  /// Popular Emoji List (Häufig genutzte)
  List<String> get popularEmojis => [
    '👍', '❤️', '😂', '😮', '😢', '🙏',
    '🔥', '⭐', '✅', '❌', '💯', '🎉',
    '👀', '💪', '🤔', '😱', '🚀', '💡',
  ];
}

/// Emoji Reaction Model
class EmojiReaction {
  final String emoji;
  final List<ReactionUser> users;

  EmojiReaction({
    required this.emoji,
    required this.users,
  });

  factory EmojiReaction.fromJson(String emoji, List<dynamic> usersJson) {
    return EmojiReaction(
      emoji: emoji,
      users: usersJson
          .map((u) => ReactionUser.fromJson(u as Map<String, dynamic>))
          .toList(),
    );
  }

  int get count => users.length;
  
  bool hasUser(String userId) {
    return users.any((u) => u.userId == userId);
  }
}

class ReactionUser {
  final String userId;
  final String username;

  ReactionUser({
    required this.userId,
    required this.username,
  });

  factory ReactionUser.fromJson(Map<String, dynamic> json) {
    return ReactionUser(
      userId: json['userId'] as String,
      username: json['username'] as String,
    );
  }
}
