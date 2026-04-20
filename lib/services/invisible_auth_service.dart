/// 🔐 UNSICHTBARE USER-AUTHENTIFIZIERUNG
/// Profil-basiert, keine Login-Screens
library;
import '../config/api_config.dart';

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/exceptions/exception_guard.dart';
import '../core/exceptions/specialized_exceptions.dart';

/// 🆔 AUTH SERVICE - Unsichtbare Benutzer-Authentifizierung
class InvisibleAuthService {
  // SharedPreferences keys (ehemals Hive 'auth_storage')
  static const String _kUserId    = 'auth_user_id';
  static const String _kAuthToken = 'auth_token';
  static const String _kDeviceId  = 'auth_device_id';

  static const String _backendUrl = ApiConfig.workerUrl;

  static final InvisibleAuthService _instance = InvisibleAuthService._internal();
  factory InvisibleAuthService() => _instance;
  InvisibleAuthService._internal();

  String? _userId;
  String? _authToken;
  String? _deviceId;

  /// Initialize Auth (call on app start)
  Future<void> initialize() async {
    await guard(
      () async {
        final prefs = await SharedPreferences.getInstance();

        _userId    = prefs.getString(_kUserId);
        _authToken = prefs.getString(_kAuthToken);
        _deviceId  = prefs.getString(_kDeviceId);

        if (_userId == null || _authToken == null) {
          await _createInvisibleUser(prefs);
        } else {
          final isValid = await _validateToken();
          if (!isValid) await _refreshToken(prefs);
        }

        if (kDebugMode) debugPrint('🔐 [Auth] Initialized: userId=$_userId');
      },
      operationName: 'InvisibleAuth.initialize',
      context: {'backendUrl': _backendUrl},
    );
  }

  /// Create invisible user (no UI, automatic)
  Future<void> _createInvisibleUser(SharedPreferences prefs) async {
    await guardApi(
      () async {
        _userId    = _generateUserId();
        _deviceId  = _generateDeviceId();
        _authToken = _generateAuthToken(_userId!, _deviceId!);

        if (kDebugMode) debugPrint('🆕 [Auth] Creating invisible user: $_userId');

        final response = await http.post(
          Uri.parse('$_backendUrl/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': _userId,
            'device_id': _deviceId,
            'auth_token': _authToken,
            'created_at': DateTime.now().toIso8601String(),
          }),
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException('Request Timeout (15s)', timeout: const Duration(seconds: 15)),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          await prefs.setString(_kUserId, _userId!);
          await prefs.setString(_kAuthToken, _authToken!);
          await prefs.setString(_kDeviceId, _deviceId!);
          if (kDebugMode) debugPrint('✅ [Auth] Invisible user created');
        } else if (response.statusCode == 401) {
          throw AuthException('Authentication failed', cause: {'userId': _userId});
        } else {
          throw BackendException('Backend registration failed',
              endpoint: '/auth/register', statusCode: response.statusCode);
        }
      },
      url: '$_backendUrl/auth/register',
      method: 'POST',
      operationName: 'InvisibleAuth.createUser',
    );
  }

  Future<bool> _validateToken() async {
    return await guard(
      () async {
        final response = await http.get(
          Uri.parse('$_backendUrl/auth/validate'),
          headers: {'Authorization': 'Bearer $_authToken', 'X-User-ID': _userId!},
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException('Request Timeout (15s)', timeout: const Duration(seconds: 15)),
        );
        return response.statusCode == 200;
      },
      operationName: 'InvisibleAuth.validateToken',
      context: {'userId': _userId},
      onError: (e, stack) async => false,
    );
  }

  Future<void> _refreshToken(SharedPreferences prefs) async {
    await guardApi(
      () async {
        final response = await http.post(
          Uri.parse('$_backendUrl/auth/refresh'),
          headers: {'Authorization': 'Bearer $_authToken', 'X-User-ID': _userId!},
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException('Request Timeout (15s)', timeout: const Duration(seconds: 15)),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _authToken = data['auth_token'] as String?;
          if (_authToken != null) await prefs.setString(_kAuthToken, _authToken!);
          if (kDebugMode) debugPrint('🔄 [Auth] Token refreshed');
        } else if (response.statusCode == 401) {
          throw AuthException('Token refresh failed', errorType: AuthErrorType.sessionExpired);
        } else {
          throw BackendException('Token refresh failed',
              endpoint: '/auth/refresh', statusCode: response.statusCode);
        }
      },
      url: '$_backendUrl/auth/refresh',
      method: 'POST',
      operationName: 'InvisibleAuth.refreshToken',
    );
  }

  String _generateUserId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'user_${ts}_${Random().nextInt(999999)}';
  }

  String _generateDeviceId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'device_${ts}_${Random().nextInt(999999)}';
  }

  String _generateAuthToken(String userId, String deviceId) {
    final payload = '$userId:$deviceId:${DateTime.now().millisecondsSinceEpoch}';
    final hash = sha256.convert(utf8.encode(payload));
    return 'wb_${hash.toString()}';
  }

  String? get userId    => _userId;
  String? get deviceId  => _deviceId;
  String? get authToken => _authToken;

  Map<String, String> authHeaders({String? world, String? role}) => {
    'Authorization': 'Bearer $_authToken',
    'X-User-ID': _userId!,
    'X-Device-ID': _deviceId!,
    if (world != null) 'X-World': world,
    if (role != null)  'X-Role': role,
  };

  Future<void> linkProfile({
    required String username,
    required String avatar,
    String? avatarUrl,
    String? world,
    String? role,
  }) async {
    await guardApi(
      () async {
        final response = await http.post(
          Uri.parse('$_backendUrl/auth/link-profile'),
          headers: authHeaders(world: world, role: role)
            ..addAll({'Content-Type': 'application/json'}),
          body: jsonEncode({
            'username': username,
            'avatar': avatar,
            'avatar_url': avatarUrl,
            if (world != null) 'world': world,
            if (role != null)  'role': role,
          }),
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException('Request Timeout (15s)', timeout: const Duration(seconds: 15)),
        );
        if (response.statusCode != 200) {
          throw BackendException('Profile linking failed',
              endpoint: '/auth/link-profile', statusCode: response.statusCode);
        }
        if (kDebugMode) debugPrint('✅ [Auth] Profile linked: $username');
      },
      url: '$_backendUrl/auth/link-profile',
      method: 'POST',
      operationName: 'InvisibleAuth.linkProfile',
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await guardApi(
      () async {
        await http.post(Uri.parse('$_backendUrl/auth/logout'), headers: authHeaders());
        await prefs.remove(_kAuthToken);
        _authToken = null;
        if (kDebugMode) debugPrint('👋 [Auth] Logged out');
      },
      url: '$_backendUrl/auth/logout',
      method: 'POST',
      operationName: 'InvisibleAuth.logout',
      onError: (e, stack) async {
        await prefs.remove(_kAuthToken);
        _authToken = null;
        if (kDebugMode) debugPrint('👋 [Auth] Logged out (backend failed)');
      },
    );
  }
}

/// 🔐 EXTENDED USER MODEL (mit Auth)
class AuthenticatedUser {
  final String userId;
  final String authToken;
  final String deviceId;
  final String username;
  final String avatar;
  final String? avatarUrl;

  AuthenticatedUser({
    required this.userId,
    required this.authToken,
    required this.deviceId,
    required this.username,
    required this.avatar,
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'username': username,
    'avatar': avatar,
    'avatar_url': avatarUrl,
    'auth_token': authToken,
    'device_id': deviceId,
  };
}
