import 'dart:math' as math;

/// Lunar Phase Model with Calculations
class LunarPhase {
  final DateTime date;
  final double illumination; // 0.0 - 1.0
  final String phaseName;
  final String emoji;
  final String description;
  final List<String> recommendations;
  final List<String> avoidActions;
  final List<String> bestCrystals;
  final String energyType;

  LunarPhase({
    required this.date,
    required this.illumination,
    required this.phaseName,
    required this.emoji,
    required this.description,
    required this.recommendations,
    required this.avoidActions,
    required this.bestCrystals,
    required this.energyType,
  });

  /// Calculate current lunar phase
  static LunarPhase calculate(DateTime date) {
    final moonAge = _calculateMoonAge(date);
    final illumination = _calculateIllumination(moonAge);
    
    String phaseName;
    String emoji;
    String description;
    List<String> recommendations;
    List<String> avoidActions;
    List<String> bestCrystals;
    String energyType;

    if (moonAge < 1.84566) {
      // Neumond
      phaseName = 'Neumond';
      emoji = '🌑';
      description = 'Zeit der Dunkelheit und des Neuanfangs';
      recommendations = [
        'Setze neue Intentionen',
        'Beginne neue Projekte',
        'Meditation für Klarheit',
        'Journaling & Selbstreflexion',
      ];
      avoidActions = [
        'Wichtige Entscheidungen treffen',
        'Große Investitionen',
      ];
      bestCrystals = ['Schwarzer Turmalin', 'Obsidian', 'Labradorit'];
      energyType = 'Introvertiert, Reflektiv';
    } else if (moonAge < 7.38264) {
      // Zunehmender Mond
      phaseName = 'Zunehmender Mond';
      emoji = '🌒';
      description = 'Wachsende Energie und Manifestation';
      recommendations = [
        'Manifestiere deine Ziele',
        'Plane und organisiere',
        'Baue Beziehungen auf',
        'Lerne Neues',
      ];
      avoidActions = [
        'Loslassen alter Muster',
        'Entgiftung',
      ];
      bestCrystals = ['Citrin', 'Pyrit', 'Grüner Aventurin'];
      energyType = 'Aufbauend, Expansiv';
    } else if (moonAge < 11.07896) {
      // Erstes Viertel
      phaseName = 'Erstes Viertel';
      emoji = '🌓';
      description = 'Herausforderungen und Entscheidungen';
      recommendations = [
        'Überwinde Hindernisse',
        'Treffe wichtige Entscheidungen',
        'Handle mit Mut',
        'Sport & körperliche Aktivität',
      ];
      avoidActions = [
        'Aufgeben bei Widerstand',
        'Passivität',
      ];
      bestCrystals = ['Roter Jaspis', 'Karneol', 'Tigerauge'];
      energyType = 'Aktiv, Durchsetzend';
    } else if (moonAge < 14.77528) {
      // Zunehmender Dreiviertelmond
      phaseName = 'Zunehmender Halbmond';
      emoji = '🌔';
      description = 'Verfeinern und optimieren';
      recommendations = [
        'Optimiere deine Pläne',
        'Details verfeinern',
        'Geduld üben',
        'Kleine Schritte machen',
      ];
      avoidActions = [
        'Überstürzte Aktionen',
        'Ungeduld',
      ];
      bestCrystals = ['Amazonit', 'Aquamarin', 'Blauer Chalcedon'];
      energyType = 'Geduldig, Verfeinert';
    } else if (moonAge < 18.4716) {
      // Vollmond
      phaseName = 'Vollmond';
      emoji = '🌕';
      description = 'Höhepunkt der Energie und Emotionen';
      recommendations = [
        'Lade Kristalle auf',
        'Vollmond-Ritual',
        'Dankbarkeit praktizieren',
        'Feiern & soziale Events',
      ];
      avoidActions = [
        'Wichtige Entscheidungen (Emotionen hoch)',
        'Konflikte suchen',
        'Chirurgische Eingriffe',
      ];
      bestCrystals = ['Mondstein', 'Selenit', 'Opal'];
      energyType = 'Intensiv, Emotional';
    } else if (moonAge < 22.16792) {
      // Abnehmender Mond
      phaseName = 'Abnehmender Mond';
      emoji = '🌖';
      description = 'Loslassen und Dankbarkeit';
      recommendations = [
        'Lasse los, was nicht dient',
        'Räume auf (physisch & emotional)',
        'Vergib',
        'Danke für Erreichte',
      ];
      avoidActions = [
        'Neue Projekte starten',
        'Große Anschaffungen',
      ];
      bestCrystals = ['Amethyst', 'Rosenquarz', 'Lapislazuli'];
      energyType = 'Loslassend, Dankbar';
    } else if (moonAge < 25.86424) {
      // Letztes Viertel
      phaseName = 'Letztes Viertel';
      emoji = '🌗';
      description = 'Überprüfung und Korrektur';
      recommendations = [
        'Überprüfe deine Fortschritte',
        'Korrigiere Kurs wenn nötig',
        'Entgifte Körper & Geist',
        'Bereite dich auf Neuanfang vor',
      ];
      avoidActions = [
        'An Altem festhalten',
        'Perfektionismus',
      ];
      bestCrystals = ['Rauchquarz', 'Hämatit', 'Schwarzer Onyx'];
      energyType = 'Überprüfend, Korrigierend';
    } else {
      // Abnehmender Sichelmond
      phaseName = 'Abnehmender Halbmond';
      emoji = '🌘';
      description = 'Letzte Vorbereitungen und Ruhe';
      recommendations = [
        'Ruhe dich aus',
        'Meditiere',
        'Bereite dich auf Neumond vor',
        'Schlaf & Regeneration',
      ];
      avoidActions = [
        'Überlastung',
        'Hektische Aktivitäten',
      ];
      bestCrystals = ['Bergkristall', 'Amethyst', 'Selenit'];
      energyType = 'Ruhig, Regenerierend';
    }

    return LunarPhase(
      date: date,
      illumination: illumination,
      phaseName: phaseName,
      emoji: emoji,
      description: description,
      recommendations: recommendations,
      avoidActions: avoidActions,
      bestCrystals: bestCrystals,
      energyType: energyType,
    );
  }

  /// Calculate moon age in days (0-29.53)
  static double _calculateMoonAge(DateTime date) {
    // Known new moon: 2000-01-06 18:14 UTC
    final knownNewMoon = DateTime.utc(2000, 1, 6, 18, 14);
    final synodicMonth = 29.53058867; // days
    
    final daysSinceKnownNewMoon = date.difference(knownNewMoon).inMilliseconds / (1000 * 60 * 60 * 24);
    final moonAge = daysSinceKnownNewMoon % synodicMonth;
    
    return moonAge;
  }

  /// Calculate illumination percentage (0.0 - 1.0)
  static double _calculateIllumination(double moonAge) {
    final phase = moonAge / 29.53058867;
    return 0.5 * (1 - math.cos(2 * math.pi * phase));
  }

  /// Get next moon phase transition
  static DateTime getNextPhaseDate(DateTime current, String targetPhase) {
    DateTime testDate = current;
    LunarPhase currentPhase = calculate(testDate);
    
    // Scan forward up to 30 days
    for (int i = 0; i < 30; i++) {
      testDate = testDate.add(const Duration(days: 1));
      final phase = calculate(testDate);
      if (phase.phaseName == targetPhase && currentPhase.phaseName != targetPhase) {
        return testDate;
      }
      currentPhase = phase;
    }
    
    return current.add(const Duration(days: 30));
  }

  /// Get lunar calendar for month
  static List<LunarPhase> getMonthCalendar(int year, int month) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return List.generate(
      daysInMonth,
      (index) => calculate(DateTime(year, month, index + 1)),
    );
  }
}
