import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// User Authentication Service
/// 
/// Zentraler Service für User-Authentifizierung und Session-Management.
/// Ersetzt Fake-User-Pattern in Inline-Tools mit echten User-Daten.
/// 
/// ✅ FEATURES:
/// - Username aus lokalem Storage holen
/// - User-ID aus lokalem Storage holen
/// - Current World context (materie/energie)
/// - Authentifizierungs-Status prüfen
/// 
/// ✅ USAGE IN INLINE-TOOLS:
/// ```dart
/// final username = await UserAuthService.getUsername();
/// final userId = await UserAuthService.getUserId();
/// final isAuth = await UserAuthService.isAuthenticated();
/// 
/// if (!isAuth) {
///   // Zeige Login-Warnung
///   return;
/// }
/// 
/// // Nutze echten Username statt 'Fake${timestamp}'
/// await api.post({
///   'username': username,
///   'user_id': userId,
///   // ...
/// });
/// ```
class UserAuthService {
  // Storage Keys
  static const String _keyUsername = 'username';
  static const String _keyUserId = 'userId';
  static const String _keyCurrentWorld = 'currentWorld';
  static const String _keyMaterieUsername = 'materie_username';
  static const String _keyEnergieUsername = 'energie_username';
  static const String _keyMaterieUserId = 'materie_userId';
  static const String _keyEnergieUserId = 'energie_userId';

  /// Get current authenticated username
  /// 
  /// Priority:
  /// 1. World-specific username (materie_username / energie_username)
  /// 2. Global username
  /// 3. null (nicht authentifiziert)
  static Future<String?> getUsername({String? world}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. World-specific username
    if (world != null) {
      final worldKey = world == 'materie' ? _keyMaterieUsername : _keyEnergieUsername;
      final worldUsername = prefs.getString(worldKey);
      if (worldUsername != null && worldUsername.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('✅ UserAuthService: Username für $world = $worldUsername');
        }
        return worldUsername;
      }
    }
    
    // 2. Current world username
    final currentWorld = await getCurrentWorld();
    if (currentWorld != null) {
      final worldKey = currentWorld == 'materie' ? _keyMaterieUsername : _keyEnergieUsername;
      final worldUsername = prefs.getString(worldKey);
      if (worldUsername != null && worldUsername.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('✅ UserAuthService: Username für current world $currentWorld = $worldUsername');
        }
        return worldUsername;
      }
    }
    
    // 3. Global username (Fallback)
    final globalUsername = prefs.getString(_keyUsername);
    if (kDebugMode && globalUsername != null) {
      debugPrint('✅ UserAuthService: Global username = $globalUsername');
    }
    return globalUsername;
  }

  /// Get current authenticated user ID
  /// 
  /// Priority:
  /// 1. World-specific user ID (materie_userId / energie_userId)
  /// 2. Global user ID
  /// 3. null (nicht authentifiziert)
  static Future<String?> getUserId({String? world}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. World-specific user ID
    if (world != null) {
      final worldKey = world == 'materie' ? _keyMaterieUserId : _keyEnergieUserId;
      final worldUserId = prefs.getString(worldKey);
      if (worldUserId != null && worldUserId.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('✅ UserAuthService: User ID für $world = $worldUserId');
        }
        return worldUserId;
      }
    }
    
    // 2. Current world user ID
    final currentWorld = await getCurrentWorld();
    if (currentWorld != null) {
      final worldKey = currentWorld == 'materie' ? _keyMaterieUserId : _keyEnergieUserId;
      final worldUserId = prefs.getString(worldKey);
      if (worldUserId != null && worldUserId.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('✅ UserAuthService: User ID für current world $currentWorld = $worldUserId');
        }
        return worldUserId;
      }
    }
    
    // 3. Global user ID (Fallback)
    final globalUserId = prefs.getString(_keyUserId);
    if (kDebugMode && globalUserId != null) {
      debugPrint('✅ UserAuthService: Global user ID = $globalUserId');
    }
    return globalUserId;
  }

  /// Get current world context (materie oder energie)
  static Future<String?> getCurrentWorld() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCurrentWorld);
  }

  /// Check if user is authenticated
  /// 
  /// User ist authentifiziert wenn:
  /// - Username existiert UND nicht leer
  /// - Für die aktuelle Welt oder global
  static Future<bool> isAuthenticated({String? world}) async {
    final username = await getUsername(world: world);
    final isAuth = username != null && username.isNotEmpty;
    
    if (kDebugMode) {
      debugPrint('✅ UserAuthService: isAuthenticated = $isAuth (world: ${world ?? 'current'})');
    }
    
    return isAuth;
  }

  /// Set username for specific world
  /// 
  /// Wird vom Profile-Editor aufgerufen nach erfolgreichem Save
  static Future<void> setUsername(String username, {String? world}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Setze global username
    await prefs.setString(_keyUsername, username);
    
    // Setze world-specific username
    if (world != null) {
      final worldKey = world == 'materie' ? _keyMaterieUsername : _keyEnergieUsername;
      await prefs.setString(worldKey, username);
      
      if (kDebugMode) {
        debugPrint('✅ UserAuthService: Username gesetzt = $username (world: $world)');
      }
    }
  }

  /// Set user ID for specific world
  /// 
  /// Wird vom Profile-Editor aufgerufen nach erfolgreichem Save
  static Future<void> setUserId(String userId, {String? world}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Setze global user ID
    await prefs.setString(_keyUserId, userId);
    
    // Setze world-specific user ID
    if (world != null) {
      final worldKey = world == 'materie' ? _keyMaterieUserId : _keyEnergieUserId;
      await prefs.setString(worldKey, userId);
      
      if (kDebugMode) {
        debugPrint('✅ UserAuthService: User ID gesetzt = $userId (world: $world)');
      }
    }
  }

  /// Set current world context
  /// 
  /// Wird vom World-Screen aufgerufen beim Welt-Wechsel
  static Future<void> setCurrentWorld(String world) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrentWorld, world);
    
    if (kDebugMode) {
      debugPrint('✅ UserAuthService: Current world gesetzt = $world');
    }
  }

  /// Clear all authentication data (Logout)
  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyCurrentWorld);
    await prefs.remove(_keyMaterieUsername);
    await prefs.remove(_keyEnergieUsername);
    await prefs.remove(_keyMaterieUserId);
    await prefs.remove(_keyEnergieUserId);
    
    if (kDebugMode) {
      debugPrint('✅ UserAuthService: Auth data cleared (Logout)');
    }
  }

  /// Get authentication info (für Debug/Logging)
  static Future<Map<String, dynamic>> getAuthInfo() async {
    final username = await getUsername();
    final userId = await getUserId();
    final currentWorld = await getCurrentWorld();
    final isAuth = await isAuthenticated();
    
    return {
      'username': username,
      'userId': userId,
      'currentWorld': currentWorld,
      'isAuthenticated': isAuth,
    };
  }
}
