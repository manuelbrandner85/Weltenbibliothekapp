/// 🧠 UNCONSCIOUS ENGINE - Kompakte Version
library;
import '../../models/energie_profile.dart';
import '../../models/spirit_unconscious.dart';

class UnconsciousEngine {
  static const String version = '1.0.0';

  static SpiritUnconscious calculateUnconscious(EnergieProfile profile) {
    final now = DateTime.now();
    final age = now.year - profile.birthDate.year;
    final personalYear = _calculatePersonalYear(profile.birthDate, now);
    
    final patterns = _analyzePatterns(age, personalYear);
    final awarenessLevel = (age / 60.0 * 70 + personalYear / 9.0 * 30).clamp(0.0, 100.0);

    return SpiritUnconscious(
      version: version,
      calculatedAt: now,
      profileName: '${profile.firstName} ${profile.lastName}',
      repeatingPatterns: patterns['repeating']!,
      projectionThemes: patterns['projection']!,
      repressionIndicators: patterns['repression']!,
      conflictAxes: patterns['conflict']!,
      mirrorMechanisms: patterns['mirror']!,
      integrationResistances: patterns['resistance']!,
      awarenessMarkers: patterns['awareness']!,
      unconsciousLeadThemes: patterns['themes']!,
      dominantPattern: patterns['repeating']!.first,
      awarenessLevel: awarenessLevel,
      interpretation: _getInterpretation(awarenessLevel),
    );
  }

  static Map<String, List<String>> _analyzePatterns(int age, int year) {
    return {
      'repeating': [
        'Wiederholung von Beziehungsmustern',
        'Karriere-Zyklen',
        if (year == 7 || year == 8) 'Rückzug in alte Gewohnheiten',
      ],
      'projection': [
        'Unerfüllte Wünsche auf andere projizieren',
        if (age < 35) 'Elternthemen',
        if (age >= 35) 'Autoritätsthemen',
      ],
      'repression': [
        if (year % 3 == 0) 'Verdrängte Emotionen',
        'Nicht gelebte Potenziale',
      ],
      'conflict': [
        'Sicherheit vs. Freiheit',
        'Anpassung vs. Authentizität',
      ],
      'mirror': [
        'Was du an anderen kritisierst, ist in dir',
        'Triggerpunkte zeigen Wachstumschancen',
      ],
      'resistance': [
        'Angst vor Veränderung',
        if (age < 30) 'Festhalten an Jugendidentität',
      ],
      'awareness': [
        if (age > 40) 'Selbstreflexion nimmt zu',
        'Bewusstheit für Muster wächst',
      ],
      'themes': [
        'Macht & Ohnmacht',
        'Liebe & Verlust',
        'Erfolg & Versagen',
      ],
    };
  }

  static String _getInterpretation(double level) {
    if (level > 70) {
      return 'Deine Bewusstheit für unbewusste Muster ist hoch. Du erkennst die Mechanismen.';
    } else if (level > 40) {
      return 'Du beginnst, deine Muster zu erkennen. Der Prozess der Bewusstwerdung läuft.';
    } else {
      return 'Viele Muster laufen noch unbewusst. Achte auf Wiederholungen in deinem Leben.';
    }
  }

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
}
