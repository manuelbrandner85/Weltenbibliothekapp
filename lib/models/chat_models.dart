/// 💬 CHAT MODELS
/// 
/// Complete chat message model with support for:
/// - Text, image, voice, file messages
/// - Reactions (emoji)
/// - Replies (threading)
/// - Message editing
/// - Read receipts
/// - Delivery status
library;

import 'package:flutter/foundation.dart';

/// Message Type Enum
enum MessageType {
  text,
  image,
  voice,
  file,
  system,
  deleted,
}

/// Message Status Enum
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

/// Chat Message Model
@immutable
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final DateTime? editedAt;
  
  // Reply/Thread support
  final String? replyToMessageId;
  final String? replyToContent;
  final String? replyToSenderName;
  
  // Reactions
  final Map<String, List<String>> reactions; // emoji -> [userId1, userId2]
  
  // Media attachments
  final String? imageUrl;
  final String? voiceUrl;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  
  // Read receipts
  final List<String> readBy;
  
  // Additional metadata
  final Map<String, dynamic> metadata;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.content,
    this.type = MessageType.text,
    this.status = MessageStatus.sending,
    required this.timestamp,
    this.editedAt,
    this.replyToMessageId,
    this.replyToContent,
    this.replyToSenderName,
    this.reactions = const {},
    this.imageUrl,
    this.voiceUrl,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.readBy = const [],
    this.metadata = const {},
  });

  /// Factory: Create text message
  factory ChatMessage.text({
    required String id,
    required String senderId,
    required String senderName,
    String? senderAvatarUrl,
    required String content,
    DateTime? timestamp,
    String? replyToMessageId,
    String? replyToContent,
    String? replyToSenderName,
  }) {
    return ChatMessage(
      id: id,
      senderId: senderId,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      content: content,
      type: MessageType.text,
      timestamp: timestamp ?? DateTime.now(),
      replyToMessageId: replyToMessageId,
      replyToContent: replyToContent,
      replyToSenderName: replyToSenderName,
    );
  }

  /// Factory: Create image message
  factory ChatMessage.image({
    required String id,
    required String senderId,
    required String senderName,
    String? senderAvatarUrl,
    required String imageUrl,
    String content = '',
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id,
      senderId: senderId,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      content: content,
      type: MessageType.image,
      imageUrl: imageUrl,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Factory: Create voice message
  factory ChatMessage.voice({
    required String id,
    required String senderId,
    required String senderName,
    String? senderAvatarUrl,
    required String voiceUrl,
    required int duration,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id,
      senderId: senderId,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      content: 'Voice message ($duration sec)',
      type: MessageType.voice,
      voiceUrl: voiceUrl,
      timestamp: timestamp ?? DateTime.now(),
      metadata: {'duration': duration},
    );
  }

  /// Factory: Create file message
  factory ChatMessage.file({
    required String id,
    required String senderId,
    required String senderName,
    String? senderAvatarUrl,
    required String fileUrl,
    required String fileName,
    required int fileSize,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id,
      senderId: senderId,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      content: fileName,
      type: MessageType.file,
      fileUrl: fileUrl,
      fileName: fileName,
      fileSize: fileSize,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Factory: Create system message
  factory ChatMessage.system({
    required String id,
    required String content,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id,
      senderId: 'system',
      senderName: 'System',
      content: content,
      type: MessageType.system,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Factory: From JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      senderName: json['sender_name'] as String,
      senderAvatarUrl: json['sender_avatar_url'] as String?,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      editedAt: json['edited_at'] != null 
          ? DateTime.parse(json['edited_at'] as String)
          : null,
      replyToMessageId: json['reply_to_message_id'] as String?,
      replyToContent: json['reply_to_content'] as String?,
      replyToSenderName: json['reply_to_sender_name'] as String?,
      reactions: (json['reactions'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(
                key,
                (value as List<dynamic>).map((e) => e.toString()).toList(),
              )) ?? {},
      imageUrl: json['image_url'] as String?,
      voiceUrl: json['voice_url'] as String?,
      fileUrl: json['file_url'] as String?,
      fileName: json['file_name'] as String?,
      fileSize: json['file_size'] as int?,
      readBy: (json['read_by'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar_url': senderAvatarUrl,
      'content': content,
      'type': type.name,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'edited_at': editedAt?.toIso8601String(),
      'reply_to_message_id': replyToMessageId,
      'reply_to_content': replyToContent,
      'reply_to_sender_name': replyToSenderName,
      'reactions': reactions,
      'image_url': imageUrl,
      'voice_url': voiceUrl,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'read_by': readBy,
      'metadata': metadata,
    };
  }

  /// Copy with
  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderAvatarUrl,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    DateTime? editedAt,
    String? replyToMessageId,
    String? replyToContent,
    String? replyToSenderName,
    Map<String, List<String>>? reactions,
    String? imageUrl,
    String? voiceUrl,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    List<String>? readBy,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      editedAt: editedAt ?? this.editedAt,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToContent: replyToContent ?? this.replyToContent,
      replyToSenderName: replyToSenderName ?? this.replyToSenderName,
      reactions: reactions ?? this.reactions,
      imageUrl: imageUrl ?? this.imageUrl,
      voiceUrl: voiceUrl ?? this.voiceUrl,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      readBy: readBy ?? this.readBy,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if message is edited
  bool get isEdited => editedAt != null;
  
  /// Check if message is a reply
  bool get isReply => replyToMessageId != null;
  
  /// Check if message has reactions
  bool get hasReactions => reactions.isNotEmpty;
  
  /// Get total reaction count
  int get reactionCount {
    return reactions.values.fold(0, (sum, users) => sum + users.length);
  }
  
  /// Check if message is read by user
  bool isReadBy(String userId) => readBy.contains(userId);
  
  /// Check if user reacted with emoji
  bool hasUserReactedWith(String userId, String emoji) {
    return reactions[emoji]?.contains(userId) ?? false;
  }
  
  /// Get formatted file size
  String get formattedFileSize {
    if (fileSize == null) return '';
    final kb = fileSize! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ChatMessage &&
        other.id == id &&
        other.senderId == senderId &&
        other.senderName == senderName &&
        other.senderAvatarUrl == senderAvatarUrl &&
        other.content == content &&
        other.type == type &&
        other.status == status &&
        other.timestamp == timestamp &&
        other.editedAt == editedAt &&
        other.replyToMessageId == replyToMessageId &&
        other.replyToContent == replyToContent &&
        other.replyToSenderName == replyToSenderName &&
        mapEquals(other.reactions, reactions) &&
        other.imageUrl == imageUrl &&
        other.voiceUrl == voiceUrl &&
        other.fileUrl == fileUrl &&
        other.fileName == fileName &&
        other.fileSize == fileSize &&
        listEquals(other.readBy, readBy) &&
        mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      senderId,
      senderName,
      senderAvatarUrl,
      content,
      type,
      status,
      timestamp,
      editedAt,
      replyToMessageId,
      replyToContent,
      replyToSenderName,
      reactions,
      imageUrl,
      voiceUrl,
      fileUrl,
      fileName,
      fileSize,
      Object.hashAll(readBy),
      metadata,
    );
  }

  @override
  String toString() {
    return 'ChatMessage('
        'id: $id, '
        'sender: $senderName, '
        'type: $type, '
        'status: $status, '
        'content: ${content.length > 50 ? content.substring(0, 50) + '...' : content}, '
        'timestamp: $timestamp, '
        'isEdited: $isEdited, '
        'isReply: $isReply, '
        'reactionCount: $reactionCount'
        ')';
  }
}
