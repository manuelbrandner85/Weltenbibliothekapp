import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

  static const _lastSeenBox = 'chat_last_seen';
  static const _unreadBox = 'chat_unread';

  final Map<String, int> _unread = <String, int>{};
  final Map<String, DateTime> _lastSeen = <String, DateTime>{};
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final seenBox = Hive.isBoxOpen(_lastSeenBox)
        ? Hive.box(_lastSeenBox)
        : await Hive.openBox(_lastSeenBox);
    final unreadBox = Hive.isBoxOpen(_unreadBox)
        ? Hive.box(_unreadBox)
        : await Hive.openBox(_unreadBox);
    for (final k in seenBox.keys) {
      final v = seenBox.get(k);
      if (v is String) {
        final parsed = DateTime.tryParse(v);
        if (parsed != null) _lastSeen[k.toString()] = parsed;
      }
    }
    for (final k in unreadBox.keys) {
      final v = unreadBox.get(k);
      if (v is int) _unread[k.toString()] = v;
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
    _unread[roomId] = 0;
    _lastSeen[roomId] = DateTime.now().toUtc();
    final seenBox = Hive.box(_lastSeenBox);
    final unreadBox = Hive.box(_unreadBox);
    await seenBox.put(roomId, _lastSeen[roomId]!.toIso8601String());
    await unreadBox.put(roomId, 0);
    notifyListeners();
  }

  /// Counter +1 für [roomId]. Fremde Nachricht eingetroffen, während Raum nicht aktiv.
  Future<void> bump(String roomId) async {
    await _ensureLoaded();
    _unread[roomId] = (_unread[roomId] ?? 0) + 1;
    final unreadBox = Hive.box(_unreadBox);
    await unreadBox.put(roomId, _unread[roomId]);
    notifyListeners();
  }

  /// Direkt eine Anzahl setzen (z.B. beim initialen Sync).
  Future<void> setCount(String roomId, int count) async {
    await _ensureLoaded();
    _unread[roomId] = count < 0 ? 0 : count;
    final unreadBox = Hive.box(_unreadBox);
    await unreadBox.put(roomId, _unread[roomId]);
    notifyListeners();
  }
}
