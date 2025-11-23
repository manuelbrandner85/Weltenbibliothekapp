import 'package:latlong2/latlong.dart';

/// Event-Modell für geografische Ereignisse
class EventModel {
  final String id;
  final String title;
  final String description;
  final LatLng location;
  final String category;
  final DateTime date;
  final String? imageUrl;
  final String? videoUrl;
  final String? documentUrl;
  final List<String> tags;
  final String? source;
  final bool isVerified;
  final double? resonanceFrequency; // Neue Eigenschaft für mystische Frequenz

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.category,
    required this.date,
    this.imageUrl,
    this.videoUrl,
    this.documentUrl,
    this.tags = const [],
    this.source,
    this.isVerified = false,
    this.resonanceFrequency,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      location: LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      imageUrl: json['image_url'] as String?,
      videoUrl: json['video_url'] as String?,
      documentUrl: json['document_url'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      source: json['source'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      resonanceFrequency: (json['resonance_frequency'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'category': category,
      'date': date.toIso8601String(),
      'image_url': imageUrl,
      'video_url': videoUrl,
      'document_url': documentUrl,
      'tags': tags,
      'source': source,
      'is_verified': isVerified,
      'resonance_frequency': resonanceFrequency,
    };
  }

  /// Helper-Methode um Kategorie-Namen zu erhalten
  static String getCategoryName(String category) {
    try {
      return EventCategory.values.firstWhere((e) => e.name == category).label;
    } catch (e) {
      return category;
    }
  }
}

/// Event-Kategorien (umbenannt zu "Alternative Ereignisse")
enum EventCategory {
  history('Historisch', '🏛️'),
  alternative('Alternative Forschung', '🔍'),
  science('Wissenschaft', '🔬'),
  archaeology('Archäologie', '⚱️'),
  mystery('Mysterium', '❓'),
  document('Dokument', '📄'),
  video('Video', '🎥'),
  conference('Konferenz', '🎤'),
  ancient('Antike Zivilisationen', '🗿'),
  energy('Energiepunkte', '⚡'),
  phenomenon('Phänomene', '🌟');

  final String label;
  final String emoji;
  const EventCategory(this.label, this.emoji);
}
