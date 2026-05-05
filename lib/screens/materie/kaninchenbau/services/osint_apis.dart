/// 🕵️ OSINT-API-Layer — alle externen kostenlosen Datenquellen.
///
/// Quellen (alle key-frei):
///  • OpenAlex            — 240M Wissenschaftspaper + Citations
///  • OpenSanctions       — OFAC/EU/UK/UN Sanktionslisten
///  • SEC EDGAR           — US-Firmen-Filings (10-K, 13F)
///  • OpenCorporates      — 200M+ Firmen weltweit (Free-Tier ohne Key)
///  • LittleSis           — Power-Broker-Datenbank
///  • Wayback Machine CDX — alle historischen Web-Snapshots
///  • CourtListener       — US-Gerichtsakten + Urteile
///  • Google Fact Check   — globale Fakten-Checks (optional Key)
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../config/api_config.dart';
import '../models/thread.dart';

class OsintApis {
  static final OsintApis instance = OsintApis._();
  OsintApis._();

  // ═══════════════════════════════════════════════════════════════
  // 1. OPENALEX — wissenschaftliche Papers (kein API-Key)
  // ═══════════════════════════════════════════════════════════════
  Future<List<AcademicPaper>> fetchOpenAlexPapers(String topic,
      {int limit = 6, bool germanize = true}) async {
    try {
      final url = Uri.parse(
          'https://api.openalex.org/works?search=${Uri.encodeComponent(topic)}&per_page=$limit&sort=cited_by_count:desc');
      final resp = await http.get(url, headers: {
        'User-Agent': 'WeltenbibliothekKaninchenbau/1.0 (mailto:dev@weltenbibliothek.app)',
      }).timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return [];
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = (data['results'] as List?) ?? const [];
      var papers = results.map((raw) {
        final m = raw as Map<String, dynamic>;
        final authorships = (m['authorships'] as List?) ?? const [];
        final authors = authorships
            .take(4)
            .map((a) => (a['author']?['display_name'] ?? '').toString())
            .where((s) => s.isNotEmpty)
            .toList();
        return AcademicPaper(
          title: (m['title'] ?? m['display_name'] ?? '').toString(),
          doi: (m['doi'] ?? '').toString().replaceFirst('https://doi.org/', ''),
          authors: authors,
          year: m['publication_year'] as int?,
          citations: (m['cited_by_count'] as int?) ?? 0,
          url: (m['doi'] ?? m['id'] ?? '').toString(),
          source: 'OpenAlex',
        );
      }).toList();

      if (germanize && papers.isNotEmpty) {
        final translated = await translateBatchToGerman(
            papers.map((p) => p.title).toList());
        papers = [
          for (var i = 0; i < papers.length; i++)
            AcademicPaper(
              title: translated[i],
              doi: papers[i].doi,
              authors: papers[i].authors,
              year: papers[i].year,
              citations: papers[i].citations,
              url: papers[i].url,
              source: papers[i].source,
            )
        ];
      }

      return papers;
    } catch (e) {
      debugPrint('OpenAlex-Error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 2. OPENSANCTIONS — Sanktionslisten (kein API-Key)
  // ═══════════════════════════════════════════════════════════════
  Future<List<SanctionEntry>> fetchSanctions(String topic,
      {int limit = 5}) async {
    try {
      final url = Uri.parse(
          'https://api.opensanctions.org/search/default?q=${Uri.encodeComponent(topic)}&limit=$limit');
      final resp = await http.get(url).timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return [];
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = (data['results'] as List?) ?? const [];
      return results.map((raw) {
        final m = raw as Map<String, dynamic>;
        final props = (m['properties'] as Map?) ?? {};
        final datasets = (m['datasets'] as List?)?.cast<String>() ?? [];
        return SanctionEntry(
          name: ((m['caption'] ?? m['name']) ?? '').toString(),
          type: (m['schema'] ?? '').toString(),
          sanctioningAuthorities:
              datasets.map((d) => _prettyDataset(d)).toSet().toList(),
          country: ((props['country'] as List?)?.firstOrNull ?? '').toString(),
          reason: ((props['notes'] as List?)?.firstOrNull ?? '').toString(),
          url: 'https://www.opensanctions.org/entities/${m['id']}',
        );
      }).toList();
    } catch (e) {
      debugPrint('OpenSanctions-Error: $e');
      return [];
    }
  }

  String _prettyDataset(String d) {
    if (d.contains('ofac')) return 'OFAC';
    if (d.contains('eu_')) return 'EU';
    if (d.contains('gb_') || d.contains('uk_')) return 'UK';
    if (d.contains('un_sc')) return 'UN';
    if (d.contains('ch_')) return 'CH';
    return d.split('_').first.toUpperCase();
  }

  // ═══════════════════════════════════════════════════════════════
  // 3. SEC EDGAR — US-Firmen-Filings (kein API-Key)
  // Search-Endpoint via efts.sec.gov (full-text)
  // ═══════════════════════════════════════════════════════════════
  Future<List<Shareholding>> fetchSecHoldings(String topic,
      {int limit = 5}) async {
    try {
      // Full-text search von EDGAR (gibt Filings-Treffer zurück)
      final url = Uri.parse(
          'https://efts.sec.gov/LATEST/search-index?q=${Uri.encodeComponent(topic)}&forms=13F-HR&hits=$limit');
      final resp = await http.get(url, headers: {
        'User-Agent': 'WeltenbibliothekKaninchenbau dev@weltenbibliothek.app',
      }).timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return [];
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final hits = ((data['hits'] as Map?)?['hits'] as List?) ?? const [];
      return hits.map((raw) {
        final m = raw as Map<String, dynamic>;
        final src = (m['_source'] as Map?) ?? {};
        final displayNames = ((src['display_names'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList();
        final holder = displayNames.isNotEmpty ? displayNames.first : 'Unknown';
        return Shareholding(
          holder: holder,
          company: topic,
          source: 'SEC EDGAR',
          url:
              'https://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=${src['ciks']?.first ?? ''}',
        );
      }).toList();
    } catch (e) {
      debugPrint('SEC-Error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 4. OPENCORPORATES — Firmen weltweit (Free Tier ohne Key)
  // ═══════════════════════════════════════════════════════════════
  Future<List<Map<String, dynamic>>> fetchOpenCorporates(String topic,
      {int limit = 5}) async {
    try {
      final url = Uri.parse(
          'https://api.opencorporates.com/v0.4/companies/search?q=${Uri.encodeComponent(topic)}&per_page=$limit');
      final resp = await http.get(url).timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return [];
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = ((data['results'] as Map?)?['companies'] as List?) ?? const [];
      return results.map((raw) {
        final r = raw as Map<String, dynamic>;
        final c = (r['company'] as Map?) ?? {};
        return {
          'name': c['name']?.toString() ?? '',
          'jurisdiction': c['jurisdiction_code']?.toString() ?? '',
          'status': c['current_status']?.toString() ?? '',
          'created': c['incorporation_date']?.toString() ?? '',
          'url': c['opencorporates_url']?.toString() ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('OpenCorporates-Error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 5. LITTLESIS — Power-Broker-Beziehungen (kein API-Key)
  // ═══════════════════════════════════════════════════════════════
  Future<List<PowerRelation>> fetchLittleSisRelations(String topic,
      {int limit = 6}) async {
    try {
      // 1. Entity-ID suchen
      final searchUrl = Uri.parse(
          'https://littlesis.org/api/entities/search?q=${Uri.encodeComponent(topic)}');
      final searchResp =
          await http.get(searchUrl).timeout(const Duration(seconds: 10));
      if (searchResp.statusCode != 200) return [];
      final searchData = jsonDecode(searchResp.body) as Map<String, dynamic>;
      final dataList = (searchData['data'] as List?) ?? const [];
      if (dataList.isEmpty) return [];
      final entityId = (dataList.first as Map)['id'];

      // 2. Beziehungen holen
      final relUrl = Uri.parse(
          'https://littlesis.org/api/entities/$entityId/relationships?per_page=$limit');
      final relResp =
          await http.get(relUrl).timeout(const Duration(seconds: 10));
      if (relResp.statusCode != 200) return [];
      final relData = jsonDecode(relResp.body) as Map<String, dynamic>;
      final rels = (relData['data'] as List?) ?? const [];

      return rels.map((raw) {
        final m = raw as Map;
        final r = (m['attributes'] as Map?) ?? {};
        return PowerRelation(
          entity1: (r['entity1_label'] ?? '').toString(),
          entity2: (r['entity2_label'] ?? '').toString(),
          relationType:
              _categorizeLittleSis((r['category_id'] as int?) ?? 0),
          description: (r['description'] ?? '').toString(),
          amount: r['amount'] as int?,
          url: 'https://littlesis.org/relationships/${m['id']}',
        );
      }).toList();
    } catch (e) {
      debugPrint('LittleSis-Error: $e');
      return [];
    }
  }

  String _categorizeLittleSis(int catId) {
    // LittleSis Category IDs (vereinfacht)
    switch (catId) {
      case 1:
        return 'Position';
      case 3:
        return 'Mitgliedschaft';
      case 4:
        return 'Familie';
      case 5:
        return 'Spende';
      case 6:
        return 'Transaktion';
      case 10:
        return 'Eigentum';
      case 11:
        return 'Hedge';
      case 12:
        return 'Berufliche Beziehung';
      default:
        return 'Verbindung';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 6. WAYBACK MACHINE CDX — historische Snapshots (kein Key)
  // ═══════════════════════════════════════════════════════════════
  Future<List<WaybackSnapshot>> fetchWaybackSnapshots(String topic,
      {int limit = 12}) async {
    // Versucht mehrere Wikipedia-Sprachvarianten + freie Domain-Suche
    final probes = [
      'de.wikipedia.org/wiki/${Uri.encodeComponent(topic.replaceAll(' ', '_'))}',
      'en.wikipedia.org/wiki/${Uri.encodeComponent(topic.replaceAll(' ', '_'))}',
      Uri.encodeComponent(topic), // freie Domain-Suche
    ];

    for (final probe in probes) {
      try {
        final url = Uri.parse(
            'https://web.archive.org/cdx/search/cdx?url=$probe&output=json&limit=$limit&filter=statuscode:200&collapse=timestamp:6');
        final resp = await http.get(url).timeout(const Duration(seconds: 12));
        if (resp.statusCode != 200) continue;
        final data = jsonDecode(resp.body) as List;
        if (data.isEmpty || data.length < 2) continue;
        final header = (data.first as List).map((e) => e.toString()).toList();
        final urlIdx = header.indexOf('original');
        final tsIdx = header.indexOf('timestamp');
        final statusIdx = header.indexOf('statuscode');
        final snapshots = <WaybackSnapshot>[];
        for (var i = 1; i < data.length; i++) {
          final row = (data[i] as List).map((e) => e.toString()).toList();
          if (row.length < header.length) continue;
          final origUrl = row[urlIdx];
          final ts = row[tsIdx];
          snapshots.add(WaybackSnapshot(
            url: origUrl,
            archiveUrl: 'https://web.archive.org/web/$ts/$origUrl',
            timestamp: ts,
            statusCode: int.tryParse(row[statusIdx]) ?? 200,
          ));
        }
        if (snapshots.isNotEmpty) {
          snapshots.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return snapshots.take(limit).toList();
        }
      } catch (e) {
        debugPrint('Wayback-Probe-Error ($probe): $e');
      }
    }
    return [];
  }

  /// Übersetzt eine Liste englischer Texte ins Deutsche (Worker-Proxy mit Groq).
  /// Gibt bei Fehler die Original-Texte zurück (kein Datenverlust).
  Future<List<String>> translateBatchToGerman(List<String> texts) async {
    if (texts.isEmpty) return texts;
    try {
      final url = Uri.parse('${ApiConfig.workerUrl}/api/translate/batch');
      final resp = await http
          .post(url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'items': texts}))
          .timeout(const Duration(seconds: 18));
      if (resp.statusCode != 200) return texts;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final out = (data['translated'] as List?)?.cast<String>();
      return out != null && out.length == texts.length ? out : texts;
    } catch (e) {
      debugPrint('Translate-Error: $e');
      return texts;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 7. COURTLISTENER — US-Gerichtsakten (Read-only ohne Key)
  // ═══════════════════════════════════════════════════════════════
  Future<List<CourtCase>> fetchCourtCases(String topic,
      {int limit = 6, bool germanize = true}) async {
    try {
      final url = Uri.parse(
          'https://www.courtlistener.com/api/rest/v3/search/?q=${Uri.encodeComponent(topic)}&type=o&order_by=score+desc');
      final resp = await http.get(url).timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return [];
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = (data['results'] as List?) ?? const [];
      var cases = results.take(limit).map((raw) {
        final m = raw as Map<String, dynamic>;
        return CourtCase(
          caseName: (m['caseName'] ?? m['caseNameShort'] ?? '').toString(),
          court: (m['court'] ?? '').toString(),
          snippet: (m['snippet'] ?? '').toString(),
          date: (m['dateFiled'] ?? '').toString(),
          url: m['absolute_url'] != null
              ? 'https://www.courtlistener.com${m['absolute_url']}'
              : null,
        );
      }).toList();

      if (germanize && cases.isNotEmpty) {
        final snippets = cases
            .map((c) => (c.snippet == null || c.snippet!.isEmpty)
                ? c.caseName
                : c.snippet!)
            .toList();
        final translated = await translateBatchToGerman(snippets);
        cases = [
          for (var i = 0; i < cases.length; i++)
            CourtCase(
              caseName: cases[i].caseName,
              court: cases[i].court,
              snippet: translated[i],
              date: cases[i].date,
              url: cases[i].url,
            )
        ];
      }
      return cases;
    } catch (e) {
      debugPrint('CourtListener-Error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 8. GOOGLE FACT CHECK TOOLS — via Worker-Proxy (Key bleibt server-side)
  // Falls Worker keinen Key hat: Fallback zu Snopes/Politifact/Correctiv-Links.
  // ═══════════════════════════════════════════════════════════════
  Future<List<FactCheck>> fetchFactChecks(String topic, {int limit = 6}) async {
    final fallbackLinks = [
      FactCheck(
        claim: 'Snopes durchsuchen: $topic',
        verdict: 'Externes Archiv',
        publisher: 'Snopes',
        url: 'https://www.snopes.com/?s=${Uri.encodeComponent(topic)}',
      ),
      FactCheck(
        claim: 'Politifact durchsuchen: $topic',
        verdict: 'Externes Archiv',
        publisher: 'Politifact',
        url:
            'https://www.politifact.com/search/?q=${Uri.encodeComponent(topic)}',
      ),
      FactCheck(
        claim: 'Correctiv durchsuchen: $topic',
        verdict: 'Externes Archiv',
        publisher: 'Correctiv',
        url: 'https://correctiv.org/?s=${Uri.encodeComponent(topic)}',
      ),
    ];

    try {
      // Worker-Proxy aufrufen (API-Key bleibt server-side im Worker)
      final url = Uri.parse(
          '${ApiConfig.workerUrl}/api/factcheck/search?q=${Uri.encodeComponent(topic)}');
      final resp =
          await http.get(url).timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return fallbackLinks;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['fallback'] == true) return fallbackLinks;
      final claims = (data['claims'] as List?) ?? const [];
      final out = <FactCheck>[];
      for (final raw in claims.take(limit)) {
        final m = raw as Map<String, dynamic>;
        final reviews = (m['claimReview'] as List?) ?? const [];
        for (final r in reviews) {
          final review = r as Map<String, dynamic>;
          out.add(FactCheck(
            claim: (m['text'] ?? '').toString(),
            claimant: (m['claimant'] ?? '').toString(),
            verdict: (review['textualRating'] ?? '').toString(),
            publisher: (review['publisher']?['name'] ?? '').toString(),
            url: (review['url'] ?? '').toString(),
            date: (review['reviewDate'] ?? '').toString(),
          ));
        }
      }
      return out.isEmpty ? fallbackLinks : out;
    } catch (e) {
      debugPrint('FactCheck-Error: $e');
      return fallbackLinks;
    }
  }
}


