import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

/// A3: Trackt, welche freigeschalteten Module/Tools der Nutzer bereits
/// "gesehen" hat, sodass neu freigeschaltete Inhalte kurzzeitig mit einem
/// "NEU"-Badge markiert werden koennen.
///
/// Pro Welt/Namespace wird ein Set bereits gesehener IDs in SharedPreferences
/// persistiert. Eine ID gilt als "neu", solange sie noch nicht im Set ist.
class NewUnlockTracker {
  NewUnlockTracker._();
  static final NewUnlockTracker instance = NewUnlockTracker._();

  static String _key(String namespace) => 'new_unlock_seen_$namespace';

  final Map<String, Set<String>> _cache = {};

  /// Laedt das Set gesehener IDs fuer einen Namespace (z.B. 'vorhang').
  Future<Set<String>> _seen(String namespace) async {
    if (_cache.containsKey(namespace)) return _cache[namespace]!;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_key(namespace)) ?? const [];
      final set = list.toSet();
      _cache[namespace] = set;
      return set;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ NewUnlockTracker._seen: $e');
      return _cache[namespace] = <String>{};
    }
  }

  /// True, wenn die ID in diesem Namespace noch nicht als gesehen markiert ist.
  Future<bool> isNew(String namespace, String id) async {
    final seen = await _seen(namespace);
    return !seen.contains(id);
  }

  /// Markiert die uebergebenen IDs als gesehen (persistiert).
  Future<void> markSeen(String namespace, Iterable<String> ids) async {
    final seen = await _seen(namespace);
    final before = seen.length;
    seen.addAll(ids);
    if (seen.length == before) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key(namespace), seen.toList());
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ NewUnlockTracker.markSeen: $e');
    }
  }
}
