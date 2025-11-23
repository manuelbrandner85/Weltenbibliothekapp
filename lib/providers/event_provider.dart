import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../services/cloudflare_service.dart';
import '../services/local_storage_service.dart';

/// Event Provider für State Management
class EventProvider extends ChangeNotifier {
  final CloudflareService _cloudflareService = CloudflareService();
  final LocalStorageService _localStorage;

  List<EventModel> _events = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedCategory;

  EventProvider({required LocalStorageService localStorage})
    : _localStorage = localStorage {
    _initializeEvents();
  }

  // Getters
  List<EventModel> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedCategory => _selectedCategory;
  bool get offlineModeEnabled => _localStorage.offlineModeEnabled;

  /// Events initial laden
  Future<void> _initializeEvents() async {
    // Zuerst gecachte Events laden
    _events = _localStorage.getCachedEvents();
    notifyListeners();

    // Dann von API aktualisieren (wenn nicht im Offline-Modus)
    if (!_localStorage.offlineModeEnabled) {
      await refreshEvents();
    }
  }

  /// Events von API neu laden
  Future<void> refreshEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final events = await _cloudflareService.getEvents(
        category: _selectedCategory,
      );

      _events = events;

      // Events im Cache speichern
      await _localStorage.cacheEvents(events);
      await _localStorage.updateLastSync();

      _error = null;
    } catch (e) {
      _error = 'Fehler beim Laden der Events: $e';
      // Bei Fehler gecachte Events verwenden
      _events = _localStorage.getCachedEvents();
      if (kDebugMode) {
        debugPrint('Error refreshing events: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Events nach Kategorie filtern
  void filterByCategory(String? category) {
    _selectedCategory = category;
    if (!_localStorage.offlineModeEnabled) {
      refreshEvents();
    } else {
      // Im Offline-Modus lokal filtern
      final cachedEvents = _localStorage.getCachedEvents();
      if (category != null) {
        _events = cachedEvents.where((e) => e.category == category).toList();
      } else {
        _events = cachedEvents;
      }
      notifyListeners();
    }
  }

  /// Events nach Text durchsuchen
  List<EventModel> searchEvents(String query) {
    if (query.isEmpty) return _events;

    final lowerQuery = query.toLowerCase();
    return _events.where((event) {
      return event.title.toLowerCase().contains(lowerQuery) ||
          event.description.toLowerCase().contains(lowerQuery) ||
          event.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// Event zu Favoriten hinzufügen/entfernen
  Future<void> toggleFavorite(String eventId) async {
    if (_localStorage.isFavorite(eventId)) {
      await _localStorage.removeFavorite(eventId);
    } else {
      await _localStorage.addFavorite(eventId);
    }
    notifyListeners();
  }

  /// Prüfen ob Event favorisiert ist
  bool isFavorite(String eventId) {
    return _localStorage.isFavorite(eventId);
  }

  /// Alle Favoriten-Events laden
  List<EventModel> getFavoriteEvents() {
    return _localStorage.getFavoriteEvents();
  }

  /// Offline-Modus umschalten
  Future<void> toggleOfflineMode() async {
    final newValue = !_localStorage.offlineModeEnabled;
    await _localStorage.setOfflineMode(newValue);

    if (!newValue) {
      // Beim Deaktivieren des Offline-Modus aktualisieren
      await refreshEvents();
    } else {
      // Im Offline-Modus gecachte Events laden
      _events = _localStorage.getCachedEvents();
      notifyListeners();
    }
  }

  /// Dunkles Theme umschalten
  Future<void> toggleDarkMode() async {
    final newValue = !_localStorage.darkModeEnabled;
    await _localStorage.setDarkMode(newValue);
    notifyListeners();
  }

  /// Letzte Synchronisierung abrufen
  DateTime? get lastSync => _localStorage.lastSync;

  @override
  void dispose() {
    _cloudflareService.dispose();
    super.dispose();
  }
}
