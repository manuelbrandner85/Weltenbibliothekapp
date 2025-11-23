/// Nachrichten-Typ
enum MessageType { text, image, video, document, location, audio }

/// Nachrichten-Modell
class MessageModel {
  final String id;
  final String channelId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final MessageType type;
  final String content;
  final String? mediaUrl;
  final DateTime timestamp;
  final bool isRead;
  final int likes;
  final List<String> likedBy;
  final Map<String, List<String>> reactions; // NEW: Emoji -> List of user IDs

  MessageModel({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.type,
    required this.content,
    this.mediaUrl,
    required this.timestamp,
    this.isRead = false,
    this.likes = 0,
    this.likedBy = const [],
    this.reactions = const {}, // NEW: Default empty reactions
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      channelId: json['channel_id'] as String,
      senderId: json['sender_id'] as String,
      senderName: json['sender_name'] as String,
      senderAvatar: json['sender_avatar'] as String?,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      content: json['content'] as String,
      mediaUrl: json['media_url'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['is_read'] as bool? ?? false,
      likes: json['likes'] as int? ?? 0,
      likedBy: (json['liked_by'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channel_id': channelId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'type': type.name,
      'content': content,
      'media_url': mediaUrl,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'likes': likes,
      'liked_by': likedBy,
      'reactions': reactions,
    };
  }

  /// Helper: Get total reaction count
  int get totalReactionCount {
    return reactions.values.fold(0, (sum, users) => sum + users.length);
  }

  /// Helper: Check if user reacted with specific emoji
  bool hasUserReaction(String userId, String emoji) {
    return reactions[emoji]?.contains(userId) ?? false;
  }

  /// Helper: Copy with updated reactions
  MessageModel copyWithReaction(String emoji, String userId, bool add) {
    final newReactions = Map<String, List<String>>.from(reactions);

    if (add) {
      // Add reaction
      if (newReactions.containsKey(emoji)) {
        if (!newReactions[emoji]!.contains(userId)) {
          newReactions[emoji] = [...newReactions[emoji]!, userId];
        }
      } else {
        newReactions[emoji] = [userId];
      }
    } else {
      // Remove reaction
      if (newReactions.containsKey(emoji)) {
        newReactions[emoji] = newReactions[emoji]!
            .where((id) => id != userId)
            .toList();
        if (newReactions[emoji]!.isEmpty) {
          newReactions.remove(emoji);
        }
      }
    }

    return MessageModel(
      id: id,
      channelId: channelId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      type: type,
      content: content,
      mediaUrl: mediaUrl,
      timestamp: timestamp,
      isRead: isRead,
      likes: likes,
      likedBy: likedBy,
      reactions: newReactions,
    );
  }
}

/// Kanal/Gruppen-Modell
class ChannelModel {
  final String id;
  final String name;
  final String description;
  final String? avatarUrl;
  final String category;
  final int memberCount;
  final DateTime createdAt;
  final MessageModel? lastMessage;
  final bool isPinned;
  final bool isMuted;
  final int unreadCount;

  ChannelModel({
    required this.id,
    required this.name,
    required this.description,
    this.avatarUrl,
    required this.category,
    this.memberCount = 0,
    required this.createdAt,
    this.lastMessage,
    this.isPinned = false,
    this.isMuted = false,
    this.unreadCount = 0,
  });

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    return ChannelModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      avatarUrl: json['avatar_url'] as String?,
      category: json['category'] as String,
      memberCount: json['member_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastMessage: json['last_message'] != null
          ? MessageModel.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      isPinned: json['is_pinned'] as bool? ?? false,
      isMuted: json['is_muted'] as bool? ?? false,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'avatar_url': avatarUrl,
      'category': category,
      'member_count': memberCount,
      'created_at': createdAt.toIso8601String(),
      'last_message': lastMessage?.toJson(),
      'is_pinned': isPinned,
      'is_muted': isMuted,
      'unread_count': unreadCount,
    };
  }
}
