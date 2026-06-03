// RestrictionGuard: zentraler Cache fuer die aktiven Bereichs-Sperren des
// aktuell eingeloggten Users (user_restrictions). Der Admin setzt Sperren
// ueber das Dashboard (Scope z.B. 'spirit_tools', 'research_tools', 'all');
// Screens fragen hier ab, ob ein Bereich gesperrt ist und blenden ihn aus.
//
// Hintergrund: Server-Endpoints (Chat-POST etc.) pruefen Restrictions bereits
// serverseitig. Reine Client-Tools (Spirit-Rechner, Recherche) haben keinen
// Server-Roundtrip, deshalb wird die Sperre hier client-seitig erzwungen.

import 'package:flutter/foundation.dart';

import 'account_service.dart';
import 'unified_profile_service.dart';

class RestrictionGuard {
  RestrictionGuard._();
  static final RestrictionGuard instance = RestrictionGuard._();

  final _account = AccountService.instance;

  Set<String> _scopes = <String>{};
  bool _loaded = false;
  Future<void>? _inflight;

  /// Aktive Scopes (z.B. {'spirit_tools'}). Leer bis [ensureLoaded].
  Set<String> get scopes => _scopes;

  /// true wenn der Bereich gesperrt ist. 'all' (Vollsperre) sperrt jeden Bereich.
  bool isRestricted(String scope) =>
      _scopes.contains('all') || _scopes.contains(scope);

  /// Laedt die Scopes einmalig (oder erzwungen via [force]). Mehrfachaufrufe
  /// teilen sich denselben In-Flight-Request.
  Future<void> ensureLoaded({bool force = false}) {
    if (_loaded && !force) return Future<void>.value();
    return _inflight ??= _load().whenComplete(() => _inflight = null);
  }

  Future<void> _load() async {
    final p = UnifiedProfileService.instance;
    final userId = p.userId;
    final username = p.username;
    if ((userId == null || userId.isEmpty) &&
        (username == null || username.isEmpty)) {
      _scopes = <String>{};
      _loaded = true;
      return;
    }
    try {
      final data = await _account.getMyRestrictions(
        userId: userId,
        username: username,
      );
      final raw = (data['scopes'] as List?) ?? const [];
      _scopes = raw.map((e) => e.toString()).toSet();
      _loaded = true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ RestrictionGuard._load: $e');
      // Im Fehlerfall NICHT sperren (fail-open: Server bleibt letzte Instanz).
      _scopes = <String>{};
      _loaded = true;
    }
  }

  /// Nach Login/Logout/Profil-Wechsel aufrufen.
  void reset() {
    _scopes = <String>{};
    _loaded = false;
  }
}
