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
  static const String rootAdmin = 'root_admin';
  static const String contentEditor = 'content_editor';  // NEU: Nur Content-Management

  // ============================================================================
  // ADMIN ACCOUNTS
  // ============================================================================
  
  /// Root-Admin (VOLLZUGRIFF auf alles)
  /// - User Management
  /// - Content Management
  /// - System Administration
  static const String rootAdminUsername = 'Weltenbibliothek';
  static const String rootAdminPassword = 'Jolene2305';
  
  /// Content-Editor Admin (NUR Content-Management)
  /// - Alle Inhalte bearbeiten (Tabs, Tools, Marker, Medien)
  /// - KEIN User Management
  /// - KEINE System-Administration
  static const String contentEditorUsername = 'Weltenbibliothekedit';
  static const String contentEditorPassword = 'Jolene2305';

  // ============================================================================
  // BERECHTIGUNGS-CHECKS - USER MANAGEMENT
  // ============================================================================
  
  /// Kann auf Admin-Dashboard zugreifen
  static bool canAccessAdminDashboard(String? role) => 
      role == admin || role == rootAdmin || role == contentEditor;

  /// Kann User verwalten (Erstellen, Löschen, Befördern)
  /// NUR für Root-Admin!
  static bool canManageUsers(String? role) => 
      role == rootAdmin;

  /// Kann User befördern/degradieren
  /// NUR für Root-Admin!
  static bool canPromoteDemote(String? role) => 
      role == rootAdmin;

  /// Kann User-Liste einsehen
  /// NUR für Root-Admin!
  static bool canViewUserList(String? role) => 
      role == rootAdmin;

  /// Kann User löschen
  /// NUR für Root-Admin!
  static bool canDeleteUsers(String? role) => 
      role == rootAdmin;

  // ============================================================================
  // BERECHTIGUNGS-CHECKS - CONTENT MANAGEMENT
  // ============================================================================
  
  /// Kann Content bearbeiten (Tabs, Tools, Marker, Medien)
  /// Root-Admin UND Content-Editor!
  static bool canEditContent(String? role) => 
      role == rootAdmin || role == contentEditor;

  /// Kann Tabs erstellen/bearbeiten/löschen
  static bool canManageTabs(String? role) => 
      role == rootAdmin || role == contentEditor;

  /// Kann Tools erstellen/bearbeiten/löschen
  static bool canManageTools(String? role) => 
      role == rootAdmin || role == contentEditor;

  /// Kann Marker erstellen/bearbeiten/löschen
  static bool canManageMarkers(String? role) => 
      role == rootAdmin || role == contentEditor;

  /// Kann Medien hochladen/bearbeiten/löschen
  static bool canManageMedia(String? role) => 
      role == rootAdmin || role == contentEditor;

  /// Kann Feature Flags verwalten
  static bool canManageFeatureFlags(String? role) => 
      role == rootAdmin || role == contentEditor;

  /// Kann Inhalte publishen/unpublishen
  static bool canPublishContent(String? role) => 
      role == rootAdmin || role == contentEditor;

  /// Kann Version-Snapshots erstellen/rollback
  static bool canManageVersions(String? role) => 
      role == rootAdmin || role == contentEditor;

  /// Kann Change-Log einsehen
  static bool canViewChangeLog(String? role) => 
      role == rootAdmin || role == contentEditor;

  /// Kann Sandbox-Modus verwenden
  static bool canUseSandbox(String? role) => 
      role == rootAdmin || role == contentEditor;

  // ============================================================================
  // HELPER FUNCTIONS
  // ============================================================================
  
  /// Ist der User ein Admin (irgendeine Admin-Rolle)
  static bool isAdmin(String? role) =>
      role == admin || role == rootAdmin || role == contentEditor;

  /// Ist der User Root-Admin (volle Rechte)
  static bool isRootAdmin(String? role) => 
      role == rootAdmin;

  /// Ist der User Content-Editor (nur Content-Rechte)
  static bool isContentEditor(String? role) => 
      role == contentEditor;

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

  /// Validate Password for Admin Accounts
  static bool validateAdminPassword(String username, String password) {
    final lower = username.toLowerCase();
    
    if (lower == rootAdminUsername.toLowerCase()) {
      return password == rootAdminPassword;
    }
    if (lower == contentEditorUsername.toLowerCase()) {
      return password == contentEditorPassword;
    }
    
    return false;  // Normale User haben kein hardcoded Password
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
