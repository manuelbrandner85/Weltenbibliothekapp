import 'package:hive_flutter/hive_flutter.dart';
import '../models/favorite.dart';
import 'achievement_service.dart';  // 🏆 Achievement System

/// Favorites Service v8.0
/// 
/// Verwaltet Lesezeichen & Favoriten mit Hive Local Storage
class FavoritesService {
  static const String _boxName = 'favorites';
  static Box<Favorite>? _box;

  /// Initialize Hive & open box
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(FavoriteAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(FavoriteTypeAdapter());
    }
    
    // Open box
    _box = await Hive.openBox<Favorite>(_boxName);
  }

  /// Get box instance
  static Box<Favorite> get box {
    if (_box == null || !_box!.isOpen) {
      throw Exception('Favorites box not initialized. Call FavoritesService.init() first.');
    }
    return _box!;
  }

  // ==================== CREATE ====================

  /// Add favorite
  static Future<void> addFavorite(Favorite favorite) async {
    await box.put(favorite.id, favorite);
    
    // 🏆 Achievement Trigger: Bookmark
    _trackBookmarkAchievement();
  }

  /// Quick add favorite
  static Future<Favorite> addQuickFavorite({
    required FavoriteType type,
    required String title,
    String? description,
    String? url,
    Map<String, dynamic>? metadata,
    List<String>? tags,
  }) async {
    final favorite = Favorite(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      title: title,
      description: description,
      url: url,
      createdAt: DateTime.now(),
      metadata: metadata,
      tags: tags,
    );
    
    await addFavorite(favorite);
    return favorite;
  }

  // ==================== READ ====================

  /// Get all favorites
  static List<Favorite> getAllFavorites() {
    return box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get favorites by type
  static List<Favorite> getFavoritesByType(FavoriteType type) {
    return box.values
        .where((f) => f.type == type)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get favorite by ID
  static Favorite? getFavoriteById(String id) {
    return box.get(id);
  }

  /// Check if favorite exists
  static bool isFavorite(String id) {
    return box.containsKey(id);
  }

  /// Search favorites
  static List<Favorite> searchFavorites(String query) {
    final queryLower = query.toLowerCase();
    return box.values
        .where((f) =>
            f.title.toLowerCase().contains(queryLower) ||
            (f.description?.toLowerCase().contains(queryLower) ?? false) ||
            (f.tags?.any((tag) => tag.toLowerCase().contains(queryLower)) ?? false))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get favorites count
  static int getFavoritesCount() {
    return box.length;
  }

  /// Get favorites count by type
  static int getFavoritesCountByType(FavoriteType type) {
    return box.values.where((f) => f.type == type).length;
  }

  // ==================== UPDATE ====================

  /// Update favorite
  static Future<void> updateFavorite(Favorite favorite) async {
    await box.put(favorite.id, favorite);
  }

  /// Add tag to favorite
  static Future<void> addTag(String favoriteId, String tag) async {
    final favorite = box.get(favoriteId);
    if (favorite != null) {
      favorite.tags ??= [];
      if (!favorite.tags!.contains(tag)) {
        favorite.tags!.add(tag);
        await box.put(favoriteId, favorite);
      }
    }
  }

  /// Remove tag from favorite
  static Future<void> removeTag(String favoriteId, String tag) async {
    final favorite = box.get(favoriteId);
    if (favorite != null && favorite.tags != null) {
      favorite.tags!.remove(tag);
      await box.put(favoriteId, favorite);
    }
  }

  // ==================== DELETE ====================

  /// Delete favorite
  static Future<void> deleteFavorite(String id) async {
    await box.delete(id);
  }

  /// Delete favorites by type
  static Future<void> deleteFavoritesByType(FavoriteType type) async {
    final idsToDelete = box.values
        .where((f) => f.type == type)
        .map((f) => f.id)
        .toList();
    
    for (final id in idsToDelete) {
      await box.delete(id);
    }
  }

  /// Clear all favorites
  static Future<void> clearAllFavorites() async {
    await box.clear();
  }

  // ==================== IMPORT/EXPORT ====================

  /// Export favorites to JSON
  static List<Map<String, dynamic>> exportToJson() {
    return box.values.map((f) => f.toJson()).toList();
  }

  /// Import favorites from JSON
  static Future<int> importFromJson(List<Map<String, dynamic>> jsonList) async {
    int imported = 0;
    for (final json in jsonList) {
      try {
        final favorite = Favorite.fromJson(json);
        await addFavorite(favorite);
        imported++;
      } catch (e) {
        // Skip invalid entries
        continue;
      }
    }
    return imported;
  }

  // ==================== STATISTICS ====================

  /// Get statistics
  static Map<String, dynamic> getStatistics() {
    final favorites = box.values.toList();
    
    return {
      'total': favorites.length,
      'byType': {
        for (var type in FavoriteType.values)
          type.label: favorites.where((f) => f.type == type).length,
      },
      'oldestDate': favorites.isEmpty
          ? null
          : favorites
              .reduce((a, b) => a.createdAt.isBefore(b.createdAt) ? a : b)
              .createdAt,
      'newestDate': favorites.isEmpty
          ? null
          : favorites
              .reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b)
              .createdAt,
    };
  }
  
  /// 🏆 Achievement Tracking Helper
  static void _trackBookmarkAchievement() {
    try {
      AchievementService().incrementProgress('first_bookmark');
      AchievementService().incrementProgress('curator');
      AchievementService().incrementProgress('knowledge_seeker');
    } catch (e) {
      // Silent fail - achievements are non-critical
    }
  }
}
