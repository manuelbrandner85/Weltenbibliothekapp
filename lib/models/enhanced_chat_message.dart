/// Enhanced Chat Message Model mit Reactions, Mentions & Read Status
class EnhancedChatMessage {
  final String id;
  final String roomId;
  final String username;
  final String message;
  final DateTime timestamp;
  final String? avatarEmoji;
  
  // 🆕 NEW FEATURES
  final Map<String, List<String>> reactions; // emoji -> [usernames]
  final List<String> mentions; // @username Liste
  final bool isRead; // Gelesen-Status
  final bool isPinned; // Angepinnte Nachricht
  final String? replyToMessageId; // Thread-Support
  
  // 🆕 MEDIA SUPPORT
  final String? imageUrl; // Bild-URL
  final String? audioUrl; // Voice Message URL
  final String? fileUrl;  // Datei-URL
  final String? fileName; // Dateiname
  final MessageType type; // Nachrichtentyp
  
  EnhancedChatMessage({
    required this.id,
    required this.roomId,
    required this.username,
    required this.message,
    required this.timestamp,
    this.avatarEmoji,
    this.reactions = const {},
    this.mentions = const [],
    this.isRead = false,
    this.isPinned = false,
    this.replyToMessageId,
    this.imageUrl,
    this.audioUrl,
    this.fileUrl,
    this.fileName,
    this.type = MessageType.text,
  });
  
  factory EnhancedChatMessage.fromMap(Map<String, dynamic> map) {
    return EnhancedChatMessage(
      id: map['id'] ?? '',
      roomId: map['room_id'] ?? map['room'] ?? '',
      username: map['username'] ?? 'Anonymous',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp'])
          : (map['created_at'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['created_at'])
              : DateTime.now()),
      avatarEmoji: map['avatar_emoji'] ?? map['avatar'],
      reactions: _parseReactions(map['reactions']),
      mentions: _parseMentions(map['mentions']),
      isRead: map['is_read'] ?? false,
      isPinned: map['is_pinned'] ?? false,
      replyToMessageId: map['reply_to_message_id'],
      imageUrl: map['image_url'],
      audioUrl: map['audio_url'],
      fileUrl: map['file_url'],
      fileName: map['file_name'],
      type: _parseMessageType(map['type']),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'room_id': roomId,
      'username': username,
      'message': message,
      'created_at': timestamp.millisecondsSinceEpoch,
      'avatar_emoji': avatarEmoji,
      'reactions': reactions,
      'mentions': mentions,
      'is_read': isRead,
      'is_pinned': isPinned,
      'reply_to_message_id': replyToMessageId,
      'image_url': imageUrl,
      'audio_url': audioUrl,
      'file_url': fileUrl,
      'file_name': fileName,
      'type': type.toString().split('.').last,
    };
  }
  
  // Reaction hinzufügen
  EnhancedChatMessage addReaction(String emoji, String username) {
    final newReactions = Map<String, List<String>>.from(reactions);
    if (newReactions.containsKey(emoji)) {
      if (!newReactions[emoji]!.contains(username)) {
        newReactions[emoji]!.add(username);
      }
    } else {
      newReactions[emoji] = [username];
    }
    
    return EnhancedChatMessage(
      id: id,
      roomId: roomId,
      username: username,
      message: message,
      timestamp: timestamp,
      avatarEmoji: avatarEmoji,
      reactions: newReactions,
      mentions: mentions,
      isRead: isRead,
      isPinned: isPinned,
      replyToMessageId: replyToMessageId,
    );
  }
  
  // Reaction entfernen
  EnhancedChatMessage removeReaction(String emoji, String username) {
    final newReactions = Map<String, List<String>>.from(reactions);
    if (newReactions.containsKey(emoji)) {
      newReactions[emoji]!.remove(username);
      if (newReactions[emoji]!.isEmpty) {
        newReactions.remove(emoji);
      }
    }
    
    return EnhancedChatMessage(
      id: id,
      roomId: roomId,
      username: username,
      message: message,
      timestamp: timestamp,
      avatarEmoji: avatarEmoji,
      reactions: newReactions,
      mentions: mentions,
      isRead: isRead,
      isPinned: isPinned,
      replyToMessageId: replyToMessageId,
    );
  }
  
  // Als gelesen markieren
  EnhancedChatMessage markAsRead() {
    return EnhancedChatMessage(
      id: id,
      roomId: roomId,
      username: username,
      message: message,
      timestamp: timestamp,
      avatarEmoji: avatarEmoji,
      reactions: reactions,
      mentions: mentions,
      isRead: true,
      isPinned: isPinned,
      replyToMessageId: replyToMessageId,
    );
  }
  
  // Mentions aus Text extrahieren
  static List<String> extractMentions(String text) {
    final regex = RegExp(r'@(\w+)');
    final matches = regex.allMatches(text);
    return matches.map((m) => m.group(1)!).toList();
  }
  
  // Reactions parsen
  static Map<String, List<String>> _parseReactions(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) {
      return data.map((key, value) => 
        MapEntry(key, (value as List).cast<String>())
      );
    }
    return {};
  }
  
  // Mentions parsen
  static List<String> _parseMentions(dynamic data) {
    if (data == null) return [];
    if (data is List) return data.cast<String>();
    if (data is String) return data.split(',').map((s) => s.trim()).toList();
    return [];
  }
  
  // Gesamtanzahl der Reactions
  int get totalReactions {
    return reactions.values.fold(0, (sum, users) => sum + users.length);
  }
  
  // Hat User reagiert?
  bool hasUserReacted(String username) {
    return reactions.values.any((users) => users.contains(username));
  }
  
  // Parse Message Type
  static MessageType _parseMessageType(dynamic type) {
    if (type == null) return MessageType.text;
    final typeStr = type.toString().toLowerCase();
    switch (typeStr) {
      case 'image': return MessageType.image;
      case 'audio': return MessageType.audio;
      case 'file': return MessageType.file;
      default: return MessageType.text;
    }
  }
}

/// Message Type Enum
enum MessageType {
  text,
  image,
  audio,
  file,
}
