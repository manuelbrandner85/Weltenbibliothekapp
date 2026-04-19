import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Lokale Liste geblockter User (in Hive, gerätebasiert).
///
/// Geblockte User werden in den Chat-Screens ausgefiltert, ihre
/// Nachrichten tauchen nicht mehr auf. Kein Server-Roundtrip – reine
/// Client-seitige Preference.
class UserBlockService extends ChangeNotifier {
  UserBlockService._();
  static final UserBlockService instance = UserBlockService._();

  static const _boxName = 'chat_blocked_users';
  static const _key = 'blocked';

  Set<String> _blocked = <String>{};
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final box = Hive.isBoxOpen(_boxName)
        ? Hive.box(_boxName)
        : await Hive.openBox(_boxName);
    final raw = box.get(_key);
    if (raw is List) {
      _blocked = raw.whereType<String>().toSet();
    }
    _loaded = true;
  }

  Future<Set<String>> all() async {
    await _ensureLoaded();
    return Set.unmodifiable(_blocked);
  }

  bool isBlockedSync(String? usernameOrId) {
    if (usernameOrId == null || usernameOrId.isEmpty) return false;
    return _blocked.contains(usernameOrId.toLowerCase());
  }

  Future<bool> isBlocked(String? usernameOrId) async {
    await _ensureLoaded();
    return isBlockedSync(usernameOrId);
  }

  Future<void> block(String usernameOrId) async {
    if (usernameOrId.trim().isEmpty) return;
    await _ensureLoaded();
    _blocked.add(usernameOrId.toLowerCase());
    await _persist();
    notifyListeners();
  }

  Future<void> unblock(String usernameOrId) async {
    await _ensureLoaded();
    if (_blocked.remove(usernameOrId.toLowerCase())) {
      await _persist();
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    final box = Hive.isBoxOpen(_boxName)
        ? Hive.box(_boxName)
        : await Hive.openBox(_boxName);
    await box.put(_key, _blocked.toList());
  }

  /// Filter-Helper: gibt nur Nachrichten zurück, deren username/user_id
  /// NICHT blockiert ist.
  Iterable<Map<String, dynamic>> filterMessages(
      Iterable<Map<String, dynamic>> messages) {
    if (_blocked.isEmpty) return messages;
    return messages.where((m) {
      final u = (m['username'] as String?)?.toLowerCase() ?? '';
      final id = (m['user_id'] as String?)?.toLowerCase() ?? '';
      return !_blocked.contains(u) && !_blocked.contains(id);
    });
  }
}
