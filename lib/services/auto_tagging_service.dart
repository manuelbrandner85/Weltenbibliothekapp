// lib/services/auto_tagging_service.dart
// WELTENBIBLIOTHEK v9.0 - FEATURE 15: AUTO-TAGGING & SMART FILTERS
// AI-powered content analysis and automatic tag generation

import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Auto-Tagging Service - Singleton
/// Analyzes content and generates relevant tags automatically
class AutoTaggingService {
  static final AutoTaggingService _instance = AutoTaggingService._internal();
  factory AutoTaggingService() => _instance;
  AutoTaggingService._internal();

  static const String _backendUrl = 'https://weltenbibliothek-api-v2.brandy13062.workers.dev';

  // Pre-defined tag categories for Weltenbibliothek
  static const Map<String, List<String>> _tagCategories = {
    'Thema': ['Atlantis', 'Pyramiden', 'UFOs', 'Verschwörung', 'Wissenschaft', 'Mystik', 'Geschichte', 'Technologie'],
    'Zeitraum': ['Antike', 'Mittelalter', 'Neuzeit', 'Modern', 'Zukunft'],
    'Region': ['Europa', 'Asien', 'Amerika', 'Afrika', 'Ozeanien', 'Global'],
    'Typ': ['Theorie', 'Fakt', 'Spekulation', 'Beweis', 'Legende', 'Mythos'],
  };

  // Common German stop words (expanded list)
  static const Set<String> _stopWords = {
    'der', 'die', 'das', 'und', 'oder', 'aber', 'ein', 'eine', 'von', 'zu', 
    'im', 'in', 'auf', 'für', 'mit', 'ist', 'sind', 'war', 'wurden', 'wird',
    'als', 'an', 'aus', 'bei', 'bis', 'dem', 'den', 'des', 'durch', 'es',
    'hat', 'haben', 'sein', 'seine', 'seiner', 'um', 'über', 'unter', 'vom',
    'was', 'wie', 'zum', 'zur', 'auch', 'noch', 'nur', 'so', 'sehr',
  };

  /// Analyze content and generate tags
  Future<TagAnalysisResult> analyzeContent({
    required String title,
    String? description,
    String? category,
    List<String>? existingTags,
  }) async {
    try {
      // Combine text for analysis
      final fullText = '$title ${description ?? ''}';
      
      // Extract keywords
      final keywords = _extractKeywords(fullText);
      
      // Generate suggested tags
      final suggestedTags = _generateTags(
        keywords: keywords,
        title: title,
        description: description,
        category: category,
        existingTags: existingTags,
      );
      
      // Calculate confidence scores
      final tagScores = _calculateConfidenceScores(suggestedTags, keywords, fullText);
      
      // Try backend AI analysis (optional enhancement)
      final backendTags = await _getBackendSuggestions(title, description);
      
      // Merge backend suggestions
      for (final tag in backendTags) {
        if (!suggestedTags.contains(tag)) {
          suggestedTags.add(tag);
          tagScores[tag] = 0.7; // Medium confidence for backend tags
        }
      }
      
      // Sort by confidence score
      suggestedTags.sort((a, b) {
        final scoreA = tagScores[a] ?? 0.0;
        final scoreB = tagScores[b] ?? 0.0;
        return scoreB.compareTo(scoreA);
      });
      
      if (kDebugMode) {
        debugPrint('🏷️ Auto-Tagging Analysis: ${suggestedTags.length} tags generated');
      }
      
      return TagAnalysisResult(
        suggestedTags: suggestedTags.take(20).toList(), // Top 20 tags
        keywords: keywords.take(30).toList(),
        confidenceScores: tagScores,
        categories: _categorizeTagsArray(suggestedTags),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Auto-Tagging error: $e');
      }
      return TagAnalysisResult(
        suggestedTags: existingTags ?? [],
        keywords: [],
        confidenceScores: {},
        categories: {},
      );
    }
  }

  /// Extract keywords from text
  List<String> _extractKeywords(String text) {
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\säöüß]'), ' ')
        .split(RegExp(r'\s+'));
    
    // Count word frequencies
    final wordFreq = <String, int>{};
    for (final word in words) {
      if (word.length > 3 && !_stopWords.contains(word)) {
        wordFreq[word] = (wordFreq[word] ?? 0) + 1;
      }
    }
    
    // Sort by frequency
    final sortedWords = wordFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedWords.map((e) => e.key).toList();
  }

  /// Generate tags from keywords and context
  List<String> _generateTags({
    required List<String> keywords,
    required String title,
    String? description,
    String? category,
    List<String>? existingTags,
  }) {
    final tags = <String>{};
    
    // Add existing tags
    if (existingTags != null) {
      tags.addAll(existingTags);
    }
    
    // Add category as tag
    if (category != null && category.isNotEmpty) {
      tags.add(category);
    }
    
    // Extract multi-word phrases from title
    final titleWords = title.split(' ');
    if (titleWords.length >= 2) {
      for (var i = 0; i < titleWords.length - 1; i++) {
        final phrase = '${titleWords[i]} ${titleWords[i + 1]}'.toLowerCase();
        if (!_stopWords.contains(titleWords[i].toLowerCase()) &&
            !_stopWords.contains(titleWords[i + 1].toLowerCase())) {
          tags.add(_capitalize(phrase));
        }
      }
    }
    
    // Add keywords as tags (capitalized)
    for (final keyword in keywords.take(15)) {
      tags.add(_capitalize(keyword));
    }
    
    // Match against pre-defined categories
    for (final category in _tagCategories.values) {
      for (final predefinedTag in category) {
        if (title.toLowerCase().contains(predefinedTag.toLowerCase()) ||
            (description?.toLowerCase().contains(predefinedTag.toLowerCase()) ?? false)) {
          tags.add(predefinedTag);
        }
      }
    }
    
    return tags.toList();
  }

  /// Calculate confidence scores for tags
  Map<String, double> _calculateConfidenceScores(
    List<String> tags,
    List<String> keywords,
    String fullText,
  ) {
    final scores = <String, double>{};
    final lowerText = fullText.toLowerCase();
    
    for (final tag in tags) {
      double score = 0.0;
      final lowerTag = tag.toLowerCase();
      
      // Check title presence (high weight)
      if (lowerText.split('.').first.contains(lowerTag)) {
        score += 0.5;
      }
      
      // Check keyword match
      if (keywords.contains(lowerTag)) {
        score += 0.3;
      }
      
      // Check frequency in text
      final occurrences = lowerText.split(lowerTag).length - 1;
      score += (occurrences * 0.1).clamp(0.0, 0.3);
      
      // Pre-defined tag bonus
      if (_tagCategories.values.any((category) => category.contains(tag))) {
        score += 0.2;
      }
      
      scores[tag] = score.clamp(0.0, 1.0);
    }
    
    return scores;
  }

  /// Categorize tags into predefined categories
  Map<String, List<String>> _categorizeTagsArray(List<String> tags) {
    final categorized = <String, List<String>>{};
    
    for (final categoryName in _tagCategories.keys) {
      final categoryTags = <String>[];
      for (final tag in tags) {
        if (_tagCategories[categoryName]!.contains(tag)) {
          categoryTags.add(tag);
        }
      }
      if (categoryTags.isNotEmpty) {
        categorized[categoryName] = categoryTags;
      }
    }
    
    // Add uncategorized tags
    final uncategorized = tags.where((tag) {
      return !categorized.values.any((catTags) => catTags.contains(tag));
    }).toList();
    
    if (uncategorized.isNotEmpty) {
      categorized['Weitere'] = uncategorized;
    }
    
    return categorized;
  }

  /// Get tag suggestions from backend AI (optional)
  Future<List<String>> _getBackendSuggestions(
    String title,
    String? description,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/ai/auto-tag'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'description': description ?? '',
        }),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['tags'] as List?)?.map((t) => t.toString()).toList() ?? [];
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Backend tagging unavailable: $e');
      }
    }
    
    return [];
  }

  /// Get trending tags
  Future<List<TrendingTag>> getTrendingTags({
    int limit = 20,
    Duration timeWindow = const Duration(days: 7),
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/api/tags/trending?limit=$limit&days=${timeWindow.inDays}'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['trending'] as List?)
                ?.map((t) => TrendingTag.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [];
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Trending tags unavailable: $e');
      }
    }
    
    return _getMockTrendingTags();
  }

  /// Get mock trending tags (fallback)
  List<TrendingTag> _getMockTrendingTags() {
    return [
      TrendingTag(tag: 'Atlantis', count: 125, trend: 0.15),
      TrendingTag(tag: 'UFOs', count: 98, trend: 0.22),
      TrendingTag(tag: 'Pyramiden', count: 87, trend: 0.08),
      TrendingTag(tag: 'Verschwörung', count: 76, trend: -0.05),
      TrendingTag(tag: 'Mystik', count: 65, trend: 0.12),
    ];
  }

  /// Capitalize first letter of string
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Get all available tag categories
  static Map<String, List<String>> getTagCategories() => _tagCategories;

  /// Validate tag name
  static bool isValidTag(String tag) {
    return tag.length >= 2 && tag.length <= 50 && !_stopWords.contains(tag.toLowerCase());
  }
}

/// Tag Analysis Result
class TagAnalysisResult {
  final List<String> suggestedTags;
  final List<String> keywords;
  final Map<String, double> confidenceScores;
  final Map<String, List<String>> categories;

  TagAnalysisResult({
    required this.suggestedTags,
    required this.keywords,
    required this.confidenceScores,
    required this.categories,
  });

  /// Get tags above confidence threshold
  List<String> getHighConfidenceTags({double threshold = 0.6}) {
    return suggestedTags
        .where((tag) => (confidenceScores[tag] ?? 0.0) >= threshold)
        .toList();
  }

  @override
  String toString() {
    return 'TagAnalysisResult(tags: ${suggestedTags.length}, keywords: ${keywords.length}, categories: ${categories.keys.join(", ")})';
  }
}

/// Trending Tag Data Class
class TrendingTag {
  final String tag;
  final int count;
  final double trend; // Percentage change (-1.0 to 1.0)

  TrendingTag({
    required this.tag,
    required this.count,
    required this.trend,
  });

  factory TrendingTag.fromJson(Map<String, dynamic> json) {
    return TrendingTag(
      tag: json['tag'] as String,
      count: json['count'] as int,
      trend: (json['trend'] as num).toDouble(),
    );
  }

  /// Get trend emoji
  String get trendEmoji {
    if (trend > 0.1) return '🔥'; // Hot
    if (trend > 0.0) return '📈'; // Rising
    if (trend < -0.1) return '📉'; // Falling
    return '➡️'; // Stable
  }

  /// Get trend label
  String get trendLabel {
    if (trend > 0.1) return 'Hot';
    if (trend > 0.0) return 'Steigend';
    if (trend < -0.1) return 'Fallend';
    return 'Stabil';
  }

  @override
  String toString() {
    return 'TrendingTag(tag: $tag, count: $count, trend: ${(trend * 100).toStringAsFixed(0)}%)';
  }
}
