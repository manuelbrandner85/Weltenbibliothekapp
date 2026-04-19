import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// 🔍 SEARCH SUGGESTIONS SERVICE
/// Provides auto-complete suggestions based on:
/// - Recent searches (from local history)
/// - Trending topics (hardcoded + dynamic)
/// - Popular keywords (frequency analysis)
class SearchSuggestionsService {
  static const String _historyBoxName = 'search_history';
  static const int _maxHistoryItems = 50;
  static const int _maxSuggestions = 8;
  
  /// 📊 TRENDING TOPICS (hardcoded - can be replaced with API call)
  static const List<String> _trendingTopics = [
    'Illuminati',
    'UFO Sichtungen',
    'Chemtrails',
    'MK-Ultra',
    'Operation Paperclip',
    'Panama Papers',
    'Epstein Files',
    'Freimaurerei',
    'NWO',
    'Bilderberg Gruppe',
    'HAARP',
    'Fluorid',
    'Mondlandung',
    '9/11',
    'JFK Attentat',
  ];
  
  /// Get suggestions based on query
  Future<List<SearchSuggestion>> getSuggestions(String query) async {
    if (query.trim().isEmpty) {
      // Return trending topics if no query
      return _trendingTopics
          .take(_maxSuggestions)
          .map((topic) => SearchSuggestion(
                text: topic,
                type: SuggestionType.trending,
                score: 1.0,
              ))
          .toList();
    }
    
    final suggestions = <SearchSuggestion>[];
    final queryLower = query.toLowerCase();
    
    // 1. RECENT SEARCHES (highest priority)
    final recentSearches = await _getRecentSearches();
    final matchingRecent = recentSearches
        .where((search) => search.toLowerCase().contains(queryLower))
        .take(3)
        .map((search) => SearchSuggestion(
              text: search,
              type: SuggestionType.recent,
              score: 1.0,
            ));
    suggestions.addAll(matchingRecent);
    
    // 2. TRENDING TOPICS (matching query)
    final matchingTrending = _trendingTopics
        .where((topic) => topic.toLowerCase().contains(queryLower))
        .take(3)
        .map((topic) => SearchSuggestion(
              text: topic,
              type: SuggestionType.trending,
              score: 0.8,
            ));
    suggestions.addAll(matchingTrending);
    
    // 3. SMART COMPLETIONS (word-based)
    if (queryLower.split(' ').length == 1) {
      // Single word - suggest related topics
      final completions = _getSmartCompletions(queryLower);
      suggestions.addAll(completions.map((text) => SearchSuggestion(
            text: text,
            type: SuggestionType.completion,
            score: 0.6,
          )));
    }
    
    // Sort by score (descending) and limit
    suggestions.sort((a, b) => b.score.compareTo(a.score));
    
    // Remove duplicates (case-insensitive)
    final seen = <String>{};
    final unique = suggestions.where((s) {
      final lower = s.text.toLowerCase();
      if (seen.contains(lower)) return false;
      seen.add(lower);
      return true;
    }).toList();
    
    return unique.take(_maxSuggestions).toList();
  }
  
  /// Get recent searches from local history
  Future<List<String>> _getRecentSearches() async {
    try {
      final box = await Hive.openBox<String>(_historyBoxName);
      final history = box.values.toList();
      history.sort((a, b) => b.compareTo(a)); // Most recent first
      return history.take(_maxHistoryItems).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [SUGGESTIONS] Error loading history: $e');
      }
      return [];
    }
  }
  
  /// Smart completions based on keywords
  List<String> _getSmartCompletions(String query) {
    // Keyword-based completions
    final completions = <String>[];
    
    if (query.contains('illuminat')) {
      completions.addAll(['Illuminati Geschichte', 'Illuminati Symbole', 'Illuminati heute']);
    } else if (query.contains('ufo')) {
      completions.addAll(['UFO Sichtungen 2025', 'UFO Akten', 'UFO Beweise']);
    } else if (query.contains('chem')) {
      completions.addAll(['Chemtrails Beweise', 'Chemtrails heute', 'Chemtrails Analyse']);
    } else if (query.contains('mk') || query.contains('ultra')) {
      completions.addAll(['MK-Ultra Dokumente', 'MK-Ultra Opfer', 'MK-Ultra CIA']);
    } else if (query.contains('epstein')) {
      completions.addAll(['Epstein Files', 'Epstein Liste', 'Epstein Netzwerk']);
    } else if (query.contains('9')) {
      completions.addAll(['9/11 Fakten', '9/11 Untersuchung', '9/11 Inside Job']);
    } else if (query.contains('jfk')) {
      completions.addAll(['JFK Attentat', 'JFK Akten', 'JFK Verschwörung']);
    }
    
    return completions.take(2).toList();
  }
  
  /// Save search to history
  Future<void> saveSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    try {
      final box = await Hive.openBox<String>(_historyBoxName);
      
      // Add with timestamp as key
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      await box.put(timestamp, query);
      
      // Cleanup old entries (keep only last 50)
      if (box.length > _maxHistoryItems) {
        final keys = box.keys.toList()..sort();
        final toDelete = keys.take(box.length - _maxHistoryItems);
        for (final key in toDelete) {
          await box.delete(key);
        }
      }
      
      if (kDebugMode) {
        debugPrint('✅ [SUGGESTIONS] Search saved: $query');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [SUGGESTIONS] Error saving search: $e');
      }
    }
  }
  
  /// Clear search history
  Future<void> clearHistory() async {
    try {
      final box = await Hive.openBox<String>(_historyBoxName);
      await box.clear();
      if (kDebugMode) {
        debugPrint('✅ [SUGGESTIONS] History cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [SUGGESTIONS] Error clearing history: $e');
      }
    }
  }
  
  /// Get trending topics (static for now)
  List<String> getTrendingTopics() {
    return _trendingTopics.take(10).toList();
  }
}

/// Search Suggestion Model
class SearchSuggestion {
  final String text;
  final SuggestionType type;
  final double score;
  
  const SearchSuggestion({
    required this.text,
    required this.type,
    required this.score,
  });
  
  /// Get icon for suggestion type
  String get icon {
    switch (type) {
      case SuggestionType.recent:
        return '🕐';
      case SuggestionType.trending:
        return '🔥';
      case SuggestionType.completion:
        return '💡';
    }
  }
}

/// Suggestion Type
enum SuggestionType {
  recent,    // From search history
  trending,  // Popular topics
  completion, // Smart completions
}
