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
      // OpenClaw-Route (bevorzugt)
      if (_openClawAvailable) {
        if (kDebugMode) {
          print('🚀 [OpenClaw Comprehensive v2.0] Starting DEEP research...');
          print('   → Query: $query');
          print('   → Max results per type: $maxResultsPerType');
        }
        
        final result = await _deepResearchViaOpenClaw(
          query: query,
          url: url,
          includeImages: includeImages,
          includeVideos: includeVideos,
          includeAudio: includeAudio,
          includePdfs: includePdfs,
          maxResultsPerType: maxResultsPerType,
        );
        
        // Cache speichern
        _cache[cacheKey] = {
          'data': result,
          'timestamp': DateTime.now(),
        };
        
        return result;
      }
      
      // Fallback zu Cloudflare
      if (kDebugMode) {
        print('🔄 [OpenClaw Comprehensive v2.0] Falling back to Cloudflare...');
      }
      return await _comprehensiveResearchViaCloudflare(query: query);
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ [OpenClaw Comprehensive v2.0] Error: $e');
      }
      
      // Fallback zu Cloudflare
      return await _comprehensiveResearchViaCloudflare(query: query);
    }
  }
  
  /// 🚀 TIEFES SCRAPING über MEHRERE Quellen mit Relevanz-Filtering
  Future<Map<String, dynamic>> _deepResearchViaOpenClaw({
    required String query,
    String? url,
    required bool includeImages,
    required bool includeVideos,
    required bool includeAudio,
    required bool includePdfs,
    required int maxResultsPerType,
  }) async {
    final results = <String, dynamic>{
      'source': 'openclaw_deep',
      'query': query,
      'url': url,
      'timestamp': DateTime.now().toIso8601String(),
      'articles': [],
      'media': {
        'images': <Map<String, dynamic>>[],
        'videos': <Map<String, dynamic>>[],
        'audio': <Map<String, dynamic>>[],
        'pdfs': <Map<String, dynamic>>[],
      },
      'analysis': {},
      'sources_scraped': 0,
    };
    
    // 1. Artikel-Recherche über OpenClaw Gateway
    List<String> articleUrls = [];
    try {
      final articlesResponse = await http.post(
        Uri.parse('${ApiConfig.openClawGatewayUrl}/api/research'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.openClawGatewayToken}',
        },
        body: jsonEncode({
          'query': query,
          'maxResults': 50, // Mehr Artikel für tieferes Scraping
          'includeAnalysis': true,
        }),
      ).timeout(const Duration(seconds: 30));
      
      if (articlesResponse.statusCode == 200) {
        final data = jsonDecode(articlesResponse.body);
        results['articles'] = data['articles'] ?? [];
        results['analysis'] = data['analysis'] ?? {};
        
        // Extrahiere alle URLs
        for (var article in results['articles']) {
          if (article['url'] != null && article['url'].toString().isNotEmpty) {
            articleUrls.add(article['url'].toString());
          }
        }
        
        if (kDebugMode) {
          print('✅ [OpenClaw Deep] Found ${results['articles'].length} articles');
          print('   → URLs to scrape: ${articleUrls.length}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [OpenClaw Deep] Article research failed: $e');
      }
    }
    
    // 2. Falls spezifische URL vorhanden, diese auch scrapen
    if (url != null && url.isNotEmpty && !articleUrls.contains(url)) {
      articleUrls.insert(0, url);
    }
    
    // 3. TIEFES SCRAPING über ALLE gefundenen URLs
    // Limitiere auf max 20 URLs für Performance
    final urlsToScrape = articleUrls.take(20).toList();
    int sourcesScraped = 0;
    
    if (kDebugMode) {
      print('🔍 [OpenClaw Deep] Starting deep scraping of ${urlsToScrape.length} sources...');
    }
    
    for (var sourceUrl in urlsToScrape) {
      try {
        sourcesScraped++;
        
        if (kDebugMode && sourcesScraped % 5 == 0) {
          print('   → Progress: $sourcesScraped/${urlsToScrape.length} sources scraped');
        }
        
        // Scrape alle Medientypen von dieser URL
        if (includeImages) {
          try {
            final imageResult = await _mediaScraper.scrapeImage(url: sourceUrl);
            if (imageResult['images'] != null) {
              final images = imageResult['images'] as List;
              for (var img in images) {
                if (img is Map<String, dynamic>) {
                  // Füge Source-URL hinzu für Tracking
                  img['source_url'] = sourceUrl;
                  results['media']['images'].add(img);
                }
              }
            }
          } catch (e) {
            if (kDebugMode) print('   ⚠️ Image scraping failed for $sourceUrl');
          }
        }
        
        if (includeVideos) {
          try {
            final videoResult = await _mediaScraper.scrapeVideo(url: sourceUrl);
            if (videoResult['videos'] != null) {
              final videos = videoResult['videos'] as List;
              for (var vid in videos) {
                if (vid is Map<String, dynamic>) {
                  vid['source_url'] = sourceUrl;
                  results['media']['videos'].add(vid);
                }
              }
            }
          } catch (e) {
            if (kDebugMode) print('   ⚠️ Video scraping failed for $sourceUrl');
          }
        }
        
        if (includeAudio) {
          try {
            final audioResult = await _mediaScraper.scrapeAudio(url: sourceUrl);
            if (audioResult['audio'] != null) {
              final audios = audioResult['audio'] as List;
              for (var aud in audios) {
                if (aud is Map<String, dynamic>) {
                  aud['source_url'] = sourceUrl;
                  results['media']['audio'].add(aud);
                }
              }
            }
          } catch (e) {
            if (kDebugMode) print('   ⚠️ Audio scraping failed for $sourceUrl');
          }
        }
        
        if (includePdfs) {
          try {
            final pdfResult = await _mediaScraper.scrapePDF(url: sourceUrl);
            if (pdfResult['pdfs'] != null) {
              final pdfs = pdfResult['pdfs'] as List;
              for (var pdf in pdfs) {
                if (pdf is Map<String, dynamic>) {
                  pdf['source_url'] = sourceUrl;
                  results['media']['pdfs'].add(pdf);
                }
              }
            }
          } catch (e) {
            if (kDebugMode) print('   ⚠️ PDF scraping failed for $sourceUrl');
          }
        }
        
      } catch (e) {
        if (kDebugMode) {
          print('   ⚠️ Failed to scrape source $sourceUrl: $e');
        }
      }
    }
    
    results['sources_scraped'] = sourcesScraped;
    
    if (kDebugMode) {
      print('✅ [OpenClaw Deep] Scraping completed:');
      print('   → Sources scraped: $sourcesScraped');
      print('   → Raw images found: ${results['media']['images'].length}');
      print('   → Raw videos found: ${results['media']['videos'].length}');
      print('   → Raw audio found: ${results['media']['audio'].length}');
      print('   → Raw PDFs found: ${results['media']['pdfs'].length}');
    }
    
    // 4. RELEVANZ-FILTERING und DEDUPLIZIERUNG
    results['media']['images'] = _filterAndRankMedia(
      results['media']['images'] as List<Map<String, dynamic>>,
      query,
      maxResultsPerType,
    );
    
    results['media']['videos'] = _filterAndRankMedia(
      results['media']['videos'] as List<Map<String, dynamic>>,
      query,
      maxResultsPerType,
    );
    
    results['media']['audio'] = _filterAndRankMedia(
      results['media']['audio'] as List<Map<String, dynamic>>,
      query,
      maxResultsPerType,
    );
    
    results['media']['pdfs'] = _filterAndRankMedia(
      results['media']['pdfs'] as List<Map<String, dynamic>>,
      query,
      maxResultsPerType,
    );
    
    if (kDebugMode) {
      print('✅ [OpenClaw Deep] After filtering (top $maxResultsPerType):');
      print('   → Images: ${results['media']['images'].length}');
      print('   → Videos: ${results['media']['videos'].length}');
      print('   → Audio: ${results['media']['audio'].length}');
      print('   → PDFs: ${results['media']['pdfs'].length}');
    }
    
    return results;
  }
  
  /// 🎯 RELEVANZ-FILTERING und RANKING
  /// Filtert Medien nach Relevanz zum Suchbegriff und dedupliziert
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
