import 'package:hive/hive.dart';

part 'research_note.g.dart';

@HiveType(typeId: 10)
class ResearchNote extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content;

  @HiveField(3)
  String sourceUrl;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  @HiveField(6)
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
}
