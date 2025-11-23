import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ModerationService {
  static const String baseUrl =
      'https://weltenbibliothek.brandy13062.workers.dev';
  final AuthService _authService = AuthService();

  // ═══════════════════════════════════════════════════════════════
  // REPORTS
  // ═══════════════════════════════════════════════════════════════

  /// Create a report
  Future<Map<String, dynamic>> createReport({
    required String reportType,
    required String reason,
    int? reportedUserId,
    String? description,
    int? referenceId,
    Map<String, dynamic>? referenceData,
  }) async {
    final token = _authService.token;
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/api/reports'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'report_type': reportType,
        'reason': reason,
        'reported_user_id': reportedUserId,
        'description': description,
        'reference_id': referenceId,
        'reference_data': referenceData,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }

    throw Exception('Failed to create report: ${response.body}');
  }

  /// Get reports (Admin/Moderator only)
  Future<List<Map<String, dynamic>>> getReports({
    String status = 'pending',
    int limit = 50,
  }) async {
    final token = _authService.token;
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/reports?status=$status&limit=$limit'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['reports']);
    }

    throw Exception('Failed to get reports: ${response.body}');
  }

  /// Resolve a report
  Future<void> resolveReport({
    required int reportId,
    required String status, // 'resolved' or 'dismissed'
    String? resolutionNote,
  }) async {
    final token = _authService.token;
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/reports/$reportId/resolve'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'status': status, 'resolution_note': resolutionNote}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to resolve report: ${response.body}');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // BANS
  // ═══════════════════════════════════════════════════════════════

  /// Ban a user
  Future<void> banUser({
    required int userId,
    required String banType, // 'permanent' or 'temporary'
    required String reason,
    int? durationHours,
  }) async {
    final token = _authService.token;
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/users/$userId/ban'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'ban_type': banType,
        'reason': reason,
        'duration_hours': durationHours,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to ban user: ${response.body}');
    }
  }

  /// Unban a user
  Future<void> unbanUser(int userId) async {
    final token = _authService.token;
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/users/$userId/unban'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to unban user: ${response.body}');
    }
  }

  /// Get user's ban history
  Future<List<Map<String, dynamic>>> getUserBans(int userId) async {
    final token = _authService.token;
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/users/$userId/bans'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['bans']);
    }

    throw Exception('Failed to get bans: ${response.body}');
  }

  // ═══════════════════════════════════════════════════════════════
  // MUTES
  // ═══════════════════════════════════════════════════════════════

  /// Mute a user
  Future<void> muteUser({
    required int userId,
    required String muteType, // 'chat', 'voice', or 'both'
    required String reason,
    int? durationHours,
  }) async {
    final token = _authService.token;
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/users/$userId/mute'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'mute_type': muteType,
        'reason': reason,
        'duration_hours': durationHours,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mute user: ${response.body}');
    }
  }

  /// Unmute a user
  Future<void> unmuteUser(int userId) async {
    final token = _authService.token;
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/users/$userId/unmute'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to unmute user: ${response.body}');
    }
  }

  /// Get user's mute history
  Future<List<Map<String, dynamic>>> getUserMutes(int userId) async {
    final token = _authService.token;
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/users/$userId/mutes'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['mutes']);
    }

    throw Exception('Failed to get mutes: ${response.body}');
  }

  // ═══════════════════════════════════════════════════════════════
  // MODERATION ACTIONS LOG
  // ═══════════════════════════════════════════════════════════════

  /// Get moderation action log
  Future<List<Map<String, dynamic>>> getModerationActions({
    int limit = 50,
    String? actionType,
  }) async {
    final token = _authService.token;
    if (token == null) throw Exception('Not authenticated');

    String url = '$baseUrl/api/admin/moderation/actions?limit=$limit';
    if (actionType != null) {
      url += '&action_type=$actionType';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['actions']);
    }

    throw Exception('Failed to get moderation actions: ${response.body}');
  }
}
