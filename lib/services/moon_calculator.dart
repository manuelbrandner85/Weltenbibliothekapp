/// Precise Moon Calculator
///
/// Meeus-basierte astronomische Berechnungen:
///  - Kapitel 25: scheinbare Länge der Sonne
///  - Kapitel 47: geozentrische ekliptikale Länge des Mondes
///    (reduzierte Reihe, ~1 arcmin Genauigkeit)
///  - Kapitel 49: exakte Zeitpunkte von Neu- und Vollmond
///
/// Liefert: Phase, Beleuchtung, Mondzeichen (tropisch),
/// Element, nächste Neu-/Vollmond-Zeitpunkte, nächster
/// Zeichenwechsel.
library;

import 'dart:math' as math;

// ═══════════════════════════════════════════════════════════
// Konstanten
// ═══════════════════════════════════════════════════════════

const double _deg2rad = math.pi / 180.0;

/// Unix-Epoch (1970-01-01 00:00 UTC) in JD.
const double _jdUnixEpoch = 2440587.5;

/// Millisekunden pro Tag.
const double _msPerDay = 86400000.0;

/// Referenz-Epoch J2000.0 (2000-01-01 12:00 TT) in JD.
const double _jdJ2000 = 2451545.0;

// ═══════════════════════════════════════════════════════════
// Tierkreiszeichen (tropisch, Aries = 0°)
// ═══════════════════════════════════════════════════════════

/// Deutsche Namen der 12 Tierkreiszeichen, beginnend mit Widder.
const List<String> zodiacNames = [
  'Widder', 'Stier', 'Zwillinge', 'Krebs', 'Löwe', 'Jungfrau',
  'Waage', 'Skorpion', 'Schütze', 'Steinbock', 'Wassermann', 'Fische',
];

/// Tierkreiszeichen-Symbole (UTF-8).
const List<String> zodiacSymbols = [
  '♈', '♉', '♊', '♋', '♌', '♍',
  '♎', '♏', '♐', '♑', '♒', '♓',
];

/// Element jedes Zeichens (Feuer, Erde, Luft, Wasser).
const List<String> zodiacElements = [
  'Feuer', 'Erde', 'Luft', 'Wasser',
  'Feuer', 'Erde', 'Luft', 'Wasser',
  'Feuer', 'Erde', 'Luft', 'Wasser',
];

/// Mondphasen-Keys (identisch mit moon_rituals.moon_phase in Supabase).
const List<String> moonPhaseKeys = [
  'new_moon',          // 0°
  'waxing_crescent',   // 0°–90°
  'first_quarter',     // 90°
  'waxing_gibbous',    // 90°–180°
  'full_moon',         // 180°
  'waning_gibbous',    // 180°–270°
  'last_quarter',      // 270°
  'waning_crescent',   // 270°–360°
];

const Map<String, String> moonPhaseLabels = {
  'new_moon': 'Neumond',
  'waxing_crescent': 'Zunehmende Sichel',
  'first_quarter': 'Erstes Viertel',
  'waxing_gibbous': 'Zunehmender Mond',
  'full_moon': 'Vollmond',
  'waning_gibbous': 'Abnehmender Mond',
  'last_quarter': 'Letztes Viertel',
  'waning_crescent': 'Abnehmende Sichel',
};

const Map<String, String> moonPhaseEmojis = {
  'new_moon': '🌑',
  'waxing_crescent': '🌒',
  'first_quarter': '🌓',
  'waxing_gibbous': '🌔',
  'full_moon': '🌕',
  'waning_gibbous': '🌖',
  'last_quarter': '🌗',
  'waning_crescent': '🌘',
};

// ═══════════════════════════════════════════════════════════
// Ergebnis-Modell
// ═══════════════════════════════════════════════════════════

/// Kompletter Mond-Snapshot für einen Zeitpunkt.
class MoonSnapshot {
  /// UTC-Zeitpunkt der Berechnung.
  final DateTime utc;

  /// Julianischer Tag.
  final double jd;

  /// Ekliptikale Länge der Sonne (0–360°).
  final double sunLongitude;

  /// Ekliptikale Länge des Mondes (0–360°).
  final double moonLongitude;

  /// Phasenwinkel Mond − Sonne (0–360°). 0° = Neumond, 180° = Vollmond.
  final double phaseAngle;

  /// Beleuchteter Anteil (0.0–1.0).
  final double illumination;

  /// Phasen-Key, siehe [moonPhaseKeys].
  final String phaseKey;

  /// Index des Mondzeichens (0 = Widder … 11 = Fische).
  final int moonSignIndex;

  /// Nimmt der Mond zu? (Phasenwinkel ≤ 180°)
  final bool isWaxing;

  const MoonSnapshot({
    required this.utc,
    required this.jd,
    required this.sunLongitude,
    required this.moonLongitude,
    required this.phaseAngle,
    required this.illumination,
    required this.phaseKey,
    required this.moonSignIndex,
    required this.isWaxing,
  });

  String get phaseLabel => moonPhaseLabels[phaseKey] ?? phaseKey;
  String get phaseEmoji => moonPhaseEmojis[phaseKey] ?? '🌙';
  String get moonSignName => zodiacNames[moonSignIndex];
  String get moonSignSymbol => zodiacSymbols[moonSignIndex];
  String get moonElement => zodiacElements[moonSignIndex];

  /// Gradzahl des Mondes INNERHALB seines Zeichens (0.0–29.999…).
  double get moonSignDegree => moonLongitude - moonSignIndex * 30.0;

  String get illuminationPercent =>
      '${(illumination * 100).toStringAsFixed(0)}%';
}

// ═══════════════════════════════════════════════════════════
// Zeit → Julianischer Tag
// ═══════════════════════════════════════════════════════════

/// Julianischer Tag (UT) aus DateTime.
/// Nutzt die direkte Millisekunden-Umrechnung ab Unix-Epoch.
/// Genauigkeit: sub-Millisekunde.
double julianDayFromUtc(DateTime utc) {
  final d = utc.toUtc();
  return _jdUnixEpoch + d.millisecondsSinceEpoch / _msPerDay;
}

/// Umkehrung: JD → UTC DateTime.
DateTime utcFromJulianDay(double jd) {
  final ms = ((jd - _jdUnixEpoch) * _msPerDay).round();
  return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
}

// ═══════════════════════════════════════════════════════════
// Sonne (Meeus Kap. 25, niedrige Genauigkeit: ~0.01°)
// ═══════════════════════════════════════════════════════════

/// Normalisiert einen Winkel in den Bereich [0, 360).
double _norm360(double d) {
  final r = d % 360.0;
  return r < 0 ? r + 360.0 : r;
}

/// Ekliptikale Länge der Sonne (scheinbar, geozentrisch) für JD.
/// Ergebnis in Grad, 0–360.
double sunEclipticLongitude(double jd) {
  final t = (jd - _jdJ2000) / 36525.0;

  // geometrische mittlere Länge
  final l0 = _norm360(280.46646 + t * (36000.76983 + t * 0.0003032));

  // mittlere Anomalie der Sonne
  final m = _norm360(357.52911 + t * (35999.05029 - t * 0.0001537));
  final mRad = m * _deg2rad;

  // Mittelpunktsgleichung
  final c = (1.914602 - t * (0.004817 + t * 0.000014)) * math.sin(mRad) +
      (0.019993 - t * 0.000101) * math.sin(2 * mRad) +
      0.000289 * math.sin(3 * mRad);

  // wahre Länge
  final trueLong = l0 + c;

  // Knotenlänge (für Aberrations-/Nutations-Näherung)
  final omega = (125.04 - 1934.136 * t) * _deg2rad;

  // scheinbare Länge (Meeus 25.8)
  final appLong = trueLong - 0.00569 - 0.00478 * math.sin(omega);

  return _norm360(appLong);
}

// ═══════════════════════════════════════════════════════════
// Mond (Meeus Kap. 47, reduzierte Reihe)
// ═══════════════════════════════════════════════════════════
//
// Die vollständige Table 47.A enthält 60 Terme. Wir benutzen die
// ~20 amplituden-stärksten, was für Mondzeichen und Phase mehr
// als ausreichend ist (typischer Fehler < 0.05°).
//
// Jede Zeile: [D, M, M', F, Sigma_l]
//   arg   = D*D + M*M + M'*M' + F*F        (Koeffizienten-Linearkombination)
//   term  = Sigma_l * E^|M| * sin(arg)     (Mikrograd → Grad /1e6)

// Top-Terme der Mond-Längen-Reihe (ΣL in millionstel Grad).
// Reihenfolge: D, M, M', F, ΣL
const List<List<int>> _moonLonTerms = [
  [0, 0, 1, 0, 6288774],
  [2, 0, -1, 0, 1274027],
  [2, 0, 0, 0, 658314],
  [0, 0, 2, 0, 213618],
  [0, 1, 0, 0, -185116],
  [0, 0, 0, 2, -114332],
  [2, 0, -2, 0, 58793],
  [2, -1, -1, 0, 57066],
  [2, 0, 1, 0, 53322],
  [2, -1, 0, 0, 45758],
  [0, 1, -1, 0, -40923],
  [1, 0, 0, 0, -34720],
  [0, 1, 1, 0, -30383],
  [2, 0, 0, -2, 15327],
  [0, 0, 1, 2, -12528],
  [0, 0, 1, -2, 10980],
  [4, 0, -1, 0, 10675],
  [0, 0, 3, 0, 10034],
  [4, 0, -2, 0, 8548],
  [2, 1, -1, 0, -7888],
  [2, 1, 0, 0, -6766],
  [1, 0, -1, 0, -5163],
  [1, 1, 0, 0, 4987],
  [2, -1, 1, 0, 4036],
  [2, 0, 2, 0, 3994],
];

/// Ekliptikale Länge des Mondes (geozentrisch, scheinbar) für JD.
/// Ergebnis in Grad, 0–360. Genauigkeit besser als 0.05°.
double moonEclipticLongitude(double jd) {
  final t = (jd - _jdJ2000) / 36525.0;

  // mittlere Mondlänge L'
  final lp = _norm360(218.3164477 +
      t * (481267.88123421 - t * (0.0015786 - t / 538841.0 - t * t / 65194000.0)));

  // mittlere Elongation D
  final d = _norm360(297.8501921 +
      t * (445267.1114034 - t * (0.0018819 - t / 545868.0 - t * t / 113065000.0)));

  // mittlere Anomalie der Sonne M
  final m = _norm360(357.5291092 +
      t * (35999.0502909 - t * (0.0001536 - t / 24490000.0)));

  // mittlere Anomalie des Mondes M'
  final mp = _norm360(134.9633964 +
      t * (477198.8675055 + t * (0.0087414 + t / 69699.0 - t * t / 14712000.0)));

  // Argument der Breite F
  final f = _norm360(93.272095 +
      t * (483202.0175233 - t * (0.0036539 + t / 3526000.0 - t * t / 863310000.0)));

  // Exzentrizitäts-Korrekturfaktor E (für M, 2M)
  final e = 1 - 0.002516 * t - 0.0000074 * t * t;

  final dRad = d * _deg2rad;
  final mRad = m * _deg2rad;
  final mpRad = mp * _deg2rad;
  final fRad = f * _deg2rad;

  double sumL = 0.0;
  for (final term in _moonLonTerms) {
    final arg = term[0] * dRad + term[1] * mRad + term[2] * mpRad + term[3] * fRad;
    double factor = 1.0;
    final absM = term[1].abs();
    if (absM == 1) factor = e;
    if (absM == 2) factor = e * e;
    sumL += term[4] * factor * math.sin(arg);
  }

  // ΣL kommt in millionstel Grad
  final longitude = lp + sumL / 1000000.0;

  return _norm360(longitude);
}

// ═══════════════════════════════════════════════════════════
// Snapshot-Berechnung
// ═══════════════════════════════════════════════════════════

/// Haupt-Einstiegspunkt: liefert den kompletten Mond-Snapshot.
MoonSnapshot calculateMoonSnapshot(DateTime utc) {
  final jd = julianDayFromUtc(utc);
  final sunLon = sunEclipticLongitude(jd);
  final moonLon = moonEclipticLongitude(jd);

  // Phasenwinkel 0–360°: 0 = Konjunktion (Neumond), 180 = Opposition (Vollmond)
  final phase = _norm360(moonLon - sunLon);

  // Beleuchtung aus Phasenwinkel.
  final illum = (1 - math.cos(phase * _deg2rad)) / 2;

  final signIdx = (moonLon ~/ 30) % 12;
  final waxing = phase <= 180.0;

  return MoonSnapshot(
    utc: utc.toUtc(),
    jd: jd,
    sunLongitude: sunLon,
    moonLongitude: moonLon,
    phaseAngle: phase,
    illumination: illum,
    phaseKey: _phaseKeyFromAngle(phase),
    moonSignIndex: signIdx,
    isWaxing: waxing,
  );
}

String _phaseKeyFromAngle(double angleDeg) {
  // 8 Phasen mit je ±22.5° um die Hauptwinkel 0, 90, 180, 270.
  // Die dazwischenliegenden Bereiche sind die "Sichel/Gibbous"-Phasen.
  if (angleDeg < 22.5 || angleDeg >= 337.5) return 'new_moon';
  if (angleDeg < 67.5) return 'waxing_crescent';
  if (angleDeg < 112.5) return 'first_quarter';
  if (angleDeg < 157.5) return 'waxing_gibbous';
  if (angleDeg < 202.5) return 'full_moon';
  if (angleDeg < 247.5) return 'waning_gibbous';
  if (angleDeg < 292.5) return 'last_quarter';
  return 'waning_crescent';
}

// ═══════════════════════════════════════════════════════════
// Nächster Zeichenwechsel des Mondes
// ═══════════════════════════════════════════════════════════

/// Findet den Zeitpunkt, zu dem der Mond in das nächste Zeichen wechselt.
/// Nutzt Bisektion auf der Mondlängen-Funktion.
/// Typische Dauer eines Mondzeichens: ~2.5 Tage.
DateTime nextMoonSignChange(DateTime fromUtc) {
  final start = fromUtc.toUtc();
  final startSnap = calculateMoonSnapshot(start);
  final targetLon = ((startSnap.moonSignIndex + 1) % 12) * 30.0;

  // Bereich: heute bis +3 Tage.
  double lo = start.millisecondsSinceEpoch.toDouble();
  double hi = lo + 3 * _msPerDay;

  // Normalisierte Differenz zur Ziel-Länge (wrap-around sauber behandeln).
  double diffAt(double ms) {
    final lon = moonEclipticLongitude(
      _jdUnixEpoch + ms / _msPerDay,
    );
    // Differenz auf [-180, +180] bringen
    double diff = lon - targetLon;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return diff;
  }

  // Bei Zeichenwechsel springt die normalisierte Differenz von negativ zu positiv.
  // Zu Beginn sollte diff < 0 sein (Mond noch vor dem Ziel).
  double dLo = diffAt(lo);
  double dHi = diffAt(hi);

  // Falls hi schon vor Zielübergang: erweitern (safety-net bis 5 Tage).
  int expandGuard = 0;
  while (dLo * dHi > 0 && expandGuard < 4) {
    hi += _msPerDay;
    dHi = diffAt(hi);
    expandGuard++;
  }

  // Bisektion bis auf 1 Minute.
  while (hi - lo > 60000) {
    final mid = (lo + hi) / 2;
    final dMid = diffAt(mid);
    if (dLo * dMid <= 0) {
      hi = mid;
      dHi = dMid;
    } else {
      lo = mid;
      dLo = dMid;
    }
  }

  return DateTime.fromMillisecondsSinceEpoch(
    ((lo + hi) / 2).round(),
    isUtc: true,
  );
}

// ═══════════════════════════════════════════════════════════
// Exakter Zeitpunkt von Neumond / Vollmond (Meeus Kap. 49)
// ═══════════════════════════════════════════════════════════

/// Berechnet den Zeitpunkt (UTC) der nächsten Mondphase nach [fromUtc].
/// [phase] ist der Phasenwinkel in Grad (0 = Neumond, 90 = erstes Viertel,
/// 180 = Vollmond, 270 = letztes Viertel).
DateTime nextMoonPhase(DateTime fromUtc, double phase) {
  assert(phase == 0 || phase == 90 || phase == 180 || phase == 270,
      'phase must be 0/90/180/270');

  final fromJd = julianDayFromUtc(fromUtc.toUtc());

  // K-Startwert: Anzahl Synodischer Monate seit 2000-01-06
  double kApprox = (fromJd - 2451550.09766) / 29.53058861;

  // Phasen-Offset (0/0.25/0.5/0.75)
  final offset = phase / 360.0;

  // Nächsten sinnvollen K-Wert für diese Phase ab fromJd finden.
  // Wir runden auf den nächsten K mit dem passenden Bruchteil.
  double k = (kApprox - offset).floorToDouble() + offset;
  double jde = _moonPhaseJde(k);
  while (jde < fromJd) {
    k += 1.0;
    jde = _moonPhaseJde(k);
  }

  return utcFromJulianDay(jde);
}

/// Meeus Formel 49.1 + 49.2 + Hauptkorrekturterme aus Tabelle 49.A
/// für Phasenwinkel 0° (Neumond) und 180° (Vollmond).
/// Genauigkeit: ca. 1 Minute.
double _moonPhaseJde(double k) {
  final t = k / 1236.85;
  final t2 = t * t;
  final t3 = t2 * t;
  final t4 = t3 * t;

  // Mittlere JDE der Phase
  final jdeMean = 2451550.09766 +
      29.530588861 * k +
      0.00015437 * t2 -
      0.000000150 * t3 +
      0.00000000073 * t4;

  // E – Sonne-Exzentrizitätskorrektur
  final e = 1 - 0.002516 * t - 0.0000074 * t2;

  // M – mittlere Anomalie der Sonne
  final m = _norm360(2.5534 + 29.10535670 * k -
      0.0000014 * t2 - 0.00000011 * t3);

  // M' – mittlere Anomalie des Mondes
  final mp = _norm360(201.5643 + 385.81693528 * k +
      0.0107582 * t2 + 0.00001238 * t3 - 0.000000058 * t4);

  // F – Argument der Breite
  final f = _norm360(160.7108 + 390.67050284 * k -
      0.0016118 * t2 - 0.00000227 * t3 + 0.000000011 * t4);

  // Ω – Knotenlänge
  final om = _norm360(124.7746 - 1.56375588 * k +
      0.0020672 * t2 + 0.00000215 * t3);

  final mR = m * _deg2rad;
  final mpR = mp * _deg2rad;
  final fR = f * _deg2rad;
  final omR = om * _deg2rad;

  // Bruchteil um zu unterscheiden: Neumond (0) vs. Vollmond (0.5)
  final frac = k - k.floorToDouble();
  final isNew = frac < 0.1 || frac > 0.9;
  final isFull = (frac - 0.5).abs() < 0.1;
  final isFirstQ = (frac - 0.25).abs() < 0.1;
  final isLastQ = (frac - 0.75).abs() < 0.1;

  double corr = 0.0;

  if (isNew || isFull) {
    // Hauptkorrekturterme Tabelle 49.A – New/Full Moon gemeinsam
    corr = -0.40720 * math.sin(mpR) +
        0.17241 * e * math.sin(mR) +
        0.01608 * math.sin(2 * mpR) +
        0.01039 * math.sin(2 * fR) +
        0.00739 * e * math.sin(mpR - mR) -
        0.00514 * e * math.sin(mpR + mR) +
        0.00208 * e * e * math.sin(2 * mR) -
        0.00111 * math.sin(mpR - 2 * fR) -
        0.00057 * math.sin(mpR + 2 * fR) +
        0.00056 * e * math.sin(2 * mpR + mR) -
        0.00042 * math.sin(3 * mpR) +
        0.00042 * e * math.sin(mR + 2 * fR) +
        0.00038 * e * math.sin(mR - 2 * fR) -
        0.00024 * e * math.sin(2 * mpR - mR) -
        0.00017 * math.sin(omR);

    // Für Vollmond: Vorzeichen einiger Terme flippen
    if (isFull) {
      corr = -0.40614 * math.sin(mpR) +
          0.17302 * e * math.sin(mR) +
          0.01614 * math.sin(2 * mpR) +
          0.01043 * math.sin(2 * fR) +
          0.00734 * e * math.sin(mpR - mR) -
          0.00515 * e * math.sin(mpR + mR) +
          0.00209 * e * e * math.sin(2 * mR) -
          0.00111 * math.sin(mpR - 2 * fR) -
          0.00057 * math.sin(mpR + 2 * fR) +
          0.00056 * e * math.sin(2 * mpR + mR) -
          0.00042 * math.sin(3 * mpR) +
          0.00042 * e * math.sin(mR + 2 * fR) +
          0.00038 * e * math.sin(mR - 2 * fR) -
          0.00024 * e * math.sin(2 * mpR - mR) -
          0.00017 * math.sin(omR);
    }
  } else if (isFirstQ || isLastQ) {
    // Hauptkorrekturterme für Viertelphasen (Tabelle 49.A Spalte 4)
    corr = -0.62801 * math.sin(mpR) +
        0.17172 * e * math.sin(mR) -
        0.01183 * e * math.sin(mpR + mR) +
        0.00862 * math.sin(2 * mpR) +
        0.00804 * math.sin(2 * fR) +
        0.00454 * e * math.sin(mpR - mR) +
        0.00204 * e * e * math.sin(2 * mR) -
        0.00180 * math.sin(mpR - 2 * fR) -
        0.00070 * math.sin(mpR + 2 * fR) -
        0.00040 * math.sin(3 * mpR) -
        0.00034 * e * math.sin(2 * mpR - mR) +
        0.00032 * e * math.sin(mR + 2 * fR) +
        0.00032 * e * math.sin(mR - 2 * fR) -
        0.00028 * e * e * math.sin(mpR + 2 * mR);

    // Meeus 49.2: extra Term W für Viertel
    final w = 0.00306 -
        0.00038 * e * math.cos(mR) +
        0.00026 * math.cos(mpR) -
        0.00002 * math.cos(mpR - mR) +
        0.00002 * math.cos(mpR + mR) +
        0.00002 * math.cos(2 * fR);
    corr += isFirstQ ? w : -w;
  }

  return jdeMean + corr;
}

// ═══════════════════════════════════════════════════════════
// Convenience: mehrere Mondphasen-Events ab Datum
// ═══════════════════════════════════════════════════════════

/// Liefert {newMoon, firstQuarter, fullMoon, lastQuarter} als nächste
/// UTC-Zeitpunkte ab [fromUtc].
Map<String, DateTime> nextFourMoonPhases(DateTime fromUtc) {
  return {
    'new_moon': nextMoonPhase(fromUtc, 0),
    'first_quarter': nextMoonPhase(fromUtc, 90),
    'full_moon': nextMoonPhase(fromUtc, 180),
    'last_quarter': nextMoonPhase(fromUtc, 270),
  };
}
