/// Recherche Bookmarks Service
/// Speichert und verwaltet gespeicherte Recherchen
library;

import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';

class RechercheBookmark {
  final String id;
  final String query;
  final DateTime timestamp;
  final String? summary;
  final int sourceCount;
  final List<String> tags;
  
  RechercheBookmark({
    required this.id,
    required this.query,
    required this.timestamp,
    this.summary,
    this.sourceCount = 0,
    this.tags = const [],
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'query': query,
    'timestamp': timestamp.toIso8601String(),
    'summary': summary,
    'sourceCount': sourceCount,
    'tags': tags,
  };
  
  factory RechercheBookmark.fromJson(Map<String, dynamic> json) {
    return RechercheBookmark(
      id: json['id'] as String,
      query: json['query'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      summary: json['summary'] as String?,
      sourceCount: json['sourceCount'] as int? ?? 0,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class RechercheBookmarksService {
  static const String _boxName = 'recherche_bookmarks';
  
  Box<dynamic>? _box;
  
  /// Initialize Hive box
  Future<void> init() async {
    try {
      _box = await Hive.openBox(_boxName);
      if (kDebugMode) {
        debugPrint('✅ [Bookmarks] Initialized with ${_box!.length} bookmarks');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Bookmarks] Init failed: $e');
      }
    }
  }
  
  /// Add bookmark
  Future<bool> addBookmark({
    required String query,
    String? summary,
    int sourceCount = 0,
    List<String> tags = const [],
  }) async {
    if (_box == null) await init();
    
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final bookmark = RechercheBookmark(
        id: id,
        query: query.trim(),
        timestamp: DateTime.now(),
        summary: summary,
        sourceCount: sourceCount,
        tags: tags,
      );
      
      await _box!.put(id, bookmark.toJson());
      
      if (kDebugMode) {
        debugPrint('✅ [Bookmarks] Added: "$query"');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Bookmarks] Add failed: $e');
      }
      return false;
    }
  }
  
  /// Get all bookmarks
  Future<List<RechercheBookmark>> getBookmarks() async {
    if (_box == null) await init();
    
    try {
      final bookmarks = <RechercheBookmark>[];
      
      for (var key in _box!.keys) {
        final json = _box!.get(key) as Map<String, dynamic>;
        bookmarks.add(RechercheBookmark.fromJson(json));
      }
      
      // Sort by timestamp (newest first)
      bookmarks.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return bookmarks;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Bookmarks] Get failed: $e');
      }
      return [];
    }
  }
  
  /// Check if query is bookmarked
  Future<bool> isBookmarked(String query) async {
    if (_box == null) await init();
    
    try {
      final bookmarks = await getBookmarks();
      return bookmarks.any((b) => b.query.toLowerCase() == query.toLowerCase());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Bookmarks] Check failed: $e');
      }
      return false;
    }
  }
  
  /// Remove bookmark
  Future<bool> removeBookmark(String bookmarkId) async {
    if (_box == null) await init();
    
    try {
      await _box!.delete(bookmarkId);
      
      if (kDebugMode) {
        debugPrint('✅ [Bookmarks] Removed: $bookmarkId');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Bookmarks] Remove failed: $e');
      }
      return false;
    }
  }
  
  /// Remove bookmark by query
  Future<bool> removeBookmarkByQuery(String query) async {
    if (_box == null) await init();
    
    try {
      final bookmarks = await getBookmarks();
      final bookmark = bookmarks.firstWhere(
        (b) => b.query.toLowerCase() == query.toLowerCase(),
        orElse: () => throw Exception('Not found'),
      );
      
      return await removeBookmark(bookmark.id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Bookmarks] Remove by query failed: $e');
      }
      return false;
    }
  }
  
  /// Clear all bookmarks
  Future<void> clearAll() async {
    if (_box == null) await init();
    
    try {
      await _box!.clear();
      if (kDebugMode) {
        debugPrint('✅ [Bookmarks] Cleared all');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Bookmarks] Clear failed: $e');
      }
    }
  }
  
  /// Get bookmarks by tag
  Future<List<RechercheBookmark>> getBookmarksByTag(String tag) async {
    final bookmarks = await getBookmarks();
    return bookmarks.where((b) => b.tags.contains(tag)).toList();
  }
}
