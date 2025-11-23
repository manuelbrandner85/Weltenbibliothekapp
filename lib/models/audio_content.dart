/// 📚 Audio Content Model für Weltenbibliothek
class AudioContent {
  final String id;
  final String title;
  final String author;
  final int duration;
  final String thumbnailUrl;
  final String category;
  final String? description;
  final DateTime? addedDate;

  AudioContent({
    required this.id,
    required this.title,
    required this.author,
    required this.duration,
    required this.thumbnailUrl,
    required this.category,
    this.description,
    this.addedDate,
  });

  factory AudioContent.fromJson(Map<String, dynamic> json) {
    return AudioContent(
      id: json['videoId'] ?? json['id'] ?? '',
      title: json['title'] ?? 'Unbekannter Titel',
      author: json['author'] ?? 'Unbekannter Autor',
      duration: json['duration'] ?? 0,
      thumbnailUrl: json['thumbnail'] ?? '',
      category: json['category'] ?? 'Allgemein',
      description: json['description'],
      addedDate: json['addedDate'] != null
          ? DateTime.parse(json['addedDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videoId': id,
      'title': title,
      'author': author,
      'duration': duration,
      'thumbnail': thumbnailUrl,
      'category': category,
      'description': description,
      'addedDate': addedDate?.toIso8601String(),
    };
  }

  String get durationFormatted {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
