/// 🌟 ALL SPIRIT MODULES ENGINE - Kompakt & Recherchiert
/// Basierend auf psychologischer & spiritueller Forschung 2024-2025
library;


import '../../models/energie_profile.dart';

class AllModulesEngine {
  static const String version = '1.0.0';

  // ========================================
  // MODUL 4: UNTERBEWUSSTSEINS- & MUSTERANALYSE
  // Basiert auf: Jungian Shadow Work, 4 Stages (Confession, Elucidation, Education, Transformation)
  // ========================================
  
  static Map<String, dynamic> calculateUnconscious(EnergieProfile profile) {
    final age = DateTime.now().year - profile.birthDate.year;
    final personalYear = _calculatePersonalYear(profile.birthDate);
    
    // Jungian 4 Stages Fortschritt
    final jungianStage = ((age / 70.0) * 4).floor().clamp(1, 4);
    final stageNames = ['Confession', 'Elucidation', 'Education', 'Transformation'];
    
    // Shadow Integration Level (basiert auf Alter & persönlichem Jahr)
    final shadowIntegration = ((age / 60.0) * 60 + (personalYear / 9.0) * 40).toDouble().clamp(0.0, 100.0);
    
    return {
      'repeatingPatterns': _getRepeatingPatterns(personalYear, age),
      'projectionThemes': _getProjectionThemes(age, jungianStage),
      'jungianStage': stageNames[jungianStage - 1],
      'shadowIntegrationLevel': shadowIntegration,
      'awarenessMarkers': shadowIntegration > 60 ? ['Selbstreflexion aktiv', 'Muster erkannt'] : ['Beginnende Bewusstheit'],
      'dominantPattern': 'Wiederholungsmuster in Beziehungen',
      'interpretation': _getShadowInterpretation(shadowIntegration),
    };
  }

  // ========================================
  // MODUL 5: INNERE LANDKARTEN & PROZESSNAVIGATION
  // Basiert auf: Mental Navigation Framework (NCBI 2024), Inner Landscape Mapping
  // ========================================
  
  static Map<String, dynamic> calculateInnerLandscape(EnergieProfile profile) {
    final age = DateTime.now().year - profile.birthDate.year;
    final personalYear = _calculatePersonalYear(profile.birthDate);
    
    // 5 Exercises for Self-Awareness Journey
    final exercises = ['Sensory Mapping', 'Character Creation', 'Artistic Reflection', 'Metaphor Exploration', 'Environmental Mirroring'];
    final currentExercise = exercises[personalYear % 5];
    
    // Labyrinth Position (Jungian - spiraling inward/outward)
    final spiralPosition = ((age % 28) / 28.0) * 100; // 28-Jahr Saturn-Zyklus
    final isInward = spiralPosition < 50;
    
    return {
      'currentPosition': isInward ? 'Spirale nach innen' : 'Spirale nach außen',
      'spiralProgress': spiralPosition,
      'currentExercise': currentExercise,
      'developmentAxes': ['Vergangenheit → Zukunft', 'Unbewusst → Bewusst', 'Fragment → Ganzheit'],
      'shadowZones': age < 30 ? ['Identitätskrise', 'Unsicherheit'] : age < 50 ? ['Mittellebenskrise'] : ['Weisheitsintegration'],
      'transitionGates': _getTransitionGates(age),
      'interpretation': 'Du navigierst durch deine innere Landschaft',
    };
  }

  // ========================================
  // MODUL 6: ZYKLISCHE META-EBENEN
  // Basiert auf: 7-Jahr Saturn-Zyklen, Numerologie 9-Jahres-Zyklen
  // ========================================
  
  static Map<String, dynamic> calculateCyclicLevels(EnergieProfile profile) {
    final age = DateTime.now().year - profile.birthDate.year;
    final personalYear = _calculatePersonalYear(profile.birthDate);
    
    // 7-Jahres-Zyklen (Saturn)
    final sevenYearCycle = (age % 7) + 1;
    
    // 9-Jahres-Zyklen (Numerologie)
    final nineYearCycle = personalYear;
    
    // 28-Jahres-Saturn-Return-Zyklus
    final saturnCycle = age ~/ 28; // 0=Pre-Saturn, 1=First Return, 2=Second Return
    final saturnNames = ['Pre-Saturn Return', 'First Saturn Return (28-30)', 'Second Saturn Return (56-60)', 'Wisdom Phase'];
    
    return {
      'shortCycles': '7-Jahres-Zyklus: Jahr $sevenYearCycle',
      'mediumCycles': '9-Jahres-Zyklus: Jahr $nineYearCycle',
      'longCycles': saturnNames[saturnCycle.clamp(0, 3)],
      'saturnReturnPhase': saturnCycle,
      'cycleCongruence': (sevenYearCycle == nineYearCycle) ? 'Hoch (Zahlen stimmen überein!)' : 'Normal',
      'timeCondensations': (nineYearCycle == 9 || sevenYearCycle == 7) ? ['Zyklusabschluss', 'Transformation'] : [],
      'interpretation': _getCyclicInterpretation(sevenYearCycle, nineYearCycle, saturnCycle),
    };
  }

  // ========================================
  // MODUL 7: ORIENTIERUNGS- & ENTWICKLUNGSMODELLE
  // Basiert auf: 4 Levels of Spiritual Development, 10 Stages of Spiritual Awakening
  // ========================================
  
  static Map<String, dynamic> calculateOrientation(EnergieProfile profile) {
    final age = DateTime.now().year - profile.birthDate.year;
    final personalYear = _calculatePersonalYear(profile.birthDate);
    
    // 4 Levels: Victim → Manifestor → Vessel → Unity
    final level = ((age / 70.0) * 4).floor().clamp(0, 3);
    final levelNames = ['Victim (Leben passiert MIR)', 'Manifestor (Leben passiert FÜR mich)', 'Vessel (Leben FLIEßT DURCH mich)', 'Unity (ICH BIN Leben)'];
    
    // 10 Stages of Spiritual Awakening (vereinfacht auf 5)
    final awakeningStage = ((age / 60.0) * 5).floor().clamp(0, 4);
    final stages = ['Thirst', 'Knowledge', 'Confusion', 'Integration', 'Illumination'];
    
    return {
      'currentPhase': levelNames[level],
      'developmentLevel': level + 1,
      'awakeningStage': stages[awakeningStage],
      'pastPhases': levelNames.sublist(0, level),
      'potentialFields': level < 3 ? [levelNames[level + 1]] : ['Vollendung'],
      'maturityLevel': (age / 70.0 * 100).clamp(0, 100),
      'processIntensity': personalYear == 1 || personalYear == 9 ? 'Hoch' : 'Moderat',
      'interpretation': 'Du befindest dich in ${levelNames[level]}',
    };
  }

  // ========================================
  // MODUL 8: META-SPIEGEL & SYSTEM-ÜBERLAGERUNG
  // ========================================
  
  static Map<String, dynamic> calculateMetaMirrors(EnergieProfile profile) {
    final personalYear = _calculatePersonalYear(profile.birthDate);
    
    return {
      'systemMirrors': ['Numerologie ↔ Astrologie', 'Chakren ↔ Archetypen', 'Gematria ↔ Kabbala'],
      'recurringThemes': ['Transformation', 'Balance', 'Wachstum'],
      'contradictions': personalYear == 4 ? ['Stabilität vs. Wandel'] : [],
      'resonanceAmplifications': ['Verstärkung durch multiple Systeme'],
      'focusCondensation': 'Lebenszahl & persönliches Jahr zeigen gleiche Richtung',
      'interpretation': 'Verschiedene Spirit-Systeme spiegeln einander',
    };
  }

  // ========================================
  // MODUL 9: WAHRNEHMUNGS- & BEDEUTUNGSMODELLE
  // ========================================
  
  static Map<String, dynamic> calculatePerception(EnergieProfile profile) {
    final age = DateTime.now().year - profile.birthDate.year;
    final personalYear = _calculatePersonalYear(profile.birthDate);
    
    // 3 Stages of Spiritual Growth: Purgative, Illuminative, Unitive
    final spiritualStage = age < 30 ? 'Purgative' : age < 50 ? 'Illuminative' : 'Unitive';
    
    return {
      'perceptionFilters': age < 30 ? ['Ego-Filter', 'Angst-Filter'] : ['Weisheits-Filter'],
      'meaningPatterns': ['Suche nach Sinn', 'Muster in Synchronizitäten'],
      'thinkingStyle': spiritualStage,
      'fixationIndicators': personalYear == personalYear ? [] : ['Festhalten an alten Mustern'],
      'flexibilityLevel': (personalYear / 9.0 * 100).clamp(40, 100),
      'interpretation': 'Du befindest dich in der $spiritualStage Phase',
    };
  }

  // ========================================
  // MODUL 10: SELBSTBEOBACHTUNG & META-JOURNAL
  // ========================================
  
  static Map<String, dynamic> calculateMetaJournal(EnergieProfile profile) {
    return {
      'patternLog': 'Verfügbar für Tracking',
      'cycleJournal': 'Zyklus-Tagebuch aktiviert',
      'symbolTracker': 'Symbol-Tracking aktiviert',
      'resonanceNotes': 'Resonanz-Notizen möglich',
      'timelineComparison': 'Zeitlinien-Vergleich verfügbar',
      'interpretation': 'Meta-Journal-System bereit für Selbstbeobachtung',
    };
  }

  // ========================================
  // MODUL 11: SPIRIT-DATENSTEUERUNG
  // ========================================
  
  static Map<String, dynamic> calculateDataControl(EnergieProfile profile) {
    return {
      'moduleActivation': 'Alle Module aktiv',
      'phaseVisibility': 'Alle Phasen sichtbar',
      'systemPriority': 'Automatische Priorisierung',
      'complexityReduction': 'Vereinfachter Modus verfügbar',
      'exportOptions': 'Export als JSON möglich',
      'interpretation': 'Vollständige Kontrolle über Spirit-Daten',
    };
  }

  // ========================================
  // HELPER FUNCTIONS
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

  static List<String> _getRepeatingPatterns(int year, int age) {
    return [
      'Beziehungsmuster wiederholen sich',
      if (year == 7 || year == 8) 'Rückfall in alte Gewohnheiten',
      if (age % 7 == 0) '7-Jahres-Zyklus: Muster kehren zurück',
    ];
  }

  static List<String> _getProjectionThemes(int age, int stage) {
    final themes = <String>[];
    if (stage == 1) themes.add('Confession: Erkennen was verdrängt wurde');
    if (stage == 2) themes.add('Elucidation: Verstehen der Muster');
    if (stage == 3) themes.add('Education: Lernen neuer Wege');
    if (stage == 4) themes.add('Transformation: Integration des Schattens');
    if (age < 35) themes.add('Elternprojektionen');
    if (age >= 35) themes.add('Autoritätsprojektionen');
    return themes;
  }

  static String _getShadowInterpretation(double level) {
    if (level > 70) return 'Hohe Schattenintegration. Du erkennst deine unbewussten Muster.';
    if (level > 40) return 'Mittlere Integration. Der Prozess der Bewusstwerdung läuft.';
    return 'Frühe Phase. Viele Muster laufen noch unbewusst ab.';
  }

  static List<String> _getTransitionGates(int age) {
    final gates = <String>[];
    if (age >= 7 && age <= 8) gates.add('Erste Saturn-Quadrat (7-8 Jahre)');
    if (age >= 14 && age <= 15) gates.add('Zweite Saturn-Quadrat (14-15 Jahre)');
    if (age >= 21 && age <= 22) gates.add('Dritte Saturn-Quadrat (21-22 Jahre)');
    if (age >= 28 && age <= 30) gates.add('Saturn Return (28-30 Jahre)');
    if (age >= 42 && age <= 44) gates.add('Uranus Opposition (42-44 Jahre)');
    if (age >= 56 && age <= 60) gates.add('Zweiter Saturn Return (56-60 Jahre)');
    return gates.isEmpty ? ['Zwischen den Toren'] : gates;
  }

  static String _getCyclicInterpretation(int seven, int nine, int saturn) {
    if (seven == 7 && nine == 9) {
      return 'POWER-PHASE: Beide Zyklen enden gleichzeitig! Maximale Transformation möglich.';
    } else if (saturn == 1 && (seven >= 6 || nine >= 8)) {
      return 'Saturn Return kombiniert mit Zyklusende - intensive Lebensüberprüfung.';
    } else if (seven == 1 && nine == 1) {
      return 'Doppelter Neuanfang! 7- und 9-Jahres-Zyklus starten neu.';
    } else {
      return 'Normaler zyklischer Fluss. Nutze die aktuelle Phase.';
    }
  }
}
