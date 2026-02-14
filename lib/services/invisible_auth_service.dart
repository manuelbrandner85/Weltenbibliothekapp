/// 🔐 UNSICHTBARE USER-AUTHENTIFIZIERUNG
/// Profil-basiert, keine Login-Screens
/// 
/// FLOW:
/// 1. App Start → Prüfe lokale UserID
/// 2. Keine UserID? → Generiere neue UserID + Token
/// 3. Speichere lokal (Hive) + sende an Backend
/// 4. Bei jedem Request: Sende AuthToken im Header
/// 5. Backend validiert Token → Gibt UserID zurück
library;

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../core/exceptions/exception_guard.dart';  // 🛡️ EXCEPTION GUARD
import '../core/exceptions/specialized_exceptions.dart';  // 🚨 AUTH EXCEPTIONS

/// 🆔 AUTH SERVICE - Unsichtbare Benutzer-Authentifizierung
class InvisibleAuthService {
  static const String _authBox = 'auth_storage';
  static const String _userIdKey = 'user_id';
  static const String _authTokenKey = 'auth_token';
  static const String _deviceIdKey = 'device_id';
  
  // Cloudflare Worker URL
  static const String _backendUrl = 'https://weltenbibliothek-api-v2.brandy13062.workers.dev';
  
  // Singleton
  static final InvisibleAuthService _instance = InvisibleAuthService._internal();
  factory InvisibleAuthService() => _instance;
  InvisibleAuthService._internal();
  
  // Current Auth State
  String? _userId;
  String? _authToken;
  String? _deviceId;
  
  /// Initialize Auth (call on app start)
  Future<void> initialize() async {
    await guard(
      () async {
        final box = await Hive.openBox(_authBox);
        
        // Load existing auth
        _userId = box.get(_userIdKey);
        _authToken = box.get(_authTokenKey);
        _deviceId = box.get(_deviceIdKey);
        
        if (_userId == null || _authToken == null) {
          // CRITICAL: First time user - create invisible auth
          await _createInvisibleUser();
        } else {
          // Validate existing token with backend
          final isValid = await _validateToken();
          if (!isValid) {
            // Token expired/invalid - refresh
            await _refreshToken();
          }
        }
        
        if (kDebugMode) {
          debugPrint('🔐 [Auth] Initialized: userId=$_userId');
        }
      },
      operationName: 'InvisibleAuth.initialize',
      context: {
        'backendUrl': _backendUrl,
      },
    );
  }
  
  /// Create invisible user (no UI, automatic)
  Future<void> _createInvisibleUser() async {
    await guardApi(
      () async {
        // Generate unique IDs
        _userId = _generateUserId();
        _deviceId = _generateDeviceId();
        _authToken = _generateAuthToken(_userId!, _deviceId!);
        
        if (kDebugMode) {
          debugPrint('🆕 [Auth] Creating invisible user: $_userId');
        }
        
        // Register with backend
        final response = await http.post(
          Uri.parse('$_backendUrl/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': _userId,
            'device_id': _deviceId,
            'auth_token': _authToken,
            'created_at': DateTime.now().toIso8601String(),
          }),
        );
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          // Save locally
          final box = await Hive.openBox(_authBox);
          await box.put(_userIdKey, _userId);
          await box.put(_authTokenKey, _authToken);
          await box.put(_deviceIdKey, _deviceId);
          
          if (kDebugMode) {
            debugPrint('✅ [Auth] Invisible user created successfully');
          }
        } else if (response.statusCode == 401) {
          throw AuthException(
            'Authentication failed',
            cause: {'userId': _userId},
          );
        } else {
          throw BackendException(
            'Backend registration failed',
            endpoint: '/auth/register',
            statusCode: response.statusCode,
          );
        }
      },
      url: '$_backendUrl/auth/register',
      method: 'POST',
      operationName: 'InvisibleAuth.createUser',
    );
  }
  
  /// Validate auth token with backend
  Future<bool> _validateToken() async {
    return await guard(
      () async {
        final response = await http.get(
          Uri.parse('$_backendUrl/auth/validate'),
          headers: {
            'Authorization': 'Bearer $_authToken',
            'X-User-ID': _userId!,
          },
        );
        
        return response.statusCode == 200;
      },
      operationName: 'InvisibleAuth.validateToken',
      context: {'userId': _userId},
      onError: (e, stack) async => false,  // Return false on any error
    );
  }
  
  /// Refresh auth token
  Future<void> _refreshToken() async {
    await guardApi(
      () async {
        final response = await http.post(
          Uri.parse('$_backendUrl/auth/refresh'),
          headers: {
            'Authorization': 'Bearer $_authToken',
            'X-User-ID': _userId!,
          },
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _authToken = data['auth_token'];
          
          // Save new token
          final box = await Hive.openBox(_authBox);
          await box.put(_authTokenKey, _authToken);
          
          if (kDebugMode) {
            debugPrint('🔄 [Auth] Token refreshed');
          }
        } else if (response.statusCode == 401) {
          throw AuthException(
            'Token refresh failed - authentication required',
            errorType: AuthErrorType.sessionExpired,
          );
        } else {
          throw BackendException(
            'Token refresh failed',
            endpoint: '/auth/refresh',
            statusCode: response.statusCode,
          );
        }
      },
      url: '$_backendUrl/auth/refresh',
      method: 'POST',
      operationName: 'InvisibleAuth.refreshToken',
    );
  }
  
  /// Generate unique User ID (UUID-like)
  String _generateUserId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return 'user_${timestamp}_$random';
  }
  
  /// Generate unique Device ID
  String _generateDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return 'device_${timestamp}_$random';
  }
  
  /// Generate secure Auth Token (JWT-like)
  String _generateAuthToken(String userId, String deviceId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final payload = '$userId:$deviceId:$timestamp';
    final bytes = utf8.encode(payload);
    final hash = sha256.convert(bytes);
    return 'wb_${hash.toString()}';
  }
  
  /// Get current User ID (for use in app)
  String? get userId => _userId;
  
  /// Get current Device ID
  String? get deviceId => _deviceId;
  
  /// Get current Auth Token (for API requests)
  String? get authToken => _authToken;
  
  /// Get authenticated headers for HTTP requests
  /// ✅ ERWEITERT: World + Role für Admin-System
  Map<String, String> authHeaders({String? world, String? role}) => {
    'Authorization': 'Bearer $_authToken',
    'X-User-ID': _userId!,
    'X-Device-ID': _deviceId!,
    if (world != null) 'X-World': world, // ✅ Aktive Welt (materie/energie)
    if (role != null) 'X-Role': role,    // ✅ Rolle in dieser Welt
  };
  
  /// Link profile to auth (when user creates profile)
  /// ✅ ERWEITERT: World + Role für Admin-System
  Future<void> linkProfile({
    required String username,
    required String avatar,
    String? avatarUrl,
    String? world,  // ✅ Welt (materie/energie)
    String? role,   // ✅ Rolle (user/admin/root_admin)
  }) async {
    await guardApi(
      () async {
        final response = await http.post(
          Uri.parse('$_backendUrl/auth/link-profile'),
          headers: authHeaders(world: world, role: role)..addAll({'Content-Type': 'application/json'}),
          body: jsonEncode({
            'username': username,
            'avatar': avatar,
            'avatar_url': avatarUrl,
            if (world != null) 'world': world,  // ✅ Welt mitschicken
            if (role != null) 'role': role,     // ✅ Rolle mitschicken
          }),
        );
        
        if (response.statusCode == 200) {
          if (kDebugMode) {
            debugPrint('✅ [Auth] Profile linked: $username (world: $world, role: $role)');
          }
        } else {
          throw BackendException(
            'Profile linking failed',
            endpoint: '/auth/link-profile',
            statusCode: response.statusCode,
          );
        }
      },
      url: '$_backendUrl/auth/link-profile',
      method: 'POST',
      operationName: 'InvisibleAuth.linkProfile',
    );
  }
  
  /// Logout (clear local auth, keep profile)
  Future<void> logout() async {
    await guardApi(
      () async {
        // Notify backend
        await http.post(
          Uri.parse('$_backendUrl/auth/logout'),
          headers: authHeaders(), // ✅ FIX: Methode aufrufen
        );
        
        // Clear local auth (but keep profile data!)
        final box = await Hive.openBox(_authBox);
        await box.delete(_authTokenKey);
        
        _authToken = null;
        
        if (kDebugMode) {
          debugPrint('👋 [Auth] Logged out');
        }
      },
      url: '$_backendUrl/auth/logout',
      method: 'POST',
      operationName: 'InvisibleAuth.logout',
      onError: (e, stack) async {
        // Even if backend fails, clear local auth
        final box = await Hive.openBox(_authBox);
        await box.delete(_authTokenKey);
        _authToken = null;
        if (kDebugMode) {
          debugPrint('👋 [Auth] Logged out (backend notification failed)');
        }
      },
    );
  }
}

/// 🔐 EXTENDED USER MODEL (mit Auth)
class AuthenticatedUser {
  final String userId;          // ✅ Unique ID
  final String authToken;       // ✅ Auth Token
  final String deviceId;        // ✅ Device ID
  final String username;        // From Profile
  final String avatar;          // From Profile
  final String? avatarUrl;      // From Profile
  
  AuthenticatedUser({
    required this.userId,
    required this.authToken,
    required this.deviceId,
    required this.username,
    required this.avatar,
    this.avatarUrl,
  });
  
  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'username': username,
    'avatar': avatar,
    'avatar_url': avatarUrl,
  };
}
