import 'package:flutter/material.dart';

/// SPIRIT DASHBOARD DATA MODEL
/// Enthält alle berechneten Werte für persönliche Signatur, Zyklen, Archetypen
class SpiritDashboard {
  // PROFIL-DATEN
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final DateTime currentDate;

  // NUMEROLOGIE
  final int lifePathNumber;
  final int soulNumber;
  final int expressionNumber;
  final int nameVibration;
  final double coreFrequency;
  final Color frequencyColor;

  // ZYKLEN
  final int personalYear;
  final int personalMonth;
  final int personalDay;
  final Map<String, dynamic> nineYearCycle;
  final bool isTransitionYear;

  // ARCHETYPEN
  final Map<String, dynamic> primaryArchetype;
  final Map<String, dynamic> secondaryArchetype;
  final Map<String, dynamic> shadowArchetype;
  final Map<String, dynamic> activationArchetype;

  SpiritDashboard({
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.currentDate,
    required this.lifePathNumber,
    required this.soulNumber,
    required this.expressionNumber,
    required this.nameVibration,
    required this.coreFrequency,
    required this.frequencyColor,
    required this.personalYear,
    required this.personalMonth,
    required this.personalDay,
    required this.nineYearCycle,
    required this.isTransitionYear,
    required this.primaryArchetype,
    required this.secondaryArchetype,
    required this.shadowArchetype,
    required this.activationArchetype,
  });

  /// PERSÖNLICHE SIGNATUR TEXT
  String get personalSignature {
    return '''
Du schwingst in der Frequenz ${coreFrequency.toStringAsFixed(1)}

🔮 Lebenszahl: $lifePathNumber
💫 Seelenzahl: $soulNumber
⚡ Ausdruckszahl: $expressionNumber
🎵 Namensschwingung: $nameVibration

Diese einzigartige Kombination macht deine energetische Grundsignatur aus.
''';
  }

  /// ZYKLUS STATUS TEXT
  String get cycleStatus {
    final phase = nineYearCycle['phase'];
    return '''
Persönliches Jahr: $personalYear
Aktueller Monat: $personalMonth
Heutiger Tag: $personalDay

9-Jahres-Zyklus: ${nineYearCycle['position']}/9 ($phase)
${isTransitionYear ? '⚠️ Transformationsjahr!' : ''}
''';
  }

  /// ARCHETYPEN ÜBERSICHT
  String get archetypeOverview {
    return '''
🎭 Primär: ${primaryArchetype['name']}
✨ Sekundär: ${secondaryArchetype['name']}
🌑 Schatten: ${shadowArchetype['name']}
⚡ Aktiviert: ${activationArchetype['name']}
''';
  }
}

/// SYNCHRONIZITÄTS-EVENT
class SynchronicityEvent {
  final DateTime timestamp;
  final String description;
  final List<int> numbers;
  final List<String> themes;
  final int resonanceStrength; // 1-5

  SynchronicityEvent({
    required this.timestamp,
    required this.description,
    required this.numbers,
    required this.themes,
    required this.resonanceStrength,
  });
}

/// INNERES JOURNAL EINTRAG
class InnerJournalEntry {
  final DateTime timestamp;
  final String question;
  final String? answer;
  final List<String> tags;
  final int archetypeId;

  InnerJournalEntry({
    required this.timestamp,
    required this.question,
    this.answer,
    required this.tags,
    required this.archetypeId,
  });
}
