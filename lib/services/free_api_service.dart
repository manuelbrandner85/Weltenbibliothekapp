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
      return articles
          .map((a) => GdeltArticle.fromJson(a as Map<String, dynamic>))
          .toList();
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
  Future<List<PubMedStudy>> fetchPubMedStudies(
    String query, {
    int limit = 8,
  }) async {
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
          .map(
            (id) =>
                PubMedStudy.fromJson(id, result[id] as Map<String, dynamic>),
          )
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
  Future<List<GuardianArticle>> fetchGuardianNews(
    String query, {
    int limit = 10,
  }) async {
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
  Future<List<WikidataEntry>> fetchWikidataEntries(
    String query, {
    int limit = 10,
  }) async {
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
  // 6b. WIKIDATA RELATIONEN (R2)
  // Holt die echten Property-Verknuepfungen einer Entity:
  //   P361 (part-of), P463 (member-of), P108 (employer),
  //   P39 (position held), P127 (owned-by), P749 (parent-org),
  //   P159 (HQ location).
  // ─────────────────────────────────────────────────────────────────────────
  static const Map<String, String> _wikidataRelationProps = {
    'P361': 'Teil von',
    'P463': 'Mitglied',
    'P108': 'Arbeitgeber',
    'P39': 'Position',
    'P127': 'Eigentuemer',
    'P749': 'Mutterorg',
    'P159': 'Hauptsitz',
    'P488': 'Vorsitz',
    'P169': 'CEO',
    'P102': 'Partei',
    'P54': 'Mitgliedsorg',
    'P26': 'Ehepartner',
    'P22': 'Vater',
    'P25': 'Mutter',
    'P40': 'Kind',
    'P3373': 'Geschwister',
    'P1037': 'Direktor',
    'P112': 'Gruender',
    'P1830': 'Eigner von',
    'P355': 'Tochterfirma',
    'P138': 'Benannt nach',
    'P276': 'Ort',
    'P800': 'Hauptwerk',
    'P937': 'Wirkungsort',
  };

  /// Klassifiziert Wikidata-Entities anhand der Property P31 (instance of).
  /// Returnt fuer jede ID einen Typ-String ('person' | 'organisation' |
  /// 'location' | 'concept'). Unbekannte/leere → 'concept'.
  ///
  /// Diese Methode ersetzt die fehleranfaellige String-Heuristik auf der
  /// Description (die fuer 95 % der Wikidata-Entries 'concept' liefert,
  /// weil de/en-Descriptions oft nicht die Schluesselworte enthalten).
  Future<Map<String, String>> fetchWikidataClassification(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return {};
    // Wikidata wbgetentities erlaubt max 50 IDs pro Call.
    final out = <String, String>{};
    for (var i = 0; i < ids.length; i += 50) {
      final chunk = ids.skip(i).take(50).toList();
      final url = Uri.parse(
        'https://www.wikidata.org/w/api.php'
        '?action=wbgetentities'
        '&ids=${chunk.join('|')}'
        '&props=claims'
        '&format=json'
        '&origin=*',
      );
      try {
        final res = await http.get(url).timeout(_timeout);
        if (res.statusCode != 200) continue;
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final entities = data['entities'] as Map<String, dynamic>? ?? {};
        entities.forEach((id, raw) {
          final claims = (raw as Map<String, dynamic>)['claims'] as Map?;
          final p31 = claims?['P31'] as List?;
          if (p31 == null) {
            out[id] = 'concept';
            return;
          }
          final classIds = <String>{};
          for (final v in p31) {
            try {
              final mainSnak = (v as Map<String, dynamic>)['mainsnak'];
              final dv = mainSnak?['datavalue'];
              final value = dv?['value'];
              if (value is Map && value['id'] is String) {
                classIds.add(value['id'] as String);
              }
            } catch (_) {
              /* skip malformed */
            }
          }
          out[id] = _classifyByP31(classIds);
        });
      } catch (e) {
        if (kDebugMode) debugPrint('Wikidata-P31: $e');
      }
    }
    return out;
  }

  /// Mappt Wikidata-Klassen-Q-IDs auf unsere 4 Entity-Typen.
  /// Quelle der Q-IDs: https://www.wikidata.org/wiki/Help:Basic_membership_properties
  static String _classifyByP31(Set<String> classIds) {
    // Person
    if (classIds.contains('Q5')) return 'person';
    // Organisation / Unternehmen / NGO / Regierung / Geheimbund
    const orgClasses = {
      'Q43229', // Organisation
      'Q4830453', // Wirtschaftsunternehmen
      'Q891723', // Public company
      'Q163740', // NGO
      'Q484652', // Internationale Organisation
      'Q7188', // Regierung
      'Q161726', // Multinational
      'Q3623811', // Gesellschaft / Verein
      'Q48204', // Gewerkschaft
      'Q207320', // Geheimorganisation
      'Q2385804', // Bildungseinrichtung
      'Q31629', // Sport-Liga
      'Q11691', // Boerse
      'Q1530705', // Stiftung
      'Q15911314', // Verein
      'Q15265344', // Religionsgemeinschaft
    };
    if (classIds.any(orgClasses.contains)) return 'organisation';
    // Ort: Stadt, Land, Siedlung, Region, Provinz
    const locClasses = {
      'Q515', // Stadt
      'Q6256', // Land
      'Q486972', // Siedlung
      'Q3624078', // Souveraener Staat
      'Q56061', // Verwaltungsgebiet
      'Q35657', // US-Bundesstaat
      'Q82794', // Geografische Region
      'Q1549591', // Grossstadt
      'Q5119', // Hauptstadt
      'Q23442', // Insel
      'Q23397', // See
      'Q4022', // Fluss
      'Q8502', // Berg
      'Q34442', // Strasse
      'Q43702', // Provinz
    };
    if (classIds.any(locClasses.contains)) return 'location';
    return 'concept';
  }

  Future<List<WikidataRelation>> fetchWikidataRelations(String entityId) async {
    if (entityId.isEmpty) return [];
    final url = Uri.parse(
      'https://www.wikidata.org/wiki/Special:EntityData/$entityId.json',
    );
    try {
      final res = await http.get(url).timeout(_timeout);
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final entities = data['entities'] as Map<String, dynamic>?;
      if (entities == null) return [];
      final entity = entities[entityId] as Map<String, dynamic>?;
      if (entity == null) return [];
      final claims = entity['claims'] as Map<String, dynamic>?;
      if (claims == null) return [];

      // Sammle Target-IDs pro Property + sammle alle Target-IDs fuer
      // Batch-Label-Lookup.
      final targetIds = <String>{};
      final pairs =
          <(String, String, String)>[]; // (propId, propLabel, targetId)
      _wikidataRelationProps.forEach((propId, propLabel) {
        final values = claims[propId] as List?;
        if (values == null) return;
        for (final v in values) {
          try {
            final mainSnak = (v as Map<String, dynamic>)['mainsnak'];
            final dv = mainSnak?['datavalue'];
            final value = dv?['value'];
            if (value is Map && value['id'] is String) {
              final tid = value['id'] as String;
              targetIds.add(tid);
              pairs.add((propId, propLabel, tid));
            }
          } catch (_) {
            /* skip malformed */
          }
        }
      });

      if (targetIds.isEmpty) return [];

      // Batch-Label-Lookup ueber wbgetentities (max 50 ids).
      final labels = await _fetchWikidataLabels(targetIds.toList());

      return pairs
          .map(
            (p) => WikidataRelation(
              sourceId: entityId,
              targetId: p.$3,
              targetLabel: labels[p.$3] ?? p.$3,
              propertyId: p.$1,
              propertyLabel: p.$2,
            ),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Wikidata-Relations: $e');
      return [];
    }
  }

  Future<Map<String, String>> _fetchWikidataLabels(List<String> ids) async {
    if (ids.isEmpty) return {};
    final chunk = ids.take(50).toList();
    final url = Uri.parse(
      'https://www.wikidata.org/w/api.php'
      '?action=wbgetentities'
      '&ids=${chunk.join('|')}'
      '&props=labels'
      '&languages=de|en'
      '&format=json'
      '&origin=*',
    );
    try {
      final res = await http.get(url).timeout(_timeout);
      if (res.statusCode != 200) return {};
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final entities = data['entities'] as Map<String, dynamic>? ?? {};
      final out = <String, String>{};
      entities.forEach((id, raw) {
        final labels = (raw as Map<String, dynamic>)['labels'] as Map?;
        if (labels == null) return;
        final de = (labels['de'] as Map?)?['value'] as String?;
        final en = (labels['en'] as Map?)?['value'] as String?;
        out[id] = de ?? en ?? id;
      });
      return out;
    } catch (_) {
      return {};
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 6c. LITTLESIS — Power-Mapping (Eliten/Konzerne/Boards), kostenlos
  // API-Doku: https://littlesis.org/api
  // ─────────────────────────────────────────────────────────────────────────

  /// Sucht LittleSis-Entities (Personen + Organisationen aus US-Eliten-DB).
  /// Liefert Edges, die das Wikidata-Netz erweitern (z.B. Board-Memberships,
  /// Spenden, Familienbeziehungen).
  Future<List<LittleSisRelation>> fetchLittleSisRelations(
    String name, {
    int limit = 10,
  }) async {
    if (name.trim().isEmpty) return [];
    // Step 1: search → entity-ID.
    final searchUrl = Uri.parse(
      'https://littlesis.org/api/entities/search'
      '?q=${Uri.encodeComponent(name)}&num=1',
    );
    try {
      final searchRes = await http.get(searchUrl).timeout(_timeout);
      if (searchRes.statusCode != 200) return [];
      final searchData = jsonDecode(searchRes.body) as Map<String, dynamic>;
      final results = searchData['data'] as List? ?? [];
      if (results.isEmpty) return [];
      final entity = results.first as Map<String, dynamic>;
      final entityId = entity['id'];
      if (entityId == null) return [];
      final entityName =
          (entity['attributes'] as Map?)?['name']?.toString() ?? name;

      // Step 2: relationships fuer diese Entity.
      final relUrl = Uri.parse(
        'https://littlesis.org/api/entities/$entityId/relationships'
        '?page_size=$limit',
      );
      final relRes = await http.get(relUrl).timeout(_timeout);
      if (relRes.statusCode != 200) return [];
      final relData = jsonDecode(relRes.body) as Map<String, dynamic>;
      final rels = relData['data'] as List? ?? [];
      return rels
          .map(
            (r) => LittleSisRelation.fromJson(
              r as Map<String, dynamic>,
              entityName,
            ),
          )
          .where((r) => r.targetName.isNotEmpty)
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('LittleSis: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 6d. OPENCORPORATES — Firmenverflechtungen, Free Tier
  // API-Doku: https://api.opencorporates.com/documentation/API-Reference
  // ─────────────────────────────────────────────────────────────────────────

  /// Sucht Firmen ueber den Namen. Liefert Land, Status, Jurisdiktion +
  /// (best-effort) Officers/Direktoren. Free-Tier: ~200 Calls/Tag ohne Key.
  Future<List<OpenCorpCompany>> fetchOpenCorpCompanies(
    String name, {
    int limit = 5,
  }) async {
    if (name.trim().isEmpty) return [];
    final url = Uri.parse(
      'https://api.opencorporates.com/v0.4.5/companies/search'
      '?q=${Uri.encodeComponent(name)}&per_page=$limit&format=json',
    );
    try {
      final res = await http.get(url).timeout(_timeout);
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final companies =
          ((data['results'] as Map?)?['companies'] as List?) ?? const [];
      return companies
          .map(
            (c) => OpenCorpCompany.fromJson(
              (c as Map<String, dynamic>)['company'] as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('OpenCorporates: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 6e. DBPEDIA SPARQL — strukturierte Verflechtungen mit deutschen Labels
  // Endpoint: https://dbpedia.org/sparql
  // ─────────────────────────────────────────────────────────────────────────

  /// Holt fuer einen DBpedia-Resource-Namen alle Predikate, die mit anderen
  /// DBpedia-Resources verlinken (z.B. dbo:foundedBy, dbo:owner, dbo:member).
  /// Liefert deutsche Labels wenn vorhanden, sonst englische.
  Future<List<DbpediaRelation>> fetchDbpediaRelations(
    String resourceLabel, {
    int limit = 30,
  }) async {
    if (resourceLabel.trim().isEmpty) return [];
    // SPARQL: erst Resource ueber rdfs:label oder Redirect aufloesen,
    // dann alle Object-Properties (mit deutschem Label).
    final sparql =
        '''
PREFIX dbo: <http://dbpedia.org/ontology/>
PREFIX dbr: <http://dbpedia.org/resource/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

SELECT DISTINCT ?propLabel ?targetLabel WHERE {
  {
    ?subject rdfs:label "$resourceLabel"@de .
  } UNION {
    ?subject rdfs:label "$resourceLabel"@en .
  }
  ?subject ?p ?target .
  ?target a ?type . FILTER(isIRI(?target))
  ?p rdfs:label ?propLabel .
  ?target rdfs:label ?targetLabel .
  FILTER(LANG(?propLabel) = "de" || LANG(?propLabel) = "en")
  FILTER(LANG(?targetLabel) = "de" || LANG(?targetLabel) = "en")
  FILTER(STRSTARTS(STR(?p), "http://dbpedia.org/ontology/"))
} LIMIT $limit
''';
    final url = Uri.parse(
      'https://dbpedia.org/sparql'
      '?query=${Uri.encodeComponent(sparql)}'
      '&format=application/sparql-results+json',
    );
    try {
      final res = await http.get(url).timeout(_timeout);
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final bindings =
          ((data['results'] as Map?)?['bindings'] as List?) ?? const [];
      final seen = <String>{};
      final out = <DbpediaRelation>[];
      for (final b in bindings) {
        final propLabel =
            (((b as Map)['propLabel'] as Map?)?['value'] as String?) ?? '';
        final targetLabel =
            ((b['targetLabel'] as Map?)?['value'] as String?) ?? '';
        if (propLabel.isEmpty || targetLabel.isEmpty) continue;
        final key = '$propLabel|$targetLabel';
        if (seen.contains(key)) continue;
        seen.add(key);
        out.add(
          DbpediaRelation(
            sourceLabel: resourceLabel,
            targetLabel: targetLabel,
            propertyLabel: propLabel,
          ),
        );
      }
      return out;
    } catch (e) {
      if (kDebugMode) debugPrint('DBpedia: $e');
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
    fmt(DateTime d) =>
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
  Future<DailyQuote?> fetchDailyQuote({
    String tags = 'wisdom,inspirational',
  }) async {
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
  // 11. Cloudflare Workers AI — Llama 3.1 8B (via eigenem Worker)
  // ─────────────────────────────────────────────────────────────────────────

  static const _workerBase = String.fromEnvironment(
    'CLOUDFLARE_WORKER_URL',
    defaultValue: 'https://weltenbibliothek-api.brandy13062.workers.dev',
  );

  /// Stellt eine Frage an Llama 3.1 8B via Cloudflare Workers AI.
  /// [systemPrompt] optional; Antwort immer auf Deutsch.
  Future<String?> fetchWorkersAI({
    required String question,
    String? systemPrompt,
    int maxTokens = 400,
  }) async {
    final uri = Uri.parse('$_workerBase/api/ai/ask');
    try {
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'question': question,
              if (systemPrompt != null) 'system': systemPrompt,
              'max_tokens': maxTokens,
            }),
          )
          .timeout(_timeout);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['answer'] as String?;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Workers AI: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 13. OpenAlex — Wissenschaftliche Studien (kein API-Key)
  // ─────────────────────────────────────────────────────────────────────────

  /// Sucht 250M+ akademische Arbeiten über OpenAlex. Kein API-Key nötig.
  Future<List<OpenAlexWork>> fetchOpenAlexWorks(
    String query, {
    int limit = 15,
  }) async {
    final url = Uri.parse(
      'https://api.openalex.org/works'
      '?search=${Uri.encodeComponent(query)}'
      '&filter=open_access.is_oa:true'
      '&per-page=$limit'
      '&select=id,title,abstract_inverted_index,authorships,publication_year,doi,open_access,cited_by_count,concepts'
      '&mailto=app@weltenbibliothek.de',
    );
    try {
      final res = await http
          .get(url, headers: {'User-Agent': 'Weltenbibliothek/1.0'})
          .timeout(_timeout);
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results = (data['results'] as List? ?? []);
      return results
          .map((r) => OpenAlexWork.fromJson(r as Map<String, dynamic>))
          .where((w) => w.title.isNotEmpty)
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ OpenAlex: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 14. Wikimedia "On This Day" — Historische Ereignisse
  // ─────────────────────────────────────────────────────────────────────────

  /// Liefert historische Ereignisse für heute (oder angegebenes Datum).
  Future<List<WikiOnThisDay>> fetchOnThisDay({DateTime? date}) async {
    final d = date ?? DateTime.now();
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final url = Uri.parse('https://history.muffinlabs.com/date/$mm/$dd');
    try {
      final res = await http
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(_timeout);
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final events = (data['data']?['Events'] as List? ?? []);
      return events
          .take(30)
          .map((e) => WikiOnThisDay.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ OnThisDay: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 15. Datamuse — Wort-Assoziationen (für Traumsymbole)
  // ─────────────────────────────────────────────────────────────────────────

  /// Liefert semantisch verwandte Begriffe zu [word] (kein API-Key).
  Future<List<String>> fetchWordAssociations(
    String word, {
    int limit = 8,
  }) async {
    final url = Uri.parse(
      'https://api.datamuse.com/words?ml=${Uri.encodeComponent(word)}&max=$limit',
    );
    try {
      final res = await http.get(url).timeout(_timeout);
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as List;
      return data.map((w) => w['word'] as String).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Datamuse: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 16. PubChem — Pflanzenwirkstoffe (NIH, kein API-Key)
  // ─────────────────────────────────────────────────────────────────────────

  /// Sucht aktive Verbindungen einer Heilpflanze in PubChem.
  Future<PubChemResult?> fetchPubChemPlant(String plantName) async {
    final url = Uri.parse(
      'https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/name/${Uri.encodeComponent(plantName)}/property/MolecularFormula,IUPACName,XLogP,Complexity/JSON',
    );
    try {
      final res = await http.get(url).timeout(_timeout);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final props = data['PropertyTable']?['Properties'];
      if (props == null || (props as List).isEmpty) return null;
      return PubChemResult.fromJson(props[0] as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ PubChem: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 17. CrossRef — 165M+ DOIs, kein API-Key
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<CrossRefWork>> fetchCrossRefWorks(
    String query, {
    int limit = 15,
  }) async {
    final url = Uri.parse(
      'https://api.crossref.org/works?query=${Uri.encodeComponent(query)}'
      '&rows=$limit&mailto=app@weltenbibliothek.de'
      '&select=title,author,published-print,DOI,publisher,is-referenced-by-count',
    );
    try {
      final res = await http
          .get(url, headers: {'User-Agent': 'Weltenbibliothek/1.0'})
          .timeout(_timeout);
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final items = (data['message']?['items'] as List? ?? []);
      return items
          .map((i) => CrossRefWork.fromJson(i as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ CrossRef: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 18. Unpaywall — Kostenlose PDF-Links für DOIs
  // ─────────────────────────────────────────────────────────────────────────

  Future<String?> fetchUnpaywallPdf(String doi) async {
    final url = Uri.parse(
      'https://api.unpaywall.org/v2/${Uri.encodeComponent(doi)}?email=app@weltenbibliothek.de',
    );
    try {
      final res = await http.get(url).timeout(_timeout);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['best_oa_location']?['url_for_pdf'] as String?;
    } catch (e) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 19. arXiv — Preprint-Suche (Physik, Mathe, CS, Bio, Wirtschaft)
  // ─────────────────────────────────────────────────────────────────────────

  /// Sucht arXiv-Preprints zu [query]. Kein API-Key noetig.
  Future<List<ArxivEntry>> fetchArxivPapers(
    String query, {
    int limit = 8,
  }) async {
    final url = Uri.parse(
      'https://export.arxiv.org/api/query'
      '?search_query=all:${Uri.encodeComponent(query)}'
      '&max_results=$limit'
      '&sortBy=relevance'
      '&sortOrder=descending',
    );
    try {
      final res = await http
          .get(url, headers: {'User-Agent': 'Weltenbibliothek/1.0'})
          .timeout(_timeout);
      if (res.statusCode != 200) return [];
      return _parseArxivXml(res.body);
    } catch (e) {
      if (kDebugMode) debugPrint('arXiv: $e');
      return [];
    }
  }

  List<ArxivEntry> _parseArxivXml(String xml) {
    final entries = <ArxivEntry>[];
    final entryRx = RegExp(r'<entry>(.*?)</entry>', dotAll: true);
    for (final m in entryRx.allMatches(xml)) {
      final entry = m.group(1) ?? '';
      final id =
          _xmlTag(entry, 'id')?.replaceAll('http://arxiv.org/abs/', '') ?? '';
      final title = _xmlTag(entry, 'title')?.trim() ?? '';
      final summary = _xmlTag(entry, 'summary')?.trim() ?? '';
      final published = _xmlTag(entry, 'published') ?? '';
      final authors = RegExp(
        r'<name>(.*?)</name>',
      ).allMatches(entry).map((a) => a.group(1) ?? '').take(3).toList();
      if (id.isNotEmpty && title.isNotEmpty) {
        entries.add(
          ArxivEntry(
            id: id,
            title: title,
            summary: summary.length > 280
                ? '${summary.substring(0, 280)}...'
                : summary,
            authors: authors,
            published: published.length >= 4
                ? published.substring(0, 4)
                : published,
            url: 'https://arxiv.org/abs/$id',
          ),
        );
      }
    }
    return entries;
  }

  String? _xmlTag(String xml, String tag) => RegExp(
    '<$tag[^>]*>(.*?)</$tag>',
    dotAll: true,
  ).firstMatch(xml)?.group(1)?.trim();

  // ─────────────────────────────────────────────────────────────────────────
  // 20. Wikipedia-Volltextsuche — Artikel und Snippets (kein API-Key)
  // ─────────────────────────────────────────────────────────────────────────

  /// Sucht Wikipedia-Artikel zu [query] (Deutsch bevorzugt, dann Englisch).
  Future<List<WikiSearchEntry>> fetchWikipediaArticles(
    String query, {
    int limit = 8,
    String lang = 'de',
  }) async {
    final url = Uri.parse(
      'https://$lang.wikipedia.org/w/api.php'
      '?action=query&list=search&srsearch=${Uri.encodeComponent(query)}'
      '&srlimit=$limit&format=json&srprop=snippet|titlesnippet&origin=*',
    );
    try {
      final res = await http.get(url).timeout(_timeout);
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final hits = (data['query']?['search'] as List? ?? []);
      return hits
          .map((h) => WikiSearchEntry.fromJson(h as Map<String, dynamic>, lang))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Wikipedia: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 21. Internet Archive — Dokumenten- und Webseiten-Suche
  // ─────────────────────────────────────────────────────────────────────────

  /// Sucht im Internet Archive nach Dokumenten, Buechern und archivierten Seiten.
  Future<List<InternetArchiveDoc>> fetchInternetArchiveDocs(
    String query, {
    int limit = 8,
  }) async {
    final url = Uri.parse(
      'https://archive.org/advancedsearch.php'
      '?q=${Uri.encodeComponent(query)}'
      '&fl=identifier,title,description,date,mediatype,creator'
      '&rows=$limit&page=1&output=json&sort%5B%5D=downloads+desc',
    );
    try {
      final res = await http.get(url).timeout(_timeout);
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final docs = (data['response']?['docs'] as List? ?? []);
      return docs
          .map((d) => InternetArchiveDoc.fromJson(d as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Internet Archive: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 12. Mondphase — Mathematische Berechnung (kein API nötig)
  // ─────────────────────────────────────────────────────────────────────────

  /// Berechnet die aktuelle Mondphase (0.0–1.0, 0=Neumond, 0.5=Vollmond).
  MoonPhase calcMoonPhase([DateTime? date]) {
    final d = date ?? DateTime.now();
    // Bekannte Neumond-Referenz: 6. Januar 2000, 18:14 UTC
    final ref = DateTime.utc(2000, 1, 6, 18, 14);
    const synodicMonth = 29.53058770576; // Tage
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
    } catch (e) {
      if (kDebugMode) debugPrint('free_api_service: silent catch -> $e');
    }
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
    } catch (e) {
      if (kDebugMode) debugPrint('free_api_service: silent catch -> $e');
    }
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

/// Echte Wikidata-Property-Relation zwischen zwei Entities.
class WikidataRelation {
  final String sourceId;
  final String targetId;
  final String targetLabel;
  final String propertyId; // 'P361','P463',...
  final String propertyLabel; // 'Teil von','Mitglied von',...

  const WikidataRelation({
    required this.sourceId,
    required this.targetId,
    required this.targetLabel,
    required this.propertyId,
    required this.propertyLabel,
  });
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
    } catch (e) {
      if (kDebugMode) debugPrint('free_api_service: silent catch -> $e');
    }
    return null;
  }

  String get intensityLabel {
    if (note == null) return 'Unbekannt';
    final n = note!.toLowerCase();
    if (n.contains('x-class') || n.contains('x1') || n.contains('extreme')) {
      return 'X-Klasse (Extrem)';
    }
    if (n.contains('m-class') || n.contains('m1') || n.contains('strong')) {
      return 'M-Klasse (Stark)';
    }
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
      } catch (e) {
        if (kDebugMode) debugPrint('free_api_service: silent catch -> $e');
      }
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

// ─── OpenAlex Work ────────────────────────────────────────────────────────────

class OpenAlexWork {
  final String id;
  final String title;
  final String abstract;
  final List<String> authors;
  final int? year;
  final String? doi;
  final String? openAccessUrl;
  final int citedBy;
  final List<String> concepts;

  const OpenAlexWork({
    required this.id,
    required this.title,
    required this.abstract,
    required this.authors,
    this.year,
    this.doi,
    this.openAccessUrl,
    required this.citedBy,
    required this.concepts,
  });

  factory OpenAlexWork.fromJson(Map<String, dynamic> j) {
    final authList = (j['authorships'] as List? ?? [])
        .take(3)
        .map((a) => (a['author']?['display_name'] ?? '') as String)
        .where((s) => s.isNotEmpty)
        .toList();
    final conceptList = (j['concepts'] as List? ?? [])
        .take(5)
        .map((c) => (c['display_name'] ?? '') as String)
        .where((s) => s.isNotEmpty)
        .toList();
    // Abstract aus inverted index
    String abstract = '';
    final inv = j['abstract_inverted_index'];
    if (inv is Map) {
      final words = <int, String>{};
      (inv as Map<String, dynamic>).forEach((word, positions) {
        for (final pos in (positions as List)) {
          words[pos as int] = word;
        }
      });
      final sortedKeys = words.keys.toList()..sort();
      abstract = sortedKeys.map((k) => words[k]).join(' ');
      if (abstract.length > 300) abstract = '${abstract.substring(0, 300)}…';
    }
    return OpenAlexWork(
      id: j['id'] as String? ?? '',
      title: (j['title'] as String? ?? '').trim(),
      abstract: abstract,
      authors: authList,
      year: j['publication_year'] as int?,
      doi: j['doi'] as String?,
      openAccessUrl: j['open_access']?['oa_url'] as String?,
      citedBy: j['cited_by_count'] as int? ?? 0,
      concepts: conceptList,
    );
  }
}

// ─── Wikimedia On This Day ────────────────────────────────────────────────────

class WikiOnThisDay {
  final int year;
  final String text;
  final List<String> links;

  const WikiOnThisDay({
    required this.year,
    required this.text,
    required this.links,
  });

  factory WikiOnThisDay.fromJson(Map<String, dynamic> j) {
    final linksList = (j['links'] as List? ?? [])
        .map((l) => (l['title'] ?? '') as String)
        .where((s) => s.isNotEmpty)
        .take(3)
        .toList();
    return WikiOnThisDay(
      year: int.tryParse(j['year']?.toString() ?? '') ?? 0,
      text: j['text'] as String? ?? '',
      links: linksList,
    );
  }
}

// ─── PubChem Result ───────────────────────────────────────────────────────────

class PubChemResult {
  final int cid;
  final String formula;
  final String iupacName;

  const PubChemResult({
    required this.cid,
    required this.formula,
    required this.iupacName,
  });

  factory PubChemResult.fromJson(Map<String, dynamic> j) => PubChemResult(
    cid: j['CID'] as int? ?? 0,
    formula: j['MolecularFormula'] as String? ?? '',
    iupacName: j['IUPACName'] as String? ?? '',
  );
}

// ─── CrossRef Work ────────────────────────────────────────────────────────────

class CrossRefWork {
  final String title;
  final List<String> authors;
  final int? year;
  final String doi;
  final String publisher;
  final int citedBy;

  const CrossRefWork({
    required this.title,
    required this.authors,
    this.year,
    required this.doi,
    required this.publisher,
    required this.citedBy,
  });

  factory CrossRefWork.fromJson(Map<String, dynamic> j) {
    final titleList = j['title'] as List?;
    final title = (titleList != null && titleList.isNotEmpty)
        ? titleList[0] as String
        : '';

    final authorList = j['author'] as List? ?? [];
    final authors = authorList
        .take(3)
        .map((a) {
          final family = (a as Map)['family'] as String? ?? '';
          final given = a['given'] as String? ?? '';
          return given.isNotEmpty ? '$given $family' : family;
        })
        .where((s) => s.isNotEmpty)
        .toList();

    final printedDate = j['published-print']?['date-parts'];
    int? year;
    if (printedDate is List && printedDate.isNotEmpty) {
      final parts = printedDate[0] as List?;
      if (parts != null && parts.isNotEmpty) year = parts[0] as int?;
    }

    return CrossRefWork(
      title: title,
      authors: authors,
      year: year,
      doi: j['DOI'] as String? ?? '',
      publisher: j['publisher'] as String? ?? '',
      citedBy: j['is-referenced-by-count'] as int? ?? 0,
    );
  }
}

/// LittleSis-Beziehung zwischen zwei Entitaeten.
class LittleSisRelation {
  final String sourceName;
  final String targetName;
  final String description; // z.B. 'Board member of', 'Donated $5,000 to'
  final String? category; // 'position', 'donation', 'family', 'membership', ...
  final String url;
  const LittleSisRelation({
    required this.sourceName,
    required this.targetName,
    required this.description,
    required this.url,
    this.category,
  });

  factory LittleSisRelation.fromJson(
    Map<String, dynamic> j,
    String sourceName,
  ) {
    final attrs = j['attributes'] as Map<String, dynamic>? ?? {};
    return LittleSisRelation(
      sourceName: sourceName,
      targetName: (attrs['entity2_name'] ?? attrs['entity1_name'] ?? '')
          .toString(),
      description: (attrs['description'] ?? attrs['category'] ?? '').toString(),
      category: attrs['category']?.toString(),
      url:
          (j['links'] as Map?)?['self']?.toString() ??
          'https://littlesis.org/relationships/${j['id']}',
    );
  }
}

/// OpenCorporates-Firma (Free-Tier-Datensatz).
class OpenCorpCompany {
  final String name;
  final String jurisdiction;
  final String? companyNumber;
  final String? status;
  final String? incorporationDate;
  final String? companyType;
  final String url;
  const OpenCorpCompany({
    required this.name,
    required this.jurisdiction,
    required this.url,
    this.companyNumber,
    this.status,
    this.incorporationDate,
    this.companyType,
  });

  factory OpenCorpCompany.fromJson(Map<String, dynamic> j) => OpenCorpCompany(
    name: (j['name'] ?? '').toString(),
    jurisdiction: (j['jurisdiction_code'] ?? '').toString(),
    companyNumber: j['company_number']?.toString(),
    status: j['current_status']?.toString(),
    incorporationDate: j['incorporation_date']?.toString(),
    companyType: j['company_type']?.toString(),
    url: (j['opencorporates_url'] ?? '').toString(),
  );
}

/// DBpedia-Beziehung (Subject → Property → Target).
class DbpediaRelation {
  final String sourceLabel;
  final String targetLabel;
  final String propertyLabel;
  const DbpediaRelation({
    required this.sourceLabel,
    required this.targetLabel,
    required this.propertyLabel,
  });
}

// ─── arXiv Entry ──────────────────────────────────────────────────────────────

class ArxivEntry {
  final String id;
  final String title;
  final String summary;
  final List<String> authors;
  final String published;
  final String url;

  const ArxivEntry({
    required this.id,
    required this.title,
    required this.summary,
    required this.authors,
    required this.published,
    required this.url,
  });

  String get authorsDisplay =>
      authors.take(2).join(', ') + (authors.length > 2 ? ' et al.' : '');
}

// ─── Wikipedia Search Entry ───────────────────────────────────────────────────

class WikiSearchEntry {
  final int pageId;
  final String title;
  final String snippet;
  final String lang;

  const WikiSearchEntry({
    required this.pageId,
    required this.title,
    required this.snippet,
    required this.lang,
  });

  factory WikiSearchEntry.fromJson(Map<String, dynamic> j, String lang) {
    final raw = j['snippet'] as String? ?? '';
    final clean = raw.replaceAll(RegExp(r'<[^>]*>'), '');
    return WikiSearchEntry(
      pageId: j['pageid'] as int? ?? 0,
      title: j['title'] as String? ?? '',
      snippet: clean,
      lang: lang,
    );
  }

  String get url => 'https://$lang.wikipedia.org/?curid=$pageId';
}

// ─── Internet Archive Document ────────────────────────────────────────────────

class InternetArchiveDoc {
  final String identifier;
  final String title;
  final String? description;
  final String? date;
  final String mediatype;
  final String? creator;

  const InternetArchiveDoc({
    required this.identifier,
    required this.title,
    this.description,
    this.date,
    required this.mediatype,
    this.creator,
  });

  factory InternetArchiveDoc.fromJson(Map<String, dynamic> j) {
    String? desc = j['description'] as String?;
    if (desc != null && desc.length > 200)
      desc = '${desc.substring(0, 200)}...';
    return InternetArchiveDoc(
      identifier: j['identifier'] as String? ?? '',
      title: j['title'] as String? ?? '',
      description: desc,
      date: j['date'] as String?,
      mediatype: j['mediatype'] as String? ?? 'texts',
      creator: j['creator'] as String?,
    );
  }

  String get url => 'https://archive.org/details/$identifier';

  String get mediatypeLabel {
    switch (mediatype) {
      case 'texts':
        return 'Dokument';
      case 'movies':
        return 'Video';
      case 'audio':
        return 'Audio';
      case 'software':
        return 'Software';
      default:
        return 'Datei';
    }
  }
}
