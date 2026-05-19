import 'package:flutter/material.dart';

/// 🎭 ARCHETYPEN-ENGINE
///
/// Basiert auf C.G. Jung's Archetypen-Theorie
///
/// 12 HAUPT-ARCHETYPEN:
/// - Der Unschuldige, Der Weise, Der Entdecker, Der Rebell
/// - Der Magier, Der Held, Der Liebende, Der Narr
/// - Der Jedermann, Der Fürsorger, Der Herrscher, Der Schöpfer
///
/// BERECHNUNG:
/// - Primär-Archetyp: Basiert auf Lebenszahl
/// - Sekundär-Archetyp: Basiert auf Ausdruckszahl
/// - Schatten-Archetyp: Basiert auf Herausforderungszahl
/// - Aktivierungs-Archetyp: Basiert auf Persönlichem Jahr
class ArchetypeEngine {
  /// 12 Jung'sche Archetypen mit vollständigen Beschreibungen
  static final Map<int, Map<String, dynamic>> _archetypes = {
    1: {
      'name': 'Der Unschuldige',
      'englishName': 'The Innocent',
      'description': 'Sucht nach Glück, Optimismus und Reinheit',
      'motivation': 'Paradies finden und Glück erleben',
      'fear': 'Bestrafung für Fehler, Schuld',
      'strength': 'Vertrauen, Optimismus, Treue',
      'weakness': 'Naivität, Realitätsflucht',
      'element': 'Luft',
      'color': Color(0xFFE3F2FD),
      'keywords': ['Optimismus', 'Vertrauen', 'Reinheit', 'Hoffnung'],
    },
    2: {
      'name': 'Der Weise',
      'englishName': 'The Sage',
      'description': 'Sucht nach Wahrheit und Erkenntnis',
      'motivation': 'Die Wahrheit verstehen und teilen',
      'fear': 'Unwissenheit, Täuschung',
      'strength': 'Weisheit, Intelligenz, Analyse',
      'weakness': 'Überanalyse, Isolation',
      'element': 'Luft',
      'color': Color(0xFF9575CD),
      'keywords': ['Wissen', 'Weisheit', 'Klarheit', 'Wahrheit'],
    },
    3: {
      'name': 'Der Entdecker',
      'englishName': 'The Explorer',
      'description': 'Strebt nach Freiheit und Abenteuer',
      'motivation': 'Die Welt erkunden, Authentizität finden',
      'fear': 'Gefangen sein, Konformität',
      'strength': 'Mut, Autonomie, Pioniergeist',
      'weakness': 'Rastlosigkeit, Verantwortungsscheu',
      'element': 'Feuer',
      'color': Color(0xFFFFCC80),
      'keywords': ['Freiheit', 'Abenteuer', 'Unabhängigkeit', 'Erkundung'],
    },
    4: {
      'name': 'Der Rebell',
      'englishName': 'The Outlaw',
      'description': 'Kämpft gegen Ungerechtigkeit und Unterdrückung',
      'motivation': 'Revolution, Zerstörung des Dysfunktionalen',
      'fear': 'Machtlosigkeit, Bedeutungslosigkeit',
      'strength': 'Mut, Radikalität, Befreiung',
      'weakness': 'Destruktivität, Selbstzerstörung',
      'element': 'Feuer',
      'color': Color(0xFFEF5350),
      'keywords': ['Revolution', 'Mut', 'Rebellion', 'Transformation'],
    },
    5: {
      'name': 'Der Magier',
      'englishName': 'The Magician',
      'description': 'Transformiert Realität durch Wissen und Macht',
      'motivation': 'Träume in Realität verwandeln',
      'fear': 'Unbeabsichtigte negative Konsequenzen',
      'strength': 'Transformation, Vision, Macht',
      'weakness': 'Manipulation, Größenwahn',
      'element': 'Äther',
      'color': Color(0xFF9C27B0),
      'keywords': ['Transformation', 'Macht', 'Vision', 'Alchemie'],
    },
    6: {
      'name': 'Der Held',
      'englishName': 'The Hero',
      'description': 'Kämpft für Gerechtigkeit und Erfolg',
      'motivation': 'Mut beweisen, die Welt verbessern',
      'fear': 'Schwäche, Verletzlichkeit',
      'strength': 'Mut, Disziplin, Durchhaltevermögen',
      'weakness': 'Arroganz, Kampfsucht',
      'element': 'Feuer',
      'color': Color(0xFFFF9800),
      'keywords': ['Mut', 'Stärke', 'Disziplin', 'Sieg'],
    },
    7: {
      'name': 'Der Liebende',
      'englishName': 'The Lover',
      'description': 'Sucht nach Intimität und Verbindung',
      'motivation': 'Liebe geben und empfangen, Leidenschaft',
      'fear': 'Einsamkeit, Ungeliebt-sein',
      'strength': 'Leidenschaft, Hingabe, Empathie',
      'weakness': 'Abhängigkeit, Selbstverlust',
      'element': 'Wasser',
      'color': Color(0xFFE91E63),
      'keywords': ['Liebe', 'Leidenschaft', 'Intimität', 'Hingabe'],
    },
    8: {
      'name': 'Der Narr',
      'englishName': 'The Jester',
      'description': 'Bringt Freude und lebt im Moment',
      'motivation': 'Freude erleben und teilen, im Jetzt leben',
      'fear': 'Langeweile, Bedeutungslosigkeit',
      'strength': 'Humor, Spontaneität, Lebensfreude',
      'weakness': 'Oberflächlichkeit, Verantwortungslosigkeit',
      'element': 'Luft',
      'color': Color(0xFFFFEB3B),
      'keywords': ['Freude', 'Humor', 'Spontaneität', 'Leichtigkeit'],
    },
    9: {
      'name': 'Der Jedermann',
      'englishName': 'The Everyman',
      'description': 'Sucht nach Zugehörigkeit und Verbundenheit',
      'motivation': 'Dazugehören, sich verbinden',
      'fear': 'Ausgeschlossen sein, auffallen',
      'strength': 'Empathie, Realismus, Bodenständigkeit',
      'weakness': 'Konformität, Selbstaufgabe',
      'element': 'Erde',
      'color': Color(0xFF8D6E63),
      'keywords': ['Gemeinschaft', 'Empathie', 'Zugehörigkeit', 'Realismus'],
    },
    10: {
      'name': 'Der Fürsorger',
      'englishName': 'The Caregiver',
      'description': 'Schützt und kümmert sich um andere',
      'motivation': 'Anderen helfen und dienen',
      'fear': 'Egoismus, Undankbarkeit',
      'strength': 'Mitgefühl, Großzügigkeit, Fürsorge',
      'weakness': 'Selbstaufopferung, Märtyrertum',
      'element': 'Wasser',
      'color': Color(0xFF81C784),
      'keywords': ['Fürsorge', 'Mitgefühl', 'Schutz', 'Dienst'],
    },
    11: {
      'name': 'Der Herrscher',
      'englishName': 'The Ruler',
      'description': 'Schafft Ordnung und Kontrolle',
      'motivation': 'Macht und Kontrolle ausüben, Wohlstand schaffen',
      'fear': 'Chaos, Machtverlust',
      'strength': 'Führung, Verantwortung, Autorität',
      'weakness': 'Kontrollzwang, Dominanz',
      'element': 'Feuer',
      'color': Color(0xFFFFD700),
      'keywords': ['Führung', 'Macht', 'Ordnung', 'Autorität'],
    },
    12: {
      'name': 'Der Schöpfer',
      'englishName': 'The Creator',
      'description': 'Erschafft bleibende Werte und Innovation',
      'motivation': 'Etwas Bedeutungsvolles erschaffen',
      'fear': 'Mittelmäßigkeit, Unkreativität',
      'strength': 'Kreativität, Imagination, Innovation',
      'weakness': 'Perfektionismus, Realitätsferne',
      'element': 'Äther',
      'color': Color(0xFF7E57C2),
      'keywords': ['Kreativität', 'Innovation', 'Vision', 'Schöpfung'],
    },
  };

  /// Berechne Primär-Archetyp basierend auf Lebenszahl
  static Map<String, dynamic> calculatePrimaryArchetype(int lifePathNumber) {
    // Reduziere Lebenszahl auf 1-12 für Archetypen-Zuordnung
    int archetypeNumber = ((lifePathNumber - 1) % 12) + 1;
    return _archetypes[archetypeNumber] ?? _archetypes[1]!;
  }

  /// Berechne Sekundär-Archetyp basierend auf Ausdruckszahl
  static Map<String, dynamic> calculateSecondaryArchetype(
      int expressionNumber) {
    int archetypeNumber = ((expressionNumber - 1) % 12) + 1;
    return _archetypes[archetypeNumber] ?? _archetypes[1]!;
  }

  /// Berechne Schatten-Archetyp (Gegenteil des Primär-Archetyps)
  static Map<String, dynamic> calculateShadowArchetype(int lifePathNumber) {
    // Schatten ist gegenüberliegend (6 Schritte weiter im Kreis)
    int primaryArchetype = ((lifePathNumber - 1) % 12) + 1;
    int shadowArchetype = ((primaryArchetype + 5) % 12) + 1;
    return _archetypes[shadowArchetype] ?? _archetypes[1]!;
  }

  /// Berechne Aktivierungs-Archetyp basierend auf Persönlichem Jahr
  static Map<String, dynamic> calculateActivationArchetype(int personalYear) {
    int archetypeNumber = ((personalYear - 1) % 12) + 1;
    return _archetypes[archetypeNumber] ?? _archetypes[1]!;
  }

  /// Berechne Archetypen-Integration Score (0-100)
  static int calculateIntegrationScore(
    Map<String, dynamic> primary,
    Map<String, dynamic> secondary,
    Map<String, dynamic> shadow,
  ) {
    // Basis-Score: 50
    int score = 50;

    // Bonus für kompatible Elemente
    if (primary['element'] == secondary['element']) {
      score += 15;
    }

    // Bonus für bewusste Schatten-Arbeit (simuliert)
    score += 20;

    // Varianz basierend auf Archetypen-Namen
    int variation = (primary['name'].toString().length +
            secondary['name'].toString().length) %
        20;
    score += variation - 10;

    return score.clamp(0, 100);
  }

  /// Berechne Element-Verteilung
  static Map<String, int> calculateElementDistribution(
    Map<String, dynamic> primary,
    Map<String, dynamic> secondary,
    Map<String, dynamic> shadow,
    Map<String, dynamic> activation,
  ) {
    final elements = <String, int>{
      'Feuer': 0,
      'Wasser': 0,
      'Luft': 0,
      'Erde': 0,
      'Äther': 0,
    };

    final primaryElement = primary['element'] as String?;
    final secondaryElement = secondary['element'] as String?;
    final shadowElement = shadow['element'] as String?;
    final activationElement = activation['element'] as String?;

    if (primaryElement != null)
      elements[primaryElement] = (elements[primaryElement] ?? 0) + 2;
    if (secondaryElement != null)
      elements[secondaryElement] = (elements[secondaryElement] ?? 0) + 2;
    if (shadowElement != null)
      elements[shadowElement] = (elements[shadowElement] ?? 0) + 1;
    if (activationElement != null)
      elements[activationElement] = (elements[activationElement] ?? 0) + 1;

    return elements;
  }

  /// Generiere Archetypen-Entwicklungs-Empfehlungen
  static List<String> generateDevelopmentRecommendations(
    Map<String, dynamic> primary,
    Map<String, dynamic> shadow,
  ) {
    return [
      '🎭 Integriere die Stärken deines Primär-Archetyps: ${primary['strength']}',
      '⚠️ Achte auf die Schwächen: ${primary['weakness']}',
      '🌑 Schattenarbeit: Erkenne und akzeptiere die Qualitäten von ${shadow['name']}',
      '💪 Entwicklungsaufgabe: Überwindung der Angst vor ${primary['fear']}',
      '🎯 Motivation: ${primary['motivation']}',
    ];
  }

  /// 🆕 Generiere AUSFÜHRLICHE Archetypen-Analyse (DETAILLIERT)
  static String generateDetailedAnalysis(
    Map<String, dynamic> primary,
    Map<String, dynamic> secondary,
    Map<String, dynamic> shadow,
    Map<String, dynamic> activation,
  ) {
    final primaryName = primary['name'] as String;
    final secondaryName = secondary['name'] as String;
    final shadowName = shadow['name'] as String;
    final activationName = activation['name'] as String;

    return '''
🎭 AUSFÜHRLICHE ARCHETYPEN-ANALYSE

═══════════════════════════════════════════════════════

📍 DEIN PRIMÄR-ARCHETYP: $primaryName
${primary['englishName']}

💫 KERNESSENZ:
${primary['description']}

🌟 TIEFERE BEDEUTUNG:
${_getArchetypeDeepMeaning(primaryName)}

🔑 ZENTRALE MOTIVATION:
${primary['motivation']}

Diese Motivation treibt dich auf einer tiefen, oft unbewussten Ebene an. Sie ist der rote Faden, der sich durch dein gesamtes Leben zieht und deine wichtigsten Entscheidungen beeinflusst.

⚡ DEINE SUPERKRÄFTE:
${primary['strength']}

Diese Stärken sind deine natürlichen Gaben. Wenn du in Harmonie mit deinem Archetyp lebst, manifestieren sich diese Qualitäten mühelos. Sie sind wie ein innerer Kompass, der dich zu deinem authentischen Selbst führt.

⚠️ DEINE HERAUSFORDERUNGEN:
${primary['weakness']}

Jeder Archetyp hat seine Schattenseiten. Diese Schwächen entstehen, wenn die positiven Qualitäten aus dem Gleichgewicht geraten. Bewusstsein ist der erste Schritt zur Transformation.

😨 TIEFSTE ANGST:
${primary['fear']}

Diese Angst sitzt oft tief im Unbewussten. Sie zu erkennen und anzunehmen ist ein wichtiger Schritt auf dem Weg zur Ganzheit. Die Angst zeigt dir, wo noch Heilung notwendig ist.

🌈 ELEMENT: ${primary['element']}

Das Element ${primary['element']} repräsentiert deine energetische Signatur. Es beeinflusst, wie du mit der Welt interagierst und Energie austauschst.

═══════════════════════════════════════════════════════

🎨 DEIN SEKUNDÄR-ARCHETYP: $secondaryName

Dein Sekundär-Archetyp $secondaryName ergänzt deine Primär-Energie auf harmonische Weise. Diese Kombination schafft die einzigartige Facette deiner Persönlichkeit.

💡 WIE DIE BEIDEN ARCHETYPEN ZUSAMMENARBEITEN:
Die Kombination von $primaryName und $secondaryName schafft eine kraftvolle Synergie in deiner Persönlichkeit. 

Während $primaryName deine Kernidentität formt, fügt $secondaryName wichtige Nuancen hinzu. Diese beiden Archetypen arbeiten wie eine Melodie und ihre Harmonie - sie ergänzen sich, schaffen Tiefe und machen dich zu einem vielschichtigen Menschen.

In praktischen Situationen manifestiert sich diese Kombination durch eine einzigartige Mischung von Qualitäten, die weder dem einen noch dem anderen Archetyp allein zuzuschreiben sind. Es ist die Alchemie zwischen beiden, die deine wahre Kraft ausmacht.

═══════════════════════════════════════════════════════

🌑 DEIN SCHATTEN-ARCHETYP: $shadowName

Der Schatten-Archetyp repräsentiert die Aspekte deiner Psyche, die du möglicherweise ablehnst oder verdrängst. C.G. Jung lehrte, dass die Integration des Schattens essentiell für die Individuation ist.

🔮 SCHATTENARBEIT-PRAXIS:
1. ERKENNEN: Wann zeigt sich $shadowName in deinem Leben auf dysfunktionale Weise? Beobachte ohne zu urteilen.

2. AKZEPTIEREN: Gestehe dir ein, dass diese Energie ein Teil von dir ist. Der Schatten verliert seine Macht, wenn er nicht mehr im Dunkeln lebt.

3. INTEGRIEREN: Finde gesunde Wege, die Qualitäten von $shadowName auszudrücken. Jede Energie hat eine konstruktive Anwendung.

4. TRANSZENDIEREN: Durch bewusste Integration wird der Schatten zum Verbündeten. Was einst sabotierte, wird zur Ressource.

═══════════════════════════════════════════════════════

⚡ AKTIVIERUNGS-ARCHETYP: $activationName

Dies ist die Energie, die aktuell in deinem Leben besonders aktiv ist. Nutze diese Phase, um die spezifischen Qualitäten von $activationName bewusst zu kultivieren.

🎯 PRAKTISCHE INTEGRATION:
• MORGENDLICHE INTENTION: Beginne den Tag mit der Frage: "Wie würde $activationName diese Situation angehen?"

• TÄGLICHE PRAXIS: Suche bewusst nach Gelegenheiten, die Qualitäten dieses Archetyps zu verkörpern

• REFLEXION AM ABEND: Reflektiere, wo du die Energie gespürt hast und wo sie gefehlt hat

• RITUALISIERUNG: Schaffe ein kleines Ritual, das die Essenz von $activationName symbolisiert

Diese Phase ist eine Einladung, neue Aspekte deiner selbst zu entdecken und zu entwickeln.

═══════════════════════════════════════════════════════

📚 TIEFENPSYCHOLOGISCHE EINORDNUNG:

Carl Gustav Jung entwickelte die Archetypen-Theorie als Teil seiner analytischen Psychologie. Archetypen sind universelle, archaische Muster und Bilder, die aus dem kollektiven Unbewussten stammen und die menschliche Erfahrung formen.

Deine Archetypen-Konstellation ist einzigartig und zeigt:
• Wie du die Welt wahrnimmst
• Welche Geschichten du in deinem Leben lebst
• Welche Rolle du in verschiedenen Kontexten einnimmst
• Wo dein größtes Wachstumspotenzial liegt

═══════════════════════════════════════════════════════

💎 AFFIRMATIONEN FÜR DEINEN ARCHETYP:
${_getAffirmations(primaryName)}

Wiederhole diese Affirmationen täglich, um die positiven Qualitäten deines Archetyps zu stärken und zu verankern.

═══════════════════════════════════════════════════════
''';
  }

  static String _getArchetypeDeepMeaning(String archetype) {
    final meanings = {
      'Der Unschuldige':
          'Du trägst die Gabe der Hoffnung in dir. Deine Fähigkeit, das Gute in Menschen und Situationen zu sehen, ist eine seltene und wertvolle Qualität. In einer komplexen Welt bewahrst du die Einfachheit und Klarheit des Herzens.',
      'Der Weise':
          'Wissen und Wahrheit sind deine Leitsterne. Du bist ein ewiger Student des Lebens, getrieben von dem tiefen Bedürfnis, die Welt zu verstehen. Deine analytischen Fähigkeiten und dein Durst nach Erkenntnis machen dich zu einem natürlichen Lehrer und Mentor.',
      'Der Entdecker':
          'Freiheit ist deine Essenz. Du bist geboren, um Grenzen zu überschreiten, neue Horizonte zu erkunden und authentisch zu leben. Dein Pioniergeist inspiriert andere, ihre eigenen Käfige zu verlassen.',
      'Der Rebell':
          'Du bist ein Katalysator für Transformation. Wo andere Ungerechtigkeit akzeptieren, erhebst du deine Stimme. Dein Mut, das System zu hinterfragen, ist eine Kraft für notwendigen Wandel.',
      'Der Magier':
          'Du besitzt die seltene Gabe, Träume in Realität zu verwandeln. Durch Wissen, Vision und Willen formst du deine Wirklichkeit. Du verstehst, dass Transformation von innen nach außen geschieht.',
      'Der Held':
          'Mut ist nicht die Abwesenheit von Angst, sondern das Handeln trotz Angst. Als Held nimmst du Herausforderungen an, kämpfst für deine Werte und inspirierst andere durch deine Standhaftigkeit.',
      'Der Liebende':
          'Liebe ist deine Sprache und Leidenschaft deine Kraft. Du verstehst, dass wahre Intimität Mut erfordert - den Mut, verletzlich zu sein und authentisch zu lieben.',
      'Der Narr':
          'In deiner Leichtigkeit liegt tiefe Weisheit. Du erinnerst uns daran, dass das Leben gespielt und nicht nur gelebt werden will. Deine Spontaneität und Freude sind Medizin für eine zu ernste Welt.',
      'Der Jedermann':
          'Du trägst die Kraft der Zugehörigkeit in dir. In deiner Bodenständigkeit und Authentizität finden andere Halt und Verbindung. Du erinnerst uns an den Wert des Gewöhnlichen.',
      'Der Fürsorger':
          'Deine Gabe ist das bedingungslose Geben. Du erkennst die Bedürfnisse anderer und antwortest mit Mitgefühl. Deine Fürsorge schafft sichere Räume, in denen andere wachsen können.',
      'Der Herrscher':
          'Führung ist deine natürliche Rolle. Du schaffst Ordnung aus Chaos, triffst Entscheidungen und übernimmst Verantwortung. Deine Autorität basiert auf Kompetenz und Integrität.',
      'Der Schöpfer':
          'Du bist ein Kanal für kreative Energie. Deine Vision und deine Fähigkeit, Neues zu erschaffen, machen dich zu einem Innovator. Du verstehst, dass Schöpfung der Kern des menschlichen Seins ist.',
    };
    return meanings[archetype] ??
        'Eine einzigartige Energie, die dein Leben prägt.';
  }

  static String _getAffirmations(String archetype) {
    final affirmations = {
      'Der Unschuldige': '''• "Ich vertraue dem Prozess des Lebens"
• "Meine Hoffnung ist eine Quelle der Kraft"
• "Ich sehe das Gute in mir und anderen"
• "Ich bin sicher in meinem Optimismus"
• "Das Leben unterstützt mich"''',
      'Der Weise': '''• "Ich vertraue meiner inneren Weisheit"
• "Wissen fließt mühelos zu mir"
• "Ich teile meine Erkenntnisse zum Wohle aller"
• "Wahrheit ist mein Kompass"
• "Ich lerne und wachse jeden Tag"''',
      'Der Entdecker': '''• "Ich bin frei, mein authentisches Leben zu leben"
• "Jede Erfahrung bereichert meine Reise"
• "Ich wage es, neue Wege zu gehen"
• "Meine Unabhängigkeit ist meine Stärke"
• "Das Unbekannte lädt mich ein"''',
      'Der Rebell': '''• "Ich stehe für meine Wahrheit ein"
• "Mein Mut schafft Veränderung"
• "Ich hinterfrage konstruktiv"
• "Meine Rebellion dient einer höheren Vision"
• "Ich bin ein Katalysator für Transformation"''',
      'Der Magier': '''• "Ich transformiere meine Realität bewusst"
• "Meine Vision wird Wirklichkeit"
• "Ich besitze die Kraft der Manifestation"
• "Wissen und Wille vereinen sich in mir"
• "Ich bin Schöpfer meiner Erfahrung"''',
      'Der Held': '''• "Ich begegne Herausforderungen mit Mut"
• "Meine Stärke wächst durch jede Prüfung"
• "Ich kämpfe für das, woran ich glaube"
• "Durchhaltevermögen ist meine Superkraft"
• "Ich bin der Held meiner eigenen Geschichte"''',
      'Der Liebende': '''• "Ich liebe authentisch und bedingungslos"
• "Meine Leidenschaft ist eine Gabe"
• "Intimität erfüllt mein Leben mit Bedeutung"
• "Ich bin würdig, geliebt zu werden"
• "Meine Verletzlichkeit ist meine Stärke"''',
      'Der Narr': '''• "Ich lebe voller Freude und Leichtigkeit"
• "Spontaneität bereichert mein Leben"
• "Ich nehme mich selbst nicht zu ernst"
• "Spielen ist heilig"
• "Im Moment zu sein ist meine Praxis"''',
      'Der Jedermann': '''• "Ich gehöre genau hierher"
• "Meine Authentizität verbindet mich mit anderen"
• "Ich bin wertvoll, so wie ich bin"
• "Bodenständigkeit ist meine Kraft"
• "Ich bin Teil eines größeren Ganzen"''',
      'Der Fürsorger': '''• "Ich gebe aus einem vollen Herzen"
• "Fürsorge für andere erfüllt mich"
• "Ich schaffe sichere Räume für Wachstum"
• "Mitgefühl ist meine Superkraft"
• "Ich darf auch für mich selbst sorgen"''',
      'Der Herrscher': '''• "Ich führe mit Weisheit und Integrität"
• "Verantwortung ist meine natürliche Rolle"
• "Ich schaffe Ordnung und Struktur"
• "Meine Entscheidungen dienen dem größeren Wohl"
• "Autorität und Mitgefühl vereinen sich in mir"''',
      'Der Schöpfer': '''• "Ich bringe Neues in die Welt"
• "Meine Kreativität kennt keine Grenzen"
• "Ich bin ein Kanal für schöpferische Energie"
• "Jeder Tag ist eine leere Leinwand"
• "Meine Vision manifestiert sich mühelos"''',
    };
    return affirmations[archetype] ??
        '''• "Ich bin auf dem Weg zur Ganzheit"
• "Ich ehre alle Facetten meiner Persönlichkeit"''';
  }

  /// Alle Archetypen abrufen
  static Map<int, Map<String, dynamic>> getAllArchetypes() {
    return Map.from(_archetypes);
  }
}
