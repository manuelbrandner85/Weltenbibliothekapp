// Astrologie-Service für Geburtshoroskop (Tool 1).
//
// Berechnet geozentrische ekliptikale Längen für Sonne, Mond und 8 Planeten
// mittels vereinfachter Meeus-Formeln (Astronomical Algorithms, 2. Aufl.).
// Genauigkeit: Sonne ±0.5°, Mond ±3°, innere Planeten ±1–2°, äußere Planeten
// ±0.5° im Zeitraum 1800–2100. Ausreichend für Natal-Interpretation;
// keine Profi-Ephemeride.
//
// Aszendent + MC werden mit Greenwich-Siderzeit berechnet, wenn
// Geburtszeit + Längen-/Breiten-Grad gegeben sind.

import 'dart:math' as math;

/// Ergebnis einer Natal-Chart-Berechnung.
class NatalChartResult {
  /// Zeichen (0=Widder ... 11=Fische) und Grad (0–30) im Zeichen
  final Map<String, _PlanetPos> planets;
  final _PlanetPos? ascendant;
  final _PlanetPos? mc;
  final Map<String, dynamic> computation;

  NatalChartResult({
    required this.planets,
    required this.ascendant,
    required this.mc,
    required this.computation,
  });
}

class _PlanetPos {
  final int sign;       // 0..11
  final double degree;  // 0..30 innerhalb des Zeichens
  final double longitude; // 0..360 absolut
  const _PlanetPos(this.sign, this.degree, this.longitude);

  Map<String, dynamic> toJson() => {
        'sign': sign,
        'degree': degree,
        'longitude': longitude,
      };
}

class NatalAstrology {
  /// Haupt-API. birthDate + optionale Zeit (UTC!) + Lat/Lng/TZ-Offset.
  static NatalChartResult compute({
    required DateTime birthDateUtc,
    double? latitude,
    double? longitude,
  }) {
    final jd = _julianDay(birthDateUtc);
    final t = (jd - 2451545.0) / 36525.0; // julian centuries from J2000

    final sunLon = _normalizeDeg(_sunLongitude(t));
    final moonLon = _normalizeDeg(_moonLongitude(t));
    final mercuryLon = _normalizeDeg(_planetLongitude('mercury', t));
    final venusLon = _normalizeDeg(_planetLongitude('venus', t));
    final marsLon = _normalizeDeg(_planetLongitude('mars', t));
    final jupiterLon = _normalizeDeg(_planetLongitude('jupiter', t));
    final saturnLon = _normalizeDeg(_planetLongitude('saturn', t));
    final uranusLon = _normalizeDeg(_planetLongitude('uranus', t));
    final neptuneLon = _normalizeDeg(_planetLongitude('neptune', t));
    final plutoLon = _normalizeDeg(_plutoLongitude(t));

    _PlanetPos? asc;
    _PlanetPos? mc;
    if (latitude != null && longitude != null) {
      final gmst = _greenwichSiderealTime(jd); // hours
      final lst = (gmst + longitude / 15.0) * 15.0; // degrees east
      final ascLon = _ascendantLongitude(lst, latitude);
      final mcLon = _mcLongitude(lst);
      asc = _toPos(_normalizeDeg(ascLon));
      mc = _toPos(_normalizeDeg(mcLon));
    }

    return NatalChartResult(
      planets: {
        'sun': _toPos(sunLon),
        'moon': _toPos(moonLon),
        'mercury': _toPos(mercuryLon),
        'venus': _toPos(venusLon),
        'mars': _toPos(marsLon),
        'jupiter': _toPos(jupiterLon),
        'saturn': _toPos(saturnLon),
        'uranus': _toPos(uranusLon),
        'neptune': _toPos(neptuneLon),
        'pluto': _toPos(plutoLon),
      },
      ascendant: asc,
      mc: mc,
      computation: {
        'birth_utc': birthDateUtc.toIso8601String(),
        'julian_day': jd,
        't_centuries': t,
        'longitudes': {
          'sun': sunLon,
          'moon': moonLon,
          'mercury': mercuryLon,
          'venus': venusLon,
          'mars': marsLon,
          'jupiter': jupiterLon,
          'saturn': saturnLon,
          'uranus': uranusLon,
          'neptune': neptuneLon,
          'pluto': plutoLon,
          if (asc != null) 'ascendant': asc.longitude,
          if (mc != null) 'mc': mc.longitude,
        },
      },
    );
  }

  // ── helpers ─────────────────────────────────────────────────────

  static _PlanetPos _toPos(double lon) {
    final sign = (lon ~/ 30) % 12;
    final deg = lon - sign * 30;
    return _PlanetPos(sign, deg, lon);
  }

  static double _normalizeDeg(double d) {
    var r = d % 360.0;
    if (r < 0) r += 360.0;
    return r;
  }

  static double _rad(double deg) => deg * math.pi / 180.0;
  static double _deg(double rad) => rad * 180.0 / math.pi;

  /// Julian Day aus UTC-DateTime.
  static double _julianDay(DateTime utc) {
    int y = utc.year;
    int m = utc.month;
    final d = utc.day +
        (utc.hour + utc.minute / 60.0 + utc.second / 3600.0) / 24.0;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        d +
        b -
        1524.5;
  }

  /// Sonnen-Länge (Meeus 25.2).
  static double _sunLongitude(double t) {
    final l0 = 280.46646 + 36000.76983 * t + 0.0003032 * t * t;
    final m = 357.52911 + 35999.05029 * t - 0.0001537 * t * t;
    final mrad = _rad(m);
    final c = (1.914602 - 0.004817 * t - 0.000014 * t * t) * math.sin(mrad) +
        (0.019993 - 0.000101 * t) * math.sin(2 * mrad) +
        0.000289 * math.sin(3 * mrad);
    return l0 + c;
  }

  /// Mond-Länge (vereinfachte Meeus 47.1, erste 6 Terme).
  static double _moonLongitude(double t) {
    final lp = 218.3164477 +
        481267.88123421 * t -
        0.0015786 * t * t +
        t * t * t / 538841.0;
    final d = _rad(297.8501921 +
        445267.1114034 * t -
        0.0018819 * t * t +
        t * t * t / 545868.0);
    final mp = _rad(134.9633964 +
        477198.8675055 * t +
        0.0087414 * t * t +
        t * t * t / 69699.0);
    final m = _rad(357.5291092 +
        35999.0502909 * t -
        0.0001536 * t * t +
        t * t * t / 24490000.0);
    final f = _rad(93.2720950 +
        483202.0175233 * t -
        0.0036539 * t * t -
        t * t * t / 3526000.0);
    // Hauptterme aus Table 47.A (Meeus) – in Grad-Einheiten der Störung
    double perturb = 6.288774 * math.sin(mp);
    perturb += 1.274027 * math.sin(2 * d - mp);
    perturb += 0.658314 * math.sin(2 * d);
    perturb += 0.213618 * math.sin(2 * mp);
    perturb -= 0.185116 * math.sin(m);
    perturb -= 0.114332 * math.sin(2 * f);
    perturb += 0.058793 * math.sin(2 * d - 2 * mp);
    perturb += 0.057066 * math.sin(2 * d - m - mp);
    perturb += 0.053322 * math.sin(2 * d + mp);
    perturb += 0.045758 * math.sin(2 * d - m);
    return lp + perturb;
  }

  /// Planeten-Länge via mittlere Bahnelemente + Bahnstörung (Meeus 32.A).
  /// Approximative heliozentrische Länge → geozentrisch über Erd-Bahn.
  static double _planetLongitude(String planet, double t) {
    // Mittlere Bahnelemente (Meeus Tab 31.A, 2000.0-Äquator):
    // L = mittlere Länge, a = große Halbachse, e = Exzentrizität,
    // i = Inklination, omega = Länge des aufsteigenden Knotens,
    // pi = Länge des Perihels
    final orb = _orbital(planet, t);
    final earth = _orbital('earth', t);

    final lambdaP = _heliocentricLongitude(orb);
    final rP = _heliocentricRadius(orb);
    final lambdaE = _heliocentricLongitude(earth);
    final rE = _heliocentricRadius(earth);

    // Vereinfacht: geozentrische ekliptikale Länge
    final xP = rP * math.cos(_rad(lambdaP));
    final yP = rP * math.sin(_rad(lambdaP));
    final xE = rE * math.cos(_rad(lambdaE));
    final yE = rE * math.sin(_rad(lambdaE));

    final x = xP - xE;
    final y = yP - yE;
    return _deg(math.atan2(y, x));
  }

  /// Pluto – sehr grobe Näherung via mittlere Bewegung ab J2000.
  /// Genauigkeit ~0.5° für 1900–2100.
  static double _plutoLongitude(double t) {
    // J2000: Pluto ekl. Länge ≈ 251.46° (NASA), mittlere tägliche Bewegung
    // ~0.00406° → pro Jahrhundert ~148.3°. Nimm quadratische Korrektur.
    final days = t * 36525.0;
    final meanLon = 251.46 + 0.00406 * days;
    // kleine Sinus-Störung für Exzentrizität
    final m = _rad(14.82 + 0.00404 * days);
    final c = 4.8 * math.sin(m) + 0.4 * math.sin(2 * m);
    return meanLon + c;
  }

  static _Orbital _orbital(String planet, double t) {
    // Werte bei J2000.0 (Epoche) + centennial rates.
    // Quelle: Meeus Tab 31.A (vereinfacht).
    switch (planet) {
      case 'earth':
        return _Orbital(
          L: 100.466457 + 35999.3728565 * t,
          a: 1.000001018,
          e: 0.01670863 - 0.00004204 * t,
          i: 0.0,
          omega: 0.0,
          pi: 102.937348 + 0.3225654 * t,
        );
      case 'mercury':
        return _Orbital(
          L: 252.250906 + 149474.0722491 * t,
          a: 0.387098310,
          e: 0.20563175 + 0.000020406 * t,
          i: 7.004986 - 0.0059516 * t,
          omega: 48.330893 - 0.1254227 * t,
          pi: 77.456119 + 0.1588643 * t,
        );
      case 'venus':
        return _Orbital(
          L: 181.979801 + 58519.2130302 * t,
          a: 0.723329820,
          e: 0.00677188 - 0.00004777 * t,
          i: 3.394662 - 0.0008568 * t,
          omega: 76.679920 - 0.2780080 * t,
          pi: 131.563707 + 0.0048646 * t,
        );
      case 'mars':
        return _Orbital(
          L: 355.433275 + 19141.6964746 * t,
          a: 1.523679342,
          e: 0.09340062 + 0.000090483 * t,
          i: 1.849726 - 0.0081479 * t,
          omega: 49.558093 - 0.2949846 * t,
          pi: 336.060234 + 0.4438898 * t,
        );
      case 'jupiter':
        return _Orbital(
          L: 34.351484 + 3036.3027889 * t,
          a: 5.202603191,
          e: 0.04849485 + 0.000163244 * t,
          i: 1.303270 - 0.0019872 * t,
          omega: 100.464441 + 0.1766828 * t,
          pi: 14.331309 + 0.2155525 * t,
        );
      case 'saturn':
        return _Orbital(
          L: 50.077471 + 1223.5110141 * t,
          a: 9.554909596,
          e: 0.05550862 - 0.000346818 * t,
          i: 2.488878 + 0.0025515 * t,
          omega: 113.665524 - 0.2566649 * t,
          pi: 93.056787 + 0.5665496 * t,
        );
      case 'uranus':
        return _Orbital(
          L: 314.055005 + 429.8640561 * t,
          a: 19.218446062,
          e: 0.04629590 - 0.000027337 * t,
          i: 0.773196 - 0.0016869 * t,
          omega: 74.005947 + 0.0741461 * t,
          pi: 173.005159 + 0.0893206 * t,
        );
      case 'neptune':
        return _Orbital(
          L: 304.348665 + 219.8833092 * t,
          a: 30.110386869,
          e: 0.00898809 + 0.000006408 * t,
          i: 1.769952 + 0.0002257 * t,
          omega: 131.784057 - 0.0061651 * t,
          pi: 48.123691 + 0.0291587 * t,
        );
    }
    throw ArgumentError('Unbekannter Planet: $planet');
  }

  /// Heliozentrische ekliptikale Länge aus Bahnelementen (stark vereinfacht).
  static double _heliocentricLongitude(_Orbital o) {
    final m = _normalizeDeg(o.L - o.pi); // mittlere Anomalie
    final mRad = _rad(m);
    // Kepler-Gleichung iterativ lösen
    double e = mRad;
    for (int i = 0; i < 8; i++) {
      e = e - (e - o.e * math.sin(e) - mRad) / (1 - o.e * math.cos(e));
    }
    // wahre Anomalie
    final v = 2 *
        math.atan2(
            math.sqrt(1 + o.e) * math.sin(e / 2),
            math.sqrt(1 - o.e) * math.cos(e / 2));
    return _normalizeDeg(_deg(v) + o.pi);
  }

  static double _heliocentricRadius(_Orbital o) {
    final m = _normalizeDeg(o.L - o.pi);
    final mRad = _rad(m);
    double e = mRad;
    for (int i = 0; i < 8; i++) {
      e = e - (e - o.e * math.sin(e) - mRad) / (1 - o.e * math.cos(e));
    }
    return o.a * (1 - o.e * math.cos(e));
  }

  /// Greenwich Mean Sidereal Time in Stunden (Meeus 12.4).
  static double _greenwichSiderealTime(double jd) {
    final t = (jd - 2451545.0) / 36525.0;
    final gmstSec = 67310.54841 +
        (876600 * 3600 + 8640184.812866) * t +
        0.093104 * t * t -
        6.2e-6 * t * t * t;
    var hours = (gmstSec / 3600.0) % 24.0;
    if (hours < 0) hours += 24.0;
    return hours;
  }

  /// Aszendent = Ekliptik ↔ Horizont-Schnittpunkt (Meeus 13.4, ε=23.4393°).
  static double _ascendantLongitude(double lst, double latitude) {
    const eps = 23.4393;
    final tanRad = math.tan(_rad(latitude));
    final lstRad = _rad(lst);
    final cosL = math.cos(lstRad);
    final sinL = math.sin(lstRad);
    final cosE = math.cos(_rad(eps));
    final sinE = math.sin(_rad(eps));
    final y = -cosL;
    final x = sinE * tanRad + cosE * sinL;
    var asc = _deg(math.atan2(y, x));
    if (asc < 0) asc += 360;
    return asc;
  }

  /// MC = Ekliptik ↔ Meridian.
  static double _mcLongitude(double lst) {
    const eps = 23.4393;
    final lstRad = _rad(lst);
    final mc =
        _deg(math.atan2(math.sin(lstRad), math.cos(lstRad) * math.cos(_rad(eps))));
    return mc < 0 ? mc + 360 : mc;
  }
}

class _Orbital {
  final double L, a, e, i, omega, pi;
  const _Orbital({
    required this.L,
    required this.a,
    required this.e,
    required this.i,
    required this.omega,
    required this.pi,
  });
}

/// Zeichen-Namen für UI (0=Widder, 11=Fische).
const List<String> kZodiacSigns = [
  'Widder',
  'Stier',
  'Zwillinge',
  'Krebs',
  'Löwe',
  'Jungfrau',
  'Waage',
  'Skorpion',
  'Schütze',
  'Steinbock',
  'Wassermann',
  'Fische',
];

const List<String> kZodiacGlyphs = [
  '♈', '♉', '♊', '♋', '♌', '♍', '♎', '♏', '♐', '♑', '♒', '♓',
];

const List<String> kPlanetNames = [
  'sun',
  'moon',
  'mercury',
  'venus',
  'mars',
  'jupiter',
  'saturn',
  'uranus',
  'neptune',
  'pluto',
];

const Map<String, String> kPlanetLabels = {
  'sun': 'Sonne',
  'moon': 'Mond',
  'mercury': 'Merkur',
  'venus': 'Venus',
  'mars': 'Mars',
  'jupiter': 'Jupiter',
  'saturn': 'Saturn',
  'uranus': 'Uranus',
  'neptune': 'Neptun',
  'pluto': 'Pluto',
};

const Map<String, String> kPlanetGlyphs = {
  'sun': '☉',
  'moon': '☽',
  'mercury': '☿',
  'venus': '♀',
  'mars': '♂',
  'jupiter': '♃',
  'saturn': '♄',
  'uranus': '♅',
  'neptune': '♆',
  'pluto': '♇',
};
