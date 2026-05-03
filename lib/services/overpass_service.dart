/// 🗺️ Overpass-API-Service — OpenStreetMap-Query für spirituelle/heilige Orte
///
/// Overpass-API erlaubt Query nach OSM-Tags. Für Energie-Welt nutzen wir:
///   - amenity=place_of_worship → Tempel, Kirchen, Moscheen
///   - historic=monument | archaeological_site → Denkmäler, Ausgrabungen
///   - tourism=archaeological_site | viewpoint
///   - natural=peak (Berge), spring (Quellen)
///   - religion + denomination Tags
///
/// Verwendung:
///   final svc = OverpassService();
///   final places = await svc.fetchSacredPlaces(
///     bbox: BoundingBox(north: 52.6, south: 52.4, east: 13.5, west: 13.3),
///   );
///
/// API-Doc: https://wiki.openstreetmap.org/wiki/Overpass_API
/// Lizenz: ODbL (Attribution erforderlich: "© OpenStreetMap-Mitwirkende")
library;

import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;

class BoundingBox {
  final double north, south, east, west;
  const BoundingBox({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });

  /// Overpass-Format: south,west,north,east
  String toOverpassBbox() => '$south,$west,$north,$east';
}

enum SacredPlaceCategory {
  worship, // Tempel, Kirchen, Moscheen
  archaeological, // Stonehenge, Pyramiden, Stätten
  monument, // Mahnmäler, religiöse Statuen
  natural, // heilige Berge, Quellen
  unknown,
}

class SacredPlace {
  final int osmId;
  final String name;
  final double lat;
  final double lon;
  final SacredPlaceCategory category;
  final String? religion; // 'christian', 'muslim', 'hindu', 'buddhist', etc.
  final String? denomination; // 'catholic', 'sunni', etc.
  final String? historicType; // 'archaeological_site', 'monument', etc.
  final Map<String, dynamic> rawTags;

  const SacredPlace({
    required this.osmId,
    required this.name,
    required this.lat,
    required this.lon,
    required this.category,
    this.religion,
    this.denomination,
    this.historicType,
    this.rawTags = const {},
  });

  /// Welt-Icon basierend auf Religion / Kategorie
  String get emoji {
    switch (religion) {
      case 'christian':
        return '⛪';
      case 'muslim':
        return '🕌';
      case 'hindu':
        return '🕉️';
      case 'buddhist':
        return '☸️';
      case 'jewish':
        return '✡️';
      case 'taoist':
        return '☯️';
    }
    switch (category) {
      case SacredPlaceCategory.archaeological:
        return '🏛️';
      case SacredPlaceCategory.monument:
        return '🗿';
      case SacredPlaceCategory.natural:
        return '⛰️';
      case SacredPlaceCategory.worship:
        return '🙏';
      default:
        return '📍';
    }
  }

  String get readableCategory {
    switch (category) {
      case SacredPlaceCategory.worship:
        return 'Religiöser Ort';
      case SacredPlaceCategory.archaeological:
        return 'Archäologische Stätte';
      case SacredPlaceCategory.monument:
        return 'Denkmal';
      case SacredPlaceCategory.natural:
        return 'Naturheiligtum';
      default:
        return 'Spiritueller Ort';
    }
  }
}

class OverpassService {
  // Public Mirror — keine Auth, mit Fair-Use-Limit
  static const String _baseUrl = 'https://overpass-api.de/api/interpreter';

  /// Holt heilige/spirituelle Orte aus einem Bounding-Box-Bereich.
  ///
  /// [bbox] = der sichtbare Map-Bereich
  /// [maxResults] = Limit (Overpass kann timeoutet bei >500)
  ///
  /// Wirft KEINE Exception — leere Liste bei Fehler.
  Future<List<SacredPlace>> fetchSacredPlaces({
    required BoundingBox bbox,
    int maxResults = 200,
  }) async {
    // Overpass-QL: kombinierte Query für alle relevanten Tags
    final query = '''
[out:json][timeout:25][maxsize:67108864];
(
  node["amenity"="place_of_worship"](${bbox.toOverpassBbox()});
  node["historic"="archaeological_site"](${bbox.toOverpassBbox()});
  node["historic"="monument"](${bbox.toOverpassBbox()});
  node["tourism"="archaeological_site"](${bbox.toOverpassBbox()});
);
out body $maxResults;
''';

    try {
      if (kDebugMode) {
        debugPrint('🗺️ Overpass: fetching bbox=${bbox.toOverpassBbox()}');
      }

      final res = await http
          .post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'data=${Uri.encodeQueryComponent(query)}',
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('⚠️ Overpass: timeout after 30s');
          }
          return http.Response('{"elements":[]}', 408);
        },
      );

      if (res.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('⚠️ Overpass: HTTP ${res.statusCode}');
        }
        return const [];
      }

      final body = jsonDecode(res.body);
      final elements = (body is Map && body['elements'] is List)
          ? body['elements'] as List
          : <dynamic>[];

      final places = <SacredPlace>[];
      for (final el in elements) {
        if (el is! Map) continue;
        try {
          final tags = (el['tags'] is Map ? el['tags'] : {}) as Map;
          final name = (tags['name'] ?? tags['name:de'] ?? tags['name:en'])
                  ?.toString() ??
              '';
          if (name.isEmpty) continue; // Anonyme Stätten skippen

          final lat = (el['lat'] as num?)?.toDouble();
          final lon = (el['lon'] as num?)?.toDouble();
          if (lat == null || lon == null) continue;

          places.add(SacredPlace(
            osmId: (el['id'] as num?)?.toInt() ?? 0,
            name: name,
            lat: lat,
            lon: lon,
            category: _categoryFromTags(tags),
            religion: tags['religion']?.toString(),
            denomination: tags['denomination']?.toString(),
            historicType: tags['historic']?.toString(),
            rawTags: tags.map((k, v) => MapEntry(k.toString(), v)),
          ));
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Overpass: skip element — $e');
          }
        }
      }

      if (kDebugMode) {
        debugPrint('🗺️ Overpass: got ${places.length} sacred places');
      }
      return places;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Overpass fetch failed: $e');
      }
      return const [];
    }
  }

  SacredPlaceCategory _categoryFromTags(Map tags) {
    if (tags['amenity'] == 'place_of_worship') {
      return SacredPlaceCategory.worship;
    }
    final historic = tags['historic']?.toString();
    if (historic == 'archaeological_site' ||
        tags['tourism'] == 'archaeological_site') {
      return SacredPlaceCategory.archaeological;
    }
    if (historic == 'monument') {
      return SacredPlaceCategory.monument;
    }
    if (tags['natural'] == 'peak' || tags['natural'] == 'spring') {
      return SacredPlaceCategory.natural;
    }
    return SacredPlaceCategory.unknown;
  }
}
