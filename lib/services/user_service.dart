import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

/// ═══════════════════════════════════════════════════════════════
/// USER SERVICE - Weltenbibliothek
/// ═══════════════════════════════════════════════════════════════
/// Verwaltet alle User-bezogenen API-Calls
/// Features:
/// - User-Profile abrufen
/// - Profile bearbeiten (Display-Name, Bio)
/// - Profilbild hochladen
/// - User-Suche
/// - Alle User abrufen
/// - Online-Status-Tracking
/// ═══════════════════════════════════════════════════════════════

class UserService {
  static const String baseUrl =
      'https://weltenbibliothek.brandy13062.workers.dev';
  final AuthService _authService = AuthService();

  // Singleton pattern
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  // ═══════════════════════════════════════════════════════════════
  // USER PROFILE OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  /// Holt User-Profil nach Username
  Future<User?> getUserProfile(String username) async {
    try {
      final response = await _authService.authenticatedGet(
        '/api/users/$username',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return User.fromJson(data['user'] as Map<String, dynamic>);
      } else if (response.statusCode == 404) {
        return null; // User nicht gefunden
      } else {
        throw Exception('Failed to fetch user profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user profile: $e');
    }
  }

  /// Holt aktuellen User (mit vollem Profil)
  Future<User> getCurrentUserProfile() async {
    try {
      final response = await _authService.authenticatedGet('/api/auth/me');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return User.fromJson(data['user'] as Map<String, dynamic>);
      } else {
        throw Exception('Failed to fetch current user');
      }
    } catch (e) {
      throw Exception('Error fetching current user: $e');
    }
  }

  /// Aktualisiert User-Profil (Display-Name, Bio)
  Future<User> updateUserProfile({String? displayName, String? bio}) async {
    try {
      final body = <String, dynamic>{};
      if (displayName != null) body['display_name'] = displayName;
      if (bio != null) body['bio'] = bio;

      final response = await _authService.authenticatedPut(
        '/api/users/me',
        body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return User.fromJson(data['user'] as Map<String, dynamic>);
      } else {
        final error = json.decode(response.body)['error'] as String?;
        throw Exception(error ?? 'Failed to update profile');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  /// Lädt Profilbild hoch
  Future<String> uploadProfilePicture(File imageFile) async {
    try {
      final token = _authService.token;
      if (token == null) throw Exception('Not authenticated');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/users/me/avatar'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Datei hinzufügen
      final fileStream = http.ByteStream(imageFile.openRead());
      final fileLength = await imageFile.length();
      final multipartFile = http.MultipartFile(
        'avatar',
        fileStream,
        fileLength,
        filename: 'avatar.jpg',
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);

      // Request senden
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['avatar_url'] as String;
      } else {
        final error = json.decode(response.body)['error'] as String?;
        throw Exception(error ?? 'Failed to upload avatar');
      }
    } catch (e) {
      throw Exception('Error uploading avatar: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // USER SEARCH & DISCOVERY
  // ═══════════════════════════════════════════════════════════════

  /// Sucht User nach Query
  Future<List<User>> searchUsers(String query, {int limit = 20}) async {
    try {
      final response = await _authService.authenticatedGet(
        '/api/users/search?q=${Uri.encodeComponent(query)}&limit=$limit',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final users = data['users'] as List<dynamic>;
        return users
            .map((u) => User.fromJson(u as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 404) {
        return []; // Keine Ergebnisse
      } else {
        throw Exception('Failed to search users');
      }
    } catch (e) {
      throw Exception('Error searching users: $e');
    }
  }

  /// Holt alle User (mit Pagination)
  Future<List<User>> getAllUsers({int page = 1, int limit = 50}) async {
    try {
      final response = await _authService.authenticatedGet(
        '/api/users?page=$page&limit=$limit',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final users = data['users'] as List<dynamic>;
        return users
            .map((u) => User.fromJson(u as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to fetch users');
      }
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ONLINE STATUS
  // ═══════════════════════════════════════════════════════════════

  /// Holt Online-Status eines Users
  Future<Map<String, dynamic>> getUserStatus(String username) async {
    try {
      final response = await _authService.authenticatedGet(
        '/api/users/$username/status',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return {
          'isOnline': data['is_online'] as bool? ?? false,
          'lastSeenAt': data['last_seen_at'] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  (data['last_seen_at'] as int) * 1000,
                )
              : null,
        };
      } else {
        return {'isOnline': false, 'lastSeenAt': null};
      }
    } catch (e) {
      return {'isOnline': false, 'lastSeenAt': null};
    }
  }

  /// Holt Online-Status für mehrere User (Batch-Request)
  Future<Map<String, bool>> getBatchUserStatus(List<String> usernames) async {
    try {
      final response = await _authService.authenticatedPost(
        '/api/users/status/batch',
        {'usernames': usernames},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final statuses = data['statuses'] as Map<String, dynamic>;
        return statuses.map((key, value) => MapEntry(key, value as bool));
      } else {
        // Fallback: alle offline
        return {for (var username in usernames) username: false};
      }
    } catch (e) {
      // Fallback: alle offline
      return {for (var username in usernames) username: false};
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // USER BLOCKING & REPORTING
  // ═══════════════════════════════════════════════════════════════

  /// Blockiert einen User
  Future<void> blockUser(String username) async {
    try {
      final response = await _authService.authenticatedPost(
        '/api/users/$username/block',
        {},
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body)['error'] as String?;
        throw Exception(error ?? 'Failed to block user');
      }
    } catch (e) {
      throw Exception('Error blocking user: $e');
    }
  }

  /// Entblockt einen User
  Future<void> unblockUser(String username) async {
    try {
      final response = await _authService.authenticatedPost(
        '/api/users/$username/unblock',
        {},
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body)['error'] as String?;
        throw Exception(error ?? 'Failed to unblock user');
      }
    } catch (e) {
      throw Exception('Error unblocking user: $e');
    }
  }

  /// Holt Liste blockierter User
  Future<List<User>> getBlockedUsers() async {
    try {
      final response = await _authService.authenticatedGet(
        '/api/users/me/blocked',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final users = data['blocked_users'] as List<dynamic>;
        return users
            .map((u) => User.fromJson(u as Map<String, dynamic>))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Meldet einen User (Report)
  Future<void> reportUser({
    required String username,
    required String reason,
    String? details,
  }) async {
    try {
      final response = await _authService.authenticatedPost(
        '/api/users/$username/report',
        {'reason': reason, if (details != null) 'details': details},
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body)['error'] as String?;
        throw Exception(error ?? 'Failed to report user');
      }
    } catch (e) {
      throw Exception('Error reporting user: $e');
    }
  }
}
