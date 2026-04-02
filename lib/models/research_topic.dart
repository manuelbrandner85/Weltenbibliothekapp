/// Recherche-Thema für MATERIE-Welt
class ResearchTopic {
  final String id;
  final String title;
  final String description;
  final List<String> categories; // z.B. "Geopolitik", "Geschichte", "Machtstrukturen"
  final List<String> sources;
  final DateTime createdAt;
  final int viewCount;
  final int commentCount;
  
  ResearchTopic({
    required this.id,
    required this.title,
    required this.description,
    required this.categories,
    required this.sources,
    required this.createdAt,
    this.viewCount = 0,
    this.commentCount = 0,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'categories': categories,
      'sources': sources,
      'createdAt': createdAt.toIso8601String(),
      'viewCount': viewCount,
      'commentCount': commentCount,
    };
  }
  
  factory ResearchTopic.fromJson(Map<String, dynamic> json) {
    return ResearchTopic(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      categories: List<String>.from(json['categories'] as List),
      sources: List<String>.from(json['sources'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      viewCount: json['viewCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
    );
  }
}
