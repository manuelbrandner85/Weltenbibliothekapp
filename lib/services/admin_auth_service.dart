// AdminAuthService -- liefert die X-Admin-Username + X-Admin-Token
// Header die der Worker (api-worker.js verifyAdminCaller) erwartet.
//
// AUDIT-FIX A1: Vorher hat die App body.admin als Klartext-Username
// an /api/admin/* gesendet. Jeder mit Worker-URL konnte das faken.
// Jetzt: HMAC-SHA256(username, ADMIN_AUTH_SECRET) als Token. Das Secret
// kommt via --dart-define=ADMIN_AUTH_SECRET=... zur Build-Zeit rein,
// liegt im obfuscated AOT-Code und ist nicht trivial extrahierbar.
//
// Wichtig: Auch wenn ein Angreifer das Secret aus der APK extrahiert,
// hat er nur Token-Generation-Faehigkeit -- der Worker prueft live
// gegen profiles.role. Sobald die Rolle in der DB downgegradet wird,
// laeuft der Token ins Leere.
//
// Verwendung in HTTP-Calls:
//   final headers = await AdminAuthService.instance.headers();
//   http.post(uri, headers: {...standardHeaders, ...headers}, body: ...);

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

import '../core/auth/admin_resolver.dart';
import '../core/constants/roles.dart';
import 'storage_service.dart';

class AdminAuthService {
  AdminAuthService._();
  static final AdminAuthService instance = AdminAuthService._();

  /// Build-Time-Secret. Muss mit Wrangler-Secret ADMIN_AUTH_SECRET
  /// uebereinstimmen. Bei fehlendem Secret werden Admin-Calls vom Worker
  /// abgelehnt -- niemals fail-open.
  static const String _secret = String.fromEnvironment(
    'ADMIN_AUTH_SECRET',
    defaultValue: '',
  );

  /// Liefert die HTTP-Header die ein Admin-Worker-Call mitschicken muss.
  /// Gibt leeres Map zurueck wenn der aktuelle User kein Admin ist --
  /// dann wird der Worker den Request mit 403 ablehnen, was korrekt ist.
  Future<Map<String, String>> headers() async {
    try {
      final role = await AdminResolver.resolveCurrentRole();
      if (!_isAdminRole(role)) return const {};

      final username = _currentUsername();
      if (username == null || username.isEmpty) return const {};
      if (_secret.isEmpty) {
        if (kDebugMode) {
          debugPrint(
              '[AdminAuthService] WARN: ADMIN_AUTH_SECRET nicht im Build -- Worker wird Admin-Calls ablehnen');
        }
        return const {};
      }

      final token = _hmacHex(_secret, username.toLowerCase());
      if (kDebugMode) {
        debugPrint(
            '[AdminAuthService] sending X-Admin-Username="$username" '
            '(role=$role) -- HMAC computed');
      }
      return {
        'X-Admin-Username': username,
        'X-Admin-Token': token,
      };
    } catch (e) {
      if (kDebugMode) debugPrint('[AdminAuthService] headers error: $e');
      return const {};
    }
  }

  bool _isAdminRole(String role) =>
      role == 'root_admin' ||
      role == 'root-admin' ||
      role == 'admin' ||
      role == 'moderator' ||
      role == 'content_editor';

  /// Liefert den Username der zum Supabase-profiles-Eintrag passt -- NICHT
  /// die InvisibleAuth-ID.
  ///
  /// Bug-Fix Identity-Chain: vorher liess die Methode einfach
  /// getMaterieProfile().username durchschlagen. Wenn dort die Auth-ID
  /// ('user_<ts>_<rand>') stand statt der echten Username (z.B.
  /// 'Weltenbibliothek'), schickte der Client das an den Worker, der
  /// `profiles WHERE username='user_<ts>_<rand>'` queryt -> 0 rows ->
  /// 403. Jetzt: zuerst nach Admin-Username-Konstanten (Weltenbibliothek,
  /// Weltenbibliothekedit) in ALLEN Profil-Feldern suchen -- wenn match,
  /// nimm den. Sonst der erste nicht-leere wirklich Profil-username,
  /// der NICHT mit 'user_' anfaengt (InvisibleAuth-IDs aussortieren).
  String? _currentUsername() {
    try {
      final storage = StorageService();
      final candidates = <String>[
        storage.getMaterieProfile()?.username ?? '',
        storage.getEnergieProfile()?.username ?? '',
      ].where((u) => u.trim().isNotEmpty).toList();

      // Prio 1: bekannte Admin-Usernames (case-insensitive, .trim() inside)
      for (final u in candidates) {
        if (AppRoles.isRootAdminByUsername(u)) {
          return AppRoles.rootAdminUsername;
        }
        if (AppRoles.isContentEditorByUsername(u)) {
          return AppRoles.contentEditorUsername;
        }
      }

      // Prio 2: erster non-InvisibleAuth-Username
      for (final u in candidates) {
        if (!u.startsWith('user_')) return u;
      }

      // Prio 3 (Fallback): erster non-empty -- gibt dem Worker zumindest
      // eine Chance fuer legacy_user_id-Lookup.
      return candidates.isEmpty ? null : candidates.first;
    } catch (_) {/* best-effort */}
    return null;
  }

  static String _hmacHex(String secret, String message) {
    final key = utf8.encode(secret);
    final bytes = utf8.encode(message);
    final mac = Hmac(sha256, key);
    return mac.convert(bytes).toString();
  }
}
