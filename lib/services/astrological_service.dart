/// Astrological Influences Service
/// Berechnet aktuelle planetare Positionen und Einflüsse
library;
import 'package:flutter/foundation.dart';

class AstrologicalService {
  static final AstrologicalService _instance = AstrologicalService._internal();
  factory AstrologicalService() => _instance;
  AstrologicalService._internal();

  /// Holt aktuelle astrologische Einflüsse
  AstrologicalData getCurrentInfluences() {
    final now = DateTime.now().toUtc();
    return calculateAstrology(now);
  }

  /// Berechnet astrologische Daten für ein Datum
  AstrologicalData calculateAstrology(DateTime date) {
    // Berechne Sonnenpositionen
    final sunSign = _calculateSunSign(date);
    final moonSign = _calculateMoonSign(date);
    
    // Berechne Planetenpositionen (vereinfacht)
    final planets = _calculatePlanetaryPositions(date);
    
    if (kDebugMode) {
      debugPrint('🌟 Astrology Service: Sun in $sunSign, Moon in $moonSign');
    }
    
    return AstrologicalData(
      date: date,
      sunSign: sunSign,
      moonSign: moonSign,
      planetaryPositions: planets,
      sunDescription: _getSunSignDescription(sunSign),
      moonDescription: _getMoonSignDescription(moonSign),
      dailyInfluence: _getDailyInfluence(sunSign, moonSign),
    );
  }

  /// Berechnet Sonnenzeichen basierend auf Datum
  String _calculateSunSign(DateTime date) {
    final month = date.month;
    final day = date.day;
    
    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return 'Widder';
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return 'Stier';
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return 'Zwillinge';
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return 'Krebs';
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return 'Löwe';
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return 'Jungfrau';
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return 'Waage';
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return 'Skorpion';
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return 'Schütze';
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return 'Steinbock';
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return 'Wassermann';
    return 'Fische'; // Feb 19 - Mar 20
  }

  /// Berechnet vereinfachtes Mondzeichen (rotiert durch Zeichen alle 2.5 Tage)
  String _calculateMoonSign(DateTime date) {
    // Vereinfachte Berechnung: Mond durchläuft Tierkreis in ~27.3 Tagen
    final daysSinceEpoch = date.difference(DateTime(2000, 1, 1)).inDays;
    final moonCycle = 27.3;
    final position = (daysSinceEpoch % moonCycle) / moonCycle;
    
    final signs = [
      'Widder', 'Stier', 'Zwillinge', 'Krebs', 'Löwe', 'Jungfrau',
      'Waage', 'Skorpion', 'Schütze', 'Steinbock', 'Wassermann', 'Fische'
    ];
    
    final index = (position * 12).floor();
    return signs[index];
  }

  /// Berechnet vereinfachte Planetenpositionen
  Map<String, PlanetaryPosition> _calculatePlanetaryPositions(DateTime date) {
    final daysSinceEpoch = date.difference(DateTime(2000, 1, 1)).inDays;
    
    return {
      'Merkur': PlanetaryPosition(
        planet: 'Merkur',
        sign: _getPlanetSign(daysSinceEpoch, 88), // 88 Tage Umlaufzeit
        symbol: '☿',
        influence: 'Kommunikation, Denken, Lernen',
        color: 0xFFFFC107, // Amber
      ),
      'Venus': PlanetaryPosition(
        planet: 'Venus',
        sign: _getPlanetSign(daysSinceEpoch, 225), // 225 Tage Umlaufzeit
        symbol: '♀',
        influence: 'Liebe, Beziehungen, Ästhetik',
        color: 0xFFE91E63, // Pink
      ),
      'Mars': PlanetaryPosition(
        planet: 'Mars',
        sign: _getPlanetSign(daysSinceEpoch, 687), // 687 Tage Umlaufzeit
        symbol: '♂',
        influence: 'Energie, Mut, Durchsetzung',
        color: 0xFFF44336, // Red
      ),
      'Jupiter': PlanetaryPosition(
        planet: 'Jupiter',
        sign: _getPlanetSign(daysSinceEpoch, 4333), // ~12 Jahre Umlaufzeit
        symbol: '♃',
        influence: 'Wachstum, Expansion, Glück',
        color: 0xFF9C27B0, // Purple
      ),
      'Saturn': PlanetaryPosition(
        planet: 'Saturn',
        sign: _getPlanetSign(daysSinceEpoch, 10759), // ~29 Jahre Umlaufzeit
        symbol: '♄',
        influence: 'Struktur, Disziplin, Verantwortung',
        color: 0xFF607D8B, // Blue Grey
      ),
    };
  }

  /// Hilfsfunktion: Berechnet Tierkreiszeichen für Planeten
  String _getPlanetSign(int days, int orbitalPeriod) {
    final signs = [
      'Widder', 'Stier', 'Zwillinge', 'Krebs', 'Löwe', 'Jungfrau',
      'Waage', 'Skorpion', 'Schütze', 'Steinbock', 'Wassermann', 'Fische'
    ];
    
    final position = (days % orbitalPeriod) / orbitalPeriod;
    final index = (position * 12).floor();
    return signs[index % 12];
  }

  String _getSunSignDescription(String sign) {
    switch (sign) {
      case 'Widder':
        return 'Pioniergeist, Mut und Tatkraft prägen diese Zeit.';
      case 'Stier':
        return 'Stabilität, Genuss und materielle Sicherheit stehen im Fokus.';
      case 'Zwillinge':
        return 'Kommunikation, Vielseitigkeit und geistige Beweglichkeit.';
      case 'Krebs':
        return 'Emotionale Tiefe, Fürsorge und familiäre Bindungen.';
      case 'Löwe':
        return 'Selbstausdruck, Kreativität und Großzügigkeit.';
      case 'Jungfrau':
        return 'Analyse, Perfektion und praktische Lösungen.';
      case 'Waage':
        return 'Harmonie, Partnerschaft und ästhetisches Empfinden.';
      case 'Skorpion':
        return 'Transformation, Intensität und tiefe Einsichten.';
      case 'Schütze':
        return 'Expansion, Philosophie und Freiheitsdrang.';
      case 'Steinbock':
        return 'Ambition, Struktur und langfristige Ziele.';
      case 'Wassermann':
        return 'Innovation, Unabhängigkeit und Gemeinschaft.';
      case 'Fische':
        return 'Intuition, Mitgefühl und spirituelle Verbindung.';
      default:
        return '';
    }
  }

  String _getMoonSignDescription(String sign) {
    final descriptions = {
      'Widder': 'Emotionale Spontaneität und Direktheit',
      'Stier': 'Emotionale Stabilität und Genuss',
      'Zwillinge': 'Emotionale Vielseitigkeit und Neugier',
      'Krebs': 'Emotionale Tiefe und Empfindsamkeit',
      'Löwe': 'Emotionale Wärme und Großzügigkeit',
      'Jungfrau': 'Emotionale Zurückhaltung und Analyse',
      'Waage': 'Emotionale Ausgewogenheit und Harmonie',
      'Skorpion': 'Emotionale Intensität und Leidenschaft',
      'Schütze': 'Emotionale Optimismus und Freiheit',
      'Steinbock': 'Emotionale Kontrolle und Pragmatismus',
      'Wassermann': 'Emotionale Distanz und Objektivität',
      'Fische': 'Emotionale Empathie und Intuition',
    };
    return descriptions[sign] ?? '';
  }

  String _getDailyInfluence(String sunSign, String moonSign) {
    return 'Die Sonne in $sunSign verbunden mit dem Mond in $moonSign schafft eine besondere Energie für Wachstum und emotionale Klarheit.';
  }

  /// Holt Zeichen-Symbol
  String getZodiacSymbol(String sign) {
    switch (sign) {
      case 'Widder':
        return '♈';
      case 'Stier':
        return '♉';
      case 'Zwillinge':
        return '♊';
      case 'Krebs':
        return '♋';
      case 'Löwe':
        return '♌';
      case 'Jungfrau':
        return '♍';
      case 'Waage':
        return '♎';
      case 'Skorpion':
        return '♏';
      case 'Schütze':
        return '♐';
      case 'Steinbock':
        return '♑';
      case 'Wassermann':
        return '♒';
      case 'Fische':
        return '♓';
      default:
        return '⭐';
    }
  }
}

class AstrologicalData {
  final DateTime date;
  final String sunSign;
  final String moonSign;
  final Map<String, PlanetaryPosition> planetaryPositions;
  final String sunDescription;
  final String moonDescription;
  final String dailyInfluence;

  AstrologicalData({
    required this.date,
    required this.sunSign,
    required this.moonSign,
    required this.planetaryPositions,
    required this.sunDescription,
    required this.moonDescription,
    required this.dailyInfluence,
  });
}

class PlanetaryPosition {
  final String planet;
  final String sign;
  final String symbol;
  final String influence;
  final int color;

  PlanetaryPosition({
    required this.planet,
    required this.sign,
    required this.symbol,
    required this.influence,
    required this.color,
  });
}
