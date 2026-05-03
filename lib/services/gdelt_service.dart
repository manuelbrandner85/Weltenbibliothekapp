/// 🌍 GDELT-Service — Echtzeit-Geopolitik-Events von gdeltproject.org
///
/// GDELT (Global Database of Events, Language, and Tone) ist eine kostenlose
/// Datenbank von 25M+ Welt-Events pro Tag, indexiert von News-Quellen weltweit.
///
/// Verwendung:
///   final svc = GdeltService();
///   final events = await svc.fetchRecentEvents(country: 'DE', daysBack: 7);
///   for (final e in events) {
///     // e.title, e.url, e.date, e.lat, e.lon
///   }
///
/// API-Doc: https://blog.gdeltproject.org/gdelt-doc-2-0-api-debuts/
/// Lizenz: Public Domain — keine Auth nötig
library;

import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;

class GdeltEvent {
  final String title;
  final String url;
  final DateTime date;
  final String? source; // News-Domain
  final double? lat;
  final double? lon;
  final String? country; // ISO-2-Code
  final double tone; // -10 (extrem negativ) bis +10 (positiv)
  final String? imageUrl;

  const GdeltEvent({
    required this.title,
    required this.url,
    required this.date,
    this.source,
    this.lat,
    this.lon,
    this.country,
    this.tone = 0,
    this.imageUrl,
  });

  /// Welche Marker-Farbe basierend auf Tone:
  /// -8..-3 = rot (negativ), -3..3 = orange (neutral), 3..8 = grün (positiv)
  String get severityHint {
    if (tone < -3) return 'negativ';
    if (tone > 3) return 'positiv';
    return 'neutral';
  }
}

class GdeltService {
  static const String _baseUrl =
      'https://api.gdeltproject.org/api/v2/doc/doc';

  /// Holt News-Events aus den letzten X Tagen, optional nach Land/Themen gefiltert.
  ///
  /// [country] = ISO-2-Code (z.B. 'DE' für Deutschland, 'US' für USA, null = global)
  /// [daysBack] = wie viele Tage zurück (max 30 sinnvoll)
  /// [keyword] = freie Suche (z.B. "protest" oder "war")
  /// [maxResults] = max Anzahl Events (default 25, GDELT-Limit ~250)
  ///
  /// Wirft KEINE Exception bei Netzwerk-Fehler — gibt leere Liste zurück.
  /// Logs in Debug-Mode.
  Future<List<GdeltEvent>> fetchRecentEvents({
    String? country,
    String keyword = 'protest OR conflict OR election OR sanction',
    int daysBack = 3,
    int maxResults = 25,
  }) async {
    try {
      // Query-Builder: GDELT akzeptiert sourcecountry, theme, keywords
      final query = StringBuffer(keyword);
      if (country != null) {
        query.write(' sourcecountry:$country');
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'query': query.toString(),
        'mode': 'ArtList', // Articles mit Metadata
        'maxrecords': maxResults.toString(),
        'format': 'json',
        'timespan': '${daysBack}d',
        'sort': 'datedesc',
      });

      if (kDebugMode) {
        debugPrint('🌍 GDELT: fetching $uri');
      }

      final res = await http.get(uri).timeout(
            const Duration(seconds: 12),
            onTimeout: () => http.Response('{"articles":[]}', 408),
          );

      if (res.statusCode != 200) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ GDELT: HTTP ${res.statusCode} — ${res.body.substring(0, 200)}');
        }
        return const [];
      }

      final body = jsonDecode(res.body);
      final list = (body is Map && body['articles'] is List)
          ? body['articles'] as List
          : <dynamic>[];

      final events = <GdeltEvent>[];
      for (final item in list) {
        if (item is! Map) continue;
        try {
          // GDELT v2 Doc-API liefert: title, url, seendate (YYYYMMDDHHMMSS),
          // domain, sourcecountry, tone, socialimage
          final dateStr = item['seendate']?.toString() ?? '';
          final date = _parseGdeltDate(dateStr) ?? DateTime.now();

          events.add(GdeltEvent(
            title: (item['title'] ?? '').toString(),
            url: (item['url'] ?? '').toString(),
            date: date,
            source: item['domain']?.toString(),
            country: item['sourcecountry']?.toString(),
            tone: double.tryParse(item['tone']?.toString() ?? '0') ?? 0,
            imageUrl: item['socialimage']?.toString(),
            // Lat/Lon nicht in Doc-API direkt — kommt aus geo-API
          ));
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ GDELT: skip 1 event — $e');
          }
        }
      }

      if (kDebugMode) {
        debugPrint('🌍 GDELT: got ${events.length} events');
      }
      return events;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ GDELT fetch failed: $e');
      }
      return const [];
    }
  }

  /// Konvertiert "20260503143022" → DateTime
  DateTime? _parseGdeltDate(String s) {
    if (s.length < 14) return null;
    try {
      return DateTime.utc(
        int.parse(s.substring(0, 4)),
        int.parse(s.substring(4, 6)),
        int.parse(s.substring(6, 8)),
        int.parse(s.substring(8, 10)),
        int.parse(s.substring(10, 12)),
        int.parse(s.substring(12, 14)),
      );
    } catch (_) {
      return null;
    }
  }
}
