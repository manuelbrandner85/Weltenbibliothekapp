/// Spirit-Eintrag für ENERGIE-Welt
class SpiritEntry {
  final String id;
  final String title;
  final String content;
  final SpiritType type; // Journal, Symbol, Synchronicity, Mood
  final List<String> tags; // z.B. "Meditation", "Archetypen", "Traum"
  final DateTime createdAt;
  final String? mood; // Optional: Mood-Tracker
  final int? rating; // Optional: 1-5 Bewertung
  
  SpiritEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.tags,
    required this.createdAt,
    this.mood,
    this.rating,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type.name,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'mood': mood,
      'rating': rating,
    };
  }
  
  factory SpiritEntry.fromJson(Map<String, dynamic> json) {
    return SpiritEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      type: SpiritType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SpiritType.journal,
      ),
      tags: List<String>.from(json['tags'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      mood: json['mood'] as String?,
      rating: json['rating'] as int?,
    );
  }
}

/// Spirit-Entry Typen
enum SpiritType {
  journal,        // Inneres Journal
  symbol,         // Symbol-Explorer
  synchronicity,  // Synchronizitäts-Log
  mood,          // Mood-Tracker
  archetype,     // Archetypen-Muster
  dream,         // Traum-Log
}
