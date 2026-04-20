class ResearchNote {
  String id;
  String title;
  String content;
  String sourceUrl;
  DateTime createdAt;
  DateTime updatedAt;
  List<String> tags;

  ResearchNote({
    required this.id,
    required this.title,
    required this.content,
    required this.sourceUrl,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
  });

  factory ResearchNote.create({
    required String title,
    required String content,
    required String sourceUrl,
    List<String> tags = const [],
  }) {
    final now = DateTime.now();
    return ResearchNote(
      id: now.millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      sourceUrl: sourceUrl,
      createdAt: now,
      updatedAt: now,
      tags: tags,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'sourceUrl': sourceUrl,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'tags': tags,
      };

  factory ResearchNote.fromJson(Map<String, dynamic> json) => ResearchNote(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        sourceUrl: json['sourceUrl'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        tags: (json['tags'] as List?)?.cast<String>() ?? [],
      );
}
