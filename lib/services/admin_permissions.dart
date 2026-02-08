/// WELTENBIBLIOTHEK ADMIN SYSTEM
/// 
/// Verwaltet Admin-Rechte und Moderator-Funktionen basierend auf Backend-Rollen
/// 
/// Admin-Levels (Backend role field):
/// - ROOT_ADMIN: 'root_admin' (Weltenbibliothek Account - Owner)
/// - ADMIN: 'admin' (Von Root Admin ernannt)
/// - MODERATOR: Room-spezifische Rechte
/// - USER: 'user' (Standard-User)
/// 
/// WICHTIG: Die eigentliche Rollenvergabe erfolgt im Backend (index.js)
/// Diese Klasse dient nur zur UI-Darstellung und Client-seitigen Checks

import 'package:flutter/foundation.dart';

enum AdminLevel {
  rootAdmin,        // 'root_admin' - Weltenbibliothek (Owner)
  admin,            // 'admin' - Von Root Admin ernannt
  moderator,        // Room-specific permissions
  user,             // 'user' - Standard User
}

class AdminPermissions {
  // 👑 ROOT ADMIN: Weltenbibliothek (Definiert im Backend mit Passwort)
  // Username: 'Weltenbibliothek'
  // Role: 'root_admin' (wird bei Login mit Passwort gesetzt)
  static const List<String> rootAdminUsernames = [
    'Weltenbibliothek',  // 👑 ROOT ADMIN - Owner Account
  ];
  
  // 🛡️ ADMINS: Von Root Admin über Backend ernannt
  // Role: 'admin' (wird in DB gesetzt)
  // Diese Liste ist NUR für Client-Side Checks, echte Rolle kommt vom Backend!
  static const List<String> knownAdmins = [
    // Hier können bekannte Admin-Usernames eingetragen werden
    // Echte Prüfung erfolgt über Backend role === 'admin'
  ];
  
  // MODERATOR IDs (Room-specific)
  static const Map<String, List<String>> moderators = {
    // MATERIE Räume
    'politik': ['mod_politik_001', 'mod_politik_002'],
    'geschichte': ['mod_geschichte_001'],
    'ufo': ['mod_ufo_001', 'mod_ufo_002'],
    'verschwoerungen': ['mod_verschwoerungen_001'],
    'wissenschaft': ['mod_wissenschaft_001'],
    // ENERGIE Räume
    'meditation': ['mod_meditation_001'],
    'astralreisen': ['mod_astralreisen_001'],
    'chakra': ['mod_chakra_001'],
    'kristalle': ['mod_kristalle_001'],
    'traumarbeit': ['mod_traumarbeit_001'],
    'frequenzen': ['mod_frequenzen_001'],
  };
  
  /// Get Admin Level for a user
  /// WICHTIG: Diese Methode sollte idealerweise durch Backend-Rolle ersetzt werden!
  /// Verwende stattdessen: checkAdminStatusFromBackend(userId)
  static AdminLevel getAdminLevel(String userId) {
    // Check Root Admin (Weltenbibliothek)
    if (rootAdminUsernames.contains(userId)) {
      return AdminLevel.rootAdmin;
    }
    
    // Check known admins (echte Prüfung sollte vom Backend kommen!)
    if (knownAdmins.contains(userId)) {
      return AdminLevel.admin;
    }
    
    // Check if moderator in any room
    for (final roomMods in moderators.values) {
      if (roomMods.contains(userId)) {
        return AdminLevel.moderator;
      }
    }
    
    return AdminLevel.user;
  }
  
  /// Get Admin Level from Backend Role (RECOMMENDED!)
  /// Backend role values: 'root_admin', 'admin', 'user'
  static AdminLevel getAdminLevelFromBackendRole(String? backendRole) {
    if (backendRole == 'root_admin') {
      return AdminLevel.rootAdmin;
    }
    if (backendRole == 'admin') {
      return AdminLevel.admin;
    }
    return AdminLevel.user;
  }
  
  /// Check if user can delete ANY message (not just own)
  static bool canDeleteAnyMessage(String userId, {String? roomId}) {
    final level = getAdminLevel(userId);
    
    // Root Admin und Admins können überall löschen
    if (level == AdminLevel.rootAdmin || level == AdminLevel.admin) {
      return true;
    }
    
    // Moderator can delete in assigned rooms
    if (level == AdminLevel.moderator && roomId != null) {
      return moderators[roomId]?.contains(userId) ?? false;
    }
    
    return false;
  }
  
  /// Check if user can ban other users
  static bool canBanUsers(String userId) {
    final level = getAdminLevel(userId);
    return level == AdminLevel.rootAdmin || level == AdminLevel.admin;
  }
  
  /// Check if user can pin messages
  static bool canPinMessages(String userId, {String? roomId}) {
    final level = getAdminLevel(userId);
    
    // Root Admin und Admins können überall pinnen
    if (level == AdminLevel.rootAdmin || level == AdminLevel.admin) {
      return true;
    }
    
    // Moderator can pin in assigned rooms
    if (level == AdminLevel.moderator && roomId != null) {
      return moderators[roomId]?.contains(userId) ?? false;
    }
    
    return false;
  }
  
  /// Check if user can create announcements
  static bool canCreateAnnouncements(String userId) {
    final level = getAdminLevel(userId);
    return level == AdminLevel.rootAdmin || level == AdminLevel.admin;
  }
  
  /// Check if user can manage admins (nur Root Admin!)
  static bool canManageAdmins(String userId) {
    return getAdminLevel(userId) == AdminLevel.rootAdmin;
  }
  
  /// Check if user can view mod tools
  static bool canViewModTools(String userId) {
    return getAdminLevel(userId) != AdminLevel.user;
  }
  
  /// Get admin badge emoji
  static String getAdminBadge(String userId) {
    switch (getAdminLevel(userId)) {
      case AdminLevel.rootAdmin:
        return '👑'; // Crown for Root Admin (Weltenbibliothek)
      case AdminLevel.admin:
        return '🛡️'; // Shield for Admin
      case AdminLevel.moderator:
        return '⚔️'; // Sword for Moderator
      case AdminLevel.user:
        return ''; // No badge for users
    }
  }
  
  /// Get admin badge from Backend Role (RECOMMENDED!)
  static String getAdminBadgeFromBackendRole(String? backendRole) {
    if (backendRole == 'root_admin') return '👑';
    if (backendRole == 'admin') return '🛡️';
    return '';
  }
  
  /// Get admin title
  static String getAdminTitle(String userId) {
    switch (getAdminLevel(userId)) {
      case AdminLevel.rootAdmin:
        return 'Root Admin';
      case AdminLevel.admin:
        return 'Admin';
      case AdminLevel.moderator:
        return 'Moderator';
      case AdminLevel.user:
        return '';
    }
  }
  
  /// Get admin title from Backend Role (RECOMMENDED!)
  static String getAdminTitleFromBackendRole(String? backendRole) {
    if (backendRole == 'root_admin') return 'Root Admin';
    if (backendRole == 'admin') return 'Admin';
    return '';
  }
  
  /// Debug: Print user permissions
  static void printPermissions(String userId, {String? roomId}) {
    if (!kDebugMode) return;
    
    final level = getAdminLevel(userId);
    debugPrint('🔐 Admin Permissions for $userId:');
    debugPrint('   Level: ${getAdminTitle(userId)} ${getAdminBadge(userId)}');
    debugPrint('   Can delete any message: ${canDeleteAnyMessage(userId, roomId: roomId)}');
    debugPrint('   Can ban users: ${canBanUsers(userId)}');
    debugPrint('   Can pin messages: ${canPinMessages(userId, roomId: roomId)}');
    debugPrint('   Can create announcements: ${canCreateAnnouncements(userId)}');
    debugPrint('   Can view mod tools: ${canViewModTools(userId)}');
  }
}
