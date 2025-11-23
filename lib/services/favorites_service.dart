import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import '../models/event_model.dart';

/// ═══════════════════════════════════════════════════════════════
/// FAVORITES SERVICE - Weltenbibliothek
/// ═══════════════════════════════════════════════════════════════
/// Manages user's favorite events with cloud sync
/// - Local caching for offline access
/// - Cloud sync with Cloudflare D1
/// - Real-time updates
/// ═══════════════════════════════════════════════════════════════

class FavoritesService {
  static const String baseUrl =
      'https://weltenbibliothek-webrtc.brandy13062.workers.dev';
  static const String _favoritesKey = 'user_favorites';

  final AuthService _authService = AuthService();
  final List<String> _favoriteEventIds = [];
  bool _isInitialized = false;

  // Singleton pattern
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  /// Initialize service and load favorites
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load from local cache first (instant UI update)
      await _loadLocalFavorites();

      // Then sync with server if authenticated
      if (_authService.isAuthenticated) {
        await syncFavorites();
      }

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Favorites init error: $e');
      }
    }
  }

  /// Get all favorite event IDs
  List<String> get favoriteEventIds => List.unmodifiable(_favoriteEventIds);

  /// Check if event is favorited
  bool isFavorite(String eventId) => _favoriteEventIds.contains(eventId);

  /// Get favorite count
  int get favoriteCount => _favoriteEventIds.length;

  // ═══════════════════════════════════════════════════════════════
  // FAVORITE MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  /// Add event to favorites
  Future<bool> addFavorite(EventModel event) async {
    if (isFavorite(event.id)) return false;

    try {
      // Optimistic update
      _favoriteEventIds.add(event.id);
      await _saveLocalFavorites();

      // Sync to server if authenticated
      if (_authService.isAuthenticated) {
        final response = await http.post(
          Uri.parse('$baseUrl/api/favorites'),
          headers: {
            'Content-Type': 'application/json',
            if (_authService.token != null)
              'Authorization': 'Bearer ${_authService.token}',
          },
          body: jsonEncode({
            'event_id': event.id,
            'event_title': event.title,
            'event_category': event.category,
            'latitude': event.location.latitude,
            'longitude': event.location.longitude,
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (kDebugMode) {
            print('⭐ Event favorited: ${event.title}');
          }
          return true;
        } else {
          // Rollback on server error
          _favoriteEventIds.remove(event.id);
          await _saveLocalFavorites();
          return false;
        }
      }

      return true;
    } catch (e) {
      // Rollback on error
      _favoriteEventIds.remove(event.id);
      await _saveLocalFavorites();

      if (kDebugMode) {
        print('❌ Add favorite error: $e');
      }
      return false;
    }
  }

  /// Remove event from favorites
  Future<bool> removeFavorite(String eventId) async {
    if (!isFavorite(eventId)) return false;

    try {
      // Optimistic update
      _favoriteEventIds.remove(eventId);
      await _saveLocalFavorites();

      // Sync to server if authenticated
      if (_authService.isAuthenticated) {
        final response = await http.delete(
          Uri.parse('$baseUrl/api/favorites/$eventId'),
          headers: {
            if (_authService.token != null)
              'Authorization': 'Bearer ${_authService.token}',
          },
        );

        if (response.statusCode == 200 || response.statusCode == 204) {
          if (kDebugMode) {
            print('🗑️ Event unfavorited: $eventId');
          }
          return true;
        } else {
          // Rollback on server error
          _favoriteEventIds.add(eventId);
          await _saveLocalFavorites();
          return false;
        }
      }

      return true;
    } catch (e) {
      // Rollback on error
      _favoriteEventIds.add(eventId);
      await _saveLocalFavorites();

      if (kDebugMode) {
        print('❌ Remove favorite error: $e');
      }
      return false;
    }
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(EventModel event) async {
    if (isFavorite(event.id)) {
      return await removeFavorite(event.id);
    } else {
      return await addFavorite(event);
    }
  }

  /// Clear all favorites (local only)
  Future<void> clearAllFavorites() async {
    _favoriteEventIds.clear();
    await _saveLocalFavorites();
  }

  // ═══════════════════════════════════════════════════════════════
  // CLOUD SYNC
  // ═══════════════════════════════════════════════════════════════

  /// Sync favorites with server
  Future<void> syncFavorites() async {
    if (!_authService.isAuthenticated) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/favorites'),
        headers: {
          if (_authService.token != null)
            'Authorization': 'Bearer ${_authService.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final favorites = data['favorites'] as List<dynamic>?;

        if (favorites != null) {
          _favoriteEventIds.clear();
          for (var fav in favorites) {
            final eventId = fav['event_id'] as String;
            if (!_favoriteEventIds.contains(eventId)) {
              _favoriteEventIds.add(eventId);
            }
          }

          await _saveLocalFavorites();

          if (kDebugMode) {
            print('🔄 Favorites synced: ${_favoriteEventIds.length} items');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Favorites sync error: $e');
      }
    }
  }

  /// Get popular events (most favorited)
  Future<List<Map<String, dynamic>>> getPopularEvents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/favorites/popular'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['popular_events'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Popular events error: $e');
      }
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // LOCAL STORAGE
  // ═══════════════════════════════════════════════════════════════

  /// Load favorites from local storage
  Future<void> _loadLocalFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoritesKey);

      if (favoritesJson != null) {
        final favorites = jsonDecode(favoritesJson) as List<dynamic>;
        _favoriteEventIds.clear();
        _favoriteEventIds.addAll(favorites.cast<String>());

        if (kDebugMode) {
          print('📂 Loaded ${_favoriteEventIds.length} favorites from cache');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Load favorites error: $e');
      }
    }
  }

  /// Save favorites to local storage
  Future<void> _saveLocalFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_favoritesKey, jsonEncode(_favoriteEventIds));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Save favorites error: $e');
      }
    }
  }
}
