import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'search_history_service.dart';

/// AI-Powered Search Suggestions Service
/// Analyzes user behavior and provides intelligent recommendations
class AISearchSuggestionService {
  // Backend URL
  static const String _backendUrl = 'https://weltenbibliothek-api-v2.brandy13062.workers.dev';
  
  // SharedPreferences Keys
  static const String _interestsKey = 'ai_user_interests';
  static const String _viewedNarrativesKey = 'ai_viewed_narratives';
  static const String _lastSuggestionsKey = 'ai_last_suggestions';
  static const String _lastUpdateKey = 'ai_last_update';
  
  // Singleton
  static final AISearchSuggestionService _instance = AISearchSuggestionService._internal();
  factory AISearchSuggestionService() => _instance;
  AISearchSuggestionService._internal();
  
  SharedPreferences? _prefs;
  
  /// Initialize service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  // ============================================
  // SMART SUGGESTIONS
  // ============================================
  
  /// Get personalized search suggestions based on user history
  Future<List<String>> getSmartSuggestions() async {
    try {
      // Check cache first (1 hour validity)
      final cachedSuggestions = _getCachedSuggestions();
      if (cachedSuggestions != null && cachedSuggestions.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('✅ Using cached suggestions');
        }
        return cachedSuggestions;
      }
      
      // Get user interests
      final interests = await _analyzeUserInterests();
      
      // Get suggestions from backend
      final response = await http.post(
        Uri.parse('$_backendUrl/api/ai/suggestions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'interests': interests,
          'limit': 10,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final suggestions = (data['suggestions'] as List?)
            ?.map((s) => s.toString())
            .toList() ?? [];
        
        // Cache suggestions
        await _cacheSuggestions(suggestions);
        
        if (kDebugMode) {
          debugPrint('✅ AI suggestions: ${suggestions.length}');
        }
        
        return suggestions;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ AI suggestions error: $e');
      }
    }
    
    // Fallback: Return popular searches
    return _getFallbackSuggestions();
  }
  
  /// Analyze user interests from search history and viewed narratives
  Future<Map<String, dynamic>> _analyzeUserInterests() async {
    final searchEntries = SearchHistoryService.getRecentHistory(limit: 50);
    final viewedNarratives = _getViewedNarratives();
    
    // Extract keywords from searches
    final keywords = <String, int>{};
    for (final entry in searchEntries) {
      final words = entry.query.toLowerCase().split(' ');
      for (final word in words) {
        if (word.length > 3) {  // Filter short words
          keywords[word] = (keywords[word] ?? 0) + 1;
        }
      }
    }
    
    // Sort by frequency
    final sortedKeywords = keywords.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topKeywords = sortedKeywords
        .take(10)
        .map((e) => e.key)
        .toList();
    
    return {
      'keywords': topKeywords,
      'search_count': searchEntries.length,
      'viewed_narratives': viewedNarratives,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Get cached suggestions (if still valid)
  List<String>? _getCachedSuggestions() {
    final lastUpdate = _prefs?.getString(_lastUpdateKey);
    if (lastUpdate == null) return null;
    
    final updateTime = DateTime.parse(lastUpdate);
    final now = DateTime.now();
    final difference = now.difference(updateTime);
    
    // Cache valid for 1 hour
    if (difference.inHours >= 1) return null;
    
    final cached = _prefs?.getStringList(_lastSuggestionsKey);
    return cached;
  }
  
  /// Cache suggestions
  Future<void> _cacheSuggestions(List<String> suggestions) async {
    await _prefs?.setStringList(_lastSuggestionsKey, suggestions);
    await _prefs?.setString(_lastUpdateKey, DateTime.now().toIso8601String());
  }
  
  /// Get fallback suggestions (popular topics)
  List<String> _getFallbackSuggestions() {
    return [
      'UFO Sichtungen',
      'Verschwörungstheorien',
      'Geheimgesellschaften',
      'Alte Zivilisationen',
      'Meditation',
      'Chakra Balance',
      'Kristalle',
      'Numerologie',
    ];
  }
  
  // ============================================
  // NARRATIVE RECOMMENDATIONS
  // ============================================
  
  /// Get recommended narratives based on user interests
  Future<List<Map<String, dynamic>>> getRecommendedNarratives() async {
    try {
      final interests = await _analyzeUserInterests();
      
      final response = await http.post(
        Uri.parse('$_backendUrl/api/ai/recommendations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'interests': interests,
          'limit': 20,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final narratives = (data['narratives'] as List?)
            ?.map((n) => n as Map<String, dynamic>)
            .toList() ?? [];
        
        if (kDebugMode) {
          debugPrint('✅ Recommended narratives: ${narratives.length}');
        }
        
        return narratives;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Recommendations error: $e');
      }
    }
    
    return [];
  }
  
  /// Get similar narratives based on a specific narrative
  Future<List<Map<String, dynamic>>> getSimilarNarratives(String narrativeId) async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/api/ai/similar/$narrativeId?limit=10'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final narratives = (data['similar'] as List?)
            ?.map((n) => n as Map<String, dynamic>)
            .toList() ?? [];
        
        return narratives;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Similar narratives error: $e');
      }
    }
    
    return [];
  }
  
  // ============================================
  // USER TRACKING
  // ============================================
  
  /// Track viewed narrative
  Future<void> trackNarrativeView(String narrativeId) async {
    final viewed = _getViewedNarratives();
    if (!viewed.contains(narrativeId)) {
      viewed.add(narrativeId);
      
      // Keep only last 100
      if (viewed.length > 100) {
        viewed.removeAt(0);
      }
      
      await _prefs?.setStringList(_viewedNarrativesKey, viewed);
      
      // Invalidate cache
      await _prefs?.remove(_lastSuggestionsKey);
      await _prefs?.remove(_lastUpdateKey);
    }
  }
  
  /// Get viewed narratives
  List<String> _getViewedNarratives() {
    return _prefs?.getStringList(_viewedNarrativesKey) ?? [];
  }
  
  /// Store user interests manually
  Future<void> updateUserInterests(List<String> interests) async {
    await _prefs?.setStringList(_interestsKey, interests);
    
    // Invalidate cache
    await _prefs?.remove(_lastSuggestionsKey);
    await _prefs?.remove(_lastUpdateKey);
  }
  
  /// Get stored user interests
  List<String> getUserInterests() {
    return _prefs?.getStringList(_interestsKey) ?? [];
  }
  
  // ============================================
  // SEARCH ENHANCEMENT
  // ============================================
  
  /// Get search query suggestions as user types
  Future<List<String>> getQuerySuggestions(String partialQuery) async {
    if (partialQuery.length < 2) return [];
    
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/api/ai/autocomplete?q=${Uri.encodeComponent(partialQuery)}'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final suggestions = (data['suggestions'] as List?)
            ?.map((s) => s.toString())
            .toList() ?? [];
        
        return suggestions;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Autocomplete error: $e');
      }
    }
    
    // Fallback: Search in history
    final historyEntries = SearchHistoryService.getRecentHistory(limit: 50);
    return historyEntries
        .where((entry) => entry.query.toLowerCase().contains(partialQuery.toLowerCase()))
        .map((entry) => entry.query)
        .take(5)
        .toList();
  }
  
  /// Get trending searches
  Future<List<String>> getTrendingSearches() async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/api/ai/trending?limit=10'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final trending = (data['trending'] as List?)
            ?.map((t) => t.toString())
            .toList() ?? [];
        
        return trending;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Trending error: $e');
      }
    }
    
    return _getFallbackSuggestions();
  }
  
  // ============================================
  // UTILITIES
  // ============================================
  
  /// Clear all AI data
  Future<void> clearAllData() async {
    await _prefs?.remove(_interestsKey);
    await _prefs?.remove(_viewedNarrativesKey);
    await _prefs?.remove(_lastSuggestionsKey);
    await _prefs?.remove(_lastUpdateKey);
    
    if (kDebugMode) {
      debugPrint('✅ AI data cleared');
    }
  }
  
  /// Get user statistics
  Map<String, dynamic> getUserStats() {
    return {
      'interests': getUserInterests().length,
      'viewed_narratives': _getViewedNarratives().length,
      'has_cached_suggestions': _getCachedSuggestions() != null,
    };
  }
}
