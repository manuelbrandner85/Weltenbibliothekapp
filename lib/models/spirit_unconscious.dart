/// 🧠 SPIRIT-MODUL 4: UNTERBEWUSSTSEINS- & MUSTERANALYSE
/// Analysiert unbewusste Muster, Projektionen und Schattenthemen
library;

class SpiritUnconscious {
  final String version;
  final DateTime calculatedAt;
  final String profileName;

  final List<String> repeatingPatterns;
  final List<String> projectionThemes;
  final List<String> repressionIndicators;
  final List<String> conflictAxes;
  final List<String> mirrorMechanisms;
  final List<String> integrationResistances;
  final List<String> awarenessMarkers;
  final List<String> unconsciousLeadThemes;
  final String dominantPattern;
  final double awarenessLevel; // 0-100
  final String interpretation;

  SpiritUnconscious({
    required this.version,
    required this.calculatedAt,
    required this.profileName,
    required this.repeatingPatterns,
    required this.projectionThemes,
    required this.repressionIndicators,
    required this.conflictAxes,
    required this.mirrorMechanisms,
    required this.integrationResistances,
    required this.awarenessMarkers,
    required this.unconsciousLeadThemes,
    required this.dominantPattern,
    required this.awarenessLevel,
    required this.interpretation,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'calculatedAt': calculatedAt.toIso8601String(),
        'profileName': profileName,
        'repeatingPatterns': repeatingPatterns,
        'projectionThemes': projectionThemes,
        'repressionIndicators': repressionIndicators,
        'conflictAxes': conflictAxes,
        'mirrorMechanisms': mirrorMechanisms,
        'integrationResistances': integrationResistances,
        'awarenessMarkers': awarenessMarkers,
        'unconsciousLeadThemes': unconsciousLeadThemes,
        'dominantPattern': dominantPattern,
        'awarenessLevel': awarenessLevel,
        'interpretation': interpretation,
      };
}
