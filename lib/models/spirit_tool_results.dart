/// Spirit-Tool Ergebnismodelle
/// Version: 1.0.0
/// 10 neue Tools basierend auf Spirit-Profil-Daten
library;

// TOOL 1: ENERGIEFELD-ANALYSE
class EnergyFieldToolResult {
  final String version;
  final DateTime calculatedAt;
  final String profileName;
  
  // Rohwerte
  final double overallFieldStrength; // 0-100%
  final String fieldQuality; // Stabil, Dynamisch, Schwankend
  final List<FrequencyBand> frequencyBands;
  final double coherence; // 0-100%
  final List<String> resonantPoints;
  
  // Einordnung
  final String stabilityLevel; // Sehr stabil, Ausgeglichen, Instabil
  final String energyFlow; // Fließend, Blockiert, Überaktiv
  final List<String> activeZones;
  
  // Meta-Hinweis
  final String interpretation;

  EnergyFieldToolResult({
    required this.version,
    required this.calculatedAt,
    required this.profileName,
    required this.overallFieldStrength,
    required this.fieldQuality,
    required this.frequencyBands,
    required this.coherence,
    required this.resonantPoints,
    required this.stabilityLevel,
    required this.energyFlow,
    required this.activeZones,
    required this.interpretation,
  });
}

class FrequencyBand {
  final String name; // Alpha, Beta, Gamma, Delta, Theta
  final double strength; // 0-100%
  final String quality; // Aktiv, Ruhend, Überaktiv

  FrequencyBand({
    required this.name,
    required this.strength,
    required this.quality,
  });
}

// TOOL 2: POLARITÄTS-ANALYSE
class PolarityToolResult {
  final String version;
  final DateTime calculatedAt;
  final String profileName;
  
  // Rohwerte
  final double yinScore; // 0-100%
  final double yangScore; // 0-100%
  final List<PolarityAxis> axes;
  final double balanceRatio; // 0-1 (0=unbalanced, 1=perfect)
  
  // Einordnung
  final String dominantPole; // Yin, Yang, Ausgeglichen
  final String balanceState; // Harmonisch, Übersteuerung, Defizit
  final List<String> tensionPoints;
  
  // Meta-Hinweis
  final String interpretation;

  PolarityToolResult({
    required this.version,
    required this.calculatedAt,
    required this.profileName,
    required this.yinScore,
    required this.yangScore,
    required this.axes,
    required this.balanceRatio,
    required this.dominantPole,
    required this.balanceState,
    required this.tensionPoints,
    required this.interpretation,
  });
}

class PolarityAxis {
  final String name; // Aktiv-Passiv, Ordnung-Chaos, Kontrolle-Hingabe, Expansion-Rückzug
  final double leftValue; // 0-100%
  final double rightValue; // 0-100%
  final String state; // Links-dominant, Rechts-dominant, Ausgeglichen

  PolarityAxis({
    required this.name,
    required this.leftValue,
    required this.rightValue,
    required this.state,
  });
}

// TOOL 3: TRANSFORMATIONS-ANALYSE
class TransformationToolResult {
  final String version;
  final DateTime calculatedAt;
  final String profileName;
  
  // Rohwerte
  final int currentStage; // 1-7 (Awakening → Illumination → Unity)
  final String stageName;
  final double stageProgress; // 0-100%
  final List<String> transitionMarkers;
  
  // Einordnung
  final String maturityLevel; // Beginnend, Entwickelnd, Gereift
  final String processIntensity; // Ruhig, Aktiv, Intensiv
  final List<String> recurrentThemes;
  
  // Meta-Hinweis
  final String interpretation;

  TransformationToolResult({
    required this.version,
    required this.calculatedAt,
    required this.profileName,
    required this.currentStage,
    required this.stageName,
    required this.stageProgress,
    required this.transitionMarkers,
    required this.maturityLevel,
    required this.processIntensity,
    required this.recurrentThemes,
    required this.interpretation,
  });
}

// TOOL 4: UNTERBEWUSSTSEINS-ANALYSE
class UnconsciousToolResult {
  final String version;
  final DateTime calculatedAt;
  final String profileName;
  
  // Rohwerte
  final int shadowStage; // 1-4 (Confession → Transformation)
  final String stageName;
  final double integrationLevel; // 0-100%
  final List<String> repeatingPatterns;
  final List<String> projectionThemes;
  
  // Einordnung
  final String awarenessLevel; // Unbewusst, Dämmert, Bewusst
  final List<String> resistancePoints;
  final List<String> integrationOpportunities;
  
  // Meta-Hinweis
  final String interpretation;

  UnconsciousToolResult({
    required this.version,
    required this.calculatedAt,
    required this.profileName,
    required this.shadowStage,
    required this.stageName,
    required this.integrationLevel,
    required this.repeatingPatterns,
    required this.projectionThemes,
    required this.awarenessLevel,
    required this.resistancePoints,
    required this.integrationOpportunities,
    required this.interpretation,
  });
}

// TOOL 5: INNERE-KARTEN-ANALYSE
class InnerMapsToolResult {
  final String version;
  final DateTime calculatedAt;
  final String profileName;
  
  // Rohwerte
  final double spiralPosition; // 0-100% (28-Jahr-Zyklus)
  final String currentExercise; // Eine von 5 Mapping-Übungen
  final List<String> developmentAxes;
  final List<String> transitionZones;
  
  // Einordnung
  final String navigationState; // Explorierend, Vertiefend, Integrierend
  final List<String> stillnessAreas;
  final List<String> movementAreas;
  
  // Meta-Hinweis
  final String interpretation;

  InnerMapsToolResult({
    required this.version,
    required this.calculatedAt,
    required this.profileName,
    required this.spiralPosition,
    required this.currentExercise,
    required this.developmentAxes,
    required this.transitionZones,
    required this.navigationState,
    required this.stillnessAreas,
    required this.movementAreas,
    required this.interpretation,
  });
}

// TOOL 6: ZYKLUS-ANALYSE
class CyclesToolResult {
  final String version;
  final DateTime calculatedAt;
  final String profileName;
  
  // Rohwerte
  final int cycle7Year; // 1-7
  final String saturnPhase; // Pre-Return, First Return, Second Return
  final int personalYear; // 1-9 (Numerologie)
  final double cycleAlignment; // 0-100%
  
  // Einordnung
  final String timeQuality; // Aufbauend, Kulminierend, Auflösend
  final List<String> overlappingCycles;
  final String rhythmState; // Harmonisch, Dissonant, Neutral
  
  // Meta-Hinweis
  final String interpretation;

  CyclesToolResult({
    required this.version,
    required this.calculatedAt,
    required this.profileName,
    required this.cycle7Year,
    required this.saturnPhase,
    required this.personalYear,
    required this.cycleAlignment,
    required this.timeQuality,
    required this.overlappingCycles,
    required this.rhythmState,
    required this.interpretation,
  });
}

// TOOL 7: ORIENTIERUNGS-ANALYSE
class OrientationToolResult {
  final String version;
  final DateTime calculatedAt;
  final String profileName;
  
  // Rohwerte
  final int developmentLevel; // 1-8 (Spiral Dynamics)
  final String levelName;
  final double levelProgress; // 0-100%
  final List<String> pastLevels;
  
  // Einordnung
  final String stabilityState; // Stabil, Übergang, Instabil
  final String processIntensity; // Ruhig, Moderat, Intensiv
  final List<String> umbruchMarkers;
  
  // Meta-Hinweis
  final String interpretation;

  OrientationToolResult({
    required this.version,
    required this.calculatedAt,
    required this.profileName,
    required this.developmentLevel,
    required this.levelName,
    required this.levelProgress,
    required this.pastLevels,
    required this.stabilityState,
    required this.processIntensity,
    required this.umbruchMarkers,
    required this.interpretation,
  });
}

// TOOL 8: META-SPIEGEL-ANALYSE
class MetaMirrorToolResult {
  final String version;
  final DateTime calculatedAt;
  final String profileName;
  
  // Rohwerte
  final List<String> systemMirrors;
  final List<String> themeOverlays;
  final List<String> contradictions;
  final double resonanceStrength; // 0-100%
  
  // Einordnung
  final String focusIndicator; // Diffus, Klar, Konzentriert
  final List<String> amplifiedThemes;
  final String mirrorQuality; // Klar, Verzerrt, Mehrdeutig
  
  // Meta-Hinweis
  final String interpretation;

  MetaMirrorToolResult({
    required this.version,
    required this.calculatedAt,
    required this.profileName,
    required this.systemMirrors,
    required this.themeOverlays,
    required this.contradictions,
    required this.resonanceStrength,
    required this.focusIndicator,
    required this.amplifiedThemes,
    required this.mirrorQuality,
    required this.interpretation,
  });
}

// TOOL 9: WAHRNEHMUNGS-ANALYSE
class PerceptionToolResult {
  final String version;
  final DateTime calculatedAt;
  final String profileName;
  
  // Rohwerte
  final int perceptionStage; // 1-3 (Purgative, Illuminative, Unitive)
  final String stageName;
  final List<String> activeFilters;
  final List<String> interpretationPatterns;
  
  // Einordnung
  final double flexibilityDegree; // 0-100%
  final List<String> fixationPoints;
  final String perspectiveRange; // Eng, Mittel, Weit
  
  // Meta-Hinweis
  final String interpretation;

  PerceptionToolResult({
    required this.version,
    required this.calculatedAt,
    required this.profileName,
    required this.perceptionStage,
    required this.stageName,
    required this.activeFilters,
    required this.interpretationPatterns,
    required this.flexibilityDegree,
    required this.fixationPoints,
    required this.perspectiveRange,
    required this.interpretation,
  });
}

// TOOL 10: SELBSTBEOBACHTUNGS-ANALYSE
class SelfObservationToolResult {
  final String version;
  final DateTime calculatedAt;
  final String profileName;
  
  // Rohwerte
  final List<String> patternLog;
  final List<String> cycleNotes;
  final List<String> symbolTracker;
  final int totalEntries;
  
  // Einordnung
  final String observationQuality; // Oberflächlich, Differenziert, Tiefgehend
  final double metacognitiveLevel; // 0-100%
  final List<String> trackingFocus;
  
  // Meta-Hinweis
  final String interpretation;

  SelfObservationToolResult({
    required this.version,
    required this.calculatedAt,
    required this.profileName,
    required this.patternLog,
    required this.cycleNotes,
    required this.symbolTracker,
    required this.totalEntries,
    required this.observationQuality,
    required this.metacognitiveLevel,
    required this.trackingFocus,
    required this.interpretation,
  });
}
