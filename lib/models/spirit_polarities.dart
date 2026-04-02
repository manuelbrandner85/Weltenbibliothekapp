/// ⚖️ SPIRIT-MODUL 2: POLARITÄTEN & AUSGLEICHSMODELLE
/// 
/// Analysiert die inneren Polaritäten und Ausgleichsmechanismen einer Person.
/// 8 Hauptberechnungen erfassen die verschiedenen Spannungsachsen.
library;

class SpiritPolarities {
  // Meta-Informationen
  final String version;
  final DateTime calculatedAt;
  final String profileName;

  // 1️⃣ Aktiv ↔ Passiv Dominanz
  final ActivePassiveDominance activePassiveDominance;

  // 2️⃣ Ordnung ↔ Chaos Achse
  final OrderChaosAxis orderChaosAxis;

  // 3️⃣ Kontrolle ↔ Hingabe
  final ControlSurrenderBalance controlSurrenderBalance;

  // 4️⃣ Expansion ↔ Rückzug
  final ExpansionWithdrawal expansionWithdrawal;

  // 5️⃣ Innere Spannungsachsen
  final InnerTensionAxes innerTensionAxes;

  // 6️⃣ Balance-Zustände
  final BalanceStates balanceStates;

  // 7️⃣ Übersteuerungsindikatoren
  final OversteeringIndicators oversteeringIndicators;

  // 8️⃣ Integrationspole
  final IntegrationPoles integrationPoles;

  SpiritPolarities({
    required this.version,
    required this.calculatedAt,
    required this.profileName,
    required this.activePassiveDominance,
    required this.orderChaosAxis,
    required this.controlSurrenderBalance,
    required this.expansionWithdrawal,
    required this.innerTensionAxes,
    required this.balanceStates,
    required this.oversteeringIndicators,
    required this.integrationPoles,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'calculatedAt': calculatedAt.toIso8601String(),
        'profileName': profileName,
        'activePassiveDominance': activePassiveDominance.toJson(),
        'orderChaosAxis': orderChaosAxis.toJson(),
        'controlSurrenderBalance': controlSurrenderBalance.toJson(),
        'expansionWithdrawal': expansionWithdrawal.toJson(),
        'innerTensionAxes': innerTensionAxes.toJson(),
        'balanceStates': balanceStates.toJson(),
        'oversteeringIndicators': oversteeringIndicators.toJson(),
        'integrationPoles': integrationPoles.toJson(),
      };
}

// ========================================
// 1️⃣ AKTIV ↔ PASSIV DOMINANZ
// ========================================

class ActivePassiveDominance {
  final double activeScore; // 0-100
  final double passiveScore; // 0-100
  final String dominantPole; // "Aktiv" | "Passiv" | "Ausgeglichen"
  final double balanceRatio; // Verhältnis Aktiv/Passiv
  final String currentPhase; // "Aktiv-Phase" | "Passiv-Phase" | "Übergang"
  final List<String> activeIndicators; // Zeichen für aktive Dominanz
  final List<String> passiveIndicators; // Zeichen für passive Dominanz
  final String interpretation;

  ActivePassiveDominance({
    required this.activeScore,
    required this.passiveScore,
    required this.dominantPole,
    required this.balanceRatio,
    required this.currentPhase,
    required this.activeIndicators,
    required this.passiveIndicators,
    required this.interpretation,
  });

  Map<String, dynamic> toJson() => {
        'activeScore': activeScore,
        'passiveScore': passiveScore,
        'dominantPole': dominantPole,
        'balanceRatio': balanceRatio,
        'currentPhase': currentPhase,
        'activeIndicators': activeIndicators,
        'passiveIndicators': passiveIndicators,
        'interpretation': interpretation,
      };
}

// ========================================
// 2️⃣ ORDNUNG ↔ CHAOS ACHSE
// ========================================

class OrderChaosAxis {
  final double orderScore; // 0-100
  final double chaosScore; // 0-100
  final String dominantPole; // "Ordnung" | "Chaos" | "Dynamisches Gleichgewicht"
  final double stabilityLevel; // Wie stabil ist die Ordnung?
  final double chaosCreativity; // Kreatives Potenzial im Chaos
  final List<String> orderPatterns; // Ordnungsmuster
  final List<String> chaosPatterns; // Chaos-Muster
  final String currentNeed; // "Mehr Struktur" | "Mehr Freiheit" | "Gut so"
  final String interpretation;

  OrderChaosAxis({
    required this.orderScore,
    required this.chaosScore,
    required this.dominantPole,
    required this.stabilityLevel,
    required this.chaosCreativity,
    required this.orderPatterns,
    required this.chaosPatterns,
    required this.currentNeed,
    required this.interpretation,
  });

  Map<String, dynamic> toJson() => {
        'orderScore': orderScore,
        'chaosScore': chaosScore,
        'dominantPole': dominantPole,
        'stabilityLevel': stabilityLevel,
        'chaosCreativity': chaosCreativity,
        'orderPatterns': orderPatterns,
        'chaosPatterns': chaosPatterns,
        'currentNeed': currentNeed,
        'interpretation': interpretation,
      };
}

// ========================================
// 3️⃣ KONTROLLE ↔ HINGABE
// ========================================

class ControlSurrenderBalance {
  final double controlScore; // 0-100
  final double surrenderScore; // 0-100
  final String dominantMode; // "Kontrolle" | "Hingabe" | "Flexibel"
  final double trustLevel; // Vertrauensniveau
  final double fearOfLoss; // Angst vor Kontrollverlust
  final List<String> controlAreas; // Wo wird kontrolliert?
  final List<String> surrenderAreas; // Wo wird losgelassen?
  final String currentLesson; // Aktuelle Lektion
  final String interpretation;

  ControlSurrenderBalance({
    required this.controlScore,
    required this.surrenderScore,
    required this.dominantMode,
    required this.trustLevel,
    required this.fearOfLoss,
    required this.controlAreas,
    required this.surrenderAreas,
    required this.currentLesson,
    required this.interpretation,
  });

  Map<String, dynamic> toJson() => {
        'controlScore': controlScore,
        'surrenderScore': surrenderScore,
        'dominantMode': dominantMode,
        'trustLevel': trustLevel,
        'fearOfLoss': fearOfLoss,
        'controlAreas': controlAreas,
        'surrenderAreas': surrenderAreas,
        'currentLesson': currentLesson,
        'interpretation': interpretation,
      };
}

// ========================================
// 4️⃣ EXPANSION ↔ RÜCKZUG
// ========================================

class ExpansionWithdrawal {
  final double expansionScore; // 0-100
  final double withdrawalScore; // 0-100
  final String currentDirection; // "Expansion" | "Rückzug" | "Pendel"
  final double energyFlow; // Energiefluss nach außen/innen
  final List<String> expansionAreas; // Wo findet Expansion statt?
  final List<String> withdrawalAreas; // Wo findet Rückzug statt?
  final String cyclicPattern; // Zyklisches Muster
  final String healthyBalance; // Gesunde Balance-Empfehlung
  final String interpretation;

  ExpansionWithdrawal({
    required this.expansionScore,
    required this.withdrawalScore,
    required this.currentDirection,
    required this.energyFlow,
    required this.expansionAreas,
    required this.withdrawalAreas,
    required this.cyclicPattern,
    required this.healthyBalance,
    required this.interpretation,
  });

  Map<String, dynamic> toJson() => {
        'expansionScore': expansionScore,
        'withdrawalScore': withdrawalScore,
        'currentDirection': currentDirection,
        'energyFlow': energyFlow,
        'expansionAreas': expansionAreas,
        'withdrawalAreas': withdrawalAreas,
        'cyclicPattern': cyclicPattern,
        'healthyBalance': healthyBalance,
        'interpretation': interpretation,
      };
}

// ========================================
// 5️⃣ INNERE SPANNUNGSACHSEN
// ========================================

class InnerTensionAxes {
  final List<TensionAxis> axes; // Liste aller Spannungsachsen
  final double overallTension; // Gesamtspannung 0-100
  final String highestTension; // Achse mit höchster Spannung
  final String lowestTension; // Achse mit niedrigster Spannung
  final List<String> conflictAreas; // Konfliktbereiche
  final String resolutionPath; // Weg zur Auflösung
  final String interpretation;

  InnerTensionAxes({
    required this.axes,
    required this.overallTension,
    required this.highestTension,
    required this.lowestTension,
    required this.conflictAreas,
    required this.resolutionPath,
    required this.interpretation,
  });

  Map<String, dynamic> toJson() => {
        'axes': axes.map((a) => a.toJson()).toList(),
        'overallTension': overallTension,
        'highestTension': highestTension,
        'lowestTension': lowestTension,
        'conflictAreas': conflictAreas,
        'resolutionPath': resolutionPath,
        'interpretation': interpretation,
      };
}

class TensionAxis {
  final String name;
  final String pole1;
  final String pole2;
  final double tensionLevel; // 0-100
  final String currentPull; // Zu welchem Pol tendierst du?

  TensionAxis({
    required this.name,
    required this.pole1,
    required this.pole2,
    required this.tensionLevel,
    required this.currentPull,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'pole1': pole1,
        'pole2': pole2,
        'tensionLevel': tensionLevel,
        'currentPull': currentPull,
      };
}

// ========================================
// 6️⃣ BALANCE-ZUSTÄNDE
// ========================================

class BalanceStates {
  final double overallBalance; // 0-100
  final Map<String, double> dimensionBalances; // Balance pro Dimension
  final String mostBalanced; // Am besten ausgeglichene Dimension
  final String leastBalanced; // Am wenigsten ausgeglichene Dimension
  final List<String> balanceStrengths; // Stärken in Balance
  final List<String> balanceWeaknesses; // Schwächen in Balance
  final String balanceType; // "Statisch" | "Dynamisch" | "Zyklisch"
  final String interpretation;

  BalanceStates({
    required this.overallBalance,
    required this.dimensionBalances,
    required this.mostBalanced,
    required this.leastBalanced,
    required this.balanceStrengths,
    required this.balanceWeaknesses,
    required this.balanceType,
    required this.interpretation,
  });

  Map<String, dynamic> toJson() => {
        'overallBalance': overallBalance,
        'dimensionBalances': dimensionBalances,
        'mostBalanced': mostBalanced,
        'leastBalanced': leastBalanced,
        'balanceStrengths': balanceStrengths,
        'balanceWeaknesses': balanceWeaknesses,
        'balanceType': balanceType,
        'interpretation': interpretation,
      };
}

// ========================================
// 7️⃣ ÜBERSTEUERUNGSINDIKATOREN
// ========================================

class OversteeringIndicators {
  final List<OversteeringArea> areas; // Übersteuerungsbereiche
  final double overallOversteering; // Gesamt-Übersteuerung 0-100
  final String mostOversteered; // Am meisten übersteuert
  final List<String> symptoms; // Symptome der Übersteuerung
  final List<String> corrections; // Korrekturvorschläge
  final String urgencyLevel; // "Niedrig" | "Mittel" | "Hoch"
  final String interpretation;

  OversteeringIndicators({
    required this.areas,
    required this.overallOversteering,
    required this.mostOversteered,
    required this.symptoms,
    required this.corrections,
    required this.urgencyLevel,
    required this.interpretation,
  });

  Map<String, dynamic> toJson() => {
        'areas': areas.map((a) => a.toJson()).toList(),
        'overallOversteering': overallOversteering,
        'mostOversteered': mostOversteered,
        'symptoms': symptoms,
        'corrections': corrections,
        'urgencyLevel': urgencyLevel,
        'interpretation': interpretation,
      };
}

class OversteeringArea {
  final String name;
  final double level; // 0-100
  final String direction; // "Zu viel" | "Zu wenig"
  final String impact; // Auswirkung

  OversteeringArea({
    required this.name,
    required this.level,
    required this.direction,
    required this.impact,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'level': level,
        'direction': direction,
        'impact': impact,
      };
}

// ========================================
// 8️⃣ INTEGRATIONSPOLE
// ========================================

class IntegrationPoles {
  final List<IntegrationPole> poles; // Integrationspunkte
  final String nearestPole; // Nächster Integrationspunkt
  final double integrationProgress; // Fortschritt 0-100
  final List<String> integrationSteps; // Nächste Schritte
  final String integrationQuality; // "Fragmentiert" | "Teilweise" | "Ganzheitlich"
  final String interpretation;

  IntegrationPoles({
    required this.poles,
    required this.nearestPole,
    required this.integrationProgress,
    required this.integrationSteps,
    required this.integrationQuality,
    required this.interpretation,
  });

  Map<String, dynamic> toJson() => {
        'poles': poles.map((p) => p.toJson()).toList(),
        'nearestPole': nearestPole,
        'integrationProgress': integrationProgress,
        'integrationSteps': integrationSteps,
        'integrationQuality': integrationQuality,
        'interpretation': interpretation,
      };
}

class IntegrationPole {
  final String name;
  final String description;
  final double distance; // Wie weit weg bist du? 0-100
  final List<String> requirements; // Was braucht es zur Integration?

  IntegrationPole({
    required this.name,
    required this.description,
    required this.distance,
    required this.requirements,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'distance': distance,
        'requirements': requirements,
      };
}
