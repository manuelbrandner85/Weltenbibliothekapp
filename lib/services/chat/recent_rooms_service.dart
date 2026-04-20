import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Speichert pro Welt die zuletzt besuchten Chat-Räume (Most-Recently-Used).
///
/// Persistiert über SharedPreferences, damit die Liste auch nach App-Neustart
/// verfügbar ist. Liste ist sortiert vom neuesten zum ältesten Besuch und
/// begrenzt auf [_maxEntries] Einträge pro Welt.
class RecentRoomsService extends ChangeNotifier {
  RecentRoomsService._();
  static final RecentRoomsService instance = RecentRoomsService._();

  static const int _maxEntries = 5;
  static const String _keyPrefix = 'recent_rooms_';

  final Map<String, List<String>> _cache = <String, List<String>>{};
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    for (final world in const ['energie', 'materie']) {
      final list = prefs.getStringList('$_keyPrefix$world') ?? const <String>[];
      _cache[world] = List<String>.from(list);
    }
    _loaded = true;
  }

  /// Gibt die MRU-Liste für die Welt zurück (neueste zuerst).
  Future<List<String>> get(String world) async {
    await _ensureLoaded();
    return List.unmodifiable(_cache[world] ?? const <String>[]);
  }

  /// Synchroner Zugriff ohne Persistenz-Load — nur wenn vorher [get] aufgerufen.
  List<String> getCached(String world) =>
      List.unmodifiable(_cache[world] ?? const <String>[]);

  /// Markiert einen Raum-Besuch: schiebt ihn an Position 0 und deduped.
  Future<void> touch(String world, String roomId) async {
    if (roomId.isEmpty) return;
    await _ensureLoaded();
    final list = _cache[world] ?? <String>[];
    list.remove(roomId);
    list.insert(0, roomId);
    if (list.length > _maxEntries) {
      list.removeRange(_maxEntries, list.length);
    }
    _cache[world] = list;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('$_keyPrefix$world', list);
    notifyListeners();
  }
}
