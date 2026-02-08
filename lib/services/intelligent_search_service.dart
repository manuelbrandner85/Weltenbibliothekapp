import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

/// Intelligenter Such-Service mit semantischer Suche
class IntelligentSearchService {
  static final IntelligentSearchService _instance = IntelligentSearchService._internal();
  factory IntelligentSearchService() => _instance;
  IntelligentSearchService._internal();

  static const String _searchHistoryKey = 'search_history';
  static const int _maxHistoryItems = 50;

  /// Suchanfrage verarbeiten
  Future<List<Map<String, dynamic>>> search({
    required String query,
    required List<Map<String, dynamic>> allArticles,
    String? world,
    String? category,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    if (query.isEmpty) return [];

    // Zur Such-Historie hinzufügen
    await _addToHistory(query);

    // Normalisiere Query
    final normalizedQuery = query.toLowerCase().trim();
    final queryWords = normalizedQuery.split(' ').where((w) => w.length > 2).toList();

    // Durchsuche alle Artikel
    final results = <Map<String, dynamic>>[];
    
    for (var article in allArticles) {
      // Filter anwenden
      if (world != null && article['world'] != world) continue;
      if (category != null && article['category'] != category) continue;
      
      // Datum-Filter
      if (fromDate != null || toDate != null) {
        final articleDate = DateTime.tryParse(article['publishedDate'] ?? '');
        if (articleDate != null) {
          if (fromDate != null && articleDate.isBefore(fromDate)) continue;
          if (toDate != null && articleDate.isAfter(toDate)) continue;
        }
      }

      // Relevanz-Score berechnen
      final score = _calculateRelevanceScore(
        article: article,
        query: normalizedQuery,
        queryWords: queryWords,
      );

      if (score > 0) {
        final result = Map<String, dynamic>.from(article);
        result['searchScore'] = score;
        results.add(result);
      }
    }

    // Sortiere nach Relevanz
    results.sort((a, b) => (b['searchScore'] as double).compareTo(a['searchScore'] as double));

    return results;
  }

  /// Berechne Relevanz-Score
  double _calculateRelevanceScore({
    required Map<String, dynamic> article,
    required String query,
    required List<String> queryWords,
  }) {
    double score = 0.0;

    final title = (article['title'] as String? ?? '').toLowerCase();
    final content = (article['content'] as String? ?? '').toLowerCase();
    final category = (article['category'] as String? ?? '').toLowerCase();
    final tags = List<String>.from(article['tags'] ?? []).map((t) => t.toLowerCase()).toList();

    // 1. EXAKTE ÜBEREINSTIMMUNGEN (höchste Priorität)
    if (title.contains(query)) score += 100.0;
    if (content.contains(query)) score += 50.0;
    if (category.contains(query)) score += 75.0;

    // 2. WORT-ÜBEREINSTIMMUNGEN
    for (var word in queryWords) {
      // Titel
      if (title.contains(word)) {
        score += 20.0;
        // Bonus für Wort am Anfang
        if (title.startsWith(word)) score += 10.0;
      }
      
      // Content
      final contentMatches = _countOccurrences(content, word);
      score += contentMatches * 5.0;
      
      // Kategorie
      if (category.contains(word)) score += 15.0;
      
      // Tags
      for (var tag in tags) {
        if (tag.contains(word)) score += 10.0;
      }
    }

    // 3. SEMANTISCHE ÄHNLICHKEIT (Synonyme & verwandte Begriffe)
    final synonymScore = _calculateSynonymScore(queryWords, title, content);
    score += synonymScore;

    // 4. AKTUALITÄT (neuere Artikel bevorzugen)
    final publishedDate = DateTime.tryParse(article['publishedDate'] ?? '');
    if (publishedDate != null) {
      final daysSincePublished = DateTime.now().difference(publishedDate).inDays;
      if (daysSincePublished < 7) {
        score += 10.0;
      } else if (daysSincePublished < 30) score += 5.0;
    }

    // 5. POPULARITÄT (falls verfügbar)
    final views = article['views'] as int? ?? 0;
    final likes = article['likes'] as int? ?? 0;
    score += (views / 100) + (likes * 2);

    return score;
  }

  /// Zähle Vorkommen eines Wortes
  int _countOccurrences(String text, String word) {
    return text.split(word).length - 1;
  }

  /// Berechne Synonym-Score
  double _calculateSynonymScore(List<String> queryWords, String title, String content) {
    double score = 0.0;

    // MATERIE-Synonyme
    final materieMap = {
      'illuminati': ['geheimbund', 'elite', 'freimauer', 'macht', 'kontrolle'],
      'ufo': ['alien', 'außerirdisch', 'raumschiff', 'area51', 'roswell'],
      'verschwörung': ['komplott', 'geheim', 'vertuschung', 'manipulation'],
      'finanzen': ['geld', 'bank', 'rothschild', 'fed', 'wirtschaft', 'krise'],
      'politik': ['regierung', 'staat', 'macht', 'kontrolle', 'system'],
    };

    // ENERGIE-Synonyme
    final energieMap = {
      'meditation': ['achtsamkeit', 'bewusstsein', 'zen', 'ruhe', 'entspannung'],
      'chakra': ['energie', 'kundalini', 'aura', 'heilung', 'balance'],
      'astral': ['obe', 'traumreise', 'projektion', 'bewusstsein'],
      'spirituell': ['geistig', 'seele', 'transzendenz', 'erleuchtung'],
      'kristall': ['stein', 'heilstein', 'energie', 'schwingung'],
    };

    final combinedMap = {...materieMap, ...energieMap};

    for (var word in queryWords) {
      // Prüfe ob Query-Wort ein Hauptbegriff ist
      if (combinedMap.containsKey(word)) {
        for (var synonym in combinedMap[word]!) {
          if (title.contains(synonym)) score += 8.0;
          if (content.contains(synonym)) score += 3.0;
        }
      }

      // Prüfe ob Query-Wort ein Synonym ist
      for (var entry in combinedMap.entries) {
        if (entry.value.contains(word)) {
          if (title.contains(entry.key)) score += 8.0;
          if (content.contains(entry.key)) score += 3.0;
        }
      }
    }

    return score;
  }

  /// Such-Vorschläge basierend auf Query
  List<String> getSuggestions(String query, List<String> allTitles) {
    if (query.length < 2) return [];

    final normalizedQuery = query.toLowerCase();
    final suggestions = <String>[];

    for (var title in allTitles) {
      if (title.toLowerCase().contains(normalizedQuery)) {
        suggestions.add(title);
      }
      if (suggestions.length >= 5) break;
    }

    return suggestions;
  }

  /// Verwandte Artikel finden
  List<Map<String, dynamic>> findRelatedArticles({
    required Map<String, dynamic> article,
    required List<Map<String, dynamic>> allArticles,
    int maxResults = 5,
  }) {
    final results = <Map<String, dynamic>>[];
    final articleId = article['id'];
    final articleCategory = article['category'];
    final articleTags = List<String>.from(article['tags'] ?? []);
    final articleTitle = (article['title'] as String).toLowerCase();

    for (var other in allArticles) {
      if (other['id'] == articleId) continue; // Skip selbst

      double relScore = 0.0;

      // Gleiche Kategorie
      if (other['category'] == articleCategory) relScore += 30.0;

      // Gemeinsame Tags
      final otherTags = List<String>.from(other['tags'] ?? []);
      final commonTags = articleTags.where((tag) => otherTags.contains(tag)).length;
      relScore += commonTags * 15.0;

      // Ähnlicher Titel
      final otherTitle = (other['title'] as String).toLowerCase();
      final titleWords = articleTitle.split(' ').where((w) => w.length > 3).toList();
      for (var word in titleWords) {
        if (otherTitle.contains(word)) relScore += 10.0;
      }

      // Gleiche Welt
      if (other['world'] == article['world']) relScore += 20.0;

      if (relScore > 0) {
        final result = Map<String, dynamic>.from(other);
        result['relatedScore'] = relScore;
        results.add(result);
      }
    }

    // Sortiere nach Relevanz
    results.sort((a, b) => (b['relatedScore'] as double).compareTo(a['relatedScore'] as double));

    return results.take(maxResults).toList();
  }

  /// Such-Historie speichern
  Future<void> _addToHistory(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_searchHistoryKey) ?? '[]';
      final history = List<String>.from(jsonDecode(historyJson));

      // Entferne Duplikate
      history.remove(query);
      
      // Füge an den Anfang hinzu
      history.insert(0, query);

      // Begrenze Anzahl
      if (history.length > _maxHistoryItems) {
        history.removeRange(_maxHistoryItems, history.length);
      }

      await prefs.setString(_searchHistoryKey, jsonEncode(history));
    } catch (e) {
      debugPrint('❌ Fehler beim Speichern der Such-Historie: $e');
    }
  }

  /// Such-Historie abrufen
  Future<List<String>> getSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_searchHistoryKey) ?? '[]';
      return List<String>.from(jsonDecode(historyJson));
    } catch (e) {
      debugPrint('❌ Fehler beim Laden der Such-Historie: $e');
      return [];
    }
  }

  /// Such-Historie löschen
  Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_searchHistoryKey);
  }

  /// Trending/Populäre Suchen
  List<String> getTrendingSearches(String world) {
    if (world == 'materie') {
      return [
        'Illuminati',
        'UFO Sichtungen',
        'Finanzkrise',
        'Geheimbünde',
        'Area 51',
        'Rothschild',
        'Deep State',
        'MK Ultra',
      ];
    } else {
      return [
        'Meditation',
        'Chakra Heilung',
        'Astralreisen',
        'Kristalle',
        'Vollmond Ritual',
        'Kundalini',
        'Numerologie',
        'Tarot',
      ];
    }
  }
}
