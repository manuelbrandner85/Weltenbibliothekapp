import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// RechercheService – calls the Supabase Edge Function "recherche"
/// and persists searches in the research_history table.
class RechercheService {
  static final RechercheService _instance = RechercheService._internal();
  factory RechercheService() => _instance;
  RechercheService._internal();

  final _db = Supabase.instance.client;

  // ── AI Search ─────────────────────────────────────────────────────────────

  /// Calls the "recherche" Edge Function.
  /// Returns a Map with keys: query, summary, sources, images, timestamp.
  Future<Map<String, dynamic>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) throw ArgumentError('Query darf nicht leer sein');

    if (kDebugMode) debugPrint('🔍 [Recherche] query: $q');

    final response = await _db.functions.invoke('recherche', body: {'query': q});

    if (response.status != 200) {
      throw Exception('Edge Function Fehler: HTTP ${response.status}');
    }

    final data = response.data as Map<String, dynamic>? ?? {};

    final result = {
      'query':     q,
      'summary':   data['summary'] as String? ?? data['answer'] as String? ?? '',
      'sources':   _normalizeList(data['sources'] ?? data['results'] ?? []),
      'images':    _normalizeList(data['images'] ?? []),
      'timestamp': DateTime.now().toIso8601String(),
    };

    _saveToHistory(q);

    return result;
  }

  // ── History ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getHistory({int limit = 20}) async {
    try {
      final userId = _db.auth.currentUser?.id;
      if (userId == null) return [];
      final rows = await _db
          .from('research_history')
          .select('id, query, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (rows as List).map((r) => {
        'id':        r['id'],
        'query':     r['query'] as String? ?? '',
        'timestamp': r['created_at'],
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Recherche] getHistory error: $e');
      return [];
    }
  }

  Future<void> deleteHistoryEntry(dynamic entryId) async {
    try {
      final userId = _db.auth.currentUser?.id;
      if (userId == null) return;
      await _db
          .from('research_history')
          .delete()
          .eq('id', entryId)
          .eq('user_id', userId);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Recherche] deleteHistoryEntry error: $e');
    }
  }

  // ── Private ───────────────────────────────────────────────────────────────

  void _saveToHistory(String query) {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;
    _db.from('research_history').insert({
      'user_id': userId,
      'query':   query,
    }).catchError((e) {
      if (kDebugMode) debugPrint('⚠️ [Recherche] saveToHistory error: $e');
      return <String, dynamic>{};
    });
  }

  List<Map<String, dynamic>> _normalizeList(dynamic raw) {
    final list = raw as List? ?? [];
    return list.map((item) {
      if (item is Map<String, dynamic>) return item;
      if (item is Map) return Map<String, dynamic>.from(item);
      return <String, dynamic>{'value': item.toString()};
    }).toList();
  }
}
