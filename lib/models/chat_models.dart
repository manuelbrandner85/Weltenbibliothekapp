/// 💬 MODERN CHAT MODELS
/// Shared data models for both Materie & Energie Chat
library;

import 'package:flutter/material.dart';

/// Chat Realm (World)
enum ChatRealm {
  materie,
  energie,
  spirit;

  String get displayName {
    switch (this) {
      case ChatRealm.materie:
        return 'MATERIE';
      case ChatRealm.energie:
        return 'ENERGIE';
      case ChatRealm.spirit:
        return 'SPIRIT';
    }
  }

  Color get primaryColor {
    switch (this) {
      case ChatRealm.materie:
        return Colors.red;
      case ChatRealm.energie:
        return const Color(0xFF9B51E0);
      case ChatRealm.spirit:
        return const Color(0xFF9B51E0);
    }
  }

  Color get accentColor {
    switch (this) {
      case ChatRealm.materie:
        return const Color(0xFFE53935);
      case ChatRealm.energie:
        return const Color(0xFF6A5ACD);
      case ChatRealm.spirit:
        return const Color(0xFF6A5ACD);
    }
  }
}

/// Message Status
enum MessageStatus {
  sending,    // 🕐 Wird gesendet
  sent,       // ✓ Auf Server
  delivered,  // ✓✓ Empfangen
  read,       // ✓✓ Gelesen (blau)
  failed;     // ❌ Fehler

  IconData get icon {
    switch (this) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.done;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error_outline;
    }
  }

  Color get color {
    switch (this) {
      case MessageStatus.sending:
        return Colors.grey;
      case MessageStatus.sent:
        return Colors.grey;
      case MessageStatus.delivered:
        return Colors.white70;
      case MessageStatus.read:
        return Colors.blue;
      case MessageStatus.failed:
        return Colors.red;
    }
  }
}

/// Chat Message (Enhanced)
class ChatMessage {
  final String id;
  final String userId;
  final String username;
  final String message;
  final DateTime timestamp;
  final String? avatarEmoji;
  final String? avatarUrl;
  final MessageStatus status;
  
  // Media
  final String? mediaType;  // 'image', 'voice', 'video'
  final String? mediaUrl;
  
  // Reactions
  final Map<String, List<String>> reactions;  // emoji -> [userIds]
  
  // Threading
  final String? replyToId;
  final ChatMessage? replyToMessage;
  
  // Editing
  final bool isEdited;
  final DateTime? editedAt;
  
  // Pinning
  final bool isPinned;
  final DateTime? pinnedAt;
  final String? pinnedBy;
  
  // Rich Text
  final List<MessageSegment>? segments;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.username,
    required this.message,
    required this.timestamp,
    this.avatarEmoji,
    this.avatarUrl,
    this.status = MessageStatus.sent,
    this.mediaType,
    this.mediaUrl,
    this.reactions = const {},
    this.replyToId,
    this.replyToMessage,
    this.isEdited = false,
    this.editedAt,
    this.isPinned = false,
    this.pinnedAt,
    this.pinnedBy,
    this.segments,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? json['message_id'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      username: json['username'] ?? '',
      message: json['message'] ?? json['text'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      avatarEmoji: json['avatar_emoji'] ?? json['avatarEmoji'],
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'],
      status: MessageStatus.sent,
      mediaType: json['media_type'] ?? json['mediaType'],
      mediaUrl: json['media_url'] ?? json['mediaUrl'],
      reactions: _parseReactions(json['reactions']),
      replyToId: json['reply_to_id'] ?? json['replyToId'],
      isEdited: json['is_edited'] ?? json['isEdited'] ?? false,
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'])
          : null,
      isPinned: json['is_pinned'] ?? json['isPinned'] ?? false,
      pinnedAt: json['pinned_at'] != null
          ? DateTime.parse(json['pinned_at'])
          : null,
      pinnedBy: json['pinned_by'] ?? json['pinnedBy'],
    );
  }

  static Map<String, List<String>> _parseReactions(dynamic reactions) {
    if (reactions == null) return {};
    if (reactions is Map) {
      return reactions.map((key, value) {
        if (value is List) {
          return MapEntry(key.toString(), value.cast<String>());
        }
        return MapEntry(key.toString(), <String>[]);
      });
    }
    return {};
  }

  ChatMessage copyWith({
    MessageStatus? status,
    Map<String, List<String>>? reactions,
    bool? isEdited,
    DateTime? editedAt,
    bool? isPinned,
  }) {
    return ChatMessage(
      id: id,
      userId: userId,
      username: username,
      message: message,
      timestamp: timestamp,
      avatarEmoji: avatarEmoji,
      avatarUrl: avatarUrl,
      status: status ?? this.status,
      mediaType: mediaType,
      mediaUrl: mediaUrl,
      reactions: reactions ?? this.reactions,
      replyToId: replyToId,
      replyToMessage: replyToMessage,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      isPinned: isPinned ?? this.isPinned,
      pinnedAt: pinnedAt,
      pinnedBy: pinnedBy,
      segments: segments,
    );
  }
}

/// Message Segment (Rich Text)
class MessageSegment {
  final String text;
  final MessageSegmentType type;
  final String? data;  // Link URL, mention userId, etc.

  MessageSegment({
    required this.text,
    required this.type,
    this.data,
  });
}

enum MessageSegmentType {
  text,
  bold,
  italic,
  code,
  strikethrough,
  mention,
  link,
  channel,
}

/// Voice Room Participant
/// Voice Room Mode
enum VoiceRoomMode {
  openMic,      // 🎤 Alle können sprechen
  raiseHand,    // ✋ Moderator-Freigabe nötig
  speakerOnly,  // 🔊 Nur Speaker sprechen
  listenOnly    // 👂 Nur zuhören
}

/// Voice Participant Role
enum VoiceRole {
  participant,  // 👤 Normaler Teilnehmer
  speaker,      // 🔊 Speaker (kann sprechen)
  moderator     // 👑 Moderator (volle Kontrolle)
}

class VoiceParticipant {
  final String userId;
  final String username;
  final String? avatarEmoji;
  final bool isSpeaking;
  final bool isMuted;
  final double volume;
  final VoiceRole role;
  final bool handRaised;

  VoiceParticipant({
    required this.userId,
    required this.username,
    this.avatarEmoji,
    this.isSpeaking = false,
    this.isMuted = false,
    this.volume = 1.0,
    this.role = VoiceRole.participant,
    this.handRaised = false,
  });

  VoiceParticipant copyWith({
    bool? isSpeaking,
    bool? isMuted,
    double? volume,
    VoiceRole? role,
    bool? handRaised,
  }) {
    return VoiceParticipant(
      userId: userId,
      username: username,
      avatarEmoji: avatarEmoji,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isMuted: isMuted ?? this.isMuted,
      volume: volume ?? this.volume,
      role: role ?? this.role,
      handRaised: handRaised ?? this.handRaised,
    );
  }
}

/// Voice Room
class VoiceRoom {
  final String roomId;
  final List<VoiceParticipant> participants;
  final int maxParticipants;
  final VoiceRoomMode mode;

  VoiceRoom({
    required this.roomId,
    this.participants = const [],
    this.maxParticipants = 10,
    this.mode = VoiceRoomMode.openMic,
  });

  bool get isFull => participants.length >= maxParticipants;
  int get participantCount => participants.length;
}

/// Typing Indicator
class TypingUser {
  final String userId;
  final String username;
  final DateTime timestamp;

  TypingUser({
    required this.userId,
    required this.username,
    required this.timestamp,
  });

  bool get isExpired {
    return DateTime.now().difference(timestamp).inSeconds > 3;
  }
}
