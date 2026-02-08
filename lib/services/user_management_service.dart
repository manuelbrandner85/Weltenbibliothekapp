import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// User Management Service für Admin User Management
/// 
/// Features:
/// - User-Liste mit Filter/Suche
/// - User Activity Timeline
/// - User Statistics
/// - User Suspend/Unsuspend
/// - User Notes (Admin-Notizen)
class UserManagementService {
  static const String _baseUrl = 'https://weltenbibliothek-api-v2.brandy13062.workers.dev';
  
  /// Get all users (with optional filters)
  /// @param world - 'materie' or 'energie'
  /// @param adminToken - Admin authentication token
  /// @param search - Optional search query
  /// @param role - Optional role filter ('user', 'admin', 'root_admin')
  /// @param limit - Results per page (default: 50)
  /// @param offset - Pagination offset (default: 0)
  Future<Map<String, dynamic>> getUsers({
    required String world,
    required String adminToken,
    String? search,
    String? role,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // 🔍 DEBUG: Token-Check
      if (kDebugMode) {
        debugPrint('🔐 [UserManagement] getUsers aufgerufen:');
        debugPrint('   World: $world');
        debugPrint('   Token: "$adminToken" (length: ${adminToken.length})');
        debugPrint('   Token isEmpty: ${adminToken.isEmpty}');
      }
      
      // ⚠️ VALIDATION: Token darf nicht leer sein
      if (adminToken.isEmpty) {
        throw Exception('Missing authentication token - please ensure you have a valid profile');
      }
      
      final uri = Uri.parse('$_baseUrl/api/admin/users/$world').replace(
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (role != null && role.isNotEmpty) 'role': role,
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );
      
      if (kDebugMode) {
        debugPrint('📡 [UserManagement] Request URI: $uri');
        debugPrint('📡 [UserManagement] Auth Header: Bearer $adminToken');
      }
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );
      
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200 && data['success'] == true) {
        if (kDebugMode) {
          debugPrint('✅ Users loaded: ${data['users']?.length ?? 0}/${data['total']}');
        }
        return data;
      } else {
        throw Exception(data['error'] ?? 'Failed to load users');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Get users error: $e');
      }
      rethrow;
    }
  }
  
  /// Get user activity timeline
  /// @param world - 'materie' or 'energie'
  /// @param userId - User ID (e.g., 'materie_max')
  /// @param adminToken - Admin authentication token
  /// @param limit - Number of activities (default: 100)
  Future<Map<String, dynamic>> getUserActivity({
    required String world,
    required String userId,
    required String adminToken,
    int limit = 100,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/admin/user/$world/$userId/activity').replace(
        queryParameters: {'limit': limit.toString()},
      );
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );
      
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200 && data['success'] == true) {
        if (kDebugMode) {
          debugPrint('✅ User activity loaded: ${data['count']} entries');
        }
        return data;
      } else {
        throw Exception(data['error'] ?? 'Failed to load user activity');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Get user activity error: $e');
      }
      rethrow;
    }
  }
  
  /// Get user statistics
  /// @param world - 'materie' or 'energie'
  /// @param userId - User ID
  /// @param adminToken - Admin authentication token
  Future<Map<String, dynamic>> getUserStats({
    required String world,
    required String userId,
    required String adminToken,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/admin/user/$world/$userId/stats');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );
      
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200 && data['success'] == true) {
        if (kDebugMode) {
          debugPrint('✅ User stats loaded for $userId');
        }
        return data;
      } else {
        throw Exception(data['error'] ?? 'Failed to load user stats');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Get user stats error: $e');
      }
      rethrow;
    }
  }
  
  /// Suspend user
  /// @param world - 'materie' or 'energie'
  /// @param userId - User ID to suspend
  /// @param suspensionType - 'temporary' or 'permanent'
  /// @param reason - Suspension reason
  /// @param adminToken - Admin authentication token
  /// @param expiresAt - Expiration date for temporary suspensions (ISO string)
  Future<Map<String, dynamic>> suspendUser({
    required String world,
    required String userId,
    required String suspensionType,
    required String reason,
    required String adminToken,
    String? expiresAt,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/admin/user/$world/$userId/suspend');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: jsonEncode({
          'suspension_type': suspensionType,
          'reason': reason,
          if (expiresAt != null) 'expires_at': expiresAt,
        }),
      );
      
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200 && data['success'] == true) {
        if (kDebugMode) {
          debugPrint('✅ User suspended: $userId ($suspensionType)');
        }
        return data;
      } else {
        throw Exception(data['error'] ?? 'Failed to suspend user');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Suspend user error: $e');
      }
      rethrow;
    }
  }
  
  /// Unsuspend user
  /// @param world - 'materie' or 'energie'
  /// @param userId - User ID to unsuspend
  /// @param adminToken - Admin authentication token
  Future<Map<String, dynamic>> unsuspendUser({
    required String world,
    required String userId,
    required String adminToken,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/admin/user/$world/$userId/unsuspend');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: jsonEncode({}),
      );
      
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200 && data['success'] == true) {
        if (kDebugMode) {
          debugPrint('✅ User unsuspended: $userId');
        }
        return data;
      } else {
        throw Exception(data['error'] ?? 'Failed to unsuspend user');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Unsuspend user error: $e');
      }
      rethrow;
    }
  }
  
  /// Add note for user
  /// @param world - 'materie' or 'energie'
  /// @param userId - User ID
  /// @param note - Note text
  /// @param noteType - 'general', 'warning', 'praise', 'concern'
  /// @param adminToken - Admin authentication token
  Future<Map<String, dynamic>> addUserNote({
    required String world,
    required String userId,
    required String note,
    required String adminToken,
    String noteType = 'general',
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/admin/user/$world/$userId/note');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: jsonEncode({
          'note': note,
          'note_type': noteType,
        }),
      );
      
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200 && data['success'] == true) {
        if (kDebugMode) {
          debugPrint('✅ User note added for $userId');
        }
        return data;
      } else {
        throw Exception(data['error'] ?? 'Failed to add user note');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Add user note error: $e');
      }
      rethrow;
    }
  }
  
  /// Get user notes
  /// @param world - 'materie' or 'energie'
  /// @param userId - User ID
  /// @param adminToken - Admin authentication token
  Future<Map<String, dynamic>> getUserNotes({
    required String world,
    required String userId,
    required String adminToken,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/admin/user/$world/$userId/notes');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );
      
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200 && data['success'] == true) {
        if (kDebugMode) {
          debugPrint('✅ User notes loaded: ${data['count']} notes');
        }
        return data;
      } else {
        throw Exception(data['error'] ?? 'Failed to load user notes');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Get user notes error: $e');
      }
      rethrow;
    }
  }
}
