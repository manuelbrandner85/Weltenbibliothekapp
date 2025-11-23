import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// ═══════════════════════════════════════════════════════════════
/// WELTENBIBLIOTHEK - AUTHENTICATION SERVICE
/// ═══════════════════════════════════════════════════════════════
/// Handles user authentication, JWT token management, and API calls
/// ═══════════════════════════════════════════════════════════════

class AuthService {
  // 🔧 CONFIGURATION - Unified Master Worker URL
  static const String baseUrl =
      'https://weltenbibliothek.brandy13062.workers.dev';

  // Token storage keys
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  // Cached user data
  Map<String, dynamic>? _currentUser;
  String? _currentToken;

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Get current authenticated user
  Map<String, dynamic>? get currentUser => _currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _currentToken != null && _currentUser != null;

  /// Get current auth token
  String? get token => _currentToken;

  /// Get current user ID
  String? get userId => _currentUser?['id'] as String?;

  // ═══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════

  /// Initialize service and restore session
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    _currentToken = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);

    if (userJson != null) {
      try {
        _currentUser = json.decode(userJson) as Map<String, dynamic>;
      } catch (e) {
        // Silent logout on corrupted user data
        await logout();
      }
    }

    // Validate token by fetching current user
    if (_currentToken != null) {
      try {
        await getCurrentUser();
      } catch (e) {
        // Silent logout on token validation failure
        await logout();
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // AUTHENTICATION METHODS
  // ═══════════════════════════════════════════════════════════════

  /// Register new user (email is optional)
  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    String? email,
  }) async {
    try {
      final body = {'username': username, 'password': password};

      // Add email only if provided
      if (email != null && email.isNotEmpty) {
        body['email'] = email;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      // CRITICAL: Check if response body is empty or invalid
      if (response.body.isEmpty) {
        return {
          'success': false,
          'error':
              'Server returned empty response (Status: ${response.statusCode})',
        };
      }

      // Try to parse JSON with better error handling
      Map<String, dynamic> data;
      try {
        data = json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        return {
          'success': false,
          'error':
              'Invalid server response: ${response.body.substring(0, 100)}',
        };
      }

      if (response.statusCode == 201) {
        // Save token and user
        await _saveAuthData(
          data['token'] as String,
          data['user'] as Map<String, dynamic>,
        );

        return {'success': true, 'user': _currentUser};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// Login user
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );

      // CRITICAL: Check if response body is empty or invalid
      if (response.body.isEmpty) {
        return {
          'success': false,
          'error':
              'Server returned empty response (Status: ${response.statusCode})',
        };
      }

      // Try to parse JSON with better error handling
      Map<String, dynamic> data;
      try {
        data = json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        return {
          'success': false,
          'error':
              'Invalid server response: ${response.body.substring(0, 100)}',
        };
      }

      if (response.statusCode == 200) {
        // Save token and user
        await _saveAuthData(
          data['token'] as String,
          data['user'] as Map<String, dynamic>,
        );

        return {'success': true, 'user': _currentUser};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);

    _currentToken = null;
    _currentUser = null;
  }

  /// Get current user from API
  Future<Map<String, dynamic>> getCurrentUser() async {
    if (_currentToken == null) {
      throw Exception('Not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/me'),
        headers: {
          'Authorization': 'Bearer $_currentToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        _currentUser = data['user'] as Map<String, dynamic>;

        // Update stored user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, json.encode(_currentUser));

        return _currentUser!;
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await logout();
        throw Exception('Session expired');
      } else {
        throw Exception('Failed to fetch user');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════

  Future<void> _saveAuthData(String token, Map<String, dynamic> user) async {
    _currentToken = token;
    _currentUser = user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, json.encode(user));
  }

  // ═══════════════════════════════════════════════════════════════
  // AUTHENTICATED HTTP HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// Make authenticated GET request
  Future<http.Response> authenticatedGet(String endpoint) async {
    if (_currentToken == null) {
      throw Exception('Not authenticated');
    }

    return await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $_currentToken',
        'Content-Type': 'application/json',
      },
    );
  }

  /// Make authenticated POST request
  Future<http.Response> authenticatedPost(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    if (_currentToken == null) {
      throw Exception('Not authenticated');
    }

    return await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $_currentToken',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );
  }

  /// Make authenticated PUT request
  Future<http.Response> authenticatedPut(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    if (_currentToken == null) {
      throw Exception('Not authenticated');
    }

    return await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $_currentToken',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );
  }

  /// Make authenticated DELETE request
  Future<http.Response> authenticatedDelete(String endpoint) async {
    if (_currentToken == null) {
      throw Exception('Not authenticated');
    }

    return await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $_currentToken',
        'Content-Type': 'application/json',
      },
    );
  }
}
