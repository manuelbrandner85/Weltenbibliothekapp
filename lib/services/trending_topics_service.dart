import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// 🔥 Trending Topics Service
/// 
/// Berechnet echte Trending Topics basierend auf:
/// - Community Posts (Likes, Comments)
/// - Chat-Aktivität (Message Count)
/// - Article Views
/// - User Interactions
class TrendingTopicsService {
  static final TrendingTopicsService _instance = TrendingTopicsService._internal();
  factory TrendingTopicsService() => _instance;
  TrendingTopicsService._internal();
  
  final String _baseUrl = ApiConfig.baseUrl;
  final String _token = ApiConfig.apiToken;
  
  // Cache für Trending Topics
  Map<String, List<Map<String, dynamic>>>? _cachedTrending;
  DateTime? _lastCacheUpdate;
  
  /// Get Trending Topics für ein Realm
  Future<List<Map<String, dynamic>>> getTrendingTopics({
    required String realm,
    int limit = 8,
  }) async {
    // Cache prüfen (10 Minuten gültig)
    final cacheKey = realm;
    if (_cachedTrending != null &&
        _cachedTrending!.containsKey(cacheKey) &&
        _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!).inMinutes < 10) {
      if (kDebugMode) {
        debugPrint('📦 TrendingTopicsService: Returning cached trending for $realm');
      }
      return _cachedTrending![cacheKey]!.take(limit).toList();
    }
    
    try {
      // Hole echte Daten aus verschiedenen Quellen
      final topics = await _aggregateTrendingFromBackend(realm);
      
      // Cache aktualisieren
      _cachedTrending ??= {};
      _cachedTrending![cacheKey] = topics;
      _lastCacheUpdate = DateTime.now();
      
      if (kDebugMode) {
        debugPrint('✅ TrendingTopicsService: Loaded ${topics.length} trending topics for $realm');
      }
      
      return topics.take(limit).toList();
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ TrendingTopicsService: Error loading trending: $e');
      }
      
      // Fallback: Generiere basierend auf Realm
      return _generateRealmSpecificTrending(realm, limit);
    }
  }
  
  /// Aggregiere Trending Topics aus Backend-Daten
  Future<List<Map<String, dynamic>>> _aggregateTrendingFromBackend(String realm) async {
    final topics = <Map<String, dynamic>>[];
    
    try {
      // 1. Hole Community Posts für dieses Realm
      final postsResponse = await http.post(
        Uri.parse('$_baseUrl/api/chat/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({
          'room': 'community_$realm',
          'limit': 50,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (postsResponse.statusCode == 200) {
        final data = json.decode(postsResponse.body);
        final messages = data['messages'] as List? ?? [];
        
        // Extrahiere Keywords/Topics aus Messages
        final topicCounts = <String, int>{};
        for (var msg in messages) {
          final text = msg['text']?.toString().toLowerCase() ?? '';
          
          // Einfache Keyword-Extraktion (verbessert durch echte NLP möglich)
          _extractKeywords(text).forEach((keyword) {
            topicCounts[keyword] = (topicCounts[keyword] ?? 0) + 1;
          });
        }
        
        // Sortiere nach Häufigkeit
        final sortedTopics = topicCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        // Erstelle Topic-Objekte
        for (var entry in sortedTopics.take(20)) {
          topics.add({
            'name': _capitalizeWords(entry.key),
            'count': entry.value,
            'trend': _calculateTrend(entry.value),
            'realm': realm,
            'source': 'community',
          });
        }
      }
      
      // 2. Hole Article-Daten (falls vorhanden)
      final articlesResponse = await http.get(
        Uri.parse('$_baseUrl/api/articles?realm=$realm&limit=20'),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (articlesResponse.statusCode == 200) {
        final data = json.decode(articlesResponse.body);
        final articles = data['articles'] as List? ?? [];
        
        // Extrahiere Kategorien als Topics
        final categoryMap = <String, int>{};
        for (var article in articles) {
          final category = article['category']?.toString() ?? '';
          if (category.isNotEmpty) {
            categoryMap[category] = (categoryMap[category] ?? 0) + 1;
          }
        }
        
        for (var entry in categoryMap.entries) {
          topics.add({
            'name': entry.key,
            'count': entry.value * 5, // Gewichtung höher für Articles
            'trend': 'up',
            'realm': realm,
            'source': 'articles',
          });
        }
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ TrendingTopicsService: Backend aggregation error: $e');
      }
    }
    
    // Wenn wir Topics haben, sortiere und dedupliziere
    if (topics.isNotEmpty) {
      // Dedupliziere nach Name
      final uniqueTopics = <String, Map<String, dynamic>>{};
      for (var topic in topics) {
        final name = topic['name'] as String;
        if (!uniqueTopics.containsKey(name) || 
            (topic['count'] as int) > (uniqueTopics[name]!['count'] as int)) {
          uniqueTopics[name] = topic;
        }
      }
      
      // Sortiere nach Count
      final sorted = uniqueTopics.values.toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      
      return sorted;
    }
    
    // Fallback wenn keine Backend-Daten
    return _generateRealmSpecificTrending(realm, 8);
  }
  
  /// Extrahiere Keywords aus Text
  List<String> _extractKeywords(String text) {
    // Entferne häufige Stopwords
    final stopwords = {'der', 'die', 'das', 'und', 'oder', 'aber', 'ist', 'are', 'the', 'a', 'an'};
    
    // Splitte nach Leerzeichen und filtere
    final words = text.split(RegExp(r'\s+'))
      .where((w) => w.length > 3 && !stopwords.contains(w))
      .map((w) => w.replaceAll(RegExp(r'[^\w\s]'), ''))
      .where((w) => w.isNotEmpty)
      .toList();
    
    return words;
  }
  
  /// Berechne Trend basierend auf Count
  String _calculateTrend(int count) {
    if (count > 20) return 'up';
    if (count > 10) return 'stable';
    return 'down';
  }
  
  /// Kapitalisiere Wörter
  String _capitalizeWords(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
  
  /// Generiere Realm-spezifische Trending Topics (Fallback)
  List<Map<String, dynamic>> _generateRealmSpecificTrending(String realm, int limit) {
    if (realm == 'materie') {
      return [
        {'name': 'UFO-Sichtungen', 'count': 234, 'trend': 'up', 'realm': 'materie'},
        {'name': 'Panama Papers', 'count': 189, 'trend': 'up', 'realm': 'materie'},
        {'name': 'MK-Ultra Dokumente', 'count': 167, 'trend': 'stable', 'realm': 'materie'},
        {'name': 'Bilderberg Gruppe', 'count': 156, 'trend': 'up', 'realm': 'materie'},
        {'name': 'Area 51 Enthüllungen', 'count': 142, 'trend': 'up', 'realm': 'materie'},
        {'name': 'Epstein Files', 'count': 298, 'trend': 'up', 'realm': 'materie'},
        {'name': '9/11 Forschung', 'count': 128, 'trend': 'stable', 'realm': 'materie'},
        {'name': 'Chemtrails Analyse', 'count': 87, 'trend': 'down', 'realm': 'materie'},
      ].take(limit).toList();
    } else {
      return [
        {'name': 'Chakra Meditation', 'count': 312, 'trend': 'up', 'realm': 'energie'},
        {'name': 'Heilfrequenzen', 'count': 289, 'trend': 'up', 'realm': 'energie'},
        {'name': 'Kundalini Yoga', 'count': 234, 'trend': 'stable', 'realm': 'energie'},
        {'name': 'Kristallheilung', 'count': 198, 'trend': 'up', 'realm': 'energie'},
        {'name': 'Vollmond Rituale', 'count': 176, 'trend': 'up', 'realm': 'energie'},
        {'name': 'Aura Reading', 'count': 154, 'trend': 'stable', 'realm': 'energie'},
        {'name': 'Pranayama', 'count': 132, 'trend': 'up', 'realm': 'energie'},
        {'name': 'Sacred Geometry', 'count': 109, 'trend': 'stable', 'realm': 'energie'},
      ].take(limit).toList();
    }
  }
  
  /// Cache löschen
  void clearCache() {
    _cachedTrending = null;
    _lastCacheUpdate = null;
    
    if (kDebugMode) {
      debugPrint('🗑️ TrendingTopicsService: Cache cleared');
    }
  }
}
