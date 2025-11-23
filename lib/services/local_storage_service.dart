import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_model.dart';

/// Lokaler Speicher-Service mit Hive für Offline-Modus
class LocalStorageService {
  static const String eventsBoxName = 'events';
  static const String favoritesBoxName = 'favorites';
  static const String settingsBoxName = 'settings';

  late Box<Map<dynamic, dynamic>> _eventsBox;
  late Box<String> _favoritesBox;
  late SharedPreferences _prefs;

  /// Service initialisieren
  Future<void> initialize() async {
    // Hive initialisieren
    await Hive.initFlutter();

    // Boxes öffnen
    _eventsBox = await Hive.openBox<Map<dynamic, dynamic>>(eventsBoxName);
    _favoritesBox = await Hive.openBox<String>(favoritesBoxName);

    // SharedPreferences initialisieren
    _prefs = await SharedPreferences.getInstance();
  }

  // ==================== EVENT CACHING ====================

  /// Events im Cache speichern
  Future<void> cacheEvents(List<EventModel> events) async {
    for (final event in events) {
      await _eventsBox.put(event.id, event.toJson());
    }
  }

  /// Event im Cache speichern
  Future<void> cacheEvent(EventModel event) async {
    await _eventsBox.put(event.id, event.toJson());
  }

  /// Events aus Cache laden
  List<EventModel> getCachedEvents() {
    try {
      final events = <EventModel>[];
      for (final entry in _eventsBox.values) {
        try {
          final json = Map<String, dynamic>.from(entry);
          events.add(EventModel.fromJson(json));
        } catch (e) {
          debugPrint('Error parsing cached event: $e');
        }
      }
      return events;
    } catch (e) {
      debugPrint('Error loading cached events: $e');
      return [];
    }
  }

  /// Einzelnes Event aus Cache laden
  EventModel? getCachedEvent(String id) {
    try {
      final json = _eventsBox.get(id);
      if (json != null) {
        return EventModel.fromJson(Map<String, dynamic>.from(json));
      }
    } catch (e) {
      debugPrint('Error loading cached event $id: $e');
    }
    return null;
  }

  /// Cache leeren
  Future<void> clearEventCache() async {
    await _eventsBox.clear();
  }

  // ==================== FAVORITEN ====================

  /// Event zu Favoriten hinzufügen
  Future<void> addFavorite(String eventId) async {
    if (!_favoritesBox.containsKey(eventId)) {
      await _favoritesBox.put(eventId, eventId);
    }
  }

  /// Event aus Favoriten entfernen
  Future<void> removeFavorite(String eventId) async {
    await _favoritesBox.delete(eventId);
  }

  /// Prüfen ob Event favorisiert ist
  bool isFavorite(String eventId) {
    return _favoritesBox.containsKey(eventId);
  }

  /// Alle Favoriten-IDs laden
  List<String> getFavoriteIds() {
    return _favoritesBox.values.toList();
  }

  /// Alle favori Events laden
  List<EventModel> getFavoriteEvents() {
    final favoriteIds = getFavoriteIds();
    final events = <EventModel>[];

    for (final id in favoriteIds) {
      final event = getCachedEvent(id);
      if (event != null) {
        events.add(event);
      }
    }

    return events;
  }

  // ==================== EINSTELLUNGEN ====================

  /// Offline-Modus aktiviert?
  bool get offlineModeEnabled => _prefs.getBool('offline_mode') ?? false;

  Future<void> setOfflineMode(bool enabled) async {
    await _prefs.setBool('offline_mode', enabled);
  }

  /// Dunkles Theme aktiviert?
  bool get darkModeEnabled => _prefs.getBool('dark_mode') ?? false;

  Future<void> setDarkMode(bool enabled) async {
    await _prefs.setBool('dark_mode', enabled);
  }

  /// Standard-Kartenposition
  double? get lastMapLatitude => _prefs.getDouble('last_map_latitude');
  double? get lastMapLongitude => _prefs.getDouble('last_map_longitude');
  double? get lastMapZoom => _prefs.getDouble('last_map_zoom');

  Future<void> saveLastMapPosition({
    required double latitude,
    required double longitude,
    required double zoom,
  }) async {
    await _prefs.setDouble('last_map_latitude', latitude);
    await _prefs.setDouble('last_map_longitude', longitude);
    await _prefs.setDouble('last_map_zoom', zoom);
  }

  /// Letzte Synchronisierung
  DateTime? get lastSync {
    final timestamp = _prefs.getInt('last_sync');
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  Future<void> updateLastSync() async {
    await _prefs.setInt('last_sync', DateTime.now().millisecondsSinceEpoch);
  }

  /// Service schließen
  Future<void> dispose() async {
    await _eventsBox.close();
    await _favoritesBox.close();
  }
}
