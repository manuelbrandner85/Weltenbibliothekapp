/// Kostenlose externe APIs — kein API-Key nötig (außer Guardian: 'test'-Key)
///
/// APIs:
///  1. GDELT        — geopolitische Weltereignisse (Echtzeit)
///  2. USGS         — Erdbeben-Feed (significant_week)
///  3. NASA SSD     — Fireball-/Bolide-Ereignisse (UFO-adjacent)
///  4. PubMed       — Wissenschaftliche Studien (eutils)
///  5. The Guardian — Nachrichtenartikel (kostenloser 'test'-Key)
///  6. Wikidata     — Historische Ereignisse (SPARQL-ähnlich)
///  7. NASA DONKI   — Sonnenstürme / kosmische Ereignisse
///  8. Quotable     — Inspirierende Zitate
///  9. Sunrise-Sunset — Sonnenaufgang/-untergang
/// 10. Wayback Machine — Archivierte Web-Snapshots
/// 11. Open-Meteo  — Mondphase berechnet aus Astronomical Formulas

library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;

class FreeApiService {
  FreeApiService._();
  static final FreeApiService instance = FreeApiService._();

  static const _timeout = Duration(seconds: 12);

  // ─────────────────────────────────────────────────────────────────────────
  // 1. GDELT — Geopolitische Ereignisse
  // ─────────────────────────────────────────────────────────────────────────

  /// Liefert bis zu [limit] aktuelle geopolitische Artikel von GDELT.
  /// [query] z.B. 'geopolitics conflict war'
  Future<List<GdeltArticle>> fetchGdeltEvents({
    String query = 'geopolitics conflict crisis',
    int limit = 20,
  }) async {
    final url = Uri.parse(
      'https://api.gdeltproject.org/api/v2/doc/doc'
      '?query=${Uri.encodeComponent(query)}'
      '&mode=ArtList&maxrecords=$limit&format=json'
      '&sort=DateDesc',
    );
    try {
      final res = await http.get(url).timeout(_timeout);
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final articles = (data['articles'] as List? ?? []);
      return articles.map((a) => GdeltArticle.fromJson(a as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ GDELT: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. USGS — Erdbeben
  // ─────────────────────────────────────────────────────────────────────────

  /// Liefert signifikante Erdbeben der letzten 7 Tage (USGS GeoJSON).
  Future<List<Earthquake>> fetchEarthquakes({String period = 'week'}) async {
    // Optionen: hour, day, week, month
    final url = Uri.parse(
      'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary'
      '/significant_$period.geojson',
    );
    try {
      final res = await http.get(url).timeout(_timeout);
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final features = (data['features'] as List? ?? []);
      return features
          .map((f) => Earthquake.fromJson(f as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ USGS: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. NASA SSD — Fireballs / Boliden (unidentifizierte Luftphänomene)
  // ─────────────────────────────────────────────────────────────────────────

  /// Liefert bestätigte Feuerball-/Bolid-Ereignisse der NASA.
  /// Ideal für UFO-Screen als "Offizielle Atmosphären-Ereignisse".
  Future<List<NasaFireball>> fetchFireballs({int limit = 30}) async {
    final url = Uri.parse(
      'https://ssd-api.jpl.nasa.gov/fireball.api?limit=$limit&sort=-date',
    );
    try {
      final res = await http.get(url).timeout(_timeout);
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final fields = List<String>.from(data['fields'] as List? ?? []);
      final rows = (data['data'] as List? ?? []);
      return rows.map((row) {
        final r = List<String?>.from(row as List);
        final m = <String, String?>{};
        for (int i = 0; i < fields.length; i++) {
          m[fields[i]] = i < r.length ? r[i] : null;
        }
        return NasaFireball.fromMap(m);
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ NASA Fireballs: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. PubMed — Wissenschaftliche Studien
  // ─────────────────────────────────────────────────────────────────────────

  /// Sucht PubMed-Studien zu [query] und gibt bis zu [limit] Ergebnisse zurück.
  Future<List<PubMedStudy>> fetchPubMedStudies(String query, {int limit = 8}) async {
    try {
      // Schritt 1: IDs suchen
      final searchUrl = Uri.parse(
        'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi'
        '?db=pubmed&term=${Uri.encodeComponent(query)}'
        '&retmode=json&retmax=$limit&sort=relevance',
      );
      final searchRes = await http.get(searchUrl).timeout(_timeout);
      if (searchRes.statusCode != 200) return [];
      final searchData = jsonDecode(searchRes.body) as Map<String, dynamic>;
      final ids = List<String>.from(
        (searchData['esearchresult']?['idlist'] as List? ?? []),
      );
      if (ids.isEmpty) return [];

      // Schritt 2: Zusammenfassung laden
      final summaryUrl = Uri.parse(
        'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi'
        '?db=pubmed&id=${ids.join(',')}&retmode=json',
      );
      final summaryRes = await http.get(summaryUrl).timeout(_timeout);
      if (summaryRes.statusCode != 200) return [];
      final summaryData = jsonDecode(summaryRes.body) as Map<String, dynamic>;
      final result = summaryData['result'] as Map<String, dynamic>? ?? {};

      return ids
          .where((id) => result.containsKey(id))
          .map((id) => PubMedStudy.fromJson(id, result[id] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ PubMed: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. The Guardian — Nachrichten
  // ─────────────────────────────────────────────────────────────────────────

  /// Sucht Guardian-Artikel zu [query]. Nutzt den kostenlosen 'test'-Key.
  Future<List<GuardianArticle>> fetchGuardianNews(String query, {int limit = 10}) async {
    final url = Uri.parse(
      'https://content.guardianapis.com/search'
      '?q=${Uri.encodeComponent(query)}'
      '&api-key=test'
      '&show-fields=trailText,thumbnail'
      '&page-size=$limit'
      '&order-by=newest',
    );
    try {
      final res = await http.get(url).timeout(_timeout);
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results = (data['response']?['results'] as List? ?? []);
      return results
          .map((r) => GuardianArticle.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Guardian: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 6. Wikidata — Historische Entitäten / Ereignisse
  // ─────────────────────────────────────────────────────────────────────────

  /// Sucht Wikidata-Entitäten zu [query] (Ereignisse, Personen, Orte).
  Future<List<WikidataEntry>> fetchWikidataEntries(String query, {int limit = 10}) async {
    final url = Uri.parse(
      'https://www.wikidata.org/w/api.php'
      '?action=wbsearchentities'
      '&search=${Uri.encodeComponent(query)}'
      '&language=de'
      '&limit=$limit'
      '&format=json'
      '&origin=*',
    );
    try {
      final res = await http.get(url).timeout(_timeout);
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final search = (data['search'] as List? ?? []);
      return search
          .map((e) => WikidataEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Wikidata: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 7. NASA DONKI — Sonnenstürme / Kosmische Ereignisse
  // ─────────────────────────────────────────────────────────────────────────

  /// Liefert Sonneneruptionen (CME) der letzten 7 Tage.
  Future<List<DonkiEvent>> fetchDonkiEvents({int daysBack = 7}) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: daysBack));
    final fmt = (DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final url = Uri.parse(
      'https://kauai.ccmc.gsfc.nasa.gov/DONKI/WS/rest/CME'
      '?startDate=${fmt(start)}&endDate=${fmt(end)}',
    );
    try {
      final res = await http.get(url).timeout(_timeout);
      if (res.statusCode != 200) return [];
      final list = jsonDecode(res.body) as List? ?? [];
      return list
          .map((e) => DonkiEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ NASA DONKI: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 8. Quotable — Inspirierendes Zitat des Tages
  // ─────────────────────────────────────────────────────────────────────────

  /// Liefert ein zufälliges Zitat (optional gefiltert nach [tags]).
  Future<DailyQuote?> fetchDailyQuote({String tags = 'wisdom,inspirational'}) async {
    final url = Uri.parse('https://api.quotable.io/random?tags=$tags');
    try {
      final res = await http.get(url).timeout(_timeout);
      if (res.statusCode != 200) return null;
      return DailyQuote.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Quotable: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 9. Sunrise-Sunset API — Sonnenaufgang + Sonnenuntergang
  // ─────────────────────────────────────────────────────────────────────────

  /// Liefert Sonnenaufgang/-untergang für [lat]/[lng] (Standard: München).
  Future<SunData?> fetchSunriseSunset({
    double lat = 48.1351,
    double lng = 11.5820,
  }) async {
    final url = Uri.parse(
      'https://api.sunrise-sunset.org/json?lat=$lat&lng=$lng&formatted=0',
    );
    try {
      final res = await http.get(url).timeout(_timeout);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return null;
      return SunData.fromJson(data['results'] as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Sunrise-Sunset: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 10. Wayback Machine — Archivierte Snapshots
  // ─────────────────────────────────────────────────────────────────────────

  /// Prüft ob [url] in der Wayback Machine archiviert ist und gibt den Link zurück.
  Future<String?> fetchWaybackSnapshot(String url) async {
    final apiUrl = Uri.parse(
      'https://archive.org/wayback/available?url=${Uri.encodeComponent(url)}',
    );
    try {
      final res = await http.get(apiUrl).timeout(_timeout);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['archived_snapshots']?['closest']?['url'] as String?;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Wayback: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 11. Mondphase — Mathematische Berechnung (kein API nötig)
  // ─────────────────────────────────────────────────────────────────────────

  /// Berechnet die aktuelle Mondphase (0.0–1.0, 0=Neumond, 0.5=Vollmond).
  MoonPhase calcMoonPhase([DateTime? date]) {
    final d = date ?? DateTime.now();
    // Bekannte Neumond-Referenz: 6. Januar 2000, 18:14 UTC
    final ref = DateTime.utc(2000, 1, 6, 18, 14);
    final synodicMonth = 29.53058770576; // Tage
    final diff = d.toUtc().difference(ref).inSeconds / 86400.0;
    final phase = (diff % synodicMonth) / synodicMonth;
    return MoonPhase(phase: phase.clamp(0.0, 1.0));
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═════════════════════════════════════════════════════════════════════════════

class GdeltArticle {
  final String title;
  final String url;
  final String domain;
  final String seendate;
  final String language;
  final String? sourcecountry;

  const GdeltArticle({
    required this.title,
    required this.url,
    required this.domain,
    required this.seendate,
    required this.language,
    this.sourcecountry,
  });

  factory GdeltArticle.fromJson(Map<String, dynamic> j) => GdeltArticle(
        title: j['title'] as String? ?? 'Kein Titel',
        url: j['url'] as String? ?? '',
        domain: j['domain'] as String? ?? '',
        seendate: j['seendate'] as String? ?? '',
        language: j['language'] as String? ?? '',
        sourcecountry: j['sourcecountry'] as String?,
      );

  /// Datum aus GDELT-Format "20260427T123456Z" parsen
  DateTime? get parsedDate {
    try {
      if (seendate.length >= 8) {
        final y = int.parse(seendate.substring(0, 4));
        final mo = int.parse(seendate.substring(4, 6));
        final dy = int.parse(seendate.substring(6, 8));
        return DateTime(y, mo, dy);
      }
    } catch (_) {}
    return null;
  }
}

class Earthquake {
  final String id;
  final String place;
  final double magnitude;
  final DateTime time;
  final double? latitude;
  final double? longitude;
  final double? depth;
  final String? url;

  const Earthquake({
    required this.id,
    required this.place,
    required this.magnitude,
    required this.time,
    this.latitude,
    this.longitude,
    this.depth,
    this.url,
  });

  factory Earthquake.fromJson(Map<String, dynamic> j) {
    final props = j['properties'] as Map<String, dynamic>? ?? {};
    final geo = j['geometry'] as Map<String, dynamic>? ?? {};
    final coords = (geo['coordinates'] as List?)?.cast<num>() ?? [];
    return Earthquake(
      id: j['id'] as String? ?? '',
      place: props['place'] as String? ?? 'Unbekannter Ort',
      magnitude: (props['mag'] as num?)?.toDouble() ?? 0.0,
      time: DateTime.fromMillisecondsSinceEpoch(
        (props['time'] as int?) ?? 0,
        isUtc: true,
      ),
      latitude: coords.length > 1 ? coords[1].toDouble() : null,
      longitude: coords.isNotEmpty ? coords[0].toDouble() : null,
      depth: coords.length > 2 ? coords[2].toDouble() : null,
      url: props['url'] as String?,
    );
  }

  String get magnitudeLabel {
    if (magnitude >= 8.0) return 'Extrem';
    if (magnitude >= 7.0) return 'Major';
    if (magnitude >= 6.0) return 'Stark';
    if (magnitude >= 5.0) return 'Mittel';
    return 'Leicht';
  }
}

class NasaFireball {
  final DateTime? date;
  final double? energy;
  final double? impactEnergy;
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? velocity;

  const NasaFireball({
    this.date,
    this.energy,
    this.impactEnergy,
    this.latitude,
    this.longitude,
    this.altitude,
    this.velocity,
  });

  factory NasaFireball.fromMap(Map<String, String?> m) {
    DateTime? d;
    try {
      if (m['date'] != null) d = DateTime.parse(m['date']!);
    } catch (_) {}
    return NasaFireball(
      date: d,
      energy: double.tryParse(m['energy'] ?? ''),
      impactEnergy: double.tryParse(m['impact-e'] ?? ''),
      latitude: double.tryParse(m['lat'] ?? ''),
      longitude: double.tryParse(m['lon'] ?? ''),
      altitude: double.tryParse(m['alt'] ?? ''),
      velocity: double.tryParse(m['vel'] ?? ''),
    );
  }

  String get locationLabel {
    if (latitude == null || longitude == null) return 'Position unbekannt';
    final ns = (latitude! >= 0) ? 'N' : 'S';
    final ew = (longitude! >= 0) ? 'O' : 'W';
    return '${latitude!.abs().toStringAsFixed(1)}°$ns, ${longitude!.abs().toStringAsFixed(1)}°$ew';
  }
}

class PubMedStudy {
  final String id;
  final String title;
  final String? source;
  final String? pubDate;
  final List<String> authors;
  final String pubmedUrl;

  const PubMedStudy({
    required this.id,
    required this.title,
    this.source,
    this.pubDate,
    required this.authors,
    required this.pubmedUrl,
  });

  factory PubMedStudy.fromJson(String id, Map<String, dynamic> j) {
    final authorList = (j['authors'] as List? ?? [])
        .map((a) => (a as Map<String, dynamic>)['name'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .take(3)
        .toList();
    return PubMedStudy(
      id: id,
      title: j['title'] as String? ?? 'Kein Titel',
      source: j['source'] as String?,
      pubDate: j['pubdate'] as String?,
      authors: authorList,
      pubmedUrl: 'https://pubmed.ncbi.nlm.nih.gov/$id/',
    );
  }
}

class GuardianArticle {
  final String id;
  final String webTitle;
  final String webUrl;
  final String? sectionName;
  final String? webPublicationDate;
  final String? trailText;
  final String? thumbnail;

  const GuardianArticle({
    required this.id,
    required this.webTitle,
    required this.webUrl,
    this.sectionName,
    this.webPublicationDate,
    this.trailText,
    this.thumbnail,
  });

  factory GuardianArticle.fromJson(Map<String, dynamic> j) {
    final fields = j['fields'] as Map<String, dynamic>? ?? {};
    return GuardianArticle(
      id: j['id'] as String? ?? '',
      webTitle: j['webTitle'] as String? ?? 'Kein Titel',
      webUrl: j['webUrl'] as String? ?? '',
      sectionName: j['sectionName'] as String?,
      webPublicationDate: j['webPublicationDate'] as String?,
      trailText: fields['trailText'] as String?,
      thumbnail: fields['thumbnail'] as String?,
    );
  }
}

class WikidataEntry {
  final String id;
  final String label;
  final String? description;
  final String url;

  const WikidataEntry({
    required this.id,
    required this.label,
    this.description,
    required this.url,
  });

  factory WikidataEntry.fromJson(Map<String, dynamic> j) => WikidataEntry(
        id: j['id'] as String? ?? '',
        label: j['label'] as String? ?? '',
        description: j['description'] as String?,
        url: j['url'] as String? ?? 'https://www.wikidata.org/wiki/${j['id']}',
      );
}

class DonkiEvent {
  final String? activityId;
  final String? startTime;
  final String? note;
  final String? link;
  final List<String> instruments;

  const DonkiEvent({
    this.activityId,
    this.startTime,
    this.note,
    this.link,
    required this.instruments,
  });

  factory DonkiEvent.fromJson(Map<String, dynamic> j) {
    final instrList = (j['instruments'] as List? ?? [])
        .map((i) => (i as Map<String, dynamic>)['displayName'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    return DonkiEvent(
      activityId: j['activityID'] as String?,
      startTime: j['startTime'] as String?,
      note: j['note'] as String?,
      link: j['link'] as String?,
      instruments: instrList,
    );
  }

  DateTime? get parsedStart {
    try {
      if (startTime != null) return DateTime.parse(startTime!);
    } catch (_) {}
    return null;
  }

  String get intensityLabel {
    if (note == null) return 'Unbekannt';
    final n = note!.toLowerCase();
    if (n.contains('x-class') || n.contains('x1') || n.contains('extreme')) return 'X-Klasse (Extrem)';
    if (n.contains('m-class') || n.contains('m1') || n.contains('strong')) return 'M-Klasse (Stark)';
    if (n.contains('c-class')) return 'C-Klasse (Mittel)';
    return 'Gemessen';
  }
}

class DailyQuote {
  final String content;
  final String author;
  final List<String> tags;

  const DailyQuote({
    required this.content,
    required this.author,
    required this.tags,
  });

  factory DailyQuote.fromJson(Map<String, dynamic> j) => DailyQuote(
        content: j['content'] as String? ?? '',
        author: j['author'] as String? ?? 'Unbekannt',
        tags: List<String>.from(j['tags'] as List? ?? []),
      );
}

class SunData {
  final DateTime? sunrise;
  final DateTime? sunset;
  final Duration? dayLength;

  const SunData({this.sunrise, this.sunset, this.dayLength});

  factory SunData.fromJson(Map<String, dynamic> j) {
    DateTime? parseUtc(String? s) {
      try {
        if (s != null) return DateTime.parse(s).toLocal();
      } catch (_) {}
      return null;
    }

    final rise = parseUtc(j['sunrise'] as String?);
    final set = parseUtc(j['sunset'] as String?);
    Duration? dayLen;
    if (rise != null && set != null) {
      dayLen = set.difference(rise);
    }
    return SunData(sunrise: rise, sunset: set, dayLength: dayLen);
  }

  String get sunriseFormatted {
    if (sunrise == null) return '--:--';
    return '${sunrise!.hour.toString().padLeft(2, '0')}:${sunrise!.minute.toString().padLeft(2, '0')}';
  }

  String get sunsetFormatted {
    if (sunset == null) return '--:--';
    return '${sunset!.hour.toString().padLeft(2, '0')}:${sunset!.minute.toString().padLeft(2, '0')}';
  }
}

class MoonPhase {
  /// 0.0 = Neumond, 0.25 = Erstes Viertel, 0.5 = Vollmond, 0.75 = Letztes Viertel
  final double phase;

  const MoonPhase({required this.phase});

  String get emoji {
    if (phase < 0.0625) return '🌑';
    if (phase < 0.1875) return '🌒';
    if (phase < 0.3125) return '🌓';
    if (phase < 0.4375) return '🌔';
    if (phase < 0.5625) return '🌕';
    if (phase < 0.6875) return '🌖';
    if (phase < 0.8125) return '🌗';
    if (phase < 0.9375) return '🌘';
    return '🌑';
  }

  String get name {
    if (phase < 0.0625) return 'Neumond';
    if (phase < 0.1875) return 'Zunehmend (Sichel)';
    if (phase < 0.3125) return 'Erstes Viertel';
    if (phase < 0.4375) return 'Zunehmend (Gibbös)';
    if (phase < 0.5625) return 'Vollmond';
    if (phase < 0.6875) return 'Abnehmend (Gibbös)';
    if (phase < 0.8125) return 'Letztes Viertel';
    if (phase < 0.9375) return 'Abnehmend (Sichel)';
    return 'Neumond';
  }

  /// Prozent Beleuchtung (0–100)
  int get illuminationPercent {
    // Annäherung: sin²(phase * π)
    final illum = math.pow(math.sin(phase * math.pi), 2);
    return (illum * 100).round();
  }
}
