import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// 📚 RESEARCH HISTORY SERVICE
/// Enhanced search history with categorization and advanced features
class ResearchHistoryService {
  static const String _boxName = 'research_history_enhanced';
  static const int _maxHistoryItems = 100;
  
  /// Save search with metadata
  Future<void> saveSearch({
    required String query,
    String? category,
    int? resultCount,
    DateTime? timestamp,
  }) async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      
      final entry = {
        'query': query,
        'category': category ?? _autoDetectCategory(query),
        'result_count': resultCount ?? 0,
        'timestamp': (timestamp ?? DateTime.now()).millisecondsSinceEpoch,
      };
      
      // Use timestamp as key
      final key = entry['timestamp'].toString();
      await box.put(key, entry);
      
      // Cleanup old entries
      if (box.length > _maxHistoryItems) {
        final keys = box.keys.toList()..sort();
        final toDelete = keys.take(box.length - _maxHistoryItems);
        for (final key in toDelete) {
          await box.delete(key);
        }
      }
      
      if (kDebugMode) {
        debugPrint('✅ [HISTORY] Search saved: $query (${entry['category']})');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [HISTORY] Error saving search: $e');
      }
    }
  }
  
  /// Get all history entries
  Future<List<ResearchHistoryEntry>> getAllHistory() async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      final entries = <ResearchHistoryEntry>[];
      
      for (final entry in box.values) {
        entries.add(ResearchHistoryEntry.fromMap(Map<String, dynamic>.from(entry)));
      }
      
      // Sort by timestamp (newest first)
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return entries;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [HISTORY] Error loading history: $e');
      }
      return [];
    }
  }
  
  /// Get history by category
  Future<List<ResearchHistoryEntry>> getHistoryByCategory(String category) async {
    final allHistory = await getAllHistory();
    return allHistory.where((entry) => entry.category == category).toList();
  }
  
  /// Search in history
  Future<List<ResearchHistoryEntry>> searchHistory(String searchQuery) async {
    final allHistory = await getAllHistory();
    final queryLower = searchQuery.toLowerCase();
    
    return allHistory.where((entry) {
      return entry.query.toLowerCase().contains(queryLower);
    }).toList();
  }
  
  /// Get recent searches (last N)
  Future<List<ResearchHistoryEntry>> getRecentSearches({int limit = 10}) async {
    final allHistory = await getAllHistory();
    return allHistory.take(limit).toList();
  }
  
  /// Get categories with counts
  Future<Map<String, int>> getCategoryCounts() async {
    final allHistory = await getAllHistory();
    final counts = <String, int>{};
    
    for (final entry in allHistory) {
      counts[entry.category] = (counts[entry.category] ?? 0) + 1;
    }
    
    return counts;
  }
  
  /// Delete entry
  Future<void> deleteEntry(int timestamp) async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      await box.delete(timestamp.toString());
      
      if (kDebugMode) {
        debugPrint('✅ [HISTORY] Entry deleted: $timestamp');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [HISTORY] Error deleting entry: $e');
      }
    }
  }
  
  /// Clear all history
  Future<void> clearHistory() async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      await box.clear();
      
      if (kDebugMode) {
        debugPrint('✅ [HISTORY] All history cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [HISTORY] Error clearing history: $e');
      }
    }
  }
  
  /// Auto-detect category from query
  String _autoDetectCategory(String query) {
    final queryLower = query.toLowerCase();
    
    // Politik & Geopolitik
    if (_containsAny(queryLower, ['politik', 'regierung', 'biden', 'trump', 'putin', 'wahl', 'eu', 'nato'])) {
      return 'Politik';
    }
    
    // Verschwörungstheorien
    if (_containsAny(queryLower, ['illuminati', 'freimaurerei', 'nwo', 'weltordnung', 'deepstate', 'bilderberg', 'skull', 'bohemian'])) {
      return 'Verschwörung';
    }
    
    // UFOs & Alien
    if (_containsAny(queryLower, ['ufo', 'alien', 'außerirdisch', 'area 51', 'roswell', 'uap'])) {
      return 'UFO & Alien';
    }
    
    // Geheime Programme
    if (_containsAny(queryLower, ['mk-ultra', 'mkultra', 'operation', 'cia', 'nsa', 'fbi', 'geheim'])) {
      return 'Geheimprogramme';
    }
    
    // Geschichte
    if (_containsAny(queryLower, ['geschichte', 'historisch', 'krieg', 'jfk', '9/11', 'attentat', 'pearl harbor'])) {
      return 'Geschichte';
    }
    
    // Wirtschaft & Finanzen
    if (_containsAny(queryLower, ['panama', 'geld', 'bank', 'finanz', 'wirtschaft', 'börse', 'paradise papers', 'steuerhinterziehung'])) {
      return 'Wirtschaft';
    }
    
    // Medien & Propaganda
    if (_containsAny(queryLower, ['medien', 'propaganda', 'mockingbird', 'zensur', 'manipulation', 'fake news'])) {
      return 'Medien';
    }
    
    // Technologie
    if (_containsAny(queryLower, ['haarp', 'technologie', '5g', 'überwachung', 'snowden', 'wikileaks', 'assange'])) {
      return 'Technologie';
    }
    
    // Gesundheit
    if (_containsAny(queryLower, ['impf', 'pharmaindustrie', 'who', 'gesundheit', 'medizin', 'corona', 'covid'])) {
      return 'Gesundheit';
    }
    
    // Epstein & Elite
    if (_containsAny(queryLower, ['epstein', 'maxwell', 'elite', 'pädophilie', 'lolita'])) {
      return 'Elite & Skandale';
    }
    
    // Default
    return 'Allgemein';
  }
  
  /// Helper: Check if string contains any of the keywords
  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }
}

/// Research History Entry Model
class ResearchHistoryEntry {
  final String query;
  final String category;
  final int resultCount;
  final DateTime timestamp;
  
  ResearchHistoryEntry({
    required this.query,
    required this.category,
    required this.resultCount,
    required this.timestamp,
  });
  
  factory ResearchHistoryEntry.fromMap(Map<String, dynamic> map) {
    return ResearchHistoryEntry(
      query: map['query'] as String,
      category: map['category'] as String,
      resultCount: map['result_count'] as int? ?? 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'query': query,
      'category': category,
      'result_count': resultCount,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
  
  /// Get category icon
  String get categoryIcon {
    switch (category) {
      case 'Politik':
        return '🏛️';
      case 'Verschwörung':
        return '👁️';
      case 'UFO & Alien':
        return '🛸';
      case 'Geheimprogramme':
        return '🕵️';
      case 'Geschichte':
        return '📜';
      case 'Wirtschaft':
        return '💰';
      case 'Medien':
        return '📺';
      case 'Technologie':
        return '💻';
      case 'Gesundheit':
        return '🏥';
      case 'Elite & Skandale':
        return '👔';
      default:
        return '📁';
    }
  }
  
  /// Get category color
  String get categoryColor {
    switch (category) {
      case 'Politik':
        return 'blue';
      case 'Verschwörung':
        return 'purple';
      case 'UFO & Alien':
        return 'green';
      case 'Geheimprogramme':
        return 'red';
      case 'Geschichte':
        return 'brown';
      case 'Wirtschaft':
        return 'orange';
      case 'Medien':
        return 'cyan';
      case 'Technologie':
        return 'teal';
      case 'Gesundheit':
        return 'pink';
      case 'Elite & Skandale':
        return 'deepPurple';
      default:
        return 'grey';
    }
  }
  
  /// Format timestamp
  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) {
      return 'Gerade eben';
    } else if (diff.inHours < 1) {
      return 'Vor ${diff.inMinutes} Min.';
    } else if (diff.inDays < 1) {
      return 'Vor ${diff.inHours} Std.';
    } else if (diff.inDays < 7) {
      return 'Vor ${diff.inDays} Tag${diff.inDays > 1 ? 'en' : ''}';
    } else {
      return '${timestamp.day}.${timestamp.month}.${timestamp.year}';
    }
  }
}
