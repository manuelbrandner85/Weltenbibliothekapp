// AccountService -- User-facing (kein Admin) Worker-Calls fuer:
//   - Notification-Loeschen (einzeln + alle)
//   - Eigene Sperren lesen (fuer In-App-Anzeige)
//   - Antraege stellen: Reaktivierung (nach Loeschung), Einspruch gegen
//     Sperre, Selbst-Loeschung des eigenen Kontos
//
// Alle Endpoints sind oeffentlich (InvisibleAuth-tauglich) und identifizieren
// den User ueber die mitgelieferte userId/username. Schreiben passiert
// serverseitig via service_role, streng auf die Identitaet beschraenkt.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class AccountService {
  AccountService._();
  static final AccountService instance = AccountService._();

  static const _timeout = Duration(seconds: 12);

  Uri _u(String path) => Uri.parse('${ApiConfig.workerUrl}$path');

  // ── Notifications ──────────────────────────────────────────────────────

  /// Loescht eine einzelne Notification des Users.
  Future<bool> deleteNotification(
      {required String id, required String userId}) async {
    try {
      final res = await http
          .delete(_u(
              '/api/notifications/$id?userId=${Uri.encodeQueryComponent(userId)}'))
          .timeout(_timeout);
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ deleteNotification: $e');
      return false;
    }
  }

  /// Loescht ALLE Notifications des Users.
  Future<bool> deleteAllNotifications({required String userId}) async {
    try {
      final res = await http
          .delete(_u(
              '/api/notifications/all?userId=${Uri.encodeQueryComponent(userId)}'))
          .timeout(_timeout);
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ deleteAllNotifications: $e');
      return false;
    }
  }

  /// Liest die In-App-Notifications via Worker (service_role, umgeht RLS).
  /// KRITISCH fuer InvisibleAuth-User: die koennen die notifications-Tabelle
  /// nicht direkt via Supabase lesen (RLS auth.uid()=user_id schlaegt fehl).
  Future<List<Map<String, dynamic>>> getNotifications({
    required String userId,
    bool unreadOnly = false,
    int limit = 100,
  }) async {
    try {
      final res = await http
          .get(
              _u('/api/notifications?userId=${Uri.encodeQueryComponent(userId)}'
                  '&unreadOnly=$unreadOnly&limit=$limit'))
          .timeout(_timeout);
      if (res.statusCode < 200 || res.statusCode >= 300) return const [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (data['notifications'] as List?) ?? const [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getNotifications: $e');
      return const [];
    }
  }

  /// Markiert eine (id gesetzt) ODER alle Notifications des Users als gelesen.
  Future<bool> markNotificationsRead({
    required String userId,
    String? id,
  }) async {
    try {
      final res = await http
          .post(
            _u('/api/notifications/mark-read'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'userId': userId,
              if (id != null) 'id': id,
            }),
          )
          .timeout(_timeout);
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ markNotificationsRead: $e');
      return false;
    }
  }

  // ── Identitaets-Lookup (Auto-Fill Username + Blacklist-Vorabpruefung) ───

  /// Findet zu Vor+Nachname den hinterlegten Username und prueft die
  /// Loesch-Blacklist. Returns z.B.
  /// { matched_username, matched_world, blacklisted, reactivation_status }.
  Future<Map<String, dynamic>> identityLookup({
    required String firstName,
    required String lastName,
    String? username,
    String? birthDate,
    String? birthPlace,
  }) async {
    try {
      final qp = <String, String>{
        'firstName': firstName,
        'lastName': lastName,
      };
      if (username != null && username.isNotEmpty) qp['username'] = username;
      if (birthDate != null && birthDate.isNotEmpty)
        qp['birthDate'] = birthDate;
      if (birthPlace != null && birthPlace.isNotEmpty) {
        qp['birthPlace'] = birthPlace;
      }
      final res = await http
          .get(_u(
              '/api/account/identity-lookup?${Uri(queryParameters: qp).query}'))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      if (kDebugMode) debugPrint('❌ identityLookup: $e');
      return {};
    }
  }

  // ── Eigene Sperren ─────────────────────────────────────────────────────

  /// Liefert { scopes: [...], restrictions: [{scope, reason, expires_at}] }
  /// der aktiven Sperren des Users. Leere Map bei Fehler.
  Future<Map<String, dynamic>> getMyRestrictions(
      {String? userId, String? username}) async {
    try {
      final qp = <String, String>{};
      if (userId != null && userId.isNotEmpty) qp['userId'] = userId;
      if (username != null && username.isNotEmpty) qp['username'] = username;
      if (qp.isEmpty) return {'scopes': [], 'restrictions': []};
      final res = await http
          .get(
              _u('/api/account/restrictions?${Uri(queryParameters: qp).query}'))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return {'scopes': [], 'restrictions': []};
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getMyRestrictions: $e');
      return {'scopes': [], 'restrictions': []};
    }
  }

  // ── Antraege ───────────────────────────────────────────────────────────

  /// Antrag auf Reaktivierung eines geloeschten Kontos.
  Future<bool> requestReactivation({
    required String username,
    String? fullName,
    String? birthDate,
    String? birthPlace,
    String? message,
  }) =>
      _postJson('/api/account/reactivation-request', {
        'username': username,
        if (fullName != null) 'full_name': fullName,
        if (birthDate != null) 'birth_date': birthDate,
        if (birthPlace != null) 'birth_place': birthPlace,
        if (message != null) 'message': message,
      });

  /// Einspruch gegen eine Sperre. [scope] = betroffener Bereich (optional).
  Future<bool> submitAppeal({
    required String userId,
    String? username,
    String? scope,
    required String message,
  }) =>
      _postJson('/api/account/appeal', {
        'userId': userId,
        if (username != null) 'username': username,
        if (scope != null) 'scope': scope,
        'message': message,
      });

  /// Antrag auf Loeschung des eigenen Kontos.
  Future<bool> requestSelfDeletion({
    required String userId,
    String? username,
    String? fullName,
    String? birthDate,
    String? birthPlace,
    String? message,
  }) =>
      _postJson('/api/account/self-delete-request', {
        'userId': userId,
        if (username != null) 'username': username,
        if (fullName != null) 'full_name': fullName,
        if (birthDate != null) 'birth_date': birthDate,
        if (birthPlace != null) 'birth_place': birthPlace,
        if (message != null) 'message': message,
      });

  Future<bool> _postJson(String path, Map<String, dynamic> body) async {
    try {
      final res = await http
          .post(_u(path),
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode(body))
          .timeout(_timeout);
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AccountService._postJson($path): $e');
      return false;
    }
  }
}
