import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'invisible_auth_service.dart'; // ✅ Auth-Integration
import '../core/storage/unified_storage_service.dart'; // ✅ Storage für Username

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
  // Cloudflare Worker URL (API v2 - World-Based Multi-Profile System)
  static const String _baseUrl = 'https://weltenbibliothek-api-v2.brandy13062.workers.dev';
  static const Duration _timeout = Duration(seconds: 10);
  
  // ✅ AUTH SERVICE
  static final InvisibleAuthService _auth = InvisibleAuthService();

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
        headers: _auth.authHeaders(world: world, role: role), // ✅ Auth-Header
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
  /// ✅ FIXED AUTH: Uses simple Bearer token (username)
  /// 
  /// Returns: List<WorldUser>
  static Future<List<WorldUser>> getUsersByWorld(String world, {String? role}) async {
    try {
      final url = Uri.parse('$_baseUrl/api/admin/users/$world');
      
      // ✅ FIX: Get username from storage (same as UserManagementService)
      final storage = UnifiedStorageService();
      final username = storage.getUsername(world);
      
      if (username == null || username.isEmpty) {
        if (kDebugMode) {
          debugPrint('❌ No username found for world: $world');
        }
        return [];
      }
      
      if (kDebugMode) {
        debugPrint('📋 Fetching users for world: $world (admin: $username)');
      }
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $username', // ✅ NEW: Simple Bearer token
          'Content-Type': 'application/json',
        },
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final users = (data['users'] as List<dynamic>?) ?? [];
        
        if (kDebugMode) {
          debugPrint('✅ Fetched ${users.length} users');
        }
        
        return users.map((u) => WorldUser.fromJson(u as Map<String, dynamic>)).toList();
      } else {
        if (kDebugMode) {
          debugPrint('⚠️  Failed to fetch users: ${response.statusCode}');
          debugPrint('   Response: ${response.body}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching users: $e');
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
      
      // ✅ FIX: Get username from storage
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
        headers: {
          'Authorization': 'Bearer $username',
          'Content-Type': 'application/json',
        },
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
          debugPrint('   Headers sent: ${_auth.authHeaders(world: world, role: role)}');
        }
        return false;
      }
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
      
      // ✅ FIX: Get username from storage
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
        headers: {
          'Authorization': 'Bearer $username',
          'Content-Type': 'application/json',
        },
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
          debugPrint('   Headers sent: ${_auth.authHeaders(world: world, role: role)}');
        }
        return false;
      }
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
      
      // ✅ FIX: Get username from storage
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
        headers: {
          'Authorization': 'Bearer $username',
          'Content-Type': 'application/json',
        },
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
          debugPrint('   Headers sent: ${_auth.authHeaders(world: world, role: role)}');
        }
        return false;
      }
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
      
      if (kDebugMode) {
        debugPrint('📜 Fetching audit log for: $world (role: $role)');
      }
      
      final response = await http.get(
        url,
        headers: _auth.authHeaders(world: world, role: role), // ✅ Auth-Header
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
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching audit log: $e');
      }
      return [];
    }
  }
  
  // ════════════════════════════════════════════════════════════
  // 🧪 MOCK DATA (für Testing - später durch echte API ersetzen!)
  // ════════════════════════════════════════════════════════════
  
  /// Get mock users for testing (bis Backend ready ist)
  /// 
  /// 🧪 TESTING ONLY - Diese Methode gibt Mock-Daten zurück
  /// ✅ PRODUCTION: getUsersByWorld() verwenden (echte API)
  static Future<List<WorldUser>> getUsersByWorldMock(String world) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (kDebugMode) {
      debugPrint('🧪 MOCK: Loading sample users for $world');
    }
    
    if (world.toLowerCase() == 'materie') {
      return [
        WorldUser(
          profileId: 'profile_1',
          userId: 'materie_Weltenbibliothek',
          username: 'Weltenbibliothek',
          role: 'root_admin',
          displayName: 'Weltenbibliothek Admin',
          avatarEmoji: '👑',
          createdAt: '2026-02-01T10:00:00Z',
        ),
        WorldUser(
          profileId: 'profile_2',
          userId: 'materie_TestAdmin',
          username: 'TestAdmin',
          role: 'admin',
          displayName: 'Test Administrator',
          avatarEmoji: '⭐',
          createdAt: '2026-02-02T14:30:00Z',
        ),
        WorldUser(
          profileId: 'profile_3',
          userId: 'materie_ForscherMax',
          username: 'ForscherMax',
          role: 'user',
          displayName: 'Max der Forscher',
          avatarEmoji: '🔬',
          createdAt: '2026-02-03T09:15:00Z',
        ),
        WorldUser(
          profileId: 'profile_4',
          userId: 'materie_WissenschaftlerAnna',
          username: 'WissenschaftlerAnna',
          role: 'user',
          displayName: 'Dr. Anna Schmidt',
          avatarEmoji: '🧪',
          createdAt: '2026-02-04T11:20:00Z',
        ),
        WorldUser(
          profileId: 'profile_5',
          userId: 'materie_AnalystPeter',
          username: 'AnalystPeter',
          role: 'user',
          displayName: 'Peter Analyst',
          avatarEmoji: '📊',
          createdAt: '2026-02-05T08:45:00Z',
        ),
      ];
    } else if (world.toLowerCase() == 'energie') {
      return [
        WorldUser(
          profileId: 'profile_6',
          userId: 'energie_Weltenbibliothek',
          username: 'Weltenbibliothek',
          role: 'root_admin',
          displayName: 'Weltenbibliothek Admin',
          avatarEmoji: '👑',
          createdAt: '2026-02-01T10:00:00Z',
        ),
        WorldUser(
          profileId: 'profile_7',
          userId: 'energie_SpiritGuide',
          username: 'SpiritGuide',
          role: 'admin',
          displayName: 'Spirit Guide',
          avatarEmoji: '🌟',
          createdAt: '2026-02-02T15:00:00Z',
        ),
        WorldUser(
          profileId: 'profile_8',
          userId: 'energie_MysticLuna',
          username: 'MysticLuna',
          role: 'user',
          displayName: 'Luna die Mystikerin',
          avatarEmoji: '🌙',
          createdAt: '2026-02-03T10:30:00Z',
        ),
        WorldUser(
          profileId: 'profile_9',
          userId: 'energie_ZenMaster',
          username: 'ZenMaster',
          role: 'user',
          displayName: 'Meister Zen',
          avatarEmoji: '🧘',
          createdAt: '2026-02-04T12:15:00Z',
        ),
        WorldUser(
          profileId: 'profile_10',
          userId: 'energie_CrystalHealer',
          username: 'CrystalHealer',
          role: 'user',
          displayName: 'Crystal Healer',
          avatarEmoji: '💎',
          createdAt: '2026-02-05T09:30:00Z',
        ),
      ];
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

  WorldUser({
    required this.profileId,
    required this.userId,
    required this.username,
    required this.role,
    this.displayName,
    this.avatarUrl,
    this.avatarEmoji,
    required this.createdAt,
  });

  factory WorldUser.fromJson(Map<String, dynamic> json) {
    return WorldUser(
      profileId: json['profile_id'] as String? ?? json['profileId'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      displayName: json['display_name'] as String? ?? json['displayName'] as String?,
      avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
      avatarEmoji: json['avatar_emoji'] as String? ?? json['avatarEmoji'] as String?,
      createdAt: json['created_at'] as String? ?? json['createdAt'] as String? ?? '',
    );
  }

  bool get isAdmin => role == 'admin' || role == 'root_admin';
  bool get isRootAdmin => role == 'root_admin';
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
        headers: {
          'X-Role': 'root_admin',
          'X-User-ID': adminUser,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'reason': reason, 'durationHours': durationHours}),
      ).timeout(WorldAdminService._timeout);
      
      return response.statusCode == 200;
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
        headers: {'X-Role': 'root_admin', 'X-User-ID': adminUser},
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
        headers: {
          'X-Role': 'root_admin',
          'X-User-ID': adminUser,
          'Content-Type': 'application/json',
        },
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
        headers: {
          'X-Role': 'root_admin',
          'X-User-ID': adminUser,
          'Content-Type': 'application/json',
        },
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
        headers: {'X-Role': 'root_admin', 'X-User-ID': adminUser},
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
        headers: {'X-Role': 'root_admin', 'X-User-ID': adminUser},
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
        headers: {'X-Role': 'root_admin', 'X-User-ID': adminUser},
      ).timeout(WorldAdminService._timeout);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'error': 'Failed'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
