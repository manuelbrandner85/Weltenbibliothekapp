// 🕐 TIMEZONE HELPER - Latitude/Longitude/Date -> UTC-Offset (Stunden)
//
// Spirit-Tools brauchen UTC-Offset fuer Geburtsdatum (z.B. fuer Aszendent-
// Berechnung im Horoskop). User sollen das NIE manuell tippen muessen.
//
// Strategie (pragmatisch, ohne extra Pakete):
//   1. Grob-Offset aus Longitude: offset_h = round(lng / 15)
//      → korrekt fuer rund 80% der Welt-Bevoelkerung (zonen-aligned)
//   2. Saisonale DST-Anpassung fuer Regionen die das nutzen:
//      Europa, Nordamerika, Australien, Israel, NZ, ...
//      DST = letzter So Maerz - letzter So Oktober (Europa-Regel,
//      USA: 2. So Maerz - 1. So Nov - leichte Abweichung).
//   3. Sonderfaelle (Indien +5.5h, Iran +3.5h, Nepal +5.75h, Afghanistan +4.5h,
//      Marquesas -9.5h, Newfoundland -3.5h) als Lookup-Override.
//
// Genauigkeit:
//   - Fuer Aszendent-Berechnung in Spirit-Tools meist auf ~15 min praezise
//     (Aszendent bewegt sich ~1° pro 4 min - akzeptabel fuer Astrologie-Apps,
//     nicht fuer wissenschaftliche Astronomie).
//   - User kann im Profil manuell overriden falls genaue TZ-Historie wichtig.
//
// Was wir NICHT machen:
//   - Pre-1970 historische TZ-Rules (Stalinsche Zeit-Aenderungen etc.)
//   - DST-Politische-Aenderungen waehrend der Lebenszeit eines Users
//   - Halbe-Sekunden-Praezision (UT1/UTC-Drift)

class TimezoneHelper {
  TimezoneHelper._();

  /// Berechnet den UTC-Offset in Stunden fuer eine Koordinate + Datum.
  /// Beispiel: lat=48.21, lng=16.37 (Wien), date=15.7.2000 -> 2.0 (MESZ)
  ///           lat=48.21, lng=16.37 (Wien), date=15.1.2000 -> 1.0 (MEZ)
  ///           lat=19.08, lng=72.88 (Mumbai), date=15.1.2000 -> 5.5 (IST)
  static double offsetForCoordinate(double lat, double lng, DateTime localDate) {
    // 1. Sonderfaelle (Halb-/Viertelstunden + politisch verschobene Zonen)
    final special = _checkSpecialZones(lat, lng);
    if (special != null) return special;

    // 2. Grob aus Longitude
    final baseOffset = (lng / 15.0).round();
    final clamped = baseOffset.clamp(-12, 14).toDouble();

    // 3. DST-Anpassung wenn Region und Datum passen
    if (_isDstObserved(lat, lng) && _isDstActive(lat, lng, localDate)) {
      return clamped + 1.0;
    }
    return clamped;
  }

  /// Inferenz fuer den Profile-Editor: wenn lat/lng beim Geocoding ermittelt
  /// werden, koennen wir TZ-Offset *fuer das Geburtsdatum* persistieren.
  /// Returns null wenn keine sinnvolle Inferenz moeglich (z.B. lat NaN).
  static double? inferOffsetHours({
    required double? latitude,
    required double? longitude,
    required DateTime? birthDate,
  }) {
    if (latitude == null || longitude == null) return null;
    if (!latitude.isFinite || !longitude.isFinite) return null;
    final date = birthDate ?? DateTime.now();
    return offsetForCoordinate(latitude, longitude, date);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Sonderzonen (Halb-Stunden + Viertel-Stunden + politische Verschiebungen)
  // ─────────────────────────────────────────────────────────────────────────

  static double? _checkSpecialZones(double lat, double lng) {
    // Indien: IST = +5.5h (kein DST)
    if (lat >= 6 && lat <= 36 && lng >= 68 && lng <= 98) return 5.5;
    // Nepal: NPT = +5.75h
    if (lat >= 26 && lat <= 31 && lng >= 80 && lng <= 89) return 5.75;
    // Iran: IRST = +3.5h (historisch DST war ab 2022 abgeschafft)
    if (lat >= 25 && lat <= 40 && lng >= 44 && lng <= 64) return 3.5;
    // Afghanistan: AFT = +4.5h
    if (lat >= 29 && lat <= 38.5 && lng >= 60.5 && lng <= 75) return 4.5;
    // Myanmar: MMT = +6.5h
    if (lat >= 9 && lat <= 28 && lng >= 92 && lng <= 102) return 6.5;
    // Sri Lanka: SLST = +5.5h
    if (lat >= 5 && lat <= 10 && lng >= 79 && lng <= 82) return 5.5;
    // Newfoundland: NST = -3.5h (DST -2.5h, vereinfacht)
    if (lat >= 46 && lat <= 52 && lng >= -60 && lng <= -52) return -3.5;
    // Adelaide / SA: ACST = +9.5h
    if (lat >= -38 && lat <= -26 && lng >= 129 && lng <= 141) return 9.5;
    // Marquesas Inseln: MART = -9.5h
    if (lat >= -11 && lat <= -7.5 && lng >= -141 && lng <= -138) return -9.5;
    // Chatham Islands NZ: CHAST = +12.75h (super selten)
    if (lat >= -44.5 && lat <= -43.5 && lng >= -177 && lng <= -176) return 12.75;
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DST-Beobachtung: Wer macht ueberhaupt Sommerzeit?
  // ─────────────────────────────────────────────────────────────────────────

  static bool _isDstObserved(double lat, double lng) {
    // Europa (ohne Russland-Russland macht kein DST seit 2011)
    if (lat >= 35 && lat <= 71 && lng >= -25 && lng <= 40) return true;
    // USA + Kanada (groesstenteils - Arizona/Hawaii nicht aber wir
    // approximieren, User kann overriden)
    if (lat >= 25 && lat <= 70 && lng >= -170 && lng <= -52) return true;
    // Australien Sued-Ost-Kueste (NSW, VIC, ACT, TAS, SA)
    if (lat >= -45 && lat <= -25 && lng >= 130 && lng <= 155) return true;
    // Neuseeland
    if (lat >= -47 && lat <= -34 && lng >= 165 && lng <= 179) return true;
    // Chile (DST ja, ABER zentral nur)
    if (lat >= -56 && lat <= -17 && lng >= -76 && lng <= -67) return true;
    // Israel/Palestina
    if (lat >= 29 && lat <= 33.5 && lng >= 34 && lng <= 36) return true;
    return false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DST aktiv? (Nordhalbkugel: Maerz-Okt, Suedhalbkugel: Okt-Apr)
  // ─────────────────────────────────────────────────────────────────────────

  static bool _isDstActive(double lat, double lng, DateTime date) {
    if (lat >= 0) {
      // Nordhalbkugel: ca. letzter So Maerz - letzter So Oktober
      final startOfDst = _lastSundayOfMonth(date.year, 3);
      final endOfDst = _lastSundayOfMonth(date.year, 10);
      return date.isAfter(startOfDst) && date.isBefore(endOfDst);
    } else {
      // Suedhalbkugel: ca. 1. So Oktober - 1. So April naechstes Jahr
      // (typisch fuer Australien)
      final start = _firstSundayOfMonth(date.year, 10);
      final end = _firstSundayOfMonth(date.year + 1, 4);
      final startPrev = _firstSundayOfMonth(date.year - 1, 10);
      final endThis = _firstSundayOfMonth(date.year, 4);
      return (date.isAfter(start) && date.isBefore(end)) ||
             (date.isAfter(startPrev) && date.isBefore(endThis));
    }
  }

  static DateTime _lastSundayOfMonth(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0);
    final weekday = lastDay.weekday; // 1=Mon, 7=Sun
    final daysBack = weekday == 7 ? 0 : weekday;
    return DateTime(year, month, lastDay.day - daysBack);
  }

  static DateTime _firstSundayOfMonth(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final weekday = firstDay.weekday;
    final daysForward = weekday == 7 ? 0 : (7 - weekday);
    return DateTime(year, month, 1 + daysForward);
  }

  /// Formattiert einen Offset wie 1.5 als "+01:30" oder -3.5 als "-03:30".
  static String formatOffset(double hours) {
    final sign = hours < 0 ? '-' : '+';
    final abs = hours.abs();
    final h = abs.floor();
    final m = ((abs - h) * 60).round();
    final hh = h.toString().padLeft(2, '0');
    final mm = m.toString().padLeft(2, '0');
    return '$sign$hh:$mm';
  }
}
