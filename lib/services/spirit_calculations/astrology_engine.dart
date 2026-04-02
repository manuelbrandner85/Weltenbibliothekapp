/// ♈ ASTROLOGIE-BERECHNUNGS-ENGINE
/// 
/// Basiert auf klassischer westlicher Astrologie
/// Quellen: Ptolemäus, moderne Astrologie
/// 
/// Berechnungsmethoden:
/// - Sonnenzeichen (Sun Sign): Tierkreiszeichen bei Geburt
/// - Mondzeichen (Moon Sign): Emotionale Natur (vereinfacht)
/// - Aszendent: Aufsteigendes Zeichen (benötigt Geburtszeit)
/// - Elementeverteilung: Feuer, Erde, Luft, Wasser
/// - Modalitäten: Kardinal, Fix, Veränderlich
/// - Planetare Dominanzen: Herrscherplanet des Zeichens
/// - Lebensphasen-Astrologie: Saturn-Return, Jupiter-Zyklus
library;

class AstrologyEngine {
  /// Tierkreiszeichen mit Datumsbereichen
  static const List<Map<String, dynamic>> _zodiacSigns = [
    {
      'name': 'Widder',
      'symbol': '♈',
      'element': 'Feuer',
      'modality': 'Kardinal',
      'ruler': 'Mars',
      'startMonth': 3,
      'startDay': 21,
      'endMonth': 4,
      'endDay': 19,
      'keywords': ['Pionier', 'Mut', 'Initiative', 'Energie'],
    },
    {
      'name': 'Stier',
      'symbol': '♉',
      'element': 'Erde',
      'modality': 'Fix',
      'ruler': 'Venus',
      'startMonth': 4,
      'startDay': 20,
      'endMonth': 5,
      'endDay': 20,
      'keywords': ['Stabilität', 'Sinnlichkeit', 'Ausdauer', 'Materie'],
    },
    {
      'name': 'Zwillinge',
      'symbol': '♊',
      'element': 'Luft',
      'modality': 'Veränderlich',
      'ruler': 'Merkur',
      'startMonth': 5,
      'startDay': 21,
      'endMonth': 6,
      'endDay': 20,
      'keywords': ['Kommunikation', 'Vielseitigkeit', 'Neugier', 'Austausch'],
    },
    {
      'name': 'Krebs',
      'symbol': '♋',
      'element': 'Wasser',
      'modality': 'Kardinal',
      'ruler': 'Mond',
      'startMonth': 6,
      'startDay': 21,
      'endMonth': 7,
      'endDay': 22,
      'keywords': ['Emotion', 'Fürsorge', 'Familie', 'Intuition'],
    },
    {
      'name': 'Löwe',
      'symbol': '♌',
      'element': 'Feuer',
      'modality': 'Fix',
      'ruler': 'Sonne',
      'startMonth': 7,
      'startDay': 23,
      'endMonth': 8,
      'endDay': 22,
      'keywords': ['Kreativität', 'Stolz', 'Großzügigkeit', 'Ausdruck'],
    },
    {
      'name': 'Jungfrau',
      'symbol': '♍',
      'element': 'Erde',
      'modality': 'Veränderlich',
      'ruler': 'Merkur',
      'startMonth': 8,
      'startDay': 23,
      'endMonth': 9,
      'endDay': 22,
      'keywords': ['Analyse', 'Dienst', 'Perfektion', 'Gesundheit'],
    },
    {
      'name': 'Waage',
      'symbol': '♎',
      'element': 'Luft',
      'modality': 'Kardinal',
      'ruler': 'Venus',
      'startMonth': 9,
      'startDay': 23,
      'endMonth': 10,
      'endDay': 22,
      'keywords': ['Balance', 'Harmonie', 'Partnerschaft', 'Ästhetik'],
    },
    {
      'name': 'Skorpion',
      'symbol': '♏',
      'element': 'Wasser',
      'modality': 'Fix',
      'ruler': 'Pluto',
      'startMonth': 10,
      'startDay': 23,
      'endMonth': 11,
      'endDay': 21,
      'keywords': ['Transformation', 'Tiefe', 'Leidenschaft', 'Macht'],
    },
    {
      'name': 'Schütze',
      'symbol': '♐',
      'element': 'Feuer',
      'modality': 'Veränderlich',
      'ruler': 'Jupiter',
      'startMonth': 11,
      'startDay': 22,
      'endMonth': 12,
      'endDay': 21,
      'keywords': ['Expansion', 'Philosophie', 'Optimismus', 'Freiheit'],
    },
    {
      'name': 'Steinbock',
      'symbol': '♑',
      'element': 'Erde',
      'modality': 'Kardinal',
      'ruler': 'Saturn',
      'startMonth': 12,
      'startDay': 22,
      'endMonth': 1,
      'endDay': 19,
      'keywords': ['Ambition', 'Struktur', 'Verantwortung', 'Meisterschaft'],
    },
    {
      'name': 'Wassermann',
      'symbol': '♒',
      'element': 'Luft',
      'modality': 'Fix',
      'ruler': 'Uranus',
      'startMonth': 1,
      'startDay': 20,
      'endMonth': 2,
      'endDay': 18,
      'keywords': ['Innovation', 'Unabhängigkeit', 'Humanität', 'Rebellion'],
    },
    {
      'name': 'Fische',
      'symbol': '♓',
      'element': 'Wasser',
      'modality': 'Veränderlich',
      'ruler': 'Neptun',
      'startMonth': 2,
      'startDay': 19,
      'endMonth': 3,
      'endDay': 20,
      'keywords': ['Mitgefühl', 'Mystik', 'Kreativität', 'Auflösung'],
    },
  ];

  /// Berechne Sonnenzeichen (Sun Sign)
  static Map<String, dynamic> calculateSunSign(DateTime birthDate) {
    final month = birthDate.month;
    final day = birthDate.day;

    for (final sign in _zodiacSigns) {
      final startMonth = sign['startMonth'] as int;
      final startDay = sign['startDay'] as int;
      final endMonth = sign['endMonth'] as int;
      final endDay = sign['endDay'] as int;

      // Spezieller Fall: Steinbock (übergreift Jahreswechsel)
      if (startMonth > endMonth) {
        if ((month == startMonth && day >= startDay) ||
            (month == endMonth && day <= endDay)) {
          return sign;
        }
      } else {
        if ((month == startMonth && day >= startDay) ||
            (month > startMonth && month < endMonth) ||
            (month == endMonth && day <= endDay)) {
          return sign;
        }
      }
    }

    return _zodiacSigns[0]; // Fallback
  }

  /// Berechne vereinfachtes Mondzeichen
  /// Hinweis: Exakte Berechnung benötigt Ephemeriden
  /// Diese Vereinfachung basiert auf Geburtsmonat + Tag
  static Map<String, dynamic> calculateMoonSign(DateTime birthDate) {
    // Vereinfachte Berechnung: Mond bewegt sich ~13° pro Tag
    // Vollständiger Zyklus: ~28 Tage durch alle 12 Zeichen
    final dayOfYear = birthDate.difference(DateTime(birthDate.year, 1, 1)).inDays;
    final moonCycle = (dayOfYear * 12 / 365).floor() % 12;

    return _zodiacSigns[moonCycle];
  }

  /// Berechne vereinfachten Aszendenten
  /// Hinweis: Exakte Berechnung benötigt Geburtszeit + Geburtsort
  /// Diese Vereinfachung basiert auf Geburtsstunde
  static Map<String, dynamic>? calculateAscendant(DateTime birthDate, String? birthTime) {
    if (birthTime == null || birthTime.isEmpty) return null;

    try {
      final parts = birthTime.split(':');
      if (parts.length < 2) return null;

      final hour = int.parse(parts[0]);
      
      // Vereinfachte Berechnung: Aszendent wechselt ca. alle 2 Stunden
      final ascIndex = (hour / 2).floor() % 12;
      return _zodiacSigns[ascIndex];
    } catch (e) {
      return null;
    }
  }

  /// Berechne Elementeverteilung
  static Map<String, int> calculateElementDistribution(
    Map<String, dynamic> sunSign,
    Map<String, dynamic> moonSign,
    Map<String, dynamic>? ascendant,
  ) {
    final elements = <String, int>{
      'Feuer': 0,
      'Erde': 0,
      'Luft': 0,
      'Wasser': 0,
    };

    final sunElement = sunSign['element'] as String?;
    final moonElement = moonSign['element'] as String?;
    if (sunElement != null) elements[sunElement] = (elements[sunElement] ?? 0) + 1;
    if (moonElement != null) elements[moonElement] = (elements[moonElement] ?? 0) + 1;
    if (ascendant != null) {
      final ascElement = ascendant['element'] as String?;
      if (ascElement != null) elements[ascElement] = (elements[ascElement] ?? 0) + 1;
    }

    return elements;
  }

  /// Berechne Modalitätenverteilung
  static Map<String, int> calculateModalityDistribution(
    Map<String, dynamic> sunSign,
    Map<String, dynamic> moonSign,
    Map<String, dynamic>? ascendant,
  ) {
    final modalities = <String, int>{
      'Kardinal': 0,
      'Fix': 0,
      'Veränderlich': 0,
    };

    final sunModality = sunSign['modality'] as String?;
    final moonModality = moonSign['modality'] as String?;
    if (sunModality != null) modalities[sunModality] = (modalities[sunModality] ?? 0) + 1;
    if (moonModality != null) modalities[moonModality] = (modalities[moonModality] ?? 0) + 1;
    if (ascendant != null) {
      final ascModality = ascendant['modality'] as String?;
      if (ascModality != null) modalities[ascModality] = (modalities[ascModality] ?? 0) + 1;
    }

    return modalities;
  }

  /// Berechne Saturn-Return (alle ~29 Jahre)
  static List<Map<String, dynamic>> calculateSaturnReturns(DateTime birthDate) {
    final returns = <Map<String, dynamic>>[];
    final currentYear = DateTime.now().year;

    for (int i = 1; i <= 3; i++) {
      final returnYear = birthDate.year + (i * 29);
      if (returnYear <= currentYear + 50) {
        returns.add({
          'return': i,
          'year': returnYear,
          'age': i * 29,
          'phase': i == 1 ? 'Erste Reife' : i == 2 ? 'Meisterschaft' : 'Weisheit',
        });
      }
    }

    return returns;
  }

  /// Berechne Jupiter-Zyklen (alle ~12 Jahre)
  static List<Map<String, dynamic>> calculateJupiterCycles(DateTime birthDate) {
    final cycles = <Map<String, dynamic>>[];
    final currentYear = DateTime.now().year;

    for (int i = 1; i <= 7; i++) {
      final cycleYear = birthDate.year + (i * 12);
      if (cycleYear <= currentYear + 50) {
        cycles.add({
          'cycle': i,
          'year': cycleYear,
          'age': i * 12,
          'theme': _getJupiterCycleTheme(i),
        });
      }
    }

    return cycles;
  }

  /// Berechne aktuelles astrologisches Alter
  static Map<String, dynamic> calculateAstrologicalAge(DateTime birthDate) {
    final now = DateTime.now();
    final age = now.year - birthDate.year;

    // Saturn-Zyklus: 0-29, 29-58, 58+
    final saturnPhase = age < 29 ? 1 : age < 58 ? 2 : 3;
    
    // Jupiter-Zyklus: 0-12, 12-24, etc.
    final jupiterCycle = (age / 12).floor() + 1;

    return {
      'age': age,
      'saturnPhase': saturnPhase,
      'saturnTheme': saturnPhase == 1 
          ? 'Aufbau & Lernen'
          : saturnPhase == 2
              ? 'Meisterschaft & Verantwortung'
              : 'Weisheit & Ernte',
      'jupiterCycle': jupiterCycle,
      'jupiterTheme': _getJupiterCycleTheme(jupiterCycle),
    };
  }

  /// Hilfsmethode: Jupiter-Zyklus Themen
  static String _getJupiterCycleTheme(int cycle) {
    switch (cycle) {
      case 1: return 'Kindheit & Unschuld';
      case 2: return 'Jugend & Expansion';
      case 3: return 'Frühe Reife & Verantwortung';
      case 4: return 'Mittlere Jahre & Stabilität';
      case 5: return 'Reife & Weisheit';
      case 6: return 'Späte Jahre & Ernte';
      default: return 'Fortgeschrittene Weisheit';
    }
  }

  /// Berechne dominantes Element
  static String getDominantElement(Map<String, int> elements) {
    return elements.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Berechne dominante Modalität
  static String getDominantModality(Map<String, int> modalities) {
    return modalities.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Beschreibung eines Elements
  static String getElementDescription(String element) {
    switch (element) {
      case 'Feuer':
        return 'Intuition, Begeisterung, Kreativität, Handlung';
      case 'Erde':
        return 'Praktisch, stabil, materiell, ausdauernd';
      case 'Luft':
        return 'Intellekt, Kommunikation, sozial, analytisch';
      case 'Wasser':
        return 'Emotion, Intuition, empathisch, fließend';
      default:
        return '';
    }
  }

  /// Beschreibung einer Modalität
  static String getModalityDescription(String modality) {
    switch (modality) {
      case 'Kardinal':
        return 'Initiativ, führend, neue Zyklen beginnend';
      case 'Fix':
        return 'Stabil, beharrlich, ausdauernd, konzentriert';
      case 'Veränderlich':
        return 'Anpassungsfähig, flexibel, vermittelnd';
      default:
        return '';
    }
  }
}
