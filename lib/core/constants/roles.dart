/// 🔐 ROLLEN-SYSTEM - SINGLE SOURCE OF TRUTH
///
/// Diese Datei definiert ALLE Rollen und Berechtigungen im System.
/// KEINE andere Datei darf Rollen-Strings hardcoden!
library;

class AppRoles {
  // Private Constructor - keine Instanziierung erlaubt
  AppRoles._();

  // ============================================================================
  // ROLLEN-DEFINITIONEN
  // ============================================================================
  
  static const String user = 'user';
  static const String admin = 'admin';
  static const String moderator = 'moderator';
  static const String rootAdmin = 'root_admin';
  static const String rootAdminLegacy = 'root-admin'; // DB-Alias (dash-variant)
  static const String contentEditor = 'content_editor';

  // ============================================================================
  // ADMIN ACCOUNTS
  // ============================================================================

  /// Root-Admin (VOLLZUGRIFF auf alles)
  /// Login: Supabase Email + Passwort – Passwort NIEMALS im Client-Code!
  /// Rolle wird in Supabase profiles.role = 'root_admin' gesetzt.
  static const String rootAdminUsername = 'Weltenbibliothek';

  /// Content-Editor Admin (NUR Content-Management)
  /// Login: Supabase Email + Passwort – Passwort NIEMALS im Client-Code!
  /// Rolle wird in Supabase profiles.role = 'content_editor' gesetzt.
  static const String contentEditorUsername = 'Weltenbibliothekedit';

  // ============================================================================
  // BERECHTIGUNGS-CHECKS - USER MANAGEMENT
  // ============================================================================
  
  static bool _isRoot(String? r) => r == rootAdmin || r == rootAdminLegacy;

  /// Kann auf Admin-Dashboard zugreifen
  static bool isModerator(String? role) => role == moderator;

  static bool canAccessAdminDashboard(String? role) =>
      role == admin || _isRoot(role) || role == contentEditor || role == moderator;

  /// Kann User verwalten (Erstellen, Löschen, Befördern)
  static bool canManageUsers(String? role) => _isRoot(role);

  /// Kann User befördern/degradieren
  static bool canPromoteDemote(String? role) => _isRoot(role);

  /// Kann User-Liste einsehen
  static bool canViewUserList(String? role) => _isRoot(role);

  /// Kann User löschen
  static bool canDeleteUsers(String? role) => _isRoot(role);

  // ============================================================================
  // BERECHTIGUNGS-CHECKS - CONTENT MANAGEMENT
  // ============================================================================
  
  /// Kann Content bearbeiten (Tabs, Tools, Marker, Medien)
  static bool canEditContent(String? role) => _isRoot(role) || role == contentEditor;
  static bool canManageTabs(String? role) => _isRoot(role) || role == contentEditor;
  static bool canManageTools(String? role) => _isRoot(role) || role == contentEditor;
  static bool canManageMarkers(String? role) => _isRoot(role) || role == contentEditor;
  static bool canManageMedia(String? role) => _isRoot(role) || role == contentEditor;
  static bool canManageFeatureFlags(String? role) => _isRoot(role) || role == contentEditor;
  static bool canPublishContent(String? role) => _isRoot(role) || role == contentEditor;
  static bool canManageVersions(String? role) => _isRoot(role) || role == contentEditor;
  static bool canViewChangeLog(String? role) => _isRoot(role) || role == contentEditor;
  static bool canUseSandbox(String? role) => _isRoot(role) || role == contentEditor;

  // ============================================================================
  // HELPER FUNCTIONS
  // ============================================================================
  
  /// Ist der User ein Admin (irgendeine Admin-Rolle)
  static bool isAdmin(String? role) =>
      role == admin || _isRoot(role) || role == contentEditor || role == moderator;

  /// Ist der User Root-Admin (volle Rechte)
  static bool isRootAdmin(String? role) => _isRoot(role);

  /// Ist der User Content-Editor (nur Content-Rechte)
  static bool isContentEditor(String? role) => role == contentEditor;

  /// Helper für Offline-Fallback - Check by Username
  static bool isRootAdminByUsername(String? username) =>
      username?.toLowerCase() == rootAdminUsername.toLowerCase();

  /// Helper für Offline-Fallback - Check by Username
  static bool isContentEditorByUsername(String? username) =>
      username?.toLowerCase() == contentEditorUsername.toLowerCase();
  
  /// Helper für Offline-Fallback - Check if user can edit content by username
  /// Prüft BEIDE: Root-Admin UND Content-Editor
  static bool canEditContentByUsername(String? username) =>
      isRootAdminByUsername(username) || isContentEditorByUsername(username);

  /// Get Role by Username (für Login)
  static String? getRoleByUsername(String? username) {
    if (username == null) return null;
    
    final lower = username.toLowerCase();
    if (lower == rootAdminUsername.toLowerCase()) {
      return rootAdmin;
    }
    if (lower == contentEditorUsername.toLowerCase()) {
      return contentEditor;
    }
    
    return user;  // Fallback für normale User
  }

  /// Get User Role Name (für UI)
  static String getRoleName(String? role) {
    switch (role) {
      case rootAdmin:
        return 'Root-Administrator';
      case contentEditor:
        return 'Content-Editor';
      case admin:
        return 'Administrator';
      case user:
        return 'Benutzer';
      default:
        return 'Unbekannt';
    }
  }

  /// Get Permission Summary (für UI)
  static String getPermissionSummary(String? role) {
    switch (role) {
      case rootAdmin:
        return 'Vollzugriff: User-Management + Content-Management + System-Administration';
      case contentEditor:
        return 'Content-Management: Alle Inhalte bearbeiten, KEIN User-Management';
      case admin:
        return 'Administrator-Zugriff';
      case user:
        return 'Standard-Benutzer-Zugriff';
      default:
        return 'Keine Berechtigungen';
    }
  }

  // ============================================================================
  // BERECHTIGUNGS-MATRIX (für Dokumentation)
  // ============================================================================
  
  /// Gibt eine Map mit allen Berechtigungen für eine Rolle zurück
  static Map<String, bool> getPermissionsForRole(String? role) {
    return {
      // User Management
      'canManageUsers': canManageUsers(role),
      'canViewUserList': canViewUserList(role),
      'canPromoteDemote': canPromoteDemote(role),
      'canDeleteUsers': canDeleteUsers(role),
      
      // Content Management
      'canEditContent': canEditContent(role),
      'canManageTabs': canManageTabs(role),
      'canManageTools': canManageTools(role),
      'canManageMarkers': canManageMarkers(role),
      'canManageMedia': canManageMedia(role),
      'canManageFeatureFlags': canManageFeatureFlags(role),
      'canPublishContent': canPublishContent(role),
      'canManageVersions': canManageVersions(role),
      'canViewChangeLog': canViewChangeLog(role),
      'canUseSandbox': canUseSandbox(role),
      
      // Dashboard Access
      'canAccessAdminDashboard': canAccessAdminDashboard(role),
    };
  }
}
