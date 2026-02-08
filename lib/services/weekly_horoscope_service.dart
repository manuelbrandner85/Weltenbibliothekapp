import '../models/spirit_extended_models.dart';
import '../models/spirit_dashboard.dart';
import '../models/energie_profile.dart';
import 'storage_service.dart';

/// VORSCHLAG 7: WOCHENHOROSKOP GENERATOR
/// Generiert personalisiertes Wochenhoroskop basierend auf:
/// - Sternzeichen
/// - Aktueller Zyklus-Phase
/// - Archetyp
class WeeklyHoroscopeService {
  final StorageService _storage = StorageService();

  /// Generiere Wochenhoroskop für aktuelle Woche
  Future<WeeklyHoroscope> generateWeeklyHoroscope({
    required EnergieProfile profile,
    required SpiritDashboard dashboard,
  }) async {
    // Prüfe ob bereits Horoskop für diese Woche existiert
    final existing = _storage.getCurrentWeekHoroscope();
    if (existing != null) {
      return existing;
    }

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1)); // Montag
    final weekEnd = weekStart.add(const Duration(days: 6)); // Sonntag

    // Berechne Horoscope basierend auf Profil & Dashboard
    final cyclePhase = dashboard.nineYearCycle['phase'] as String;
    final archetype = dashboard.primaryArchetype['name'] as String;
    final personalYear = dashboard.personalYear;

    final horoscope = WeeklyHoroscope(
      weekStart: weekStart,
      weekEnd: weekEnd,
      overallTheme: _generateOverallTheme(cyclePhase, personalYear),
      categories: _generateCategories(cyclePhase, archetype, personalYear),
      luckyDays: _calculateLuckyDays(weekStart, dashboard),
      challengingDays: _calculateChallengingDays(weekStart, dashboard),
      specialAdvice: _generateSpecialAdvice(archetype, cyclePhase),
    );

    await _storage.saveWeeklyHoroscope(horoscope);
    return horoscope;
  }

  String _generateOverallTheme(String cyclePhase, int personalYear) {
    final themes = {
      'Neuanfang': 'Diese Woche steht im Zeichen des Neubeginns. '
          'Nutze die Energie für frische Starts und neue Projekte.',
      'Wachstum': 'Eine Woche des Wachstums und der Expansion. '
          'Deine Bemühungen tragen Früchte.',
      'Höhepunkt': 'Du befindest dich auf dem Gipfel deines Zyklus. '
          'Zeit für Ernte und Anerkennung.',
      'Abschluss': 'Eine Phase des Loslassens und Abschließens. '
          'Bereite dich auf den nächsten Zyklus vor.',
    };

    return themes[cyclePhase] ?? 'Eine Woche voller Möglichkeiten erwartet dich.';
  }

  Map<String, String> _generateCategories(String cyclePhase, String archetype, int personalYear) {
    return {
      'Liebe': _generateLoveForecast(cyclePhase, archetype),
      'Karriere': _generateCareerForecast(cyclePhase, personalYear),
      'Gesundheit': _generateHealthForecast(archetype),
      'Spiritualität': _generateSpiritualityForecast(cyclePhase, archetype),
    };
  }

  String _generateLoveForecast(String cyclePhase, String archetype) {
    if (archetype == 'Der Liebende') {
      return '💖 Deine Herzenergie ist besonders stark diese Woche. '
          'Perfekt für tiefe Verbindungen und romantische Momente.';
    }

    final forecasts = {
      'Neuanfang': '💖 Neue Begegnungen sind möglich. '
          'Sei offen für unerwartete Verbindungen.',
      'Wachstum': '💖 Bestehende Beziehungen vertiefen sich. '
          'Gute Zeit für wichtige Gespräche.',
      'Höhepunkt': '💖 Deine Ausstrahlung ist besonders stark. '
          'Genieße die Harmonie in deinen Beziehungen.',
    };

    return forecasts[cyclePhase] ?? '💖 Achte auf die kleinen Gesten der Liebe um dich herum.';
  }

  String _generateCareerForecast(String cyclePhase, int personalYear) {
    final forecasts = {
      'Neuanfang': '💼 Ideal für neue Projekte und Karrieresprünge. '
          'Deine Initiative wird belohnt.',
      'Wachstum': '💼 Deine Arbeit trägt Früchte. '
          'Anerkennung und Erfolg sind nah.',
      'Höhepunkt': '💼 Höchste Produktivität und Erfolg. '
          'Nutze diese Energie für wichtige Entscheidungen.',
      'Abschluss': '💼 Zeit für Reflexion und Planung. '
          'Schließe alte Projekte ab, bevor du Neues beginnst.',
    };

    return forecasts[cyclePhase] ?? '💼 Bleibe fokussiert auf deine Ziele.';
  }

  String _generateHealthForecast(String archetype) {
    if (archetype == 'Der Krieger') {
      return '🌿 Deine körperliche Energie ist hoch. '
          'Perfekt für Sport und körperliche Herausforderungen.';
    }

    return '🌿 Achte auf die Balance zwischen Aktivität und Ruhe. '
        'Dein Körper braucht beides.';
  }

  String _generateSpiritualityForecast(String cyclePhase, String archetype) {
    if (archetype == 'Der Weise') {
      return '🔮 Deine spirituelle Verbindung ist besonders stark. '
          'Nutze die Woche für tiefe Meditation und Erkenntnisse.';
    }

    final forecasts = {
      'Neuanfang': '🔮 Öffne dich für neue spirituelle Praktiken. '
          'Die Energie unterstützt dein Wachstum.',
      'Wachstum': '🔮 Deine spirituelle Praxis vertieft sich. '
          'Bleibe konsequent in deinen Übungen.',
      'Höhepunkt': '🔮 Höchste spirituelle Klarheit. '
          'Wichtige Erkenntnisse sind möglich.',
    };

    return forecasts[cyclePhase] ?? '🔮 Bleibe verbunden mit deinem höheren Selbst.';
  }

  List<String> _calculateLuckyDays(DateTime weekStart, SpiritDashboard dashboard) {
    final luckyDays = <String>[];
    final personalDay = dashboard.personalDay;

    // Basierend auf persönlichem Tag-Rhythmus
    if (personalDay % 3 == 0) {
      luckyDays.add('Montag');
      luckyDays.add('Donnerstag');
    } else if (personalDay % 3 == 1) {
      luckyDays.add('Dienstag');
      luckyDays.add('Freitag');
    } else {
      luckyDays.add('Mittwoch');
      luckyDays.add('Samstag');
    }

    return luckyDays;
  }

  List<String> _calculateChallengingDays(DateTime weekStart, SpiritDashboard dashboard) {
    final challengingDays = <String>[];
    final personalDay = dashboard.personalDay;

    // Herausfordernde Tage basierend auf Zyklus
    if (dashboard.isTransitionYear) {
      challengingDays.add('Mittwoch'); // Mitte der Woche
    }

    if (personalDay % 5 == 0) {
      challengingDays.add('Montag');
    }

    return challengingDays;
  }

  String _generateSpecialAdvice(String archetype, String cyclePhase) {
    final advice = {
      'Der Weise': '🎯 Nutze deine Weisheit, um anderen zu helfen. '
          'Dein Rat wird diese Woche besonders wertvoll sein.',
      'Der Krieger': '🎯 Setze klare Grenzen und kämpfe für das, was dir wichtig ist. '
          'Deine Stärke inspiriert andere.',
      'Der Magier': '🎯 Deine Manifestationskraft ist stark. '
          'Was du diese Woche visualisierst, kann Realität werden.',
      'Der Liebende': '🎯 Liebe ist deine Superkraft. '
          'Teile sie großzügig mit der Welt.',
    };

    return advice[archetype] ?? 
        '🎯 Vertraue deiner Intuition und folge deinem inneren Kompass.';
  }
}
