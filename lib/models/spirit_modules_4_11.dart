/// 🌟 SPIRIT MODULES 4-11 DATA MODELS
/// Basierend auf psychologischer & spiritueller Forschung 2024-2025
library;

// ========================================
// MODUL 4: UNTERBEWUSSTSEINS- & MUSTERANALYSE
// ========================================

class SpiritUnconscious {
  final List<String> repeatingPatterns;
  final List<String> projectionThemes;
  final String jungianStage;
  final double shadowIntegrationLevel;
  final List<String> awarenessMarkers;
  final String dominantPattern;
  final String interpretation;

  SpiritUnconscious({
    required this.repeatingPatterns,
    required this.projectionThemes,
    required this.jungianStage,
    required this.shadowIntegrationLevel,
    required this.awarenessMarkers,
    required this.dominantPattern,
    required this.interpretation,
  });

  factory SpiritUnconscious.fromMap(Map<String, dynamic> map) {
    return SpiritUnconscious(
      repeatingPatterns: List<String>.from(map['repeatingPatterns'] ?? []),
      projectionThemes: List<String>.from(map['projectionThemes'] ?? []),
      jungianStage: map['jungianStage'] ?? '',
      shadowIntegrationLevel: (map['shadowIntegrationLevel'] ?? 0).toDouble(),
      awarenessMarkers: List<String>.from(map['awarenessMarkers'] ?? []),
      dominantPattern: map['dominantPattern'] ?? '',
      interpretation: map['interpretation'] ?? '',
    );
  }
}

// ========================================
// MODUL 5: INNERE LANDKARTEN & PROZESSNAVIGATION
// ========================================

class SpiritInnerLandscape {
  final String currentPosition;
  final double spiralProgress;
  final String currentExercise;
  final List<String> developmentAxes;
  final List<String> shadowZones;
  final List<String> transitionGates;
  final String interpretation;

  SpiritInnerLandscape({
    required this.currentPosition,
    required this.spiralProgress,
    required this.currentExercise,
    required this.developmentAxes,
    required this.shadowZones,
    required this.transitionGates,
    required this.interpretation,
  });

  factory SpiritInnerLandscape.fromMap(Map<String, dynamic> map) {
    return SpiritInnerLandscape(
      currentPosition: map['currentPosition'] ?? '',
      spiralProgress: (map['spiralProgress'] ?? 0).toDouble(),
      currentExercise: map['currentExercise'] ?? '',
      developmentAxes: List<String>.from(map['developmentAxes'] ?? []),
      shadowZones: List<String>.from(map['shadowZones'] ?? []),
      transitionGates: List<String>.from(map['transitionGates'] ?? []),
      interpretation: map['interpretation'] ?? '',
    );
  }
}

// ========================================
// MODUL 6: ZYKLISCHE META-EBENEN
// ========================================

class SpiritCyclicLevels {
  final String shortCycles;
  final String mediumCycles;
  final String longCycles;
  final int saturnReturnPhase;
  final String cycleCongruence;
  final List<String> timeCondensations;
  final String interpretation;

  SpiritCyclicLevels({
    required this.shortCycles,
    required this.mediumCycles,
    required this.longCycles,
    required this.saturnReturnPhase,
    required this.cycleCongruence,
    required this.timeCondensations,
    required this.interpretation,
  });

  factory SpiritCyclicLevels.fromMap(Map<String, dynamic> map) {
    return SpiritCyclicLevels(
      shortCycles: map['shortCycles'] ?? '',
      mediumCycles: map['mediumCycles'] ?? '',
      longCycles: map['longCycles'] ?? '',
      saturnReturnPhase: map['saturnReturnPhase'] ?? 0,
      cycleCongruence: map['cycleCongruence'] ?? '',
      timeCondensations: List<String>.from(map['timeCondensations'] ?? []),
      interpretation: map['interpretation'] ?? '',
    );
  }
}

// ========================================
// MODUL 7: ORIENTIERUNGS- & ENTWICKLUNGSMODELLE
// ========================================

class SpiritOrientation {
  final String currentPhase;
  final int developmentLevel;
  final String awakeningStage;
  final List<String> pastPhases;
  final List<String> potentialFields;
  final double maturityLevel;
  final String processIntensity;
  final String interpretation;

  SpiritOrientation({
    required this.currentPhase,
    required this.developmentLevel,
    required this.awakeningStage,
    required this.pastPhases,
    required this.potentialFields,
    required this.maturityLevel,
    required this.processIntensity,
    required this.interpretation,
  });

  factory SpiritOrientation.fromMap(Map<String, dynamic> map) {
    return SpiritOrientation(
      currentPhase: map['currentPhase'] ?? '',
      developmentLevel: map['developmentLevel'] ?? 1,
      awakeningStage: map['awakeningStage'] ?? '',
      pastPhases: List<String>.from(map['pastPhases'] ?? []),
      potentialFields: List<String>.from(map['potentialFields'] ?? []),
      maturityLevel: (map['maturityLevel'] ?? 0).toDouble(),
      processIntensity: map['processIntensity'] ?? '',
      interpretation: map['interpretation'] ?? '',
    );
  }
}

// ========================================
// MODUL 8: META-SPIEGEL & SYSTEM-ÜBERLAGERUNG
// ========================================

class SpiritMetaMirrors {
  final List<String> systemMirrors;
  final List<String> recurringThemes;
  final List<String> contradictions;
  final List<String> resonanceAmplifications;
  final String focusCondensation;
  final String interpretation;

  SpiritMetaMirrors({
    required this.systemMirrors,
    required this.recurringThemes,
    required this.contradictions,
    required this.resonanceAmplifications,
    required this.focusCondensation,
    required this.interpretation,
  });

  factory SpiritMetaMirrors.fromMap(Map<String, dynamic> map) {
    return SpiritMetaMirrors(
      systemMirrors: List<String>.from(map['systemMirrors'] ?? []),
      recurringThemes: List<String>.from(map['recurringThemes'] ?? []),
      contradictions: List<String>.from(map['contradictions'] ?? []),
      resonanceAmplifications: List<String>.from(map['resonanceAmplifications'] ?? []),
      focusCondensation: map['focusCondensation'] ?? '',
      interpretation: map['interpretation'] ?? '',
    );
  }
}

// ========================================
// MODUL 9: WAHRNEHMUNGS- & BEDEUTUNGSMODELLE
// ========================================

class SpiritPerception {
  final List<String> perceptionFilters;
  final List<String> meaningPatterns;
  final String thinkingStyle;
  final List<String> fixationIndicators;
  final double flexibilityLevel;
  final String interpretation;

  SpiritPerception({
    required this.perceptionFilters,
    required this.meaningPatterns,
    required this.thinkingStyle,
    required this.fixationIndicators,
    required this.flexibilityLevel,
    required this.interpretation,
  });

  factory SpiritPerception.fromMap(Map<String, dynamic> map) {
    return SpiritPerception(
      perceptionFilters: List<String>.from(map['perceptionFilters'] ?? []),
      meaningPatterns: List<String>.from(map['meaningPatterns'] ?? []),
      thinkingStyle: map['thinkingStyle'] ?? '',
      fixationIndicators: List<String>.from(map['fixationIndicators'] ?? []),
      flexibilityLevel: (map['flexibilityLevel'] ?? 0).toDouble(),
      interpretation: map['interpretation'] ?? '',
    );
  }
}

// ========================================
// MODUL 10: SELBSTBEOBACHTUNG & META-JOURNAL
// ========================================

class SpiritMetaJournal {
  final String patternLog;
  final String cycleJournal;
  final String symbolTracker;
  final String resonanceNotes;
  final String timelineComparison;
  final String interpretation;

  SpiritMetaJournal({
    required this.patternLog,
    required this.cycleJournal,
    required this.symbolTracker,
    required this.resonanceNotes,
    required this.timelineComparison,
    required this.interpretation,
  });

  factory SpiritMetaJournal.fromMap(Map<String, dynamic> map) {
    return SpiritMetaJournal(
      patternLog: map['patternLog'] ?? '',
      cycleJournal: map['cycleJournal'] ?? '',
      symbolTracker: map['symbolTracker'] ?? '',
      resonanceNotes: map['resonanceNotes'] ?? '',
      timelineComparison: map['timelineComparison'] ?? '',
      interpretation: map['interpretation'] ?? '',
    );
  }
}

// ========================================
// MODUL 11: SPIRIT-DATENSTEUERUNG
// ========================================

class SpiritDataControl {
  final String moduleActivation;
  final String phaseVisibility;
  final String systemPriority;
  final String complexityReduction;
  final String exportOptions;
  final String interpretation;

  SpiritDataControl({
    required this.moduleActivation,
    required this.phaseVisibility,
    required this.systemPriority,
    required this.complexityReduction,
    required this.exportOptions,
    required this.interpretation,
  });

  factory SpiritDataControl.fromMap(Map<String, dynamic> map) {
    return SpiritDataControl(
      moduleActivation: map['moduleActivation'] ?? '',
      phaseVisibility: map['phaseVisibility'] ?? '',
      systemPriority: map['systemPriority'] ?? '',
      complexityReduction: map['complexityReduction'] ?? '',
      exportOptions: map['exportOptions'] ?? '',
      interpretation: map['interpretation'] ?? '',
    );
  }
}
