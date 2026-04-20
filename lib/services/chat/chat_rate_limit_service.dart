import 'package:flutter/foundation.dart';

/// Client-seitige Spam-Bremse fürs Senden im Chat.
///
/// Kombiniert:
/// - **Rate-Limit**: max. N Nachrichten pro rollendem Fenster (default 8/60s).
/// - **Slow-Mode**: pro Raum konfigurierter Mindest-Abstand zwischen
///   eigenen Nachrichten (default 0 = aus).
///
/// Das ist nur die Client-Seite. Der Server enforced zusätzlich via RLS /
/// Edge-Function — aber der Client gibt sofort Feedback, ohne Roundtrip.
class ChatRateLimitService extends ChangeNotifier {
  ChatRateLimitService._();
  static final ChatRateLimitService instance = ChatRateLimitService._();

  static const int _maxMessagesPerWindow = 8;
  static const Duration _window = Duration(seconds: 60);

  /// Timestamps aller eigenen Sends (global, nicht pro Raum).
  final List<DateTime> _recentSends = <DateTime>[];

  /// last-send pro Raum (für Slow-Mode).
  final Map<String, DateTime> _lastSendPerRoom = <String, DateTime>{};

  /// Slow-Mode-Sekunden pro Raum (0 = aus). Wird von Raum-Settings befüllt.
  final Map<String, int> _slowModePerRoom = <String, int>{};

  /// Slow-Mode für [roomId] setzen (z.B. aus Realtime-Update).
  void setSlowMode(String roomId, int seconds) {
    if (seconds <= 0) {
      _slowModePerRoom.remove(roomId);
    } else {
      _slowModePerRoom[roomId] = seconds;
    }
    notifyListeners();
  }

  int slowModeSeconds(String roomId) => _slowModePerRoom[roomId] ?? 0;

  /// Wie viele Sekunden muss User in [roomId] noch warten?
  /// Gibt 0 zurück, wenn er senden darf.
  int secondsUntilCanSend(String roomId) {
    _pruneRecent();
    final now = DateTime.now();

    // Rate-Limit
    if (_recentSends.length >= _maxMessagesPerWindow) {
      final oldest = _recentSends.first;
      final wait = _window.inSeconds - now.difference(oldest).inSeconds;
      if (wait > 0) return wait;
    }

    // Slow-Mode pro Raum
    final slow = _slowModePerRoom[roomId] ?? 0;
    if (slow > 0) {
      final last = _lastSendPerRoom[roomId];
      if (last != null) {
        final passed = now.difference(last).inSeconds;
        if (passed < slow) return slow - passed;
      }
    }

    return 0;
  }

  bool canSend(String roomId) => secondsUntilCanSend(roomId) == 0;

  /// Muss direkt VOR dem eigentlichen Send-Request aufgerufen werden
  /// (egal ob der erfolgreich ist — sonst umgeht der User durch
  /// Fehlversuche das Limit nicht).
  void recordSend(String roomId) {
    final now = DateTime.now();
    _recentSends.add(now);
    _lastSendPerRoom[roomId] = now;
    _pruneRecent();
    notifyListeners();
  }

  /// Formatiert die Wartezeit als lesbare deutsche Meldung.
  String cooldownMessage(String roomId) {
    final secs = secondsUntilCanSend(roomId);
    if (secs <= 0) return '';
    final slow = _slowModePerRoom[roomId] ?? 0;
    final reason = (slow > 0 &&
            _lastSendPerRoom[roomId] != null &&
            DateTime.now().difference(_lastSendPerRoom[roomId]!).inSeconds <
                slow)
        ? 'Slow-Mode'
        : 'Zu schnell';
    if (secs >= 60) {
      final m = (secs / 60).ceil();
      return '$reason – noch $m Min. warten';
    }
    return '$reason – noch $secs Sek. warten';
  }

  void _pruneRecent() {
    final cutoff = DateTime.now().subtract(_window);
    _recentSends.removeWhere((t) => t.isBefore(cutoff));
  }

  /// Für Logout / Account-Wechsel.
  void clearAll() {
    _recentSends.clear();
    _lastSendPerRoom.clear();
    _slowModePerRoom.clear();
    notifyListeners();
  }
}
