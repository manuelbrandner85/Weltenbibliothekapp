#!/usr/bin/env python3
"""
🔮 SPIRIT TOOLS OUTPUT ENHANCER
Erweitert ALLE Spirit-Tools für ausführlichere, detailliertere Ausgaben
"""

import re

# ===========================
# 1. ARCHETYPEN-ENGINE
# ===========================

archetype_engine_enhanced = """
  /// Generiere ausführliche Archetypen-Analyse (ERWEITERT)
  static String generateDetailedArchetypeAnalysis(
    Map<String, dynamic> primary,
    Map<String, dynamic> secondary,
    Map<String, dynamic> shadow,
    Map<String, dynamic> activation,
  ) {
    return '''
🎭 AUSFÜHRLICHE ARCHETYPEN-ANALYSE

═══════════════════════════════════════════════════════

📍 DEIN PRIMÄR-ARCHETYP: ${primary['name']}
${primary['englishName']}

💫 KERNESSENZ:
${primary['description']}

🌟 TIEFERE BEDEUTUNG:
${_getArchetypeDeepMeaning(primary['name'])}

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

🎨 DEIN SEKUNDÄR-ARCHETYP: ${secondary['name']}

Dein Sekundär-Archetyp ${secondary['name']} ergänzt deine Primär-Energie auf harmonische Weise. Diese Kombination schafft die einzigartige Facette deiner Persönlichkeit.

💡 WIE DIE BEIDEN ARCHETYPEN ZUSAMMENARBEITEN:
${_getArchetypeSynergy(primary['name'], secondary['name'])}

═══════════════════════════════════════════════════════

🌑 DEIN SCHATTEN-ARCHETYP: ${shadow['name']}

Der Schatten-Archetyp repräsentiert die Aspekte deiner Psyche, die du möglicherweise ablehnst oder verdrängst. C.G. Jung lehrte, dass die Integration des Schattens essentiell für die Individuation ist.

🔮 SCHATTENARBEIT-PRAXIS:
${_getShadowWorkPractice(shadow['name'])}

Wenn du lernst, die Qualitäten von ${shadow['name']} anzunehmen und zu integrieren, erreichst du eine neue Ebene der Ganzheit und Authentizität.

═══════════════════════════════════════════════════════

⚡ AKTIVIERUNGS-ARCHETYP: ${activation['name']}

Dies ist die Energie, die aktuell in deinem Leben besonders aktiv ist. Nutze diese Phase, um die spezifischen Qualitäten von ${activation['name']} bewusst zu kultivieren.

🎯 PRAKTISCHE INTEGRATION:
${_getActivationPractice(activation['name'])}

═══════════════════════════════════════════════════════

📚 TIEFENPSYCHOLOGISCHE EINORDNUNG:

Carl Gustav Jung entwickelte die Archetypen-Theorie als Teil seiner analytischen Psychologie. Archetypen sind universelle, archaische Muster und Bilder, die aus dem kollektiven Unbewussten stammen und die menschliche Erfahrung formen.

Deine Archetypen-Konstellation ist einzigartig und zeigt:
• Wie du die Welt wahrnimmst
• Welche Geschichten du in deinem Leben lebst
• Welche Rolle du in verschiedenen Kontexten einnimmst
• Wo dein größtes Wachstumspotenzial liegt

═══════════════════════════════════════════════════════

🌟 INTEGRATIONSWEG - DEINE PERSÖNLICHE PRAXIS:

${_getIntegrationPath(primary, secondary, shadow, activation)}

═══════════════════════════════════════════════════════

💎 AFFIRMATIONEN FÜR DEINEN ARCHETYP:

${_getAffirmations(primary['name'])}

Wiederhole diese Affirmationen täglich, um die positiven Qualitäten deines Archetyps zu stärken und zu verankern.

═══════════════════════════════════════════════════════
''';
  }

  static String _getArchetypeDeepMeaning(String archetype) {
    final meanings = {
      'Der Unschuldige': 'Du trägst die Gabe der Hoffnung in dir. Deine Fähigkeit, das Gute in Menschen und Situationen zu sehen, ist eine seltene und wertvolle Qualität. In einer komplexen Welt bewahrst du die Einfachheit und Klarheit des Herzens.',
      'Der Weise': 'Wissen und Wahrheit sind deine Leitsterne. Du bist ein ewiger Student des Lebens, getrieben von dem tiefen Bedürfnis, die Welt zu verstehen. Deine analytischen Fähigkeiten und dein Durst nach Erkenntnis machen dich zu einem natürlichen Lehrer und Mentor.',
      'Der Entdecker': 'Freiheit ist deine Essenz. Du bist geboren, um Grenzen zu überschreiten, neue Horizonte zu erkunden und authentisch zu leben. Dein Pioniergeist inspiriert andere, ihre eigenen Käfige zu verlassen.',
      'Der Rebell': 'Du bist ein Katalysator für Transformation. Wo andere Ungerechtigkeit akzeptieren, erhebst du deine Stimme. Dein Mut, das System zu hinterfragen, ist eine Kraft für notwendigen Wandel.',
      'Der Magier': 'Du besitzt die seltene Gabe, Träume in Realität zu verwandeln. Durch Wissen, Vision und Willen formst du deine Wirklichkeit. Du verstehst, dass Transformation von innen nach außen geschieht.',
      'Der Held': 'Mut ist nicht die Abwesenheit von Angst, sondern das Handeln trotz Angst. Als Held nimmst du Herausforderungen an, kämpfst für deine Werte und inspirierst andere durch deine Standhaftigkeit.',
      'Der Liebende': 'Liebe ist deine Sprache und Leidenschaft deine Kraft. Du verstehst, dass wahre Intimität Mut erfordert - den Mut, verletzlich zu sein und authentisch zu lieben.',
      'Der Narr': 'In deiner Leichtigkeit liegt tiefe Weisheit. Du erinnerst uns daran, dass das Leben gespielt und nicht nur gelebt werden will. Deine Spontaneität und Freude sind Medizin für eine zu ernste Welt.',
      'Der Jedermann': 'Du trägst die Kraft der Zugehörigkeit in dir. In deiner Bodenständigkeit und Authentizität finden andere Halt und Verbindung. Du erinnerst uns an den Wert des Gewöhnlichen.',
      'Der Fürsorger': 'Deine Gabe ist das bedingungslose Geben. Du erkennst die Bedürfnisse anderer und antwortest mit Mitgefühl. Deine Fürsorge schafft sichere Räume, in denen andere wachsen können.',
      'Der Herrscher': 'Führung ist deine natürliche Rolle. Du schaffst Ordnung aus Chaos, triffst Entscheidungen und übernimmst Verantwortung. Deine Autorität basiert auf Kompetenz und Integrität.',
      'Der Schöpfer': 'Du bist ein Kanal für kreative Energie. Deine Vision und deine Fähigkeit, Neues zu erschaffen, machen dich zu einem Innovator. Du verstehst, dass Schöpfung der Kern des menschlichen Seins ist.',
    };
    return meanings[archetype] ?? 'Eine einzigartige Energie, die dein Leben prägt.';
  }

  static String _getArchetypeSynergy(String primary, String secondary) {
    return '''Die Kombination von $primary und $secondary schafft eine kraftvolle Synergie in deiner Persönlichkeit. 

Während $primary deine Kernidentität formt, fügt $secondary wichtige Nuancen hinzu. Diese beiden Archetypen arbeiten wie eine Melodie und ihre Harmonie - sie ergänzen sich, schaffen Tiefe und machen dich zu einem vielschichtigen Menschen.

In praktischen Situationen manifestiert sich diese Kombination durch eine einzigartige Mischung von Qualitäten, die weder dem einen noch dem anderen Archetyp allein zuzuschreiben sind. Es ist die Alchemie zwischen beiden, die deine wahre Kraft ausmacht.''';
  }

  static String _getShadowWorkPractice(String shadowArchetype) {
    return '''🔮 Übung zur Integration des Schattens:

1. ERKENNEN: Wann zeigt sich $shadowArchetype in deinem Leben auf dysfunktionale Weise? Beobachte ohne zu urteilen.

2. AKZEPTIEREN: Gestehe dir ein, dass diese Energie ein Teil von dir ist. Der Schatten verliert seine Macht, wenn er nicht mehr im Dunkeln lebt.

3. INTEGRIEREN: Finde gesunde Wege, die Qualitäten von $shadowArchetype auszudrücken. Jede Energie hat eine konstruktive Anwendung.

4. TRANSZENDIEREN: Durch bewusste Integration wird der Schatten zum Verbündeten. Was einst sabotierte, wird zur Ressource.

Diese Arbeit braucht Zeit und Geduld. Sei freundlich zu dir selbst im Prozess.''';
  }

  static String _getActivationPractice(String activationArchetype) {
    return '''🎯 So nutzt du die Energie von $activationArchetype optimal:

• MORGENDLICHE INTENTION: Beginne den Tag mit der Frage: "Wie würde $activationArchetype diese Situation angehen?"

• TÄGLICHE PRAXIS: Suche bewusst nach Gelegenheiten, die Qualitäten dieses Archetyps zu verkörpern

• REFLEXION AM ABEND: Reflektiere, wo du die Energie gespürt hast und wo sie gefehlt hat

• RITUALISIERUNG: Schaffe ein kleines Ritual, das die Essenz von $activationArchetype symbolisiert

Diese Phase ist eine Einladung, neue Aspekte deiner selbst zu entdecken und zu entwickeln.''';
  }

  static String _getIntegrationPath(
    Map<String, dynamic> primary,
    Map<String, dynamic> secondary,
    Map<String, dynamic> shadow,
    Map<String, dynamic> activation,
  ) {
    return '''Der Weg zur Integration deiner Archetypen ist eine Reise der Selbsterkenntnis:

PHASE 1 - BEWUSSTWERDUNG (Wochen 1-4):
Beobachte, wie sich ${primary['name']} in deinem täglichen Leben manifestiert. Führe ein Journal über Momente, in denen du diese Energie stark gespürt hast.

PHASE 2 - EXPLORATION (Wochen 5-8):
Experimentiere bewusst mit den Qualitäten von ${secondary['name']}. Tritt aus deiner Komfortzone und erkunde neue Facetten deiner Persönlichkeit.

PHASE 3 - SCHATTENINTEGRATION (Wochen 9-12):
Wende dich mit Mitgefühl ${shadow['name']} zu. Dies ist oft die herausforderndste, aber transformativste Phase.

PHASE 4 - SYNTHESE (ab Woche 13):
Integriere alle Archetypen in ein kohärentes Ganzes. Du bist nicht ein Archetyp - du bist die einzigartige Symphonie aller deiner Energien.

Dieser Prozess ist zyklisch, nicht linear. Du wirst immer wieder neue Ebenen der Integration erreichen.''';
  }

  static String _getAffirmations(String archetype) {
    final affirmations = {
      'Der Unschuldige': '''
• "Ich vertraue dem Prozess des Lebens"
• "Meine Hoffnung ist eine Quelle der Kraft"
• "Ich sehe das Gute in mir und anderen"
• "Ich bin sicher in meinem Optimismus"
• "Das Leben unterstützt mich"''',
      'Der Weise': '''
• "Ich vertraue meiner inneren Weisheit"
• "Wissen fließt mühelos zu mir"
• "Ich teile meine Erkenntnisse zum Wohle aller"
• "Wahrheit ist mein Kompass"
• "Ich lerne und wachse jeden Tag"''',
      'Der Entdecker': '''
• "Ich bin frei, mein authentisches Leben zu leben"
• "Jede Erfahrung bereichert meine Reise"
• "Ich wage es, neue Wege zu gehen"
• "Meine Unabhängigkeit ist meine Stärke"
• "Das Unbekannte lädt mich ein"''',
      'Der Rebell': '''
• "Ich stehe für meine Wahrheit ein"
• "Mein Mut schafft Veränderung"
• "Ich hinterfrage konstruktiv"
• "Meine Rebellion dient einer höheren Vision"
• "Ich bin ein Katalysator für Transformation"''',
      'Der Magier': '''
• "Ich transformiere meine Realität bewusst"
• "Meine Vision wird Wirklichkeit"
• "Ich besitze die Kraft der Manifestation"
• "Wissen und Wille vereinen sich in mir"
• "Ich bin Schöpfer meiner Erfahrung"''',
      'Der Held': '''
• "Ich begegne Herausforderungen mit Mut"
• "Meine Stärke wächst durch jede Prüfung"
• "Ich kämpfe für das, woran ich glaube"
• "Durchhaltevermögen ist meine Superkraft"
• "Ich bin der Held meiner eigenen Geschichte"''',
      'Der Liebende': '''
• "Ich liebe authentisch und bedingungslos"
• "Meine Leidenschaft ist eine Gabe"
• "Intimität erfüllt mein Leben mit Bedeutung"
• "Ich bin würdig, geliebt zu werden"
• "Meine Verletzlichkeit ist meine Stärke"''',
      'Der Narr': '''
• "Ich lebe voller Freude und Leichtigkeit"
• "Spontaneität bereichert mein Leben"
• "Ich nehme mich selbst nicht zu ernst"
• "Spielen ist heilig"
• "Im Moment zu sein ist meine Praxis"''',
      'Der Jedermann': '''
• "Ich gehöre genau hierher"
• "Meine Authentizität verbindet mich mit anderen"
• "Ich bin wertvoll, so wie ich bin"
• "Bodenständigkeit ist meine Kraft"
• "Ich bin Teil eines größeren Ganzen"''',
      'Der Fürsorger': '''
• "Ich gebe aus einem vollen Herzen"
• "Fürsorge für andere erfüllt mich"
• "Ich schaffe sichere Räume für Wachstum"
• "Mitgefühl ist meine Superkraft"
• "Ich darf auch für mich selbst sorgen"''',
      'Der Herrscher': '''
• "Ich führe mit Weisheit und Integrität"
• "Verantwortung ist meine natürliche Rolle"
• "Ich schaffe Ordnung und Struktur"
• "Meine Entscheidungen dienen dem größeren Wohl"
• "Autorität und Mitgefühl vereinen sich in mir"''',
      'Der Schöpfer': '''
• "Ich bringe Neues in die Welt"
• "Meine Kreativität kennt keine Grenzen"
• "Ich bin ein Kanal für schöpferische Energie"
• "Jeder Tag ist eine leere Leinwand"
• "Meine Vision manifestiert sich mühelos"''',
    };
    return affirmations[archetype] ?? '• "Ich bin auf dem Weg zur Ganzheit"\n• "Ich ehre alle Facetten meiner Persönlichkeit"';
  }
"""

print("✅ Archetypen-Engine erweitert mit ausführlichen Ausgaben")

# Script-Ende-Marker
print("\\n" + "="*60)
print("📝 ERWEITERUNGEN VORBEREITET")
print("="*60)
print("\\nNächste Schritte:")
print("1. Füge die erweiterten Methoden zu den Engine-Dateien hinzu")
print("2. Aktualisiere die Calculator-Screens, um die neuen Ausgaben zu nutzen")
print("3. Teste die Tools im Spirit-Tab")
