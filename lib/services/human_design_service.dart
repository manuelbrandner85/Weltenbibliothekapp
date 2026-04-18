// Human Design Service.
//
// Berechnet für eine Geburt (UTC + optional Ort):
//  • Personality: 13 Aktivierungen zum Zeitpunkt der Geburt
//  • Design:      13 Aktivierungen, 88° Sonnenbogen (≈ 88 Tage) zuvor
//  • Gates + Lines (pro Aktivierung)
//  • Definierte Zentren (aus aktivierten Channels)
//  • Type, Strategy, Authority, Profile (Personality-Sonne / Design-Sonne Line)
//
// Quelle Bahn-Daten: `NatalAstrology.longitudesAtJd(jd)` (Meeus-Formeln).

import 'natal_astrology_service.dart';

/// Die 13 "Bodies" (Planeten + Erde + Knoten), die Human Design nutzt.
const List<String> kHdBodies = [
  'sun',
  'earth',
  'moon',
  'north_node',
  'south_node',
  'mercury',
  'venus',
  'mars',
  'jupiter',
  'saturn',
  'uranus',
  'neptune',
  'pluto',
];

/// Wheel-Reihenfolge: startet bei 02°00′ Wassermann = 302° und geht
/// 5.625° (= 1 Tor) im Zodiak voran. 64 Tore.
const List<int> kGateWheel = [
  41, 19, 13, 49, 30, 55, 37, 63,
  22, 36, 25, 17, 21, 51, 42, 3,
  27, 24, 2, 23, 8, 20, 16, 35,
  45, 12, 15, 52, 39, 53, 62, 56,
  31, 33, 7, 4, 29, 59, 40, 64,
  47, 6, 46, 18, 48, 57, 32, 50,
  28, 44, 1, 43, 14, 34, 9, 5,
  26, 11, 10, 58, 38, 54, 61, 60,
];
const double kWheelStart = 302.0; // ° ekliptik
const double kGateSize = 360.0 / 64.0; // 5.625
const double kLineSize = kGateSize / 6.0; // 0.9375

/// Gate → Center mapping.
const Map<int, String> kGateToCenter = {
  // Head
  64: 'head', 61: 'head', 63: 'head',
  // Ajna
  47: 'ajna', 24: 'ajna', 4: 'ajna', 17: 'ajna', 43: 'ajna', 11: 'ajna',
  // Throat
  62: 'throat', 23: 'throat', 56: 'throat', 16: 'throat', 20: 'throat',
  31: 'throat', 8: 'throat', 33: 'throat', 35: 'throat', 12: 'throat',
  45: 'throat',
  // G
  1: 'g', 13: 'g', 25: 'g', 46: 'g', 2: 'g', 15: 'g', 10: 'g', 7: 'g',
  // Heart / Ego
  21: 'heart', 40: 'heart', 26: 'heart', 51: 'heart',
  // Solar Plexus
  36: 'solar_plexus', 22: 'solar_plexus', 37: 'solar_plexus',
  6: 'solar_plexus', 49: 'solar_plexus', 55: 'solar_plexus',
  30: 'solar_plexus',
  // Sacral
  34: 'sacral', 5: 'sacral', 14: 'sacral', 29: 'sacral', 59: 'sacral',
  9: 'sacral', 3: 'sacral', 42: 'sacral', 27: 'sacral',
  // Spleen
  48: 'spleen', 57: 'spleen', 44: 'spleen', 50: 'spleen', 32: 'spleen',
  28: 'spleen', 18: 'spleen',
  // Root
  53: 'root', 60: 'root', 52: 'root', 19: 'root', 39: 'root', 41: 'root',
  58: 'root', 38: 'root', 54: 'root',
};

/// 36 Channels in Human Design (jedes Paar aus zwei Gates).
const List<List<int>> kChannels = [
  [1, 8],     // Inspiration
  [2, 14],    // Beat
  [3, 60],    // Mutation
  [4, 63],    // Logic
  [5, 15],    // Rhythm
  [6, 59],    // Mating
  [7, 31],    // The Alpha
  [9, 52],    // Concentration
  [10, 20],   // Awakening
  [10, 34],   // Exploration
  [10, 57],   // Perfected Form
  [11, 56],   // Curiosity
  [12, 22],   // Openness
  [13, 33],   // The Prodigal
  [16, 48],   // The Wavelength
  [17, 62],   // Acceptance
  [18, 58],   // Judgment
  [19, 49],   // Synthesis
  [20, 34],   // Charisma
  [20, 57],   // The Brainwave
  [21, 45],   // Money Line
  [23, 43],   // Structuring
  [24, 61],   // Awareness
  [25, 51],   // Initiation
  [26, 44],   // Surrender
  [27, 50],   // Preservation
  [28, 38],   // Struggle
  [29, 46],   // Discovery
  [30, 41],   // Recognition
  [32, 54],   // Transformation
  [34, 57],   // Power
  [35, 36],   // Transitoriness
  [37, 40],   // Community
  [39, 55],   // Emoting
  [42, 53],   // Maturation
  [47, 64],   // Abstraction
];

/// 9 Zentren.
const List<String> kCenters = [
  'head',
  'ajna',
  'throat',
  'g',
  'heart',
  'sacral',
  'solar_plexus',
  'spleen',
  'root',
];

/// Die Motoren (Energie-Quellen für die Kehle).
const Set<String> kMotorCenters = {'sacral', 'heart', 'solar_plexus', 'root'};

/// Ergebnis einer einzelnen Aktivierung.
class HdActivation {
  final String body;
  final double longitude;
  final int gate;
  final int line; // 1..6
  const HdActivation({
    required this.body,
    required this.longitude,
    required this.gate,
    required this.line,
  });
  Map<String, dynamic> toJson() => {
        'body': body,
        'longitude': longitude,
        'gate': gate,
        'line': line,
      };
}

class HumanDesignResult {
  final List<HdActivation> personality;
  final List<HdActivation> design;
  final Set<int> definedGates;
  final Set<List<int>> definedChannels;
  final Set<String> definedCenters;
  final String type;
  final String authority;
  final String strategy;
  final String profile;
  final Map<String, dynamic> computation;

  HumanDesignResult({
    required this.personality,
    required this.design,
    required this.definedGates,
    required this.definedChannels,
    required this.definedCenters,
    required this.type,
    required this.authority,
    required this.strategy,
    required this.profile,
    required this.computation,
  });
}

class HumanDesign {
  /// Haupt-API.
  static HumanDesignResult compute({required DateTime birthDateUtc}) {
    final jdBirth = NatalAstrology.julianDayFromUtc(birthDateUtc);
    final jdDesign = _designJd(jdBirth);

    final personality = _activationsAt(jdBirth);
    final design = _activationsAt(jdDesign);

    final defGates = <int>{
      for (final a in personality) a.gate,
      for (final a in design) a.gate,
    };

    final defChannels = <List<int>>{};
    for (final ch in kChannels) {
      if (defGates.contains(ch[0]) && defGates.contains(ch[1])) {
        defChannels.add(ch);
      }
    }

    // Definierte Zentren: Ein Center ist definiert, wenn BEIDE Seiten
    // eines Channels davon berührt werden. Einzeln aktivierte Gates
    // definieren kein Center.
    final defCenters = <String>{};
    for (final ch in defChannels) {
      final c1 = kGateToCenter[ch[0]];
      final c2 = kGateToCenter[ch[1]];
      if (c1 != null) defCenters.add(c1);
      if (c2 != null) defCenters.add(c2);
    }

    final throatConnectedToMotor = _throatConnectedToMotor(defChannels);
    final type = _type(defCenters, throatConnectedToMotor);
    final authority = _authority(defCenters, type);
    final strategy = _strategy(type);
    final profile = _profile(personality, design);

    return HumanDesignResult(
      personality: personality,
      design: design,
      definedGates: defGates,
      definedChannels: defChannels,
      definedCenters: defCenters,
      type: type,
      authority: authority,
      strategy: strategy,
      profile: profile,
      computation: {
        'birth_utc': birthDateUtc.toIso8601String(),
        'jd_birth': jdBirth,
        'jd_design': jdDesign,
        'personality': personality.map((a) => a.toJson()).toList(),
        'design': design.map((a) => a.toJson()).toList(),
      },
    );
  }

  /// Finde JD, an dem die Sonne genau 88° vor der Geburts-Sonne stand.
  /// Newton-Iteration, tägliche Sonnenbewegung ≈ 0.9856°/Tag.
  static double _designJd(double jdBirth) {
    final sunsBirth = NatalAstrology.longitudesAtJd(jdBirth)['sun']!;
    double target = sunsBirth - 88.0;
    while (target < 0) {
      target += 360.0;
    }
    double jd = jdBirth - 88.0 * (365.25 / 360.0); // ≈ 89.3 Tage
    for (var i = 0; i < 10; i++) {
      final s = NatalAstrology.longitudesAtJd(jd)['sun']!;
      double diff = s - target;
      // in [-180, 180] normieren
      while (diff > 180) {
        diff -= 360;
      }
      while (diff < -180) {
        diff += 360;
      }
      if (diff.abs() < 0.0001) break;
      jd -= diff / 0.9856; // Grad / (Grad/Tag) = Tage
    }
    return jd;
  }

  static List<HdActivation> _activationsAt(double jd) {
    final lons = NatalAstrology.longitudesAtJd(jd);
    final out = <HdActivation>[];
    for (final body in kHdBodies) {
      final lon = lons[body]!;
      final gate = longitudeToGate(lon);
      final line = longitudeToLine(lon);
      out.add(HdActivation(
          body: body, longitude: lon, gate: gate, line: line));
    }
    return out;
  }

  /// Ekliptik-Länge → Gate (1..64).
  static int longitudeToGate(double lon) {
    var x = (lon - kWheelStart) % 360.0;
    if (x < 0) x += 360.0;
    final idx = (x / kGateSize).floor() % 64;
    return kGateWheel[idx];
  }

  /// Ekliptik-Länge → Line (1..6).
  static int longitudeToLine(double lon) {
    var x = (lon - kWheelStart) % 360.0;
    if (x < 0) x += 360.0;
    final inGate = x - (x / kGateSize).floor() * kGateSize; // 0..5.625
    return (inGate / kLineSize).floor().clamp(0, 5) + 1;
  }

  static bool _throatConnectedToMotor(Set<List<int>> defChannels) {
    // Rekursive Traversierung: gibt es einen Weg von Throat zu einem Motor
    // über aktive Channels?
    // Erst: Map Center → angrenzende Centers (via definierte Channels).
    final edges = <String, Set<String>>{};
    for (final ch in defChannels) {
      final c1 = kGateToCenter[ch[0]];
      final c2 = kGateToCenter[ch[1]];
      if (c1 == null || c2 == null || c1 == c2) continue;
      edges.putIfAbsent(c1, () => <String>{}).add(c2);
      edges.putIfAbsent(c2, () => <String>{}).add(c1);
    }
    final visited = <String>{'throat'};
    final queue = <String>['throat'];
    while (queue.isNotEmpty) {
      final cur = queue.removeLast();
      if (kMotorCenters.contains(cur)) return true;
      for (final n in edges[cur] ?? const <String>{}) {
        if (visited.add(n)) queue.add(n);
      }
    }
    return false;
  }

  static String _type(Set<String> defCenters, bool throatToMotor) {
    if (defCenters.isEmpty) return 'reflector';
    final sacral = defCenters.contains('sacral');
    if (sacral && throatToMotor) return 'manifesting_generator';
    if (sacral) return 'generator';
    if (throatToMotor) return 'manifestor';
    return 'projector';
  }

  static String _authority(Set<String> defCenters, String type) {
    if (type == 'reflector') return 'lunar';
    if (defCenters.contains('solar_plexus')) return 'emotional';
    if (defCenters.contains('sacral')) return 'sacral';
    if (defCenters.contains('spleen')) return 'splenic';
    if (defCenters.contains('heart')) return 'ego';
    if (defCenters.contains('g')) return 'self_projected';
    return 'mental';
  }

  static String _strategy(String type) {
    switch (type) {
      case 'manifestor':
        return 'inform';
      case 'generator':
      case 'manifesting_generator':
        return 'respond';
      case 'projector':
        return 'wait_invitation';
      case 'reflector':
        return 'wait_lunar';
      default:
        return 'respond';
    }
  }

  static String _profile(
      List<HdActivation> personality, List<HdActivation> design) {
    final p = personality.firstWhere((a) => a.body == 'sun').line;
    final d = design.firstWhere((a) => a.body == 'sun').line;
    return '$p/$d';
  }
}

/// UI-Labels für Centers.
const Map<String, String> kHdCenterLabels = {
  'head': 'Kopf',
  'ajna': 'Ajna',
  'throat': 'Kehle',
  'g': 'G',
  'heart': 'Herz / Ego',
  'sacral': 'Sakral',
  'solar_plexus': 'Solarplexus',
  'spleen': 'Milz',
  'root': 'Wurzel',
};

/// UI-Labels für Types.
const Map<String, String> kHdTypeLabels = {
  'manifestor': 'Manifestor',
  'generator': 'Generator',
  'manifesting_generator': 'Manifesting Generator',
  'projector': 'Projektor',
  'reflector': 'Reflektor',
};

const Map<String, String> kHdAuthorityLabels = {
  'emotional': 'Emotionale Autorität',
  'sacral': 'Sakrale Autorität',
  'splenic': 'Splenische Autorität',
  'ego': 'Ego-/Herz-Autorität',
  'self_projected': 'Selbst-projiziert',
  'lunar': 'Mond (Reflektor)',
  'mental': 'Mentale Autorität',
};

const Map<String, String> kHdStrategyLabels = {
  'inform': 'Informieren',
  'respond': 'Antworten',
  'wait_invitation': 'Auf Einladung warten',
  'wait_lunar': '28-Tage-Zyklus',
};

/// UI-Labels für Bodies (Aktivierungen).
const Map<String, String> kHdBodyLabels = {
  'sun': 'Sonne ☉',
  'earth': 'Erde ⊕',
  'moon': 'Mond ☽',
  'north_node': 'Nord-Knoten ☊',
  'south_node': 'Süd-Knoten ☋',
  'mercury': 'Merkur ☿',
  'venus': 'Venus ♀',
  'mars': 'Mars ♂',
  'jupiter': 'Jupiter ♃',
  'saturn': 'Saturn ♄',
  'uranus': 'Uranus ♅',
  'neptune': 'Neptun ♆',
  'pluto': 'Pluto ♇',
};
