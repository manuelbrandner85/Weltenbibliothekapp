/// 📚 BOOK MODEL - Professionelle wissenschaftliche Bücher
/// Akademische Qualität: Quellen, Zitate, Fußnoten, Bibliographie
class Book {
  final String id;
  final String title;
  final String author;
  final String category;
  final String description;
  final String coverImageUrl;
  final List<BookChapter> chapters;
  final List<String> tags;
  final int estimatedReadingMinutes;
  final BookType type;
  final DifficultyLevel difficulty;
  final DateTime publishedDate;
  final String language;
  final String isbn;
  final String publisher;
  final String edition;
  final List<String> keywords;
  final String abstract;
  final List<Reference> bibliography;
  final Map<String, String> metadata;
  
  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.description,
    required this.coverImageUrl,
    required this.chapters,
    required this.tags,
    required this.estimatedReadingMinutes,
    required this.type,
    required this.difficulty,
    required this.publishedDate,
    required this.language,
    this.isbn = '',
    this.publisher = '',
    this.edition = '',
    this.keywords = const [],
    this.abstract = '',
    this.bibliography = const [],
    this.metadata = const {},
  });
  
  // Berechnete Properties
  int get totalChapters => chapters.length;
  int get totalWords => chapters.fold(0, (sum, chapter) => sum + chapter.wordCount);
  String get formattedReadingTime {
    final hours = estimatedReadingMinutes ~/ 60;
    final minutes = estimatedReadingMinutes % 60;
    if (hours > 0) {
      return '$hours Std $minutes Min';
    }
    return '$minutes Min';
  }
  
  // JSON Serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'author': author,
    'category': category,
    'description': description,
    'coverImageUrl': coverImageUrl,
    'chapters': chapters.map((c) => c.toJson()).toList(),
    'tags': tags,
    'estimatedReadingMinutes': estimatedReadingMinutes,
    'type': type.toString(),
    'difficulty': difficulty.toString(),
    'publishedDate': publishedDate.toIso8601String(),
    'language': language,
  };
  
  factory Book.fromJson(Map<String, dynamic> json) => Book(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    author: json['author'] ?? '',
    category: json['category'] ?? '',
    description: json['description'] ?? '',
    coverImageUrl: json['coverImageUrl'] ?? '',
    chapters: (json['chapters'] as List?)?.map((c) => BookChapter.fromJson(c)).toList() ?? [],
    tags: List<String>.from(json['tags'] ?? []),
    estimatedReadingMinutes: json['estimatedReadingMinutes'] ?? 0,
    type: BookType.values.firstWhere(
      (e) => e.toString() == json['type'],
      orElse: () => BookType.book,
    ),
    difficulty: DifficultyLevel.values.firstWhere(
      (e) => e.toString() == json['difficulty'],
      orElse: () => DifficultyLevel.intermediate,
    ),
    publishedDate: DateTime.parse(json['publishedDate'] ?? DateTime.now().toIso8601String()),
    language: json['language'] ?? 'de',
  );
}

/// 📖 BOOK CHAPTER - Wissenschaftliches Kapitel mit Quellen
class BookChapter {
  final String id;
  final int chapterNumber;
  final String title;
  final String content;
  final List<String> sections;
  final int wordCount;
  final int estimatedMinutes;
  final List<String> keyPoints;
  final List<Citation> citations;
  final List<Figure> figures;
  final String summary;
  
  BookChapter({
    required this.id,
    required this.chapterNumber,
    required this.title,
    required this.content,
    required this.sections,
    required this.wordCount,
    required this.estimatedMinutes,
    this.keyPoints = const [],
    this.citations = const [],
    this.figures = const [],
    this.summary = '',
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'chapterNumber': chapterNumber,
    'title': title,
    'content': content,
    'sections': sections,
    'wordCount': wordCount,
    'estimatedMinutes': estimatedMinutes,
  };
  
  factory BookChapter.fromJson(Map<String, dynamic> json) => BookChapter(
    id: json['id'] ?? '',
    chapterNumber: json['chapterNumber'] ?? 0,
    title: json['title'] ?? '',
    content: json['content'] ?? '',
    sections: List<String>.from(json['sections'] ?? []),
    wordCount: json['wordCount'] ?? 0,
    estimatedMinutes: json['estimatedMinutes'] ?? 0,
  );
}

/// 📚 BOOK TYPE - Art des Buches
enum BookType {
  book,           // Vollständiges Buch
  practice,       // Praxis-Anleitung
  encyclopedia,   // Lexikon/Enzyklopädie
  source,         // Quellen-Sammlung
  ritual,         // Ritual-Buch
}

/// 📊 DIFFICULTY LEVEL
enum DifficultyLevel {
  beginner,
  intermediate,
  advanced,
  expert,
}

extension DifficultyLevelExtension on DifficultyLevel {
  String get displayName {
    switch (this) {
      case DifficultyLevel.beginner:
        return 'Anfänger';
      case DifficultyLevel.intermediate:
        return 'Fortgeschritten';
      case DifficultyLevel.advanced:
        return 'Experte';
      case DifficultyLevel.expert:
        return 'Meister';
    }
  }
}

/// 📝 CITATION - Wissenschaftliche Zitate
class Citation {
  final String id;
  final String author;
  final String text;
  final String source;
  final int page;
  final int year;
  
  Citation({
    required this.id,
    required this.author,
    required this.text,
    required this.source,
    required this.page,
    required this.year,
  });
}

/// 📚 REFERENCE - Bibliographie-Eintrag
class Reference {
  final String id;
  final String author;
  final String title;
  final String publisher;
  final int year;
  final String isbn;
  final ReferenceType type;
  
  Reference({
    required this.id,
    required this.author,
    required this.title,
    required this.publisher,
    required this.year,
    this.isbn = '',
    required this.type,
  });
  
  String get formatted {
    switch (type) {
      case ReferenceType.book:
        return '$author ($year). $title. $publisher.';
      case ReferenceType.article:
        return '$author ($year). "$title". $publisher.';
      case ReferenceType.study:
        return '$author ($year). $title. $publisher.';
      case ReferenceType.website:
        return '$author ($year). $title. Available at: $publisher';
    }
  }
}

enum ReferenceType { book, article, study, website }

/// 📊 FIGURE - Abbildungen/Diagramme
class Figure {
  final String id;
  final String title;
  final String description;
  final FigureType type;
  final String data; // Kann JSON für Diagramm-Daten enthalten
  
  Figure({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.data,
  });
}

enum FigureType { chart, table, timeline, infographic, diagram }
