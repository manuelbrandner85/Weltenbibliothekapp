import 'package:hive_flutter/hive_flutter.dart';
import '../models/search_history.dart';

/// Search History Service v8.0
/// 
/// Manages search history with Hive Local Storage
/// - Stores last 50 searches
/// - Auto-cleanup old entries
/// - Search & Filter capabilities
class SearchHistoryService {
  static const String _boxName = 'search_history';
  static const int _maxHistoryEntries = 50;
  static Box<SearchHistoryEntry>? _box;

  /// Initialize Hive & open box
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapter
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SearchHistoryEntryAdapter());
    }
    
    // Open box
    _box = await Hive.openBox<SearchHistoryEntry>(_boxName);
    
    // Auto-cleanup on init
    await _cleanupOldEntries();
  }

  /// Get box instance
  static Box<SearchHistoryEntry> get box {
    if (_box == null || !_box!.isOpen) {
      throw Exception('SearchHistory box not initialized. Call SearchHistoryService.init() first.');
    }
    return _box!;
  }

  // ==================== CREATE ====================

  /// Add search to history
  static Future<void> addSearch({
    required String query,
    int resultCount = 0,
    String? summary,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) async {
    // Check if query already exists (avoid duplicates)
    final existing = box.values
        .where((e) => e.query.toLowerCase() == query.toLowerCase())
        .toList();
    
    // Remove existing entries of same query
    for (var entry in existing) {
      await box.delete(entry.key);
    }
    
    // Create new entry
    final entry = SearchHistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      query: query,
      timestamp: DateTime.now(),
      resultCount: resultCount,
      summary: summary,
      tags: tags,
      metadata: metadata,
    );
    
    await box.put(entry.id, entry);
    
    // Cleanup if exceeds max
    await _cleanupOldEntries();
  }

  // ==================== READ ====================

  /// Get all history entries (sorted by newest first)
  static List<SearchHistoryEntry> getAllHistory() {
    return box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get recent history (last N entries)
  static List<SearchHistoryEntry> getRecentHistory({int limit = 10}) {
    final all = getAllHistory();
    return all.take(limit).toList();
  }

  /// Search in history
  static List<SearchHistoryEntry> searchHistory(String query) {
    if (query.isEmpty) return getAllHistory();
    
    final queryLower = query.toLowerCase();
    return box.values
        .where((e) =>
            e.query.toLowerCase().contains(queryLower) ||
            (e.summary?.toLowerCase().contains(queryLower) ?? false) ||
            (e.tags?.any((tag) => tag.toLowerCase().contains(queryLower)) ?? false))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get history count
  static int getHistoryCount() {
    return box.length;
  }

  /// Check if query exists in history
  static bool hasQuery(String query) {
    return box.values.any((e) => e.query.toLowerCase() == query.toLowerCase());
  }

  // ==================== DELETE ====================

  /// Delete history entry
  static Future<void> deleteEntry(String id) async {
    await box.delete(id);
  }

  /// Clear all history
  static Future<void> clearAllHistory() async {
    await box.clear();
  }

  /// Delete entries older than specified days
  static Future<void> deleteOlderThan(int days) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final idsToDelete = box.values
        .where((e) => e.timestamp.isBefore(cutoffDate))
        .map((e) => e.id)
        .toList();
    
    for (final id in idsToDelete) {
      await box.delete(id);
    }
  }

  // ==================== CLEANUP ====================

  /// Auto-cleanup: Keep only last N entries
  static Future<void> _cleanupOldEntries() async {
    if (box.length <= _maxHistoryEntries) return;
    
    final all = getAllHistory();
    final toDelete = all.skip(_maxHistoryEntries).toList();
    
    for (final entry in toDelete) {
      await box.delete(entry.id);
    }
  }

  // ==================== STATS ====================

  /// Get most searched queries
  static List<String> getMostSearchedQueries({int limit = 10}) {
    final queryCount = <String, int>{};
    
    for (final entry in box.values) {
      final query = entry.query.toLowerCase();
      queryCount[query] = (queryCount[query] ?? 0) + 1;
    }
    
    final sorted = queryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// Get search statistics
  static Map<String, dynamic> getStatistics() {
    final all = box.values.toList();
    
    if (all.isEmpty) {
      return {
        'totalSearches': 0,
        'uniqueQueries': 0,
        'averageResultCount': 0,
        'oldestSearch': null,
        'newestSearch': null,
      };
    }
    
    final uniqueQueries = all.map((e) => e.query.toLowerCase()).toSet().length;
    final totalResults = all.fold<int>(0, (sum, e) => sum + e.resultCount);
    final avgResults = totalResults / all.length;
    
    all.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    return {
      'totalSearches': all.length,
      'uniqueQueries': uniqueQueries,
      'averageResultCount': avgResults.round(),
      'oldestSearch': all.first.timestamp,
      'newestSearch': all.last.timestamp,
    };
  }
}
