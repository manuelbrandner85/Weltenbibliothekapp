import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorite.dart';
import 'achievement_service.dart';

/// Favorites Service v9.0 (SharedPreferences)
///
/// Verwaltet Lesezeichen & Favoriten lokal – in-memory + SharedPreferences.
class FavoritesService {
  static const String _kFavorites = 'favorites_list';

  static List<Favorite> _favorites = [];
  static bool _loaded = false;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kFavorites);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _favorites = list
            .map((e) => Favorite.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('⚠️ FavoritesService: konnte Favoriten-JSON nicht parsen — '
              'reset auf leere Liste. $e\n$st');
        }
        _favorites = [];
      }
    }
    _loaded = true;
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kFavorites,
      jsonEncode(_favorites.map((f) => f.toJson()).toList()),
    );
  }

  static Future<void> _ensureLoaded() async {
    if (!_loaded) await init();
  }

  // ==================== CREATE ====================

  static Future<void> addFavorite(Favorite favorite) async {
    await _ensureLoaded();
    _favorites.removeWhere((f) => f.id == favorite.id);
    _favorites.add(favorite);
    await _persist();
    _trackBookmarkAchievement();
  }

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

  static List<Favorite> getAllFavorites() {
    return List.of(_favorites)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static List<Favorite> getFavoritesByType(FavoriteType type) {
    return _favorites
        .where((f) => f.type == type)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Favorite? getFavoriteById(String id) {
    try {
      return _favorites.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  static bool isFavorite(String id) => _favorites.any((f) => f.id == id);

  static List<Favorite> searchFavorites(String query) {
    final q = query.toLowerCase();
    return _favorites
        .where((f) =>
            f.title.toLowerCase().contains(q) ||
            (f.description?.toLowerCase().contains(q) ?? false) ||
            (f.tags?.any((tag) => tag.toLowerCase().contains(q)) ?? false))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static int getFavoritesCount() => _favorites.length;

  static int getFavoritesCountByType(FavoriteType type) =>
      _favorites.where((f) => f.type == type).length;

  // ==================== UPDATE ====================

  static Future<void> updateFavorite(Favorite favorite) async {
    await _ensureLoaded();
    final idx = _favorites.indexWhere((f) => f.id == favorite.id);
    if (idx != -1) _favorites[idx] = favorite;
    await _persist();
  }

  static Future<void> addTag(String favoriteId, String tag) async {
    await _ensureLoaded();
    final idx = _favorites.indexWhere((f) => f.id == favoriteId);
    if (idx == -1) return;
    final f = _favorites[idx];
    f.tags ??= [];
    if (!f.tags!.contains(tag)) {
      f.tags!.add(tag);
      await _persist();
    }
  }

  static Future<void> removeTag(String favoriteId, String tag) async {
    await _ensureLoaded();
    final idx = _favorites.indexWhere((f) => f.id == favoriteId);
    if (idx == -1) return;
    _favorites[idx].tags?.remove(tag);
    await _persist();
  }

  // ==================== DELETE ====================

  static Future<void> deleteFavorite(String id) async {
    await _ensureLoaded();
    _favorites.removeWhere((f) => f.id == id);
    await _persist();
  }

  static Future<void> deleteFavoritesByType(FavoriteType type) async {
    await _ensureLoaded();
    _favorites.removeWhere((f) => f.type == type);
    await _persist();
  }

  static Future<void> clearAllFavorites() async {
    _favorites.clear();
    await _persist();
  }

  // ==================== IMPORT/EXPORT ====================

  static List<Map<String, dynamic>> exportToJson() =>
      _favorites.map((f) => f.toJson()).toList();

  static Future<int> importFromJson(List<Map<String, dynamic>> jsonList) async {
    int imported = 0;
    for (final json in jsonList) {
      try {
        await addFavorite(Favorite.fromJson(json));
        imported++;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ FavoritesService.import: skip 1 Eintrag — $e');
        }
        continue;
      }
    }
    return imported;
  }

  // ==================== STATISTICS ====================

  static Map<String, dynamic> getStatistics() {
    return {
      'total': _favorites.length,
      'byType': {
        for (var type in FavoriteType.values)
          type.label: _favorites.where((f) => f.type == type).length,
      },
      'oldestDate': _favorites.isEmpty
          ? null
          : _favorites
              .reduce((a, b) => a.createdAt.isBefore(b.createdAt) ? a : b)
              .createdAt,
      'newestDate': _favorites.isEmpty
          ? null
          : _favorites
              .reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b)
              .createdAt,
    };
  }

  static void _trackBookmarkAchievement() {
    try {
      AchievementService().incrementProgress('first_bookmark');
      AchievementService().incrementProgress('curator');
      AchievementService().incrementProgress('knowledge_seeker');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Achievement-Tracking fehlgeschlagen: $e');
      }
    }
  }
}
