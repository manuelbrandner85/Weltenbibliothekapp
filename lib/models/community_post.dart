import 'dart:convert';

/// Community-Post (für beide Welten) mit Media-Support
class CommunityPost {
  final String id;
  final String authorUsername;
  final String? authorAvatar; // Avatar-Emoji
  final String content;
  final List<String> tags;
  final DateTime createdAt;
  final int likes;
  final int comments;
  final int? shares;
  final bool? hasImage; // Deprecated - verwende mediaUrl
  final String? mediaUrl; // 🆕 R2 Storage URL (Bild oder Video)
  final String? mediaType; // 🆕 'image' oder 'video'
  final WorldType worldType; // Materie oder Energie
  
  CommunityPost({
    required this.id,
    required this.authorUsername,
    this.authorAvatar,
    required this.content,
    required this.tags,
    required this.createdAt,
    this.likes = 0,
    this.comments = 0,
    this.shares,
    this.hasImage,
    this.mediaUrl,  // 🆕
    this.mediaType, // 🆕
    required this.worldType,
  });
  
  /// Hat Post Media?
  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;
  
  /// Ist Media ein Bild?
  bool get isImage => mediaType == 'image';
  
  /// Ist Media ein Video?
  bool get isVideo => mediaType == 'video';
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorUsername': authorUsername,
      'authorAvatar': authorAvatar,
      'content': content,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'hasImage': hasImage,
      'mediaUrl': mediaUrl,   // 🆕
      'mediaType': mediaType, // 🆕
      'worldType': worldType.name,
    };
  }
  
  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    // Parse tags - kann String (JSON) oder List sein
    List<String> parsedTags = [];
    if (json['tags'] != null) {
      if (json['tags'] is String) {
        // Backend sendet JSON-String
        try {
          final decoded = jsonDecode(json['tags'] as String);
          parsedTags = List<String>.from(decoded as List);
        } catch (e) {
          parsedTags = []; // Fallback bei Parse-Fehler
        }
      } else if (json['tags'] is List) {
        // Bereits als Liste
        parsedTags = List<String>.from(json['tags'] as List);
      }
    }
    
    return CommunityPost(
      id: json['id'] as String,
      authorUsername: json['authorUsername'] as String,
      authorAvatar: json['authorAvatar'] as String?,
      content: json['content'] as String,
      tags: parsedTags,
      createdAt: DateTime.parse(json['createdAt'] as String),
      likes: json['likes'] as int? ?? 0,
      comments: json['comments'] as int? ?? 0,
      shares: json['shares'] as int?,
      hasImage: json['hasImage'] == null ? null : (json['hasImage'] is bool ? json['hasImage'] as bool : (json['hasImage'] as int) == 1),
      mediaUrl: json['mediaUrl'] as String?,   // 🆕
      mediaType: json['mediaType'] as String?, // 🆕
      worldType: WorldType.values.firstWhere(
        (e) => e.name == json['worldType'],
        orElse: () => WorldType.materie,
      ),
    );
  }
}

/// Welten-Typ für strikte Trennung
enum WorldType {
  materie,  // Forschung, Fakten, Geopolitik
  energie,  // Spiritualität, Bewusstsein
}
