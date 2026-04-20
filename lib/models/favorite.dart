/// Favorite Item Model v8.0
///
/// Speichert Lesezeichen & Favoriten lokal mit SQLite
class Favorite {
  String id;
  FavoriteType type;
  String title;
  String? description;
  String? url;
  DateTime createdAt;
  Map<String, dynamic>? metadata;
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
enum FavoriteType {
  research,      // Recherche-Ergebnisse
  narrative,     // Narratives (Area 51, MK-Ultra, etc.)
  pdf,           // PDF Dokumente
  image,         // Bilder
  video,         // Videos
  telegram,      // Telegram Kanäle
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
