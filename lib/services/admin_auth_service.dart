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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth/admin_resolver.dart';
import '../core/constants/roles.dart';
import '../core/storage/unified_storage_service.dart';
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

      final username = await _currentUsername();
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
  /// Sucht in 4 Quellen und nimmt die hoechste Prioritaet:
  ///   1. Supabase-Auth-Session (web user) -> profile.username via DB
  ///   2. AppRoles.isRootAdminByUsername / isContentEditorByUsername Match
  ///      in StorageService (Hive) ODER UnifiedStorageService -> kanonische
  ///      Username-Konstante zurueckgeben ('Weltenbibliothek')
  ///   3. SharedPreferences 'web_user_name' (Web-Login Fallback)
  ///   4. Erster non-'user_'-prefix Storage-Username
  ///   5. (last resort): erster non-empty Storage-Username
  Future<String?> _currentUsername() async {
    try {
      final storage = StorageService();
      final unified = UnifiedStorageService();

      // Sammle alle Quellen
      final candidates = <String>[
        storage.getMaterieProfile()?.username ?? '',
        storage.getEnergieProfile()?.username ?? '',
        unified.getUsername('materie') ?? '',
        unified.getUsername('energie') ?? '',
      ];

      // Prio 1 (Web-User): Supabase-Auth-Session + profile-Lookup
      try {
        final supaUser = Supabase.instance.client.auth.currentUser;
        if (supaUser != null) {
          final row = await Supabase.instance.client
              .from('profiles')
              .select('username,role')
              .eq('id', supaUser.id)
              .maybeSingle()
              .timeout(const Duration(seconds: 4));
          final dbUsername = row?['username'] as String?;
          if (dbUsername != null && dbUsername.trim().isNotEmpty) {
            return dbUsername.trim();
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[AdminAuthService] Supabase-username lookup: $e');
        }
      }

      // Prio 2: bekannter Admin-Username (kanonisch zurueckgeben)
      for (final u in candidates) {
        if (AppRoles.isRootAdminByUsername(u)) {
          return AppRoles.rootAdminUsername;
        }
        if (AppRoles.isContentEditorByUsername(u)) {
          return AppRoles.contentEditorUsername;
        }
      }

      // Prio 3: SharedPreferences (Web-Auth-Gate fallback)
      try {
        final prefs = await SharedPreferences.getInstance();
        final webName = prefs.getString('web_user_name');
        if (webName != null && webName.trim().isNotEmpty) {
          return webName.trim();
        }
      } catch (_) {/* best-effort */}

      final nonEmpty =
          candidates.where((u) => u.trim().isNotEmpty).toList();

      // Prio 4: erster non-InvisibleAuth-Username
      for (final u in nonEmpty) {
        if (!u.startsWith('user_')) return u;
      }

      // Prio 5 (Fallback): erster non-empty
      return nonEmpty.isEmpty ? null : nonEmpty.first;
    } catch (e) {
      if (kDebugMode) debugPrint('[AdminAuthService] _currentUsername: $e');
      return null;
    }
  }

  static String _hmacHex(String secret, String message) {
    final key = utf8.encode(secret);
    final bytes = utf8.encode(message);
    final mac = Hmac(sha256, key);
    return mac.convert(bytes).toString();
  }
}
