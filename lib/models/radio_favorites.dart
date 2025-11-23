import 'package:shared_preferences/shared_preferences.dart';

/// 🌟 Radio Favoriten & History Manager
class RadioFavorites {
  static const String _favoritesKey = 'radio_favorite_genres';
  static const String _historyKey = 'radio_genre_history';
  static const String _lastPlayedKey = 'radio_last_played';

  /// Speichere Favoriten-Genre
  static Future<void> toggleFavorite(String genre) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_favoritesKey) ?? [];
    
    if (favorites.contains(genre)) {
      favorites.remove(genre);
    } else {
      favorites.add(genre);
    }
    
    await prefs.setStringList(_favoritesKey, favorites);
  }

  /// Hole alle Favoriten
  static Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey) ?? [];
  }

  /// Prüfe ob Genre Favorit ist
  static Future<bool> isFavorite(String genre) async {
    final favorites = await getFavorites();
    return favorites.contains(genre);
  }

  /// Speichere Genre in History
  static Future<void> addToHistory(String genre) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_historyKey) ?? [];
    
    // Entferne Duplikate
    history.remove(genre);
    
    // Füge am Anfang hinzu
    history.insert(0, genre);
    
    // Begrenze auf 10 Einträge
    if (history.length > 10) {
      history.removeLast();
    }
    
    await prefs.setStringList(_historyKey, history);
  }

  /// Hole History
  static Future<List<String>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_historyKey) ?? [];
  }

  /// Speichere zuletzt gespieltes Genre + Station
  static Future<void> saveLastPlayed(String genre, String station) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPlayedKey, '$genre|$station');
  }

  /// Hole zuletzt gespieltes Genre + Station
  static Future<Map<String, String>?> getLastPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPlayed = prefs.getString(_lastPlayedKey);
    
    if (lastPlayed == null) return null;
    
    final parts = lastPlayed.split('|');
    if (parts.length != 2) return null;
    
    return {'genre': parts[0], 'station': parts[1]};
  }
}
