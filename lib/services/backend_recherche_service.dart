import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'achievement_service.dart';  // 🏆 Achievement System
import 'daily_challenges_service.dart';  // 🎯 Daily Challenges
import 'real_source_enhancer.dart';  // 🔍 REAL SOURCE ENHANCER

/// Production-Ready Backend Recherche Service
/// 
/// KRITISCH: Verwendet Backend-Proxy statt direktem API-Zugriff
/// - CORS-Kompatibel für Flutter Web
/// - API-Token-Security (serverseitig)
/// - Rate Limiting & Error Handling
/// - Alternative Quellen Priorisierung
class BackendRechercheService {
  // PRODUCTION: Nutze Backend-Proxy
  static const String _backendUrl = 'https://weltenbibliothek-api-v2.brandy13062.workers.dev';
  
  // Alternative & unabhängige Quellen Domains
  static const Set<String> _alternativeSources = {
    'wikileaks.org',
    'theintercept.com',
    'propublica.org',
    'bellingcat.com',
    'archive.org',
    'substack.com',
    'medium.com',
    'telegram.org',
    'odysee.com',
    'bitchute.com',
    'rumble.com',
    'gettr.com',
    'gab.com',
  };
  
  static const Set<String> _mainstreamSources = {
    'cnn.com',
    'bbc.com',
    'nytimes.com',
    'washingtonpost.com',
    'theguardian.com',
    'reuters.com',
    'apnews.com',
    'foxnews.com',
  };

  /// Internet-Recherche durchführen
  Future<InternetSearchResult> searchInternet(String query) async {
    if (kDebugMode) {
      debugPrint('🔍 Backend-Recherche: $query');
    }
    
    // 🏆 Achievement Trigger: Search
    _trackSearchAchievement();
    
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/recherche?q=${Uri.encodeComponent(query)}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          throw TimeoutException('Die Recherche dauert zu lange. Bitte versuche es erneut.');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return await _parseBackendResponse(data, query);  // ← await added
        
      } else if (response.statusCode == 503) {
        throw ServiceUnavailableException(
          'Backend-Service ist vorübergehend nicht erreichbar. '
          'Bitte versuche es in wenigen Sekunden erneut.'
        );
        
      } else if (response.statusCode == 429) {
        throw RateLimitException(
          'Zu viele Anfragen. Bitte warte einen Moment.'
        );
        
      } else {
        throw BackendException(
          'Backend-Fehler (${response.statusCode}): ${response.body}'
        );
      }
      
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Network Error: $e');
      }
      throw NetworkException(
        'Keine Verbindung zum Backend möglich. '
        'Bitte prüfe deine Internetverbindung.'
      );
      
    } on FormatException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Format Error: $e');
      }
      throw DataFormatException(
        'Ungültiges Antwort-Format vom Backend.'
      );
      
    } catch (e) {
      if (e is RechercheException) {
        rethrow;
      }
      if (kDebugMode) {
        debugPrint('❌ Unexpected Error: $e');
      }
      throw UnexpectedException('Unerwarteter Fehler: ${e.toString()}');
    }
  }

  /// Parse Backend Response
  Future<InternetSearchResult> _parseBackendResponse(
    Map<String, dynamic> data, 
    String query
  ) async {
    final summary = data['summary'] as String? ?? 'Keine Zusammenfassung verfügbar.';
    final sourcesData = data['sources'] as List<dynamic>? ?? [];
    var multimedia = data['multimedia'] as Map<String, dynamic>?;  // Backend multimedia
    
    // 🔍 ENHANCE WITH REAL SOURCES
    final enhancedMultimedia = await _enhanceWithRealSources(query, multimedia);
    
    final sources = sourcesData.map((sourceJson) {
      final url = sourceJson['url'] as String? ?? '';
      final title = sourceJson['title'] as String? ?? _extractTitle(url);
      final snippet = sourceJson['snippet'] as String? ?? '';
      
      return SearchSource(
        title: title,
        url: url,
        snippet: snippet,
        sourceType: _detectSourceType(url),
        timestamp: DateTime.now(),
      );
    }).toList();
    
    // ✅ FILTER: Nur spezifische Unterseiten, KEINE Hauptseiten
    final filteredSources = sources.where((source) {
      final url = source.url;
      if (url.isEmpty) return true; // Leer → behalten (Backend entscheidet)
      
      final uri = Uri.tryParse(url);
      if (uri == null) return true; // Fehler → behalten
      
      // Filtere NUR offensichtliche Hauptseiten raus
      final path = uri.path;
      
      // ❌ SKIP: Komplett leere Paths oder nur /
      if (path.isEmpty || path == '/') {
        if (kDebugMode) {
          debugPrint('❌ FILTERED (main page): $url');
        }
        return false;
      }
      
      // ❌ SKIP: /index.html, /index.php, /home, /start
      final pathLower = path.toLowerCase();
      if (pathLower == '/index.html' || 
          pathLower == '/index.php' ||
          pathLower == '/home' ||
          pathLower == '/start') {
        if (kDebugMode) {
          debugPrint('❌ FILTERED (index page): $url');
        }
        return false;
      }
      
      // ✅ KEEP: Alles andere (auch kurze Paths wie /news, /blog)
      // URLs mit Query-Params (z.B. ?id=123) sind OK
      // PDFs, Artikel-URLs, etc. werden behalten
      
      if (kDebugMode) {
        debugPrint('✅ KEPT: $url');
      }
      return true;
      
    }).toList();
    
    // 🆕 Extract Related Topics & Timeline from Backend (🔧 FIX: Safe casting)
    final relatedTopics = (data['relatedTopics'] as List<dynamic>?)
        ?.whereType<Map<String, dynamic>>()
        .toList();
    final timeline = (data['timeline'] as List<dynamic>?)
        ?.whereType<Map<String, dynamic>>()
        .toList();
    
    return InternetSearchResult(
      query: query,
      summary: summary,
      sources: filteredSources,  // ✅ Filtered sources
      timestamp: DateTime.now(),
      followUpQuestions: _generateFollowUpQuestions(query, summary),
      multimedia: enhancedMultimedia,  // ✅ Enhanced multimedia
      relatedTopics: relatedTopics,
      timeline: timeline,
    );
  }
  
  /// 🔍 ENHANCE WITH REAL SOURCES
  Future<Map<String, dynamic>> _enhanceWithRealSources(
    String query,
    Map<String, dynamic>? backendMultimedia,
  ) async {
    final enhanced = <String, dynamic>{};
    
    // Start with backend data if available
    if (backendMultimedia != null) {
      enhanced.addAll(backendMultimedia);
    }
    
    try {
      // 📄 Find REAL PDFs
      final pdfs = await RealSourceEnhancer.findRealPDFs(query);
      if (pdfs.isNotEmpty) {
        enhanced['pdfs'] = pdfs;
      }
      
      // 📱 Find REAL Telegram channels
      final telegram = await RealSourceEnhancer.findRealTelegramChannels(query);
      if (telegram.isNotEmpty) {
        enhanced['telegram'] = telegram;
      }
      
      // 🖼️ Find REAL Images
      final images = await RealSourceEnhancer.findRealImages(query);
      if (images.isNotEmpty) {
        enhanced['images'] = images;
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Real source enhancement failed: $e');
      }
      // Continue with backend data only
    }
    
    return enhanced;
  }

  /// Detect Source Type
  SourceType _detectSourceType(String url) {
    if (url.isEmpty) return SourceType.independent;
    
    final domain = Uri.tryParse(url)?.host ?? '';
    
    if (_alternativeSources.any((s) => domain.contains(s))) {
      return SourceType.alternative;
    } else if (_mainstreamSources.any((s) => domain.contains(s))) {
      return SourceType.mainstream;
    } else {
      return SourceType.independent;
    }
  }

  /// Extract Title from URL
  String _extractTitle(String url) {
    if (url.isEmpty) return 'Unbekannte Quelle';
    
    final uri = Uri.tryParse(url);
    if (uri == null) return 'Unbekannte Quelle';
    
    final path = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : uri.host;
    return path
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .replaceAll('%20', ' ');
  }

  /// Generate Follow-Up Questions
  List<String> _generateFollowUpQuestions(String query, String summary) {
    return [
      'Was sind alternative Perspektiven zu "$query"?',
      'Welche unabhängigen Quellen berichten darüber?',
      'Gibt es Widersprüche in den Mainstream-Medien?',
      'Was sagen Experten aus dem alternativen Spektrum?',
      'Welche historischen Parallelen gibt es?',
    ];
  }

  /// Query Suggestions
  Future<List<String>> getQuerySuggestions(String input) async {
    if (input.length < 3) return [];
    
    return [
      '$input - Alternative Quellen',
      '$input - Mainstream vs. Alternative',
      '$input - Unabhängige Recherche',
      '$input - Kritische Analyse',
      '$input - Verschwörungstheorien',
    ];
  }
}

// ============================================================================
// CUSTOM EXCEPTIONS - Production-Ready Error Handling
// ============================================================================

abstract class RechercheException implements Exception {
  final String message;
  const RechercheException(this.message);
  
  @override
  String toString() => message;
}

class NetworkException extends RechercheException {
  const NetworkException(super.message);
}

class ServiceUnavailableException extends RechercheException {
  const ServiceUnavailableException(super.message);
}

class RateLimitException extends RechercheException {
  const RateLimitException(super.message);
}

class BackendException extends RechercheException {
  const BackendException(super.message);
}

class DataFormatException extends RechercheException {
  const DataFormatException(super.message);
}

class UnexpectedException extends RechercheException {
  const UnexpectedException(super.message);
}

class TimeoutException extends RechercheException {
  const TimeoutException(super.message);
}

/// 🏆 Achievement Tracking Helper
void _trackSearchAchievement() {
  try {
    AchievementService().incrementProgress('first_search');
    AchievementService().incrementProgress('search_veteran');
    AchievementService().incrementProgress('search_master');
    
    // 🎯 Daily Challenge Tracking
    DailyChallengesService().incrementProgress(
      ChallengeCategory.search,
      amount: 1,
    );
  } catch (e) {
    if (kDebugMode) debugPrint('⚠️ Achievement tracking error: $e');
  }
}

// ============================================================================
// MODELS - Gleich wie vorher
// ============================================================================

class InternetSearchResult {
  final String query;
  final String summary;
  final List<SearchSource> sources;
  final DateTime timestamp;
  final List<String> followUpQuestions;
  final Map<String, dynamic>? multimedia;  // 🆕 Multimedia-Support
  final List<Map<String, dynamic>>? relatedTopics;  // 🆕 Related Topics
  final List<Map<String, dynamic>>? timeline;  // 🆕 Timeline

  InternetSearchResult({
    required this.query,
    required this.summary,
    required this.sources,
    required this.timestamp,
    required this.followUpQuestions,
    this.multimedia,  // Optional
    this.relatedTopics,  // Optional
    this.timeline,  // Optional
  });
  
  // 🆕 Convert to JSON for ShareResearchWidget
  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'summary': summary,
      'sources': sources.map((s) => s.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
      'followUpQuestions': followUpQuestions,
      'multimedia': multimedia,
      'relatedTopics': relatedTopics,
      'timeline': timeline,
    };
  }
}

class SearchSource {
  final String title;
  final String url;
  final String snippet;
  final SourceType sourceType;
  final DateTime timestamp;

  SearchSource({
    required this.title,
    required this.url,
    required this.snippet,
    required this.sourceType,
    required this.timestamp,
  });
  
  // 🆕 Convert to JSON for EnhancedSourceCard
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'snippet': snippet,
      'sourceType': sourceType.label,
      'category': sourceType.label,
      'clickable': true,
      'metadata': {
        'domain': Uri.tryParse(url)?.host ?? 'unknown',
        'credibility': sourceType.label.toLowerCase(),
        'language': 'de/en',
        'lastUpdated': null,
      },
    };
  }
}

enum SourceType {
  mainstream,
  alternative,
  independent,
}

extension SourceTypeExtension on SourceType {
  String get label {
    switch (this) {
      case SourceType.mainstream:
        return 'Mainstream';
      case SourceType.alternative:
        return 'Alternative';
      case SourceType.independent:
        return 'Unabhängig';
    }
  }

  Color get color {
    switch (this) {
      case SourceType.mainstream:
        return const Color(0xFF2196F3);
      case SourceType.alternative:
        return const Color(0xFFFF9800);
      case SourceType.independent:
        return const Color(0xFF4CAF50);
    }
  }
}
