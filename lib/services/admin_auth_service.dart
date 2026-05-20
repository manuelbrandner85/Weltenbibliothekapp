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

  String? _currentUsername() {
    try {
      final storage = StorageService();
      final mat = storage.getMaterieProfile()?.username;
      if (mat != null && mat.isNotEmpty) return mat;
      final en = storage.getEnergieProfile()?.username;
      if (en != null && en.isNotEmpty) return en;
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
