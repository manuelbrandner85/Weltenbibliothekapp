import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/search_history.dart';

/// Search History Service v10.0 (SharedPreferences)
///
/// Manages search history – last 50 searches, auto-cleanup, filter.
///
/// Performance (v10.0): The in-memory store is kept as an ordered index so
/// query operations no longer re-sort the whole list on every read:
///   * `_entries` maintains a sorted-descending-by-timestamp invariant, so
///     reads (getAllHistory / getRecentHistory / searchHistory) return without
///     an O(n log n) sort per call.
///   * `_queryIndex` holds all lowercased queries for O(1) hasQuery / dedup
///     lookups instead of a linear scan with repeated toLowerCase() calls.
///   * getStatistics computes min/max in a single O(n) pass instead of sorting.
class SearchHistoryService {
  static const String _kHistory = 'search_history';
  static const int _maxHistoryEntries = 50;

  /// Invariant: always sorted descending by timestamp (newest first).
  static List<SearchHistoryEntry> _entries = [];

  /// Lowercased-query index for O(1) existence/dedup checks. Queries are unique
  /// because addSearch replaces an existing entry with the same query.
  static final Set<String> _queryIndex = <String>{};

  static bool _loaded = false;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kHistory);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _entries = list
            .map((e) => SearchHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _entries = [];
      }
    }
    _loaded = true;
    _purgeInvalid();
    // Establish the sorted invariant + index once on load; every later read
    // relies on it instead of sorting again.
    _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    await _cleanupOldEntries();
    _rebuildIndex();
  }

  /// M3: Entfernt leere/Whitespace-only Eintraege aus Altbestaenden.
  static void _purgeInvalid() {
    _entries.removeWhere((e) => e.query.trim().isEmpty);
  }

  /// Rebuilds the lowercased-query index from the current entries. Cheap
  /// (n <= 50) and only needed after a full load or a bulk delete.
  static void _rebuildIndex() {
    _queryIndex
      ..clear()
      ..addAll(_entries.map((e) => e.query.toLowerCase()));
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kHistory,
      jsonEncode(_entries.map((e) => e.toJson()).toList()),
    );
  }

  // ==================== CREATE ====================

  static Future<void> addSearch({
    required String query,
    int resultCount = 0,
    String? summary,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_loaded) await init();
    // M3: leere/Whitespace-Queries nicht speichern.
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    query = trimmed;
    final lower = query.toLowerCase();
    // O(1) index check avoids a full scan when the query is new.
    if (_queryIndex.contains(lower)) {
      _entries.removeWhere((e) => e.query.toLowerCase() == lower);
    }

    final entry = SearchHistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      query: query,
      timestamp: DateTime.now(),
      resultCount: resultCount,
      summary: summary,
      tags: tags,
      metadata: metadata,
    );

    // The new entry is the newest, so it belongs at the front. This keeps the
    // sorted-descending invariant without re-sorting the whole list.
    _entries.insert(0, entry);
    _queryIndex.add(lower);
    await _cleanupOldEntries();
    await _persist();
  }

  // ==================== READ ====================

  static List<SearchHistoryEntry> getAllHistory() {
    // Already sorted (invariant) – just return a defensive copy.
    return List.of(_entries);
  }

  static List<SearchHistoryEntry> getRecentHistory({int limit = 10}) {
    // No sort needed: entries are kept newest-first.
    return _entries.take(limit).toList();
  }

  static List<SearchHistoryEntry> searchHistory(String query) {
    if (query.isEmpty) return getAllHistory();
    final q = query.toLowerCase();
    // Iterating the already-sorted list preserves newest-first order without
    // an extra sort.
    return _entries
        .where(
          (e) =>
              e.query.toLowerCase().contains(q) ||
              (e.summary?.toLowerCase().contains(q) ?? false) ||
              (e.tags?.any((tag) => tag.toLowerCase().contains(q)) ?? false),
        )
        .toList();
  }

  static int getHistoryCount() => _entries.length;

  static bool hasQuery(String query) =>
      _queryIndex.contains(query.toLowerCase());

  // ==================== DELETE ====================

  static Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    _rebuildIndex();
    await _persist();
  }

  static Future<void> clearAllHistory() async {
    _entries.clear();
    _queryIndex.clear();
    await _persist();
  }

  static Future<void> deleteOlderThan(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    _entries.removeWhere((e) => e.timestamp.isBefore(cutoff));
    _rebuildIndex();
    await _persist();
  }

  // ==================== CLEANUP ====================

  static Future<void> _cleanupOldEntries() async {
    if (_entries.length <= _maxHistoryEntries) return;
    // Entries are kept sorted (newest first), so trimming the tail drops the
    // oldest entries without another sort.
    final removed = _entries.sublist(_maxHistoryEntries);
    _entries = _entries.take(_maxHistoryEntries).toList();
    for (final e in removed) {
      _queryIndex.remove(e.query.toLowerCase());
    }
  }

  // ==================== STATS ====================

  static List<String> getMostSearchedQueries({int limit = 10}) {
    final queryCount = <String, int>{};
    for (final e in _entries) {
      final q = e.query.toLowerCase();
      queryCount[q] = (queryCount[q] ?? 0) + 1;
    }
    final sorted = queryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }

  static Map<String, dynamic> getStatistics() {
    if (_entries.isEmpty) {
      return {
        'totalSearches': 0,
        'uniqueQueries': 0,
        'averageResultCount': 0,
        'oldestSearch': null,
        'newestSearch': null,
      };
    }
    // Single O(n) pass for unique count, total results and min/max timestamps
    // instead of an O(n log n) sort just to read the first/last timestamps.
    final uniqueQueries = <String>{};
    var totalResults = 0;
    var oldest = _entries.first.timestamp;
    var newest = _entries.first.timestamp;
    for (final e in _entries) {
      uniqueQueries.add(e.query.toLowerCase());
      totalResults += e.resultCount;
      if (e.timestamp.isBefore(oldest)) oldest = e.timestamp;
      if (e.timestamp.isAfter(newest)) newest = e.timestamp;
    }
    return {
      'totalSearches': _entries.length,
      'uniqueQueries': uniqueQueries.length,
      'averageResultCount': (totalResults / _entries.length).round(),
      'oldestSearch': oldest,
      'newestSearch': newest,
    };
  }
}
