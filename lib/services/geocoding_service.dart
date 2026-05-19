// 🌍 GEOCODING SERVICE - Stadt-Name -> Latitude/Longitude
//
// Nutzt OpenStreetMap Nominatim API (free, no API key, fair-use):
//   https://nominatim.openstreetmap.org/search?q=<query>&format=json&limit=5
//
// Per Nominatim TOS:
//   - Max 1 Request/Sekunde
//   - Eigener User-Agent Pflicht
//   - Cache verwenden um Last zu reduzieren
//
// Wir cachen Anfragen lokal in SharedPreferences fuer 30 Tage damit der
// gleiche User nicht 10x dieselbe Suche triggert.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GeocodedPlace {
  final String displayName;
  final double latitude;
  final double longitude;
  final String? country;
  final String? region;
  final String? city;

  /// Inferred IANA timezone name (best-effort, nullable).
  final String? timezone;

  const GeocodedPlace({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.country,
    this.region,
    this.city,
    this.timezone,
  });

  Map<String, dynamic> toJson() => {
        'display_name': displayName,
        'latitude': latitude,
        'longitude': longitude,
        'country': country,
        'region': region,
        'city': city,
        'timezone': timezone,
      };

  factory GeocodedPlace.fromJson(Map<String, dynamic> j) => GeocodedPlace(
        displayName: j['display_name'] as String? ?? '',
        latitude: (j['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (j['longitude'] as num?)?.toDouble() ?? 0.0,
        country: j['country'] as String?,
        region: j['region'] as String?,
        city: j['city'] as String?,
        timezone: j['timezone'] as String?,
      );
}

class GeocodingService {
  GeocodingService._();
  static final GeocodingService instance = GeocodingService._();

  static const String _userAgent =
      'weltenbibliothek-app/5.x (https://github.com/manuelbrandner85/Weltenbibliothekapp)';
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  static const Duration _cacheTtl = Duration(days: 30);
  static const String _cachePrefix = 'geocache_v1:';
  static const Duration _httpTimeout = Duration(seconds: 8);

  DateTime? _lastRequestAt;

  /// Search for places matching [query]. Returns up to [limit] results.
  /// Empty list on error (never throws to UI).
  Future<List<GeocodedPlace>> searchPlace(String query, {int limit = 5}) async {
    final q = query.trim();
    if (q.length < 2) return const [];

    // Cache hit?
    final cached = await _readCache(q);
    if (cached != null) return cached;

    // Rate-limit Pause (Nominatim TOS: 1 req/s)
    await _respectRateLimit();

    try {
      final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
        'q': q,
        'format': 'json',
        'addressdetails': '1',
        'limit': limit.toString(),
        'accept-language': 'de,en',
      });
      final res = await http.get(uri, headers: {
        'User-Agent': _userAgent,
        'Accept': 'application/json',
      }).timeout(_httpTimeout);

      _lastRequestAt = DateTime.now();

      if (res.statusCode != 200) {
        if (kDebugMode) {
          debugPrint(
              '[GeocodingService] HTTP ${res.statusCode}: ${res.body.substring(0, res.body.length.clamp(0, 200))}');
        }
        return const [];
      }

      final data = jsonDecode(res.body);
      if (data is! List) return const [];

      final results = <GeocodedPlace>[];
      for (final raw in data) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        final lat = double.tryParse(m['lat']?.toString() ?? '');
        final lng = double.tryParse(m['lon']?.toString() ?? '');
        if (lat == null || lng == null) continue;
        final addr = (m['address'] is Map)
            ? Map<String, dynamic>.from(m['address'] as Map)
            : <String, dynamic>{};
        results.add(GeocodedPlace(
          displayName: m['display_name']?.toString() ?? '',
          latitude: lat,
          longitude: lng,
          country: addr['country']?.toString(),
          region: (addr['state'] ?? addr['region'])?.toString(),
          city: (addr['city'] ?? addr['town'] ?? addr['village'])?.toString(),
          timezone: null, // Nominatim liefert standardmaessig keine TZ
        ));
      }

      await _writeCache(q, results);
      return results;
    } on TimeoutException {
      if (kDebugMode) debugPrint('[GeocodingService] timeout for "$q"');
      return const [];
    } catch (e, st) {
      if (kDebugMode) debugPrint('[GeocodingService] error: $e\n$st');
      return const [];
    }
  }

  Future<void> _respectRateLimit() async {
    final last = _lastRequestAt;
    if (last == null) return;
    final elapsed = DateTime.now().difference(last);
    if (elapsed < const Duration(seconds: 1)) {
      await Future<void>.delayed(const Duration(seconds: 1) - elapsed);
    }
  }

  Future<List<GeocodedPlace>?> _readCache(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _cachePrefix + query.toLowerCase();
      final raw = prefs.getString(key);
      if (raw == null) return null;
      final parsed = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.tryParse(parsed['saved_at'] as String? ?? '');
      if (savedAt == null || DateTime.now().difference(savedAt) > _cacheTtl) {
        await prefs.remove(key);
        return null;
      }
      final items = parsed['items'] as List? ?? const [];
      return items
          .whereType<Map>()
          .map((m) => GeocodedPlace.fromJson(Map<String, dynamic>.from(m)))
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String query, List<GeocodedPlace> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _cachePrefix + query.toLowerCase();
      await prefs.setString(
        key,
        jsonEncode({
          'saved_at': DateTime.now().toIso8601String(),
          'items': items.map((i) => i.toJson()).toList(),
        }),
      );
    } catch (_) {/* non-fatal */}
  }
}
