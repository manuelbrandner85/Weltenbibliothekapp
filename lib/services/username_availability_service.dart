/// 🆔 USERNAME-AVAILABILITY-SERVICE
///
/// Prüft Benutzernamen-Eindeutigkeit gegen die Supabase `profiles`-Tabelle.
/// Username ist case-insensitive eindeutig (UNIQUE INDEX auf `username`).
///
/// Verwendung:
///   final svc = UsernameAvailabilityService.instance;
///   final result = await svc.check('Manuel');
///   switch (result.status) {
///     case UsernameStatus.available: ...
///     case UsernameStatus.taken: ...
///     case UsernameStatus.invalidFormat: ...
///     case UsernameStatus.checkFailed: ...
///   }
///
/// Validierungs-Regeln (lokal, ohne Server):
///   - mindestens 3 Zeichen, max 20
///   - nur Buchstaben, Ziffern, Unterstrich, Bindestrich, Punkt
///   - keine führenden/abschließenden Sonderzeichen
library;

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

enum UsernameStatus {
  /// Username ist frei — kann verwendet werden.
  available,

  /// Username ist bereits vergeben.
  taken,

  /// Username verletzt Regeln (Länge, Zeichen).
  invalidFormat,

  /// Server nicht erreichbar — Caller darf trotzdem speichern aber
  /// muss bei Insert mit Conflict-Error rechnen.
  checkFailed,
}

class UsernameCheckResult {
  final UsernameStatus status;

  /// User-friendly Message (deutsch). Auch bei `available` gesetzt
  /// für positive Bestätigung.
  final String message;

  /// Vorschläge wenn `taken` — z.B. ["manuel1", "manuel_x"]
  final List<String> suggestions;

  const UsernameCheckResult({
    required this.status,
    required this.message,
    this.suggestions = const [],
  });

  bool get isAvailable => status == UsernameStatus.available;
}

class UsernameAvailabilityService {
  UsernameAvailabilityService._();
  static final instance = UsernameAvailabilityService._();

  /// Cache für Performance — gleicher Username innerhalb 30s nicht erneut
  /// gegen Supabase prüfen (z.B. bei Live-Check während Typing).
  final Map<String, _CachedResult> _cache = {};
  static const _cacheTtl = Duration(seconds: 30);

  /// Validiert Format LOKAL (ohne Netzwerk-Aufruf).
  bool _hasValidFormat(String name) {
    if (name.length < 3 || name.length > 20) return false;
    // Erlaubte Zeichen: a-z A-Z 0-9 _ - .
    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(name)) return false;
    // Darf nicht mit Sonderzeichen anfangen oder enden
    if (RegExp(r'^[._-]').hasMatch(name)) return false;
    if (RegExp(r'[._-]$').hasMatch(name)) return false;
    return true;
  }

  /// Prüft Verfügbarkeit gegen Supabase. Kombiniert lokales Format-Check +
  /// Server-Lookup in `profiles`-Tabelle (case-insensitive).
  Future<UsernameCheckResult> check(String rawUsername) async {
    final username = rawUsername.trim();

    // 1. Lokal: Format-Check
    if (username.isEmpty) {
      return const UsernameCheckResult(
        status: UsernameStatus.invalidFormat,
        message: 'Bitte einen Benutzernamen eingeben.',
      );
    }
    if (!_hasValidFormat(username)) {
      return const UsernameCheckResult(
        status: UsernameStatus.invalidFormat,
        message: '3–20 Zeichen, nur Buchstaben, Ziffern, '
            'Punkt, Bindestrich oder Unterstrich.',
      );
    }

    // 2. Cache-Lookup (case-insensitive)
    final cacheKey = username.toLowerCase();
    final cached = _cache[cacheKey];
    if (cached != null && DateTime.now().difference(cached.at) < _cacheTtl) {
      return cached.result;
    }

    // 3. Supabase-Query
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('username')
          .ilike('username', username)
          .limit(1)
          .timeout(const Duration(seconds: 5));

      final taken = response.isNotEmpty;
      final result = taken
          ? UsernameCheckResult(
              status: UsernameStatus.taken,
              message: '"$username" ist bereits vergeben.',
              suggestions: _generateSuggestions(username),
            )
          : UsernameCheckResult(
              status: UsernameStatus.available,
              message: '"$username" ist frei.',
            );
      _cache[cacheKey] = _CachedResult(result, DateTime.now());
      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ UsernameAvailability: check failed — $e');
      }
      return const UsernameCheckResult(
        status: UsernameStatus.checkFailed,
        message: 'Konnte nicht prüfen — bitte später nochmal versuchen.',
      );
    }
  }

  /// Generiert 3 Vorschläge basierend auf dem gewünschten Namen.
  List<String> _generateSuggestions(String base) {
    final clean = base.replaceAll(RegExp(r'[._-]+$'), '');
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    final shortTs = ts.substring(ts.length - 4);
    return <String>[
      '${clean}1',
      '${clean}_neu',
      '${clean}_$shortTs',
    ].where((s) => s.length >= 3 && s.length <= 20).toList();
  }

  /// Invalidiert den Cache — z.B. nach erfolgreichem Profil-Save.
  void invalidate(String username) {
    _cache.remove(username.toLowerCase());
  }
}

class _CachedResult {
  final UsernameCheckResult result;
  final DateTime at;
  _CachedResult(this.result, this.at);
}
