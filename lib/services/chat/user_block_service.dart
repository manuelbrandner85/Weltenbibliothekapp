import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lokale Liste geblockter User (SharedPreferences, gerätebasiert).
///
/// Geblockte User werden in den Chat-Screens ausgefiltert, ihre
/// Nachrichten tauchen nicht mehr auf. Kein Server-Roundtrip – reine
/// Client-seitige Preference.
class UserBlockService extends ChangeNotifier {
  UserBlockService._();
  static final UserBlockService instance = UserBlockService._();

  static const _key = 'chat_blocked_users';

  Set<String> _blocked = <String>{};
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key);
    if (list != null) _blocked = list.toSet();
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _blocked.toList());
  }

  /// Filter-Helper: gibt nur Nachrichten zurück, deren username/user_id
  /// NICHT blockiert ist.
  Iterable<Map<String, dynamic>> filterMessages(
      Iterable<Map<String, dynamic>> messages) {
    if (_blocked.isEmpty) return messages;
    return messages.where((m) {
      final u  = (m['username'] as String?)?.toLowerCase() ?? '';
      final id = (m['user_id']  as String?)?.toLowerCase() ?? '';
      return !_blocked.contains(u) && !_blocked.contains(id);
    });
  }
}
