/// 🌟 ENERGETISCHE FELDANALYSE - DATENMODELL
/// 
/// Repräsentiert das persönliche Energiefeld basierend auf:
/// - Geburtsdaten (Name, Datum, Ort, Zeit)
/// - Numerologische Berechnungen
/// - Zeitliche Zyklen
/// 
/// ALLE Berechnungen sind symbolisch und modellhaft.
library;

class SpiritEnergyField {
  // === GESAMT-ENERGIEFELD ===
  final double overallFieldStrength; // 0.0 - 1.0 (Gesamtstärke)
  final String fieldQuality; // 'Stabil', 'Dynamisch', 'Turbulent', etc.
  final String fieldColor; // Symbolische Farbe
  
  // === DOMINANTE ENERGIEFREQUENZEN ===
  final List<EnergyFrequency> dominantFrequencies; // Top 3-5 Frequenzen
  final EnergyFrequency primaryFrequency; // Stärkste Frequenz
  
  // === SCHWACHE / INSTABILE FELDER ===
  final List<EnergyFrequency> weakFields; // Unterentwickelte Bereiche
  final List<String> instabilityZones; // Bereiche mit Schwankungen
  
  // === ÜBERLAGERTE ENERGIEN ===
  final List<EnergyOverlay> overlays; // Mehrschichtige Energien
  final int overlayComplexity; // Anzahl Überlagerungen
  
  // === FELDKOHÄRENZ ===
  final double coherenceLevel; // 0.0 - 1.0 (Stabilität)
  final String coherenceState; // 'Hoch kohärent', 'Chaotisch', etc.
  final double chaosIndex; // 0.0 - 1.0 (Unordnung)
  
  // === ENERGIEFLUSS-ACHSEN ===
  final List<EnergyAxis> flowAxes; // Hauptflussrichtungen
  final String flowPattern; // 'Zirkulär', 'Linear', 'Spiralförmig', etc.
  
  // === RESONANZDICHTE ===
  final double resonanceDensity; // 0.0 - 1.0
  final List<String> resonancePoints; // Resonanz-Hotspots
  
  // === LANGZEIT-FELDVERÄNDERUNG ===
  final FieldEvolution evolution; // Historische Entwicklung
  final String currentPhase; // Aktuelle Entwicklungsphase
  final String nextPhase; // Potenzielle nächste Phase
  
  // === META-DATEN ===
  final DateTime calculatedAt;
  final String version; // Berechnungsversion

  SpiritEnergyField({
    required this.overallFieldStrength,
    required this.fieldQuality,
    required this.fieldColor,
    required this.dominantFrequencies,
    required this.primaryFrequency,
    required this.weakFields,
    required this.instabilityZones,
    required this.overlays,
    required this.overlayComplexity,
    required this.coherenceLevel,
    required this.coherenceState,
    required this.chaosIndex,
    required this.flowAxes,
    required this.flowPattern,
    required this.resonanceDensity,
    required this.resonancePoints,
    required this.evolution,
    required this.currentPhase,
    required this.nextPhase,
    required this.calculatedAt,
    this.version = '1.0.0',
  });

  Map<String, dynamic> toJson() => {
    'overallFieldStrength': overallFieldStrength,
    'fieldQuality': fieldQuality,
    'fieldColor': fieldColor,
    'dominantFrequencies': dominantFrequencies.map((f) => f.toJson()).toList(),
    'primaryFrequency': primaryFrequency.toJson(),
    'weakFields': weakFields.map((f) => f.toJson()).toList(),
    'instabilityZones': instabilityZones,
    'overlays': overlays.map((o) => o.toJson()).toList(),
    'overlayComplexity': overlayComplexity,
    'coherenceLevel': coherenceLevel,
    'coherenceState': coherenceState,
    'chaosIndex': chaosIndex,
    'flowAxes': flowAxes.map((a) => a.toJson()).toList(),
    'flowPattern': flowPattern,
    'resonanceDensity': resonanceDensity,
    'resonancePoints': resonancePoints,
    'evolution': evolution.toJson(),
    'currentPhase': currentPhase,
    'nextPhase': nextPhase,
    'calculatedAt': calculatedAt.toIso8601String(),
    'version': version,
  };
}

/// Einzelne Energiefrequenz
class EnergyFrequency {
  final String name; // z.B. 'Kreative Energie', 'Stabile Erdung'
  final double strength; // 0.0 - 1.0
  final String quality; // 'Hoch', 'Mittel', 'Niedrig'
  final String color; // Symbolische Farbe
  final String description; // Was diese Frequenz bedeutet
  final List<String> keywords; // Assoziierte Begriffe

  EnergyFrequency({
    required this.name,
    required this.strength,
    required this.quality,
    required this.color,
    required this.description,
    required this.keywords,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'strength': strength,
    'quality': quality,
    'color': color,
    'description': description,
    'keywords': keywords,
  };
}

/// Energieüberlagerung (mehrere Schichten)
class EnergyOverlay {
  final String layer; // 'Oberflächlich', 'Mittlere Ebene', 'Tief'
  final List<String> energies; // Welche Energien sich überlagern
  final double intensity; // Wie stark die Überlagerung
  final String effect; // Verstärkend / Abschwächend / Konfliktär

  EnergyOverlay({
    required this.layer,
    required this.energies,
    required this.intensity,
    required this.effect,
  });

  Map<String, dynamic> toJson() => {
    'layer': layer,
    'energies': energies,
    'intensity': intensity,
    'effect': effect,
  };
}

/// Energiefluss-Achse
class EnergyAxis {
  final String direction; // 'Aufwärts', 'Abwärts', 'Horizontal', etc.
  final double flowRate; // 0.0 - 1.0 (Fließgeschwindigkeit)
  final String quality; // 'Fließend', 'Stockend', 'Turbulent'
  final List<String> areas; // Betroffene Lebensbereiche

  EnergyAxis({
    required this.direction,
    required this.flowRate,
    required this.quality,
    required this.areas,
  });

  Map<String, dynamic> toJson() => {
    'direction': direction,
    'flowRate': flowRate,
    'quality': quality,
    'areas': areas,
  };
}

/// Feldentwicklung über Zeit
class FieldEvolution {
  final List<FieldSnapshot> history; // Vergangene Zustände
  final String trend; // 'Steigend', 'Fallend', 'Stabil', 'Oszillierend'
  final double changeRate; // 0.0 - 1.0 (Veränderungsgeschwindigkeit)
  final List<String> milestones; // Wichtige Wendepunkte

  FieldEvolution({
    required this.history,
    required this.trend,
    required this.changeRate,
    required this.milestones,
  });

  Map<String, dynamic> toJson() => {
    'history': history.map((s) => s.toJson()).toList(),
    'trend': trend,
    'changeRate': changeRate,
    'milestones': milestones,
  };
}

/// Feldmomentaufnahme
class FieldSnapshot {
  final DateTime timestamp;
  final double fieldStrength;
  final String phase;

  FieldSnapshot({
    required this.timestamp,
    required this.fieldStrength,
    required this.phase,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'fieldStrength': fieldStrength,
    'phase': phase,
  };
}
