import 'package:flutter/material.dart';

/// 🌳 KABBALA-ENGINE
///
/// Basiert auf dem Baum des Lebens (Etz Chaim)
///
/// 10 SEPHIROTH (Emanationen):
/// 1. Kether (Krone) - Göttliche Einheit
/// 2. Chokmah (Weisheit) - Dynamische Kraft
/// 3. Binah (Verständnis) - Formende Kraft
/// 4. Chesed (Gnade) - Liebe & Großzügigkeit
/// 5. Geburah (Stärke) - Macht & Gerechtigkeit
/// 6. Tiphereth (Schönheit) - Harmonie & Herz
/// 7. Netzach (Sieg) - Ausdauer & Emotion
/// 8. Hod (Glorie) - Intellekt & Form
/// 9. Yesod (Fundament) - Unterbewusstsein
/// 10. Malkuth (Königreich) - Physische Welt
///
/// 22 PFADE: Verbinden die Sephiroth (entsprechen den 22 hebräischen Buchstaben)
class KabbalahEngine {
  /// 10 Sephiroth mit vollständigen Beschreibungen
  static final Map<int, Map<String, dynamic>> _sephiroth = {
    1: {
      'name': 'Kether',
      'germanName': 'Krone',
      'meaning': 'Göttliche Einheit, Ursprung',
      'description':
          'Die allererhöchste, transzendenteste Sephira im gesamten kabbalistischen Baum des Lebens - Kether ist die reine, unmanifestierte Quelle allen Seins, allen Lebens und aller Existenz! Sie repräsentiert die göttliche Krone, den absoluten Ursprung, die undifferenzierte Einheit vor aller Schöpfung und das höchste göttliche Bewusstsein. Hier existiert noch keine Trennung, keine Dualität, kein "Ich" und "Du" - nur reine, absolute Einheit mit dem göttlichen Urgrund. Kether ist das Ziel der spirituellen Reise zurück zur Quelle, zur Rückkehr in die göttliche Einheit. Menschen, die stark mit Kether verbunden sind, erfahren tiefe spirituelle Erleuchtung, kosmisches Bewusstsein und Momente der absoluten Einheit mit allem was ist.',
      'attribute': 'Einheit, Transzendenz',
      'color': Color(0xFFFFFFFF),
      'planet': 'Primum Mobile',
      'virtue': 'Vollendung des Großen Werkes',
      'vice': 'Keine (höchste Ebene)',
      'bodyPart': 'Scheitel des Kopfes',
      'keywords': ['Einheit', 'Ursprung', 'Krone', 'Transzendenz'],
      'pillar': 'Mittlere Säule',
      'level': 'Göttliche Welt (Atziluth)',
    },
    2: {
      'name': 'Chokmah',
      'germanName': 'Weisheit',
      'meaning': 'Dynamische, schöpferische Energie',
      'description':
          'Chokmah repräsentiert die erste aktive, dynamische, uranfängliche männliche, schaffende Kraft im Universum - die reine, ungezügelte Schöpferenergie! Sie ist der erste Impuls zur Manifestation, die explosive, expandierende Yang-Energie, die alles in Bewegung setzt. Chokmah ist reines Sein ohne Form, die visionäre Kraft, die neue Realitäten erträumt und initiiert. Sie repräsentiert den göttlichen Vater, die zeugende Urkraft und den Funken göttlicher Inspiration. Menschen mit starker Chokmah-Verbindung sind hochgradig kreativ, visionär, initiierend, explosiv in ihrer Schöpferkraft und haben Zugang zu reiner Inspiration und uranfänglicher Weisheit, die aus der Quelle selbst kommt.',
      'attribute': 'Weisheit, Dynamik',
      'color': Color(0xFF808080),
      'planet': 'Zodiak',
      'virtue': 'Hingabe',
      'vice': 'Keine',
      'bodyPart': 'Linke Gehirnhälfte',
      'keywords': ['Weisheit', 'Dynamik', 'Anfang', 'Yang'],
      'pillar': 'Rechte Säule (Gnade)',
      'level': 'Göttliche Welt (Atziluth)',
    },
    3: {
      'name': 'Binah',
      'germanName': 'Verständnis',
      'meaning': 'Formende, empfangende Energie',
      'description':
          'Binah ist die göttliche Mutter, die formende, empfangende, strukturierende, weibliche Urkraft des Universums! Sie nimmt die chaotische, ungezügelte Energie von Chokmah auf und formt daraus strukturierte, manifeste Realität. Binah repräsentiert Verständnis, tiefe Einsicht, die Fähigkeit zu begreifen und zu strukturieren. Sie ist die Gebärmutter der Form, aus der alle Manifestation entsteht. Binah ist auch das Prinzip der Begrenzung, der Grenzen, der Zeit - alles was der reinen Energie Form gibt. Menschen mit starker Binah-Verbindung haben tiefes Verständnis für Strukturen, Muster und Zusammenhänge, sind fähig, chaos zu ordnen und besitzen eine reife, mütterliche Weisheit.',
      'attribute': 'Verständnis, Form',
      'color': Color(0xFF000000),
      'planet': 'Saturn',
      'virtue': 'Stille',
      'vice': 'Habsucht',
      'bodyPart': 'Rechte Gehirnhälfte',
      'keywords': ['Verständnis', 'Form', 'Yin', 'Mutter'],
      'pillar': 'Linke Säule (Strenge)',
      'level': 'Göttliche Welt (Atziluth)',
    },
    4: {
      'name': 'Chesed',
      'germanName': 'Gnade',
      'meaning': 'Liebe, Großzügigkeit, Fülle',
      'description':
          'Chesed repräsentiert bedingungslose göttliche Liebe, grenzenlose Großzügigkeit, unendliche Barmherzigkeit und expandierende Fülle! Sie ist die Sephira des bedingungslosen Gebens, der Gnade, der Vergebung und des grenzenlosen Mitgefühls. Chesed möchte sich ausbreiten, wachsen, alles umarmen und jedem geben ohne Grenzen oder Bedingungen. Sie repräsentiert den barmherzigen, liebevollen Aspekt des Göttlichen - den Teil, der niemals richtet, immer vergibt und bedingungslos liebt. Menschen mit starker Chesed-Verbindung sind außergewöhnlich großzügig, liebevoll, gnädig, vergebend und haben Zugang zu tiefer, bedingungsloser Liebe. Ohne Balance kann Chesed zu Grenzlosigkeit, Co-Abhängigkeit oder blinder Güte führen.',
      'attribute': 'Gnade, Liebe',
      'color': Color(0xFF0000FF),
      'planet': 'Jupiter',
      'virtue': 'Gehorsam',
      'vice': 'Bigotterie, Völlerei',
      'bodyPart': 'Linker Arm',
      'keywords': ['Liebe', 'Gnade', 'Fülle', 'Expansion'],
      'pillar': 'Rechte Säule (Gnade)',
      'level': 'Schöpfungswelt (Briah)',
    },
    5: {
      'name': 'Geburah',
      'germanName': 'Stärke',
      'meaning': 'Macht, Gerechtigkeit, Disziplin',
      'description':
          'Geburah repräsentiert göttliche Gerechtigkeit, notwendige Strenge, disziplinierende Kraft und die Fähigkeit, Grenzen zu setzen! Sie ist der Gegenpol zu Chesed - wo Chesed grenzenlos gibt, setzt Geburah notwendige Grenzen. Sie ist die Sephira der Gerechtigkeit, der Macht, der Disziplin und der Fähigkeit "Nein" zu sagen. Geburah schneidet weg, was nicht mehr dient, zerstört Altes, um Platz für Neues zu schaffen und setzt klare, feste Grenzen. Sie repräsentiert den gerechten, aber strengen Aspekt des Göttlichen. Menschen mit starker Geburah-Verbindung haben starken Willen, klare Grenzen, Fähigkeit zur Disziplin und Gerechtigkeit. Ohne Balance kann Geburah zu Grausamkeit, Zerstörungswut oder rigider Stränge führen.',
      'attribute': 'Stärke, Gerechtigkeit',
      'color': Color(0xFFFF0000),
      'planet': 'Mars',
      'virtue': 'Energie, Mut',
      'vice': 'Grausamkeit, Zerstörung',
      'bodyPart': 'Rechter Arm',
      'keywords': ['Stärke', 'Gerechtigkeit', 'Macht', 'Grenzen'],
      'pillar': 'Linke Säule (Strenge)',
      'level': 'Schöpfungswelt (Briah)',
    },
    6: {
      'name': 'Tiphereth',
      'germanName': 'Schönheit',
      'meaning': 'Harmonie, Herz, Balance',
      'description':
          'Tiphereth ist das strahlende, goldene Herzzentrum des gesamten kabbalistischen Baumes - die harmonische Mitte, die perfekte Balance zwischen allen Gegensätzen! Sie repräsentiert Schönheit, Harmonie, Ausgeglichenheit und die Fähigkeit, alle widerstreitenden Kräfte in harmonische Balance zu bringen. Tiphereth ist das höhere Selbst, das Christus-Bewusstsein, der erleuchtete Zustand, in dem alle Gegensätze versöhnt werden. Sie ist das spirituelle Herz, das sowohl mit dem Göttlichen oben als auch mit der materiellen Welt unten verbunden ist. Menschen mit starker Tiphereth-Verbindung sind ausgewogen, harmonisch, schön im Inneren und Äußeren und haben die Fähigkeit, Frieden zu stiften und Gegensatze zu integrieren.',
      'attribute': 'Schönheit, Harmonie',
      'color': Color(0xFFFFD700),
      'planet': 'Sonne',
      'virtue': 'Hingabe zum Großen Werk',
      'vice': 'Stolz',
      'bodyPart': 'Herz',
      'keywords': ['Schönheit', 'Harmonie', 'Herz', 'Balance'],
      'pillar': 'Mittlere Säule',
      'level': 'Schöpfungswelt (Briah)',
    },
    7: {
      'name': 'Netzach',
      'germanName': 'Sieg',
      'meaning': 'Ausdauer, Emotionen, Natur',
      'description':
          'Netzach repräsentiert die emotionale Ebene, natürliche Triebe, Instinkte, Leidenschaft und die Kraft der Ausdauer! Sie ist die Sephira der Emotionen, der Liebe, der Lust, der Kreativität und aller natürlichen, instinktiven Kräfte. Netzach ist die Energie, die uns trotz aller Hindernisse weitermachen lässt, die uns Ausdauer, Durchhaltevermögen und emotionale Resilienz gibt. Sie repräsentiert die Venus-Energie - Liebe, Schönheit, Sinnlichkeit, Künstlerisches und alles, was uns Menschen emotional berührt. Menschen mit starker Netzach-Verbindung sind emotional lebendig, leidenschaftlich, kreativ, ausdauernd und haben Zugang zu tiefen Gefühlen. Ohne Balance kann Netzach zu emotionaler Überwältigung, Wollust oder unkontrollierten Trieben führen.',
      'attribute': 'Sieg, Emotionen',
      'color': Color(0xFF00FF00),
      'planet': 'Venus',
      'virtue': 'Selbstlosigkeit',
      'vice': 'Wollust, Unkeuschheit',
      'bodyPart': 'Rechte Hüfte',
      'keywords': ['Sieg', 'Emotionen', 'Natur', 'Ausdauer'],
      'pillar': 'Rechte Säule (Gnade)',
      'level': 'Formungswelt (Yetzirah)',
    },
    8: {
      'name': 'Hod',
      'germanName': 'Glorie',
      'meaning': 'Intellekt, Kommunikation, Form',
      'description':
          'Hod repräsentiert die intellektuelle Ebene, Sprache, Kommunikation, logisches Denken und die Magie des Verstandes! Sie ist die Sephira des Intellekts, der Analyse, der Strukturierung von Gedanken und der Fähigkeit, Ideen in Worte, Sätze und Konzepte zu fassen. Hod ist die Merkur-Energie - schnelles Denken, clevere Kommunikation, analytische Fähigkeiten und die Magie der Sprache. Sie repräsentiert alles, was mit Denken, Lernen, Verstehen und intellektueller Durchdringung zu tun hat. Menschen mit starker Hod-Verbindung sind hochintelligent, analytisch, kommunikativ, sprachbegabt und haben die Fähigkeit, komplexe Ideen klar zu vermitteln. Ohne Balance kann Hod zu Überintellektualisierung, Falschheit oder kalter Logik ohne Gefühl führen.',
      'attribute': 'Glorie, Intellekt',
      'color': Color(0xFFFF8C00),
      'planet': 'Merkur',
      'virtue': 'Wahrhaftigkeit',
      'vice': 'Falschheit, Unehrlichkeit',
      'bodyPart': 'Linke Hüfte',
      'keywords': ['Intellekt', 'Kommunikation', 'Form', 'Magie'],
      'pillar': 'Linke Säule (Strenge)',
      'level': 'Formungswelt (Yetzirah)',
    },
    9: {
      'name': 'Yesod',
      'germanName': 'Fundament',
      'meaning': 'Unterbewusstsein, Träume, Astralwelt',
      'description':
          'Yesod ist das Fundament der Manifestation, die astrale Ebene, die Welt der Träume, Bilder und des Unterbewusstseins! Sie ist die Sephira, die zwischen dem Spirituellen und dem Materiellen vermittelt - alles muss durch Yesod, bevor es in Malkuth manifest werden kann. Yesod repräsentiert die Mond-Energie - das Unterbewusstsein, Träume, Instinkte, die astrale Welt und alle nicht-physischen Realitäten. Sie ist das Fundament, auf dem die physische Welt steht, und der Zugang zur Traumwelt, zum kollektiven Unbewussten und zur astralen Ebene. Menschen mit starker Yesod-Verbindung haben lebendige Träume, starke Intuition, Zugang zum Unterbewusstsein und die Fähigkeit, zwischen Welten zu reisen.',
      'attribute': 'Fundament, Astral',
      'color': Color(0xFF9370DB),
      'planet': 'Mond',
      'virtue': 'Unabhängigkeit',
      'vice': 'Müßiggang',
      'bodyPart': 'Genitalien',
      'keywords': ['Fundament', 'Träume', 'Astral', 'Unterbewusstsein'],
      'pillar': 'Mittlere Säule',
      'level': 'Formungswelt (Yetzirah)',
    },
    10: {
      'name': 'Malkuth',
      'germanName': 'Königreich',
      'meaning': 'Physische Welt, Manifestation',
      'description':
          'Malkuth ist das Königreich - die vollständig manifestierte, physische, materielle Welt, die wir mit unseren fünf Sinnen wahrnehmen! Sie ist die letzte Sephira im Baum, die Endstation der Emanation, wo alles Spirituelle schlussendlich physisch greifbar wird. Malkuth repräsentiert die Erd-Energie - Stabilität, Materie, den physischen Körper, die Natur und alles Greifbare. Sie ist sowohl das Ende als auch der Anfang - das Ende der Emanation von oben nach unten, aber auch der Startpunkt für die spirituelle Reise zurück nach oben. Menschen mit starker Malkuth-Verbindung sind geerdet, praktisch, mit der Natur verbunden und haben eine gesunde Beziehung zur physischen Realität. Malkuth zu ehren bedeutet, die Materie zu heiligen!',
      'attribute': 'Königreich, Materie',
      'color': Color(0xFF8B4513),
      'planet': 'Erde',
      'virtue': 'Unterscheidungsvermögen',
      'vice': 'Habsucht, Trägheit',
      'bodyPart': 'Füße',
      'keywords': ['Königreich', 'Materie', 'Erde', 'Manifestation'],
      'pillar': 'Mittlere Säule',
      'level': 'Materielle Welt (Assiah)',
    },
  };

  /// Berechne persönliche Sephira basierend auf Lebenszahl
  static Map<String, dynamic> calculatePersonalSephira(int lifePathNumber) {
    // Reduziere auf 1-10
    int sephiraNumber = ((lifePathNumber - 1) % 10) + 1;
    return _sephiroth[sephiraNumber] ?? _sephiroth[1]!;
  }

  /// Berechne Entwicklungs-Sephira (wohin du wächst)
  static Map<String, dynamic> calculateDevelopmentSephira(
      int expressionNumber) {
    int sephiraNumber = ((expressionNumber - 1) % 10) + 1;
    return _sephiroth[sephiraNumber] ?? _sephiroth[1]!;
  }

  /// Berechne blockierte Sephira (Herausforderung)
  static Map<String, dynamic> calculateBlockedSephira(int challengeNumber) {
    int sephiraNumber = ((challengeNumber - 1) % 10) + 1;
    return _sephiroth[sephiraNumber] ?? _sephiroth[1]!;
  }

  /// Berechne Sephiroth-Aktivierungs-Scores für alle 10 Sephiroth
  static Map<int, int> calculateSephirothScores(
    String firstName,
    String lastName,
    DateTime birthDate,
    int lifePathNumber,
  ) {
    final scores = <int, int>{};

    // Basis-Score: 40
    for (int i = 1; i <= 10; i++) {
      scores[i] = 40;
    }

    // Persönliche Sephira erhält Bonus
    int personalSephira = ((lifePathNumber - 1) % 10) + 1;
    scores[personalSephira] = (scores[personalSephira] ?? 40) + 30;

    // Namen-Einfluss
    int nameSum = _calculateNameSum(firstName + lastName);
    for (int i = 1; i <= 10; i++) {
      int influence = (nameSum + i * 7) % 25 - 12;
      scores[i] = (scores[i] ?? 40) + influence;
    }

    // Geburtsdatum-Einfluss
    int birthInfluence = ((birthDate.day + birthDate.month) % 10) + 1;
    scores[birthInfluence] = (scores[birthInfluence] ?? 40) + 20;

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

  /// Berechne Säulen-Balance (3 Säulen)
  static Map<String, int> calculatePillarBalance(
      Map<int, int> sephirothScores) {
    // Rechte Säule (Gnade): Chokmah (2), Chesed (4), Netzach (7)
    int rightPillar = ((sephirothScores[2] ?? 0) +
            (sephirothScores[4] ?? 0) +
            (sephirothScores[7] ?? 0)) ~/
        3;

    // Linke Säule (Strenge): Binah (3), Geburah (5), Hod (8)
    int leftPillar = ((sephirothScores[3] ?? 0) +
            (sephirothScores[5] ?? 0) +
            (sephirothScores[8] ?? 0)) ~/
        3;

    // Mittlere Säule (Balance): Kether (1), Tiphereth (6), Yesod (9), Malkuth (10)
    int middlePillar = ((sephirothScores[1] ?? 0) +
            (sephirothScores[6] ?? 0) +
            (sephirothScores[9] ?? 0) +
            (sephirothScores[10] ?? 0)) ~/
        4;

    return {
      'Gnade (Rechts)': rightPillar,
      'Strenge (Links)': leftPillar,
      'Balance (Mitte)': middlePillar,
    };
  }

  /// Berechne Welten-Verteilung (4 Welten der Kabbala)
  static Map<String, int> calculateWorldsDistribution(
      Map<int, int> sephirothScores) {
    // Atziluth (Göttliche Welt): Kether (1), Chokmah (2), Binah (3)
    int atziluth = ((sephirothScores[1] ?? 0) +
            (sephirothScores[2] ?? 0) +
            (sephirothScores[3] ?? 0)) ~/
        3;

    // Briah (Schöpfungswelt): Chesed (4), Geburah (5), Tiphereth (6)
    int briah = ((sephirothScores[4] ?? 0) +
            (sephirothScores[5] ?? 0) +
            (sephirothScores[6] ?? 0)) ~/
        3;

    // Yetzirah (Formungswelt): Netzach (7), Hod (8), Yesod (9)
    int yetzirah = ((sephirothScores[7] ?? 0) +
            (sephirothScores[8] ?? 0) +
            (sephirothScores[9] ?? 0)) ~/
        3;

    // Assiah (Materielle Welt): Malkuth (10)
    int assiah = sephirothScores[10] ?? 0;

    return {
      'Atziluth (Göttlich)': atziluth,
      'Briah (Schöpfung)': briah,
      'Yetzirah (Formung)': yetzirah,
      'Assiah (Materiell)': assiah,
    };
  }

  /// Generiere Entwicklungs-Empfehlungen
  static List<String> generatePathworkRecommendations(
    Map<String, dynamic> personal,
    Map<String, dynamic> blocked,
    Map<int, int> sephirothScores,
  ) {
    final recommendations = <String>[];

    recommendations.add(
        '🌳 Deine persönliche Sephira: ${personal['name']} - ${personal['meaning']}');
    recommendations.add('🎯 Entwickle: ${personal['virtue']}');
    recommendations.add(
        '⚠️ Blockierte Sephira: ${blocked['name']} - Überwinde ${blocked['vice']}');

    // Finde schwächste Sephira
    int weakestSephira = 1;
    int lowestScore = 100;
    sephirothScores.forEach((sephira, score) {
      if (score < lowestScore) {
        lowestScore = score;
        weakestSephira = sephira;
      }
    });

    final weakest = _sephiroth[weakestSephira];
    if (weakest != null) {
      recommendations.add(
          '💪 Stärke ${weakest['name']}: Arbeite an ${weakest['attribute']}');
    }

    recommendations.add(
        '🧘 Meditation: Fokussiere auf ${personal['bodyPart']} für ${personal['name']}');

    return recommendations;
  }

  /// Alle Sephiroth abrufen
  static Map<int, Map<String, dynamic>> getAllSephiroth() {
    return Map.from(_sephiroth);
  }

  /// Sephira-Farbe für Visualisierung
  static Color getSephiraColor(int sephiraNumber) {
    final sephira = _sephiroth[sephiraNumber];
    return (sephira?['color'] as Color?) ?? Colors.grey;
  }

  /// Sephira-Name
  static String getSephiraName(int sephiraNumber) {
    final sephira = _sephiroth[sephiraNumber];
    return sephira?['name'] as String? ?? 'Unbekannt';
  }

  /// 22 Pfade-Information (vereinfacht)
  static String getPathDescription(int sephiraFrom, int sephiraTo) {
    return 'Pfad von ${getSephiraName(sephiraFrom)} zu ${getSephiraName(sephiraTo)}';
  }
}
