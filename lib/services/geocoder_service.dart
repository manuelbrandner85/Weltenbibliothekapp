/// 🔍 Geocoder-Service — Nominatim (OpenStreetMap)
///
/// Kostenlos, keine Auth nötig — Fair-Use-Limit: 1 req/sec.
/// Nutzt User-Agent-Header (Pflicht laut Nominatim-Policy).
///
/// Verwendung:
///   final svc = GeocoderService();
///   final results = await svc.search('Berlin');
///   if (results.isNotEmpty) {
///     mapController.move(LatLng(results.first.lat, results.first.lon), 12);
///   }
///
/// API-Doc: https://nominatim.org/release-docs/develop/api/Search/
library;

import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;

class GeocodeResult {
  final String displayName;
  final double lat;
  final double lon;
  final String? type; // 'city', 'country', 'mountain', etc.
  final double importance; // 0..1, höher = relevanter

  const GeocodeResult({
    required this.displayName,
    required this.lat,
    required this.lon,
    this.type,
    this.importance = 0,
  });

  /// Kurzer Display-Name: erste 1-2 Komponenten ("Berlin, Deutschland")
  String get shortName {
    final parts = displayName.split(',');
    if (parts.length <= 2) return displayName;
    return '${parts.first.trim()}, ${parts.last.trim()}';
  }
}

class GeocoderService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';
  // Pflicht laut Nominatim-Policy — sonst Block
  static const String _userAgent = 'Weltenbibliothek-App/5.40 (mobile)';

  /// Sucht Orte nach freier Text-Eingabe.
  ///
  /// [query] = was der User getippt hat (z.B. "Berlin", "Mount Kailash")
  /// [maxResults] = wie viele Treffer (default 5 für Vorschlagsliste)
  /// [language] = Sprach-Präferenz (default 'de')
  ///
  /// Wirft KEINE Exception — leere Liste bei Fehler.
  Future<List<GeocodeResult>> search(
    String query, {
    int maxResults = 5,
    String language = 'de',
  }) async {
    if (query.trim().length < 2) return const [];

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'q': query.trim(),
        'format': 'json',
        'limit': maxResults.toString(),
        'accept-language': language,
        'addressdetails': '0',
      });

      if (kDebugMode) {
        debugPrint('🔍 Geocoder: search "$query"');
      }

      final res = await http.get(
        uri,
        headers: {'User-Agent': _userAgent},
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('⚠️ Geocoder: HTTP ${res.statusCode}');
        }
        return const [];
      }

      final body = jsonDecode(res.body);
      if (body is! List) return const [];

      final results = <GeocodeResult>[];
      for (final item in body) {
        if (item is! Map) continue;
        try {
          final lat = double.tryParse(item['lat']?.toString() ?? '');
          final lon = double.tryParse(item['lon']?.toString() ?? '');
          if (lat == null || lon == null) continue;
          results.add(GeocodeResult(
            displayName: (item['display_name'] ?? '').toString(),
            lat: lat,
            lon: lon,
            type: item['type']?.toString(),
            importance:
                double.tryParse(item['importance']?.toString() ?? '0') ?? 0,
          ));
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Geocoder: skip result — $e');
          }
        }
      }

      // Sort nach Wichtigkeit
      results.sort((a, b) => b.importance.compareTo(a.importance));

      if (kDebugMode) {
        debugPrint('🔍 Geocoder: ${results.length} hits for "$query"');
      }
      return results;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Geocoder fetch failed: $e');
      }
      return const [];
    }
  }
}
