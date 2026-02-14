import 'package:flutter/foundation.dart';
import '../core/exceptions/specialized_exceptions.dart';

/// 🔐 AUTHENTICATION SERVICE
/// Manages user authentication tokens and state
/// 
/// Features:
/// - Secure token management
/// - AuthException for authentication errors
/// - Debug logging
/// - Token validation
class AuthService {
  String? _token;
  DateTime? _tokenExpiry;

  /// Get current authentication token
  /// 
  /// Throws [AuthException] if not authenticated or token expired
  String get token {
    if (_token == null) {
      if (kDebugMode) {
        debugPrint('❌ AuthService: Token access denied - not authenticated');
      }
      throw AuthException(
        'Not authenticated',
        errorType: AuthErrorType.sessionExpired,
      );
    }

    // Check token expiry
    if (_tokenExpiry != null && DateTime.now().isAfter(_tokenExpiry!)) {
      if (kDebugMode) {
        debugPrint('❌ AuthService: Token expired at $_tokenExpiry');
      }
      throw AuthException(
        'Token expired',
        errorType: AuthErrorType.sessionExpired,
      );
    }

    if (kDebugMode) {
      debugPrint('✅ AuthService: Token retrieved successfully');
    }
    return _token!;
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _token != null && !isTokenExpired;

  /// Check if token is expired
  bool get isTokenExpired {
    if (_tokenExpiry == null) return false;
    return DateTime.now().isAfter(_tokenExpiry!);
  }

  /// Set authentication token with optional expiry
  /// 
  /// [token] - The authentication token
  /// [expiresIn] - Token lifetime in seconds (default: 1 hour)
  void setToken(String token, {int expiresIn = 3600}) {
    if (token.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ AuthService: Attempted to set empty token');
      }
      throw AuthException(
        'Invalid token',
        errorType: AuthErrorType.tokenInvalid,
      );
    }

    _token = token;
    _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));

    if (kDebugMode) {
      debugPrint('✅ AuthService: Token set successfully');
      debugPrint('   Expires at: $_tokenExpiry');
    }
  }

  /// Clear authentication state
  void clear() {
    final wasAuthenticated = _token != null;
    _token = null;
    _tokenExpiry = null;

    if (kDebugMode) {
      if (wasAuthenticated) {
        debugPrint('✅ AuthService: Authentication cleared');
      } else {
        debugPrint('ℹ️ AuthService: Clear called but was not authenticated');
      }
    }
  }

  /// Refresh token (extend expiry)
  void refreshToken({int expiresIn = 3600}) {
    if (_token == null) {
      throw AuthException(
        'Cannot refresh: not authenticated',
        errorType: AuthErrorType.sessionExpired,
      );
    }

    _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));

    if (kDebugMode) {
      debugPrint('✅ AuthService: Token refreshed');
      debugPrint('   New expiry: $_tokenExpiry');
    }
  }
}
