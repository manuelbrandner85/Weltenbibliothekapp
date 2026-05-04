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
