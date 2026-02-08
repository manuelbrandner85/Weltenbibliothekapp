/// Planetary Hours Service
/// Berechnet planetare Stunden basierend auf Sonnenaufgang und Sonnenuntergang
library;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

class PlanetaryHoursService {
  static final PlanetaryHoursService _instance = PlanetaryHoursService._internal();
  factory PlanetaryHoursService() => _instance;
  PlanetaryHoursService._internal();

  /// Holt aktuelle planetare Stunde
  PlanetaryHour getCurrentPlanetaryHour({
    double latitude = 48.1351, // München als Default
    double longitude = 11.5820,
  }) {
    final now = DateTime.now();
    return calculatePlanetaryHour(now, latitude: latitude, longitude: longitude);
  }

  /// Berechnet planetare Stunde für ein spezifisches Datum
  PlanetaryHour calculatePlanetaryHour(
    DateTime dateTime, {
    required double latitude,
    required double longitude,
  }) {
    // Berechne Sonnenaufgang und Sonnenuntergang (vereinfacht)
    final sunrise = _calculateSunrise(dateTime, latitude, longitude);
    final sunset = _calculateSunset(dateTime, latitude, longitude);
    
    // Bestimme ob Tag oder Nacht
    final isDay = dateTime.isAfter(sunrise) && dateTime.isBefore(sunset);
    
    // Berechne planetare Stunden
    final hours = _calculateHours(dateTime, sunrise, sunset, isDay);
    
    // Finde aktuelle Stunde
    final current = hours.firstWhere(
      (h) => dateTime.isAfter(h.startTime) && dateTime.isBefore(h.endTime),
      orElse: () => hours.first,
    );
    
    if (kDebugMode) {
      debugPrint('🕐 Planetary Hour: ${current.planet} (${current.startTime.hour}:${current.startTime.minute} - ${current.endTime.hour}:${current.endTime.minute})');
    }
    
    return current;
  }

  /// Holt alle planetaren Stunden für einen Tag
  List<PlanetaryHour> getDailyPlanetaryHours(
    DateTime date, {
    required double latitude,
    required double longitude,
  }) {
    final sunrise = _calculateSunrise(date, latitude, longitude);
    final sunset = _calculateSunset(date, latitude, longitude);
    
    final dayHours = _calculateHours(date, sunrise, sunset, true);
    final nightHours = _calculateHours(date, sunrise, sunset, false);
    
    return [...dayHours, ...nightHours];
  }

  /// Vereinfachte Sonnenaufgangs-Berechnung
  DateTime _calculateSunrise(DateTime date, double lat, double lng) {
    // Vereinfachte Berechnung: 6:30 AM ± Variation basierend auf Monat
    final month = date.month;
    final variation = math.sin((month - 3) * math.pi / 6) * 2; // ±2 Stunden
    final hour = 6 + variation.round();
    final minute = 30;
    
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// Vereinfachte Sonnenuntergangs-Berechnung
  DateTime _calculateSunset(DateTime date, double lat, double lng) {
    // Vereinfachte Berechnung: 18:30 PM ± Variation basierend auf Monat
    final month = date.month;
    final variation = math.sin((month - 3) * math.pi / 6) * 2; // ±2 Stunden
    final hour = 18 + variation.round();
    final minute = 30;
    
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// Berechnet die 12 planetaren Stunden
  List<PlanetaryHour> _calculateHours(
    DateTime date,
    DateTime sunrise,
    DateTime sunset,
    bool isDay,
  ) {
    // Planet-Reihenfolge (klassische Planetenstunden)
    final planetOrder = ['Saturn', 'Jupiter', 'Mars', 'Sonne', 'Venus', 'Merkur', 'Mond'];
    
    // Wochentag bestimmt Start-Planeten
    final dayOfWeek = date.weekday; // 1=Monday, 7=Sunday
    final dayPlanets = {
      1: 'Mond',     // Monday
      2: 'Mars',     // Tuesday
      3: 'Merkur',   // Wednesday
      4: 'Jupiter',  // Thursday
      5: 'Venus',    // Friday
      6: 'Saturn',   // Saturday
      7: 'Sonne',    // Sunday
    };
    
    final startPlanet = dayPlanets[dayOfWeek]!;
    final startIndex = planetOrder.indexOf(startPlanet);
    
    // Berechne Zeitspanne
    final period = isDay ? sunset.difference(sunrise) : sunrise.add(const Duration(days: 1)).difference(sunset);
    final hourDuration = period.inMinutes / 12;
    
    // Erstelle Stunden
    final hours = <PlanetaryHour>[];
    final startTime = isDay ? sunrise : sunset;
    
    for (var i = 0; i < 12; i++) {
      final planetIndex = (startIndex + (isDay ? i : i + 12)) % 7;
      final planet = planetOrder[planetIndex];
      
      final hourStart = startTime.add(Duration(minutes: (hourDuration * i).round()));
      final hourEnd = startTime.add(Duration(minutes: (hourDuration * (i + 1)).round()));
      
      hours.add(PlanetaryHour(
        planet: planet,
        startTime: hourStart,
        endTime: hourEnd,
        isDay: isDay,
        hourNumber: i + 1,
        symbol: _getPlanetSymbol(planet),
        color: _getPlanetColor(planet),
        activities: _getPlanetActivities(planet),
        description: _getPlanetDescription(planet),
      ));
    }
    
    return hours;
  }

  String _getPlanetSymbol(String planet) {
    switch (planet) {
      case 'Sonne':
        return '☉';
      case 'Mond':
        return '☽';
      case 'Merkur':
        return '☿';
      case 'Venus':
        return '♀';
      case 'Mars':
        return '♂';
      case 'Jupiter':
        return '♃';
      case 'Saturn':
        return '♄';
      default:
        return '⭐';
    }
  }

  int _getPlanetColor(String planet) {
    switch (planet) {
      case 'Sonne':
        return 0xFFFFC107; // Amber/Gold
      case 'Mond':
        return 0xFF9E9E9E; // Silver/Grey
      case 'Merkur':
        return 0xFFFF9800; // Orange
      case 'Venus':
        return 0xFFE91E63; // Pink
      case 'Mars':
        return 0xFFF44336; // Red
      case 'Jupiter':
        return 0xFF9C27B0; // Purple
      case 'Saturn':
        return 0xFF607D8B; // Blue Grey
      default:
        return 0xFFFFFFFF;
    }
  }

  List<String> _getPlanetActivities(String planet) {
    switch (planet) {
      case 'Sonne':
        return ['Führung übernehmen', 'Selbstbewusstsein stärken', 'Kreative Projekte', 'Öffentliche Auftritte'];
      case 'Mond':
        return ['Emotionale Arbeit', 'Intuition nutzen', 'Familie & Zuhause', 'Meditation'];
      case 'Merkur':
        return ['Kommunizieren', 'Lernen & Lehren', 'Verträge abschließen', 'Reisen planen'];
      case 'Venus':
        return ['Beziehungspflege', 'Kunst & Musik', 'Shopping', 'Selbstfürsorge'];
      case 'Mars':
        return ['Sport & Bewegung', 'Konflikte lösen', 'Mut fassen', 'Projekte starten'];
      case 'Jupiter':
        return ['Expansion & Wachstum', 'Finanzplanung', 'Studium', 'Reisen'];
      case 'Saturn':
        return ['Struktur schaffen', 'Langfristig planen', 'Disziplin üben', 'Verantwortung'];
      default:
        return [];
    }
  }

  String _getPlanetDescription(String planet) {
    switch (planet) {
      case 'Sonne':
        return 'Perfekt für Führung, Selbstausdruck und kreative Projekte. Zeit, um im Mittelpunkt zu stehen.';
      case 'Mond':
        return 'Ideal für emotionale Arbeit, Intuition und häusliche Angelegenheiten. Zeit für Reflexion.';
      case 'Merkur':
        return 'Optimal für Kommunikation, Lernen und geschäftliche Angelegenheiten. Zeit für Austausch.';
      case 'Venus':
        return 'Beste Zeit für Liebe, Kunst, Schönheit und soziale Aktivitäten. Zeit für Genuss.';
      case 'Mars':
        return 'Günstig für körperliche Aktivität, Mut und Durchsetzung. Zeit für Action.';
      case 'Jupiter':
        return 'Perfekt für Wachstum, Expansion und spirituelle Entwicklung. Zeit für Großes.';
      case 'Saturn':
        return 'Ideal für Struktur, Disziplin und langfristige Planung. Zeit für Ernsthaftes.';
      default:
        return '';
    }
  }
}

class PlanetaryHour {
  final String planet;
  final DateTime startTime;
  final DateTime endTime;
  final bool isDay;
  final int hourNumber;
  final String symbol;
  final int color;
  final List<String> activities;
  final String description;

  PlanetaryHour({
    required this.planet,
    required this.startTime,
    required this.endTime,
    required this.isDay,
    required this.hourNumber,
    required this.symbol,
    required this.color,
    required this.activities,
    required this.description,
  });

  /// Formatierte Start-Zeit
  String get formattedStartTime => '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';

  /// Formatierte End-Zeit
  String get formattedEndTime => '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

  /// Zeitbereich als String
  String get timeRange => '$formattedStartTime - $formattedEndTime';
}
