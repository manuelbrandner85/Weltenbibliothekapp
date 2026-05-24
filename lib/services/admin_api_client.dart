// AdminApiClient -- zentraler HTTP-Client fuer ALLE /api/admin/* und
// /api/push/* Endpoints. Kapselt:
//   * HMAC-Header (X-Admin-Username + X-Admin-Token) via AdminAuthService
//   * Legacy-Header (Authorization Bearer + X-Admin-ID + X-Role)
//   * Timeout (Default 12s)
//   * Detaillierte AdminApiException bei Fehler (statusCode + bodySnippet)
//   * Diagnostics-Logbuch (letzte 10 Fehler fuer Diag-Button im Dashboard)
//
// Hintergrund: vor dieser Klasse haben 10+ Call-Sites in world_admin_service.dart
// + world_admin_dashboard.dart die HMAC-Header VERGESSEN (z.B. line 281
// getAllUsers: nur `Accept`). Das fuehrte zu 403-Antworten + leeren Tabs
// im Dashboard ohne dass User oder Entwickler sahen warum. Diese Klasse
// macht es UNMOEGLICH einen Admin-Call ohne Auth-Header zu setzen.
//
// Verwendung:
//   final client = AdminApiClient.instance;
//   final json = await client.getJson('/api/admin/users');
//   final result = await client.postJson('/api/admin/users/<id>/role',
//                                        body: {'role': 'moderator'});

import 'dart:async';
import 'dart:convert';
import 'dart:collection';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../config/api_config.dart';
import 'admin_auth_service.dart';

/// Fehler vom Worker. statusCode + bodySnippet werden in der Dashboard-
/// Error-Anzeige sichtbar damit Admins sofort sehen warum etwas
/// fehlschlug (vorher: nur "Keine Nutzer geladen").
class AdminApiException implements Exception {
  final int statusCode;
  final String bodySnippet;
  final String path;
  final String method;

  AdminApiException({
    required this.statusCode,
    required this.bodySnippet,
    required this.path,
    required this.method,
  });

  @override
  String toString() =>
      'AdminApiException($method $path -> $statusCode: $bodySnippet)';

  /// User-freundliche Meldung in Deutsch.
  String get userMessage {
    switch (statusCode) {
      case 401:
      case 403:
        return 'Keine Berechtigung. Bitte App neu starten und als Admin '
            'anmelden ($statusCode).';
      case 404:
        return 'Endpunkt nicht gefunden ($path).';
      case 429:
        return 'Zu viele Anfragen -- bitte kurz warten.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'Server-Fehler ($statusCode). Bitte spaeter erneut versuchen.';
      default:
        if (statusCode == 0) return 'Netzwerkfehler. Internet pruefen.';
        return 'HTTP $statusCode: $bodySnippet';
    }
  }
}

/// Eintrag im Diagnose-Logbuch.
class AdminApiDiagEntry {
  final DateTime when;
  final String method;
  final String path;
  final int statusCode;
  final String message;
  final bool hmacHeadersSent;

  AdminApiDiagEntry({
    required this.when,
    required this.method,
    required this.path,
    required this.statusCode,
    required this.message,
    required this.hmacHeadersSent,
  });
}

class _CachedResponse {
  final Map<String, dynamic> body;
  final DateTime cachedAt;
  _CachedResponse(this.body, this.cachedAt);
}

class AdminApiClient {
  AdminApiClient._();
  static final AdminApiClient instance = AdminApiClient._();

  static const Duration _defaultTimeout = Duration(seconds: 12);
  static const int _bodySnippetMax = 240;

  /// Ring-Buffer der letzten 10 Calls (success + failed). Wird vom
  /// Diagnose-Button im Dashboard angezeigt.
  final Queue<AdminApiDiagEntry> _diagLog = Queue<AdminApiDiagEntry>();
  List<AdminApiDiagEntry> get diagLog => List.unmodifiable(_diagLog);

  /// In-Memory Response-Cache fuer GET-Endpoints. TTL 30s default.
  /// Verhindert dass beim Tab-Wechsel sofort wieder gefetcht wird.
  /// Kann via invalidateCache() forciert geleert werden (z.B. nach
  /// erfolgreichem ban/role-change).
  final Map<String, _CachedResponse> _cache = {};
  Duration _cacheTtl = const Duration(seconds: 30);

  /// Cache komplett leeren (z.B. nach einer Mutation um stale Daten
  /// zu verhindern).
  void invalidateCache([String? pathPrefix]) {
    if (pathPrefix == null) {
      _cache.clear();
    } else {
      _cache.removeWhere((key, _) => key.startsWith(pathPrefix));
    }
  }

  void _record(AdminApiDiagEntry e) {
    _diagLog.addLast(e);
    while (_diagLog.length > 10) {
      _diagLog.removeFirst();
    }
  }

  /// Baut die volle Header-Map: Legacy-Header (JWT + X-Admin-ID + X-Role)
  /// + HMAC-Header (X-Admin-Username + X-Admin-Token).
  ///
  /// Legacy bleibt drin damit aeltere Worker-Versionen die noch
  /// X-Admin-ID lesen weiter funktionieren -- harmlos fuer neue Worker
  /// die die Legacy-Header ignorieren.
  Future<Map<String, String>> _buildHeaders({
    String? role,
    String? extraContentType,
  }) async {
    final hmac = await AdminAuthService.instance.headers();
    final jwt = Supabase.instance.client.auth.currentSession?.accessToken;
    final adminId = Supabase.instance.client.auth.currentUser?.id;

    final headers = <String, String>{
      'Accept': 'application/json',
      if (extraContentType != null) 'Content-Type': extraContentType,
      if (jwt != null) 'Authorization': 'Bearer $jwt',
      if (adminId != null) 'X-Admin-ID': adminId,
      if (role != null) 'X-Role': role,
      ...hmac,
    };
    return headers;
  }

  /// GET-Request gegen einen Pfad relativ zum Worker (z.B. '/api/admin/users').
  /// Wenn `path` mit 'http' beginnt, wird er als absolute URL behandelt.
  /// Liefert das geparste JSON als Map<String,dynamic> -- oder wirft
  /// AdminApiException bei !200.
  ///
  /// [useCache]: wenn true und Cache-Hit < cacheTtl, liefert sofort
  ///   aus dem Cache statt zu netzwerken. Default false.
  Future<Map<String, dynamic>> getJson(
    String path, {
    String? role,
    Duration? timeout,
    bool useCache = false,
  }) async {
    if (useCache) {
      final cached = _cache[path];
      if (cached != null &&
          DateTime.now().difference(cached.cachedAt) < _cacheTtl) {
        return cached.body;
      }
    }
    final result = await _request<Map<String, dynamic>>(
      method: 'GET',
      path: path,
      role: role,
      timeout: timeout,
      parser: _parseAsMap,
    );
    if (useCache) {
      _cache[path] = _CachedResponse(result, DateTime.now());
    }
    return result;
  }

  /// Wie getJson aber gibt rohe Response zurueck (fuer Endpoints die
  /// kein JSON liefern oder spezielles Parsing brauchen).
  Future<http.Response> getRaw(
    String path, {
    String? role,
    Duration? timeout,
  }) async {
    return _doRequest(
      method: 'GET',
      path: path,
      role: role,
      timeout: timeout,
    );
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    String? role,
    Duration? timeout,
  }) async {
    return _request<Map<String, dynamic>>(
      method: 'POST',
      path: path,
      body: body,
      role: role,
      timeout: timeout,
      parser: _parseAsMap,
    );
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic>? body,
    String? role,
    Duration? timeout,
  }) async {
    return _request<Map<String, dynamic>>(
      method: 'PATCH',
      path: path,
      body: body,
      role: role,
      timeout: timeout,
      parser: _parseAsMap,
    );
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    Map<String, dynamic>? body,
    String? role,
    Duration? timeout,
  }) async {
    return _request<Map<String, dynamic>>(
      method: 'PUT',
      path: path,
      body: body,
      role: role,
      timeout: timeout,
      parser: _parseAsMap,
    );
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    String? role,
    Duration? timeout,
  }) async {
    return _request<Map<String, dynamic>>(
      method: 'DELETE',
      path: path,
      role: role,
      timeout: timeout,
      parser: _parseAsMap,
    );
  }

  static Map<String, dynamic> _parseAsMap(http.Response res) {
    if (res.body.isEmpty) return const {};
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return {'data': decoded};
  }

  Future<T> _request<T>({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    String? role,
    Duration? timeout,
    required T Function(http.Response) parser,
  }) async {
    final res = await _doRequest(
      method: method,
      path: path,
      body: body,
      role: role,
      timeout: timeout,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AdminApiException(
        statusCode: res.statusCode,
        bodySnippet: _snippet(res.body),
        path: path,
        method: method,
      );
    }
    try {
      return parser(res);
    } catch (e) {
      throw AdminApiException(
        statusCode: res.statusCode,
        bodySnippet: 'Parse-Fehler: $e',
        path: path,
        method: method,
      );
    }
  }

  Future<http.Response> _doRequest({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    String? role,
    Duration? timeout,
  }) async {
    final url = path.startsWith('http')
        ? Uri.parse(path)
        : Uri.parse('${ApiConfig.workerUrl}$path');
    final headers = await _buildHeaders(
      role: role,
      extraContentType: body != null ? 'application/json' : null,
    );
    final hmacSent = headers.containsKey('X-Admin-Token');
    final to = timeout ?? _defaultTimeout;

    try {
      final http.Response res;
      switch (method) {
        case 'GET':
          res = await http.get(url, headers: headers).timeout(to);
          break;
        case 'POST':
          res = await http
              .post(url, headers: headers, body: jsonEncode(body ?? const {}))
              .timeout(to);
          break;
        case 'PATCH':
          res = await http
              .patch(url, headers: headers, body: jsonEncode(body ?? const {}))
              .timeout(to);
          break;
        case 'PUT':
          res = await http
              .put(url, headers: headers, body: jsonEncode(body ?? const {}))
              .timeout(to);
          break;
        case 'DELETE':
          res = await http.delete(url, headers: headers).timeout(to);
          break;
        default:
          throw ArgumentError('Method $method nicht unterstuetzt');
      }
      _record(AdminApiDiagEntry(
        when: DateTime.now(),
        method: method,
        path: path,
        statusCode: res.statusCode,
        message: res.statusCode >= 400 ? _snippet(res.body) : 'ok',
        hmacHeadersSent: hmacSent,
      ));
      if (kDebugMode && res.statusCode >= 400) {
        debugPrint(
            '[AdminApiClient] $method $path -> ${res.statusCode}: '
            '${_snippet(res.body)}');
      }
      return res;
    } on TimeoutException {
      _record(AdminApiDiagEntry(
        when: DateTime.now(),
        method: method,
        path: path,
        statusCode: 0,
        message: 'Timeout nach ${to.inSeconds}s',
        hmacHeadersSent: hmacSent,
      ));
      throw AdminApiException(
        statusCode: 0,
        bodySnippet: 'Timeout nach ${to.inSeconds}s',
        path: path,
        method: method,
      );
    } catch (e) {
      _record(AdminApiDiagEntry(
        when: DateTime.now(),
        method: method,
        path: path,
        statusCode: 0,
        message: 'Netzwerkfehler: $e',
        hmacHeadersSent: hmacSent,
      ));
      throw AdminApiException(
        statusCode: 0,
        bodySnippet: 'Netzwerkfehler: $e',
        path: path,
        method: method,
      );
    }
  }

  static String _snippet(String s) {
    if (s.length <= _bodySnippetMax) return s;
    return '${s.substring(0, _bodySnippetMax)}...';
  }

  /// Live-Diagnose: prueft den Worker komplett durch.
  /// Wird vom Diag-Button im Dashboard aufgerufen.
  Future<Map<String, dynamic>> diagnose() async {
    final result = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'worker_url': ApiConfig.workerUrl,
    };

    // 1. /health (kein Auth)
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.workerUrl}/health'))
          .timeout(const Duration(seconds: 5));
      result['health'] = {
        'status': res.statusCode,
        'body': _snippet(res.body),
      };
    } catch (e) {
      result['health'] = {'error': e.toString()};
    }

    // 2. HMAC-Header verfuegbar?
    try {
      final hmac = await AdminAuthService.instance.headers();
      result['hmac'] = {
        'username': hmac['X-Admin-Username'] ?? '(keiner)',
        'token_length': (hmac['X-Admin-Token'] ?? '').length,
        'headers_complete': hmac.containsKey('X-Admin-Username') &&
            hmac.containsKey('X-Admin-Token'),
      };
    } catch (e) {
      result['hmac'] = {'error': e.toString()};
    }

    // 3. /api/admin/check (kein Auth noetig, prueft Profile-Existenz)
    final username =
        (result['hmac'] as Map?)?['username']?.toString() ?? 'Weltenbibliothek';
    try {
      final res = await http
          .get(Uri.parse(
              '${ApiConfig.workerUrl}/api/admin/check/materie/$username'))
          .timeout(const Duration(seconds: 5));
      result['admin_check'] = {
        'status': res.statusCode,
        'body': _snippet(res.body),
      };
    } catch (e) {
      result['admin_check'] = {'error': e.toString()};
    }

    // 4. /api/admin/users echter Call (mit Auth)
    try {
      await getJson('/api/admin/users');
      result['admin_users'] = {'ok': true};
    } on AdminApiException catch (e) {
      result['admin_users'] = {
        'status': e.statusCode,
        'body': e.bodySnippet,
        'user_message': e.userMessage,
      };
    } catch (e) {
      result['admin_users'] = {'error': e.toString()};
    }

    // 5. Letzte 5 Diag-Entries
    result['recent_calls'] = _diagLog
        .toList()
        .reversed
        .take(5)
        .map((e) => {
              'when': e.when.toIso8601String(),
              'method': e.method,
              'path': e.path,
              'status': e.statusCode,
              'message': e.message,
              'hmac_sent': e.hmacHeadersSent,
            })
        .toList();

    return result;
  }
}
