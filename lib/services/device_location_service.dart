// DeviceLocationService — leichter Wrapper um geolocator mit Cache.
//
// Eine 30-Min-Cache vermeidet, dass jede Anfrage GPS aufweckt. Wenn
// Permission verweigert oder Plugin nicht verfügbar, kehrt null zurück
// — Aufrufer fallen dann auf Cloudflare-IP-Geo zurück.
//
// Verwendet auf Mobile via geolocator. Auf Web: GeolocatorPlatform nutzt
// die Browser-Geolocation-API, was ebenfalls funktioniert (User wird
// einmal um Permission gefragt).

import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceLocation {
  final double lat;
  final double lng;
  final DateTime fetchedAt;
  const DeviceLocation({
    required this.lat,
    required this.lng,
    required this.fetchedAt,
  });

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'at': fetchedAt.toIso8601String(),
      };
  factory DeviceLocation.fromJson(Map<String, dynamic> j) => DeviceLocation(
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        fetchedAt:
            DateTime.tryParse(j['at'] as String? ?? '') ?? DateTime.now(),
      );

  bool get isFresh =>
      DateTime.now().difference(fetchedAt) < const Duration(minutes: 30);
}

class DeviceLocationService {
  DeviceLocationService._();
  static final instance = DeviceLocationService._();

  static const _cacheKey = 'device_location_cache_v1';
  static const _deniedKey = 'device_location_denied';

  DeviceLocation? _memCache;

  /// Liefert die aktuelle Geräte-Position. Reihenfolge:
  /// 1) In-Memory frischer Cache (<30 Min)
  /// 2) SharedPrefs frischer Cache
  /// 3) Geolocator (asks for permission if first time)
  /// Bei Fehler / Verweigerung: null.
  Future<DeviceLocation?> getCurrent({bool forceRefresh = false}) async {
    if (!forceRefresh && _memCache != null && _memCache!.isFresh) {
      return _memCache;
    }
    final prefs = await SharedPreferences.getInstance();
    if (!forceRefresh) {
      final raw = prefs.getString(_cacheKey);
      if (raw != null) {
        try {
          final loc =
              DeviceLocation.fromJson(jsonDecode(raw) as Map<String, dynamic>);
          if (loc.isFresh) {
            _memCache = loc;
            return loc;
          }
        } catch (e) { if (kDebugMode) debugPrint('device_location_service: silent catch -> $e'); }
      }
    }

    // Wenn der User Permission abgelehnt hat, in dieser Session nicht
    // erneut nerven (User kann manuell in Settings re-enablen).
    if (prefs.getBool(_deniedKey) ?? false) {
      if (kDebugMode) {
        debugPrint('📍 Location previously denied — skipping prompt');
      }
      return null;
    }

    try {
      final serviceOk = await Geolocator.isLocationServiceEnabled();
      if (!serviceOk) return null;

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        await prefs.setBool(_deniedKey, true);
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low, // Stadt-Level reicht fürs Wetter
          timeLimit: Duration(seconds: 8),
        ),
      );
      final loc = DeviceLocation(
        lat: pos.latitude,
        lng: pos.longitude,
        fetchedAt: DateTime.now(),
      );
      _memCache = loc;
      await prefs.setString(_cacheKey, jsonEncode(loc.toJson()));
      return loc;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Location fetch: $e');
      return null;
    }
  }

  /// User hat Permission wieder erteilt — Flag zurücksetzen damit beim
  /// nächsten getCurrent() neu gefragt wird.
  Future<void> clearDeniedFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deniedKey);
  }
}
