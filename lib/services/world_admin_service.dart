import 'dart:async';
import 'dart:io' if (dart.library.html) '../stubs/dart_io_stub.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'admin_api_client.dart';
import 'admin_auth_service.dart';
import 'push_notification_helper.dart';
import 'dart:convert';
import 'invisible_auth_service.dart'; // ✅ Auth-Integration
import '../config/api_config.dart'; // 🆕 API Config for admin token
import 'supabase_service.dart'; // 🔥 Supabase Direct Access

/// World-Based Admin Service
/// Verbindet mit weltenbibliothek-api-v2 für weltspezifische Admin-Funktionen
///
/// 🔐 ALLE ENDPOINTS ERFORDERN AUTH-HEADERS:
/// - Authorization: Bearer {token}
/// - X-World: materie/energie
/// - X-Role: admin/root_admin
/// - X-User-ID: {userId}
///
/// ✅ ENDPOINTS:
/// - GET /api/admin/check/:world/:username - Admin-Status prüfen
/// - GET /api/admin/users/:world - User-Liste pro Welt
/// - POST /api/admin/promote/:world/:userId - User zu Admin
/// - POST /api/admin/demote/:world/:userId - Admin zu User (nur Root-Admin)
/// - DELETE /api/admin/delete/:world/:userId - User löschen (nur Root-Admin)
/// - GET /api/admin/audit/:world - Audit-Log
///
/// 🛡️ WORLD-ISOLATION:
/// - Jede Welt hat separate Admin-Rollen
/// - Root-Admin in Materie ≠ Root-Admin in Energie
/// - Admin kann nur User in seiner Welt verwalten
class WorldAdminService {
  static const String _baseUrl = ApiConfig.workerUrl;
  static const Duration _timeout = Duration(seconds: 10);

  static final InvisibleAuthService _auth = InvisibleAuthService();

  /// Supabase JWT des aktuell eingeloggten Admins.
  /// Wird für alle Admin-API-Aufrufe als Bearer-Token genutzt.
  static String get _jwt => supabase.auth.currentSession?.accessToken ?? '';

  /// Supabase UUID des aktuell eingeloggten Admins.
  static String get _adminId => supabase.auth.currentUser?.id ?? '';

  /// Standard-Auth-Header für Admin-Requests (JWT + UUID).
  /// AUDIT-FIX A1: Legacy-Variante. Neue Endpoints brauchen
  /// `_adminAuthHeaders()` mit HMAC-Token (asynchron).
  static Map<String, String> _adminHeaders({String? role}) => {
        'Authorization': 'Bearer $_jwt',
        'X-Admin-ID': _adminId,
        if (role != null) 'X-Role': role,
        'Content-Type': 'application/json',
      };

  /// AUDIT-FIX A1: HMAC-Header fuer verifyAdminCaller im Worker.
  /// Async weil Username via StorageService geholt wird. Kombiniert
  /// die Legacy-Header mit dem neuen Token-Header.
  static Future<Map<String, String>> _adminAuthHeaders({String? role}) async {
    final hmac = await AdminAuthService.instance.headers();
    return {
      ..._adminHeaders(role: role),
      ...hmac,
    };
  }

  // ════════════════════════════════════════════════════════════
  // ADMIN STATUS CHECK
  // ════════════════════════════════════════════════════════════

  /// Check if user is admin in a specific world
  /// ✅ MIT AUTH-HEADER (world + role)
  ///
  /// Returns:
  /// {
  ///   "success": true,
  ///   "isAdmin": true,
  ///   "isRootAdmin": false,
  ///   "user": { "userId": "...", "username": "...", "role": "admin", "world": "materie" }
  /// }
  static Future<Map<String, dynamic>> checkAdminStatus(
      String world, String username,
      {String? role}) async {
    try {
      final url = Uri.parse('$_baseUrl/api/admin/check/$world/$username');

      if (kDebugMode) {
        debugPrint('🔍 Checking admin status: $world/$username (role: $role)');
      }

      final response = await http
          .get(
            url,
            headers:
                _auth.authHeaders(world: world, role: role), // ✅ Auth-Header
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (kDebugMode) {
          debugPrint('✅ Admin check successful');
          debugPrint('   isAdmin: ${data['isAdmin']}');
          debugPrint('   isRootAdmin: ${data['isRootAdmin']}');
        }

        return data;
      } else {
        if (kDebugMode) {
          debugPrint('⚠️  Admin check failed: ${response.statusCode}');
        }
        return {
          'success': false,
          'isAdmin': false,
          'isRootAdmin': false,
          'error': 'HTTP ${response.statusCode}',
        };
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Network: Keine Internetverbindung');
      }
      return {
        'success': false,
        'isAdmin': false,
        'isRootAdmin': false,
        'error': e.toString(),
      };
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Timeout: $e');
      }
      return {
        'success': false,
        'isAdmin': false,
        'isRootAdmin': false,
        'error': e.toString(),
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Admin check error: $e $e');
      }
      return {
        'success': false,
        'isAdmin': false,
        'isRootAdmin': false,
        'error': e.toString(),
      };
    }
  }

  // ════════════════════════════════════════════════════════════
  // USER MANAGEMENT
  // ════════════════════════════════════════════════════════════

  /// Get list of users in a specific world
  /// ✅ FIXED AUTH: Uses simple Bearer token (username)
  ///
  /// Returns: List[WorldUser]
  /// v103: deprecated -- ein User hat EIN globales Profil. Verwende
  /// getAllUsers() statt einer Welt-Liste.
  @Deprecated('v103: Profile sind global. Use getAllUsers() instead.')
  static Future<List<WorldUser>> getUsersByWorld(String world,
      {String? role}) async {
    if (kDebugMode) {
      debugPrint('📋 Fetching users for world: $world');
    }

    // ─────────────────────────────────────────────────────────────────────
    // 1️⃣ PRIMARY: Supabase direct query (both world and world_preference)
    //    Falls keine World-spezifischen User: Alle User anzeigen (Admin-Kontext)
    // ─────────────────────────────────────────────────────────────────────
    try {
      // Erst versuchen mit World-Filter
      var result = await supabase
          .from('profiles')
          .select(
              'id,username,display_name,role,is_banned,avatar_url,created_at,world,world_preference')
          .or('world.eq.$world,world_preference.eq.$world')
          .order('created_at', ascending: false)
          .limit(200);

      var rawList = (result as List<dynamic>);

      // ✅ FALLBACK: Wenn keine World-spezifischen User → alle User laden
      // Das passiert wenn Nutzer noch kein world_preference gesetzt haben
      if (rawList.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ Keine $world-User gefunden – lade alle Profile');
        }
        result = await supabase
            .from('profiles')
            .select(
                'id,username,display_name,role,is_banned,avatar_url,created_at,world,world_preference')
            .order('created_at', ascending: false)
            .limit(200);
        rawList = result as List<dynamic>;
      }

      final users = rawList
          .map((u) => Map<String, dynamic>.from(u as Map))
          .map((u) => WorldUser(
                profileId: u['id'] as String? ?? '',
                userId: u['id'] as String? ?? '',
                username: u['username'] as String? ?? 'Unbekannt',
                displayName: u['display_name'] as String?,
                role: u['role'] as String? ?? 'user',
                avatarUrl: u['avatar_url'] as String?,
                avatarEmoji: null,
                createdAt: u['created_at'] as String? ?? '',
              ))
          .toList();

      if (kDebugMode) {
        debugPrint('✅ Supabase users: ${users.length} for world=$world');
      }
      return users;
    } catch (supaErr) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase users failed: $supaErr – trying worker...');
      }
    }

    // ─────────────────────────────────────────────────────────────────────
    // 2️⃣ FALLBACK: Cloudflare Worker
    // ─────────────────────────────────────────────────────────────────────
    try {
      // PHASE-1 FIX: HMAC-Header (deprecated getUsersByWorld -- aber falls
      // noch genutzt, soll es auch funktionieren).
      final url = Uri.parse('$_baseUrl/api/admin/users/$world');
      final response = await http
          .get(
            url,
            headers: await _adminAuthHeaders(role: role),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final users = (data['users'] as List<dynamic>?) ?? [];
        if (kDebugMode) {
          debugPrint('✅ Worker users: ${users.length}');
        }
        return users
            .map((u) => WorldUser.fromJson(u as Map<String, dynamic>))
            .toList();
      }
    } on SocketException {
      if (kDebugMode) debugPrint('❌ Network: Keine Internetverbindung');
    } on TimeoutException catch (e) {
      if (kDebugMode) debugPrint('❌ Timeout: $e');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error fetching users: $e');
    }

    return [];
  }

  /// Get ALL users from BOTH worlds (Energie + Materie)
  /// Admin sees all users with world label
  /// Lädt ALLE User aus profiles — keine Welt-Filterung mehr.
  /// Ein User hat genau EIN Profile-Datensatz, angelegt via
  /// Profile-Onboarding-Screen (App ODER Web). `web_access_requests` ist
  /// NUR Approval-Flow zum Web-Zugang — kein User-Profil — und wird hier
  /// nicht gelistet. System-Profile (id 00000000-…) werden ausgefiltert.
  static Future<List<WorldUser>> getAllUsers() async {
    if (kDebugMode) debugPrint('📋 Loading ALL profiles');

    // 🔑 PRIMÄR: Cloudflare Worker mit SERVICE_ROLE_KEY → umgeht RLS.
    // Client-seitige Direkt-Queries auf profiles sehen wegen RLS nur die
    // eigene Zeile — auch Admins. Worker nutzt service_role + filtert
    // System-Profile + liefert last_seen_at/world.
    Map<String, dynamic>? raw;
    bool hasLastSeen = true;
    // PHASE-1 FIX: AdminApiClient haengt HMAC-Header automatisch dran.
    // Vorher fehlten die Headers -> Worker antwortete 403 -> Fallback
    // auf Supabase RLS-Query lieferte 0 Rows -> "Keine Nutzer geladen".
    try {
      final data = await AdminApiClient.instance.getJson('/api/admin/users');
      final users = (data['users'] as List?) ?? const [];
      raw = {'rows': users};
      if (kDebugMode) debugPrint('✅ Loaded ${users.length} users via Worker');
    } on AdminApiException catch (e) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ Worker /api/admin/users ${e.statusCode}: ${e.bodySnippet} -- Fallback Supabase');
      }
      raw = null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ Worker /api/admin/users failed: $e -- Fallback Supabase');
      }
      raw = null;
    }

    // FALLBACK: direkt Supabase (funktioniert nur wenn RLS auf profiles
    // breit genug ist oder der eingeloggte User SELECT-Recht auf alle Rows hat).
    // v5.45+ avatar_emoji + legacy_user_id mit drin, damit Web- und
    // InvisibleAuth-User identisch dargestellt werden.
    if (raw == null) {
      try {
        raw = {
          'rows': await supabase
              .from('profiles')
              .select(
                  'id,username,display_name,full_name,role,is_banned,avatar_url,avatar_emoji,created_at,world,world_preference,last_seen_at,legacy_user_id')
              .order('created_at', ascending: false)
              .limit(5000)
        };
      } on PostgrestException catch (e) {
        if (e.code == '42703' ||
            e.message.contains('last_seen_at') ||
            e.message.contains('legacy_user_id') ||
            e.message.contains('avatar_emoji')) {
          if (kDebugMode) {
            debugPrint('⚠️ Optional-Spalte fehlt — minimaler Fallback');
          }
          hasLastSeen = false;
          try {
            raw = {
              'rows': await supabase
                  .from('profiles')
                  .select(
                      'id,username,display_name,role,is_banned,avatar_url,created_at,world,world_preference')
                  .order('created_at', ascending: false)
                  .limit(5000)
            };
          } catch (e2) {
            if (kDebugMode) debugPrint('❌ getAllUsers Fallback-Fehler: $e2');
            return const [];
          }
        } else {
          if (kDebugMode) debugPrint('❌ getAllUsers Postgrest: ${e.message}');
          return const [];
        }
      } catch (e) {
        if (kDebugMode) debugPrint('❌ getAllUsers Fehler: $e');
        return const [];
      }
    }

    try {
      final result = raw['rows'] as List<dynamic>;
      final users = result
          .map((u) => Map<String, dynamic>.from(u as Map))
          // System-Profile (00000000-...) ausfiltern. KEINE Filterung mehr
          // nach role='system' weil das echte User mit administrativen Rollen
          // ausschloss (matched Worker-Verhalten seit v5.44.7).
          .where((u) {
        final rawId =
            (u['id'] as String?) ?? (u['profile_id'] as String?) ?? '';
        return !rawId.startsWith('00000000-');
      }).map((u) {
        // Worker response uses 'profile_id'; Supabase direct uses 'id'.
        final id = (u['id'] as String?) ?? (u['profile_id'] as String?) ?? '';
        final legacy = u['legacy_user_id'] as String?;
        final username = (u['username'] as String?)?.trim().isNotEmpty == true
            ? u['username'] as String
            : '(ohne Username)';
        return WorldUser(
          profileId: id,
          // Aktionen brauchen einen nicht-leeren userId. Bevorzuge UUID,
          // sonst legacy_user_id (InvisibleAuth). Sonst Profile-ID.
          userId: id.isNotEmpty ? id : (legacy ?? ''),
          username: username,
          displayName:
              (u['display_name'] as String?) ?? (u['full_name'] as String?),
          role: u['role'] as String? ?? 'user',
          avatarUrl: u['avatar_url'] as String?,
          avatarEmoji: u['avatar_emoji'] as String?,
          createdAt: u['created_at'] as String? ?? '',
          lastSeenAt: hasLastSeen ? u['last_seen_at'] as String? : null,
          legacyUserId: legacy,
          isSuspended: u['is_banned'] as bool? ?? false,
          warningCount: (u['warning_count'] as num?)?.toInt() ?? 0,
        )..world =
            (u['world'] as String?) ?? (u['world_preference'] as String?);
      }).toList();

      const order = {
        'root_admin': 0,
        'admin': 1,
        'moderator': 2,
        'content_editor': 3,
        'user': 4
      };
      users.sort((a, b) {
        final aOrder = order[a.role] ?? 5;
        final bOrder = order[b.role] ?? 5;
        return aOrder == bOrder
            ? a.username.toLowerCase().compareTo(b.username.toLowerCase())
            : aOrder.compareTo(bOrder);
      });
      if (kDebugMode) debugPrint('✅ Total real users: ${users.length}');
      return users;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getAllUsers parse error: $e');
      return const [];
    }
  }

  // ════════════════════════════════════════════════════════════
  // ROLE MANAGEMENT
  // ════════════════════════════════════════════════════════════

  static Future<bool> promoteUser(String world, String userId,
      {String? role}) async {
    try {
      final url = Uri.parse('$_baseUrl/api/admin/promote/$world/$userId');
      if (kDebugMode) debugPrint('⬆️ Promoting user: $world/$userId');
      final response = await http
          .post(
            url,
            headers: await _adminAuthHeaders(role: role ?? 'root_admin'),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        if (kDebugMode) debugPrint('✅ User promoted successfully');
        return true;
      } else {
        if (kDebugMode) {
          debugPrint(
              '⚠️ Promotion failed: ${response.statusCode} – ${response.body}');
        }
        return false;
      }
    } on SocketException {
      if (kDebugMode) {
        debugPrint('❌ Network: Keine Internetverbindung');
      }
      return false;
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Timeout: $e');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Promotion error: $e $e');
      }
      return false;
    }
  }

  /// Demote admin to user
  static Future<bool> demoteUser(String world, String userId,
      {String? role}) async {
    try {
      final url = Uri.parse('$_baseUrl/api/admin/demote/$world/$userId');
      if (kDebugMode) debugPrint('⬇️ Demoting user: $world/$userId');
      final response = await http
          .post(
            url,
            headers: await _adminAuthHeaders(role: role ?? 'root_admin'),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        if (kDebugMode) debugPrint('✅ User demoted');
        return true;
      }
      if (kDebugMode) {
        debugPrint(
            '⚠️ Demotion failed: ${response.statusCode} – ${response.body}');
      }
      return false;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Demotion error: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════
  // USER DELETION
  // ════════════════════════════════════════════════════════════

  /// Delete user (root admin only)
  /// ✅ FIXED AUTH: Uses simple Bearer token (username)
  static Future<bool> deleteUser(String world, String userId,
      {String? role}) async {
    try {
      final url = Uri.parse('$_baseUrl/api/admin/delete/$world/$userId');
      if (kDebugMode) debugPrint('🗑️ Deleting user: $world/$userId');
      final response = await http
          .delete(
            url,
            headers: await _adminAuthHeaders(role: 'root_admin'),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        if (kDebugMode) debugPrint('✅ User deleted');
        return true;
      }
      if (kDebugMode) {
        debugPrint(
            '⚠️ Deletion failed: ${response.statusCode} – ${response.body}');
      }
      return false;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Deletion error: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════
  // AUDIT LOG
  // ════════════════════════════════════════════════════════════

  /// Get audit log for a world
  /// ✅ MIT AUTH-HEADER
  ///
  /// Returns: List[AuditLogEntry]
  static Future<List<AuditLogEntry>> getAuditLog(String world,
      {int limit = 50, String? role}) async {
    // ─────────────────────────────────────────────────────────────────────
    // 1️⃣ PRIMARY: Worker API
    // ─────────────────────────────────────────────────────────────────────
    try {
      final url = Uri.parse('$_baseUrl/api/admin/audit/$world?limit=$limit');
      if (kDebugMode) {
        debugPrint('📜 Fetching audit log for: $world (role: $role)');
      }

      // PHASE-1 FIX: HMAC-Header via AdminAuthService (vorher fehlten sie,
      // Audit-Tab war leer).
      final response = await http
          .get(
            url,
            headers: await _adminAuthHeaders(role: role),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final logs = (data['logs'] as List<dynamic>?) ?? [];
        if (logs.isNotEmpty) {
          if (kDebugMode) {
            debugPrint('✅ Fetched ${logs.length} audit log entries');
          }
          return logs
              .map((l) => AuditLogEntry.fromJson(l as Map<String, dynamic>))
              .toList();
        }
      }
    } on SocketException {
      if (kDebugMode) debugPrint('❌ Audit log: Keine Internetverbindung');
    } on TimeoutException {
      if (kDebugMode) debugPrint('❌ Audit log: Timeout');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Audit log worker error: $e');
    }

    // ─────────────────────────────────────────────────────────────────────
    // 2️⃣ FALLBACK: Supabase – Chat-Nachrichten als Aktivitäts-Log
    //    Zeigt letzte Nachrichten als "Aktivitäten" wenn kein echtes Audit-Log
    // ─────────────────────────────────────────────────────────────────────
    try {
      if (kDebugMode) {
        debugPrint('📜 Fallback: Lade Chat-Aktivitäten als Audit-Log');
      }

      // Lade editierte/gelöschte Nachrichten als Audit-Einträge
      final editedResult = await supabase
          .from('chat_messages')
          .select(
              'id,room_id,user_id,username,message,edited_at,deleted_at,is_deleted,created_at')
          .like('room_id', '$world-%')
          .not('edited_at', 'is', null)
          .order('edited_at', ascending: false)
          .limit(limit ~/ 2);

      final deletedResult = await supabase
          .from('chat_messages')
          .select(
              'id,room_id,user_id,username,message,edited_at,deleted_at,is_deleted,created_at')
          .like('room_id', '$world-%')
          .eq('is_deleted', true)
          .order('deleted_at', ascending: false)
          .limit(limit ~/ 2);

      final entries = <AuditLogEntry>[];

      for (final m in (editedResult as List<dynamic>)) {
        final msg = Map<String, dynamic>.from(m as Map);
        entries.add(AuditLogEntry(
          logId: msg['id'] as String? ?? '',
          adminUsername: msg['username'] as String? ?? 'Unbekannt',
          action: 'edit_message',
          targetUsername: msg['username'] as String? ?? '',
          oldRole: null,
          newRole: null,
          timestamp:
              msg['edited_at'] as String? ?? msg['created_at'] as String? ?? '',
        ));
      }

      for (final m in (deletedResult as List<dynamic>)) {
        final msg = Map<String, dynamic>.from(m as Map);
        entries.add(AuditLogEntry(
          logId: msg['id'] as String? ?? '',
          adminUsername: msg['username'] as String? ?? 'Unbekannt',
          action: 'delete_message',
          targetUsername: msg['username'] as String? ?? '',
          oldRole: null,
          newRole: null,
          timestamp: msg['deleted_at'] as String? ??
              msg['created_at'] as String? ??
              '',
        ));
      }

      // Nach Zeit sortieren (neueste zuerst)
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      if (kDebugMode) {
        debugPrint('✅ Fallback Audit: ${entries.length} Aktivitäten');
      }
      return entries.take(limit).toList();
    } catch (supaErr) {
      if (kDebugMode) debugPrint('⚠️ Supabase audit fallback error: $supaErr');
    }

    return [];
  }
}

// ════════════════════════════════════════════════════════════
// DATA MODELS
// ════════════════════════════════════════════════════════════

/// World User Model
class WorldUser {
  final String profileId;
  final String userId;
  final String username;
  final String role;
  final String? displayName;
  final String? avatarUrl;
  final String? avatarEmoji;
  final String createdAt;
  String? world; // Welche Welt (materie/energie) - mutable for tagging
  final bool isSuspended;
  final String? suspensionReason;
  // 🟢 Online-Status: ISO-Timestamp des letzten Heartbeats.
  final String? lastSeenAt;
  // 🔑 InvisibleAuth legacy ID (client-generated `user_<ts>_<rand>`).
  // null wenn User ueber Supabase Auth (Web) registriert wurde.
  final String? legacyUserId;
  // v115: Anzahl Verwarnungen (aus admin_warnings-Aggregat im Worker).
  final int warningCount;
  // v117: Herkunft direkt vom Worker ('app'|'web'). Authoritative -- der
  // frueher client-seitig geratene Wert war fuer alle 'web' (profiles.id
  // ist immer UUID). null wenn Worker (noch) kein source liefert.
  final String? sourceFromServer;
  // v117: Web-Zugangs-Antrag ohne echtes Profil -- User-Aktionen greifen nicht.
  final bool isWebOnly;
  // v123: Shadow-ban (root_admin only). Content visible to sender, hidden to others.
  final bool isShadowBanned;
  // v123: Chat-Mute until this timestamp. null = not muted.
  final DateTime? mutedUntil;
  // v123: Account created < 24h AND post count above threshold -> bot suspect.
  final bool isBotSuspect;
  // v123: Post count (filled by Worker if available).
  final int postCount;

  WorldUser({
    required this.profileId,
    required this.userId,
    required this.username,
    required this.role,
    this.displayName,
    this.avatarUrl,
    this.avatarEmoji,
    required this.createdAt,
    this.world,
    this.isSuspended = false,
    this.suspensionReason,
    this.lastSeenAt,
    this.legacyUserId,
    this.warningCount = 0,
    this.sourceFromServer,
    this.isWebOnly = false,
    this.isShadowBanned = false,
    this.mutedUntil,
    this.isBotSuspect = false,
    this.postCount = 0,
  });

  factory WorldUser.fromJson(Map<String, dynamic> json) {
    final id =
        json['profile_id'] as String? ?? json['profileId'] as String? ?? '';
    final legacy =
        json['legacy_user_id'] as String? ?? json['legacyUserId'] as String?;
    final mutedStr =
        json['muted_until'] as String? ?? json['mutedUntil'] as String?;
    return WorldUser(
      profileId: id,
      // userId fuer Aktionen: wenn UUID vorhanden, nimm die. Sonst InvisibleAuth-ID.
      userId: (json['user_id'] as String?)?.isNotEmpty == true
          ? json['user_id'] as String
          : (id.isNotEmpty ? id : (legacy ?? '')),
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      displayName:
          json['display_name'] as String? ?? json['displayName'] as String?,
      avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
      avatarEmoji:
          json['avatar_emoji'] as String? ?? json['avatarEmoji'] as String?,
      createdAt:
          json['created_at'] as String? ?? json['createdAt'] as String? ?? '',
      world: json['world'] as String?,
      isSuspended:
          json['is_suspended'] as bool? ?? json['is_banned'] as bool? ?? false,
      suspensionReason:
          json['suspension_reason'] as String? ?? json['ban_reason'] as String?,
      lastSeenAt:
          json['last_seen_at'] as String? ?? json['lastSeenAt'] as String?,
      legacyUserId: legacy,
      warningCount: (json['warning_count'] as num?)?.toInt() ?? 0,
      sourceFromServer: json['source'] as String?,
      isWebOnly: json['is_web_only'] as bool? ?? false,
      isShadowBanned: json['shadow_banned'] as bool? ??
          json['isShadowBanned'] as bool? ??
          false,
      mutedUntil: mutedStr != null ? DateTime.tryParse(mutedStr) : null,
      isBotSuspect: json['is_bot_suspect'] as bool? ??
          json['isBotSuspect'] as bool? ??
          false,
      postCount: (json['post_count'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isAdmin => role == 'admin' || role == 'root_admin';
  bool get isRootAdmin => role == 'root_admin';
  bool get isMuted =>
      mutedUntil != null && mutedUntil!.isAfter(DateTime.now().toUtc());

  /// True for auto-generated InvisibleAuth accounts that never set a real
  /// username (pattern: 'user_' followed only by digits).
  bool get isGhostUser =>
      username.startsWith('user_') && RegExp(r'^user_\d+$').hasMatch(username);

  /// Herkunft des Profils: 'app' (InvisibleAuth, hat legacy_user_id) oder
  /// 'web' (Supabase-Auth/Web-Login). v117: Worker liefert 'source'
  /// authoritative; Fallback auf legacy_user_id (NICHT mehr auf die id-Form,
  /// da profiles.id immer eine UUID ist -> sonst war alles faelschlich 'web').
  String get source {
    if (sourceFromServer == 'app' || sourceFromServer == 'web') {
      return sourceFromServer!;
    }
    if ((legacyUserId ?? '').isNotEmpty || profileId.startsWith('user_')) {
      return 'app';
    }
    return 'web';
  }

  /// World label for display (v103: alle 4 Welten unterstuetzt).
  String get worldLabel {
    switch (world) {
      case 'materie':
        return 'Materie';
      case 'energie':
        return 'Energie';
      case 'vorhang':
        return 'Vorhang';
      case 'ursprung':
        return 'Ursprung';
      default:
        return 'Alle';
    }
  }
}

/// Audit Log Entry Model
class AuditLogEntry {
  final String logId;
  final String adminUsername;
  final String action;
  final String targetUsername;
  final String? oldRole;
  final String? newRole;
  final String timestamp;

  AuditLogEntry({
    required this.logId,
    required this.adminUsername,
    required this.action,
    required this.targetUsername,
    this.oldRole,
    this.newRole,
    required this.timestamp,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      logId: json['log_id'] as String? ?? json['logId'] as String? ?? '',
      adminUsername: json['admin_username'] as String? ??
          json['adminUsername'] as String? ??
          '',
      action: json['action'] as String? ?? '',
      targetUsername: json['target_username'] as String? ??
          json['targetUsername'] as String? ??
          '',
      oldRole: json['old_role'] as String? ?? json['oldRole'] as String?,
      newRole: json['new_role'] as String? ?? json['newRole'] as String?,
      timestamp: json['timestamp'] as String? ?? '',
    );
  }
}

// ════════════════════════════════════════════════════════════
// 🆕 BACKEND V16.2 ADMIN APIS - EXTENSION
// ════════════════════════════════════════════════════════════

/// Extension mit neuen Backend V16.2 Admin APIs
/// Fügt User Ban/Mute/Status, Dashboard und Analytics hinzu
///
/// ⚠️ WICHTIG: ROLLEN-PRÜFUNG
/// Alle Ban/Mute/Management-Funktionen erfordern:
/// - Root Admin Rolle (AppRoles.canManageUsers)
/// - Verifizierung über AdminState (adminStateProvider)
///
/// Bitte VOR dem Aufruf prüfen:
/// ```dart
/// final admin = ref.read(adminStateProvider(world));
/// if (!admin.isRootAdmin) {
///   // Keine Berechtigung!
///   return;
/// }
/// ```
/// YouTube-Suchergebnis fuer das Admin-Einpflege-Dialog.
class YoutubeSearchResult {
  final String videoId;
  final String title;
  final String thumbnailUrl;
  final String? channelTitle;
  const YoutubeSearchResult({
    required this.videoId,
    required this.title,
    required this.thumbnailUrl,
    this.channelTitle,
  });
  factory YoutubeSearchResult.fromJson(Map<String, dynamic> j) {
    final id = j['video_id'] as String? ?? '';
    return YoutubeSearchResult(
      videoId: id,
      title: j['title'] as String? ?? '',
      thumbnailUrl: j['thumbnail_url'] as String? ??
          (id.isNotEmpty ? 'https://img.youtube.com/vi/$id/mqdefault.jpg' : ''),
      channelTitle: j['channel_title'] as String?,
    );
  }
}

extension WorldAdminServiceV162 on WorldAdminService {
  // AUDIT-FIX A1: HMAC-Header fuer Worker verifyAdminCaller.
  static Future<Map<String, String>> get _h async =>
      WorldAdminService._adminAuthHeaders(role: 'root_admin');

  /// Ban a user. [expiresAt] is an ISO-8601 timestamp stored in admin_bans
  /// for display; Worker sets profiles.is_banned=true regardless.
  /// Null expiresAt = permanent ban (no auto-unban).
  static Future<bool> banUser({
    required String userId,
    required String reason,
    int durationHours = 24,
    String? expiresAt,
    String? adminUserId,
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/users/$userId/ban',
        body: {
          'reason': reason,
          'durationHours': durationHours,
          if (expiresAt != null) 'expires_at': expiresAt,
        },
      );
      AdminApiClient.instance.invalidateCache('/api/admin/users');
      return data['success'] as bool? ?? false;
    } on AdminApiException catch (e) {
      if (kDebugMode) debugPrint('❌ banUser: ${e.statusCode} ${e.bodySnippet}');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ banUser: $e');
      return false;
    }
  }

  static Future<bool> unbanUser(
      {required String userId, String? adminUserId}) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/users/$userId/unban',
      );
      AdminApiClient.instance.invalidateCache('/api/admin/users');
      return data['success'] as bool? ?? false;
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ unbanUser: ${e.statusCode} ${e.bodySnippet}');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ unbanUser: $e');
      return false;
    }
  }

  /// v5.44.3: Aendert die Rolle eines Users.
  /// Schreibt via Service-Role direkt in profiles.role und triggert
  /// admin_audit_log via v91-Trigger profiles_role_change_audit.
  ///
  /// [newRole] muss einer sein von:
  ///   'user', 'moderator', 'admin', 'content_editor', 'root_admin'
  ///
  /// Returns true on HTTP 200, false bei Fehler.
  static Future<bool> changeUserRole({
    required String userId,
    required String newRole,
    String? adminUsername,
  }) async {
    try {
      final data = await AdminApiClient.instance.putJson(
        '/api/admin/users/$userId/role',
        body: {
          'role': newRole,
          if (adminUsername != null) 'admin': adminUsername,
        },
      );
      if (data['success'] == true) {
        PushNotificationHelper.instance.sendToUser(
          targetUserId: userId,
          type: 'admin_role_change',
          title: 'Rolle geaendert',
          body: 'Deine Rolle wurde zu "${_prettyRoleName(newRole)}" geaendert.',
          data: {
            'action': 'role_change',
            'new_role': newRole,
            'admin': adminUsername,
          },
        ).ignore();
      }
      return data['success'] as bool? ?? false;
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ changeUserRole: ${e.statusCode} ${e.bodySnippet}');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ changeUserRole exception: $e');
      return false;
    }
  }

  /// v103 (4.5): Helper fuer User-freundliche Rollennamen in Push-Texten.
  static String _prettyRoleName(String role) {
    switch (role) {
      case 'root_admin':
      case 'root-admin':
        return 'Root-Admin';
      case 'admin':
        return 'Administrator';
      case 'content_editor':
        return 'Content-Editor';
      case 'moderator':
        return 'Moderator';
      case 'user':
        return 'Benutzer';
      default:
        return role;
    }
  }

  static Future<bool> muteUser({
    required String userId,
    required String reason,
    int durationMinutes = 60,
    String? adminUserId,
  }) async {
    try {
      await AdminApiClient.instance.postJson(
        '/api/admin/users/$userId/mute',
        body: {'reason': reason, 'durationMinutes': durationMinutes},
      );
      return true;
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ muteUser: ${e.statusCode} ${e.bodySnippet}');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ muteUser: $e');
      return false;
    }
  }

  /// v98: Hard-Delete eines Users. Loescht profile-Zeile (cascadiert)
  /// und auth.users-Zeile falls UUID. Returns true bei HTTP 200 + success.
  static Future<bool> deleteUser({
    required String userId,
    String? adminUsername,
    String? reason,
  }) async {
    try {
      final qp = reason != null && reason.isNotEmpty
          ? '?reason=${Uri.encodeQueryComponent(reason)}'
          : '';
      final data = await AdminApiClient.instance.deleteJson(
        '/api/admin/users/$userId$qp',
      );
      return data['success'] as bool? ?? false;
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ deleteUser: ${e.statusCode} ${e.bodySnippet}');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ deleteUser exception: $e');
      return false;
    }
  }

  /// v98: Sync-Endpoint. Backfillt Profile fuer auth.users und optional
  /// fuer InvisibleAuth-Sessions aus dem Client.
  static Future<Map<String, dynamic>?> syncUsers({
    List<Map<String, dynamic>>? extraUsers,
  }) async {
    try {
      final url =
          Uri.parse('${WorldAdminService._baseUrl}/api/admin/users/sync');
      final response = await http
          .post(
            url,
            headers: await _h,
            body: jsonEncode({'users': extraUsers ?? []}),
          )
          .timeout(WorldAdminService._timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ syncUsers exception: $e');
      return null;
    }
  }

  // Manual XP-Vergabe durch Admin. amount > 0 = Bonus, amount < 0 = Abzug.
  // Worker schreibt Audit-Log + sendet Push.
  // Returns: { success, new_xp, amount } oder null bei Fehler.
  static Future<Map<String, dynamic>?> grantXp({
    required String userId,
    required int amount,
    required String reason,
    String? adminUsername,
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/users/$userId/xp',
        body: {
          'amount': amount,
          'reason': reason,
          'admin': adminUsername ?? 'admin',
        },
      );
      return data;
    } on AdminApiException catch (e) {
      if (kDebugMode) debugPrint('❌ grantXp: ${e.statusCode} ${e.bodySnippet}');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ grantXp: $e');
      return null;
    }
  }

  static Future<bool> unmuteUser(
      {required String userId, String? adminUserId}) async {
    try {
      await AdminApiClient.instance.postJson(
        '/api/admin/users/$userId/unmute',
      );
      return true;
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ unmuteUser: ${e.statusCode} ${e.bodySnippet}');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ unmuteUser: $e');
      return false;
    }
  }

  /// 🆕 Check User Status (V16.2)
  static Future<Map<String, dynamic>> checkUserStatus({
    required String userId,
    String? adminUserId,
  }) async {
    try {
      // PHASE-1 FIX: HMAC-Header
      final url = Uri.parse(
          '${WorldAdminService._baseUrl}/api/admin/users/$userId/status');
      final response = await http
          .get(
            url,
            headers: await _h,
          )
          .timeout(WorldAdminService._timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'userId': userId, 'banned': false, 'muted': false};
    } catch (e) {
      return {
        'userId': userId,
        'banned': false,
        'muted': false,
        'error': e.toString()
      };
    }
  }

  /// 🆕 Get Admin Dashboard (V16.2)
  static Future<Map<String, dynamic>> getAdminDashboard(
      {String? adminUserId}) async {
    try {
      // PHASE-1 FIX: HMAC-Header
      final url =
          Uri.parse('${WorldAdminService._baseUrl}/api/admin/dashboard');
      final response = await http
          .get(
            url,
            headers: await _h,
          )
          .timeout(WorldAdminService._timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      if (response.statusCode == 403) {
        return {
          'error': 'Zugriff verweigert (403) -- ADMIN_AUTH_SECRET pruefen'
        };
      }
      return {'error': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// 🆕 Get Analytics (V16.2)
  static Future<Map<String, dynamic>> getAnalytics({
    required String realm,
    int days = 7,
    String? adminUserId,
  }) async {
    try {
      // PHASE-1 FIX: HMAC-Header
      final url = Uri.parse(
          '${WorldAdminService._baseUrl}/api/admin/analytics/$realm?days=$days');
      final response = await http
          .get(
            url,
            headers: await _h,
          )
          .timeout(WorldAdminService._timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'error': 'Failed'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ════════════════════════════════════════════════════════════
  // 🆕 ADMIN DASHBOARD ENDPOINTS (V99)
  // ════════════════════════════════════════════════════════════

  /// Get active voice calls in a world
  ///
  /// Returns list of active calls with participants, duration, etc.
  ///
  /// Example response:
  /// ```json
  /// {
  ///   "success": true,
  ///   "world": "materie",
  ///   "calls": [
  ///     {
  ///       "room_id": "politik",
  ///       "room_name": "Politik Diskussion",
  ///       "participant_count": 5,
  ///       "participants": [...],
  ///       "started_at": "2026-02-13T17:00:00.000Z",
  ///       "duration_seconds": 1234
  ///     }
  ///   ]
  /// }
  /// ```
  static Future<List<Map<String, dynamic>>> getActiveVoiceCalls(
      String world) async {
    try {
      // Use API token from ApiConfig
      final url = Uri.parse(
          '${WorldAdminService._baseUrl}/api/admin/voice-calls/$world');

      if (kDebugMode) {
        debugPrint('📊 Fetching active voice calls for: $world');
      }

      // PHASE-1 FIX: HMAC-Header (war Legacy _adminHeaders ohne HMAC)
      final response = await http
          .get(
            url,
            headers: await _h,
          )
          .timeout(WorldAdminService._timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          final calls = data['calls'] as List<dynamic>;

          if (kDebugMode) {
            debugPrint('✅ Found ${calls.length} active calls');
          }

          return calls.cast<Map<String, dynamic>>();
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        if (kDebugMode) {
          debugPrint('⚠️  ${response.statusCode}: Admin-Auth fehlt');
        }
        throw Exception('Admin-Auth required (${response.statusCode})');
      }

      if (kDebugMode) {
        debugPrint('⚠️  Failed to fetch active calls: ${response.statusCode}');
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching active calls: $e');
      }
      throw Exception('Failed to fetch active calls: $e');
    }
  }

  /// Get call history for a world
  ///
  /// Returns list of past voice calls with statistics
  ///
  /// Example response:
  /// ```json
  /// {
  ///   "success": true,
  ///   "world": "materie",
  ///   "calls": [
  ///     {
  ///       "room_id": "politik",
  ///       "started_at": "2026-02-13T16:00:00.000Z",
  ///       "ended_at": "2026-02-13T16:45:00.000Z",
  ///       "duration_seconds": 2700,
  ///       "max_participants": 8
  ///     }
  ///   ]
  /// }
  /// ```
  static Future<List<Map<String, dynamic>>> getCallHistory(
    String world, {
    int limit = 50,
  }) async {
    try {
      final url = Uri.parse(
          '${WorldAdminService._baseUrl}/api/admin/call-history/$world?limit=$limit');

      if (kDebugMode) {
        debugPrint('📚 Fetching call history for: $world (limit: $limit)');
      }

      // PHASE-1 FIX: HMAC-Header
      final response = await http
          .get(
            url,
            headers: await _h,
          )
          .timeout(WorldAdminService._timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          final calls = data['calls'] as List<dynamic>;

          if (kDebugMode) {
            debugPrint('✅ Found ${calls.length} past calls');
          }

          return calls.cast<Map<String, dynamic>>();
        }
      } else if (response.statusCode == 401) {
        if (kDebugMode) {
          debugPrint('⚠️  Unauthorized: Invalid API token');
        }
        throw Exception('Unauthorized: Invalid API token');
      }

      if (kDebugMode) {
        debugPrint('⚠️  Failed to fetch call history: ${response.statusCode}');
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching call history: $e');
      }
      throw Exception('Failed to fetch call history: $e');
    }
  }

  /// Get user profile with activity stats
  ///
  /// Returns detailed user information including:
  /// - Basic profile (username, role, avatar)
  /// - Voice call statistics (total calls, minutes)
  /// - Moderation history (warnings, kicks, bans)
  ///
  /// Example response:
  /// ```json
  /// {
  ///   "success": true,
  ///   "user": {
  ///     "user_id": "materie_Weltenbibliothek",
  ///     "username": "Weltenbibliothek",
  ///     "role": "root_admin",
  ///     "total_calls": 45,
  ///     "total_minutes": 3240,
  ///     "warnings": 0,
  ///     "kicks": 0,
  ///     "bans": 0
  ///   }
  /// }
  /// ```
  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final url = Uri.parse(
          '${WorldAdminService._baseUrl}/api/admin/user-profile/$userId');

      if (kDebugMode) {
        debugPrint('👤 Fetching user profile for: $userId');
      }

      // PHASE-1 FIX: HMAC-Header
      final response = await http
          .get(
            url,
            headers: await _h,
          )
          .timeout(WorldAdminService._timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          final user = data['user'] as Map<String, dynamic>;

          if (kDebugMode) {
            debugPrint('✅ User profile loaded: ${user['username']}');
          }

          return user;
        }
      } else if (response.statusCode == 404) {
        if (kDebugMode) {
          debugPrint('⚠️  User not found: $userId');
        }
        throw Exception('User not found');
      } else if (response.statusCode == 401) {
        if (kDebugMode) {
          debugPrint('⚠️  Unauthorized: Invalid API token');
        }
        throw Exception('Unauthorized: Invalid API token');
      }

      if (kDebugMode) {
        debugPrint('⚠️  Failed to fetch user profile: ${response.statusCode}');
      }

      throw Exception('Failed to fetch user profile');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching user profile: $e');
      }
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  // ════════════════════════════════════════════════════════════
  // v115 Feature B: Verwarnungen
  // ════════════════════════════════════════════════════════════

  /// Liefert alle Verwarnungen eines Users. Returns leere Liste bei Fehler.
  static Future<List<Map<String, dynamic>>> getWarnings(String userId) async {
    try {
      final data = await AdminApiClient.instance
          .getJson('/api/admin/users/$userId/warnings');
      final list = (data['warnings'] as List?) ?? const [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ getWarnings: ${e.statusCode} ${e.bodySnippet}');
      return const [];
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getWarnings: $e');
      return const [];
    }
  }

  /// Verwarnt einen User. Bei der 3. Verwarnung erfolgt automatischer Ban.
  /// Returns { success, warning_count, auto_banned } oder null bei Fehler.
  static Future<Map<String, dynamic>?> warnUser({
    required String userId,
    required String reason,
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/users/$userId/warn',
        body: {'reason': reason},
      );
      AdminApiClient.instance.invalidateCache('/api/admin/users');
      return data;
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ warnUser: ${e.statusCode} ${e.bodySnippet}');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ warnUser: $e');
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════
  // v115 Feature C: Admin-Notizen
  // ════════════════════════════════════════════════════════════

  /// Liefert alle internen Notizen zu einem User.
  static Future<List<Map<String, dynamic>>> getNotes(String userId) async {
    try {
      final data = await AdminApiClient.instance
          .getJson('/api/admin/users/$userId/notes');
      final list = (data['notes'] as List?) ?? const [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ getNotes: ${e.statusCode} ${e.bodySnippet}');
      return const [];
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getNotes: $e');
      return const [];
    }
  }

  /// Fuegt eine interne Notiz zu einem User hinzu.
  static Future<bool> addNote({
    required String userId,
    required String note,
  }) async {
    try {
      await AdminApiClient.instance.postJson(
        '/api/admin/users/$userId/notes',
        body: {'note': note},
      );
      return true;
    } on AdminApiException catch (e) {
      if (kDebugMode) debugPrint('❌ addNote: ${e.statusCode} ${e.bodySnippet}');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ addNote: $e');
      return false;
    }
  }

  /// Loescht eine interne Notiz.
  static Future<bool> deleteNote({
    required String userId,
    required String noteId,
  }) async {
    try {
      await AdminApiClient.instance
          .deleteJson('/api/admin/users/$userId/notes/$noteId');
      return true;
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ deleteNote: ${e.statusCode} ${e.bodySnippet}');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ deleteNote: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════
  // v116: Admin-gesteuerte Modul-Freischaltung / -Sperre
  // ════════════════════════════════════════════════════════════

  /// Liefert alle Modul-Overrides (grant/block) fuer einen User.
  static Future<List<Map<String, dynamic>>> getModuleAccess(
      String userId) async {
    try {
      final data = await AdminApiClient.instance
          .getJson('/api/admin/users/$userId/module-access');
      final list = (data['overrides'] as List?) ?? const [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ getModuleAccess: ${e.statusCode} ${e.bodySnippet}');
      return const [];
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getModuleAccess: $e');
      return const [];
    }
  }

  /// Setzt einen Modul-Override (Force-Unlock oder Force-Block).
  /// [isGranted]=true → Modul immer freigeschaltet, unabhaengig von Voraussetzungen.
  /// [isGranted]=false → Modul gesperrt, auch wenn Voraussetzungen erfuellt.
  static Future<bool> setModuleAccess({
    required String userId,
    required String moduleCode,
    required String moduleType,
    required bool isGranted,
    String? reason,
  }) async {
    try {
      await AdminApiClient.instance.postJson(
        '/api/admin/users/$userId/module-access',
        body: {
          'module_code': moduleCode,
          'module_type': moduleType,
          'is_granted': isGranted,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      return true;
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ setModuleAccess: ${e.statusCode} ${e.bodySnippet}');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ setModuleAccess: $e');
      return false;
    }
  }

  /// Setzt is_granted fuer ALLE Module beider Welten (vorhang + ursprung).
  /// v130: "Beide Welten" Bulk-Aktion.
  static Future<(bool, int)> batchGrantModuleAccess({
    required String userId,
    required bool isGranted,
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/users/$userId/module-access/batch-all',
        body: {'is_granted': isGranted},
      );
      final count = (data['count'] as num?)?.toInt() ?? 0;
      return (true, count);
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint(
            '❌ batchGrantModuleAccess: ${e.statusCode} ${e.bodySnippet}');
      return (false, 0);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ batchGrantModuleAccess: $e');
      return (false, 0);
    }
  }

  /// Entfernt einen Modul-Override; der User faellt zurueck auf die normale
  /// Prerequisite-Logik.
  static Future<bool> removeModuleAccess({
    required String userId,
    required String moduleCode,
  }) async {
    try {
      await AdminApiClient.instance.postJson(
        '/api/admin/users/$userId/module-access',
        body: {'module_code': moduleCode, 'action': 'remove'},
      );
      return true;
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ removeModuleAccess: ${e.statusCode} ${e.bodySnippet}');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ removeModuleAccess: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════
  // v128 (Task 3): MODUL-WERKSTATT (KI-gestuetzte Modul-Erstellung)
  // ════════════════════════════════════════════════════════════

  /// Liefert 3-5 KI-Themenvorschlaege fuer ein Welt-Modul.
  /// [hint] kann leer sein -> KI schlaegt frei vor.
  static Future<List<String>> getModuleTopicSuggestions({
    required String world,
    String hint = '',
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/module-workshop/topics',
        body: {'world': world, 'hint': hint},
      );
      final list = (data['suggestions'] as List?) ?? const [];
      return list.map((e) => e.toString()).toList();
    } on AdminApiException catch (e) {
      if (kDebugMode) {
        debugPrint(
            'getModuleTopicSuggestions: ${e.statusCode} ${e.bodySnippet}');
      }
      return const [];
    } catch (e) {
      if (kDebugMode) debugPrint('getModuleTopicSuggestions: $e');
      return const [];
    }
  }

  /// Generiert ein vollstaendiges Modul (title/subtitle/branch/theory/case/exercise/xp).
  /// Returns Map oder null bei Fehler.
  static Future<Map<String, dynamic>?> generateModule({
    required String world,
    required String topic,
    String? branch,
    bool newTheme = false,
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/module-workshop/generate',
        body: {
          'world': world,
          'topic': topic,
          if (branch != null && branch.isNotEmpty) 'branch': branch,
          if (newTheme) 'new_theme': true,
        },
        timeout: const Duration(seconds: 45),
      );
      return (data['module'] as Map?)?.cast<String, dynamic>();
    } on AdminApiException catch (e) {
      if (kDebugMode) {
        debugPrint('generateModule: ${e.statusCode} ${e.bodySnippet}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('generateModule: $e');
      return null;
    }
  }

  /// Erweitert/verbessert ein bestehendes Modul via KI.
  static Future<Map<String, dynamic>?> expandModule({
    required String world,
    required Map<String, dynamic> current,
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/module-workshop/expand',
        body: {'world': world, 'current': current},
        timeout: const Duration(seconds: 45),
      );
      return (data['module'] as Map?)?.cast<String, dynamic>();
    } on AdminApiException catch (e) {
      if (kDebugMode) {
        debugPrint('expandModule: ${e.statusCode} ${e.bodySnippet}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('expandModule: $e');
      return null;
    }
  }

  /// Speichert ein neues oder bestehendes Modul.
  /// [editCode] = vorhandener module_code zum Editieren, sonst null = neu.
  /// Returns Map mit { success, module_code, action, errors? }.
  static Future<Map<String, dynamic>> saveModule({
    required String world,
    required Map<String, dynamic> module,
    String? editCode,
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/module-workshop/save',
        body: {
          'world': world,
          'module': module,
          if (editCode != null && editCode.isNotEmpty) 'edit_code': editCode,
        },
      );
      return Map<String, dynamic>.from(data);
    } on AdminApiException catch (e) {
      if (kDebugMode) {
        debugPrint('saveModule: ${e.statusCode} ${e.bodySnippet}');
      }
      // Body kann JSON mit errors-Liste enthalten (Inhalts-Check 400).
      try {
        final body = e.bodySnippet;
        if (body.contains('errors')) {
          return {
            'success': false,
            'errors': [body]
          };
        }
      } catch (_) {}
      return {
        'success': false,
        'errors': ['HTTP ${e.statusCode}']
      };
    } catch (e) {
      if (kDebugMode) debugPrint('saveModule: $e');
      return {
        'success': false,
        'errors': [e.toString()]
      };
    }
  }

  /// Liefert alle Module einer Welt fuer die Edit-Ansicht (inkl. theory_content).
  static Future<List<Map<String, dynamic>>> listWorkshopModules({
    required String world,
  }) async {
    try {
      final data = await AdminApiClient.instance
          .getJson('/api/admin/module-workshop/list?world=$world');
      final list = (data['modules'] as List?) ?? const [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on AdminApiException catch (e) {
      if (kDebugMode) {
        debugPrint('listWorkshopModules: ${e.statusCode} ${e.bodySnippet}');
      }
      return const [];
    } catch (e) {
      if (kDebugMode) debugPrint('listWorkshopModules: $e');
      return const [];
    }
  }

  /// W2: Loescht ein Modul endgueltig (nur Root-Admin serverseitig).
  static Future<bool> deleteWorkshopModule({
    required String world,
    required String moduleCode,
  }) async {
    try {
      final data = await AdminApiClient.instance.deleteJson(
        '/api/admin/module-workshop/module?world=$world&code=${Uri.encodeQueryComponent(moduleCode)}',
      );
      return data['success'] as bool? ?? false;
    } catch (e) {
      if (kDebugMode) debugPrint('deleteWorkshopModule: $e');
      return false;
    }
  }

  /// W2: Speichert eine neue Reihenfolge (branch_order) fuer mehrere Module.
  static Future<bool> reorderWorkshopModules({
    required String world,
    required List<Map<String, dynamic>> order, // [{module_code, branch_order}]
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/module-workshop/reorder',
        body: {'world': world, 'order': order},
      );
      return data['success'] as bool? ?? false;
    } catch (e) {
      if (kDebugMode) debugPrint('reorderWorkshopModules: $e');
      return false;
    }
  }

  /// W3: Generiert ein Cover-Bild per KI. Returns cover_image_url.
  static Future<String?> generateModuleCover({
    required String world,
    required String title,
    String? hint,
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/module-workshop/cover',
        body: {'world': world, 'title': title, if (hint != null) 'hint': hint},
        timeout: const Duration(seconds: 45),
      );
      if (data['success'] == true) return data['cover_image_url'] as String?;
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('generateModuleCover: $e');
      return null;
    }
  }

  /// W5: Anzahl vorhandener Versions-Snapshots fuer ein Modul.
  static Future<int> getModuleVersionCount({
    required String world,
    required String moduleCode,
  }) async {
    try {
      final data = await AdminApiClient.instance.getJson(
        '/api/admin/module-workshop/versions?world=$world&code=${Uri.encodeQueryComponent(moduleCode)}',
      );
      final list = (data['versions'] as List?) ?? const [];
      return list.length;
    } catch (e) {
      if (kDebugMode) debugPrint('getModuleVersionCount: $e');
      return 0;
    }
  }

  /// W5: Stellt die letzte Version eines Moduls wieder her.
  static Future<bool> undoModule({
    required String world,
    required String moduleCode,
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/module-workshop/undo',
        body: {'world': world, 'code': moduleCode},
      );
      return data['success'] as bool? ?? false;
    } catch (e) {
      if (kDebugMode) debugPrint('undoModule: $e');
      return false;
    }
  }

  /// W4: Uebersetzt ein Modul in eine Zielsprache. Returns uebersetztes Modul.
  static Future<Map<String, dynamic>?> translateModule({
    required Map<String, dynamic> module,
    required String targetLang,
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/module-workshop/translate',
        body: {'module': module, 'target_lang': targetLang},
        timeout: const Duration(seconds: 45),
      );
      if (data['success'] == true && data['module'] != null) {
        return Map<String, dynamic>.from(data['module'] as Map);
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('translateModule: $e');
      return null;
    }
  }

  /// W7: Liest die Auto-Scan-Konfiguration ({enabled, worlds}).
  static Future<Map<String, dynamic>?> getScanConfig() async {
    try {
      final data = await AdminApiClient.instance
          .getJson('/api/admin/module-workshop/scan-config');
      if (data['config'] != null) {
        return Map<String, dynamic>.from(data['config'] as Map);
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('getScanConfig: $e');
      return null;
    }
  }

  /// W7: Setzt die Auto-Scan-Konfiguration.
  static Future<bool> setScanConfig(
      {bool? enabled, List<String>? worlds}) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/module-workshop/scan-config',
        body: {
          if (enabled != null) 'enabled': enabled,
          if (worlds != null) 'worlds': worlds,
        },
      );
      return data['success'] as bool? ?? false;
    } catch (e) {
      if (kDebugMode) debugPrint('setScanConfig: $e');
      return false;
    }
  }

  // ── Modul-Werkstatt-Automatik (Vorschlaege A/B/C/D) ─────────────────

  /// Startet einen manuellen Scan: KI analysiert den Modul-Bestand und
  /// erzeugt Vorschlaege (neue Module / Verbesserungen / Qualitaets-Findings).
  /// [modes] = Teilmenge von ['new','improve','quality'].
  /// Returns Map { success, created: { new, improve, quality } } oder null.
  static Future<Map<String, dynamic>?> scanModuleSuggestions({
    required String world,
    required List<String> modes,
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/module-workshop/scan',
        body: {'world': world, 'modes': modes},
        timeout: const Duration(seconds: 90),
      );
      return Map<String, dynamic>.from(data);
    } on AdminApiException catch (e) {
      if (kDebugMode) {
        debugPrint('scanModuleSuggestions: ${e.statusCode} ${e.bodySnippet}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('scanModuleSuggestions: $e');
      return null;
    }
  }

  /// Liefert offene (oder beliebige) Modul-Vorschlaege einer Welt.
  static Future<List<Map<String, dynamic>>> getModuleSuggestions({
    required String world,
    String status = 'pending',
  }) async {
    try {
      final data = await AdminApiClient.instance.getJson(
          '/api/admin/module-workshop/suggestions?world=$world&status=$status');
      final list = (data['suggestions'] as List?) ?? const [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on AdminApiException catch (e) {
      if (kDebugMode) {
        debugPrint('getModuleSuggestions: ${e.statusCode} ${e.bodySnippet}');
      }
      return const [];
    } catch (e) {
      if (kDebugMode) debugPrint('getModuleSuggestions: $e');
      return const [];
    }
  }

  /// Nimmt einen Vorschlag an (Root-Admin only). Bei new/improve wird das
  /// Modul live geschrieben, bei quality wird das Finding als erledigt markiert.
  static Future<Map<String, dynamic>> acceptModuleSuggestion(String id) async {
    try {
      final data = await AdminApiClient.instance
          .postJson('/api/admin/module-workshop/suggestions/$id/accept');
      return Map<String, dynamic>.from(data);
    } on AdminApiException catch (e) {
      if (kDebugMode) {
        debugPrint('acceptModuleSuggestion: ${e.statusCode} ${e.bodySnippet}');
      }
      return {'success': false, 'error': 'HTTP ${e.statusCode}'};
    } catch (e) {
      if (kDebugMode) debugPrint('acceptModuleSuggestion: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Lehnt einen Vorschlag ab.
  static Future<bool> rejectModuleSuggestion(String id) async {
    try {
      await AdminApiClient.instance
          .postJson('/api/admin/module-workshop/suggestions/$id/reject');
      return true;
    } on AdminApiException catch (e) {
      if (kDebugMode) {
        debugPrint('rejectModuleSuggestion: ${e.statusCode} ${e.bodySnippet}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('rejectModuleSuggestion: $e');
      return false;
    }
  }

  // ── Tool-Werkstatt (T1-T4) ─────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getTools(String world) async {
    try {
      final data = await AdminApiClient.instance
          .getJson('/api/admin/tools?world=$world');
      return ((data['tools'] as List?) ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('getTools: $e');
      return const [];
    }
  }

  static Future<bool> saveTool(Map<String, dynamic> tool) async {
    try {
      final data = await AdminApiClient.instance
          .postJson('/api/admin/tools', body: tool);
      return data['success'] as bool? ?? false;
    } catch (e) {
      if (kDebugMode) debugPrint('saveTool: $e');
      return false;
    }
  }

  static Future<bool> deleteTool(String id) async {
    try {
      final data =
          await AdminApiClient.instance.deleteJson('/api/admin/tools?id=$id');
      return data['success'] as bool? ?? false;
    } catch (e) {
      if (kDebugMode) debugPrint('deleteTool: $e');
      return false;
    }
  }

  /// KI-Vorschlag im Erstellen/Aendern-Formular: {title, description}.
  static Future<Map<String, dynamic>?> getToolIdea({
    required String world,
    required String mode, // 'new' | 'extend'
    String? target,
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/tools/idea',
        body: {
          'world': world,
          'mode': mode,
          if (target != null) 'target': target
        },
        timeout: const Duration(seconds: 30),
      );
      if (data['success'] == true) return data;
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('getToolIdea: $e');
      return null;
    }
  }

  /// Batch2b: KI-Komplett-Spezifikation aus einem Stichwort/Titel generieren
  /// (Zweck, Eingaben, Logik, UI, Beispiel, Edge-Cases). Liefert Markdown.
  static Future<String?> toolSpec({
    required String world,
    required String title,
    String? template,
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/module-workshop/tool-spec',
        body: {
          'world': world,
          'title': title,
          if (template != null && template.isNotEmpty) 'template': template,
        },
        timeout: const Duration(seconds: 45),
      );
      final spec = data['spec'];
      return (spec is String && spec.isNotEmpty) ? spec : null;
    } catch (e) {
      if (kDebugMode) debugPrint('toolSpec: $e');
      return null;
    }
  }

  static Future<int> scanTools(String world) async {
    try {
      final data = await AdminApiClient.instance.postJson(
          '/api/admin/tools/scan',
          body: {'world': world},
          timeout: const Duration(seconds: 60));
      return (data['created'] as num?)?.toInt() ?? 0;
    } catch (e) {
      if (kDebugMode) debugPrint('scanTools: $e');
      return 0;
    }
  }

  static Future<List<Map<String, dynamic>>> getToolSuggestions(
      String world) async {
    try {
      final data = await AdminApiClient.instance
          .getJson('/api/admin/tools/suggestions?world=$world');
      return ((data['suggestions'] as List?) ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('getToolSuggestions: $e');
      return const [];
    }
  }

  static Future<Map<String, dynamic>> acceptToolSuggestion(String id) async {
    try {
      final data = await AdminApiClient.instance
          .postJson('/api/admin/tools/suggestions/$id/accept', body: {});
      return Map<String, dynamic>.from(data);
    } catch (e) {
      if (kDebugMode) debugPrint('acceptToolSuggestion: $e');
      return {'success': false};
    }
  }

  static Future<bool> rejectToolSuggestion(String id) async {
    try {
      final data = await AdminApiClient.instance
          .postJson('/api/admin/tools/suggestions/$id/reject', body: {});
      return data['success'] as bool? ?? false;
    } catch (e) {
      if (kDebugMode) debugPrint('rejectToolSuggestion: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getToolRequests(
      String world) async {
    try {
      final data = await AdminApiClient.instance
          .getJson('/api/admin/tools/requests?world=$world');
      return ((data['requests'] as List?) ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('getToolRequests: $e');
      return const [];
    }
  }

  /// Stellt eine Tool-Anfrage (LOGIK-Modul) -> GitHub-Issue-Bruecke.
  /// Returns Map { success, auto_created, issue_url?, prefill_url? }.
  static Future<Map<String, dynamic>> requestTool({
    required String title,
    required String description,
    String? world,
    String mode = 'new', // 'new' | 'extend'
    String? target, // bei extend: Name des bestehenden Tools
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/module-workshop/tool-request',
        body: {
          'title': title,
          'description': description,
          if (world != null) 'world': world,
          'mode': mode,
          if (target != null && target.isNotEmpty) 'target': target,
        },
        // KI-Spec + Issue-Erstellung dauert laenger als die Standard-12s.
        timeout: const Duration(seconds: 35),
      );
      return Map<String, dynamic>.from(data);
    } on AdminApiException catch (e) {
      if (kDebugMode) {
        debugPrint('requestTool: ${e.statusCode} ${e.bodySnippet}');
      }
      return {'success': false, 'error': 'HTTP ${e.statusCode}'};
    } catch (e) {
      if (kDebugMode) debugPrint('requestTool: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ── Tool-Freigaben (Root-Admin gibt Admin-Anfragen frei) ──────────────
  /// Offene Tool-Bau-/Erweiterungs-Anfragen einfacher Admins (pending_approval).
  /// Nur fuer Root-Admin sinnvoll.
  static Future<List<Map<String, dynamic>>> getToolApprovals(
      String world) async {
    try {
      final data = await AdminApiClient.instance
          .getJson('/api/admin/tools/approvals?world=$world');
      return ((data['approvals'] as List?) ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('getToolApprovals: $e');
      return const [];
    }
  }

  /// Root-Admin gibt eine Admin-Anfrage frei -> Issue + Auto-Build.
  static Future<Map<String, dynamic>> approveToolRequest(String id) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/tools/approvals/$id/approve',
        body: {},
        timeout: const Duration(seconds: 30),
      );
      return Map<String, dynamic>.from(data);
    } catch (e) {
      if (kDebugMode) debugPrint('approveToolRequest: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Root-Admin lehnt eine Admin-Anfrage ab.
  static Future<Map<String, dynamic>> rejectToolRequest(String id) async {
    try {
      final data = await AdminApiClient.instance
          .postJson('/api/admin/tools/approvals/$id/reject', body: {});
      return Map<String, dynamic>.from(data);
    } catch (e) {
      if (kDebugMode) debugPrint('rejectToolRequest: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ── Inhalte-Verwaltung (Materie/Energie Tool-Inhalte) ─────────────────
  static Future<List<Map<String, dynamic>>> getContentTables(
      String world) async {
    try {
      final data = await AdminApiClient.instance
          .getJson('/api/admin/content/tables?world=$world');
      final list = (data['tables'] as List?) ?? const [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('getContentTables: $e');
      return const [];
    }
  }

  static Future<Map<String, dynamic>> getContentRows({
    required String world,
    required String table,
  }) async {
    try {
      final data = await AdminApiClient.instance
          .getJson('/api/admin/content/rows?world=$world&table=$table');
      return {
        'rows': ((data['rows'] as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        'columns': ((data['columns'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      };
    } catch (e) {
      if (kDebugMode) debugPrint('getContentRows: $e');
      return {'rows': <Map<String, dynamic>>[], 'columns': <String>[]};
    }
  }

  static Future<bool> saveContentRow({
    required String world,
    required String table,
    required Map<String, dynamic> row,
    dynamic id,
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/content/row',
        body: {
          'world': world,
          'table': table,
          'row': row,
          if (id != null) 'id': id,
        },
      );
      return data['success'] as bool? ?? false;
    } catch (e) {
      if (kDebugMode) debugPrint('saveContentRow: $e');
      return false;
    }
  }

  static Future<bool> deleteContentRow({
    required String world,
    required String table,
    required dynamic id,
  }) async {
    try {
      final data = await AdminApiClient.instance.deleteJson(
          '/api/admin/content/row?world=$world&table=$table&id=${Uri.encodeQueryComponent('$id')}');
      return data['success'] as bool? ?? false;
    } catch (e) {
      if (kDebugMode) debugPrint('deleteContentRow: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════
  // v115 Feature E: Moderations-Queue (User-Reports)
  // ════════════════════════════════════════════════════════════

  /// Liefert offene User-Reports + Counts. status: open|reviewing|resolved|
  /// dismissed|all. Returns { reports, counts, by_type } oder null bei Fehler.
  static Future<Map<String, dynamic>?> getReports({
    String status = 'open',
    int limit = 50,
  }) async {
    try {
      final data = await AdminApiClient.instance
          .getJson('/api/admin/reports?status=$status&limit=$limit');
      return data;
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ getReports: ${e.statusCode} ${e.bodySnippet}');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getReports: $e');
      return null;
    }
  }

  /// Setzt den Status eines Reports (open|reviewing|resolved|dismissed).
  static Future<bool> updateReport({
    required String reportId,
    required String status,
    String? resolutionNote,
  }) async {
    try {
      await AdminApiClient.instance.patchJson(
        '/api/admin/reports/$reportId',
        body: {
          'status': status,
          if (resolutionNote != null) 'resolution_note': resolutionNote,
        },
      );
      return true;
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ updateReport: ${e.statusCode} ${e.bodySnippet}');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ updateReport: $e');
      return false;
    }
  }

  /// Loescht eine einzelne Meldung/Report. NUR root_admin (Worker prueft Rolle).
  static Future<bool> deleteReport(String reportId,
      {String role = 'root_admin'}) async {
    try {
      await AdminApiClient.instance
          .deleteJson('/api/admin/reports/$reportId', role: role);
      return true;
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ deleteReport: ${e.statusCode} ${e.bodySnippet}');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ deleteReport: $e');
      return false;
    }
  }

  /// Loescht ALLE Meldungen (optional gefiltert nach status). NUR root_admin.
  static Future<bool> clearReports(
      {String? status, String role = 'root_admin'}) async {
    try {
      final q = (status != null && status != 'all') ? '&status=$status' : '';
      await AdminApiClient.instance
          .deleteJson('/api/admin/reports?all=true$q', role: role);
      return true;
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ clearReports: ${e.statusCode} ${e.bodySnippet}');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ clearReports: $e');
      return false;
    }
  }

  /// Loescht einen einzelnen Audit-/Log-Eintrag (log_id, z.B. "audit_<uuid>").
  /// NUR root_admin. edit_/del_-Eintraege (Chat-Historie) sind nicht loeschbar.
  static Future<bool> deleteAuditEntry({
    required String world,
    required String logId,
    String role = 'root_admin',
  }) async {
    try {
      await AdminApiClient.instance.deleteJson(
        '/api/admin/audit/$world?id=${Uri.encodeQueryComponent(logId)}',
        role: role,
      );
      return true;
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ deleteAuditEntry: ${e.statusCode} ${e.bodySnippet}');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ deleteAuditEntry: $e');
      return false;
    }
  }

  /// Loescht ALLE Audit-/Log-Eintraege (world!='all' -> nur diese Welt +
  /// welt-lose). NUR root_admin.
  static Future<bool> clearAuditLog({
    required String world,
    String role = 'root_admin',
  }) async {
    try {
      await AdminApiClient.instance
          .deleteJson('/api/admin/audit/$world?all=true', role: role);
      return true;
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ clearAuditLog: ${e.statusCode} ${e.bodySnippet}');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ clearAuditLog: $e');
      return false;
    }
  }

  /// Liest app_config (Update-Versionskonfiguration). Nur root_admin.
  /// Returns Liste der Plattform-Zeilen (android, ios).
  static Future<List<Map<String, dynamic>>?> getAppConfig() async {
    try {
      final data =
          await AdminApiClient.instance.getJson('/api/admin/app-config');
      final rows = data['rows'];
      if (rows is List) {
        return rows.cast<Map<String, dynamic>>();
      }
      return [];
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ getAppConfig: ${e.statusCode} ${e.bodySnippet}');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getAppConfig: $e');
      return null;
    }
  }

  /// Aktualisiert app_config-Felder fuer eine Plattform.
  /// [updates] darf latest_version, min_version, apk_download_url,
  /// changelog, patch_changelog, release_notes_url enthalten.
  static Future<bool> updateAppConfig({
    required String platform,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final data = await AdminApiClient.instance.patchJson(
        '/api/admin/app-config',
        body: {'platform': platform, ...updates},
      );
      return data['success'] as bool? ?? false;
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ updateAppConfig: ${e.statusCode} ${e.bodySnippet}');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ updateAppConfig: $e');
      return false;
    }
  }

  /// Laedt vollstaendiges Nutzerprofil mit Modul-Fortschritt, Warnungen
  /// und letzten Admin-Aktionen. Returns null bei Fehler/404.
  static Future<Map<String, dynamic>?> getUserDetail(String userId) async {
    try {
      final data = await AdminApiClient.instance
          .getJson('/api/admin/users/$userId/detail');
      return data;
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ getUserDetail: ${e.statusCode} ${e.bodySnippet}');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getUserDetail: $e');
      return null;
    }
  }

  /// Sendet eine Push-Benachrichtigung direkt an einen einzelnen Nutzer.
  /// [recipient] kann ein Benutzername ODER ein Klarname sein -- der Worker
  /// loest beides auf. Returnt (ok, fehlermeldung?) -- bei Mehrdeutigkeit
  /// enthaelt die Meldung die Kandidaten.
  static Future<(bool, String?)> sendDirectPush({
    String? userId,
    String? username,
    required String title,
    required String body,
    String type = 'admin_message',
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/push/user',
        body: {
          if (userId != null) 'userId': userId,
          if (username != null) 'username': username,
          'title': title,
          'body': body,
          'type': type,
        },
      );
      return ((data['success'] as bool? ?? false), null);
    } on AdminApiException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ sendDirectPush: ${e.statusCode} ${e.bodySnippet}');
      }
      // Server-Fehlermeldung extrahieren (z.B. Mehrdeutigkeit/nicht gefunden).
      String? msg;
      try {
        final m = jsonDecode(e.bodySnippet) as Map<String, dynamic>;
        msg = m['error']?.toString();
      } catch (_) {}
      return (false, msg);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ sendDirectPush: $e');
      return (false, null);
    }
  }

  /// Loescht Push-Eintraege aus der notification_queue (raeumt die Zaehler).
  /// [scope] = 'failed' | 'pending' | 'all' (sent+failed) |
  ///           'everything' (alle drei) | 'broadcast'.
  static Future<bool> clearPushQueue({String scope = 'failed'}) async {
    try {
      await AdminApiClient.instance
          .deleteJson('/api/admin/push/history?scope=$scope');
      return true;
    } on AdminApiException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ clearPushQueue: ${e.statusCode} ${e.bodySnippet}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ clearPushQueue: $e');
      return false;
    }
  }

  /// Laedt alle Artikel (global, optional gefiltert nach [world] und [status]).
  /// [status] ∈ 'all'|'published'|'unpublished'
  static Future<List<Map<String, dynamic>>?> getArticles({
    String? world,
    String status = 'all',
    int limit = 100,
  }) async {
    try {
      final qp = <String, String>{'status': status, 'limit': '$limit'};
      if (world != null) qp['world'] = world;
      final data = await AdminApiClient.instance.getJson(
        '/api/admin/articles?${Uri(queryParameters: qp).query}',
      );
      final articles = data['articles'];
      if (articles is List) return articles.cast<Map<String, dynamic>>();
      return [];
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ getArticles: ${e.statusCode} ${e.bodySnippet}');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getArticles: $e');
      return null;
    }
  }

  /// Aktualisiert Felder eines Artikels. [fields] darf
  /// title, content, excerpt, is_published, is_featured enthalten.
  static Future<bool> updateArticle({
    required String articleId,
    required Map<String, dynamic> fields,
  }) async {
    try {
      final data = await AdminApiClient.instance.patchJson(
        '/api/admin/articles/$articleId',
        body: fields,
      );
      return data['success'] as bool? ?? false;
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ updateArticle: ${e.statusCode} ${e.bodySnippet}');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ updateArticle: $e');
      return false;
    }
  }

  // ── B2: KI-MODERATION ─────────────────────────────────────────────────────

  /// Klassifiziert eine Meldung per KI. Liefert {severity, action, summary}.
  static Future<Map<String, dynamic>?> triageReport({
    required String title,
    String? body,
    String? type,
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/reports/triage',
        body: {
          'title': title,
          if (body != null && body.isNotEmpty) 'body': body,
          if (type != null) 'type': type,
        },
      );
      if (data['success'] == true) return data;
      return null;
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ triageReport: ${e.statusCode} ${e.bodySnippet}');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ triageReport: $e');
      return null;
    }
  }

  // ── B3: KI-ARTIKEL-WERKSTATT ──────────────────────────────────────────────

  /// Generiert einen kompletten Artikel-Entwurf aus einem Thema.
  static Future<Map<String, dynamic>?> generateArticle({
    required String topic,
    required String world,
  }) async {
    return _articleWorkshop('generate', {'topic': topic, 'world': world});
  }

  /// Baut einen bestehenden Artikel-Entwurf per KI aus.
  static Future<Map<String, dynamic>?> expandArticle({
    required String title,
    required String content,
    required String world,
  }) async {
    return _articleWorkshop(
        'expand', {'title': title, 'content': content, 'world': world});
  }

  /// Speichert/veroeffentlicht einen Artikel (neu oder Update via editId).
  static Future<Map<String, dynamic>?> saveArticle({
    required String title,
    required String content,
    required String world,
    String? excerpt,
    String? category,
    List<String>? tags,
    bool isPublished = true,
    String? editId,
  }) async {
    return _articleWorkshop('save', {
      'title': title,
      'content': content,
      'world': world,
      if (excerpt != null) 'excerpt': excerpt,
      if (category != null) 'category': category,
      if (tags != null) 'tags': tags,
      'is_published': isPublished,
      if (editId != null) 'edit_id': editId,
    });
  }

  static Future<Map<String, dynamic>?> _articleWorkshop(
      String action, Map<String, dynamic> body) async {
    try {
      final data = await AdminApiClient.instance.postJson(
          '/api/admin/article-workshop/$action',
          body: body,
          timeout: const Duration(seconds: 50));
      if (data['success'] == true) return data;
      return null;
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint(
            '❌ articleWorkshop/$action: ${e.statusCode} ${e.bodySnippet}');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ articleWorkshop/$action: $e');
      return null;
    }
  }

  // ── VIDEO-ARCHIV (Mediathek) ──────────────────────────────────────────────

  /// Laedt Videos fuer das Admin-Review (alle Status oder gefiltert).
  /// [status] in 'all'|'pending'|'confirmed'|'rejected'.
  static Future<List<Map<String, dynamic>>?> getArchiveVideos({
    String? world,
    String status = 'all',
    int limit = 200,
  }) async {
    try {
      final qp = <String, String>{'status': status, 'limit': '$limit'};
      if (world != null) qp['world'] = world;
      final data = await AdminApiClient.instance.getJson(
        '/api/admin/videos?${Uri(queryParameters: qp).query}',
      );
      final videos = data['videos'];
      if (videos is List) return videos.cast<Map<String, dynamic>>();
      return [];
    } on AdminApiException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ getArchiveVideos: ${e.statusCode} ${e.bodySnippet}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getArchiveVideos: $e');
      return null;
    }
  }

  /// Pflegt ein YouTube-Video ein. [youtubeUrl] darf URL oder reine ID sein.
  /// Titel/Thumbnail werden serverseitig best-effort via oEmbed gefuellt.
  static Future<Map<String, dynamic>?> createArchiveVideo({
    required String youtubeUrl,
    required List<String> worlds,
    String? category,
    String? rawTitle,
    String status = 'confirmed',
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/videos',
        body: {
          'youtube_url': youtubeUrl,
          'worlds': worlds,
          if (category != null && category.isNotEmpty) 'category': category,
          if (rawTitle != null && rawTitle.isNotEmpty) 'raw_title': rawTitle,
          'status': status,
        },
      );
      if (data['success'] == true) {
        return (data['video'] as Map?)?.cast<String, dynamic>();
      }
      return null;
    } on AdminApiException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ createArchiveVideo: ${e.statusCode} ${e.bodySnippet}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ createArchiveVideo: $e');
      return null;
    }
  }

  /// YouTube-Videosuche fuer den Admin-Einpflege-Dialog.
  /// Gibt leere Liste zurueck wenn YOUTUBE_API_KEY im Worker fehlt oder
  /// die Suche keine Treffer liefert.
  static Future<List<YoutubeSearchResult>> searchYoutubeVideos(
    String query,
  ) async {
    try {
      final data = await AdminApiClient.instance.getJson(
        '/api/admin/videos/search'
        '?q=${Uri.encodeQueryComponent(query)}&max_results=8',
      );
      final items = data['videos'] as List?;
      if (items == null) return const [];
      return items
          .map((e) => YoutubeSearchResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } on AdminApiException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ searchYoutubeVideos: ${e.statusCode} ${e.bodySnippet}');
      }
      return const [];
    } catch (e) {
      if (kDebugMode) debugPrint('❌ searchYoutubeVideos: $e');
      return const [];
    }
  }

  /// KI-Vorschlag: aus YouTube-URL/ID Welt(en) + Kategorie ableiten.
  /// Liefert {worlds:[...], category, title, thumbnail_url, source} oder null.
  static Future<Map<String, dynamic>?> suggestVideoClassification(
    String youtubeUrl,
  ) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/videos/suggest',
        body: {'youtube_url': youtubeUrl},
        timeout: const Duration(seconds: 20),
      );
      if (data['success'] == true) return data;
      return null;
    } on AdminApiException catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ suggestVideoClassification: ${e.statusCode} ${e.bodySnippet}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ suggestVideoClassification: $e');
      return null;
    }
  }

  /// Setzt status='confirmed' (sichtbar) fuer ein Video.
  static Future<bool> confirmArchiveVideo(String videoId) async {
    try {
      final data = await AdminApiClient.instance
          .postJson('/api/admin/videos/$videoId/confirm');
      return data['success'] as bool? ?? false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ confirmArchiveVideo: $e');
      return false;
    }
  }

  /// Setzt status='rejected' (ausgeblendet, nicht geloescht).
  static Future<bool> rejectArchiveVideo(String videoId) async {
    try {
      final data = await AdminApiClient.instance
          .postJson('/api/admin/videos/$videoId/reject');
      return data['success'] as bool? ?? false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ rejectArchiveVideo: $e');
      return false;
    }
  }

  /// Aendert Kategorie und/oder Welten eines bereits eingepflegten Videos.
  /// [worlds] null laesst die Welten unveraendert; sonst muss mind. eine
  /// gueltige Welt enthalten sein.
  static Future<bool> updateArchiveVideo({
    required String videoId,
    String? category,
    List<String>? worlds,
    String? moduleCode, // C3: '' loest die Bindung
    String? moduleWorld,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (category != null) body['category'] = category;
      if (worlds != null) body['worlds'] = worlds;
      if (moduleCode != null) {
        body['module_code'] = moduleCode;
        if (moduleWorld != null) body['module_world'] = moduleWorld;
      }
      if (body.isEmpty) return false;
      final data = await AdminApiClient.instance
          .patchJson('/api/admin/videos/$videoId', body: body);
      return data['success'] as bool? ?? false;
    } on AdminApiException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ updateArchiveVideo: ${e.statusCode} ${e.bodySnippet}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ updateArchiveVideo: $e');
      return false;
    }
  }

  /// C1: KI-Video-Vorschlaege fuer eine Welt (sucht passende YouTube-Videos).
  static Future<List<Map<String, dynamic>>> aiSuggestVideos(
      {required String world}) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/videos/ai-suggest',
        body: {'world': world},
      );
      final list = (data['candidates'] as List?) ?? const [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ aiSuggestVideos: $e');
      return const [];
    }
  }

  /// C2: Batch-Aktion fuer mehrere Videos. action = confirm|reject|delete.
  static Future<int> batchVideos({
    required String action,
    List<String>? ids,
    bool allPending = false,
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/videos/batch',
        body: {
          'action': action,
          if (ids != null) 'ids': ids,
          if (allPending) 'all_pending': true,
        },
      );
      return (data['count'] as num?)?.toInt() ?? 0;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ batchVideos: $e');
      return 0;
    }
  }

  /// C4: KI-Qualitaetscheck fuer ein Video. {score, verdict, clickbait, reasons}.
  static Future<Map<String, dynamic>?> checkVideoQuality({
    required String title,
    String? channel,
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/videos/quality',
        body: {'title': title, if (channel != null) 'channel': channel},
      );
      if (data['success'] == true) return data;
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ checkVideoQuality: $e');
      return null;
    }
  }

  /// Entfernt ein Video endgueltig.
  static Future<bool> deleteArchiveVideo(String videoId) async {
    try {
      final data = await AdminApiClient.instance
          .deleteJson('/api/admin/videos/$videoId');
      return data['success'] as bool? ?? false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ deleteArchiveVideo: $e');
      return false;
    }
  }

  /// Laedt Zustellstatistiken der notification_queue (letzte 7 Tage).
  static Future<Map<String, dynamic>?> getPushStats() async {
    try {
      final data =
          await AdminApiClient.instance.getJson('/api/admin/push/stats');
      return data;
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ getPushStats: ${e.statusCode} ${e.bodySnippet}');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getPushStats: $e');
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // v117: Granulare Sperren (user_restrictions)
  // ════════════════════════════════════════════════════════════════════

  /// Liefert die aktiven + historischen Sperren eines Users.
  static Future<List<Map<String, dynamic>>> getRestrictions(
      String userId) async {
    try {
      final data = await AdminApiClient.instance
          .getJson('/api/admin/users/$userId/restrictions');
      final list = data['restrictions'];
      if (list is List) return list.cast<Map<String, dynamic>>();
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getRestrictions: $e');
      return [];
    }
  }

  /// Sperrt einen User in den angegebenen [scopes]. [durationHours] <= 0
  /// bedeutet permanent. 'all' => Vollsperre (spiegelt is_banned).
  static Future<bool> restrictUser({
    required String userId,
    required List<String> scopes,
    String reason = 'Admin-Sperre',
    int durationHours = 0,
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/users/$userId/restrict',
        body: {
          'scopes': scopes,
          'reason': reason,
          'duration_h': durationHours,
        },
      );
      AdminApiClient.instance.invalidateCache('/api/admin/users');
      return data['success'] as bool? ?? false;
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ restrictUser: ${e.statusCode} ${e.bodySnippet}');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ restrictUser: $e');
      return false;
    }
  }

  /// Hebt Sperren auf. Leere [scopes] oder ['all'] => alle Sperren aufheben.
  static Future<bool> unrestrictUser({
    required String userId,
    List<String> scopes = const [],
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/users/$userId/unrestrict',
        body: {'scopes': scopes},
      );
      AdminApiClient.instance.invalidateCache('/api/admin/users');
      return data['success'] as bool? ?? false;
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ unrestrictUser: ${e.statusCode} ${e.bodySnippet}');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ unrestrictUser: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // v117: Antrags-Inbox + Loesch-Blacklist
  // ════════════════════════════════════════════════════════════════════

  /// Laedt Antraege (Reaktivierung / Einspruch / Selbstloeschung).
  /// [status] ∈ 'pending'|'approved'|'rejected'|'all'
  static Future<List<Map<String, dynamic>>> getAccountRequests(
      {String status = 'pending'}) async {
    try {
      final data = await AdminApiClient.instance
          .getJson('/api/admin/account-requests?status=$status');
      final list = data['requests'];
      if (list is List) return list.cast<Map<String, dynamic>>();
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getAccountRequests: $e');
      return [];
    }
  }

  /// Bearbeitet einen Antrag. [approve] true = annehmen, false = ablehnen.
  static Future<bool> resolveAccountRequest({
    required String requestId,
    required bool approve,
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/account-requests/$requestId/resolve',
        body: {'action': approve ? 'approve' : 'reject'},
      );
      return data['success'] as bool? ?? false;
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ resolveAccountRequest: ${e.statusCode} ${e.bodySnippet}');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ resolveAccountRequest: $e');
      return false;
    }
  }

  /// Laedt die Loesch-Blacklist (geloeschte Identitaeten).
  static Future<List<Map<String, dynamic>>> getDeletedIdentities() async {
    try {
      final data = await AdminApiClient.instance
          .getJson('/api/admin/deleted-identities');
      final list = data['identities'];
      if (list is List) return list.cast<Map<String, dynamic>>();
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getDeletedIdentities: $e');
      return [];
    }
  }

  /// Entfernt einen Blacklist-Eintrag (gibt Neuanmeldung wieder frei).
  static Future<bool> removeDeletedIdentity(String id) async {
    try {
      final data = await AdminApiClient.instance
          .deleteJson('/api/admin/deleted-identities/$id');
      return data['success'] as bool? ?? false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ removeDeletedIdentity: $e');
      return false;
    }
  }

  // ── v123: Shadow-Ban (root_admin only) ────────────────────────────────────

  static Future<bool> shadowBanUser({
    required String userId,
    required bool enable,
    String? adminUsername,
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/users/$userId/shadow-ban',
        body: {'enable': enable},
      );
      return data['success'] as bool? ?? false;
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ shadowBanUser: ${e.statusCode} ${e.bodySnippet}');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ shadowBanUser: $e');
      return false;
    }
  }

  // ── v123: Temp-Mute (muted_until on profile) ──────────────────────────────

  static Future<bool> tempMuteUser({
    required String userId,
    required int durationMinutes, // 0 = unmute
    String? reason,
    String? adminUsername,
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/users/$userId/temp-mute',
        body: {
          'duration_minutes': durationMinutes,
          if (reason != null) 'reason': reason,
        },
      );
      return data['success'] as bool? ?? false;
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ tempMuteUser: ${e.statusCode} ${e.bodySnippet}');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ tempMuteUser: $e');
      return false;
    }
  }

  // ── v123: Feature Flags ────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getFeatureFlags() async {
    try {
      final data =
          await AdminApiClient.instance.getJson('/api/admin/feature-flags');
      final list = data['flags'] as List? ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getFeatureFlags: $e');
      return [];
    }
  }

  static Future<bool> setFeatureFlag({
    required String key,
    required bool enabled,
    String? world,
    String? value,
    String? adminUsername,
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/feature-flags/$key',
        body: {
          'enabled': enabled,
          if (world != null) 'world': world,
          if (value != null) 'value': value,
        },
      );
      return data['success'] as bool? ?? false;
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ setFeatureFlag: ${e.statusCode} ${e.bodySnippet}');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ setFeatureFlag: $e');
      return false;
    }
  }

  // ── v123: Scheduled Announcements ─────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAnnouncements() async {
    try {
      final data =
          await AdminApiClient.instance.getJson('/api/admin/announcements');
      final list = data['announcements'] as List? ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getAnnouncements: $e');
      return [];
    }
  }

  static Future<bool> createAnnouncement({
    required String title,
    required String body,
    required DateTime runAt,
    String? world,
    bool push = false,
    String? adminUsername,
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/announcements',
        body: {
          'title': title,
          'body': body,
          'run_at': runAt.toUtc().toIso8601String(),
          if (world != null) 'world': world,
          'push': push,
        },
      );
      return data['success'] as bool? ?? false;
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ createAnnouncement: ${e.statusCode} ${e.bodySnippet}');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ createAnnouncement: $e');
      return false;
    }
  }

  static Future<bool> deleteAnnouncement(String announcementId) async {
    try {
      final data = await AdminApiClient.instance
          .deleteJson('/api/admin/announcements/$announcementId');
      return data['success'] as bool? ?? false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ deleteAnnouncement: $e');
      return false;
    }
  }

  // ── v123: Content Approval Queue ──────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getPendingVideos() async {
    try {
      final data = await AdminApiClient.instance
          .getJson('/api/admin/videos?status=pending');
      final list = data['videos'] as List? ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getPendingVideos: $e');
      return [];
    }
  }

  // ── v123: Insights / Analytics ────────────────────────────────────────────

  static Future<Map<String, dynamic>> getInsights() async {
    try {
      final data = await AdminApiClient.instance.getJson('/api/admin/insights');
      return data;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getInsights: $e');
      return {};
    }
  }

  // ── v123: Health check (enriched) ─────────────────────────────────────────

  static Future<Map<String, dynamic>> getHealthStatus() async {
    try {
      final data = await AdminApiClient.instance.getJson('/api/admin/health');
      return data;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getHealthStatus: $e');
      return {};
    }
  }

  // ── v123: Audit log with filter ───────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAuditLogFiltered({
    String? actorId,
    String? action,
    DateTime? from,
    DateTime? to,
    int limit = 100,
  }) async {
    try {
      final params = <String, String>{
        'limit': '$limit',
        if (actorId != null && actorId.isNotEmpty) 'actor': actorId,
        if (action != null && action.isNotEmpty) 'action': action,
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
      };
      final qs = params.entries
          .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');
      final data =
          await AdminApiClient.instance.getJson('/api/admin/audit-log?$qs');
      final list = data['entries'] as List? ?? data['log'] as List? ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getAuditLogFiltered: $e');
      return [];
    }
  }

  // ── v123: Undo last action ────────────────────────────────────────────────

  static Future<bool> undoAuditEntry(String entryId) async {
    try {
      final data = await AdminApiClient.instance
          .postJson('/api/admin/audit-log/$entryId/undo', body: {});
      return data['success'] as bool? ?? false;
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ undoAuditEntry: ${e.statusCode} ${e.bodySnippet}');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ undoAuditEntry: $e');
      return false;
    }
  }

  // ── v123: Bulk-Warn ───────────────────────────────────────────────────────

  static Future<bool> bulkWarnUsers({
    required List<String> userIds,
    required String reason,
    String? adminUsername,
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/users/bulk-warn',
        body: {'user_ids': userIds, 'reason': reason},
      );
      return data['success'] as bool? ?? false;
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ bulkWarnUsers: ${e.statusCode} ${e.bodySnippet}');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ bulkWarnUsers: $e');
      return false;
    }
  }

  static Future<bool> bulkChangeRole({
    required List<String> userIds,
    required String newRole,
    String? adminUsername,
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/users/bulk-role',
        body: {'user_ids': userIds, 'role': newRole},
      );
      return data['success'] as bool? ?? false;
    } on AdminApiException catch (e) {
      if (kDebugMode)
        debugPrint('❌ bulkChangeRole: ${e.statusCode} ${e.bodySnippet}');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ bulkChangeRole: $e');
      return false;
    }
  }

  // ── v124: Impersonation (read-only) ───────────────────────────────────────

  /// Schreibt einen Audit-Eintrag (action='impersonation_view'), KEIN echter
  /// Login-Wechsel. Pflicht-Schritt bevor [getImpersonationSnapshot] aufgerufen
  /// wird, damit jeder View-as-User-Vorgang nachvollziehbar ist.
  /// Nur root_admin (Worker prueft 403).
  static Future<bool> startImpersonation({
    required String targetUserId,
    String? reason,
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/impersonation/start',
        body: {
          'target_user_id': targetUserId,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      return data['success'] as bool? ?? false;
    } on AdminApiException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ startImpersonation: ${e.statusCode} ${e.bodySnippet}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ startImpersonation: $e');
      return false;
    }
  }

  /// Read-only Snapshot eines Users -- nur Daten die der User selber sieht:
  /// recent activity, notification prefs, module progress. Root-Admin only.
  static Future<Map<String, dynamic>?> getImpersonationSnapshot(
      String userId) async {
    try {
      final data = await AdminApiClient.instance
          .getJson('/api/admin/users/$userId/impersonation-snapshot');
      return data;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getImpersonationSnapshot: $e');
      return null;
    }
  }

  // ── v124: Linked Accounts (IP/Device) ─────────────────────────────────────

  /// Findet andere Profile, die in den letzten 90 Tagen denselben pseudonymen
  /// IP/Geraete-Hash verwendet haben. Liefert Treffer mit Profil-Metadaten
  /// (kein Klartext-IP). Root-Admin only.
  static Future<Map<String, dynamic>?> getLinkedAccounts(String userId) async {
    try {
      final data = await AdminApiClient.instance
          .getJson('/api/admin/users/$userId/linked-accounts');
      return data;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getLinkedAccounts: $e');
      return null;
    }
  }
}
