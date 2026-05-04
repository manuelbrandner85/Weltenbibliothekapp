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

  final _free = FreeApiService();

  /// Wikidata-Entity holen — Identität (Name, Beschreibung, Bild, Typ).
  Future<Map<String, dynamic>?> fetchIdentity(String topic) async {
    try {
      final entities = await _free.fetchWikidataEntities(topic, limit: 1);
      if (entities.isEmpty) return null;
      return entities.first;
    } catch (e) {
      debugPrint('Identity-Error: $e');
      return null;
    }
  }

  /// Netzwerk: über Wikidata-SPARQL verwandte Entitäten holen.
  Future<List<NetworkNode>> fetchNetworkNodes(String topic) async {
    try {
      final results = await _free.fetchWikidataEntities(topic, limit: 8);
      final nodes = <NetworkNode>[
        NetworkNode(id: 'center', label: topic, type: 'concept', weight: 1.0),
      ];
      for (var i = 0; i < results.length; i++) {
        final r = results[i];
        nodes.add(NetworkNode(
          id: 'n$i',
          label: (r['label'] ?? r['name'] ?? '?').toString(),
          type: _guessType(r['description']?.toString() ?? ''),
          weight: 0.7 - (i * 0.05),
        ));
      }
      return nodes;
    } catch (_) {
      return [NetworkNode(id: 'center', label: topic, type: 'concept', weight: 1.0)];
    }
  }

  String _guessType(String desc) {
    final d = desc.toLowerCase();
    if (d.contains('company') || d.contains('corporation') || d.contains('firma')) return 'company';
    if (d.contains('politician') || d.contains('person') || d.contains('researcher')) return 'person';
    if (d.contains('organization') || d.contains('foundation')) return 'org';
    return 'concept';
  }

  /// Quellen aggregieren — offizielle (Wikipedia/Guardian) + alternative (CrossRef/Retracted).
  Future<List<SourceItem>> fetchSources(String topic) async {
    final results = <SourceItem>[];

    try {
      final guardianFuture = _free.fetchGuardianNews(topic, limit: 4);
      final crossrefFuture = _free.fetchCrossRefWorks(topic, limit: 4);

      final responses = await Future.wait([guardianFuture, crossrefFuture],
          eagerError: false);

      // Guardian → official
      final guardian = (responses[0] as List?) ?? const [];
      for (final g in guardian.take(3)) {
        final m = g as Map<String, dynamic>;
        results.add(SourceItem(
          title: (m['title'] ?? '').toString(),
          url: (m['url'] ?? '').toString(),
          snippet: (m['section'] ?? '').toString(),
          lens: SourceLens.official,
          credibility: 78,
        ));
      }

      // CrossRef → mostly neutral / scientific
      final crossref = responses[1];
      if (crossref is List) {
        for (final c in crossref.take(3)) {
          final m = c as Map<String, dynamic>;
          results.add(SourceItem(
            title: (m['title'] ?? '').toString(),
            url: 'https://doi.org/${m['doi'] ?? ''}',
            snippet: '${m['publisher'] ?? ''} · ${m['year'] ?? ''}',
            lens: SourceLens.neutral,
            credibility: 85,
          ));
        }
      }
    } catch (e) {
      debugPrint('Sources-Error: $e');
    }

    return results;
  }

  /// Zeitstrahl: GDELT-Events + Wikipedia OnThisDay.
  Future<List<TimelineEntry>> fetchTimeline(String topic) async {
    final entries = <TimelineEntry>[];
    try {
      final gdelt = await _free.fetchGdeltEvents(topic, limit: 6);
      for (final g in gdelt) {
        final m = g as Map<String, dynamic>;
        final dateStr = (m['seendate'] ?? '').toString();
        final year = int.tryParse(dateStr.substring(0, 4)) ?? DateTime.now().year;
        entries.add(TimelineEntry(
          year: year,
          title: (m['title'] ?? '').toString(),
          sourceUrl: (m['url'] ?? '').toString(),
        ));
      }
    } catch (e) {
      debugPrint('Timeline-Error: $e');
    }
    entries.sort((a, b) => a.year.compareTo(b.year));
    return entries;
  }

  /// Geldflüsse — Heuristik: aus Wikidata "owner of"/"subsidiary of" Felder
  /// + bekannte öffentliche Datenbanken. Stub-Demo wenn keine echten Daten.
  Future<List<MoneyFlow>> fetchMoneyFlows(String topic) async {
    // Phase 1: Aus Wikidata-Description extrahieren (Light-Version).
    // Echte OpenSecrets/SEC-Integration kommt in Phase 2.
    return const [];
  }

  /// Verwandte Pfade — algorithmisch aus Wikidata + Datamuse.
  Future<List<String>> fetchRelatedTopics(String topic) async {
    final result = <String>{};
    try {
      final assoc = await _free.fetchWordAssociations(topic, limit: 8);
      for (final a in assoc) {
        final word = (a['word'] ?? '').toString();
        if (word.isNotEmpty && word.toLowerCase() != topic.toLowerCase()) {
          result.add(word);
        }
      }
    } catch (_) {}

    if (result.length < 6) {
      try {
        final entities = await _free.fetchWikidataEntities(topic, limit: 10);
        for (final e in entities) {
          final label = (e['label'] ?? '').toString();
          if (label.isNotEmpty && label.toLowerCase() != topic.toLowerCase()) {
            result.add(label);
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
      // Worker AI returns various shapes; try common keys
      return (data['response'] ?? data['answer'] ?? data['text'] ?? data['result'])
          ?.toString()
          .trim();
    } catch (e) {
      debugPrint('VIRGIL-Error: $e');
      return null;
    }
  }
}
