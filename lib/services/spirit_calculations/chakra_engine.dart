import 'package:flutter/material.dart';

/// 🌈 CHAKRA-ENGINE
///
/// 7 HAUPT-CHAKREN System (Hinduistische Tradition)
///
/// BERECHNUNG:
/// - Basiert auf Numerologie-Zahlen + Geburtsdatum
/// - Jedes Chakra erhält einen Aktivierungs-Score (0-100)
/// - Dominantes Chakra: Basiert auf Lebenszahl
/// - Blockiertes Chakra: Basiert auf Herausforderungszahl
///
/// CHAKREN (1-7):
/// 1. Wurzel (Muladhara) - Rot - Sicherheit, Überleben
/// 2. Sakral (Svadhisthana) - Orange - Kreativität, Sexualität
/// 3. Solar Plexus (Manipura) - Gelb - Macht, Willenskraft
/// 4. Herz (Anahata) - Grün - Liebe, Mitgefühl
/// 5. Hals (Vishuddha) - Blau - Kommunikation, Ausdruck
/// 6. Stirn (Ajna) - Indigo - Intuition, Weisheit
/// 7. Krone (Sahasrara) - Violett - Spiritualität, Einheit
class ChakraEngine {
  /// 7 Haupt-Chakren mit vollständigen Beschreibungen
  static final Map<int, Map<String, dynamic>> _chakras = {
    1: {
      'name': 'Wurzel-Chakra',
      'sanskritName': 'Muladhara',
      'location': 'Basis der Wirbelsäule',
      'color': Color(0xFFE53935),
      'element': 'Erde',
      'mantra': 'LAM',
      'frequency': 396.0, // Hz
      'theme': 'Sicherheit, Überleben, Erdung',
      'qualities': ['Stabilität', 'Sicherheit', 'Vertrauen', 'Erdung'],
      'balanced':
          'Tiefes Gefühl von absoluter Sicherheit, unerschütterlicher Stabilität, bedingungslosem Vertrauen ins Leben und kraftvoller Erdung im Hier und Jetzt! Wenn dein Wurzel-Chakra vollständig ausgeglichen und harmonisch geöffnet ist, fühlst du dich tief mit der Erde verbunden, absolut sicher in deinem Körper und vollkommen vertrauensvoll, dass das Universum für dich sorgt. Du hast ein starkes Fundament, gesunde Grenzen und die Fähigkeit, deine Grundbedürfnisse mühelos zu erfüllen. Du bist präsent, geerdet und zutiefst verbunden mit der physischen Realität. Finanziell fühlst du dich sicher und materielle Sorgen belasten dich nicht. Du kannst im Moment sein und das Leben genießen, ohne ständig in Ängsten zu leben.',
      'blocked':
          'Quälende Existenzängste, tiefes Misstrauen gegenüber dem Leben und anderen Menschen, chronische finanzielle Sorgen, konstante Überlebensangst! Wenn dein Wurzel-Chakra blockiert oder unteraktiv ist, fühlst du dich unsicher, ungestützt, entwurzelt und im Leben nicht wirklich angekommen. Du kämpfst mit Geldsorgen, Existenzängsten und dem Gefühl, nicht genug zu haben oder nicht genug zu sein. Vertrauen fällt dir schwer - sowohl in andere Menschen als auch ins Leben selbst. Du könntest unter Fluchttendenz oder dem Wunsch nach totaler Kontrolle leiden. Körperlich zeigt sich das oft durch Probleme mit den Beinen, Füßen, Knochen oder dem Dickdarm sowie chronische Müdigkeit.',
      'affirmation': 'Ich bin sicher und geerdet',
      'bodyParts': ['Beine', 'Füße', 'Knochen', 'Dickdarm'],
    },
    2: {
      'name': 'Sakral-Chakra',
      'sanskritName': 'Svadhisthana',
      'location': 'Unterhalb des Nabels',
      'color': Color(0xFFFF6F00),
      'element': 'Wasser',
      'mantra': 'VAM',
      'frequency': 417.0,
      'theme': 'Kreativität, Sexualität, Emotionen',
      'qualities': ['Kreativität', 'Freude', 'Sinnlichkeit', 'Lebensfreude'],
      'balanced':
          'Lebendige Kreativität spürt ununterbrochen in dir, emotionale Ausgeglichenheit durchströmt dein gesamtes Sein und du erlebst gesunde, erfüllte Sexualität in all ihren Facetten! Wenn dein Sakral-Chakra vollständig ausgeglichen ist, fließt Lebensenergie mühelos durch dich, du bist kreativ produktiv, emotional flexibel und kannst Freude, Lust und Vergnügen ohne Schuld oder Scham genießen. Du hast einen gesunden Bezug zu deinem Körper, deiner Sexualität und deinen Emotionen. Du kannst dich hingeben, loslassen und den natürlichen Fluss des Lebens genießen. Beziehungen sind lebendig, sinnlich und erfüllend.',
      'blocked':
          'Emotionale Blockaden, die deine Lebendigkeit ersticken, Kreativitätsmangel oder vollständige kreative Sterilisation, sexuelle Probleme oder völlige sexuelle Repression! Wenn dein Sakral-Chakra blockiert ist, fühlst du dich emotional taub, kreativ leer und sexuell abgeschnitten oder unterdrückt. Freude und Vergnügen fühlen sich schuldbehaftet oder unerreichbar an. Du könntest unter emotionaler Instabilität, Suchtverhalten oder Schwierigkeiten leiden, dich in Beziehungen zu öffnen. Oft zeigt sich das auch durch Probleme mit den Fortpflanzungsorganen, Nieren oder Blase sowie hormonelle Ungleichgewichte.',
      'affirmation': 'Ich fließe mit dem Leben',
      'bodyParts': ['Fortpflanzungsorgane', 'Nieren', 'Blase'],
    },
    3: {
      'name': 'Solarplexus-Chakra',
      'sanskritName': 'Manipura',
      'location': 'Oberhalb des Nabels',
      'color': Color(0xFFFFD600),
      'element': 'Feuer',
      'mantra': 'RAM',
      'frequency': 528.0,
      'theme': 'Macht, Willenskraft, Selbstwert',
      'qualities': [
        'Willenskraft',
        'Selbstwert',
        'Durchsetzung',
        'Transformation'
      ],
      'balanced':
          'Starker, fokussierter Wille trägt dich durch jede Herausforderung, gesundes, unerschütterliches Selbstwertgefühl durchdringt dein gesamtes Sein und kraftvolle Durchsetzungsfähigkeit ist deine zweite Natur! Wenn dein Solarplexus-Chakra vollständig ausgeglichen ist, kennst du deinen Wert, setzt klare Grenzen und kannst deine Ziele mit Entschlossenheit verfolgen ohne rücksichtslos zu sein. Du hast Zugang zu deiner persönlichen Macht, deinem inneren Feuer und deiner Transformationskraft. Du fühlst dich selbstsicher, selbstbestimmt und in der Lage, dein Leben aktiv zu gestalten. Autoritativer Missbrauch lässt dich unberührt.',
      'blocked':
          'Zwanghafter Kontrollzwang oder völlige Machtlosigkeit und Hilflosigkeit, extrem geringes Selbstwertgefühl oder pathologischer Narzissmus! Wenn dein Solarplexus-Chakra blockiert ist, kämpfst du entweder mit dem Bedürfnis nach totaler Kontrolle oder fühlst dich völlig machtlos und handlungsunfähig. Dein Selbstwertgefühl ist niedrig, du zweifelst ständig an dir und kannst dich nicht durchsetzen. Oder das Gegenteil: Du bist dominant, aggressiv und kompensierst innere Schwäche durch äußere Macht. Körperlich zeigt sich das oft durch Magenprobleme, Verdauungsstörungen oder Leberbeschwerden.',
      'affirmation': 'Ich bin kraftvoll und selbstbewusst',
      'bodyParts': ['Magen', 'Leber', 'Gallenblase', 'Bauchspeicheldrüse'],
    },
    4: {
      'name': 'Herz-Chakra',
      'sanskritName': 'Anahata',
      'location': 'Herz-Zentrum',
      'color': Color(0xFF4CAF50),
      'element': 'Luft',
      'mantra': 'YAM',
      'frequency': 639.0,
      'theme': 'Liebe, Mitgefühl, Heilung',
      'qualities': ['Liebe', 'Mitgefühl', 'Vergebung', 'Heilung'],
      'balanced':
          'Bedingungslose Liebe durchströmt dein gesamtes Sein, tiefes universelles Mitgefühl für alle Lebewesen erfüllt dich und emotionale Balance trägt dich durch alle Lebenssituationen! Wenn dein Herz-Chakra vollständig geöffnet und ausgeglichen ist, kannst du bedingungslos lieben - dich selbst, andere und das Leben an sich. Du vergebst leicht, hegst keinen Groll und fühlst tiefe Verbundenheit mit allen Wesen. Mitgefühl fließt natürlich aus dir, ohne dass du dich dabei selbst verlierst. Du kannst empfangen genauso gut wie geben. Beziehungen sind erfüllt von authentischer Liebe, Respekt und gegenseitiger Wertschätzung.',
      'blocked':
          'Intensiver Herzschmerz und emotionale Wunden, völlige Unfähigkeit zu lieben oder Liebe anzunehmen, tiefe Verbitterung und emotionale Panzerung! Wenn dein Herz-Chakra blockiert ist, fühlst du dich emotional verschlossen, lieblos oder liebensunwürdig. Du kämpfst mit Einsamkeit, ködigung oder der Unfähigkeit, Vertrauen aufzubauen. Alte Herzwunden sind ungeheilt und du schützt dein Herz durch emotionale Mauern. Vergebung fällt dir extrem schwer. Körperlich zeigt sich das oft durch Herzprobleme, Lungenerkrankungen, Asthma oder Schulter- und Armschmerzen.',
      'affirmation': 'Ich liebe bedingungslos',
      'bodyParts': ['Herz', 'Lunge', 'Thymusdrüse', 'Arme'],
    },
    5: {
      'name': 'Hals-Chakra',
      'sanskritName': 'Vishuddha',
      'location': 'Kehle',
      'color': Color(0xFF2196F3),
      'element': 'Äther',
      'mantra': 'HAM',
      'frequency': 741.0,
      'theme': 'Kommunikation, Ausdruck, Wahrheit',
      'qualities': ['Kommunikation', 'Wahrheit', 'Ausdruck', 'Authentizität'],
      'balanced':
          'Kristallklare, authentische Kommunikation, mutiger authentischer Selbstausdruck ohne Angst vor Ablehnung und kompromisslose Wahrheit in allen Lebensbereichen! Wenn dein Hals-Chakra vollständig geöffnet ist, kannst du deine Wahrheit klar, direkt und respektvoll aussprechen. Du drückst dich authentisch aus, ohne dich verstellen zu müssen, und deine Kommunikation ist klar, ehrlich und konstruktiv. Du kannst gut zuhören und verstehen, was andere wirklich sagen wollen. Deine Stimme hat Kraft und wird gehört. Du stehst zu deiner Meinung ohne aggressiv oder defensiv zu sein.',
      'blocked':
          'Schwere Kommunikationsprobleme oder völliges Schweigen, zwanghaftes Lügen oder Wahrheitsunterdrückung, lähmende Angst vor authentischem Ausdruck! Wenn dein Hals-Chakra blockiert ist, fällt es dir schwer, dich auszudrücken, deine Wahrheit zu sagen oder für dich einzustehen. Du könntest stottern, deine Stimme ist schwach oder du schweigst komplett. Oder das Gegenteil: Du redest ununterbrochen ohne wirklich zu kommunizieren. Wahrheit fällt dir schwer, du verstellst dich oder lügst. Körperlich zeigt sich das oft durch Halsschmerzen, Schilddrüsenprobleme, Nackenverspannungen oder Zähneknirschen.',
      'affirmation': 'Ich spreche meine Wahrheit',
      'bodyParts': ['Kehle', 'Schilddrüse', 'Nacken', 'Mund'],
    },
    6: {
      'name': 'Stirn-Chakra',
      'sanskritName': 'Ajna',
      'location': 'Zwischen den Augenbrauen (Drittes Auge)',
      'color': Color(0xFF3F51B5),
      'element': 'Licht',
      'mantra': 'OM',
      'frequency': 852.0,
      'theme': 'Intuition, Weisheit, Vorstellungskraft',
      'qualities': ['Intuition', 'Weisheit', 'Vision', 'Klarheit'],
      'balanced':
          'Starke, zuverlässige Intuition führt dich sicher durchs Leben, kristallklare innere Vision zeigt dir den Weg und tiefe innere Weisheit durchströmt alle deine Entscheidungen! Wenn dein Stirn-Chakra (Drittes Auge) vollständig geöffnet ist, hast du Zugang zu deiner Intuition, inneren Führung und hellsichtigen Fähigkeiten. Du siehst durch Illusionen, erkennst Muster und Zusammenhänge und verfügst über tiefe Weisheit. Deine Träume sind bedeutungsvoll und klar. Du kannst zwischen Ego und höherem Selbst unterscheiden. Deine Vorstellungskraft ist lebendig und du kannst visualisieren, was du manifestieren möchtest.',
      'blocked':
          'Geistige Verwirrung und mentales Chaos, hartnäckige Illusionen und Selbsttäuschung, völliger Mangel an Vorstellungskraft oder Vision! Wenn dein Stirn-Chakra blockiert ist, bist du von deiner Intuition abgeschnitten, vertraust nur dem rationalen Verstand und hast keinen Zugang zu deiner inneren Führung. Du fühlst dich verwirrt, orientierungslos und unfai zu unterscheiden, was wahr ist. Illusionen und Selbsttäuschung dominieren. Deine Träume sind chaotisch oder du erinnerst dich nicht. Körperlich zeigt sich das oft durch Kopfschmerzen, Migräne, Augenpro bleme, Seh störungen oder Schlafstörungen.',
      'affirmation': 'Ich vertraue meiner Intuition',
      'bodyParts': ['Gehirn', 'Augen', 'Ohren', 'Nase'],
    },
    7: {
      'name': 'Kronen-Chakra',
      'sanskritName': 'Sahasrara',
      'location': 'Scheitel des Kopfes',
      'color': Color(0xFF9C27B0),
      'element': 'Gedanke/Bewusstsein',
      'mantra': 'AUM',
      'frequency': 963.0,
      'theme': 'Spiritualität, Einheit, Erleuchtung',
      'qualities': ['Spiritualität', 'Einheit', 'Erleuchtung', 'Bewusstsein'],
      'balanced':
          'Tiefe spirituelle Verbindung zu etwas Größerem, Einheitsbewusstsein mit allem was ist und Momente tiefer Erleuchtung durchströmen dein Leben! Wenn dein Kronen-Chakra vollständig geöffnet ist, fühlst du dich verbunden mit dem Universum, dem Göttlichen, der Quelle - wie auch immer du es nennst. Du erlebst Einheit statt Trennung, verstehst, dass alles miteinander verbunden ist und hast Zugang zu universeller Weisheit. Du kannst zwischen Ego und höherem Selbst unterscheiden und lebst zunehmend aus deinem höchsten Bewusstsein. Spirituelle Erfahrungen wie Erleuchtungsmomente, kosmisches Bewusstsein oder Einheitserlebnisse sind dir nicht fremd.',
      'blocked':
          'Spirituelle Disconnection und völlige Abgetrenntheit vom Größeren, rein materialistisches Weltbild ohne Transzendenz, tiefe existenzielle Sinnlosigkeit und innere Leere! Wenn dein Kronen-Chakra blockiert ist, fühlst du dich spirituell leer, von etwas Größerem abgetrennt und existenziell verloren. Das Leben erscheint sinnlos, materialistisch und oberflächlich. Du glaubst nur, was du sehen und anfassen kannst und hast keinen Zugang zu spirituellen Erfahrungen. Oder das Gegenteil: Du bist so abgehoben und erd-entrückt, dass du dich nicht mehr in der physischen Realität verankern kannst. Körperlich zeigt sich das oft durch Kopfschmerzen, Depressionen, Desorientiertheit oder neurologische Störungen.',
      'affirmation': 'Ich bin eins mit dem Universum',
      'bodyParts': ['Zirbeldrüse', 'Großhirn', 'Nervensystem'],
    },
  };

  /// Berechne dominantes Chakra basierend auf Lebenszahl
  static Map<String, dynamic> calculateDominantChakra(int lifePathNumber) {
    // Reduziere Lebenszahl auf 1-7
    int chakraNumber = ((lifePathNumber - 1) % 7) + 1;
    return _chakras[chakraNumber] ?? _chakras[1]!;
  }

  /// Berechne blockiertes Chakra (simuliert durch Herausforderungszahl)
  static Map<String, dynamic> calculateBlockedChakra(int challengeNumber) {
    int chakraNumber = ((challengeNumber - 1) % 7) + 1;
    return _chakras[chakraNumber] ?? _chakras[1]!;
  }

  /// Berechne Chakra-Aktivierungs-Scores für alle 7 Chakren
  static Map<int, int> calculateChakraScores(
    String firstName,
    String lastName,
    DateTime birthDate,
    int lifePathNumber,
  ) {
    final scores = <int, int>{};

    // Basis-Score für jedes Chakra: 50
    for (int i = 1; i <= 7; i++) {
      scores[i] = 50;
    }

    // Dominantes Chakra erhält Bonus
    int dominantChakra = ((lifePathNumber - 1) % 7) + 1;
    scores[dominantChakra] = (scores[dominantChakra] ?? 50) + 25;

    // Namen-Energie-Einfluss
    int nameSum = _calculateNameSum(firstName + lastName);
    for (int i = 1; i <= 7; i++) {
      int influence = (nameSum + i * 13) % 20 - 10;
      scores[i] = (scores[i] ?? 50) + influence;
    }

    // Geburtstag-Einfluss
    int birthDay = birthDate.day;
    int birthInfluence = ((birthDay - 1) % 7) + 1;
    scores[birthInfluence] = (scores[birthInfluence] ?? 50) + 15;

    // Normalisiere alle Scores auf 0-100
    scores.forEach((key, value) {
      scores[key] = value.clamp(0, 100);
    });

    return scores;
  }

  /// Berechne Namens-Summe (einfache Numerologie)
  static int _calculateNameSum(String name) {
    int sum = 0;
    for (int i = 0; i < name.length; i++) {
      sum += name.codeUnitAt(i);
    }
    return sum;
  }

  /// Berechne Element-Verteilung basierend auf Chakra-Scores
  static Map<String, int> calculateElementDistribution(
      Map<int, int> chakraScores) {
    final elements = <String, int>{
      'Erde': chakraScores[1] ?? 50,
      'Wasser': chakraScores[2] ?? 50,
      'Feuer': chakraScores[3] ?? 50,
      'Luft': chakraScores[4] ?? 50,
      'Äther': chakraScores[5] ?? 50,
      'Licht': chakraScores[6] ?? 50,
      'Bewusstsein': chakraScores[7] ?? 50,
    };
    return elements;
  }

  /// Generiere Chakra-Balance-Empfehlungen
  static List<String> generateBalanceRecommendations(
    Map<int, int> chakraScores,
    int dominantChakra,
    int blockedChakra,
  ) {
    final recommendations = <String>[];

    // Empfehlungen für dominantes Chakra
    final dominant = _chakras[dominantChakra];
    if (dominant != null) {
      recommendations
          .add('🌟 Stärke dein ${dominant['name']}: ${dominant['balanced']}');
    }

    // Empfehlungen für blockiertes Chakra
    final blocked = _chakras[blockedChakra];
    if (blocked != null) {
      recommendations.add(
          '⚠️ Arbeite an deinem ${blocked['name']}: ${blocked['blocked']}');
      recommendations
          .add('🧘 Mantra für ${blocked['name']}: ${blocked['mantra']}');
      recommendations.add('💚 Affirmation: ${blocked['affirmation']}');
    }

    // Finde schwächstes Chakra
    int weakestChakra = 1;
    int lowestScore = 100;
    chakraScores.forEach((chakra, score) {
      if (score < lowestScore) {
        lowestScore = score;
        weakestChakra = chakra;
      }
    });

    final weakest = _chakras[weakestChakra];
    if (weakest != null && weakestChakra != blockedChakra) {
      recommendations.add(
          '💪 Stärke dein schwächstes Chakra (${weakest['name']}): Frequenz ${weakest['frequency']} Hz');
    }

    return recommendations;
  }

  /// Berechne Gesamt-Chakra-Balance (0-100)
  static int calculateOverallBalance(Map<int, int> chakraScores) {
    // Berechne Durchschnitt
    int sum = 0;
    chakraScores.forEach((_, score) {
      sum += score;
    });
    int average = (sum / 7).round();

    // Berechne Varianz (niedrige Varianz = gute Balance)
    int variance = 0;
    chakraScores.forEach((_, score) {
      variance += ((score - average) * (score - average)).abs();
    });
    int variancePenalty = (variance / 100).round();

    // Balance-Score: Durchschnitt minus Varianz-Strafe
    int balanceScore = average - variancePenalty;
    return balanceScore.clamp(0, 100);
  }

  /// Alle Chakren abrufen
  static Map<int, Map<String, dynamic>> getAllChakras() {
    return Map.from(_chakras);
  }

  /// Chakra-Farbe für Visualisierung
  static Color getChakraColor(int chakraNumber) {
    final chakra = _chakras[chakraNumber];
    return (chakra?['color'] as Color?) ?? Colors.grey;
  }

  /// Chakra-Name
  static String getChakraName(int chakraNumber) {
    final chakra = _chakras[chakraNumber];
    return chakra?['name'] as String? ?? 'Unbekannt';
  }
}
