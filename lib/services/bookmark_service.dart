/// 🔖 BOOKMARK SERVICE v2.0 (SharedPreferences)
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Bookmark {
  String id;
  String title;
  String url;
  String? description;
  String? thumbnailUrl;
  String category;
  DateTime createdAt;
  List<String> tags;
  Map<String, dynamic>? metadata;

  Bookmark({
    required this.id,
    required this.title,
    required this.url,
    this.description,
    this.thumbnailUrl,
    this.category = 'general',
    DateTime? createdAt,
    List<String>? tags,
    this.metadata,
  })  : createdAt = createdAt ?? DateTime.now(),
        tags = tags ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'url': url,
    'description': description,
    'thumbnailUrl': thumbnailUrl,
    'category': category,
    'createdAt': createdAt.toIso8601String(),
    'tags': tags,
    'metadata': metadata,
  };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
    id: json['id'] as String,
    title: json['title'] as String,
    url: json['url'] as String,
    description: json['description'] as String?,
    thumbnailUrl: json['thumbnailUrl'] as String?,
    category: json['category'] as String? ?? 'general',
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
    tags: (json['tags'] as List?)?.cast<String>() ?? [],
    metadata: json['metadata'] as Map<String, dynamic>?,
  );
}

class BookmarkService {
  static const String _kBookmarks = 'bookmarks_list';

  List<Bookmark> _bookmarks = [];
  bool _loaded = false;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kBookmarks);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _bookmarks = list
            .map((e) => Bookmark.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      _loaded = true;
      if (kDebugMode) {
        debugPrint('🔖 BookmarkService initialized: ${_bookmarks.length} bookmarks');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error initializing BookmarkService: $e');
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kBookmarks,
      jsonEncode(_bookmarks.map((b) => b.toJson()).toList()),
    );
  }

  Future<void> _ensureLoaded() async {
    if (!_loaded) await init();
  }

  /// Add bookmark
  Future<bool> addBookmark(Bookmark bookmark) async {
    try {
      await _ensureLoaded();
      if (_bookmarks.any((b) => b.id == bookmark.id)) {
        if (kDebugMode) debugPrint('⚠️ Bookmark already exists: ${bookmark.id}');
        return false;
      }
      _bookmarks.add(bookmark);
      await _persist();
      if (kDebugMode) debugPrint('✅ Bookmark added: ${bookmark.title}');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error adding bookmark: $e');
      return false;
    }
  }

  /// Remove bookmark by ID
  Future<bool> removeBookmark(String id) async {
    try {
      await _ensureLoaded();
      final before = _bookmarks.length;
      _bookmarks.removeWhere((b) => b.id == id);
      if (_bookmarks.length < before) {
        await _persist();
        if (kDebugMode) debugPrint('✅ Bookmark removed: $id');
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error removing bookmark: $e');
      return false;
    }
  }

  /// Get all bookmarks sorted by newest first
  Future<List<Bookmark>> getAllBookmarks() async {
    await _ensureLoaded();
    return List.of(_bookmarks)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get bookmarks by category
  Future<List<Bookmark>> getBookmarksByCategory(String category) async {
    await _ensureLoaded();
    return _bookmarks
        .where((b) => b.category == category)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Search bookmarks
  Future<List<Bookmark>> searchBookmarks(String query) async {
    await _ensureLoaded();
    if (query.isEmpty) return getAllBookmarks();
    final q = query.toLowerCase();
    return _bookmarks
        .where((b) =>
            b.title.toLowerCase().contains(q) ||
            (b.description?.toLowerCase().contains(q) ?? false) ||
            b.tags.any((tag) => tag.toLowerCase().contains(q)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Check if bookmark exists
  Future<bool> isBookmarked(String id) async {
    await _ensureLoaded();
    return _bookmarks.any((b) => b.id == id);
  }

  /// Get bookmark count
  Future<int> getBookmarkCount() async {
    await _ensureLoaded();
    return _bookmarks.length;
  }

  /// Get count by category
  Future<int> getCountByCategory(String category) async {
    await _ensureLoaded();
    return _bookmarks.where((b) => b.category == category).length;
  }

  /// Clear all bookmarks
  Future<void> clearAll() async {
    _bookmarks.clear();
    await _persist();
  }

  /// Alias für removeBookmark (UI-kompatibel)
  Future<bool> deleteBookmark(String id) => removeBookmark(id);

  /// Export aller Bookmarks als JSON-Liste
  Future<List<Map<String, dynamic>>> exportBookmarks() async {
    await _ensureLoaded();
    return _bookmarks.map((b) => b.toJson()).toList();
  }

  /// Sync-Statistiken (liest aus in-memory Cache).
  /// Erwartet, dass init() bereits gelaufen ist.
  Map<String, dynamic> getStatistics() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart  = todayStart.subtract(Duration(days: todayStart.weekday - 1));

    int recherche = 0, narratives = 0, andere = 0;
    int addedToday = 0, addedThisWeek = 0;

    for (final b in _bookmarks) {
      switch (b.category) {
        case 'Recherche':  recherche++; break;
        case 'Narratives': narratives++; break;
        default:           andere++;
      }
      if (!b.createdAt.isBefore(todayStart)) addedToday++;
      if (!b.createdAt.isBefore(weekStart))  addedThisWeek++;
    }

    return {
      'total': _bookmarks.length,
      'byCategory': {
        'Recherche':  recherche,
        'Narratives': narratives,
        'Andere':     andere,
      },
      'addedToday':    addedToday,
      'addedThisWeek': addedThisWeek,
    };
  }
}
