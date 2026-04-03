/// 🌟 ENERGETISCHE FELDANALYSE - BERECHNUNGS-ENGINE
/// 
/// Berechnet alle Aspekte des persönlichen Energiefelds basierend auf:
/// - Numerologischen Kern-Zahlen
/// - Aktuellen Zyklen
/// - Zeitlichen Mustern
/// 
/// WICHTIG: Alle Berechnungen sind symbolisch und modellhaft!
library;

import 'dart:math' as math;
import '../../models/energie_profile.dart';
import '../../models/spirit_energy_field.dart';
import 'numerology_engine.dart';

class EnergyFieldEngine {
  /// Hauptmethode: Berechnet vollständiges Energiefeld
  static SpiritEnergyField calculateEnergyField(EnergieProfile profile) {
    // Basis-Numerologie berechnen
    final lifePath = NumerologyEngine.calculateLifePath(profile.birthDate);
    final soulNumber = NumerologyEngine.calculateSoulNumber(profile.firstName, profile.lastName);
    final expressionNumber = NumerologyEngine.calculateExpressionNumber(profile.firstName, profile.lastName);
    final personalityNumber = NumerologyEngine.calculatePersonalityNumber(profile.firstName, profile.lastName);
    
    // Aktuelle Zyklen
    final now = DateTime.now();
    final personalYear = NumerologyEngine.calculatePersonalYear(profile.birthDate, now);
    final personalMonth = NumerologyEngine.calculatePersonalMonth(profile.birthDate, now);
// UNUSED: final personalDay = NumerologyEngine.calculatePersonalDay(profile.birthDate, now);
    
    // 1. Gesamt-Energiefeld berechnen
    final overallStrength = _calculateOverallFieldStrength(
      lifePath, soulNumber, expressionNumber, personalYear
    );
    final fieldQuality = _determineFieldQuality(overallStrength, personalYear);
    final fieldColor = _determineFieldColor(lifePath, soulNumber);
    
    // 2. Dominante Frequenzen
    final dominantFreqs = _calculateDominantFrequencies(
      lifePath, soulNumber, expressionNumber, personalityNumber, personalYear
    );
    final primaryFreq = dominantFreqs.first;
    
    // 3. Schwache Felder
    final weakFields = _calculateWeakFields(
      lifePath, soulNumber, expressionNumber, personalityNumber
    );
    final instabilityZones = _detectInstabilityZones(personalYear, personalMonth);
    
    // 4. Überlagerungen
    final overlays = _calculateEnergyOverlays(
      lifePath, expressionNumber, personalYear, personalMonth
    );
    
    // 5. Feldkohärenz
    final coherence = _calculateCoherence(
      lifePath, soulNumber, expressionNumber, personalYear
    );
    final coherenceState = _determineCoherenceState(coherence);
    final chaosIndex = 1.0 - coherence;
    
    // 6. Energiefluss-Achsen
    final flowAxes = _calculateFlowAxes(lifePath, personalYear, personalMonth);
    final flowPattern = _determineFlowPattern(flowAxes);
    
    // 7. Resonanzdichte
    final resonanceDensity = _calculateResonanceDensity(
      lifePath, soulNumber, expressionNumber
    );
    final resonancePoints = _identifyResonancePoints(
      lifePath, personalYear, personalMonth
    );
    
    // 8. Feldentwicklung
    final evolution = _calculateFieldEvolution(
      profile.birthDate, lifePath, personalYear
    );
    final currentPhase = _determineCurrentPhase(personalYear, evolution);
    final nextPhase = _predictNextPhase(personalYear, lifePath);
    
    return SpiritEnergyField(
      overallFieldStrength: overallStrength,
      fieldQuality: fieldQuality,
      fieldColor: fieldColor,
      dominantFrequencies: dominantFreqs,
      primaryFrequency: primaryFreq,
      weakFields: weakFields,
      instabilityZones: instabilityZones,
      overlays: overlays,
      overlayComplexity: overlays.length,
      coherenceLevel: coherence,
      coherenceState: coherenceState,
      chaosIndex: chaosIndex,
      flowAxes: flowAxes,
      flowPattern: flowPattern,
      resonanceDensity: resonanceDensity,
      resonancePoints: resonancePoints,
      evolution: evolution,
      currentPhase: currentPhase,
      nextPhase: nextPhase,
      calculatedAt: DateTime.now(),
    );
  }
  
  // === HILFSMETHODEN ===
  
  static double _calculateOverallFieldStrength(
    int lifePath, int soul, int expression, int year
  ) {
    // Komplexe Formel basierend auf allen Zahlen
    final baseStrength = (lifePath + soul + expression) / 27.0; // Normalisiert auf 0-1
    final yearModifier = (year % 9) / 9.0;
    final combined = (baseStrength * 0.7) + (yearModifier * 0.3);
    
    // Meisterzahlen verstärken
    if (lifePath == 11 || lifePath == 22 || lifePath == 33) {
      return math.min(1.0, combined * 1.2);
    }
    
    return combined.clamp(0.0, 1.0);
  }
  
  static String _determineFieldQuality(double strength, int year) {
    if (strength > 0.8) {
      return year % 2 == 0 ? 'Hochstabil' : 'Dynamisch-Kraftvoll';
    } else if (strength > 0.6) {
      return 'Ausgewogen';
    } else if (strength > 0.4) {
      return 'Entwickelnd';
    } else {
      return 'Neuformierend';
    }
  }
  
  static String _determineFieldColor(int lifePath, int soul) {
    // Farbzuordnung basierend auf Zahlen
    final combined = (lifePath + soul) % 12;
    const colors = [
      'Tiefviolett', 'Indigoblau', 'Himmelblau', 'Türkis',
      'Smaragdgrün', 'Gelbgrün', 'Goldgelb', 'Bernstein',
      'Orange', 'Korallenrot', 'Magenta', 'Silbergrau'
    ];
    return colors[combined];
  }
  
  static List<EnergyFrequency> _calculateDominantFrequencies(
    int lifePath, int soul, int expression, int personality, int year
  ) {
    final frequencies = <EnergyFrequency>[];
    
    // Frequenz 1: Basierend auf Lebenszahl
    frequencies.add(_createFrequencyFromNumber(lifePath, 'Lebensweg-Frequenz'));
    
    // Frequenz 2: Basierend auf Seelenzahl
    frequencies.add(_createFrequencyFromNumber(soul, 'Seelen-Frequenz'));
    
    // Frequenz 3: Basierend auf Ausdruckszahl
    frequencies.add(_createFrequencyFromNumber(expression, 'Ausdruck-Frequenz'));
    
    // Frequenz 4: Jahres-Frequenz
    frequencies.add(_createFrequencyFromNumber(year, 'Jahres-Frequenz'));
    
    // Nach Stärke sortieren
    frequencies.sort((a, b) => b.strength.compareTo(a.strength));
    
    return frequencies.take(4).toList();
  }
  
  static EnergyFrequency _createFrequencyFromNumber(int number, String type) {
    final strength = (number / 11.0).clamp(0.0, 1.0);
    final quality = strength > 0.7 ? 'Hoch' : strength > 0.4 ? 'Mittel' : 'Entwickelnd';
    
    final names = {
      1: 'Initiator-Energie',
      2: 'Harmonisierende Energie',
      3: 'Kreative Energie',
      4: 'Stabilisierende Energie',
      5: 'Transformative Energie',
      6: 'Fürsorgliche Energie',
      7: 'Mystische Energie',
      8: 'Manifestations-Energie',
      9: 'Vollendungs-Energie',
      11: 'Erleuchtungs-Energie',
      22: 'Meisterbaumeister-Energie',
      33: 'Meisterlehrer-Energie',
    };
    
    final descriptions = {
      1: 'Neue Wege bahnen, führen, initiieren',
      2: 'Ausgleichen, vermitteln, verbinden',
      3: 'Erschaffen, ausdrücken, inspirieren',
      4: 'Strukturieren, fundieren, stabilisieren',
      5: 'Verändern, befreien, erneuern',
      6: 'Heilen, nähren, harmonisieren',
      7: 'Erforschen, verstehen, erkennen',
      8: 'Manifestieren, gestalten, verwirklichen',
      9: 'Vollenden, integrieren, transzendieren',
      11: 'Erleuchten, inspirieren, erwecken',
      22: 'Große Visionen verwirklichen',
      33: 'Bedingungslos lieben und lehren',
    };
    
    final colors = {
      1: 'Feuerrot', 2: 'Pastellrosa', 3: 'Sonnengelb', 4: 'Erdbraun',
      5: 'Türkis', 6: 'Rosenquarz', 7: 'Violett', 8: 'Gold',
      9: 'Regenbogen', 11: 'Weißgold', 22: 'Platin', 33: 'Kristallklar',
    };
    
    final keywords = {
      1: ['Führung', 'Mut', 'Neuanfang'],
      2: ['Harmonie', 'Partnerschaft', 'Intuition'],
      3: ['Kreativität', 'Freude', 'Kommunikation'],
      4: ['Stabilität', 'Ordnung', 'Sicherheit'],
      5: ['Freiheit', 'Abenteuer', 'Wandel'],
      6: ['Liebe', 'Fürsorge', 'Verantwortung'],
      7: ['Weisheit', 'Spiritualität', 'Analyse'],
      8: ['Macht', 'Erfolg', 'Fülle'],
      9: ['Mitgefühl', 'Vollendung', 'Universalität'],
      11: ['Erleuchtung', 'Vision', 'Inspiration'],
      22: ['Meisterschaft', 'Große Ziele', 'Vermächtnis'],
      33: ['Bedingungslose Liebe', 'Selbstlosigkeit', 'Heilung'],
    };
    
    return EnergyFrequency(
      name: names[number] ?? 'Unbekannte Energie',
      strength: strength,
      quality: quality,
      color: colors[number] ?? 'Neutral',
      description: descriptions[number] ?? 'Spezielle Energie',
      keywords: keywords[number] ?? ['Einzigartig'],
    );
  }
  
  static List<EnergyFrequency> _calculateWeakFields(
    int lifePath, int soul, int expression, int personality
  ) {
    // Identifiziere fehlende oder unterentwickelte Bereiche
    final allNumbers = {lifePath, soul, expression, personality};
    final weakNumbers = <int>[];
    
    // Prüfe welche Zahlen 1-9 NICHT in den Kernzahlen vorkommen
    for (int i = 1; i <= 9; i++) {
      if (!allNumbers.contains(i)) {
        weakNumbers.add(i);
      }
    }
    
    // Erstelle Frequenzen mit reduzierter Stärke
    return weakNumbers.take(3).map((numVal) {
      final freq = _createFrequencyFromNumber(numVal, 'Schwaches Feld');
      return EnergyFrequency(
        name: freq.name,
        strength: freq.strength * 0.3, // Reduzierte Stärke
        quality: 'Zu entwickeln',
        color: freq.color,
        description: 'Unterentwickelter Bereich: ${freq.description}',
        keywords: freq.keywords,
      );
    }).toList();
  }
  
  static List<String> _detectInstabilityZones(int year, int month) {
    final zones = <String>[];
    
    // Jahr 5 = Veränderungsenergie = potenzielle Instabilität
    if (year == 5) zones.add('Veränderungs-Turbulenzen');
    
    // Ungerade Monate = mehr Dynamik
    if (month % 2 != 0) zones.add('Monatliche Schwankungen');
    
    // Kombinationen
    if (year == 9) zones.add('Vollendungs-Unruhe');
    if (year == 1) zones.add('Neuanfangs-Unsicherheit');
    
    return zones.isEmpty ? ['Stabile Phase'] : zones;
  }
  
  static List<EnergyOverlay> _calculateEnergyOverlays(
    int lifePath, int expression, int year, int month
  ) {
    final overlays = <EnergyOverlay>[];
    
    // Oberflächliche Ebene (Monat + Tag)
    overlays.add(EnergyOverlay(
      layer: 'Tagesbewusstsein',
      energies: ['Monatsenergie $month', 'Tagesimpuls'],
      intensity: 0.4 + (month / 12.0) * 0.3,
      effect: month % 2 == 0 ? 'Verstärkend' : 'Kontrastierend',
    ));
    
    // Mittlere Ebene (Jahr)
    overlays.add(EnergyOverlay(
      layer: 'Jahresebene',
      energies: ['Jahresenergie $year', 'Zyklusthema'],
      intensity: 0.6 + (year / 9.0) * 0.2,
      effect: year == lifePath ? 'Resonant' : 'Ergänzend',
    ));
    
    // Tiefe Ebene (Lebenszahl)
    overlays.add(EnergyOverlay(
      layer: 'Lebenskern',
      energies: ['Lebensweg $lifePath', 'Seelenmission'],
      intensity: 0.8 + (lifePath / 11.0) * 0.2,
      effect: 'Grundierend',
    ));
    
    return overlays;
  }
  
  static double _calculateCoherence(int lifePath, int soul, int expression, int year) {
    // Wie gut harmonieren die verschiedenen Zahlen?
    final numbers = [lifePath, soul, expression, year];
    
    // Ähnlichkeit der Zahlen
    final avg = numbers.reduce((a, b) => a + b) / numbers.length;
    final variance = numbers.map((n) => math.pow(n - avg, 2)).reduce((a, b) => a + b) / numbers.length;
    
    // Niedrige Varianz = hohe Kohärenz
    final coherence = 1.0 - (math.sqrt(variance) / 9.0);
    
    return coherence.clamp(0.0, 1.0);
  }
  
  static String _determineCoherenceState(double coherence) {
    if (coherence > 0.8) return 'Hoch kohärent - Harmonisch';
    if (coherence > 0.6) return 'Ausgeglichen';
    if (coherence > 0.4) return 'Dynamisch-Vielfältig';
    return 'Komplex-Turbulent';
  }
  
  static List<EnergyAxis> _calculateFlowAxes(int lifePath, int year, int month) {
    final axes = <EnergyAxis>[];
    
    // Hauptachse: Aufwärts vs. Abwärts
    final upwardFlow = (lifePath + year) % 2 == 0;
    axes.add(EnergyAxis(
      direction: upwardFlow ? 'Aufwärts-Expansiv' : 'Abwärts-Vertiefend',
      flowRate: 0.5 + (year / 9.0) * 0.5,
      quality: year == 5 ? 'Turbulent' : 'Fließend',
      areas: upwardFlow 
        ? ['Spirituelles Wachstum', 'Bewusstseinserweiterung']
        : ['Erdung', 'Innere Tiefe'],
    ));
    
    // Horizontale Achse
    axes.add(EnergyAxis(
      direction: 'Horizontal-Verbindend',
      flowRate: 0.4 + (month / 12.0) * 0.4,
      quality: 'Wellenförmig',
      areas: ['Beziehungen', 'Kommunikation', 'Austausch'],
    ));
    
    return axes;
  }
  
  static String _determineFlowPattern(List<EnergyAxis> axes) {
    if (axes.isEmpty) return 'Statisch';
    
    final upward = axes.any((a) => a.direction.contains('Aufwärts'));
    final horizontal = axes.any((a) => a.direction.contains('Horizontal'));
    
    if (upward && horizontal) return 'Spiralförmig-Aufsteigend';
    if (upward) return 'Linear-Aufwärts';
    return 'Zirkulär-Integrierend';
  }
  
  static double _calculateResonanceDensity(int lifePath, int soul, int expression) {
    // Wie viele "Resonanzpunkte" gibt es?
    final sum = lifePath + soul + expression;
    final density = (sum % 27) / 27.0;
    
    // Meisterzahlen erhöhen Dichte
    int masterCount = 0;
    if (lifePath == 11 || lifePath == 22 || lifePath == 33) masterCount++;
    if (soul == 11 || soul == 22 || soul == 33) masterCount++;
    if (expression == 11 || expression == 22 || expression == 33) masterCount++;
    
    return (density + (masterCount * 0.15)).clamp(0.0, 1.0);
  }
  
  static List<String> _identifyResonancePoints(int lifePath, int year, int month) {
    final points = <String>[];
    
    if (lifePath == year) points.add('Jahres-Lebensweg-Resonanz');
    if (lifePath == month) points.add('Monats-Lebensweg-Resonanz');
    if (year == month) points.add('Jahr-Monat-Synchron');
    
    // Numerologische Hotspots
    if (lifePath == 11 || lifePath == 22 || lifePath == 33) {
      points.add('Meisterzahl-Hotspot');
    }
    
    if (year == 9) points.add('Vollendungs-Resonanz');
    if (year == 1) points.add('Neuanfangs-Resonanz');
    
    return points.isEmpty ? ['Diffuse Resonanz'] : points;
  }
  
  static FieldEvolution _calculateFieldEvolution(
    DateTime birthDate, int lifePath, int year
  ) {
    final now = DateTime.now();
    final age = now.year - birthDate.year;
    
    // Erstelle historische Snapshots (vereinfacht)
    final history = <FieldSnapshot>[];
    
    // Jugendphase (0-28)
    if (age >= 28) {
      history.add(FieldSnapshot(
        timestamp: DateTime(birthDate.year + 14),
        fieldStrength: 0.3 + (lifePath / 11.0) * 0.3,
        phase: 'Jugend-Entwicklung',
      ));
    }
    
    // Reifephase (28-56)
    if (age >= 40) {
      history.add(FieldSnapshot(
        timestamp: DateTime(birthDate.year + 40),
        fieldStrength: 0.6 + (lifePath / 11.0) * 0.2,
        phase: 'Reife-Stabilisierung',
      ));
    }
    
    // Aktuell
    history.add(FieldSnapshot(
      timestamp: now,
      fieldStrength: 0.5 + (year / 9.0) * 0.4,
      phase: 'Gegenwart',
    ));
    
    // Trend bestimmen
    String trend = 'Stabil';
    if (history.length >= 2) {
      final last = history[history.length - 1].fieldStrength;
      final prev = history[history.length - 2].fieldStrength;
      if (last > prev + 0.1) {
        trend = 'Steigend';
      } else if (last < prev - 0.1) {
        trend = 'Fallend';
      } else if ((last - prev).abs() < 0.05) {
        trend = 'Stabil';
      } else {
        trend = 'Oszillierend';
      }
    }
    
    return FieldEvolution(
      history: history,
      trend: trend,
      changeRate: year == 5 ? 0.8 : 0.4,
      milestones: _identifyMilestones(age, lifePath),
    );
  }
  
  static List<String> _identifyMilestones(int age, int lifePath) {
    final milestones = <String>[];
    
    if (age >= 28) milestones.add('Übergang zur Reifephase (28 Jahre)');
    if (age >= 56) milestones.add('Beginn der Weisheitsphase (56 Jahre)');
    if (age % lifePath == 0 && age > 0) {
      milestones.add('Lebenszahl-Zyklus-Abschluss ($age Jahre)');
    }
    
    return milestones.isEmpty ? ['Entwicklungsphase'] : milestones;
  }
  
  static String _determineCurrentPhase(int year, FieldEvolution evolution) {
    final trend = evolution.trend;
    
    if (year == 1) return 'Neuanfangs-Phase';
    if (year == 5) return 'Transformations-Phase';
    if (year == 9) return 'Vollendungs-Phase';
    
    if (trend == 'Steigend') return 'Aufbau-Phase';
    if (trend == 'Fallend') return 'Loslöse-Phase';
    
    return 'Integrations-Phase';
  }
  
  static String _predictNextPhase(int year, int lifePath) {
    final nextYear = (year % 9) + 1;
    
    if (nextYear == 1) return 'Neuanfang-Energie kommt';
    if (nextYear == 5) return 'Veränderungs-Welle nähert sich';
    if (nextYear == 9) return 'Vollendungs-Zyklusende voraus';
    if (nextYear == lifePath) return 'Resonanz-Jahr steht bevor';
    
    return 'Kontinuierliche Entwicklung';
  }
}
