// lib/models/narrative.dart
// WELTENBIBLIOTHEK v9.0 - Simple Narrative Model
// Placeholder model for Narrative Connection Engine

/// Simple Narrative Model
/// Represents a narrative/conspiracy theory/topic in the Weltenbibliothek
class Narrative {
  final String id;
  final String titel;
  final String? zusammenfassung;
  final String kategorie;
  final List<String>? tags;
  final DateTime? erstelltAm;
  final String? coverImageUrl;

  Narrative({
    required this.id,
    required this.titel,
    this.zusammenfassung,
    required this.kategorie,
    this.tags,
    this.erstelltAm,
    this.coverImageUrl,
  });

  /// Create from JSON
  factory Narrative.fromJson(Map<String, dynamic> json) {
    return Narrative(
      id: json['id'] as String,
      titel: json['titel'] as String,
      zusammenfassung: json['zusammenfassung'] as String?,
      kategorie: json['kategorie'] as String,
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList(),
      erstelltAm: json['erstellt_am'] != null 
          ? DateTime.tryParse(json['erstellt_am'] as String)
          : null,
      coverImageUrl: json['cover_image_url'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titel': titel,
      'zusammenfassung': zusammenfassung,
      'kategorie': kategorie,
      'tags': tags,
      'erstellt_am': erstelltAm?.toIso8601String(),
      'cover_image_url': coverImageUrl,
    };
  }

  @override
  String toString() {
    return 'Narrative(id: $id, titel: $titel, kategorie: $kategorie)';
  }
}
