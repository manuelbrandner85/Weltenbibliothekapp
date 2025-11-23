import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../services/favorites_service.dart';

/// ═══════════════════════════════════════════════════════════════
/// FAVORITES PROVIDER - State Management
/// ═══════════════════════════════════════════════════════════════
/// Manages favorites state and notifies UI of changes
/// ═══════════════════════════════════════════════════════════════

class FavoritesProvider extends ChangeNotifier {
  final FavoritesService _favoritesService = FavoritesService();
  bool _isInitialized = false;
  bool _isLoading = false;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;

  /// Initialize favorites
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _favoritesService.initialize();
      _isInitialized = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get all favorite event IDs
  List<String> get favoriteEventIds => _favoritesService.favoriteEventIds;

  /// Get favorite count
  int get favoriteCount => _favoritesService.favoriteCount;

  /// Check if event is favorited
  bool isFavorite(String eventId) => _favoritesService.isFavorite(eventId);

  /// Toggle favorite status
  Future<bool> toggleFavorite(EventModel event) async {
    final success = await _favoritesService.toggleFavorite(event);
    if (success) {
      notifyListeners();
    }
    return success;
  }

  /// Add to favorites
  Future<bool> addFavorite(EventModel event) async {
    final success = await _favoritesService.addFavorite(event);
    if (success) {
      notifyListeners();
    }
    return success;
  }

  /// Remove from favorites
  Future<bool> removeFavorite(String eventId) async {
    final success = await _favoritesService.removeFavorite(eventId);
    if (success) {
      notifyListeners();
    }
    return success;
  }

  /// Sync with server
  Future<void> syncFavorites() async {
    await _favoritesService.syncFavorites();
    notifyListeners();
  }

  /// Clear all favorites
  Future<void> clearAll() async {
    await _favoritesService.clearAllFavorites();
    notifyListeners();
  }
}
