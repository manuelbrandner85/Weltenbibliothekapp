/// ☯️ POLARITÄTS-TOOL ENGINE
/// Basiert auf TCM Yin-Yang Balance & 4 Imbalances
library;

import '../../models/energie_profile.dart';

class PolarityToolEngine {
  static const String version = '1.0.0';
  
  /// Berechne Polaritätsprofil
  static Map<String, dynamic> calculatePolarityProfile(EnergieProfile profile) {
    // Yin-Yang aus Name
    final yinYang = _calculateYinYang(profile.firstName, profile.lastName);
    
    // Spannungsachsen
    final tensions = _calculateTensionAxes(profile.birthDate);
    
    // Balance-Status
    final balance = _calculateBalanceStatus(yinYang['yin']!, yinYang['yang']!);
    
    // Dominanzverteilung
    final dominance = _calculateDominance(yinYang, tensions);
    
    // Integrationspunkte
    final integration = _calculateIntegrationPoints(balance);
    
    // Übersteuerung
    final overload = _checkOverload(yinYang, tensions);
    
    return {
      'yinWert': yinYang['yin'],
      'yangWert': yinYang['yang'],
      'balanceStatus': balance,
      'dominanterPol': yinYang['yin']! > yinYang['yang']! ? 'Yin (Empfangend)' : 'Yang (Aktiv)',
      'spannungsachsen': tensions,
      'dominanzverteilung': dominance,
      'integrationspunkte': integration,
      'uebersteuerung': overload,
      'interpretation': _getInterpretation(profile.firstName, yinYang, balance),
      'empfehlung': _getRecommendation(yinYang, balance),
    };
  }
  
  static Map<String, double> _calculateYinYang(String first, String last) {
    final fullName = (first + last).toUpperCase();
    final vowels = 'AEIOU';
    
    int yinCount = 0;
    int yangCount = 0;
    
    for (var char in fullName.split('')) {
      if (vowels.contains(char)) {
        yinCount++;
      } else if (char.codeUnitAt(0) >= 65 && char.codeUnitAt(0) <= 90) {
        yangCount++;
      }
    }
    
    final total = yinCount + yangCount;
    if (total == 0) return {'yin': 50.0, 'yang': 50.0};
    
    return {
      'yin': (yinCount / total * 100),
      'yang': (yangCount / total * 100),
    };
  }
  
  static String _calculateBalanceStatus(double yin, double yang) {
    final diff = (yin - yang).abs();
    
    if (diff < 10) return 'Perfekte Balance ⚖️';
    if (diff < 20) return 'Harmonisch ausgewogen 🌓';
    if (diff < 30) return 'Leichte Tendenz 🌗';
    return 'Starke Polarität 🌑🌕';
  }
  
  static List<String> _calculateTensionAxes(DateTime birthDate) {
    final month = birthDate.month;
    final axes = <String>[];
    
    // Jahreszeit bestimmt Spannung
    if (month >= 3 && month <= 5) {
      axes.add('Frühling: Wachstum ↔ Geduld');
    } else if (month >= 6 && month <= 8) {
      axes.add('Sommer: Expansion ↔ Bewahrung');
    } else if (month >= 9 && month <= 11) {
      axes.add('Herbst: Ernte ↔ Loslassen');
    } else {
      axes.add('Winter: Rückzug ↔ Erneuerung');
    }
    
    // Mondzahl für zusätzliche Achse
    final daySum = birthDate.day % 4;
    if (daySum == 0) axes.add('Ordnung ↔ Chaos');
    if (daySum == 1) axes.add('Kontrolle ↔ Hingabe');
    if (daySum == 2) axes.add('Aktion ↔ Rezeption');
    if (daySum == 3) axes.add('Expansion ↔ Kontraktion');
    
    return axes;
  }
  
  static Map<String, double> _calculateDominance(Map<String, double> yinYang, List<String> tensions) {
    return {
      'aktivDominanz': yinYang['yang']!,
      'passivDominanz': yinYang['yin']!,
      'spannungsIntensitaet': tensions.length * 25.0,
    };
  }
  
  static List<String> _calculateIntegrationPoints(String balance) {
    if (balance.contains('Perfekte')) {
      return [
        '✨ Du lebst bereits in der Mitte',
        '🎯 Halte diese Balance bewusst',
      ];
    }
    return [
      '🌱 Erkenne beide Pole in dir',
      '🔄 Übe den Wechsel zwischen Aktivität und Ruhe',
      '💫 Die Mitte ist dein Ziel, nicht die Extreme',
    ];
  }
  
  static String _checkOverload(Map<String, double> yinYang, List<String> tensions) {
    final diff = (yinYang['yin']! - yinYang['yang']!).abs();
    
    if (diff > 40) {
      if (yinYang['yin']! > yinYang['yang']!) {
        return '⚠️ Yin-Übersteuerung: Zu viel Passivität, braucht Yang-Aktivierung';
      }
      return '⚠️ Yang-Übersteuerung: Zu viel Aktivität, braucht Yin-Ruhe';
    }
    return '✅ Keine Übersteuerung - gesunde Polarität';
  }
  
  static String _getInterpretation(String name, Map<String, double> yinYang, String balance) {
    final yinPercent = yinYang['yin']!.toInt();
    final yangPercent = yinYang['yang']!.toInt();
    
    if (balance.contains('Perfekte')) {
      return '$name, du verkörperst eine wunderbare Balance! Mit $yinPercent% Yin und $yangPercent% Yang lebst du die harmonische Mitte. Du kannst sowohl empfangen als auch geben, ruhen und handeln.';
    }
    
    if (yinYang['yin']! > yinYang['yang']!) {
      return '$name, deine Yin-Energie dominiert mit $yinPercent%. Du bist intuitiv, empfangend und reflektierend. Erlaube dir auch mal aktive Yang-Momente!';
    }
    
    return '$name, deine Yang-Energie führt mit $yangPercent%. Du bist aktiv, gestaltend und vorwärtsgerichtet. Gönn dir auch Yin-Phasen der Stille!';
  }
  
  static String _getRecommendation(Map<String, double> yinYang, String balance) {
    if (balance.contains('Perfekte')) {
      return '🎯 Empfehlung: Halte deine Balance durch achtsames Leben. Beobachte, wann du welche Energie brauchst.';
    }
    
    if (yinYang['yin']! > yinYang['yang']!) {
      return '🔥 Empfehlung: Aktiviere deine Yang-Seite durch Sport, kreatives Gestalten oder mutige Entscheidungen.';
    }
    
    return '🌙 Empfehlung: Stärke deine Yin-Seite durch Meditation, sanfte Bewegung (Yoga, Tai Chi) und Naturverbindung.';
  }
}
