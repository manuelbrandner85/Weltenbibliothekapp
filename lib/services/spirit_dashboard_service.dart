import 'package:flutter/material.dart';
import '../models/spirit_dashboard.dart';
import '../models/energie_profile.dart';
import 'numerology_service.dart';
import 'cycle_analysis_service.dart';
import 'archetype_service.dart';

/// SPIRIT DASHBOARD SERVICE
/// Zentrale Berechnung aller Spirit-Daten aus Profil
class SpiritDashboardService {
  final _numerology = NumerologyService();
  final _cycles = CycleAnalysisService();
  final _archetypes = ArchetypeService();

  /// BERECHNE VOLLSTÄNDIGES DASHBOARD AUS PROFIL
  SpiritDashboard calculateDashboard(EnergieProfile profile) {
    final currentDate = DateTime.now();
    final birthDate = profile.birthDate;
    
    // NUMEROLOGIE
    final lifePathNumber = _numerology.calculateLifePath(birthDate);
    final soulNumber = _numerology.calculateSoulNumber(
      profile.fullName.split(' ').first,
      profile.fullName.split(' ').length > 1 
        ? profile.fullName.split(' ').last 
        : '',
    );
    final expressionNumber = _numerology.calculateExpressionNumber(
      profile.fullName.split(' ').first,
      profile.fullName.split(' ').length > 1 
        ? profile.fullName.split(' ').last 
        : '',
    );
    final nameVibration = _numerology.calculateNameVibration(
      profile.fullName.split(' ').first,
      profile.fullName.split(' ').length > 1 
        ? profile.fullName.split(' ').last 
        : '',
    );
    final coreFrequency = _numerology.calculateCoreFrequency(
      birthDate,
      profile.fullName.split(' ').first,
      profile.fullName.split(' ').length > 1 
        ? profile.fullName.split(' ').last 
        : '',
    );
    
    // Farbe aus Frequenz
    final frequencyColorHex = _numerology.getCoreFrequencyColor(coreFrequency);
    final frequencyColor = Color(
      int.parse(frequencyColorHex.replaceFirst('#', '0xFF'))
    );

    // ZYKLEN
    final personalYear = _cycles.calculatePersonalYear(birthDate, currentDate);
    final personalMonth = _cycles.calculatePersonalMonth(birthDate, currentDate);
    final personalDay = _cycles.calculatePersonalDay(birthDate, currentDate);
    final nineYearCycle = _cycles.calculateNineYearCycle(birthDate, currentDate);
    final isTransitionYear = _cycles.isTransitionYear(birthDate, currentDate);

    // ARCHETYPEN
    final primaryArchetype = _archetypes.getPrimaryArchetype(lifePathNumber);
    final secondaryArchetype = _archetypes.getSecondaryArchetype(soulNumber);
    final shadowArchetype = _archetypes.getShadowArchetype(lifePathNumber);
    final activationArchetype = _archetypes.getActivationArchetype(personalYear);

    return SpiritDashboard(
      firstName: profile.fullName.split(' ').first,
      lastName: profile.fullName.split(' ').length > 1 
        ? profile.fullName.split(' ').last 
        : '',
      birthDate: birthDate,
      currentDate: currentDate,
      lifePathNumber: lifePathNumber,
      soulNumber: soulNumber,
      expressionNumber: expressionNumber,
      nameVibration: nameVibration,
      coreFrequency: coreFrequency,
      frequencyColor: frequencyColor,
      personalYear: personalYear,
      personalMonth: personalMonth,
      personalDay: personalDay,
      nineYearCycle: nineYearCycle,
      isTransitionYear: isTransitionYear,
      primaryArchetype: primaryArchetype,
      secondaryArchetype: secondaryArchetype,
      shadowArchetype: shadowArchetype,
      activationArchetype: activationArchetype,
    );
  }

  /// GENERIERE KI-FRAGEN BASIEREND AUF AKTUELLEM STATUS
  List<String> generateContextualQuestions(SpiritDashboard dashboard) {
    final questions = <String>[];
    
    // Basierend auf Persönlichem Jahr
    if (dashboard.personalYear == 1) {
      questions.add('Was möchtest du in diesem Jahr der Neuanfänge initiieren?');
      questions.add('Welche alte Version von dir darfst du jetzt loslassen?');
    } else if (dashboard.personalYear == 7) {
      questions.add('Welche innere Weisheit möchte sich dir offenbaren?');
      questions.add('Was brauchst du, um tiefer in die Stille zu gehen?');
    } else if (dashboard.personalYear == 9) {
      questions.add('Was ist bereit, vollendet zu werden?');
      questions.add('Welche Lektion hat dieser Zyklus für dich?');
    }
    
    // Basierend auf Primärem Archetyp
    final archetypeName = dashboard.primaryArchetype['name'] as String;
    if (archetypeName.contains('Magier')) {
      questions.add('Welche Transformation möchte durch dich geschehen?');
    } else if (archetypeName.contains('Weise')) {
      questions.add('Welche Wahrheit möchte erkannt werden?');
    } else if (archetypeName.contains('Entdecker')) {
      questions.add('Wohin ruft dich die innere Reise?');
    }
    
    // Basierend auf Übergangsphase
    if (dashboard.isTransitionYear) {
      questions.add('Was endet gerade in deinem Leben?');
      questions.add('Was wartet darauf, geboren zu werden?');
    }
    
    // Fallback
    if (questions.isEmpty) {
      questions.add('Welche Rolle wiederholt sich aktuell in deinem Leben?');
      questions.add('Was möchte diese Phase von dir lernen?');
    }
    
    return questions.take(3).toList();
  }
}
