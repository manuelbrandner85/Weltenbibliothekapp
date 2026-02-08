import 'package:hive/hive.dart';

part 'favorite.g.dart';

/// Favorite Item Model v8.0
/// 
/// Speichert Lesezeichen & Favoriten lokal mit Hive
@HiveType(typeId: 0)
class Favorite extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  FavoriteType type;

  @HiveField(2)
  String title;

  @HiveField(3)
  String? description;

  @HiveField(4)
  String? url;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  Map<String, dynamic>? metadata;

  @HiveField(7)
  List<String>? tags;

  Favorite({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.url,
    required this.createdAt,
    this.metadata,
    this.tags,
  });

  // JSON Serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'title': title,
      'description': description,
      'url': url,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
      'tags': tags,
    };
  }

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'] as String,
      type: FavoriteType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => FavoriteType.research,
      ),
      title: json['title'] as String,
      description: json['description'] as String?,
      url: json['url'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
      tags: (json['tags'] as List?)?.cast<String>(),
    );
  }
}

/// Favorite Types
@HiveType(typeId: 1)
enum FavoriteType {
  @HiveField(0)
  research,      // Recherche-Ergebnisse
  
  @HiveField(1)
  narrative,     // Narratives (Area 51, MK-Ultra, etc.)
  
  @HiveField(2)
  pdf,           // PDF Dokumente
  
  @HiveField(3)
  image,         // Bilder
  
  @HiveField(4)
  video,         // Videos
  
  @HiveField(5)
  telegram,      // Telegram Kanäle
  
  @HiveField(6)
  source,        // Quellen/Links
}

extension FavoriteTypeExtension on FavoriteType {
  String get label {
    switch (this) {
      case FavoriteType.research:
        return 'Recherche';
      case FavoriteType.narrative:
        return 'Narrative';
      case FavoriteType.pdf:
        return 'PDF';
      case FavoriteType.image:
        return 'Bild';
      case FavoriteType.video:
        return 'Video';
      case FavoriteType.telegram:
        return 'Telegram';
      case FavoriteType.source:
        return 'Quelle';
    }
  }

  String get icon {
    switch (this) {
      case FavoriteType.research:
        return '🔍';
      case FavoriteType.narrative:
        return '📖';
      case FavoriteType.pdf:
        return '📄';
      case FavoriteType.image:
        return '🖼️';
      case FavoriteType.video:
        return '🎥';
      case FavoriteType.telegram:
        return '📱';
      case FavoriteType.source:
        return '🔗';
    }
  }
}
