/// 🔄 TRANSFORMATION ENGINE - Kompakte Version
/// Berechnet Transformations- und Schwellenphasen
library;

import 'dart:math';
import '../../models/energie_profile.dart';
import '../../models/spirit_transformation.dart';

class TransformationEngine {
  static const String version = '1.0.0';

  static SpiritTransformation calculateTransformation(EnergieProfile profile) {
    final now = DateTime.now();
    final age = now.year - profile.birthDate.year;
    final personalYear = _calculatePersonalYear(profile.birthDate, now);
    
    return SpiritTransformation(
      version: version,
      calculatedAt: now,
      profileName: '${profile.firstName} ${profile.lastName}',
      transitionPhases: _calculateTransitionPhases(age, personalYear),
      dissolutionPhases: _calculateDissolutionPhases(personalYear, age),
      formationPhases: _calculateFormationPhases(personalYear, age),
      initiationMarkers: _calculateInitiationMarkers(age),
      maturityPhases: _calculateMaturityPhases(age, personalYear),
      densificationLevels: _calculateDensificationLevels(age, personalYear),
      relapsePatterns: _calculateRelapsePatterns(personalYear, age),
      integrationWindows: _calculateIntegrationWindows(personalYear, age),
    );
  }

  static TransitionPhases _calculateTransitionPhases(int age, int personalYear) {
    String currentPhase;
    double intensity;
    
    if (personalYear == 1 || personalYear == 9) {
      currentPhase = 'Schwelle';
      intensity = 90.0;
    } else if (personalYear >= 2 && personalYear <= 4) {
      currentPhase = 'Integration';
      intensity = 60.0;
    } else {
      currentPhase = 'Vorbereitung';
      intensity = 40.0;
    }

    final daysSinceBirthday = (DateTime.now().difference(
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    ).inDays % 365).abs();
    
    return TransitionPhases(
      currentPhase: currentPhase,
      phaseIntensity: intensity,
      daysInPhase: daysSinceBirthday,
      estimatedDaysRemaining: 365 - daysSinceBirthday,
      phaseCharacteristics: _getPhaseCharacteristics(currentPhase),
      nextPhase: _getNextPhase(personalYear),
      interpretation: _getTransitionInterpretation(currentPhase, intensity),
    );
  }

  static DissolutionPhases _calculateDissolutionPhases(int year, int age) {
    final isInDissolution = year == 9 || (age % 7 == 6);
    return DissolutionPhases(
      isInDissolution: isInDissolution,
      dissolutionIntensity: isInDissolution ? 80.0 : 20.0,
      dissolvingPatterns: isInDissolution 
        ? ['Alte Identitäten', 'Überholte Muster', 'Vergangene Rollen']
        : ['Kleinere Anpassungen'],
      dissolutionType: year == 9 ? 'Radikal' : 'Sanft',
      resistancePoints: isInDissolution 
        ? ['Angst vor Neuem', 'Festhalten am Bekannten']
        : [],
      guidanceForRelease: 'Vertraue dem Prozess der Auflösung',
      interpretation: isInDissolution
        ? 'Du bist in einer intensiven Auflösungsphase'
        : 'Keine aktive Auflösung, Zeit für Stabilität',
    );
  }

  static FormationPhases _calculateFormationPhases(int year, int age) {
    final isInFormation = year == 1 || (age % 7 == 0);
    return FormationPhases(
      isInFormation: isInFormation,
      formationIntensity: isInFormation ? 85.0 : 30.0,
      emergingPatterns: isInFormation
        ? ['Neue Identität', 'Frische Perspektiven', 'Unbekannte Potenziale']
        : ['Organisches Wachstum'],
      formationType: year == 1 ? 'Spontan' : 'Organisch',
      readinessLevel: isInFormation ? 70.0 : 50.0,
      supportingFactors: ['Offenheit', 'Mut', 'Vertrauen'],
      interpretation: 'Neubildung ist ${isInFormation ? 'sehr aktiv' : 'moderat'}',
    );
  }

  static InitiationMarkers _calculateInitiationMarkers(int age) {
    final initiations = [
      InitiationEvent(
        name: 'Saturn-Return',
        ageRange: '28-30 Jahre',
        description: 'Erste große Lebensüberprüfung',
        isPassed: age > 30,
      ),
      InitiationEvent(
        name: 'Mittlere Lebenskrise',
        ageRange: '40-45 Jahre',
        description: 'Neuausrichtung der Lebensziele',
        isPassed: age > 45,
      ),
      InitiationEvent(
        name: 'Zweiter Saturn-Return',
        ageRange: '56-60 Jahre',
        description: 'Weisheits-Initiation',
        isPassed: age > 60,
      ),
    ];

    return InitiationMarkers(
      pastInitiations: initiations.where((i) => i.isPassed).toList(),
      currentInitiation: initiations.firstWhere(
        (i) => !i.isPassed && age >= int.parse(i.ageRange.split('-')[0]) - 2,
        orElse: () => initiations.first,
      ),
      upcomingInitiations: initiations.where((i) => !i.isPassed).toList(),
      initiationReadiness: min(age / 60.0 * 100, 100),
      interpretation: 'Du durchläufst wichtige Lebensschwellen',
    );
  }

  static MaturityPhases _calculateMaturityPhases(int age, int year) {
    String level;
    double score;
    
    if (age < 21) {
      level = 'Unreif';
      score = age / 21.0 * 40;
    } else if (age < 42) {
      level = 'Reifend';
      score = 40 + ((age - 21) / 21.0 * 30);
    } else if (age < 63) {
      level = 'Reif';
      score = 70 + ((age - 42) / 21.0 * 20);
    } else {
      level = 'Überreif';
      score = 90 + min((age - 63) / 21.0 * 10, 10);
    }

    return MaturityPhases(
      currentMaturityLevel: level,
      maturityScore: score,
      maturityIndicators: ['Selbstreflexion', 'Geduld', 'Weisheit'],
      immaturityIndicators: age < 30 ? ['Impulsivität', 'Ungeduld'] : [],
      maturityPath: 'Durch Erfahrung und Integration',
      interpretation: 'Deine Reife entwickelt sich natürlich',
    );
  }

  static DensificationLevels _calculateDensificationLevels(int age, int year) {
    final density = min((age / 60.0) * 80 + (year / 9.0) * 20, 100.0);
    String trend;
    
    if (year <= 3) {
      trend = 'Verdichtend';
    } else if (year >= 7) {
      trend = 'Auflösend';
    } else {
      trend = 'Stabil';
    }

    return DensificationLevels(
      currentDensity: density,
      densityTrend: trend,
      densityAreas: ['Materielle Realität', 'Körperliche Form'],
      healthyDensityRange: '40-70%',
      adjustmentGuidance: 'Balance zwischen Erdung und Leichtigkeit',
      interpretation: 'Deine Verdichtung ist ${trend.toLowerCase()}',
    );
  }

  static RelapsePatterns _calculateRelapsePatterns(int year, int age) {
    final patterns = [
      RelapsePattern(
        name: 'Alte Gewohnheiten',
        frequency: (year == 7 || year == 8) ? 3 : 1,
        lastOccurrence: 'Vor ${(9 - year)} Monaten',
        intensity: (year == 7 || year == 8) ? 70.0 : 30.0,
      ),
    ];

    return RelapsePatterns(
      detectedPatterns: patterns,
      relapseRisk: (year == 7 || year == 8) ? 65.0 : 25.0,
      mostCommonRelapse: 'Alte Gewohnheiten',
      triggers: ['Stress', 'Unsicherheit', 'Müdigkeit'],
      preventionStrategies: ['Achtsamkeit', 'Selbstfürsorge', 'Neue Routinen'],
      interpretation: 'Rückfallmuster sind erkennbar und managebar',
    );
  }

  static IntegrationWindows _calculateIntegrationWindows(int year, int age) {
    final isOpen = year >= 3 && year <= 6;
    return IntegrationWindows(
      isWindowOpen: isOpen,
      windowDuration: isOpen ? (6 - year + 1) * 120.0 : 0,
      whatToIntegrate: isOpen
        ? ['Neue Erkenntnisse', 'Transformationserfahrungen']
        : ['Bereite dich vor'],
      integrationProgress: isOpen ? ((year - 3) / 3.0) * 100.0 : 0.0,
      nextWindowOpening: isOpen ? 'Aktuell offen' : 'Jahr ${(9 - year + 3) % 9}',
      integrationPractices: ['Meditation', 'Reflexion', 'Journaling'],
      interpretation: isOpen
        ? 'Ein Integrationsfenster ist geöffnet'
        : 'Warte auf das nächste Fenster',
    );
  }

  // Helper functions
  static int _calculatePersonalYear(DateTime birthDate, DateTime now) {
    final sum = birthDate.day + birthDate.month + now.year;
    return _reduceToSingleDigit(sum);
  }

  static int _reduceToSingleDigit(int number) {
    while (number > 9 && number != 11 && number != 22 && number != 33) {
      number = number.toString().split('').map(int.parse).reduce((a, b) => a + b);
    }
    return number;
  }

  static List<String> _getPhaseCharacteristics(String phase) {
    switch (phase) {
      case 'Schwelle':
        return ['Intensität', 'Unsicherheit', 'Potenzial'];
      case 'Integration':
        return ['Verarbeitung', 'Verankerung', 'Stabilisierung'];
      case 'Vorbereitung':
        return ['Sammlung', 'Planung', 'Aufbau'];
      default:
        return [];
    }
  }

  static String _getNextPhase(int year) {
    if (year == 9) return 'Neuanfang (Jahr 1)';
    if (year >= 7) return 'Schwelle (Jahr 9)';
    if (year <= 3) return 'Integration (Jahr 4-6)';
    return 'Vorbereitung (Jahr 7-8)';
  }

  static String _getTransitionInterpretation(String phase, double intensity) {
    if (phase == 'Schwelle' && intensity > 80) {
      return 'Du stehst an einer wichtigen Schwelle. Große Transformation ist im Gange.';
    } else if (phase == 'Integration') {
      return 'Zeit der Integration. Was du erfahren hast, wird jetzt Teil von dir.';
    } else {
      return 'Vorbereitung. Du sammelst Kraft für kommende Veränderungen.';
    }
  }
}
