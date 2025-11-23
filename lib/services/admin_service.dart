import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// ═══════════════════════════════════════════════════════════════
/// ADMIN SERVICE - Weltenbibliothek
/// ═══════════════════════════════════════════════════════════════
/// Handles admin operations:
/// - Get all users
/// - Promote/demote users
/// - View admin actions
/// ═══════════════════════════════════════════════════════════════

class AdminService {
  static const String baseUrl =
      'https://weltenbibliothek.brandy13062.workers.dev';
  final AuthService _authService = AuthService();

  /// Get all users (Super-Admin & Admin only)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final token = _authService.token;
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/users'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['users']);
      } else {
        throw Exception('Failed to get users: ${response.statusCode}');
      }
    } catch (e) {
      print('Get users error: $e');
      rethrow;
    }
  }

  /// Promote user to admin or moderator
  Future<void> promoteUser(
    int userId,
    String role,
    List<String> permissions,
  ) async {
    try {
      final token = _authService.token;
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/users/$userId/promote'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'role': role, 'permissions': permissions}),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body)['error'];
        throw Exception(error ?? 'Failed to promote user');
      }
    } catch (e) {
      print('Promote user error: $e');
      rethrow;
    }
  }

  /// Demote user to normal user
  Future<void> demoteUser(int userId) async {
    try {
      final token = _authService.token;
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/users/$userId/demote'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body)['error'];
        throw Exception(error ?? 'Failed to demote user');
      }
    } catch (e) {
      print('Demote user error: $e');
      rethrow;
    }
  }

  /// Get admin action log
  Future<List<Map<String, dynamic>>> getAdminActions({int limit = 50}) async {
    try {
      final token = _authService.token;
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/actions?limit=$limit'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['actions']);
      } else {
        throw Exception('Failed to get actions');
      }
    } catch (e) {
      print('Get actions error: $e');
      rethrow;
    }
  }
}
