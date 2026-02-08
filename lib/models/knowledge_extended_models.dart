import 'package:flutter/material.dart';

/// ============================================
/// KNOWLEDGE EXTENDED MODELS
/// Erweiterte Datenmodelle für Wissens-System
/// ============================================

/// WISSENSDATENBANK-EINTRAG (Erweitert)
class KnowledgeEntry {
  final String id;
  final String world; // 'materie' oder 'energie'
  final String title;
  final String description;
  final String fullContent;
  final String category;
  final String type; // 'book', 'article', 'video', 'practice', 'research'
  final List<String> tags;
  final DateTime createdAt;
  final String? imageUrl;
  final String? author;
  final int? yearPublished;
  final String? sourceUrl;
  
  // Erweiterte Felder
  final int viewCount;
  final double rating; // 0.0 - 5.0
  final int readingTimeMinutes;

  KnowledgeEntry({
    required this.id,
    required this.world,
    required this.title,
    required this.description,
    required this.fullContent,
    required this.category,
    required this.type,
    required this.tags,
    required this.createdAt,
    this.imageUrl,
    this.author,
    this.yearPublished,
    this.sourceUrl,
    this.viewCount = 0,
    this.rating = 0.0,
    this.readingTimeMinutes = 10,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'world': world,
      'title': title,
      'description': description,
      'full_content': fullContent,
      'category': category,
      'type': type,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'image_url': imageUrl,
      'author': author,
      'year_published': yearPublished,
      'source_url': sourceUrl,
      'view_count': viewCount,
      'rating': rating,
      'reading_time_minutes': readingTimeMinutes,
    };
  }

  factory KnowledgeEntry.fromJson(Map<String, dynamic> json) {
    return KnowledgeEntry(
      id: json['id'] as String,
      world: json['world'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      fullContent: json['full_content'] as String,
      category: json['category'] as String,
      type: json['type'] as String,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: DateTime.parse(json['created_at'] as String),
      imageUrl: json['image_url'] as String?,
      author: json['author'] as String?,
      yearPublished: json['year_published'] as int?,
      sourceUrl: json['source_url'] as String?,
      viewCount: json['view_count'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      readingTimeMinutes: json['reading_time_minutes'] as int? ?? 10,
    );
  }

  KnowledgeEntry copyWith({
    String? id,
    String? world,
    String? title,
    String? description,
    String? fullContent,
    String? category,
    String? type,
    List<String>? tags,
    DateTime? createdAt,
    String? imageUrl,
    String? author,
    int? yearPublished,
    String? sourceUrl,
    int? viewCount,
    double? rating,
    int? readingTimeMinutes,
  }) {
    return KnowledgeEntry(
      id: id ?? this.id,
      world: world ?? this.world,
      title: title ?? this.title,
      description: description ?? this.description,
      fullContent: fullContent ?? this.fullContent,
      category: category ?? this.category,
      type: type ?? this.type,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
      author: author ?? this.author,
      yearPublished: yearPublished ?? this.yearPublished,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      viewCount: viewCount ?? this.viewCount,
      rating: rating ?? this.rating,
      readingTimeMinutes: readingTimeMinutes ?? this.readingTimeMinutes,
    );
  }
}

/// FAVORITEN-EINTRAG
class FavoriteEntry {
  final String knowledgeId;
  final DateTime addedAt;
  final String? notes;

  FavoriteEntry({
    required this.knowledgeId,
    required this.addedAt,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'knowledge_id': knowledgeId,
      'added_at': addedAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory FavoriteEntry.fromJson(Map<String, dynamic> json) {
    return FavoriteEntry(
      knowledgeId: json['knowledge_id'] as String,
      addedAt: DateTime.parse(json['added_at'] as String),
      notes: json['notes'] as String?,
    );
  }
}

/// NOTIZ ZU WISSENSEINTRAG
class KnowledgeNote {
  final String id;
  final String knowledgeId;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> tags;

  KnowledgeNote({
    required this.id,
    required this.knowledgeId,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'knowledge_id': knowledgeId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'tags': tags,
    };
  }

  factory KnowledgeNote.fromJson(Map<String, dynamic> json) {
    return KnowledgeNote(
      id: json['id'] as String,
      knowledgeId: json['knowledge_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

/// LESEFORTSCHRITT
class ReadingProgress {
  final String knowledgeId;
  final bool isRead;
  final DateTime? readAt;
  final int progressPercent; // 0-100
  final DateTime lastAccessedAt;

  ReadingProgress({
    required this.knowledgeId,
    required this.isRead,
    this.readAt,
    this.progressPercent = 0,
    required this.lastAccessedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'knowledge_id': knowledgeId,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'progress_percent': progressPercent,
      'last_accessed_at': lastAccessedAt.toIso8601String(),
    };
  }

  factory ReadingProgress.fromJson(Map<String, dynamic> json) {
    return ReadingProgress(
      knowledgeId: json['knowledge_id'] as String,
      isRead: json['is_read'] as bool,
      readAt: json['read_at'] != null 
          ? DateTime.parse(json['read_at'] as String)
          : null,
      progressPercent: json['progress_percent'] as int? ?? 0,
      lastAccessedAt: DateTime.parse(json['last_accessed_at'] as String),
    );
  }
}

/// KATEGORIEN ENUMS
enum KnowledgeCategory {
  // MATERIE
  conspiracy,
  ancientWisdom,
  forbiddenKnowledge,
  modernResearch,
  books,
  documentaries,
  
  // ENERGIE
  meditation,
  astrology,
  energyWork,
  consciousness,
  spiritualPractices,
  healing,
}

enum KnowledgeType {
  book,
  article,
  video,
  practice,
  research,
  documentary,
}

/// KATEGORIE-HELPERS
extension KnowledgeCategoryExtension on KnowledgeCategory {
  String get displayName {
    switch (this) {
      case KnowledgeCategory.conspiracy:
        return 'Verschwörungstheorien';
      case KnowledgeCategory.ancientWisdom:
        return 'Alte Weisheit';
      case KnowledgeCategory.forbiddenKnowledge:
        return 'Verbotenes Wissen';
      case KnowledgeCategory.modernResearch:
        return 'Moderne Forschung';
      case KnowledgeCategory.books:
        return 'Bücher';
      case KnowledgeCategory.documentaries:
        return 'Dokumentationen';
      case KnowledgeCategory.meditation:
        return 'Meditation';
      case KnowledgeCategory.astrology:
        return 'Astrologie';
      case KnowledgeCategory.energyWork:
        return 'Energie-Arbeit';
      case KnowledgeCategory.consciousness:
        return 'Bewusstsein';
      case KnowledgeCategory.spiritualPractices:
        return 'Spirituelle Praktiken';
      case KnowledgeCategory.healing:
        return 'Heilung';
    }
  }

  IconData get icon {
    switch (this) {
      case KnowledgeCategory.conspiracy:
        return Icons.psychology;
      case KnowledgeCategory.ancientWisdom:
        return Icons.auto_awesome;
      case KnowledgeCategory.forbiddenKnowledge:
        return Icons.lock;
      case KnowledgeCategory.modernResearch:
        return Icons.science;
      case KnowledgeCategory.books:
        return Icons.menu_book;
      case KnowledgeCategory.documentaries:
        return Icons.play_circle_outline;
      case KnowledgeCategory.meditation:
        return Icons.spa;
      case KnowledgeCategory.astrology:
        return Icons.stars;
      case KnowledgeCategory.energyWork:
        return Icons.energy_savings_leaf;
      case KnowledgeCategory.consciousness:
        return Icons.visibility;
      case KnowledgeCategory.spiritualPractices:
        return Icons.self_improvement;
      case KnowledgeCategory.healing:
        return Icons.healing;
    }
  }

  Color get color {
    switch (this) {
      case KnowledgeCategory.conspiracy:
        return const Color(0xFFE53935); // Red
      case KnowledgeCategory.ancientWisdom:
        return const Color(0xFFFFB300); // Amber
      case KnowledgeCategory.forbiddenKnowledge:
        return const Color(0xFF6A1B9A); // Deep Purple
      case KnowledgeCategory.modernResearch:
        return const Color(0xFF1E88E5); // Blue
      case KnowledgeCategory.books:
        return const Color(0xFF43A047); // Green
      case KnowledgeCategory.documentaries:
        return const Color(0xFFF4511E); // Deep Orange
      case KnowledgeCategory.meditation:
        return const Color(0xFF7E57C2); // Deep Purple Light
      case KnowledgeCategory.astrology:
        return const Color(0xFFAB47BC); // Purple
      case KnowledgeCategory.energyWork:
        return const Color(0xFF26A69A); // Teal
      case KnowledgeCategory.consciousness:
        return const Color(0xFF29B6F6); // Light Blue
      case KnowledgeCategory.spiritualPractices:
        return const Color(0xFF66BB6A); // Light Green
      case KnowledgeCategory.healing:
        return const Color(0xFFEC407A); // Pink
    }
  }
}
