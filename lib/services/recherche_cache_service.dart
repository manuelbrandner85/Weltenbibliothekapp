/// WELTENBIBLIOTHEK v5.18 – RECHERCHE-CACHE-SERVICE
library;
import 'package:flutter/foundation.dart';
/// 
/// Caching-System für alle Recherche-Modi:
/// - Standard-Recherche
/// - Kaninchenbau (6 Ebenen)
/// - Internationale Perspektiven
/// 
/// Vorteile:
/// - Schnellere Wiederholungs-Anfragen
/// - Offline-Verfügbarkeit
/// - Reduzierte API-Calls
/// - Bessere User Experience

import 'package:hive_flutter/hive_flutter.dart';

/// Cache-Eintrag für Recherche-Ergebnisse
class RechercheCacheEntry {
  final String query;
  final String mode; // 'standard', 'rabbitHole', 'international'
  final Map<String, dynamic> result;
  final DateTime timestamp;
  final int ttlSeconds; // Time To Live in Sekunden
  
  RechercheCacheEntry({
    required this.query,
    required this.mode,
    required this.result,
    required this.timestamp,
    this.ttlSeconds = 3600, // Default: 1 Stunde
  });
  
  /// Prüft ob Cache-Eintrag noch gültig ist
  bool get isValid {
    final age = DateTime.now().difference(timestamp).inSeconds;
    return age < ttlSeconds;
  }
  
  /// Konvertiert zu Map für Hive-Speicherung
  Map<String, dynamic> toMap() {
    return {
      'query': query,
      'mode': mode,
      'result': result,
      'timestamp': timestamp.toIso8601String(),
      'ttlSeconds': ttlSeconds,
    };
  }
  
  /// Erstellt Eintrag aus Map
  factory RechercheCacheEntry.fromMap(Map<String, dynamic> map) {
    return RechercheCacheEntry(
      query: map['query'] as String,
      mode: map['mode'] as String,
      result: Map<String, dynamic>.from(map['result'] as Map),
      timestamp: DateTime.parse(map['timestamp'] as String),
      ttlSeconds: map['ttlSeconds'] as int? ?? 3600,
    );
  }
}

/// Recherche-Cache-Service
class RechercheCacheService {
  static const String _boxName = 'recherche_cache';
  static const int _maxCacheSize = 100; // Maximal 100 Einträge
  static const int _defaultTTL = 3600; // 1 Stunde
  
  Box<Map>? _cacheBox;
  
  /// Initialisiert Hive und öffnet Cache-Box
  Future<void> init() async {
    try {
      // Hive initialisieren (sollte in main.dart bereits gemacht sein)
      // await Hive.initFlutter();
      
      // Cache-Box öffnen
      _cacheBox = await Hive.openBox<Map>(_boxName);
      
      // Alte Einträge aufräumen
      await _cleanupExpiredEntries();
    } catch (e) {
      debugPrint('Cache-Init-Fehler: $e');
    }
  }
  
  /// Prüft ob Ergebnis im Cache existiert
  /// 
  /// Verwendung:
  /// ```dart
  /// if (await cache.isCached(query, mode)) {
  ///   return await cache.get(query, mode);
  /// }
  /// ```
  Future<bool> isCached(String query, String mode) async {
    if (_cacheBox == null) return false;
    
    final key = _buildKey(query, mode);
    
    if (!_cacheBox!.containsKey(key)) {
      return false;
    }
    
    try {
      final map = _cacheBox!.get(key);
      if (map == null) return false;
      
      final entry = RechercheCacheEntry.fromMap(
        Map<String, dynamic>.from(map),
      );
      
      // Prüfe ob noch gültig
      if (!entry.isValid) {
        await _cacheBox!.delete(key);
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('Cache-Check-Fehler: $e');
      return false;
    }
  }
  
  /// Holt Ergebnis aus Cache
  Future<Map<String, dynamic>?> get(String query, String mode) async {
    if (_cacheBox == null) return null;
    
    final key = _buildKey(query, mode);
    
    try {
      final map = _cacheBox!.get(key);
      if (map == null) return null;
      
      final entry = RechercheCacheEntry.fromMap(
        Map<String, dynamic>.from(map),
      );
      
      // Prüfe ob noch gültig
      if (!entry.isValid) {
        await _cacheBox!.delete(key);
        return null;
      }
      
      return entry.result;
    } catch (e) {
      debugPrint('Cache-Get-Fehler: $e');
      return null;
    }
  }
  
  /// Speichert Ergebnis im Cache
  Future<void> put(
    String query,
    String mode,
    Map<String, dynamic> result, {
    int? ttlSeconds,
  }) async {
    if (_cacheBox == null) return;
    
    // Cache-Größe limitieren
    if (_cacheBox!.length >= _maxCacheSize) {
      await _removeOldestEntry();
    }
    
    final key = _buildKey(query, mode);
    final entry = RechercheCacheEntry(
      query: query,
      mode: mode,
      result: result,
      timestamp: DateTime.now(),
      ttlSeconds: ttlSeconds ?? _defaultTTL,
    );
    
    try {
      await _cacheBox!.put(key, entry.toMap());
    } catch (e) {
      debugPrint('Cache-Put-Fehler: $e');
    }
  }
  
  /// Löscht spezifischen Cache-Eintrag
  Future<void> delete(String query, String mode) async {
    if (_cacheBox == null) return;
    
    final key = _buildKey(query, mode);
    await _cacheBox!.delete(key);
  }
  
  /// Löscht alle Cache-Einträge
  Future<void> clear() async {
    if (_cacheBox == null) return;
    await _cacheBox!.clear();
  }
  
  /// Gibt Cache-Statistiken zurück
  Future<Map<String, dynamic>> getStats() async {
    if (_cacheBox == null) {
      return {
        'totalEntries': 0,
        'validEntries': 0,
        'expiredEntries': 0,
      };
    }
    
    int validCount = 0;
    int expiredCount = 0;
    
    for (final map in _cacheBox!.values) {
      try {
        final entry = RechercheCacheEntry.fromMap(
          Map<String, dynamic>.from(map),
        );
        if (entry.isValid) {
          validCount++;
        } else {
          expiredCount++;
        }
      } catch (e) {
        expiredCount++;
      }
    }
    
    return {
      'totalEntries': _cacheBox!.length,
      'validEntries': validCount,
      'expiredEntries': expiredCount,
      'maxSize': _maxCacheSize,
      'defaultTTL': _defaultTTL,
    };
  }
  
  /// Baut Cache-Key aus Query und Modus
  String _buildKey(String query, String mode) {
    // Normalisiere Query (lowercase, trim)
    final normalizedQuery = query.trim().toLowerCase();
    return '$mode:$normalizedQuery';
  }
  
  /// Entfernt abgelaufene Einträge
  Future<void> _cleanupExpiredEntries() async {
    if (_cacheBox == null) return;
    
    final keysToDelete = <String>[];
    
    for (final key in _cacheBox!.keys) {
      try {
        final map = _cacheBox!.get(key);
        if (map == null) {
          keysToDelete.add(key as String);
          continue;
        }
        
        final entry = RechercheCacheEntry.fromMap(
          Map<String, dynamic>.from(map),
        );
        
        if (!entry.isValid) {
          keysToDelete.add(key as String);
        }
      } catch (e) {
        keysToDelete.add(key as String);
      }
    }
    
    for (final key in keysToDelete) {
      await _cacheBox!.delete(key);
    }
  }
  
  /// Entfernt ältesten Eintrag (LRU-Strategie)
  Future<void> _removeOldestEntry() async {
    if (_cacheBox == null || _cacheBox!.isEmpty) return;
    
    DateTime? oldestTime;
    String? oldestKey;
    
    for (final key in _cacheBox!.keys) {
      try {
        final map = _cacheBox!.get(key);
        if (map == null) continue;
        
        final entry = RechercheCacheEntry.fromMap(
          Map<String, dynamic>.from(map),
        );
        
        if (oldestTime == null || entry.timestamp.isBefore(oldestTime)) {
          oldestTime = entry.timestamp;
          oldestKey = key as String;
        }
      } catch (e) {
        continue;
      }
    }
    
    if (oldestKey != null) {
      await _cacheBox!.delete(oldestKey);
    }
  }
  
  /// Schließt Cache-Box
  Future<void> close() async {
    await _cacheBox?.close();
  }
}
