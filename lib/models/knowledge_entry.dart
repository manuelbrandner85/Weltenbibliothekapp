/// WISSENSDATENBANK EINTRAG
/// Für MATERIE und ENERGIE Wissens-Tabs
enum KnowledgeType {
  book,        // Buch
  practice,    // Praktik/Übung
  method,      // Methode/Technik
  symbol,      // Symbol/Zeichen
  ritual,      // Ritual
  concept,     // Konzept/Erklärung
  lexicon,     // Lexikon-Eintrag
  source,      // Quelle/Referenz
}

enum KnowledgeCategory {
  // MATERIE Kategorien
  geopolitics,
  alternativeMedia,
  research,
  conspiracy,
  history,
  science,
  
  // ENERGIE Kategorien
  meditation,
  chakra,
  astrology,
  numerology,
  sacred,
  healing,
  spirituality,
}

class KnowledgeEntry {
  final String id;
  final String title;
  final String description;
  final String fullContent;
  final KnowledgeType type;
  final KnowledgeCategory category;
  final List<String> tags;
  final String? author;
  final String? source;
  final DateTime? publishedDate;
  final int difficulty; // 1-5 (Einstieg bis Fortgeschritten)
  final int readingTime; // Minuten
  final bool isFavorite;
  
  KnowledgeEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.fullContent,
    required this.type,
    required this.category,
    required this.tags,
    this.author,
    this.source,
    this.publishedDate,
    this.difficulty = 3,
    this.readingTime = 5,
    this.isFavorite = false,
  });
  
  // Typ-Label
  String get typeLabel {
    switch (type) {
      case KnowledgeType.book:
        return 'BUCH';
      case KnowledgeType.practice:
        return 'PRAKTIK';
      case KnowledgeType.method:
        return 'METHODE';
      case KnowledgeType.symbol:
        return 'SYMBOL';
      case KnowledgeType.ritual:
        return 'RITUAL';
      case KnowledgeType.concept:
        return 'KONZEPT';
      case KnowledgeType.lexicon:
        return 'LEXIKON';
      case KnowledgeType.source:
        return 'QUELLE';
    }
  }
  
  // Kategorie-Label
  String get categoryLabel {
    switch (category) {
      case KnowledgeCategory.geopolitics:
        return 'Geopolitik';
      case KnowledgeCategory.alternativeMedia:
        return 'Alternative Medien';
      case KnowledgeCategory.research:
        return 'Forschung';
      case KnowledgeCategory.conspiracy:
        return 'Verschwörungstheorien';
      case KnowledgeCategory.history:
        return 'Geschichte';
      case KnowledgeCategory.science:
        return 'Wissenschaft';
      case KnowledgeCategory.meditation:
        return 'Meditation';
      case KnowledgeCategory.chakra:
        return 'Chakren';
      case KnowledgeCategory.astrology:
        return 'Astrologie';
      case KnowledgeCategory.numerology:
        return 'Numerologie';
      case KnowledgeCategory.sacred:
        return 'Heilige Geometrie';
      case KnowledgeCategory.healing:
        return 'Heilung';
      case KnowledgeCategory.spirituality:
        return 'Spiritualität';
    }
  }
  
  // Schwierigkeit-Label
  String get difficultyLabel {
    switch (difficulty) {
      case 1:
        return 'Einsteiger';
      case 2:
        return 'Leicht';
      case 3:
        return 'Mittel';
      case 4:
        return 'Fortgeschritten';
      case 5:
        return 'Experte';
      default:
        return 'Mittel';
    }
  }
}
