/// 🔖 BOOKMARK SERVICE
/// Lokales Bookmark-System für Recherche-Ergebnisse und Inhalte
/// 
/// Features:
/// - Bookmarks speichern (Hive)
/// - Bookmarks laden
/// - Kategorisierung
/// - Suchfunktion
/// - Export/Import
library;

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

// part 'bookmark_service.g.dart'; // TODO: Generate with build_runner

@HiveType(typeId: 10)
class Bookmark extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String title;
  
  @HiveField(2)
  String url;
  
  @HiveField(3)
  String? description;
  
  @HiveField(4)
  String? thumbnailUrl;
  
  @HiveField(5)
  String category; // 'recherche', 'narrative', 'wissen', etc.
  
  @HiveField(6)
  DateTime createdAt;
  
  @HiveField(7)
  List<String> tags;
  
  @HiveField(8)
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
}

class BookmarkService {
  static const String _boxName = 'bookmarks';
  Box<Bookmark>? _box;
  
  /// Initialize Hive box
  Future<void> init() async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        _box = await Hive.openBox<Bookmark>(_boxName);
      } else {
        _box = Hive.box<Bookmark>(_boxName);
      }
      
      if (kDebugMode) {
        debugPrint('🔖 BookmarkService initialized: ${_box!.length} bookmarks');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error initializing BookmarkService: $e');
      }
    }
  }
  
  /// Add bookmark
  Future<bool> addBookmark(Bookmark bookmark) async {
    try {
      await _ensureBoxOpen();
      
      // Check if already exists
      if (_box!.containsKey(bookmark.id)) {
        if (kDebugMode) {
          debugPrint('⚠️ Bookmark already exists: ${bookmark.id}');
        }
        return false;
      }
      
      await _box!.put(bookmark.id, bookmark);
      
      if (kDebugMode) {
        debugPrint('✅ Bookmark added: ${bookmark.title}');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error adding bookmark: $e');
      }
      return false;
    }
  }
  
  /// Remove bookmark
  Future<bool> removeBookmark(String id) async {
    try {
      await _ensureBoxOpen();
      
      if (_box!.containsKey(id)) {
        await _box!.delete(id);
        
        if (kDebugMode) {
          debugPrint('🗑️ Bookmark removed: $id');
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error removing bookmark: $e');
      }
      return false;
    }
  }
  
  /// Get all bookmarks
  Future<List<Bookmark>> getAllBookmarks() async {
    try {
      await _ensureBoxOpen();
      
      final bookmarks = _box!.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return bookmarks;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting bookmarks: $e');
      }
      return [];
    }
  }
  
  /// Get bookmarks by category
  Future<List<Bookmark>> getBookmarksByCategory(String category) async {
    try {
      await _ensureBoxOpen();
      
      final bookmarks = _box!.values
          .where((b) => b.category == category)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return bookmarks;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting bookmarks by category: $e');
      }
      return [];
    }
  }
  
  /// Search bookmarks
  Future<List<Bookmark>> searchBookmarks(String query) async {
    try {
      await _ensureBoxOpen();
      
      final lowerQuery = query.toLowerCase();
      final bookmarks = _box!.values
          .where((b) =>
              b.title.toLowerCase().contains(lowerQuery) ||
              (b.description?.toLowerCase().contains(lowerQuery) ?? false) ||
              b.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return bookmarks;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error searching bookmarks: $e');
      }
      return [];
    }
  }
  
  /// Check if bookmark exists
  Future<bool> isBookmarked(String id) async {
    try {
      await _ensureBoxOpen();
      return _box!.containsKey(id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking bookmark: $e');
      }
      return false;
    }
  }
  
  /// Get bookmark count
  Future<int> getBookmarkCount() async {
    try {
      await _ensureBoxOpen();
      return _box!.length;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting bookmark count: $e');
      }
      return 0;
    }
  }
  
  /// Get bookmark count by category
  Future<int> getBookmarkCountByCategory(String category) async {
    try {
      await _ensureBoxOpen();
      return _box!.values.where((b) => b.category == category).length;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting bookmark count by category: $e');
      }
      return 0;
    }
  }
  
  /// Clear all bookmarks
  Future<void> clearAll() async {
    try {
      await _ensureBoxOpen();
      await _box!.clear();
      
      if (kDebugMode) {
        debugPrint('🗑️ All bookmarks cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error clearing bookmarks: $e');
      }
    }
  }
  
  /// Ensure box is open
  Future<void> _ensureBoxOpen() async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }
  }
  
  /// Get categories with counts
  Future<Map<String, int>> getCategoryCounts() async {
    try {
      await _ensureBoxOpen();
      
      final Map<String, int> counts = {};
      for (final bookmark in _box!.values) {
        counts[bookmark.category] = (counts[bookmark.category] ?? 0) + 1;
      }
      
      return counts;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting category counts: $e');
      }
      return {};
    }
  }
  
  /// Delete bookmark (alias for removeBookmark)
  Future<bool> deleteBookmark(String id) async {
    return removeBookmark(id);
  }
  
  /// Export bookmarks to JSON
  Future<List<Map<String, dynamic>>> exportBookmarks() async {
    try {
      final bookmarks = await getAllBookmarks();
      return bookmarks.map((b) => {
        'id': b.id,
        'title': b.title,
        'url': b.url,
        'description': b.description,
        'thumbnailUrl': b.thumbnailUrl,
        'category': b.category,
        'createdAt': b.createdAt.toIso8601String(),
        'tags': b.tags,
        'metadata': b.metadata,
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error exporting bookmarks: $e');
      }
      return [];
    }
  }
  
  /// Get statistics
  Map<String, dynamic> getStatistics() {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekAgo = today.subtract(const Duration(days: 7));
      
      final all = _box?.values.toList() ?? [];
      final addedToday = all.where((b) {
        final bDate = DateTime(b.createdAt.year, b.createdAt.month, b.createdAt.day);
        return bDate == today;
      }).length;
      
      final addedThisWeek = all.where((b) => b.createdAt.isAfter(weekAgo)).length;
      
      final byCategory = <String, int>{};
      for (final bookmark in all) {
        byCategory[bookmark.category] = (byCategory[bookmark.category] ?? 0) + 1;
      }
      
      // Ensure default categories exist
      byCategory.putIfAbsent('Recherche', () => 0);
      byCategory.putIfAbsent('Narratives', () => 0);
      byCategory.putIfAbsent('Andere', () => 0);
      
      return {
        'total': all.length,
        'byCategory': byCategory,
        'addedToday': addedToday,
        'addedThisWeek': addedThisWeek,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting statistics: $e');
      }
      return {
        'total': 0,
        'byCategory': {'Recherche': 0, 'Narratives': 0, 'Andere': 0},
        'addedToday': 0,
        'addedThisWeek': 0,
      };
    }
  }
}
