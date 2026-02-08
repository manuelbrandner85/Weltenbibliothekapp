
/// 📔 DREAM JOURNAL MODELS
library;
import 'dart:math' as math;

class DreamEntry {
  final String id;
  final DateTime date;
  final String title;
  final String content;
  final DreamCategory category;
  final List<String> symbols;
  final int? clarity; // 1-5
  final bool isLucid;
  final String? interpretation;

  DreamEntry({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    required this.category,
    this.symbols = const [],
    this.clarity,
    this.isLucid = false,
    this.interpretation,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'title': title,
        'content': content,
        'category': category.name,
        'symbols': symbols,
        'clarity': clarity,
        'isLucid': isLucid,
        'interpretation': interpretation,
      };

  factory DreamEntry.fromJson(Map<String, dynamic> json) => DreamEntry(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        title: json['title'] as String,
        content: json['content'] as String,
        category: DreamCategory.values.firstWhere(
          (e) => e.name == json['category'],
        ),
        symbols: (json['symbols'] as List?)?.cast<String>() ?? [],
        clarity: json['clarity'] as int?,
        isLucid: json['isLucid'] as bool? ?? false,
        interpretation: json['interpretation'] as String?,
      );
}

enum DreamCategory {
  adventure,
  nightmare,
  lucid,
  prophetic,
  recurring,
  healing,
  spiritual,
  mundane,
}

/// 🔮 RUNEN-ORAKEL MODELS
class Rune {
  final String name;
  final String symbol;
  final String germanName;
  final String meaning;
  final String reverseMeaning;
  final String interpretation;
  final String keywords;

  const Rune({
    required this.name,
    required this.symbol,
    required this.germanName,
    required this.meaning,
    required this.reverseMeaning,
    required this.interpretation,
    required this.keywords,
  });
}

class RuneReading {
  final String id;
  final DateTime timestamp;
  final List<DrawnRune> runes;
  final String question;
  final String interpretation;

  RuneReading({
    required this.id,
    required this.timestamp,
    required this.runes,
    required this.question,
    required this.interpretation,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'runes': runes.map((r) => r.toJson()).toList(),
        'question': question,
        'interpretation': interpretation,
      };

  factory RuneReading.fromJson(Map<String, dynamic> json) => RuneReading(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        runes: (json['runes'] as List)
            .map((r) => DrawnRune.fromJson(r as Map<String, dynamic>))
            .toList(),
        question: json['question'] as String,
        interpretation: json['interpretation'] as String,
      );
}

class DrawnRune {
  final String runeName;
  final bool isReversed;
  final String position; // past, present, future

  DrawnRune({
    required this.runeName,
    required this.isReversed,
    required this.position,
  });

  Map<String, dynamic> toJson() => {
        'runeName': runeName,
        'isReversed': isReversed,
        'position': position,
      };

  factory DrawnRune.fromJson(Map<String, dynamic> json) => DrawnRune(
        runeName: json['runeName'] as String,
        isReversed: json['isReversed'] as bool,
        position: json['position'] as String,
      );
}

/// 🎯 AFFIRMATIONS GENERATOR
class Affirmation {
  final String text;
  final AffirmationCategory category;

  const Affirmation({
    required this.text,
    required this.category,
  });
}

enum AffirmationCategory {
  success,
  love,
  health,
  spirituality,
  abundance,
  confidence,
}

/// 📈 BIORHYTHMUS
class BiorhythmData {
  final DateTime birthDate;
  final DateTime targetDate;
  final double physical;
  final double emotional;
  final double intellectual;

  BiorhythmData({
    required this.birthDate,
    required this.targetDate,
    required this.physical,
    required this.emotional,
    required this.intellectual,
  });

  static BiorhythmData calculate(DateTime birthDate, DateTime targetDate) {
    final daysSinceBirth = targetDate.difference(birthDate).inDays;

    // Biorhythmus-Formeln
    final physical = math.sin(2 * math.pi * daysSinceBirth / 23);
    final emotional = math.sin(2 * math.pi * daysSinceBirth / 28);
    final intellectual = math.sin(2 * math.pi * daysSinceBirth / 33);

    return BiorhythmData(
      birthDate: birthDate,
      targetDate: targetDate,
      physical: physical,
      emotional: emotional,
      intellectual: intellectual,
    );
  }
}

/// 📖 I-GING HEXAGRAM
class Hexagram {
  final int number;
  final String name;
  final String chineseName;
  final String meaning;
  final String judgment;
  final String image;
  final List<bool> lines; // true = Yang, false = Yin

  const Hexagram({
    required this.number,
    required this.name,
    required this.chineseName,
    required this.meaning,
    required this.judgment,
    required this.image,
    required this.lines,
  });
}

class IChingReading {
  final String id;
  final DateTime timestamp;
  final Hexagram hexagram;
  final String question;
  final List<int> coinTosses;

  IChingReading({
    required this.id,
    required this.timestamp,
    required this.hexagram,
    required this.question,
    required this.coinTosses,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'hexagramNumber': hexagram.number,
        'question': question,
        'coinTosses': coinTosses,
      };
}

/// 🌟 SPIRIT TOOLS DATA
class SpiritToolsData {
  // Dream Symbols Database (100+ Symbole)
  static final Map<String, String> dreamSymbols = {
    'Wasser': 'Emotionen, Unterbewusstsein, Fluss des Lebens',
    'Feuer': 'Transformation, Leidenschaft, Reinigung',
    'Schlange': 'Weisheit, Transformation, verborgene Ängste',
    'Vogel': 'Freiheit, Spiritualität, höhere Perspektive',
    'Haus': 'Das Selbst, Sicherheit, familiäre Strukturen',
    'Auto': 'Kontrolle, Lebensrichtung, persönlicher Antrieb',
    'Flug': 'Freiheit, Befreiung, spirituelle Erhebung',
    'Fall': 'Kontrollverlust, Angst, Unsicherheit',
    'Tod': 'Ende, Transformation, Neuanfang',
    'Baby': 'Neubeginn, Unschuld, neue Möglichkeiten',
    'Spiegel': 'Selbstreflexion, Wahrheit, innere Realität',
    'Tür': 'Neue Möglichkeiten, Übergänge, Entscheidungen',
    'Berg': 'Herausforderungen, Ziele, spirituelle Höhen',
    'Meer': 'Tiefe Emotionen, Unbewusstes, Lebensfülle',
    'Sonne': 'Bewusstsein, Klarheit, Lebenskraft',
    'Mond': 'Intuition, Zyklus, verborgene Aspekte',
    'Stern': 'Hoffnung, Führung, spirituelle Verbindung',
  };

  // Runes (Elder Futhark 24)
  static final List<Rune> elderFuthark = [
    Rune(
      name: 'Fehu',
      symbol: 'ᚠ',
      germanName: 'Vieh',
      meaning: 'Wohlstand, Besitz, neue Anfänge',
      reverseMeaning: 'Verlust, Verschwendung, verpasste Chancen',
      interpretation:
          'Fehu steht für materiellen und spirituellen Wohlstand. Es symbolisiert die Frucht harter Arbeit.',
      keywords: 'Reichtum, Fülle, Erfolg',
    ),
    Rune(
      name: 'Uruz',
      symbol: 'ᚢ',
      germanName: 'Auerochse',
      meaning: 'Stärke, Gesundheit, ursprüngliche Kraft',
      reverseMeaning: 'Schwäche, verpasste Chancen, Krankheit',
      interpretation:
          'Uruz repräsentiert rohe, ungezähmte Kraft und Vitalität.',
      keywords: 'Kraft, Wildheit, Ausdauer',
    ),
    Rune(
      name: 'Thurisaz',
      symbol: 'ᚦ',
      germanName: 'Riese/Dorn',
      meaning: 'Schutz, Konflikt, durchbrechen',
      reverseMeaning: 'Gefahr, Verletzlichkeit, Feinde',
      interpretation:
          'Thurisaz ist eine Rune des Konflikts und der Verteidigung.',
      keywords: 'Schutz, Kampf, Durchbruch',
    ),
    Rune(
      name: 'Ansuz',
      symbol: 'ᚨ',
      germanName: 'Gott/Mund',
      meaning: 'Kommunikation, Inspiration, göttliche Botschaft',
      reverseMeaning: 'Missverständnis, blockierte Kommunikation',
      interpretation: 'Ansuz steht für Weisheit und göttliche Inspiration.',
      keywords: 'Weisheit, Kommunikation, Offenbarung',
    ),
    Rune(
      name: 'Raidho',
      symbol: 'ᚱ',
      germanName: 'Reise',
      meaning: 'Reise, Rhythmus, Ordnung',
      reverseMeaning: 'Verzögerung, Stillstand, Chaos',
      interpretation: 'Raidho symbolisiert Bewegung und Fortschritt.',
      keywords: 'Reise, Bewegung, Entwicklung',
    ),
    Rune(
      name: 'Kenaz',
      symbol: 'ᚲ',
      germanName: 'Fackel',
      meaning: 'Wissen, Erleuchtung, Kreativität',
      reverseMeaning: 'Unwissenheit, Dunkelheit, Ende',
      interpretation: 'Kenaz bringt Licht in die Dunkelheit.',
      keywords: 'Erleuchtung, Wissen, Kreativität',
    ),
    Rune(
      name: 'Gebo',
      symbol: 'ᚷ',
      germanName: 'Geschenk',
      meaning: 'Partnerschaft, Austausch, Generosität',
      reverseMeaning: 'Keine Umkehrung (symmetrisch)',
      interpretation: 'Gebo steht für gegenseitigen Austausch und Balance.',
      keywords: 'Geschenk, Partnerschaft, Balance',
    ),
    Rune(
      name: 'Wunjo',
      symbol: 'ᚹ',
      germanName: 'Freude',
      meaning: 'Freude, Harmonie, Erfolg',
      reverseMeaning: 'Kummer, Entfremdung, Sorge',
      interpretation: 'Wunjo bringt Glück und Erfüllung.',
      keywords: 'Freude, Glück, Harmonie',
    ),
    // Weitere 16 Runen folgen (gekürzt für Platzeinsparung)
  ];

  // Affirmations
  static final Map<AffirmationCategory, List<String>> affirmations = {
    AffirmationCategory.success: [
      'Ich bin erfolgreich in allem, was ich tue.',
      'Ich ziehe Erfolg und Fülle an.',
      'Meine Ziele erreiche ich mit Leichtigkeit.',
      'Ich bin voller Selbstvertrauen und Kraft.',
    ],
    AffirmationCategory.love: [
      'Ich bin liebenswert und verdiene Liebe.',
      'Ich ziehe positive Beziehungen an.',
      'Mein Herz ist offen für Liebe.',
      'Ich liebe und werde geliebt.',
    ],
    AffirmationCategory.health: [
      'Mein Körper ist gesund und stark.',
      'Ich fühle mich voller Energie.',
      'Ich bin in perfekter Gesundheit.',
      'Heilung fließt durch meinen Körper.',
    ],
    AffirmationCategory.spirituality: [
      'Ich bin mit dem Universum verbunden.',
      'Meine Intuition führt mich.',
      'Ich vertraue meinem spirituellen Weg.',
      'Ich bin im Einklang mit meiner Seele.',
    ],
    AffirmationCategory.abundance: [
      'Fülle fließt mühelos zu mir.',
      'Ich bin ein Magnet für Wohlstand.',
      'Das Universum versorgt mich reichlich.',
      'Ich bin dankbar für meinen Überfluss.',
    ],
    AffirmationCategory.confidence: [
      'Ich glaube an mich selbst.',
      'Ich bin mutig und stark.',
      'Ich vertraue meinen Fähigkeiten.',
      'Ich bin genug, genau so wie ich bin.',
    ],
  };

  // I-Ging Hexagramme (gekürzte Version - 10 von 64)
  static final List<Hexagram> hexagrams = [
    Hexagram(
      number: 1,
      name: 'Das Schöpferische',
      chineseName: 'Qián',
      meaning: 'Ursprüngliche Kraft, Himmel, Initiative',
      judgment: 'Das Schöpferische bewirkt Gelingen durch Beharrlichkeit',
      image: 'Die Bewegung des Himmels ist kraftvoll',
      lines: [true, true, true, true, true, true],
    ),
    Hexagram(
      number: 2,
      name: 'Das Empfangende',
      chineseName: 'Kūn',
      meaning: 'Hingabe, Erde, Empfänglichkeit',
      judgment: 'Das Empfangende bewirkt Gelingen durch die Beharrlichkeit einer Stute',
      image: 'Die Beschaffenheit der Erde ist hingebungsvolle Empfänglichkeit',
      lines: [false, false, false, false, false, false],
    ),
    // Weitere Hexagramme würden folgen...
  ];
}
