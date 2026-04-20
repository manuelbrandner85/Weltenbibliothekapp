import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Zählt ungelesene Nachrichten pro Raum seit letztem Besuch.
///
/// - `lastSeen(roomId)` → ISO-Timestamp des letzten Öffnens des Raums.
/// - `markSeen(roomId)` → setzt Timestamp auf jetzt und nullt den Counter.
/// - `bump(roomId)` → +1 unread (wird von Realtime-Handler bei neuer
///   fremder Nachricht gerufen, wenn der Raum gerade NICHT offen ist).
/// - `counts()` → aktuelle unread-Counts pro Raum.
class UnreadTrackerService extends ChangeNotifier {
  UnreadTrackerService._();
  static final UnreadTrackerService instance = UnreadTrackerService._();

  static const _prefixUnread   = 'chat_unread_';
  static const _prefixLastSeen = 'chat_last_seen_';

  final Map<String, int>      _unread   = <String, int>{};
  final Map<String, DateTime> _lastSeen = <String, DateTime>{};
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_prefixUnread)) {
        final roomId = key.substring(_prefixUnread.length);
        final v = prefs.getInt(key);
        if (v != null) _unread[roomId] = v;
      } else if (key.startsWith(_prefixLastSeen)) {
        final roomId = key.substring(_prefixLastSeen.length);
        final v = prefs.getString(key);
        if (v != null) {
          final parsed = DateTime.tryParse(v);
          if (parsed != null) _lastSeen[roomId] = parsed;
        }
      }
    }
    _loaded = true;
  }

  Future<int> countFor(String roomId) async {
    await _ensureLoaded();
    return _unread[roomId] ?? 0;
  }

  int countForSync(String roomId) => _unread[roomId] ?? 0;

  Future<Map<String, int>> counts() async {
    await _ensureLoaded();
    return Map.unmodifiable(_unread);
  }

  Future<DateTime?> lastSeen(String roomId) async {
    await _ensureLoaded();
    return _lastSeen[roomId];
  }

  /// Raum als gelesen markieren: Counter → 0, lastSeen = jetzt.
  Future<void> markSeen(String roomId) async {
    await _ensureLoaded();
    _unread[roomId]   = 0;
    _lastSeen[roomId] = DateTime.now().toUtc();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefixUnread$roomId', 0);
    await prefs.setString('$_prefixLastSeen$roomId', _lastSeen[roomId]!.toIso8601String());
    notifyListeners();
  }

  /// Counter +1 für [roomId]. Fremde Nachricht eingetroffen, während Raum nicht aktiv.
  Future<void> bump(String roomId) async {
    await _ensureLoaded();
    _unread[roomId] = (_unread[roomId] ?? 0) + 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefixUnread$roomId', _unread[roomId]!);
    notifyListeners();
  }

  /// Direkt eine Anzahl setzen (z.B. beim initialen Sync).
  Future<void> setCount(String roomId, int count) async {
    await _ensureLoaded();
    _unread[roomId] = count < 0 ? 0 : count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefixUnread$roomId', _unread[roomId]!);
    notifyListeners();
  }
}
