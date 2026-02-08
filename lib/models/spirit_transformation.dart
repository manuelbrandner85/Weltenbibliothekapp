/// 🔄 SPIRIT-MODUL 3: TRANSFORMATION & SCHWELLENPHASEN
/// 
/// Analysiert Übergangsphasen, Transformationsprozesse und Schwellen im Leben.
/// 8 Hauptberechnungen erfassen verschiedene Transformations-Aspekte.
library;

class SpiritTransformation {
  // Meta-Informationen
  final String version;
  final DateTime calculatedAt;
  final String profileName;

  // 1️⃣ Übergangsphasen-Erkennung
  final TransitionPhases transitionPhases;

  // 2️⃣ Auflösungsphasen
  final DissolutionPhases dissolutionPhases;

  // 3️⃣ Neubildungsphasen
  final FormationPhases formationPhases;

  // 4️⃣ Initiationsmarker
  final InitiationMarkers initiationMarkers;

  // 5️⃣ Reifegrad-Phasen
  final MaturityPhases maturityPhases;

  // 6️⃣ Verdichtungsstufen
  final DensificationLevels densificationLevels;

  // 7️⃣ Rückfall- & Wiederholungsphasen
  final RelapsePatterns relapsePatterns;

  // 8️⃣ Integrationsfenster
  final IntegrationWindows integrationWindows;

  SpiritTransformation({
    required this.version,
    required this.calculatedAt,
    required this.profileName,
    required this.transitionPhases,
    required this.dissolutionPhases,
    required this.formationPhases,
    required this.initiationMarkers,
    required this.maturityPhases,
    required this.densificationLevels,
    required this.relapsePatterns,
    required this.integrationWindows,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'calculatedAt': calculatedAt.toIso8601String(),
        'profileName': profileName,
        'transitionPhases': transitionPhases.toJson(),
        'dissolutionPhases': dissolutionPhases.toJson(),
        'formationPhases': formationPhases.toJson(),
        'initiationMarkers': initiationMarkers.toJson(),
        'maturityPhases': maturityPhases.toJson(),
        'densificationLevels': densificationLevels.toJson(),
        'relapsePatterns': relapsePatterns.toJson(),
        'integrationWindows': integrationWindows.toJson(),
      };
}

// ========================================
// 1️⃣ ÜBERGANGSPHASEN-ERKENNUNG
// ========================================

class TransitionPhases {
  final String currentPhase; // "Vorbereitung" | "Schwelle" | "Integration"
  final double phaseIntensity; // 0-100
  final int daysInPhase; // Wie lange schon in dieser Phase?
  final int estimatedDaysRemaining; // Geschätzte Restdauer
  final List<String> phaseCharacteristics; // Merkmale dieser Phase
  final String nextPhase; // Was kommt als nächstes?
  final String interpretation;

  TransitionPhases({
    required this.currentPhase,
    required this.phaseIntensity,
    required this.daysInPhase,
    required this.estimatedDaysRemaining,
    required this.phaseCharacteristics,
    required this.nextPhase,
    required this.interpretation,
  });

  Map<String, dynamic> toJson() => {
        'currentPhase': currentPhase,
        'phaseIntensity': phaseIntensity,
        'daysInPhase': daysInPhase,
        'estimatedDaysRemaining': estimatedDaysRemaining,
        'phaseCharacteristics': phaseCharacteristics,
        'nextPhase': nextPhase,
        'interpretation': interpretation,
      };
}

// ========================================
// 2️⃣ AUFLÖSUNGSPHASEN
// ========================================

class DissolutionPhases {
  final bool isInDissolution; // Bist du gerade in Auflösung?
  final double dissolutionIntensity; // 0-100
  final List<String> dissolvingPatterns; // Was löst sich auf?
  final String dissolutionType; // "Sanft" | "Radikal" | "Schleichend"
  final List<String> resistancePoints; // Wo lehnst du dich dagegen auf?
  final String guidanceForRelease; // Anleitung zum Loslassen
  final String interpretation;

  DissolutionPhases({
    required this.isInDissolution,
    required this.dissolutionIntensity,
    required this.dissolvingPatterns,
    required this.dissolutionType,
    required this.resistancePoints,
    required this.guidanceForRelease,
    required this.interpretation,
  });

  Map<String, dynamic> toJson() => {
        'isInDissolution': isInDissolution,
        'dissolutionIntensity': dissolutionIntensity,
        'dissolvingPatterns': dissolvingPatterns,
        'dissolutionType': dissolutionType,
        'resistancePoints': resistancePoints,
        'guidanceForRelease': guidanceForRelease,
        'interpretation': interpretation,
      };
}

// ========================================
// 3️⃣ NEUBILDUNGSPHASEN
// ========================================

class FormationPhases {
  final bool isInFormation; // Bist du in Neubildung?
  final double formationIntensity; // 0-100
  final List<String> emergingPatterns; // Was entsteht neu?
  final String formationType; // "Organisch" | "Geplant" | "Spontan"
  final double readinessLevel; // Wie bereit bist du? 0-100
  final List<String> supportingFactors; // Was unterstützt die Neubildung?
  final String interpretation;

  FormationPhases({
    required this.isInFormation,
    required this.formationIntensity,
    required this.emergingPatterns,
    required this.formationType,
    required this.readinessLevel,
    required this.supportingFactors,
    required this.interpretation,
  });

  Map<String, dynamic> toJson() => {
        'isInFormation': isInFormation,
        'formationIntensity': formationIntensity,
        'emergingPatterns': emergingPatterns,
        'formationType': formationType,
        'readinessLevel': readinessLevel,
        'supportingFactors': supportingFactors,
        'interpretation': interpretation,
      };
}

// ========================================
// 4️⃣ INITIATIONSMARKER
// ========================================

class InitiationMarkers {
  final List<InitiationEvent> pastInitiations; // Vergangene Initiationen
  final InitiationEvent? currentInitiation; // Aktuelle Initiation
  final List<InitiationEvent> upcomingInitiations; // Kommende Initiationen
  final double initiationReadiness; // Bereitschaft 0-100
  final String interpretation;

  InitiationMarkers({
    required this.pastInitiations,
    this.currentInitiation,
    required this.upcomingInitiations,
    required this.initiationReadiness,
    required this.interpretation,
  });

  Map<String, dynamic> toJson() => {
        'pastInitiations': pastInitiations.map((i) => i.toJson()).toList(),
        'currentInitiation': currentInitiation?.toJson(),
        'upcomingInitiations':
            upcomingInitiations.map((i) => i.toJson()).toList(),
        'initiationReadiness': initiationReadiness,
        'interpretation': interpretation,
      };
}

class InitiationEvent {
  final String name;
  final String ageRange; // z.B. "28-30 Jahre"
  final String description;
  final bool isPassed; // Schon durchlaufen?

  InitiationEvent({
    required this.name,
    required this.ageRange,
    required this.description,
    required this.isPassed,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'ageRange': ageRange,
        'description': description,
        'isPassed': isPassed,
      };
}

// ========================================
// 5️⃣ REIFEGRAD-PHASEN
// ========================================

class MaturityPhases {
  final String currentMaturityLevel; // "Unreif" | "Reifend" | "Reif" | "Überreif"
  final double maturityScore; // 0-100
  final List<String> maturityIndicators; // Zeichen der Reife
  final List<String> immaturityIndicators; // Zeichen der Unreife
  final String maturityPath; // Weg zur nächsten Stufe
  final String interpretation;

  MaturityPhases({
    required this.currentMaturityLevel,
    required this.maturityScore,
    required this.maturityIndicators,
    required this.immaturityIndicators,
    required this.maturityPath,
    required this.interpretation,
  });

  Map<String, dynamic> toJson() => {
        'currentMaturityLevel': currentMaturityLevel,
        'maturityScore': maturityScore,
        'maturityIndicators': maturityIndicators,
        'immaturityIndicators': immaturityIndicators,
        'maturityPath': maturityPath,
        'interpretation': interpretation,
      };
}

// ========================================
// 6️⃣ VERDICHTUNGSSTUFEN
// ========================================

class DensificationLevels {
  final double currentDensity; // 0-100 (0=ätherisch, 100=maximal verdichtet)
  final String densityTrend; // "Verdichtend" | "Auflösend" | "Stabil"
  final List<String> densityAreas; // Wo ist Verdichtung am stärksten?
  final String healthyDensityRange; // Empfohlener Bereich
  final String adjustmentGuidance; // Wie anpassen?
  final String interpretation;

  DensificationLevels({
    required this.currentDensity,
    required this.densityTrend,
    required this.densityAreas,
    required this.healthyDensityRange,
    required this.adjustmentGuidance,
    required this.interpretation,
  });

  Map<String, dynamic> toJson() => {
        'currentDensity': currentDensity,
        'densityTrend': densityTrend,
        'densityAreas': densityAreas,
        'healthyDensityRange': healthyDensityRange,
        'adjustmentGuidance': adjustmentGuidance,
        'interpretation': interpretation,
      };
}

// ========================================
// 7️⃣ RÜCKFALL- & WIEDERHOLUNGSPHASEN
// ========================================

class RelapsePatterns {
  final List<RelapsePattern> detectedPatterns; // Gefundene Muster
  final double relapseRisk; // Rückfallrisiko 0-100
  final String mostCommonRelapse; // Häufigstes Rückfallmuster
  final List<String> triggers; // Was löst Rückfälle aus?
  final List<String> preventionStrategies; // Wie verhindern?
  final String interpretation;

  RelapsePatterns({
    required this.detectedPatterns,
    required this.relapseRisk,
    required this.mostCommonRelapse,
    required this.triggers,
    required this.preventionStrategies,
    required this.interpretation,
  });

  Map<String, dynamic> toJson() => {
        'detectedPatterns': detectedPatterns.map((p) => p.toJson()).toList(),
        'relapseRisk': relapseRisk,
        'mostCommonRelapse': mostCommonRelapse,
        'triggers': triggers,
        'preventionStrategies': preventionStrategies,
        'interpretation': interpretation,
      };
}

class RelapsePattern {
  final String name;
  final int frequency; // Wie oft wiederholt?
  final String lastOccurrence; // Wann zuletzt?
  final double intensity; // Wie stark? 0-100

  RelapsePattern({
    required this.name,
    required this.frequency,
    required this.lastOccurrence,
    required this.intensity,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'frequency': frequency,
        'lastOccurrence': lastOccurrence,
        'intensity': intensity,
      };
}

// ========================================
// 8️⃣ INTEGRATIONSFENSTER
// ========================================

class IntegrationWindows {
  final bool isWindowOpen; // Ist jetzt ein Integrationsfenster offen?
  final double windowDuration; // Wie lange noch offen? (Tage)
  final List<String> whatToIntegrate; // Was sollte integriert werden?
  final double integrationProgress; // Fortschritt 0-100
  final String nextWindowOpening; // Wann öffnet sich das nächste?
  final List<String> integrationPractices; // Empfohlene Praktiken
  final String interpretation;

  IntegrationWindows({
    required this.isWindowOpen,
    required this.windowDuration,
    required this.whatToIntegrate,
    required this.integrationProgress,
    required this.nextWindowOpening,
    required this.integrationPractices,
    required this.interpretation,
  });

  Map<String, dynamic> toJson() => {
        'isWindowOpen': isWindowOpen,
        'windowDuration': windowDuration,
        'whatToIntegrate': whatToIntegrate,
        'integrationProgress': integrationProgress,
        'nextWindowOpening': nextWindowOpening,
        'integrationPractices': integrationPractices,
        'interpretation': interpretation,
      };
}
