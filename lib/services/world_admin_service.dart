import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/storage/unified_storage_service.dart'; // ✅ Storage für Username
import '../config/api_config.dart'; // ✅ Zentrale API Config

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
  // ✅ ZENTRALE API URL aus ApiConfig
  static const String _baseUrl = 'https://weltenbibliothek-api-v2.brandy13062.workers.dev';
  static const Duration _timeout = Duration(seconds: 15);
  
  /// ✅ EINHEITLICHE Admin-Auth-Headers
  /// Verwendet immer ApiConfig.adminToken für alle Admin-Operationen
  static Map<String, String> _adminHeaders({String? world, String? username}) => {
    'Authorization': 'Bearer ${ApiConfig.adminToken}',
    'Content-Type': 'application/json',
    if (world != null) 'X-World': world,
    'X-Role': 'root_admin',
    if (username != null) 'X-User-ID': username,
  };

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
  static Future<Map<String, dynamic>> checkAdminStatus(String world, String username, {String? role}) async {
    try {
      final url = Uri.parse('$_baseUrl/api/admin/check/$world/$username');
      
      if (kDebugMode) {
        debugPrint('🔍 Checking admin status: $world/$username (role: $role)');
      }
      
      final response = await http.get(
        url,
        headers: _adminHeaders(world: world, username: username),
      ).timeout(_timeout);
      
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
        debugPrint('❌ Admin check error: $e');
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
  /// Returns: List<WorldUser>
  static Future<List<WorldUser>> getUsersByWorld(String world, {String? role}) async {
    try {
      final url = Uri.parse('$_baseUrl/api/admin/users/$world');
      
      final storage = UnifiedStorageService();
      // Versuche Username aus der angefragten Welt, Fallback auf andere Welt
      final username = storage.getUsername(world) 
          ?? storage.getUsername(world == 'materie' ? 'energie' : 'materie');
      
      if (username == null || username.isEmpty) {
        if (kDebugMode) {
          debugPrint('Kein Benutzername gefunden');
        }
        return [];
      }
      
      if (kDebugMode) {
        debugPrint('Lade User fuer $world (Admin: $username)');
      }
      
      final response = await http.get(
        url,
        headers: _adminHeaders(world: world, username: username),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final users = (data['users'] as List<dynamic>?) ?? [];
        
        if (kDebugMode) {
          debugPrint('${users.length} User geladen ($world)');
        }
        
        // Setze world auf jeden User damit Admin sieht woher der User kommt
        return users.map((u) {
          final map = u as Map<String, dynamic>;
          map['world'] = world; // Welt-Vermerk setzen
          return WorldUser.fromJson(map);
        }).toList();
      } else {
        if (kDebugMode) {
          debugPrint('User-Laden fehlgeschlagen: ${response.statusCode}');
          debugPrint('   Response: ${response.body}');
        }
        return [];
      }
    } on SocketException {
      if (kDebugMode) {
        debugPrint('Keine Internetverbindung');
      }
      return [];
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        debugPrint('Timeout: $e');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching users: $e');
      }
      return [];
    }
  }

  /// ADMIN: Alle User aus BEIDEN Welten laden
  /// Admin sieht alle User mit Welt-Vermerk (Materie/Energie)
  static Future<List<WorldUser>> getAllUsers({String? role}) async {
    try {
      if (kDebugMode) {
        debugPrint('Lade User aus beiden Welten...');
      }
      
      // Parallel beide Welten laden
      final results = await Future.wait([
        getUsersByWorld('materie', role: role),
        getUsersByWorld('energie', role: role),
      ]);
      
      final allUsers = <WorldUser>[...results[0], ...results[1]];
      
      // Sortiere: Root-Admins zuerst, dann Admins, dann User
      allUsers.sort((a, b) {
        if (a.isRootAdmin && !b.isRootAdmin) return -1;
        if (!a.isRootAdmin && b.isRootAdmin) return 1;
        if (a.isAdmin && !b.isAdmin) return -1;
        if (!a.isAdmin && b.isAdmin) return 1;
        return a.username.compareTo(b.username);
      });
      
      if (kDebugMode) {
        debugPrint('${allUsers.length} User gesamt (Materie: ${results[0].length}, Energie: ${results[1].length})');
      }
      
      return allUsers;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading all users: $e');
      }
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════
  // ROLE MANAGEMENT
  // ════════════════════════════════════════════════════════════

  /// Promote user to admin
  /// ✅ FIXED AUTH: Uses simple Bearer token (username)
  static Future<bool> promoteUser(String world, String userId, {String? role}) async {
    try {
      final url = Uri.parse('$_baseUrl/api/admin/promote/$world/$userId');
      
      final storage = UnifiedStorageService();
      final username = storage.getUsername(world);
      
      if (username == null || username.isEmpty) {
        if (kDebugMode) {
          debugPrint('❌ No username found for world: $world');
        }
        return false;
      }
      
      if (kDebugMode) {
        debugPrint('⬆️  Promoting user: $world/$userId (by: $username)');
      }
      
      final response = await http.post(
        url,
        headers: _adminHeaders(world: world, username: username),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('✅ User promoted successfully');
          debugPrint('   Response: ${response.body}');
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('⚠️  Promotion failed: ${response.statusCode}');
          debugPrint('   Response: ${response.body}');
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
        debugPrint('❌ Promotion error: $e');
      }
      return false;
    }
  }

  /// Demote admin to user
  /// ✅ FIXED AUTH: Uses simple Bearer token (username)
  static Future<bool> demoteUser(String world, String userId, {String? role}) async {
    try {
      final url = Uri.parse('$_baseUrl/api/admin/demote/$world/$userId');
      
      final storage = UnifiedStorageService();
      final username = storage.getUsername(world);
      
      if (username == null || username.isEmpty) {
        if (kDebugMode) {
          debugPrint('❌ No username found for world: $world');
        }
        return false;
      }
      
      if (kDebugMode) {
        debugPrint('⬇️  Demoting user: $world/$userId (by: $username)');
      }
      
      final response = await http.post(
        url,
        headers: _adminHeaders(world: world, username: username),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('✅ User demoted successfully');
          debugPrint('   Response: ${response.body}');
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('⚠️  Demotion failed: ${response.statusCode}');
          debugPrint('   Response: ${response.body}');
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
        debugPrint('❌ Demotion error: $e');
      }
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════
  // USER DELETION
  // ════════════════════════════════════════════════════════════

  /// Delete user (root admin only)
  /// ✅ FIXED AUTH: Uses simple Bearer token (username)
  static Future<bool> deleteUser(String world, String userId, {String? role}) async {
    try {
      final url = Uri.parse('$_baseUrl/api/admin/delete/$world/$userId');
      
      final storage = UnifiedStorageService();
      final username = storage.getUsername(world);
      
      if (username == null || username.isEmpty) {
        if (kDebugMode) {
          debugPrint('❌ No username found for world: $world');
        }
        return false;
      }
      
      if (kDebugMode) {
        debugPrint('🗑️  Deleting user: $world/$userId (by root_admin: $username)');
      }
      
      final response = await http.delete(
        url,
        headers: _adminHeaders(world: world, username: username),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('✅ User deleted successfully');
          debugPrint('   Response: ${response.body}');
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('⚠️  Deletion failed: ${response.statusCode}');
          debugPrint('   Response: ${response.body}');
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
        debugPrint('❌ Deletion error: $e');
      }
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════
  // AUDIT LOG
  // ════════════════════════════════════════════════════════════

  /// Get audit log for a world
  /// ✅ MIT AUTH-HEADER
  /// 
  /// Returns: List<AuditLogEntry>
  static Future<List<AuditLogEntry>> getAuditLog(String world, {int limit = 50, String? role}) async {
    try {
      final url = Uri.parse('$_baseUrl/api/admin/audit/$world?limit=$limit');
      
      final storage = UnifiedStorageService();
      final username = storage.getUsername(world);
      
      if (kDebugMode) {
        debugPrint('📜 Fetching audit log for: $world (admin: $username)');
      }
      
      final response = await http.get(
        url,
        headers: _adminHeaders(world: world, username: username),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final logs = (data['logs'] as List<dynamic>?) ?? [];
        
        if (kDebugMode) {
          debugPrint('✅ Fetched ${logs.length} audit log entries');
        }
        
        return logs.map((l) => AuditLogEntry.fromJson(l as Map<String, dynamic>)).toList();
      } else {
        if (kDebugMode) {
          debugPrint('⚠️  Failed to fetch audit log: ${response.statusCode}');
        }
        return [];
      }
    } on SocketException {
      if (kDebugMode) {
        debugPrint('❌ Network: Keine Internetverbindung');
      }
      return [];
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Timeout: $e');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching audit log: $e');
      }
      return [];
    }
  }
  
}

// ════════════════════════════════════════════════════════════
// DATA MODELS
// ════════════════════════════════════════════════════════════

/// World User Model - EINHEITLICH fuer gesamte App
class WorldUser {
  final String profileId;
  final String userId;
  final String username;
  final String role;
  final String? world; // 'materie' oder 'energie' - Welt-Zuordnung
  final String? displayName;
  final String? avatarUrl;
  final String? avatarEmoji;
  final String createdAt;
  final bool isSuspended;
  final String? suspensionReason;
  final DateTime? lastActivityAt;

  WorldUser({
    required this.profileId,
    required this.userId,
    required this.username,
    required this.role,
    this.world,
    this.displayName,
    this.avatarUrl,
    this.avatarEmoji,
    required this.createdAt,
    this.isSuspended = false,
    this.suspensionReason,
    this.lastActivityAt,
  });

  factory WorldUser.fromJson(Map<String, dynamic> json) {
    return WorldUser(
      profileId: json['profile_id'] as String? ?? json['profileId'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      world: json['world'] as String?,
      displayName: json['display_name'] as String? ?? json['displayName'] as String?,
      avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
      avatarEmoji: json['avatar_emoji'] as String? ?? json['avatarEmoji'] as String?,
      createdAt: json['created_at'] as String? ?? json['createdAt'] as String? ?? '',
      isSuspended: json['is_suspended'] as bool? ?? false,
      suspensionReason: json['suspension_reason'] as String?,
      lastActivityAt: json['last_activity_at'] != null
          ? DateTime.tryParse(json['last_activity_at'] as String)
          : null,
    );
  }

  bool get isAdmin => role == 'admin' || role == 'root_admin';
  bool get isRootAdmin => role == 'root_admin';
  
  /// Welt-Label fuer UI
  String get worldLabel => world == 'energie' ? 'Energie' : world == 'materie' ? 'Materie' : 'Unbekannt';
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
      adminUsername: json['admin_username'] as String? ?? json['adminUsername'] as String? ?? '',
      action: json['action'] as String? ?? '',
      targetUsername: json['target_username'] as String? ?? json['targetUsername'] as String? ?? '',
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
/// - Root Admin Rolle (AdminPermissions.canManageAdmins)
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
extension WorldAdminServiceV162 on WorldAdminService {
  /// 🆕 Ban User (V16.2)
  /// ⚠️ REQUIRES: Root Admin (AdminPermissions.canManageAdmins)
  static Future<bool> banUser({
    required String userId,
    required String reason,
    int durationHours = 24,
    String? adminUserId,
  }) async {
    try {
      final url = Uri.parse('${WorldAdminService._baseUrl}/api/admin/users/$userId/ban');
      final storage = UnifiedStorageService();
      final adminUser = adminUserId ?? storage.getUsername('materie') ?? 'admin';
      
      final response = await http.post(
        url,
        headers: WorldAdminService._adminHeaders(username: adminUser),
        body: jsonEncode({'reason': reason, 'durationHours': durationHours}),
      ).timeout(WorldAdminService._timeout);
      
      // ✅ ENHANCED: Response validation with body parsing
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final success = data['success'] as bool? ?? true;
          if (kDebugMode) {
            debugPrint(success ? '✅ Ban successful' : '⚠️ Ban failed: ${data['error'] ?? 'Unknown'}');
          }
          return success;
        } catch (e) {
          // Fallback: HTTP 200 without valid JSON = success
          if (kDebugMode) {
            debugPrint('✅ Ban successful (legacy response)');
          }
          return true;
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ Ban failed: HTTP ${response.statusCode}');
          debugPrint('   Response: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// 🆕 Unban User (V16.2)
  /// ⚠️ REQUIRES: Root Admin (AdminPermissions.canManageAdmins)
  static Future<bool> unbanUser({required String userId, String? adminUserId}) async {
    try {
      final url = Uri.parse('${WorldAdminService._baseUrl}/api/admin/users/$userId/unban');
      final storage = UnifiedStorageService();
      final adminUser = adminUserId ?? storage.getUsername('materie') ?? 'admin';
      
      final response = await http.post(
        url,
        headers: WorldAdminService._adminHeaders(username: adminUser),
      ).timeout(WorldAdminService._timeout);
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// 🆕 Mute User (V16.2)
  static Future<bool> muteUser({
    required String userId,
    required String reason,
    int durationMinutes = 60,
    String? adminUserId,
  }) async {
    try {
      final url = Uri.parse('${WorldAdminService._baseUrl}/api/admin/users/$userId/mute');
      final storage = UnifiedStorageService();
      final adminUser = adminUserId ?? storage.getUsername('materie') ?? 'admin';
      
      final response = await http.post(
        url,
        headers: WorldAdminService._adminHeaders(username: adminUser),
        body: jsonEncode({'reason': reason, 'durationMinutes': durationMinutes}),
      ).timeout(WorldAdminService._timeout);
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// 🆕 Unmute User (V16.2)
  static Future<bool> unmuteUser({
    required String userId,
    String? adminUserId,
  }) async {
    try {
      final url = Uri.parse('${WorldAdminService._baseUrl}/api/admin/users/$userId/unmute');
      final storage = UnifiedStorageService();
      final adminUser = adminUserId ?? storage.getUsername('materie') ?? 'admin';
      
      final response = await http.post(
        url,
        headers: WorldAdminService._adminHeaders(username: adminUser),
      ).timeout(WorldAdminService._timeout);
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// 🆕 Check User Status (V16.2)
  static Future<Map<String, dynamic>> checkUserStatus({
    required String userId,
    String? adminUserId,
  }) async {
    try {
      final url = Uri.parse('${WorldAdminService._baseUrl}/api/admin/users/$userId/status');
      final storage = UnifiedStorageService();
      final adminUser = adminUserId ?? storage.getUsername('materie') ?? 'admin';
      
      final response = await http.get(
        url,
        headers: WorldAdminService._adminHeaders(username: adminUser),
      ).timeout(WorldAdminService._timeout);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'userId': userId, 'banned': false, 'muted': false};
    } catch (e) {
      return {'userId': userId, 'banned': false, 'muted': false, 'error': e.toString()};
    }
  }

  /// 🆕 Get Admin Dashboard (V16.2)
  static Future<Map<String, dynamic>> getAdminDashboard({String? adminUserId}) async {
    try {
      final url = Uri.parse('${WorldAdminService._baseUrl}/api/admin/dashboard');
      final storage = UnifiedStorageService();
      final adminUser = adminUserId ?? storage.getUsername('materie') ?? 'admin';
      
      final response = await http.get(
        url,
        headers: WorldAdminService._adminHeaders(username: adminUser),
      ).timeout(WorldAdminService._timeout);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'error': 'Failed'};
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
      final url = Uri.parse('${WorldAdminService._baseUrl}/api/admin/analytics/$realm?days=$days');
      final storage = UnifiedStorageService();
      final adminUser = adminUserId ?? storage.getUsername('materie') ?? 'admin';
      
      final response = await http.get(
        url,
        headers: WorldAdminService._adminHeaders(username: adminUser),
      ).timeout(WorldAdminService._timeout);
      
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
  static Future<List<Map<String, dynamic>>> getActiveVoiceCalls(String world) async {
    try {
      final url = Uri.parse('${WorldAdminService._baseUrl}/api/admin/voice-calls/$world');
      
      if (kDebugMode) {
        debugPrint('📊 Fetching active voice calls for: $world');
      }
      
      final response = await http.get(
        url,
        headers: WorldAdminService._adminHeaders(world: world),
      ).timeout(WorldAdminService._timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (data['success'] == true) {
          final calls = data['calls'] as List<dynamic>;
          
          if (kDebugMode) {
            debugPrint('✅ Found ${calls.length} active calls');
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
      final url = Uri.parse('${WorldAdminService._baseUrl}/api/admin/call-history/$world?limit=$limit');
      
      if (kDebugMode) {
        debugPrint('📚 Fetching call history for: $world (limit: $limit)');
      }
      
      final response = await http.get(
        url,
        headers: WorldAdminService._adminHeaders(world: world),
      ).timeout(WorldAdminService._timeout);
      
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
      final url = Uri.parse('${WorldAdminService._baseUrl}/api/admin/user-profile/$userId');
      
      if (kDebugMode) {
        debugPrint('👤 Fetching user profile for: $userId');
      }
      
      final response = await http.get(
        url,
        headers: WorldAdminService._adminHeaders(),
      ).timeout(WorldAdminService._timeout);
      
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
}
