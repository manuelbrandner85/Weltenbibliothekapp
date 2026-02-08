/// 🌟 ALLE SPIRIT-MODULE ENGINE - DEUTSCH & PERSÖNLICH
/// Vollständig auf Deutsch mit persönlicher Ansprache
library;

import '../../models/energie_profile.dart';

class AllModulesEngineDE {
  static const String version = '2.0.0-de';

  // ========================================
  // MODUL 4: UNTERBEWUSSTSEINS- & MUSTERANALYSE
  // ========================================
  
  static Map<String, dynamic> calculateUnconscious(EnergieProfile profile) {
    final age = DateTime.now().year - profile.birthDate.year;
    final personalYear = _calculatePersonalYear(profile.birthDate);
    
    // Jungian 4 Stages
    final jungianStage = ((age / 70.0) * 4).floor().clamp(1, 4);
    final stageNames = ['Geständnis', 'Aufklärung', 'Bildung', 'Transformation'];
    
    final shadowIntegration = ((age / 60.0) * 60 + (personalYear / 9.0) * 40).toDouble().clamp(0.0, 100.0);
    
    return {
      'repeatingPatterns': _getRepeatingPatterns(personalYear, age, profile.firstName),
      'projectionThemes': _getProjectionThemes(age, jungianStage, profile.firstName),
      'jungianStage': stageNames[jungianStage - 1],
      'shadowIntegrationLevel': shadowIntegration,
      'awarenessMarkers': shadowIntegration > 60 
          ? ['Du reflektierst aktiv über dein Inneres', 'Muster werden dir bewusst', 'Dein Schatten wird zum Verbündeten'] 
          : ['Deine Bewusstseinsreise beginnt', 'Erste Muster tauchen auf', 'Der Schatten wird sichtbar'],
      'dominantPattern': _getDominantPattern(personalYear, profile.firstName),
      'interpretation': _getShadowInterpretation(shadowIntegration, profile.firstName, age),
    };
  }

  // ========================================
  // MODUL 5: INNERE LANDKARTEN & PROZESSNAVIGATION
  // ========================================
  
  static Map<String, dynamic> calculateInnerLandscape(EnergieProfile profile) {
    final age = DateTime.now().year - profile.birthDate.year;
    final personalYear = _calculatePersonalYear(profile.birthDate);
    
    final exercises = [
      'Sinnliche Kartierung',
      'Charakter-Erschaffung', 
      'Künstlerische Reflexion',
      'Metaphern-Erkundung',
      'Umgebungs-Spiegelung'
    ];
    final currentExercise = exercises[personalYear % 5];
    
    final spiralPosition = ((age % 28) / 28.0) * 100;
    final isInward = spiralPosition < 50;
    
    return {
      'currentPosition': isInward ? 'Deine Spirale bewegt sich nach innen' : 'Deine Spirale öffnet sich nach außen',
      'spiralProgress': spiralPosition,
      'currentExercise': currentExercise,
      'developmentAxes': [
        '🕐 Deine Zeitachse: Vergangenheit → Gegenwart → Zukunft',
        '💡 Deine Bewusstseinsachse: Unbewusst → Bewusst',
        '🧩 Deine Ganzheitsachse: Fragment → Vollständigkeit'
      ],
      'shadowZones': age < 30 
          ? ['🌱 Identitätssuche: Wer bin ich wirklich?', '🎭 Rollenwechsel: Zwischen Erwartung und Authentizität'] 
          : age < 50 
              ? ['🔄 Lebensmitte: Neuausrichtung deiner Werte', '⚖️ Balance: Zwischen Haben und Sein']
              : ['🌟 Weisheitsintegration: Deine Erfahrungen werden zu Schätzen', '🧘 Gelassenheit: Du kennst den Weg'],
      'transitionGates': _getTransitionGates(age, profile.firstName),
      'interpretation': _getInnerLandscapeInterpretation(spiralPosition, age, profile.firstName, isInward),
    };
  }

  // ========================================
  // MODUL 6: ZYKLISCHE META-EBENEN
  // ========================================
  
  static Map<String, dynamic> calculateCyclicLevels(EnergieProfile profile) {
    final age = DateTime.now().year - profile.birthDate.year;
    final personalYear = _calculatePersonalYear(profile.birthDate);
    
    final sevenYearCycle = (age % 7) + 1;
    final nineYearCycle = personalYear;
    final saturnCycle = age ~/ 28;
    
    final saturnNames = [
      '🌱 Vor dem ersten Saturn-Return: Aufbau deines Fundaments',
      '⚡ Erster Saturn-Return (28-30): Deine Lebensüberprüfung',
      '🌟 Zweiter Saturn-Return (56-60): Deine Weisheitsphase',
      '👑 Jenseits der Zyklen: Deine Meisterschaft'
    ];
    
    return {
      'shortCycles': '7-Jahres-Zyklus: Du bist in Jahr $sevenYearCycle von 7',
      'mediumCycles': '9-Jahres-Zyklus: Dein persönliches Jahr $nineYearCycle',
      'longCycles': saturnNames[saturnCycle.clamp(0, 3)],
      'saturnReturnPhase': saturnCycle,
      'cycleCongruence': (sevenYearCycle == nineYearCycle) 
          ? '✨ KRAFTVOLL: ${profile.firstName}, beide Zyklen sind synchron!' 
          : '🌊 Normal fließend',
      'timeCondensations': (nineYearCycle == 9 || sevenYearCycle == 7)
          ? ['🎯 Zyklusabschluss: Eine Phase endet', '🔄 Transformation: Bereite dich auf Neues vor']
          : [],
      'interpretation': _getCyclicInterpretation(sevenYearCycle, nineYearCycle, saturnCycle, profile.firstName, age),
    };
  }

  // ========================================
  // MODUL 7: ORIENTIERUNGS- & ENTWICKLUNGSMODELLE
  // ========================================
  
  static Map<String, dynamic> calculateOrientation(EnergieProfile profile) {
    final age = DateTime.now().year - profile.birthDate.year;
    final personalYear = _calculatePersonalYear(profile.birthDate);
    
    final level = ((age / 70.0) * 4).floor().clamp(0, 3);
    final levelNames = [
      '🎭 Opfer-Bewusstsein: "Das Leben passiert MIR"',
      '🎨 Gestalter-Bewusstsein: "Das Leben geschieht FÜR mich"',
      '🌊 Kanal-Bewusstsein: "Das Leben FLIEßT DURCH mich"',
      '🌟 Einheits-Bewusstsein: "ICH BIN das Leben"'
    ];
    
    final awakeningStage = ((age / 60.0) * 5).floor().clamp(0, 4);
    final stages = ['Durst', 'Wissen', 'Verwirrung', 'Integration', 'Erleuchtung'];
    
    return {
      'currentPhase': levelNames[level],
      'developmentLevel': level + 1,
      'awakeningStage': '${stages[awakeningStage]}-Phase deiner spirituellen Reise',
      'pastPhases': level > 0 ? levelNames.sublist(0, level) : [],
      'potentialFields': level < 3 
          ? ['💫 Nächster Schritt: ${levelNames[level + 1]}']
          : ['👑 Du hast die höchste Stufe erreicht - lebe sie!'],
      'maturityLevel': (age / 70.0 * 100).clamp(0, 100),
      'processIntensity': personalYear == 1 || personalYear == 9 ? 'Sehr intensiv 🔥' : 'Moderat ausgewogen ⚖️',
      'interpretation': _getOrientationInterpretation(level, stages[awakeningStage], profile.firstName, age),
    };
  }

  // ========================================
  // MODUL 8: META-SPIEGEL & SYSTEM-ÜBERLAGERUNG
  // ========================================
  
  static Map<String, dynamic> calculateMetaMirrors(EnergieProfile profile) {
    final personalYear = _calculatePersonalYear(profile.birthDate);
    
    return {
      'systemMirrors': [
        '🔢 Numerologie ↔ ⭐ Astrologie: Zahlen spiegeln Sterne',
        '💎 Chakren ↔ 🎭 Archetypen: Energie spiegelt Symbole',
        '🔤 Gematria ↔ 🌳 Kabbala: Buchstaben spiegeln Lebensbaum'
      ],
      'recurringThemes': [
        '🔄 Transformation erscheint in allen deinen Systemen',
        '⚖️ Balance ist dein roter Faden',
        '🌱 Wachstum zeigt sich überall'
      ],
      'contradictions': personalYear == 4 
          ? ['⚠️ Spannung: Stabilität vs. Wandel - ${profile.firstName}, finde die Synthese!']
          : [],
      'resonanceAmplifications': [
        '📢 Verstärkung: Wenn mehrere Systeme dasselbe zeigen, höre besonders gut hin!'
      ],
      'focusCondensation': 'Deine Lebenszahl und dein persönliches Jahr zeigen in die gleiche Richtung',
      'interpretation': _getMetaMirrorInterpretation(profile.firstName, personalYear),
    };
  }

  // ========================================
  // MODUL 9: WAHRNEHMUNGS- & BEDEUTUNGSMODELLE
  // ========================================
  
  static Map<String, dynamic> calculatePerception(EnergieProfile profile) {
    final age = DateTime.now().year - profile.birthDate.year;
    final personalYear = _calculatePersonalYear(profile.birthDate);
    
    final spiritualStage = age < 30 ? 'Läuterung' : age < 50 ? 'Erleuchtung' : 'Vereinigung';
    
    return {
      'perceptionFilters': age < 30 
          ? ['🎭 Ego-Filter: "Ich vs. die Welt"', '😨 Angst-Filter: "Was könnte passieren?"']
          : age < 50
              ? ['🔍 Klarheits-Filter: "Was ist wirklich wichtig?"', '💡 Weisheits-Filter: "Was habe ich gelernt?"']
              : ['🌟 Einheits-Filter: "Alles ist verbunden"'],
      'meaningPatterns': [
        '🔮 Du siehst Zeichen und Synchronizitäten',
        '🧩 Du findest Muster im scheinbaren Chaos',
        '💫 Die Welt spricht zu dir in Symbolen'
      ],
      'thinkingStyle': '$spiritualStage-Denken',
      'fixationIndicators': [],
      'flexibilityLevel': (personalYear / 9.0 * 100).clamp(40, 100),
      'interpretation': _getPerceptionInterpretation(spiritualStage, age, profile.firstName),
    };
  }

  // ========================================
  // MODUL 10: SELBSTBEOBACHTUNG & META-JOURNAL
  // ========================================
  
  static Map<String, dynamic> calculateMetaJournal(EnergieProfile profile) {
    return {
      'patternLog': '📝 Dein Muster-Tagebuch ist bereit',
      'cycleJournal': '🔄 Verfolge deine Zyklen und erkenne Wiederholungen',
      'symbolTracker': '🔮 Sammle die Symbole, die dir begegnen',
      'resonanceNotes': '💫 Notiere, was in dir nachklingt',
      'timelineComparison': '📊 Vergleiche deine Entwicklung über die Zeit',
      'interpretation': 'Liebe/r ${profile.firstName}, dein Meta-Journal wartet darauf, deine innere Reise zu dokumentieren. Jede Notiz ist ein Schatz für deine Selbsterkenntnis.',
    };
  }

  // ========================================
  // MODUL 11: SPIRIT-DATENSTEUERUNG
  // ========================================
  
  static Map<String, dynamic> calculateDataControl(EnergieProfile profile) {
    return {
      'moduleActivation': '✅ Alle 11 Module sind für dich aktiviert',
      'phaseVisibility': '👁️ Alle Phasen deiner Entwicklung sind sichtbar',
      'systemPriority': '🎯 Automatische Priorisierung nach deinen Bedürfnissen',
      'complexityReduction': '🎚️ Vereinfachter Modus: Ein/Aus nach Bedarf',
      'exportOptions': '💾 Exportiere deine Daten als JSON oder PDF',
      'interpretation': '${profile.firstName}, du hast die volle Kontrolle über deine spirituelle Daten-Architektur. Nutze sie weise!',
    };
  }

  // ========================================
  // HELPER FUNCTIONS - PERSÖNLICH & DEUTSCH
  // ========================================
  
  static int _calculatePersonalYear(DateTime birthDate) {
    final now = DateTime.now();
    final sum = birthDate.day + birthDate.month + now.year;
    return _reduceToSingleDigit(sum);
  }

  static int _reduceToSingleDigit(int number) {
    while (number > 9 && number != 11 && number != 22 && number != 33) {
      number = number.toString().split('').map(int.parse).reduce((a, b) => a + b);
    }
    return number;
  }

  static List<String> _getRepeatingPatterns(int year, int age, String name) {
    return [
      '🔄 $name, du wiederholst bestimmte Muster in Beziehungen',
      if (year == 7 || year == 8) '⚠️ Alte Gewohnheiten melden sich zurück - erkenne sie!',
      if (age % 7 == 0) '🎯 7-Jahres-Zyklus: Bekannte Muster kehren auf neuer Ebene zurück',
    ];
  }

  static List<String> _getProjectionThemes(int age, int stage, String name) {
    final themes = <String>[];
    if (stage == 1) themes.add('🎭 Phase 1: $name, erkenne was du verdrängt hast');
    if (stage == 2) themes.add('💡 Phase 2: Verstehe die Muster hinter deinen Projektionen');
    if (stage == 3) themes.add('📚 Phase 3: Lerne neue Wege mit deinem Schatten');
    if (stage == 4) themes.add('🦋 Phase 4: Integriere deinen Schatten als Kraft');
    if (age < 35) themes.add('👪 Du projizierst noch Elternthemen auf andere');
    if (age >= 35) themes.add('👔 Du projizierst Autoritätsthemen auf Personen');
    return themes;
  }

  static String _getDominantPattern(int year, String name) {
    if (year == 1) return '$name, dein Muster: "Ich muss alles alleine schaffen"';
    if (year == 2) return '$name, dein Muster: "Ich brauche Harmonie um jeden Preis"';
    if (year == 3) return '$name, dein Muster: "Ich muss immer kreativ sein"';
    if (year == 4) return '$name, dein Muster: "Ich brauche Sicherheit und Struktur"';
    if (year == 5) return '$name, dein Muster: "Ich suche ständig Veränderung"';
    if (year == 6) return '$name, dein Muster: "Ich muss für alle sorgen"';
    if (year == 7) return '$name, dein Muster: "Ich muss alles verstehen"';
    if (year == 8) return '$name, dein Muster: "Ich muss erfolgreich sein"';
    return '$name, dein Muster: "Ich muss loslassen"';
  }

  static String _getShadowInterpretation(double level, String name, int age) {
    if (level > 70) {
      return 'Liebe/r $name, mit $age Jahren hast du eine beeindruckende Schattenintegration erreicht! Du erkennst deine unbewussten Muster und nutzt sie als Wachstumskraft. Dein Schatten ist dein Verbündeter geworden.';
    } else if (level > 40) {
      return '$name, du bist mitten im Prozess der Bewusstwerdung. Mit $age Jahren wird dir immer klarer, welche Muster dich lenken. Sei geduldig mit dir - Schatten zeigen sich langsam.';
    }
    return '$name, deine Schattenreise beginnt gerade. Mit $age Jahren ist es normal, dass noch vieles unbewusst abläuft. Deine Bereitschaft zur Selbstreflexion ist der erste wichtige Schritt!';
  }

  static List<String> _getTransitionGates(int age, String name) {
    final gates = <String>[];
    if (age >= 7 && age <= 8) gates.add('🚪 $name, du bist am ersten Saturn-Tor (7-8 Jahre)');
    if (age >= 14 && age <= 15) gates.add('🚪 Zweites Saturn-Tor (14-15): Teenager-Transformation');
    if (age >= 21 && age <= 22) gates.add('🚪 Drittes Saturn-Tor (21-22): Erwachsenwerden');
    if (age >= 28 && age <= 30) gates.add('⚡ SATURN RETURN (28-30): $name, deine große Lebensüberprüfung!');
    if (age >= 42 && age <= 44) gates.add('🌊 Uranus-Opposition (42-44): Midlife-Neuausrichtung');
    if (age >= 56 && age <= 60) gates.add('👑 Zweiter Saturn Return (56-60): Weisheits-Initiation');
    return gates.isEmpty ? ['🌊 $name, du befindest dich zwischen den großen Toren - nutze die Ruhe!'] : gates;
  }

  static String _getInnerLandscapeInterpretation(double progress, int age, String name, bool isInward) {
    if (isInward) {
      return 'Liebe/r $name, mit $age Jahren bewegst du dich nach innen (${progress.toInt()}% im 28-Jahres-Zyklus). Das ist deine Zeit der Introspektion, der Heilung alter Wunden und des Findens deiner inneren Wahrheit.';
    } else {
      return '$name, du öffnest dich nach außen (${progress.toInt()}% im Zyklus). Mit $age Jahren ist es Zeit, das Gelernte in die Welt zu tragen, deine Gaben zu teilen und Verbindungen zu vertiefen.';
    }
  }

  static String _getCyclicInterpretation(int seven, int nine, int saturn, String name, int age) {
    if (seven == 7 && nine == 9) {
      return '🔥 POWER-PHASE, $name! Mit $age Jahren enden BEIDE Zyklen gleichzeitig! Dies ist ein seltener Moment maximaler Transformation. Nutze diese Energie!';
    } else if (saturn == 1 && (seven >= 6 || nine >= 8)) {
      return '⚡ $name, dein Saturn Return kombiniert sich mit einem Zyklusende - eine intensive Phase der Lebensüberprüfung erwartet dich!';
    } else if (seven == 1 && nine == 1) {
      return '🌱 Doppelter Neuanfang, $name! Beide Zyklen starten neu - säe jetzt die Samen für die nächsten 7-9 Jahre!';
    } else {
      return '$name, deine Zyklen fließen normal. Nutze Jahr $seven im 7-Jahres-Zyklus und Jahr $nine im 9-Jahres-Zyklus weise.';
    }
  }

  static String _getOrientationInterpretation(int level, String stage, String name, int age) {
    final levelDescriptions = [
      'In der Opfer-Phase lernst du, dass das Leben dir Erfahrungen bringt, um zu wachsen.',
      'Als Gestalter erkennst du: Alles geschieht FÜR dich, nicht GEGEN dich!',
      'Als Kanal lässt du das Leben durch dich fließen - du bist Instrument des Universums.',
      'In der Einheit bist du EINS mit allem - du bist das Leben selbst!'
    ];
    
    return '$name, mit $age Jahren bist du in der ${levelDescriptions[level]} Gleichzeitig durchläufst du die $stage deines spirituellen Erwachens. Jede Phase ist wertvoll - atme und vertraue!';
  }

  static String _getMetaMirrorInterpretation(String name, int year) {
    return '$name, deine verschiedenen spirituellen Systeme spiegeln einander wie Facetten eines Kristalls. Wenn Numerologie, Astrologie und Kabbala dasselbe Thema zeigen, hör besonders gut hin! In deinem persönlichen Jahr $year verstärken sich diese Spiegel.';
  }

  static String _getPerceptionInterpretation(String stage, int age, String name) {
    if (stage == 'Läuterung') {
      return '$name, mit $age Jahren bist du in der Läuterungs-Phase. Du reinigst deine Wahrnehmung von alten Prägungen. Deine Ego-Filter werden durchsichtiger.';
    } else if (stage == 'Erleuchtung') {
      return '$name, in der Erleuchtungs-Phase ($age Jahre) beginnt deine Wahrnehmung sich zu öffnen. Du siehst klarer, was wirklich wichtig ist.';
    }
    return '$name, in der Vereinigungs-Phase ($age Jahre) erkennst du: Alles ist EINS. Deine Wahrnehmung hat sich gewandelt - du siehst die Verbundenheit aller Dinge.';
  }
}
