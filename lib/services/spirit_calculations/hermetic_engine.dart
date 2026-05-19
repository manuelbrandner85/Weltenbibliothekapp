import 'package:flutter/material.dart';

/// 📜 HERMETIK-ENGINE
///
/// Basiert auf den 7 Hermetischen Prinzipien (Das Kybalion)
///
/// 7 PRINZIPIEN:
/// 1. Mentalismus - Alles ist Geist
/// 2. Entsprechung - Wie oben, so unten
/// 3. Schwingung - Nichts ruht, alles bewegt sich
/// 4. Polarität - Alles ist dual
/// 5. Rhythmus - Alles fließt, ein und aus
/// 6. Ursache & Wirkung - Jede Ursache hat eine Wirkung
/// 7. Geschlecht - Alles hat männliche und weibliche Prinzipien
class HermeticEngine {
  /// 7 Hermetische Prinzipien mit vollständigen Beschreibungen
  static final Map<int, Map<String, dynamic>> _principles = {
    1: {
      'name': 'Mentalismus',
      'originalName': 'The Principle of Mentalism',
      'axiom': 'Das All ist Geist, das Universum ist mental',
      'description':
          'Die physische Realität ist eine Manifestation des universellen Geistes',
      'application': 'Deine Gedanken erschaffen deine Realität',
      'color': Color(0xFF9C27B0),
      'element': 'Äther',
      'mastery': 'Bewusste Gedankenkontrolle',
      'keywords': ['Bewusstsein', 'Manifestation', 'Gedankenkraft', 'Geist'],
      'practice': 'Meditation, Visualisierung, bewusstes Denken',
      'warning': 'Negative Gedanken erschaffen negative Realität',
    },
    2: {
      'name': 'Entsprechung',
      'originalName': 'The Principle of Correspondence',
      'axiom': 'Wie oben, so unten; wie innen, so außen',
      'description':
          'Die Muster des Universums wiederholen sich auf allen Ebenen',
      'application': 'Erkenne die Spiegelungen zwischen Mikro- und Makrokosmos',
      'color': Color(0xFF2196F3),
      'element': 'Luft',
      'mastery': 'Analoges Denken',
      'keywords': ['Spiegelung', 'Analogie', 'Muster', 'Fraktale'],
      'practice': 'Muster-Erkennung, Selbstreflexion, Naturbeobachtung',
      'warning': 'Nicht alles ist direkt übertragbar',
    },
    3: {
      'name': 'Schwingung',
      'originalName': 'The Principle of Vibration',
      'axiom': 'Nichts ruht, alles bewegt sich, alles schwingt',
      'description':
          'Alles im Universum ist in ständiger Bewegung und Schwingung',
      'application': 'Erhöhe deine Schwingung für positive Manifestation',
      'color': Color(0xFFFFEB3B),
      'element': 'Feuer',
      'mastery': 'Frequenz-Kontrolle',
      'keywords': ['Energie', 'Frequenz', 'Bewegung', 'Schwingung'],
      'practice': 'Klangmeditation, Frequenz-Arbeit, energetische Reinigung',
      'warning': 'Niedrige Schwingungen ziehen Negatives an',
    },
    4: {
      'name': 'Polarität',
      'originalName': 'The Principle of Polarity',
      'axiom': 'Alles ist dual, alles hat Pole, alles hat sein Gegenpaar',
      'description':
          'Gegensätze sind identisch in der Natur, aber unterschiedlich im Grad',
      'application': 'Transformiere Negatives durch Verschiebung der Polarität',
      'color': Color(0xFFE91E63),
      'element': 'Wasser',
      'mastery': 'Mentale Transmutation',
      'keywords': ['Dualität', 'Gegensätze', 'Balance', 'Transformation'],
      'practice': 'Perspektivenwechsel, Gegensätze integrieren, Alchemie',
      'warning': 'Extreme führen zu Ungleichgewicht',
    },
    5: {
      'name': 'Rhythmus',
      'originalName': 'The Principle of Rhythm',
      'axiom': 'Alles fließt aus und ein, alles hat seine Gezeiten',
      'description': 'Alle Dinge unterliegen einem rhythmischen Schwung',
      'application': 'Erkenne und nutze die natürlichen Zyklen',
      'color': Color(0xFF00BCD4),
      'element': 'Wasser',
      'mastery': 'Rhythmus-Beherrschung',
      'keywords': ['Zyklen', 'Rhythmus', 'Gezeiten', 'Pendel'],
      'practice': 'Zyklen-Beobachtung, Timing, natürliche Rhythmen folgen',
      'warning': 'Gegen den Rhythmus kämpfen erschöpft',
    },
    6: {
      'name': 'Ursache & Wirkung',
      'originalName': 'The Principle of Cause and Effect',
      'axiom': 'Jede Ursache hat ihre Wirkung, jede Wirkung hat ihre Ursache',
      'description': 'Nichts geschieht durch Zufall, alles folgt dem Gesetz',
      'application': 'Sei Ursache, nicht Wirkung in deinem Leben',
      'color': Color(0xFF4CAF50),
      'element': 'Erde',
      'mastery': 'Bewusste Kausalität',
      'keywords': ['Karma', 'Gesetz', 'Ursache', 'Verantwortung'],
      'practice': 'Bewusste Entscheidungen, Verantwortung übernehmen',
      'warning': 'Unbewusste Ursachen führen zu ungewollten Wirkungen',
    },
    7: {
      'name': 'Geschlecht',
      'originalName': 'The Principle of Gender',
      'axiom':
          'Geschlecht ist in allem, alles hat männliche und weibliche Prinzipien',
      'description':
          'Männlich (aktiv, projizierend) und weiblich (empfangend, formend) in allem',
      'application': 'Balanciere Yang (männlich) und Yin (weiblich) Energien',
      'color': Color(0xFFFF9800),
      'element': 'Feuer/Wasser',
      'mastery': 'Energetische Balance',
      'keywords': ['Yang/Yin', 'Balance', 'Schöpfung', 'Dualität'],
      'practice': 'Energie-Balance, aktiv/passiv-Phasen, Integration',
      'warning': 'Unbalance führt zu Dysfunktion',
    },
  };

  /// Berechne dominantes Prinzip basierend auf Lebenszahl
  static Map<String, dynamic> calculateDominantPrinciple(int lifePathNumber) {
    int principleNumber = ((lifePathNumber - 1) % 7) + 1;
    return _principles[principleNumber] ?? _principles[1]!;
  }

  /// Berechne zu entwickelndes Prinzip
  static Map<String, dynamic> calculateDevelopmentPrinciple(
      int expressionNumber) {
    int principleNumber = ((expressionNumber - 1) % 7) + 1;
    return _principles[principleNumber] ?? _principles[1]!;
  }

  /// Berechne schwächstes Prinzip (Herausforderung)
  static Map<String, dynamic> calculateWeakPrinciple(int challengeNumber) {
    int principleNumber = ((challengeNumber - 1) % 7) + 1;
    return _principles[principleNumber] ?? _principles[1]!;
  }

  /// Berechne Prinzipien-Scores für alle 7 Prinzipien
  static Map<int, int> calculatePrincipleScores(
    String firstName,
    String lastName,
    DateTime birthDate,
    int lifePathNumber,
  ) {
    final scores = <int, int>{};

    // Basis-Score: 50
    for (int i = 1; i <= 7; i++) {
      scores[i] = 50;
    }

    // Dominantes Prinzip erhält Bonus
    int dominantPrinciple = ((lifePathNumber - 1) % 7) + 1;
    scores[dominantPrinciple] = (scores[dominantPrinciple] ?? 50) + 25;

    // Namen-Einfluss
    int nameSum = _calculateNameSum(firstName + lastName);
    for (int i = 1; i <= 7; i++) {
      int influence = (nameSum + i * 11) % 20 - 10;
      scores[i] = (scores[i] ?? 50) + influence;
    }

    // Geburtsjahr-Einfluss (Rhythmus)
    int yearInfluence = ((birthDate.year % 7) + 1);
    scores[yearInfluence] = (scores[yearInfluence] ?? 50) + 15;

    // Normalisiere auf 0-100
    scores.forEach((key, value) {
      scores[key] = value.clamp(0, 100);
    });

    return scores;
  }

  static int _calculateNameSum(String name) {
    int sum = 0;
    for (int i = 0; i < name.length; i++) {
      sum += name.codeUnitAt(i);
    }
    return sum;
  }

  /// Berechne Balance-Score (wie ausgewogen sind die Prinzipien?)
  static int calculateHermeticBalance(Map<int, int> principleScores) {
    // Durchschnitt
    int sum = 0;
    principleScores.forEach((_, score) {
      sum += score;
    });
    int average = (sum / 7).round();

    // Varianz berechnen
    int variance = 0;
    principleScores.forEach((_, score) {
      variance += ((score - average) * (score - average)).abs();
    });
    int variancePenalty = (variance / 50).round();

    int balanceScore = average - variancePenalty;
    return balanceScore.clamp(0, 100);
  }

  /// Berechne Element-Verteilung
  static Map<String, int> calculateElementDistribution(
      Map<int, int> principleScores) {
    final elements = <String, int>{
      'Äther': principleScores[1] ?? 50,
      'Luft': principleScores[2] ?? 50,
      'Feuer': ((principleScores[3] ?? 50) + (principleScores[7] ?? 50)) ~/ 2,
      'Wasser': ((principleScores[4] ?? 50) + (principleScores[5] ?? 50)) ~/ 2,
      'Erde': principleScores[6] ?? 50,
    };
    return elements;
  }

  /// Generiere Praxis-Empfehlungen
  static List<String> generatePracticeRecommendations(
    Map<String, dynamic> dominant,
    Map<String, dynamic> weak,
    Map<int, int> principleScores,
  ) {
    final recommendations = <String>[];

    recommendations.add('🔮 Dein dominantes Prinzip: ${dominant['name']}');
    recommendations.add('✨ ${dominant['axiom']}');
    recommendations.add('🎯 Praktiziere: ${dominant['practice']}');
    recommendations
        .add('⚠️ Schwaches Prinzip: ${weak['name']} - ${weak['practice']}');
    recommendations
        .add('⚖️ Balance-Tipp: Integriere alle 7 Prinzipien gleichmäßig');

    return recommendations;
  }

  /// Berechne Meisterschaft-Level (0-100)
  static int calculateMasteryLevel(Map<int, int> principleScores) {
    // Durchschnitt aller Scores
    int sum = 0;
    principleScores.forEach((_, score) {
      sum += score;
    });
    return (sum / 7).round();
  }

  /// Alle Prinzipien abrufen
  static Map<int, Map<String, dynamic>> getAllPrinciples() {
    return Map.from(_principles);
  }

  /// Prinzip-Farbe für Visualisierung
  static Color getPrincipleColor(int principleNumber) {
    final principle = _principles[principleNumber];
    return (principle?['color'] as Color?) ?? Colors.grey;
  }

  /// Prinzip-Name
  static String getPrincipleName(int principleNumber) {
    final principle = _principles[principleNumber];
    return principle?['name'] as String? ?? 'Unbekannt';
  }

  /// Generiere Transmutations-Anleitung (Polaritäts-Prinzip)
  static String generateTransmutationGuide(
      String negativeState, String desiredState) {
    return 'Transmutiere "$negativeState" zu "$desiredState" durch mentale Verschiebung der Polarität. '
        'Fokussiere auf das gewünschte Gegenteil und erhöhe deine Schwingung.';
  }
}
