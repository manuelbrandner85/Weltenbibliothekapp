/// OpenClaw Comprehensive Service v2.0
/// ERWEITERT: Tiefes Scraping über mehrere Quellen mit Relevanz-Filtering
/// 
/// Funktionen:
/// - 🔍 Tiefes Multi-Source Scraping (nicht nur 1 URL)
/// - 🎯 Relevanz-basiertes Filtering (Suchbegriff-Match)
/// - 🖼️ Top 10 Bilder pro Recherche
/// - 🎥 Top 10 Videos pro Recherche
/// - 🎵 Top 10 Audio-Dateien pro Recherche
/// - 📄 Top 10 PDFs pro Recherche
/// - 🔄 Automatisches Fallback zu Cloudflare
/// - 💾 Intelligentes Caching

library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'openclaw_media_scraper_service.dart';
import 'cloudflare_api_service.dart';

class OpenClawComprehensiveService {
  static final OpenClawComprehensiveService _instance = OpenClawComprehensiveService._internal();
  factory OpenClawComprehensiveService() => _instance;
  OpenClawComprehensiveService._internal() {
    _init();
  }

  // Services
  late final OpenClawMediaScraperService _mediaScraper;
  late final CloudflareApiService _cloudflare;
  
  // Status
  bool _isInitialized = false;
  bool _openClawAvailable = false;
  
  // Cache
  final Map<String, dynamic> _cache = {};
  
  void _init() {
    _mediaScraper = OpenClawMediaScraperService();
    _cloudflare = CloudflareApiService();
    _checkOpenClawStatus();
  }
  
  Future<void> _checkOpenClawStatus() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.openClawGatewayUrl}/health'),
      ).timeout(const Duration(seconds: 3));
      
      _openClawAvailable = response.statusCode == 200;
      _isInitialized = true;
      
      if (kDebugMode) {
        print('🔧 [OpenClaw Comprehensive v2.0] Status: ${_openClawAvailable ? "✅ Online" : "❌ Offline"}');
      }
    } catch (e) {
      _openClawAvailable = false;
      _isInitialized = true;
      if (kDebugMode) {
        print('⚠️ [OpenClaw Comprehensive] Health check failed: $e');
      }
    }
  }
  
  /// 🔍 HAUPT-RECHERCHE-FUNKTION V2.0
  /// Scrapt TIEF über MEHRERE Quellen und filtert nach Relevanz
  /// Liefert maximal 10 Ergebnisse pro Medientyp
  Future<Map<String, dynamic>> comprehensiveResearch({
    required String query,
    String? url,
    bool includeImages = true,
    bool includeVideos = true,
    bool includeAudio = true,
    bool includePdfs = true,
    int maxResultsPerType = 10, // Maximal 10 Ergebnisse pro Typ
  }) async {
    if (!_isInitialized) {
      await _checkOpenClawStatus();
    }
    
    // Cache-Check
    final cacheKey = 'research_$query${url ?? ''}';
    if (_cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey];
      if (DateTime.now().difference(cached['timestamp']).inHours < 1) {
        if (kDebugMode) {
          print('💾 [OpenClaw Comprehensive v2.0] Using cached result');
        }
        return cached['data'];
      }
    }
    
    try {
      // Worker-Route (direkt, kein OpenClaw Gateway mehr)
      if (kDebugMode) {
        print('🚀 [OpenClaw Comprehensive v2.0] Starting research via Worker...');
        print('   → Query: $query');
      }

      final result = await _deepResearchViaWorker(
        query: query,
        url: url,
        maxResultsPerType: maxResultsPerType,
      );

      // Cache speichern
      _cache[cacheKey] = {
        'data': result,
        'timestamp': DateTime.now(),
      };

      return result;
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ [OpenClaw Comprehensive v2.0] Error: $e');
      }
      
      // Fallback zu Cloudflare
      return await _comprehensiveResearchViaCloudflare(query: query);
    }
  }
  
  /// 🚀 RECHERCHE via Cloudflare Worker /recherche Endpoint
  /// Ersetzt den nicht erreichbaren OpenClaw Gateway (http://72.62.154.95:50074)
  Future<Map<String, dynamic>> _deepResearchViaWorker({
    required String query,
    String? url,
    required int maxResultsPerType,
  }) async {
    final workerUrl = Uri.parse(
      '${ApiConfig.workerUrl}/recherche?q=${Uri.encodeComponent(query)}',
    );

    final response = await http.get(workerUrl).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Worker /recherche returned ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    // Worker liefert: results[], summary, sources{}
    // Wir mappen auf: articles[], media{}, analysis{}, sources_scraped
    final rawResults = (data['results'] as List<dynamic>? ?? []);
    final sourcesMap = data['sources'] as Map<String, dynamic>? ?? {};

    final articles = rawResults
        .whereType<Map<String, dynamic>>()
        .map((r) => <String, dynamic>{
              'title': r['title'] ?? '',
              'url': r['url'] ?? r['link'] ?? '',
              'snippet': r['snippet'] ?? r['description'] ?? '',
              'source': r['source'] ?? '',
            })
        .take(maxResultsPerType)
        .toList();

    final analysis = <String, dynamic>{
      if (data['summary'] != null) 'summary': data['summary'],
      'sources_count': sourcesMap.length,
    };

    if (kDebugMode) {
      print('✅ [Worker Recherche] Found ${articles.length} articles');
      print('   → Sources: ${sourcesMap.keys.join(', ')}');
    }

    return {
      'source': 'worker_recherche',
      'query': query,
      'url': url,
      'timestamp': DateTime.now().toIso8601String(),
      'articles': articles,
      'media': {
        'images': <Map<String, dynamic>>[],
        'videos': <Map<String, dynamic>>[],
        'audio': <Map<String, dynamic>>[],
        'pdfs': <Map<String, dynamic>>[],
      },
      'analysis': analysis,
      'sources_scraped': sourcesMap.length,
    };
  }
  
  /// 🎯 RELEVANZ-FILTERING und RANKING
  /// Filtert Medien nach Relevanz zum Suchbegriff und dedupliziert
  // ignore: unused_element
  List<Map<String, dynamic>> _filterAndRankMedia(
    List<Map<String, dynamic>> items,
    String query,
    int maxResults,
  ) {
    // Deduplizierung nach URL
    final seen = <String>{};
    final unique = <Map<String, dynamic>>[];
    
    for (var item in items) {
      final url = item['url'] ?? item['src'] ?? '';
      if (url.isNotEmpty && !seen.contains(url)) {
        seen.add(url);
        
        // Berechne Relevanz-Score
        item['relevance_score'] = _calculateRelevanceScore(item, query);
        unique.add(item);
      }
    }
    
    // Sortiere nach Relevanz-Score (höchster zuerst)
    unique.sort((a, b) {
      final scoreA = a['relevance_score'] as double? ?? 0.0;
      final scoreB = b['relevance_score'] as double? ?? 0.0;
      return scoreB.compareTo(scoreA);
    });
    
    // Limitiere auf maxResults
    return unique.take(maxResults).toList();
  }
  
  /// 📊 RELEVANZ-SCORE BERECHNUNG
  /// Score basiert auf: Titel-Match, Alt-Text-Match, URL-Match, Quelle
  double _calculateRelevanceScore(Map<String, dynamic> item, String query) {
    double score = 0.0;
    final queryLower = query.toLowerCase();
    final queryWords = queryLower.split(' ');
    
    // 1. Titel/Name-Match (40 Punkte)
    final title = (item['title'] ?? item['alt'] ?? item['name'] ?? '').toString().toLowerCase();
    if (title.contains(queryLower)) {
      score += 40.0;
    } else {
      // Partial word match
      for (var word in queryWords) {
        if (word.length > 3 && title.contains(word)) {
          score += 10.0;
        }
      }
    }
    
    // 2. Alt-Text / Description Match (30 Punkte)
    final alt = (item['alt'] ?? item['description'] ?? '').toString().toLowerCase();
    if (alt.contains(queryLower)) {
      score += 30.0;
    } else {
      for (var word in queryWords) {
        if (word.length > 3 && alt.contains(word)) {
          score += 7.5;
        }
      }
    }
    
    // 3. URL-Match (20 Punkte)
    final url = (item['url'] ?? item['src'] ?? '').toString().toLowerCase();
    if (url.contains(queryLower)) {
      score += 20.0;
    } else {
      for (var word in queryWords) {
        if (word.length > 3 && url.contains(word)) {
          score += 5.0;
        }
      }
    }
    
    // 4. Source Quality Bonus (10 Punkte)
    final sourceUrl = (item['source_url'] ?? '').toString().toLowerCase();
    if (sourceUrl.contains('wikipedia') || sourceUrl.contains('gov') || sourceUrl.contains('edu')) {
      score += 10.0;
    } else if (sourceUrl.contains('news') || sourceUrl.contains('article')) {
      score += 5.0;
    }
    
    return score;
  }
  
  /// Cloudflare-Fallback
  Future<Map<String, dynamic>> _comprehensiveResearchViaCloudflare({
    required String query,
  }) async {
    try {
      final articles = await _cloudflare.search(query: query, realm: 'materie', limit: 20);
      
      return {
        'source': 'cloudflare',
        'query': query,
        'timestamp': DateTime.now().toIso8601String(),
        'articles': articles,
        'media': {
          'images': [],
          'videos': [],
          'audio': [],
          'pdfs': [],
        },
        'analysis': {},
        'sources_scraped': 0,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Cloudflare Fallback] Error: $e');
      }
      
      return {
        'source': 'error',
        'query': query,
        'timestamp': DateTime.now().toIso8601String(),
        'articles': [],
        'media': {
          'images': [],
          'videos': [],
          'audio': [],
          'pdfs': [],
        },
        'analysis': {},
        'sources_scraped': 0,
        'error': e.toString(),
      };
    }
  }
  
  /// 🖼️ Bild-spezifisches Scraping
  Future<List<Map<String, dynamic>>> scrapeImages(String url) async {
    if (!_openClawAvailable) {
      return [];
    }
    
    try {
      final result = await _mediaScraper.scrapeImage(url: url);
      return (result['images'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Image Scraping] Error: $e');
      }
      return [];
    }
  }
  
  /// 🎥 Video-spezifisches Scraping
  Future<List<Map<String, dynamic>>> scrapeVideos(String url) async {
    if (!_openClawAvailable) {
      return [];
    }
    
    try {
      final result = await _mediaScraper.scrapeVideo(url: url);
      return (result['videos'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Video Scraping] Error: $e');
      }
      return [];
    }
  }
  
  /// 🎵 Audio-spezifisches Scraping
  Future<List<Map<String, dynamic>>> scrapeAudio(String url) async {
    if (!_openClawAvailable) {
      return [];
    }
    
    try {
      final result = await _mediaScraper.scrapeAudio(url: url);
      return (result['audio'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Audio Scraping] Error: $e');
      }
      return [];
    }
  }
  
  /// 📄 PDF-spezifisches Scraping
  Future<List<Map<String, dynamic>>> scrapePdfs(String url) async {
    if (!_openClawAvailable) {
      return [];
    }
    
    try {
      final result = await _mediaScraper.scrapePDF(url: url);
      return (result['pdfs'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ [PDF Scraping] Error: $e');
      }
      return [];
    }
  }
  
  /// Cache löschen
  void clearCache() {
    _cache.clear();
    if (kDebugMode) {
      print('🗑️ [OpenClaw Comprehensive v2.0] Cache cleared');
    }
  }
  
  /// Status abrufen
  Map<String, dynamic> getStatus() {
    return {
      'initialized': _isInitialized,
      'openClawAvailable': _openClawAvailable,
      'cacheSize': _cache.length,
      'version': '2.0',
    };
  }
}
