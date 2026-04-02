/// 🌟 COMPLETE ENGINES - Module 5-11 kompakt
library;
import '../../models/energie_profile.dart';
import '../../models/spirit_complete.dart';

class CompleteEngines {
  static const String version = '1.0.0';

  // MODUL 5: INNERE LANDKARTEN
  static SpiritInnerMaps calculateInnerMaps(EnergieProfile profile) {
    final now = DateTime.now();
    final age = now.year - profile.birthDate.year;
    
    return SpiritInnerMaps(
      version: version,
      calculatedAt: now,
      profileName: '${profile.firstName} ${profile.lastName}',
      currentPosition: age < 30 ? 'Aufbau-Phase' : age < 50 ? 'Meisterschaft' : 'Weisheit',
      developmentAxes: ['Persönlich → Universal', 'Ego → Selbst'],
      shadowZones: ['Unentdeckte Potenziale', 'Verdrängte Ängste'],
      transitionGates: ['28 Jahre', '42 Jahre', '56 Jahre'],
      processDirection: 'Aufwärts-Spirale',
      interpretation: 'Du bewegst dich auf deiner inneren Landkarte vorwärts',
    );
  }

  // MODUL 6: ZYKLISCHE META-EBENEN
  static SpiritCycles calculateCycles(EnergieProfile profile) {
    final now = DateTime.now();
    final age = now.year - profile.birthDate.year;
    final personalYear = _calculatePersonalYear(profile.birthDate, now);
    
    return SpiritCycles(
      version: version,
      calculatedAt: now,
      profileName: '${profile.firstName} ${profile.lastName}',
      shortCycle: personalYear,
      mediumCycle: (age ~/ 7) % 4 + 1,
      longCycle: (age ~/ 28) % 3 + 1,
      overlappingCycles: [
        '9-Jahres-Zyklus: Jahr $personalYear',
        '7-Jahres-Zyklus: Phase ${(age % 7) + 1}',
      ],
      currentIntensity: personalYear == 1 || personalYear == 9 ? 'Hoch' : 'Moderat',
      interpretation: 'Mehrere Zyklen überlappen sich aktuell',
    );
  }

  // MODUL 7: ORIENTIERUNGS- & ENTWICKLUNGSMODELLE
  static SpiritOrientation calculateOrientation(EnergieProfile profile) {
    final now = DateTime.now();
    final age = now.year - profile.birthDate.year;
    
    return SpiritOrientation(
      version: version,
      calculatedAt: now,
      profileName: '${profile.firstName} ${profile.lastName}',
      currentPhase: age < 28 ? 'Jugend & Exploration' : age < 56 ? 'Reife & Produktivität' : 'Weisheit & Integration',
      completedPhases: age > 28 ? ['Jugendphase'] : [],
      potentialFields: ['Spirituelles Wachstum', 'Kreative Expression'],
      maturityDegree: (age / 60.0 * 100).clamp(0, 100),
      processIntensity: 'Aktiv',
      interpretation: 'Du befindest dich in einer aktiven Entwicklungsphase',
    );
  }

  // MODUL 8: META-SPIEGEL
  static SpiritMetaMirror calculateMetaMirror(EnergieProfile profile) {
    final now = DateTime.now();
    
    return SpiritMetaMirror(
      version: version,
      calculatedAt: now,
      profileName: '${profile.firstName} ${profile.lastName}',
      systemMirrors: ['Numerologie spiegelt Archetypen', 'Chakren spiegeln Gematria'],
      recurringThemes: ['Macht & Transformation', 'Freiheit & Struktur'],
      contradictions: ['Sicherheit vs. Abenteuer'],
      resonanceAmplifications: ['Kreativität verstärkt sich'],
      focusDensity: 'Mittel',
      interpretation: 'Verschiedene Systeme zeigen ähnliche Themen',
    );
  }

  // MODUL 9: WAHRNEHMUNG
  static SpiritPerception calculatePerception(EnergieProfile profile) {
    final now = DateTime.now();
    final age = now.year - profile.birthDate.year;
    
    return SpiritPerception(
      version: version,
      calculatedAt: now,
      profileName: '${profile.firstName} ${profile.lastName}',
      perceptionFilters: ['Vergangene Erfahrungen', 'Kulturelle Prägung'],
      meaningPatterns: ['Alles hat einen Sinn', 'Synchronizität'],
      thinkingStyle: age < 35 ? 'Linear' : 'Systemisch',
      fixationIndicators: ['Festhalten an Überzeugungen'],
      flexibilityDegree: (age / 60.0 * 80).clamp(0, 100),
      interpretation: 'Deine Wahrnehmung wird flexibler mit dem Alter',
    );
  }

  // MODUL 10: META-JOURNAL
  static SpiritMetaJournal calculateMetaJournal(EnergieProfile profile) {
    final now = DateTime.now();
    
    return SpiritMetaJournal(
      version: version,
      calculatedAt: now,
      profileName: '${profile.firstName} ${profile.lastName}',
      patternLog: ['Wiederholende Träume', 'Synchronizitäten'],
      cycleObservations: ['Energie steigt im Frühling'],
      symbolTracking: ['Schmetterlinge tauchen auf'],
      resonanceNotes: ['Starke Verbindung zu Wasser'],
      interpretation: 'Deine Selbstbeobachtung wächst',
    );
  }

  // MODUL 11: DATENSTEUERUNG
  static SpiritDataControl calculateDataControl(EnergieProfile profile) {
    final now = DateTime.now();
    
    return SpiritDataControl(
      version: version,
      calculatedAt: now,
      profileName: '${profile.firstName} ${profile.lastName}',
      activeModules: {
        'energyField': true,
        'polarities': true,
        'transformation': true,
        'unconscious': true,
        'innerMaps': true,
        'cycles': true,
        'orientation': true,
        'metaMirror': true,
        'perception': true,
        'metaJournal': true,
      },
      modulePriority: {
        'energyField': 1,
        'polarities': 2,
        'transformation': 3,
      },
      complexityLevel: 'Vollständig',
      interpretation: 'Alle Spirit-Module sind aktiviert',
    );
  }

  // Helper
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
