import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 🗄️ Radio Cache Service - Schnelles Laden von Genres & Stationen
class RadioCacheService {
  static const String _cachePrefix = 'radio_cache_';
  static const Duration _cacheExpiration = Duration(hours: 24);

  /// Cache Station Liste für Genre
  static Future<void> cacheStations(
    String genre,
    List<Map<String, dynamic>> stations,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_cachePrefix$genre';
    
    final cacheData = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'stations': stations,
    };
    
    await prefs.setString(cacheKey, jsonEncode(cacheData));
  }

  /// Lade gecachte Stationen
  static Future<List<Map<String, dynamic>>?> getCachedStations(
    String genre,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_cachePrefix$genre';
    final cachedJson = prefs.getString(cacheKey);
    
    if (cachedJson == null) return null;
    
    try {
      final cacheData = jsonDecode(cachedJson);
      final timestamp = cacheData['timestamp'] as int;
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      
      // Cache abgelaufen?
      if (cacheAge > _cacheExpiration.inMilliseconds) {
        return null;
      }
      
      final stations = (cacheData['stations'] as List)
          .map((s) => Map<String, dynamic>.from(s))
          .toList();
      
      return stations;
    } catch (e) {
      return null;
    }
  }

  /// Lösche gesamten Cache
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    for (final key in keys) {
      if (key.startsWith(_cachePrefix)) {
        await prefs.remove(key);
      }
    }
  }
}
