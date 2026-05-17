// SmartTagsService — AI-vorgeschlagene Tags für Research-Archive (C4).
//
// suggest()  → ruft Worker /api/ai/tags mit Text auf, kriegt Liste zurück.
// persist()  → schreibt akzeptierte Tags in research_smart_tags.
// listFor()  → liest gespeicherte Tags für einen Archive-Eintrag.

import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/api_config.dart';

class SmartTag {
  final String tag;
  final double? confidence;
  final String source; // 'ai' | 'user'
  const SmartTag({required this.tag, this.confidence, this.source = 'ai'});
}

class SmartTagsService {
  SmartTagsService._();
  static final instance = SmartTagsService._();

  SupabaseClient get _s => Supabase.instance.client;

  /// Schlägt Tags via Worker AI vor (Worker-Endpoint /api/ai/tags muss
  /// existieren — wenn nicht, fällt es auf einfaches Keyword-Extract
  /// zurück mit den häufigsten Substantiven).
  Future<List<SmartTag>> suggest(String text, {int limit = 8}) async {
    if (text.trim().length < 30) return const [];
    try {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.workerUrl}/api/ai/tags'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text, 'limit': limit}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final tags = (body['tags'] as List?) ?? [];
        return tags
            .map((t) => SmartTag(
                  tag: (t is Map ? t['tag'] : t).toString(),
                  confidence:
                      t is Map ? (t['confidence'] as num?)?.toDouble() : null,
                ))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ SmartTags suggest: $e');
    }
    // Lokaler Fallback: häufigste Substantive (>3 Buchstaben).
    return _localFallback(text, limit: limit);
  }

  List<SmartTag> _localFallback(String text, {int limit = 8}) {
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zäöüß\s-]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 4)
        .toList();
    final counts = <String, int>{};
    const stop = {
      'oder', 'aber', 'eine', 'einer', 'einen', 'dieser', 'diese', 'dieses',
      'wenn', 'dann', 'sind', 'haben', 'wird', 'wurde', 'durch', 'gegen',
      'ohne', 'unter', 'über', 'nach', 'noch', 'auch', 'nicht', 'kann',
    };
    for (final w in words) {
      if (stop.contains(w)) continue;
      counts[w] = (counts[w] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .take(limit)
        .map((e) => SmartTag(tag: e.key, confidence: e.value / words.length))
        .toList();
  }

  Future<void> persist(String archiveId, List<SmartTag> tags) async {
    if (tags.isEmpty) return;
    try {
      await _s.from('research_smart_tags').upsert(
        tags
            .map((t) => {
                  'archive_id': archiveId,
                  'tag': t.tag,
                  'source': t.source,
                  'confidence': t.confidence,
                })
            .toList(),
        onConflict: 'archive_id,tag',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ SmartTags persist: $e');
    }
  }

  Future<List<SmartTag>> listFor(String archiveId) async {
    try {
      final res = await _s
          .from('research_smart_tags')
          .select()
          .eq('archive_id', archiveId)
          .order('confidence', ascending: false);
      return (res as List)
          .map((r) {
            final m = Map<String, dynamic>.from(r as Map);
            return SmartTag(
              tag: m['tag'] as String,
              confidence: (m['confidence'] as num?)?.toDouble(),
              source: m['source'] as String? ?? 'ai',
            );
          })
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ SmartTags list: $e');
      return const [];
    }
  }
}
