import '../models/spirit_dashboard.dart';

/// INNERES JOURNAL SERVICE
/// KI-gestützte Fragengenerierung basierend auf persönlichem Profil
class InnerJournalService {
  static final InnerJournalService _instance = InnerJournalService._internal();
  factory InnerJournalService() => _instance;
  InnerJournalService._internal();

  /// GENERIERE KONTEXTUELLE FRAGEN
  /// Basierend auf Persönlichem Jahr, Archetypen, Mondphase
  List<String> generateContextualQuestions(
    int personalYear,
    int personalMonth,
    String primaryArchetype,
    bool isTransitionYear,
    String? dominantElement,
  ) {
    final questions = <String>[];
    
    // BASIEREND AUF PERSÖNLICHEM JAHR
    questions.addAll(_getYearQuestions(personalYear));
    
    // BASIEREND AUF PERSÖNLICHEM MONAT
    questions.addAll(_getMonthQuestions(personalMonth));
    
    // BASIEREND AUF ARCHETYP
    questions.addAll(_getArchetypeQuestions(primaryArchetype));
    
    // BASIEREND AUF ÜBERGANGSPHASE
    if (isTransitionYear) {
      questions.addAll(_getTransitionQuestions());
    }
    
    // BASIEREND AUF ELEMENT
    if (dominantElement != null) {
      questions.addAll(_getElementQuestions(dominantElement));
    }
    
    // Mische und gib top 5 zurück
    questions.shuffle();
    return questions.take(5).toList();
  }

  List<String> _getYearQuestions(int year) {
    switch (year) {
      case 1:
        return [
          'Was möchtest du in diesem Jahr der Neuanfänge initiieren?',
          'Welche alte Version von dir darfst du jetzt loslassen?',
          'Was würde geschehen, wenn du deinen mutigsten Traum lebst?',
        ];
      case 2:
        return [
          'Wo in deinem Leben rufst du nach mehr Harmonie?',
          'Welche Beziehung möchte vertieft werden?',
          'Was lehrt dich Geduld gerade?',
        ];
      case 3:
        return [
          'Welcher kreative Ausdruck möchte durch dich geboren werden?',
          'Was möchte deine Stimme der Welt mitteilen?',
          'Wo darfst du spielerischer sein?',
        ];
      case 4:
        return [
          'Welches Fundament baust du gerade auf?',
          'Was braucht Struktur und Disziplin in deinem Leben?',
          'Welche langfristige Vision trägt dich?',
        ];
      case 5:
        return [
          'Welche Freiheit rufst du in dein Leben?',
          'Wohin möchtest du innerlich reisen?',
          'Was darf sich jetzt verändern?',
        ];
      case 6:
        return [
          'Wo übernimmst du zu viel Verantwortung für andere?',
          'Wie kannst du für dich selbst sorgen?',
          'Welche Harmonie möchtest du in deinem Zuhause schaffen?',
        ];
      case 7:
        return [
          'Welche innere Weisheit möchte sich dir offenbaren?',
          'Was brauchst du, um tiefer in die Stille zu gehen?',
          'Welche spirituelle Frage bewegt dich am meisten?',
        ];
      case 8:
        return [
          'Welche Fülle manifestierst du gerade?',
          'Wo darfst du deine Macht kraftvoll einsetzen?',
          'Was ist bereit, in die materielle Welt geboren zu werden?',
        ];
      case 9:
        return [
          'Was ist bereit, vollendet zu werden?',
          'Welche Lektion hat dieser Zyklus für dich?',
          'Was darfst du jetzt mit Dankbarkeit gehen lassen?',
        ];
      default:
        return [];
    }
  }

  List<String> _getMonthQuestions(int month) {
    if (month <= 3) {
      return ['Was möchte im kommenden Monat geboren werden?'];
    } else if (month <= 6) {
      return ['Welcher Aspekt deines Lebens braucht jetzt Aufmerksamkeit?'];
    } else if (month <= 9) {
      return ['Was darfst du im nächsten Monat loslassen?'];
    }
    return [];
  }

  List<String> _getArchetypeQuestions(String archetype) {
    if (archetype.contains('Magier')) {
      return [
        'Welche Transformation möchte durch dich geschehen?',
        'Wo setzt du deine innere Macht ein?',
      ];
    } else if (archetype.contains('Weise')) {
      return [
        'Welche Wahrheit möchte erkannt werden?',
        'Was lehrt dich das Leben gerade?',
      ];
    } else if (archetype.contains('Entdecker')) {
      return [
        'Wohin ruft dich die innere Reise?',
        'Was möchtest du erforschen?',
      ];
    } else if (archetype.contains('Held')) {
      return [
        'Welche Herausforderung rufst du in dein Leben?',
        'Wo zeigst du Mut?',
      ];
    } else if (archetype.contains('Liebende')) {
      return [
        'Wo öffnest du dein Herz?',
        'Welche Verbindung vertieft sich?',
      ];
    }
    return ['Welche Rolle wiederholt sich in deinem Leben?'];
  }

  List<String> _getTransitionQuestions() {
    return [
      'Was endet gerade in deinem Leben?',
      'Was wartet darauf, geboren zu werden?',
      'Welcher Teil von dir transformiert sich?',
    ];
  }

  List<String> _getElementQuestions(String element) {
    switch (element) {
      case 'Feuer':
        return [
          'Wo lodert deine Leidenschaft?',
          'Welche kreative Flamme möchte genährt werden?',
        ];
      case 'Wasser':
        return [
          'Welches Gefühl möchte gefühlt werden?',
          'Wo fließt deine Intuition?',
        ];
      case 'Luft':
        return [
          'Welche Idee möchte gedacht werden?',
          'Wo brauchst du mehr geistige Freiheit?',
        ];
      case 'Erde':
        return [
          'Was braucht Erdung in deinem Leben?',
          'Welches Fundament baust du?',
        ];
      default:
        return [];
    }
  }

  /// VERTIEFENDE FOLLOW-UP FRAGEN
  List<String> getFollowUpQuestions(String primaryAnswer) {
    return [
      'Und was würde geschehen, wenn du das vollständig lebst?',
      'Welcher tiefere Teil von dir spricht hier?',
      'Was hindert dich daran, diesen Weg zu gehen?',
      'Welche Ressource brauchst du, um dies zu verwirklichen?',
      'Wer wärst du, wenn dies bereits wahr wäre?',
    ];
  }

  /// THEMEN-FOKUS FÜR VERSCHIEDENE PHASEN
  String getThemeFocus(int personalYear, int personalMonth) {
    if (personalYear == 1 || personalYear == 9) {
      return 'TRANSFORMATION & NEUAUSRICHTUNG';
    } else if (personalYear == 7) {
      return 'INNENSCHAU & WEISHEIT';
    } else if (personalYear == 5) {
      return 'FREIHEIT & VERÄNDERUNG';
    } else if (personalMonth <= 3) {
      return 'VISIONEN & POTENZIALE';
    } else if (personalMonth <= 6) {
      return 'UMSETZUNG & MANIFESTATION';
    } else if (personalMonth <= 9) {
      return 'REFLEXION & INTEGRATION';
    }
    return 'VOLLENDUNG & DANKBARKEIT';
  }

  /// REFLEXIONS-TIEFE ANGEPASST AN PROFIL
  /// 1 = Oberflächlich, 5 = Sehr tief
  int getReflectionDepth(int lifePathNumber, bool isTransitionYear) {
    int depth = 3; // Default
    
    // Tiefere Reflexion bei spirituellen Lebenszahlen
    if (lifePathNumber == 7 || lifePathNumber == 9 || lifePathNumber == 11) {
      depth = 5;
    }
    
    // Noch tiefer bei Übergangsphase
    if (isTransitionYear) {
      depth = (depth + 1).clamp(1, 5);
    }
    
    return depth;
  }

  /// DEMO JOURNAL-EINTRÄGE
  static List<InnerJournalEntry> getDemoEntries() {
    final now = DateTime.now();
    
    return [
      InnerJournalEntry(
        timestamp: now.subtract(const Duration(days: 1)),
        question: 'Was möchte in diesem Jahr der Neuanfänge initiieren?',
        answer: 'Ich möchte meine spirituelle Praxis vertiefen und mehr Zeit für Meditation einplanen.',
        tags: ['Neuanfang', 'Spiritualität', 'Meditation'],
        archetypeId: 5, // Magier
      ),
      InnerJournalEntry(
        timestamp: now.subtract(const Duration(days: 3)),
        question: 'Welche Transformation möchte durch dich geschehen?',
        answer: 'Eine Transformation von Angst zu Vertrauen. Ich lerne, dem Fluss des Lebens zu vertrauen.',
        tags: ['Transformation', 'Vertrauen', 'Loslassen'],
        archetypeId: 5,
      ),
      InnerJournalEntry(
        timestamp: now.subtract(const Duration(days: 7)),
        question: 'Wo öffnest du dein Herz?',
        tags: ['Herz', 'Liebe', 'Öffnung'],
        archetypeId: 7, // Liebende
      ),
    ];
  }
}
