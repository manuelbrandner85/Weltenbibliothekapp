import '../models/spirit_extended_models.dart';
import '../services/storage_service.dart';
import '../models/energie_profile.dart';

/// VORSCHLAG 4: ASTRO-TRANSIT-KALENDER SERVICE
/// Berechnet astrologische Events für die nächsten 30 Tage
class AstroTransitService {
  // UNUSED FIELD: final StorageService _storage = StorageService();

  /// Generiere Transit-Events für die nächsten 30 Tage
  Future<List<AstroTransitEvent>> generateNext30Days({
    required EnergieProfile profile,
  }) async {
    final events = <AstroTransitEvent>[];
    final now = DateTime.now();

    // Berechne Vollmonde & Neumonde (ca. alle 14-15 Tage)
    events.addAll(_calculateMoonPhases(now, 30));

    // Persönliche Transite basierend auf Geburtstag
    events.addAll(_calculatePersonalTransits(profile, now, 30));

    // Sortiere nach Datum
    events.sort((a, b) => a.date.compareTo(b.date));

    return events;
  }

  List<AstroTransitEvent> _calculateMoonPhases(DateTime startDate, int days) {
    final events = <AstroTransitEvent>[];
    
    // Vereinfachte Mondphasen-Berechnung (ungefähr alle 14-15 Tage)
    // In echter App würde man eine Astro-Library verwenden
    final moonCycleLength = 29.5; // Tage
    final daysSinceKnownNewMoon = startDate.difference(DateTime(2024, 1, 11)).inDays % moonCycleLength.toInt();
    
    // Nächster Neumond
    var daysToNewMoon = (moonCycleLength - daysSinceKnownNewMoon).toInt();
    if (daysToNewMoon < days) {
      final newMoonDate = startDate.add(Duration(days: daysToNewMoon));
      events.add(AstroTransitEvent(
        date: newMoonDate,
        eventType: 'newmoon',
        title: '🌑 Neumond',
        description: 'Perfekter Zeitpunkt für Neuanfänge und Intentionen setzen. '
            'Die Energie des Neumonds unterstützt neue Projekte und frische Starts.',
        influence: 'positive',
        recommendations: [
          'Setze neue Intentionen',
          'Starte ein neues Projekt',
          'Meditiere über deine Ziele',
          'Schreibe Wünsche auf',
        ],
      ));
    }

    // Vollmond (ca. 14-15 Tage nach Neumond)
    var daysToFullMoon = daysToNewMoon + 15;
    if (daysToFullMoon < days) {
      final fullMoonDate = startDate.add(Duration(days: daysToFullMoon));
      events.add(AstroTransitEvent(
        date: fullMoonDate,
        eventType: 'fullmoon',
        title: '🌕 Vollmond',
        description: 'Zeit der Vollendung und des Loslassens. '
            'Der Vollmond bringt Emotionen an die Oberfläche und ermöglicht Transformation.',
        influence: 'neutral',
        recommendations: [
          'Loslassen, was nicht mehr dient',
          'Vollmond-Ritual durchführen',
          'Emotionen zulassen',
          'Dankbarkeit praktizieren',
        ],
      ));
    }

    return events;
  }

  List<AstroTransitEvent> _calculatePersonalTransits(
    EnergieProfile profile,
    DateTime startDate,
    int days,
  ) {
    final events = <AstroTransitEvent>[];
    final birthDate = profile.birthDate;

    // Prüfe ob Geburtstag in den nächsten 30 Tagen
    final nextBirthday = DateTime(
      startDate.year,
      birthDate.month,
      birthDate.day,
    );
    
    final daysUntilBirthday = nextBirthday.difference(startDate).inDays;
    
    if (daysUntilBirthday >= 0 && daysUntilBirthday <= days) {
      events.add(AstroTransitEvent(
        date: nextBirthday,
        eventType: 'solar_return',
        title: '🎂 Solar Return (Geburtstag)',
        description: 'Die Sonne kehrt an ihre Geburtsposition zurück. '
            'Ein kraftvoller Tag für Reflexion und neue Jahresvorsätze.',
        influence: 'positive',
        recommendations: [
          'Reflektiere über das vergangene Jahr',
          'Setze Intentionen für das neue Jahr',
          'Feiere deine Erfolge',
          'Ehre deinen Lebensweg',
        ],
      ));

      // Eine Woche vor Geburtstag
      if (daysUntilBirthday > 7) {
        events.add(AstroTransitEvent(
          date: nextBirthday.subtract(const Duration(days: 7)),
          eventType: 'pre_solar_return',
          title: '⚡ Pre-Solar Return Phase',
          description: 'Die Woche vor deinem Geburtstag ist eine intensive Zeit der Vorbereitung. '
              'Alte Energien klären sich, um Platz für Neues zu machen.',
          influence: 'challenging',
          recommendations: [
            'Räume auf (physisch & energetisch)',
            'Lasse los, was nicht mehr passt',
            'Bereite dich auf Transformation vor',
            'Sei sanft mit dir selbst',
          ],
        ));
      }
    }

    // Persönliche Tage basierend auf Numerologie
    events.addAll(_calculateNumerologyDays(profile, startDate, days));

    return events;
  }

  List<AstroTransitEvent> _calculateNumerologyDays(
    EnergieProfile profile,
    DateTime startDate,
    int days,
  ) {
    final events = <AstroTransitEvent>[];

    // Berechne "Power Days" basierend auf Geburtsdatum
    for (var i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final dayNumber = date.day;
      final birthDay = profile.birthDate.day;

      // Wenn Tag = Geburtstag-Tag (z.B. beide 15.)
      if (dayNumber == birthDay && date != profile.birthDate) {
        events.add(AstroTransitEvent(
          date: date,
          eventType: 'power_day',
          title: '⚡ Persönlicher Power-Tag',
          description: 'Heute ist dein persönlicher Power-Tag (Tag $dayNumber). '
              'Die Energie dieses Tages resoniert besonders mit deiner Geburtsschwingung.',
          influence: 'positive',
          recommendations: [
            'Wichtige Entscheidungen treffen',
            'Manifestations-Arbeit',
            'Mutige Schritte wagen',
            'Auf Intuition vertrauen',
          ],
        ));
      }

      // Master-Zahlen Tage (11, 22)
      if (dayNumber == 11 || dayNumber == 22) {
        events.add(AstroTransitEvent(
          date: date,
          eventType: 'master_number_day',
          title: '✨ Master-Zahl Tag ($dayNumber)',
          description: 'Master-Zahlen tragen besondere spirituelle Energie. '
              'Heute ist ein Tag erhöhter Intuition und spiritueller Verbindung.',
          influence: 'positive',
          recommendations: [
            'Meditation vertiefen',
            'Auf Synchronizitäten achten',
            'Spirituelle Praktiken',
            'Innere Führung hören',
          ],
        ));
      }
    }

    return events;
  }

  /// Hole Event für spezifischen Tag
  AstroTransitEvent? getEventForDate(List<AstroTransitEvent> events, DateTime date) {
    return events.firstWhere(
      (e) => e.date.year == date.year && 
             e.date.month == date.month && 
             e.date.day == date.day,
      orElse: () => events.first, // Fallback
    );
  }

  /// Farbe basierend auf Einfluss
  int getInfluenceColor(String influence) {
    switch (influence) {
      case 'positive': return 0xFF4CAF50; // Grün
      case 'challenging': return 0xFFFF9800; // Orange
      case 'neutral': return 0xFF2196F3; // Blau
      default: return 0xFF9C27B0; // Lila
    }
  }

  /// Icon basierend auf Event-Typ
  String getEventIcon(String eventType) {
    switch (eventType) {
      case 'fullmoon': return '🌕';
      case 'newmoon': return '🌑';
      case 'solar_return': return '🎂';
      case 'power_day': return '⚡';
      case 'master_number_day': return '✨';
      default: return '🔮';
    }
  }
}
