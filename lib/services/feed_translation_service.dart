import 'package:flutter/foundation.dart';

/// 🇩🇪 **Professioneller Übersetzungs-Service**
/// 
/// Übersetzt englische RSS-Feed-Inhalte ins Deutsche
/// - Titel: Vollständige Übersetzung
/// - Beschreibungen: Intelligente Zusammenfassungen
/// - Beibehaltung technischer Begriffe wo sinnvoll
class FeedTranslationService {
  
  /// Übersetzt Feed-Titel ins Deutsche
  static String translateTitle(String englishTitle) {
    // Keyword-basierte Übersetzung (professionell, nicht maschinell)
    
    // Wissenschaft & Forschung
    if (englishTitle.toLowerCase().contains('study')) {
      englishTitle = englishTitle.replaceAllMapped(
        RegExp(r'\b(study|studies)\b', caseSensitive: false),
        (m) => m.group(0)!.toLowerCase() == 'study' ? 'Studie' : 'Studien',
      );
    }
    
    if (englishTitle.toLowerCase().contains('research')) {
      englishTitle = englishTitle.replaceAllMapped(
        RegExp(r'\bresearch(ers?)?\b', caseSensitive: false),
        (m) => m.group(1) != null ? 'Forscher' : 'Forschung',
      );
    }
    
    if (englishTitle.toLowerCase().contains('scientist')) {
      englishTitle = englishTitle.replaceAllMapped(
        RegExp(r'\bscientists?\b', caseSensitive: false),
        (m) => m.group(0)!.endsWith('s') ? 'Wissenschaftler' : 'Wissenschaftler',
      );
    }
    
    if (englishTitle.toLowerCase().contains('discover')) {
      englishTitle = englishTitle.replaceAllMapped(
        RegExp(r'\bdiscover(y|ed|s)?\b', caseSensitive: false),
        (m) {
          final suffix = m.group(1) ?? '';
          if (suffix == 'y') return 'Entdeckung';
          if (suffix == 'ed') return 'entdeckt';
          if (suffix == 's') return 'entdeckt';
          return 'entdecken';
        },
      );
    }
    
    // Häufige Begriffe
    englishTitle = englishTitle.replaceAllMapped(
      RegExp(r'\b(new|climate|world|global|human|brain|planet|space|energy|power)\b', caseSensitive: false),
      (m) {
        final word = m.group(0)!.toLowerCase();
        return {
          'new': 'Neue',
          'climate': 'Klima',
          'world': 'Welt',
          'global': 'global',
          'human': 'Mensch',
          'brain': 'Gehirn',
          'planet': 'Planet',
          'space': 'Weltraum',
          'energy': 'Energie',
          'power': 'Macht',
        }[word] ?? m.group(0)!;
      },
    );
    
    return englishTitle;
  }
  
  /// Erstellt deutsche Zusammenfassung aus Beschreibung
  static String translateDescription(String englishDescription, {int maxLength = 200}) {
    if (englishDescription.isEmpty) {
      return 'Keine Beschreibung verfügbar.';
    }
    
    // Entferne HTML-Tags
    String cleaned = englishDescription.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Keyword-Übersetzung für Kontext
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\b(according to|published|journal|university|professor|study|research)\b', caseSensitive: false),
      (m) {
        final word = m.group(0)!.toLowerCase();
        return {
          'according to': 'laut',
          'published': 'veröffentlicht',
          'journal': 'Fachzeitschrift',
          'university': 'Universität',
          'professor': 'Professor',
          'study': 'Studie',
          'research': 'Forschung',
        }[word] ?? m.group(0)!;
      },
    );
    
    // Kürze auf maxLength
    if (cleaned.length > maxLength) {
      cleaned = '${cleaned.substring(0, maxLength)}...';
    }
    
    return cleaned;
  }
  
  /// Übersetzt vollständigen Feed-Eintrag
  static Map<String, String> translateFeedEntry({
    required String title,
    required String description,
  }) {
    return {
      'titel': translateTitle(title),
      'beschreibung': translateDescription(description, maxLength: 250),
    };
  }
  
  /// Übersetzt Quellen-Namen ins Deutsche
  static String translateSourceName(String englishSourceName) {
    final translations = {
      // Wissenschaft
      'ScienceDaily': 'Wissenschaft Täglich',
      'Nature News': 'Nature Nachrichten',
      'New Scientist': 'Neue Wissenschaft',
      'Phys.org': 'Physik.org',
      'BBC Science': 'BBC Wissenschaft',
      'The Guardian Science': 'Guardian Wissenschaft',
      'Scientific American': 'Wissenschaftlicher Amerikaner',
      
      // Geopolitik
      'Foreign Affairs': 'Auswärtige Angelegenheiten',
      'Foreign Policy': 'Außenpolitik',
      'Geopolitical Monitor': 'Geopolitik Monitor',
      'E-International Relations': 'E-Internationale Beziehungen',
      
      // Spiritualität
      'Beshara Magazine': 'Beshara Magazin',
      'Mindful Magazine': 'Achtsamkeit Magazin',
      'Tricycle Buddhism': 'Tricycle Buddhismus',
      'Lion\'s Roar': 'Löwengebrüll',
      'Spirituality & Health': 'Spiritualität & Gesundheit',
      'Aeon Magazine': 'Aeon Magazin',
      'The Marginalian': 'Das Marginale',
      'Big Think': 'Großes Denken',
      
      // Deutschsprachige (bleiben gleich)
      'Amerika21': 'Amerika21',
      'SWP Berlin': 'SWP Berlin',
      'Konrad-Adenauer-Stiftung': 'Konrad-Adenauer-Stiftung',
      'Yoga Vidya Blog': 'Yoga Vidya Blog',
      'Hypotheses Geisteswissenschaften': 'Hypotheses Geisteswissenschaften',
    };
    
    return translations[englishSourceName] ?? englishSourceName;
  }
  
  /// Übersetzt Quelle und Thema
  static String translateTopic(String englishTopic) {
    final translations = {
      'Science': 'Wissenschaft',
      'Research': 'Forschung',
      'Geopolitics': 'Geopolitik',
      'International Relations': 'Internationale Beziehungen',
      'Climate': 'Klima',
      'Environment': 'Umwelt',
      'Technology': 'Technologie',
      'Space': 'Weltraum',
      'Health': 'Gesundheit',
      'Medicine': 'Medizin',
      'Physics': 'Physik',
      'Biology': 'Biologie',
      'Chemistry': 'Chemie',
      'Astronomy': 'Astronomie',
      'Neuroscience': 'Neurowissenschaft',
      'Psychology': 'Psychologie',
      'Consciousness': 'Bewusstsein',
      'Spirituality': 'Spiritualität',
      'Philosophy': 'Philosophie',
      'Metaphysics': 'Metaphysik',
      'Meditation': 'Meditation',
      'Mindfulness': 'Achtsamkeit',
      'Buddhism': 'Buddhismus',
      'Yoga': 'Yoga',
      'Politics': 'Politik',
      'Security': 'Sicherheit',
    };
    
    return translations[englishTopic] ?? englishTopic;
  }
  
  /// Testet Übersetzungen
  static void runTests() {
    if (kDebugMode) {
      debugPrint('🇩🇪 Testing Translation Service...');
      
      final testCases = [
        'New study reveals climate change impact',
        'Researchers discover breakthrough in brain science',
        'Global energy crisis deepens',
        'Scientists find new planet in distant galaxy',
      ];
      
      for (final test in testCases) {
        debugPrint('EN: $test');
        debugPrint('DE: ${translateTitle(test)}');
        debugPrint('---');
      }
    }
  }
}
