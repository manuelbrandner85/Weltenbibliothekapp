import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/search_history.dart';

/// Search History Service v9.0 (SharedPreferences)
///
/// Manages search history – last 50 searches, auto-cleanup, filter.
class SearchHistoryService {
  static const String _kHistory = 'search_history';
  static const int _maxHistoryEntries = 50;

  static List<SearchHistoryEntry> _entries = [];
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
    await _cleanupOldEntries();
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
    _entries.removeWhere((e) => e.query.toLowerCase() == query.toLowerCase());

    final entry = SearchHistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      query: query,
      timestamp: DateTime.now(),
      resultCount: resultCount,
      summary: summary,
      tags: tags,
      metadata: metadata,
    );

    _entries.add(entry);
    await _cleanupOldEntries();
    await _persist();
  }

  // ==================== READ ====================

  static List<SearchHistoryEntry> getAllHistory() {
    return List.of(_entries)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  static List<SearchHistoryEntry> getRecentHistory({int limit = 10}) {
    return getAllHistory().take(limit).toList();
  }

  static List<SearchHistoryEntry> searchHistory(String query) {
    if (query.isEmpty) return getAllHistory();
    final q = query.toLowerCase();
    return _entries
        .where((e) =>
            e.query.toLowerCase().contains(q) ||
            (e.summary?.toLowerCase().contains(q) ?? false) ||
            (e.tags?.any((tag) => tag.toLowerCase().contains(q)) ?? false))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  static int getHistoryCount() => _entries.length;

  static bool hasQuery(String query) =>
      _entries.any((e) => e.query.toLowerCase() == query.toLowerCase());

  // ==================== DELETE ====================

  static Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    await _persist();
  }

  static Future<void> clearAllHistory() async {
    _entries.clear();
    await _persist();
  }

  static Future<void> deleteOlderThan(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    _entries.removeWhere((e) => e.timestamp.isBefore(cutoff));
    await _persist();
  }

  // ==================== CLEANUP ====================

  static Future<void> _cleanupOldEntries() async {
    if (_entries.length <= _maxHistoryEntries) return;
    _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _entries = _entries.take(_maxHistoryEntries).toList();
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
    final uniqueQueries = _entries.map((e) => e.query.toLowerCase()).toSet().length;
    final totalResults = _entries.fold<int>(0, (sum, e) => sum + e.resultCount);
    final sorted = List.of(_entries)..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return {
      'totalSearches': _entries.length,
      'uniqueQueries': uniqueQueries,
      'averageResultCount': (totalResults / _entries.length).round(),
      'oldestSearch': sorted.first.timestamp,
      'newestSearch': sorted.last.timestamp,
    };
  }
}
