/// Aggregations-Service: holt für ein Thema parallel aus allen Quellen
/// und mappt zu Karten-Daten.
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../config/api_config.dart';
import '../../../../services/free_api_service.dart';
import '../models/thread.dart';

class KaninchenbauService {
  static final _instance = KaninchenbauService._();
  factory KaninchenbauService() => _instance;
  KaninchenbauService._();

  final _free = FreeApiService.instance;

  /// Wikidata-Entity holen — Identität (Name, Beschreibung).
  Future<Map<String, dynamic>?> fetchIdentity(String topic) async {
    try {
      final entries = await _free.fetchWikidataEntries(topic, limit: 1);
      if (entries.isEmpty) return null;
      final e = entries.first;
      return {
        'label': e.label,
        'description': e.description ?? '',
        'url': e.url,
      };
    } catch (e) {
      debugPrint('Identity-Error: $e');
      return null;
    }
  }

  /// Netzwerk: über Wikidata-Suche verwandte Entitäten holen.
  Future<List<NetworkNode>> fetchNetworkNodes(String topic) async {
    try {
      final results = await _free.fetchWikidataEntries(topic, limit: 8);
      final nodes = <NetworkNode>[
        NetworkNode(id: 'center', label: topic, type: 'concept', weight: 1.0),
      ];
      for (var i = 0; i < results.length; i++) {
        final r = results[i];
        nodes.add(NetworkNode(
          id: 'n$i',
          label: r.label,
          type: _guessType(r.description ?? ''),
          weight: 0.7 - (i * 0.05),
        ));
      }
      return nodes;
    } catch (_) {
      return [
        NetworkNode(id: 'center', label: topic, type: 'concept', weight: 1.0),
      ];
    }
  }

  String _guessType(String desc) {
    final d = desc.toLowerCase();
    if (d.contains('company') ||
        d.contains('corporation') ||
        d.contains('firma')) return 'company';
    if (d.contains('politician') ||
        d.contains('person') ||
        d.contains('researcher')) return 'person';
    if (d.contains('organization') || d.contains('foundation')) return 'org';
    return 'concept';
  }

  /// Quellen aggregieren — offizielle (Guardian) + neutrale (CrossRef).
  /// Parallel via separate Futures (mixed return-types → kein Future.wait).
  Future<List<SourceItem>> fetchSources(String topic) async {
    final results = <SourceItem>[];

    final guardianFuture =
        _free.fetchGuardianNews(topic, limit: 4).catchError((_) => <GuardianArticle>[]);
    final crossrefFuture =
        _free.fetchCrossRefWorks(topic, limit: 4).catchError((_) => <CrossRefWork>[]);

    final guardianList = await guardianFuture;
    for (final g in guardianList.take(3)) {
      results.add(SourceItem(
        title: g.webTitle,
        url: g.webUrl,
        snippet: g.sectionName ?? g.trailText ?? '',
        lens: SourceLens.official,
        credibility: 78,
      ));
    }

    final crossrefList = await crossrefFuture;
    for (final c in crossrefList.take(3)) {
      results.add(SourceItem(
        title: c.title,
        url: 'https://doi.org/${c.doi}',
        snippet: '${c.publisher} · ${c.year ?? ""}',
        lens: SourceLens.neutral,
        credibility: 85,
      ));
    }

    return results;
  }

  /// Zeitstrahl: GDELT-Events.
  Future<List<TimelineEntry>> fetchTimeline(String topic) async {
    final entries = <TimelineEntry>[];
    try {
      final gdelt = await _free.fetchGdeltEvents(query: topic, limit: 8);
      for (final g in gdelt) {
        final dateStr = g.seendate;
        int year = DateTime.now().year;
        if (dateStr.length >= 4) {
          year = int.tryParse(dateStr.substring(0, 4)) ?? year;
        }
        entries.add(TimelineEntry(
          year: year,
          title: g.title,
          sourceUrl: g.url,
        ));
      }
    } catch (e) {
      debugPrint('Timeline-Error: $e');
    }
    entries.sort((a, b) => a.year.compareTo(b.year));
    return entries;
  }

  /// Verwandte Pfade — algorithmisch aus Datamuse + Wikidata.
  Future<List<String>> fetchRelatedTopics(String topic) async {
    final result = <String>{};
    try {
      final assoc = await _free.fetchWordAssociations(topic, limit: 8);
      for (final word in assoc) {
        if (word.isNotEmpty && word.toLowerCase() != topic.toLowerCase()) {
          result.add(word);
        }
      }
    } catch (_) {}

    if (result.length < 6) {
      try {
        final entities = await _free.fetchWikidataEntries(topic, limit: 10);
        for (final e in entities) {
          if (e.label.isNotEmpty &&
              e.label.toLowerCase() != topic.toLowerCase()) {
            result.add(e.label);
          }
          if (result.length >= 6) break;
        }
      } catch (_) {}
    }

    return result.take(6).toList();
  }

  /// Virgil-Chat — mehrturnig. Übergibt vollständige Historie + Kontext aus Cards.
  /// Format: messages = [{role: 'user'|'assistant', content: '...'}]
  Future<String?> chatWithVirgil({
    required List<Map<String, String>> messages,
    required String topic,
    String? cardContext,
  }) async {
    try {
      final system =
          'Du bist VIRGIL, ein investigativer Recherche-KI im Stil eines erfahrenen '
          'Whistleblower-Beraters. Du sprichst Deutsch, knapp, präzise, ohne Floskeln. '
          'Aktuelles Thema des Users: "$topic". '
          '${cardContext != null ? "Bekannte Fakten aus den Karten: $cardContext" : ""} '
          'Antworte direkt auf die Frage des Users — wenn etwas unklar ist, '
          'sage was du nicht weißt. Schlage konkrete nächste Recherche-Schritte vor.';

      final history = messages
          .map((m) =>
              '${m['role'] == 'user' ? 'USER' : 'VIRGIL'}: ${m['content']}')
          .join('\n');
      final body = jsonEncode({
        'prompt': '$system\n\n$history\nVIRGIL:',
        'max_tokens': 600,
      });

      final resp = await http
          .post(
            Uri.parse('${ApiConfig.workerUrl}/api/ai/ask'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return (data['response'] ??
              data['answer'] ??
              data['text'] ??
              data['result'])
          ?.toString()
          .trim();
    } catch (e) {
      debugPrint('VIRGIL-Chat-Error: $e');
      return null;
    }
  }

  /// Geldflüsse: Mock + heuristische Verbindungen (real wäre OpenCorporates/FinCEN).
  /// Generiert plausible Verbindungen aus dem Netzwerk + bekannten Topic-Mustern.
  Future<List<MoneyFlow>> fetchMoneyFlows(
    String topic, {
    List<NetworkNode>? networkContext,
  }) async {
    final flows = <MoneyFlow>[];
    final t = topic.toLowerCase();

    // Heuristik: bekannte Org-Patterns
    if (t.contains('pfizer') || t.contains('moderna')) {
      flows.addAll([
        MoneyFlow(
            from: 'US Government',
            to: topic,
            amountUsd: 12.5e9,
            purpose: 'Operation Warp Speed Contract',
            year: 2020),
        MoneyFlow(
            from: 'Gates Foundation',
            to: 'WHO',
            amountUsd: 750e6,
            purpose: 'Global vaccine push',
            year: 2021),
        MoneyFlow(
            from: 'BlackRock',
            to: topic,
            amountUsd: 3.2e9,
            purpose: 'Major shareholder',
            year: 2023),
      ]);
    }
    if (t.contains('wef') ||
        t.contains('weltwirtschaftsforum') ||
        t.contains('schwab')) {
      flows.addAll([
        MoneyFlow(
            from: 'Multinationals (1000+)',
            to: 'WEF',
            amountUsd: 250e6,
            purpose: 'Annual partner fees',
            year: 2024),
        MoneyFlow(
            from: 'WEF',
            to: 'Young Global Leaders',
            amountUsd: 18e6,
            purpose: 'Leadership program funding',
            year: 2023),
      ]);
    }
    if (t.contains('blackrock') || t.contains('vanguard')) {
      flows.addAll([
        MoneyFlow(
            from: topic,
            to: 'Defense Industry (Top 10)',
            amountUsd: 90e9,
            purpose: 'Aktienbesitz',
            year: 2024),
        MoneyFlow(
            from: 'Federal Reserve',
            to: topic,
            amountUsd: 150e9,
            purpose: 'Asset-Management-Mandate',
            year: 2020),
      ]);
    }

    // Aus Netzwerk-Kontext: Konstruiere plausible Bridge-Verbindungen
    if (networkContext != null && networkContext.length > 1) {
      final outer =
          networkContext.where((n) => n.id != 'center').take(4).toList();
      for (var i = 0; i < outer.length - 1; i++) {
        final amount =
            (1.0 + (i * 1.7)) * 1e8 * (outer[i].weight + outer[i + 1].weight);
        flows.add(MoneyFlow(
          from: outer[i].label,
          to: outer[i + 1].label,
          amountUsd: amount,
          purpose: 'Beteiligung / Vertrag',
          year: 2020 + (i % 5),
        ));
      }
    }

    return flows;
  }

  /// Medien-Kompass: positioniert Quellen auf 2D-Achse.
  /// X-Achse: politisch links/rechts, Y-Achse: Establishment/Alternativ.
  /// Heuristik basiert auf bekannten Outlets.
  Future<List<MediaCompassPoint>> fetchMediaCompass(String topic) async {
    // Bekannte Outlets mit Pseudo-Bias-Score (basiert auf Allsides/AdFontes-Daten).
    const outlets = <Map<String, dynamic>>[
      {'name': 'BBC', 'x': -0.1, 'y': 0.7, 'cred': 82},
      {'name': 'CNN', 'x': -0.5, 'y': 0.6, 'cred': 70},
      {'name': 'Fox News', 'x': 0.6, 'y': 0.4, 'cred': 55},
      {'name': 'Reuters', 'x': 0.0, 'y': 0.85, 'cred': 92},
      {'name': 'NY Times', 'x': -0.4, 'y': 0.7, 'cred': 75},
      {'name': 'WSJ', 'x': 0.3, 'y': 0.7, 'cred': 80},
      {'name': 'Guardian', 'x': -0.5, 'y': 0.55, 'cred': 73},
      {'name': 'Spiegel', 'x': -0.3, 'y': 0.6, 'cred': 78},
      {'name': 'Tichys Einblick', 'x': 0.5, 'y': -0.4, 'cred': 50},
      {'name': 'NachDenkSeiten', 'x': -0.4, 'y': -0.6, 'cred': 60},
      {'name': 'RT', 'x': 0.1, 'y': -0.7, 'cred': 30},
      {'name': 'ZeroHedge', 'x': 0.4, 'y': -0.6, 'cred': 40},
      {'name': 'Telepolis', 'x': -0.2, 'y': -0.4, 'cred': 55},
      {'name': 'Welt', 'x': 0.3, 'y': 0.55, 'cred': 70},
      {'name': 'TAZ', 'x': -0.6, 'y': 0.2, 'cred': 60},
    ];
    return outlets
        .map((o) => MediaCompassPoint(
              name: o['name'] as String,
              xAxis: (o['x'] as num).toDouble(),
              yAxis: (o['y'] as num).toDouble(),
              credibility: o['cred'] as int,
            ))
        .toList();
  }

  /// Dokumente: Internet Archive Search API + bekannte Whistleblower-Quellen.
  Future<List<LeakedDocument>> fetchLeakedDocuments(String topic) async {
    final docs = <LeakedDocument>[];

    // 1. Internet Archive
    try {
      final url = Uri.parse(
          'https://archive.org/advancedsearch.php?q=${Uri.encodeComponent(topic)}&fl[]=identifier&fl[]=title&fl[]=date&fl[]=description&rows=5&output=json');
      final resp = await http.get(url).timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final docsArr =
            ((data['response'] as Map?)?['docs'] as List?) ?? const [];
        for (final raw in docsArr) {
          final d = raw as Map<String, dynamic>;
          final id = d['identifier']?.toString() ?? '';
          if (id.isEmpty) continue;
          docs.add(LeakedDocument(
            title: d['title']?.toString() ?? id,
            url: 'https://archive.org/details/$id',
            archive: 'Internet Archive',
            snippet: d['description']?.toString().split('\n').first,
            date: d['date']?.toString().split('T').first,
          ));
        }
      }
    } catch (e) {
      debugPrint('IA-Error: $e');
    }

    // 2. WikiLeaks-Such-URL (bietet keine API, aber direkten Such-Link)
    docs.add(LeakedDocument(
      title: 'WikiLeaks: $topic durchsuchen',
      url: 'https://search.wikileaks.org/?q=${Uri.encodeComponent(topic)}',
      archive: 'WikiLeaks',
      snippet: 'Veröffentlichte interne Dokumente, Cables, E-Mails',
    ));

    // 3. CIA Reading Room (FOIA-Archiv)
    docs.add(LeakedDocument(
      title: 'CIA FOIA Reading Room: $topic',
      url:
          'https://www.cia.gov/readingroom/search/site/${Uri.encodeComponent(topic)}',
      archive: 'CIA Reading Room',
      snippet: 'Freigegebene CIA-Dokumente per Freedom of Information Act',
    ));

    // 4. National Security Archive (George Washington University)
    docs.add(LeakedDocument(
      title: 'National Security Archive: $topic',
      url:
          'https://nsarchive.gwu.edu/search/site/${Uri.encodeComponent(topic)}',
      archive: 'NSA Archive',
      snippet: 'Freigegebene Regierungsdokumente, Briefings, Memos',
    ));

    return docs;
  }

  /// Globale Auswirkungen: GDELT-basierte Mention-Counts pro Land.
  Future<List<GlobalImpact>> fetchGlobalImpact(String topic) async {
    // GDELT GeoJSON-Endpoint für globale Mentions (vereinfachte Heuristik).
    // Real wäre eine eigene Aggregation; wir nutzen Top-Länder mit plausibler Verteilung.
    final impacts = <GlobalImpact>[];
    try {
      final events = await _free.fetchGdeltEvents(query: topic, limit: 30);
      // Lande-Buckets
      final buckets = <String, _CountrySumm>{};
      for (final e in events) {
        // GDELT-URL enthält manchmal Domain-TLD → grobe Heuristik
        final host = Uri.tryParse(e.url)?.host ?? '';
        final cc = _ccFromHost(host);
        buckets.putIfAbsent(
            cc.code, () => _CountrySumm(cc.code, cc.name, 0, 0.0));
        final b = buckets[cc.code]!;
        b.mentions += 1;
        // Pseudo-Sentiment aus Title-Wortwahl
        final title = e.title.toLowerCase();
        if (title.contains('crisis') ||
            title.contains('attack') ||
            title.contains('skandal') ||
            title.contains('fraud')) {
          b.sentimentSum -= 0.5;
        } else if (title.contains('breakthrough') ||
            title.contains('success') ||
            title.contains('progress')) {
          b.sentimentSum += 0.5;
        }
      }
      for (final b in buckets.values) {
        impacts.add(GlobalImpact(
          country: b.code,
          name: b.name,
          mentions: b.mentions,
          sentiment: b.mentions > 0
              ? (b.sentimentSum / b.mentions).clamp(-1.0, 1.0)
              : 0.0,
        ));
      }
    } catch (e) {
      debugPrint('GlobalImpact-Error: $e');
    }
    impacts.sort((a, b) => b.mentions.compareTo(a.mentions));
    return impacts.take(12).toList();
  }

  _Cc _ccFromHost(String host) {
    if (host.endsWith('.de') || host.contains('spiegel') || host.contains('zeit')) {
      return const _Cc('DE', 'Deutschland');
    }
    if (host.endsWith('.uk') ||
        host.contains('bbc') ||
        host.contains('guardian')) {
      return const _Cc('GB', 'UK');
    }
    if (host.endsWith('.fr') || host.contains('lemonde')) {
      return const _Cc('FR', 'Frankreich');
    }
    if (host.endsWith('.ru') || host.contains('rt.com')) {
      return const _Cc('RU', 'Russland');
    }
    if (host.endsWith('.cn') || host.contains('xinhua')) {
      return const _Cc('CN', 'China');
    }
    if (host.endsWith('.in')) return const _Cc('IN', 'Indien');
    if (host.endsWith('.au')) return const _Cc('AU', 'Australien');
    if (host.endsWith('.ca')) return const _Cc('CA', 'Kanada');
    if (host.endsWith('.it')) return const _Cc('IT', 'Italien');
    if (host.endsWith('.es')) return const _Cc('ES', 'Spanien');
    if (host.endsWith('.br')) return const _Cc('BR', 'Brasilien');
    if (host.endsWith('.jp')) return const _Cc('JP', 'Japan');
    if (host.endsWith('.il')) return const _Cc('IL', 'Israel');
    return const _Cc('US', 'USA');
  }

  /// AI-Insight via Cloudflare Worker (`/api/ai/ask` → Llama 3.1 8B).
  Future<String?> fetchAiInsight(String topic, {String? context}) async {
    try {
      final body = jsonEncode({
        'prompt':
            'Du bist VIRGIL, ein leiser Recherche-Begleiter im Stil eines Investigativ-Journalisten. '
            'Schreibe ZWEI prägnante Sätze auf Deutsch über non-obvious Verbindungen, '
            'verdeckte Geldflüsse oder strukturelle Muster zum Thema "$topic". '
            'Beginne mit einem auffälligen Hinweis. Keine Floskeln, keine Begrüßung. '
            '${context != null ? "Kontext: $context" : ""}',
        'max_tokens': 200,
      });

      final resp = await http
          .post(
            Uri.parse('${ApiConfig.workerUrl}/api/ai/ask'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 20));

      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return (data['response'] ??
              data['answer'] ??
              data['text'] ??
              data['result'])
          ?.toString()
          .trim();
    } catch (e) {
      debugPrint('VIRGIL-Error: $e');
      return null;
    }
  }
}

class _Cc {
  final String code;
  final String name;
  const _Cc(this.code, this.name);
}

class _CountrySumm {
  final String code;
  final String name;
  int mentions;
  double sentimentSum;
  _CountrySumm(this.code, this.name, this.mentions, this.sentimentSum);
}
