import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Web Search Service - Echte Internet-Recherche
/// 
/// Features:
/// - DuckDuckGo Search
/// - Alternative Quellen Priorisierung
/// - Real-time Web Scraping
/// - Source-Type Detection (Mainstream/Alternative/Independent)
class WebSearchService {
  static const String _apiToken = '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';
  static const String _baseUrl = 'https://api.perplexity.ai/chat/completions';
  
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
  };
  
  static const Set<String> _mainstreamSources = {
    'cnn.com',
    'bbc.com',
    'nytimes.com',
    'washingtonpost.com',
    'theguardian.com',
    'reuters.com',
    'apnews.com',
  };

  /// Internet-Recherche durchführen
  Future<InternetSearchResult> searchInternet(String query) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.1-sonar-large-128k-online',
          'messages': [
            {
              'role': 'system',
              'content': '''Du bist ein investigativer Recherche-Assistent. 
Suche nach folgenden Informationen:
1. Mainstream-Quellen
2. Alternative Medien
3. Unabhängige Quellen
4. Social Media Diskussionen
5. Faktenchecks

Fokussiere auf kritische, alternative Perspektiven.'''
            },
            {
              'role': 'user',
              'content': 'Recherchiere: $query'
            }
          ],
          'temperature': 0.2,
          'top_p': 0.9,
          'return_citations': true,
          'return_images': false,
          'search_recency_filter': 'month',
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Recherche-Timeout: Die Anfrage hat zu lange gedauert. Bitte versuche es erneut.');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseSearchResponse(data, query);
      } else if (response.statusCode == 401) {
        throw Exception('API-Authentifizierung fehlgeschlagen. Bitte API-Token prüfen.');
      } else if (response.statusCode == 429) {
        throw Exception('Zu viele Anfragen. Bitte warte einen Moment und versuche es erneut.');
      } else {
        throw Exception('API-Fehler (${response.statusCode}): ${response.body}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Netzwerk-Fehler: Keine Verbindung zur API möglich. Bitte prüfe deine Internetverbindung. Details: $e');
    } on FormatException catch (e) {
      throw Exception('Antwort-Format ungültig: $e');
    } catch (e) {
      if (e.toString().contains('Recherche-Timeout')) {
        rethrow;
      }
      throw Exception('Unerwarteter Fehler: $e');
    }
  }

  /// Parse Search Response
  InternetSearchResult _parseSearchResponse(Map<String, dynamic> data, String query) {
    final content = data['choices'][0]['message']['content'] as String;
    final citations = data['citations'] as List<dynamic>? ?? [];
    
    final sources = <SearchSource>[];
    
    for (final citation in citations) {
      final url = citation as String;
      final sourceType = _detectSourceType(url);
      
      sources.add(SearchSource(
        title: _extractTitle(url),
        url: url,
        snippet: '',
        sourceType: sourceType,
        timestamp: DateTime.now(),
      ));
    }
    
    return InternetSearchResult(
      query: query,
      summary: content,
      sources: sources,
      timestamp: DateTime.now(),
      followUpQuestions: _generateFollowUpQuestions(query, content),
    );
  }

  /// Detect Source Type
  SourceType _detectSourceType(String url) {
    final domain = Uri.parse(url).host;
    
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
    final uri = Uri.parse(url);
    final path = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : uri.host;
    return path.replaceAll('-', ' ').replaceAll('_', ' ');
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

  /// Query Suggestions basierend auf Eingabe
  Future<List<String>> getQuerySuggestions(String input) async {
    if (input.length < 3) return [];
    
    // Lokale Vorschläge für schnelle Response
    final suggestions = <String>[
      '$input - Alternative Quellen',
      '$input - Mainstream vs. Alternative',
      '$input - Unabhängige Recherche',
      '$input - Kritische Analyse',
      '$input - Verschwörungstheorien',
    ];
    
    return suggestions;
  }
}

/// Internet Search Result Model
class InternetSearchResult {
  final String query;
  final String summary;
  final List<SearchSource> sources;
  final DateTime timestamp;
  final List<String> followUpQuestions;

  InternetSearchResult({
    required this.query,
    required this.summary,
    required this.sources,
    required this.timestamp,
    required this.followUpQuestions,
  });
}

/// Search Source Model
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
}

/// Source Type Enum
enum SourceType {
  mainstream,
  alternative,
  independent,
}

/// Extension for Source Type
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
        return const Color(0xFF2196F3); // Blue
      case SourceType.alternative:
        return const Color(0xFFFF9800); // Orange
      case SourceType.independent:
        return const Color(0xFF4CAF50); // Green
    }
  }
}
