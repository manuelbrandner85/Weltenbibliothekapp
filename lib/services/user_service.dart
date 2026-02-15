import 'storage_service.dart';
import 'package:flutter/foundation.dart';
import 'invisible_auth_service.dart';

/// User Service - Holt Benutzerdaten aus Energie/Materie Profilen
/// ✅ ERWEITERT MIT AUTHENTICATION (Phase 1)
class UserService {
  final InvisibleAuthService _auth = InvisibleAuthService();
  final StorageService _storage = StorageService();
  
  /// Get current user from Energie or Materie profile
  /// ✅ ERWEITERT: Inkludiert jetzt userId und authToken
  Future<AuthenticatedUser> getCurrentUser() async {
    try {
      // 🔥 PRIO 1: Energie-Profil prüfen
      final energieProfile = _storage.getEnergieProfile();
      
      debugPrint('🔍 DEBUG UserService.getCurrentUser():');
      debugPrint('  energieProfile: ${energieProfile != null ? "EXISTS" : "NULL"}');
      
      if (energieProfile != null && energieProfile.username.isNotEmpty) {
        debugPrint('  username: ${energieProfile.username}');
        debugPrint('  avatarEmoji: ${energieProfile.avatarEmoji}');
        debugPrint('  avatarUrl: ${energieProfile.avatarUrl}');
        
        return AuthenticatedUser(
          userId: _auth.userId ?? '',
          authToken: _auth.authToken ?? '',
          deviceId: _auth.deviceId ?? '',
          username: energieProfile.username,
          avatar: energieProfile.avatarEmoji ?? '🔮',
          avatarUrl: energieProfile.avatarUrl,
        );
      }
      
      // 🔷 PRIO 2: Materie-Profil prüfen
      final materieProfile = _storage.getMaterieProfile();
      if (materieProfile != null && materieProfile.username.isNotEmpty) {
        return AuthenticatedUser(
          userId: _auth.userId ?? '',
          authToken: _auth.authToken ?? '',
          deviceId: _auth.deviceId ?? '',
          username: materieProfile.username,
          avatar: materieProfile.avatarEmoji ?? '💎',
          avatarUrl: materieProfile.avatarUrl,
        );
      }
      
      // ❌ KEIN PROFIL: Return null username (wird gecheckt)
      return AuthenticatedUser(
        userId: _auth.userId ?? '',
        authToken: _auth.authToken ?? '',
        deviceId: _auth.deviceId ?? '',
        username: '',  // LEERER String = kein Profil!
        avatar: '👤',
        avatarUrl: null,
      );
    } catch (e) {
      return AuthenticatedUser(
        userId: _auth.userId ?? '',
        authToken: _auth.authToken ?? '',
        deviceId: _auth.deviceId ?? '',
        username: '',
        avatar: '👤',
        avatarUrl: null,
      );
    }
  }
  
  /// Link profile to authentication (when user creates profile)
  Future<void> linkProfileToAuth(String username, String avatar, String? avatarUrl) async {
    await _auth.linkProfile(
      username: username,
      avatar: avatar,
      avatarUrl: avatarUrl,
    );
  }
  
  /// Set current user (nicht verwendet - Profile werden über Screens gespeichert)
  Future<void> setCurrentUser(String username, String avatar) async {
    // Deprecated - Profile werden über StorageService gespeichert
  }
  
  // 🔥 STATIC HELPER METHODS (for convenient access)
  
  /// Get current user ID (static helper)
  static String getCurrentUserId() {
    final auth = InvisibleAuthService();
    return auth.userId ?? 'user_anonymous';
  }
  
  /// Get current username (static helper)
  static String getCurrentUsername() {
    final storage = StorageService();
    // Try Energie profile first
    final energieProfile = storage.getEnergieProfile();
    if (energieProfile != null && energieProfile.username.isNotEmpty) {
      return energieProfile.username;
    }
    // Try Materie profile
    final materieProfile = storage.getMaterieProfile();
    if (materieProfile != null && materieProfile.username.isNotEmpty) {
      return materieProfile.username;
    }
    return 'Gast';
  }
}

