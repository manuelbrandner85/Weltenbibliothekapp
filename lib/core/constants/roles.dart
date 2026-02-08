/// 🔐 ROLLEN-SYSTEM - SINGLE SOURCE OF TRUTH
///
/// Diese Datei definiert ALLE Rollen und Berechtigungen im System.
/// KEINE andere Datei darf Rollen-Strings hardcoden!
library;

class AppRoles {
  // Private Constructor - keine Instanziierung erlaubt
  AppRoles._();

  // Rollen-Definitionen
  static const String user = 'user';
  static const String admin = 'admin';
  static const String rootAdmin = 'root_admin';

  // Root-Admin Username (hardcoded für Offline-Fallback)
  static const String rootAdminUsername = 'Weltenbibliothek';

  // Berechtigungs-Checks
  static bool isAdmin(String? role) =>
      role == admin || role == rootAdmin;

  static bool isRootAdmin(String? role) => role == rootAdmin;

  static bool canAccessAdminDashboard(String? role) => isAdmin(role);

  static bool canManageUsers(String? role) => isRootAdmin(role);

  static bool canPromoteDemote(String? role) => isRootAdmin(role);

  // Helper für Offline-Fallback
  static bool isRootAdminByUsername(String? username) =>
      username?.toLowerCase() == rootAdminUsername.toLowerCase();
}
