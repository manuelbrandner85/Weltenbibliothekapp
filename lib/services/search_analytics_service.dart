/// Search Analytics & Related Topics Service
/// Tracks search patterns and suggests related topics
library;

import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';

class SearchAnalytics {
  final String query;
  final DateTime timestamp;
  final int resultCount;
  final Duration searchDuration;
  
  SearchAnalytics({
    required this.query,
    required this.timestamp,
    required this.resultCount,
    required this.searchDuration,
  });
  
  Map<String, dynamic> toJson() => {
    'query': query,
    'timestamp': timestamp.toIso8601String(),
    'resultCount': resultCount,
    'searchDuration': searchDuration.inMilliseconds,
  };
  
  factory SearchAnalytics.fromJson(Map<String, dynamic> json) {
    return SearchAnalytics(
      query: json['query'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      resultCount: json['resultCount'] as int,
      searchDuration: Duration(milliseconds: json['searchDuration'] as int),
    );
  }
}

class SearchAnalyticsService {
  static const String _boxName = 'search_analytics';
  static const int _maxAnalytics = 100;
  
  Box<dynamic>? _box;
  
  /// Initialize
  Future<void> init() async {
    try {
      _box = await Hive.openBox(_boxName);
      if (kDebugMode) {
        debugPrint('✅ [Analytics] Initialized with ${_box!.length} entries');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Analytics] Init failed: $e');
      }
    }
  }
  
  /// Track search
  Future<void> trackSearch({
    required String query,
    required int resultCount,
    required Duration searchDuration,
  }) async {
    if (_box == null) await init();
    
    try {
      final analytics = SearchAnalytics(
        query: query,
        timestamp: DateTime.now(),
        resultCount: resultCount,
        searchDuration: searchDuration,
      );
      
      // Get existing analytics
      final existing = await getAll();
      existing.add(analytics);
      
      // Keep only last N
      if (existing.length > _maxAnalytics) {
        existing.removeRange(0, existing.length - _maxAnalytics);
      }
      
      // Save
      await _box!.put('analytics', existing.map((a) => a.toJson()).toList());
      
      if (kDebugMode) {
        debugPrint('✅ [Analytics] Tracked: "$query" (${existing.length} total)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Analytics] Track failed: $e');
      }
    }
  }
  
  /// Get all analytics
  Future<List<SearchAnalytics>> getAll() async {
    if (_box == null) await init();
    
    try {
      final data = _box!.get('analytics') as List<dynamic>?;
      if (data == null) return [];
      
      return data
          .map((json) => SearchAnalytics.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Analytics] Get failed: $e');
      }
      return [];
    }
  }
  
  /// Get total searches
  Future<int> getTotalSearches() async {
    final analytics = await getAll();
    return analytics.length;
  }
  
  /// Get average search time
  Future<Duration> getAverageSearchTime() async {
    final analytics = await getAll();
    if (analytics.isEmpty) return Duration.zero;
    
    final totalMs = analytics.fold<int>(
      0,
      (sum, a) => sum + a.searchDuration.inMilliseconds,
    );
    
    return Duration(milliseconds: totalMs ~/ analytics.length);
  }
  
  /// Get most searched topics
  Future<List<MapEntry<String, int>>> getTopSearches({int limit = 10}) async {
    final analytics = await getAll();
    
    // Count queries
    final Map<String, int> queryCount = {};
    for (var a in analytics) {
      final query = a.query.toLowerCase();
      queryCount[query] = (queryCount[query] ?? 0) + 1;
    }
    
    // Sort by count
    final sorted = queryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(limit).toList();
  }
  
  /// Get related topics (based on common searches)
  Future<List<String>> getRelatedTopics(String query, {int limit = 5}) async {
    final analytics = await getAll();
    
    // Find searches that contain similar words
    final queryLower = query.toLowerCase();
    final words = queryLower.split(' ');
    
    final Map<String, int> relatedScores = {};
    
    for (var a in analytics) {
      final searchQuery = a.query.toLowerCase();
      if (searchQuery == queryLower) continue; // Skip same query
      
      // Calculate similarity score
      int score = 0;
      for (var word in words) {
        if (searchQuery.contains(word)) {
          score += 2;
        }
      }
      
      if (score > 0) {
        relatedScores[a.query] = (relatedScores[a.query] ?? 0) + score;
      }
    }
    
    // Sort by score
    final sorted = relatedScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Return top related
    return sorted.take(limit).map((e) => e.key).toList();
  }
  
  /// Get searches today
  Future<int> getSearchesToday() async {
    final analytics = await getAll();
    final today = DateTime.now();
    
    return analytics.where((a) =>
      a.timestamp.year == today.year &&
      a.timestamp.month == today.month &&
      a.timestamp.day == today.day
    ).length;
  }
  
  /// Get searches this week
  Future<int> getSearchesThisWeek() async {
    final analytics = await getAll();
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    return analytics.where((a) => a.timestamp.isAfter(weekAgo)).length;
  }
  
  /// Clear all analytics
  Future<void> clearAll() async {
    if (_box == null) await init();
    
    try {
      await _box!.delete('analytics');
      if (kDebugMode) {
        debugPrint('✅ [Analytics] Cleared all');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Analytics] Clear failed: $e');
      }
    }
  }
}
