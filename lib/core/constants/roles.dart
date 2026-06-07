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
  static bool _isAdminLike(String? r) => _isRoot(r) || r == admin;
  static bool _isModeratorOrAbove(String? r) =>
      _isAdminLike(r) || r == moderator;

  /// Kann auf Admin-Dashboard zugreifen
  static bool isModerator(String? role) => role == moderator;

  static bool canAccessAdminDashboard(String? role) =>
      _isModeratorOrAbove(role) || role == contentEditor;

  /// Kann User in Supabase persistieren / massiv eingreifen.
  /// Nur Root: User loeschen + Rollen auf admin/root_admin setzen.
  static bool canManageUsers(String? role) => _isRoot(role);

  /// Rollen aendern? Root darf alles, admin nur bis zu 'moderator'.
  static bool canPromoteDemote(String? role) => _isAdminLike(role);

  /// Nur Root darf zu root_admin/admin promoten -- admin nur bis moderator.
  static bool canPromoteToRole(String? actorRole, String? targetRole) {
    if (_isRoot(actorRole)) return true;
    if (actorRole == admin) {
      // admin darf maximal moderator/content_editor/user setzen
      return targetRole == moderator ||
          targetRole == contentEditor ||
          targetRole == user;
    }
    return false;
  }

  /// Wer darf die User-Liste im Dashboard sehen?
  static bool canViewUserList(String? role) => _isModeratorOrAbove(role);

  /// Wer darf User vollstaendig loeschen? Nur Root.
  static bool canDeleteUsers(String? role) => _isRoot(role);

  /// Wer darf bannen/entbannen? Moderator+
  static bool canBanUsers(String? role) => _isModeratorOrAbove(role);

  /// Wer darf XP vergeben? Admin+
  static bool canGrantXp(String? role) => _isAdminLike(role);

  /// Wer darf Chat-Nachrichten loeschen? Moderator+
  static bool canDeleteMessages(String? role) => _isModeratorOrAbove(role);

  /// Wer darf Audit-Log sehen? Admin+ (Root sieht alles inkl. detaillierter Reports)
  static bool canViewAuditLog(String? role) => _isAdminLike(role);

  /// Wer darf Profile-Sync triggern? Admin+
  static bool canRunUserSync(String? role) => _isAdminLike(role);

  /// Wer darf Nachrichten anpinnen? Moderator+ (Phase 3b: ersetzt
  /// AdminPermissions.canPinMessages).
  static bool canPinMessages(String? role) => _isModeratorOrAbove(role);

  /// Wer darf Mod-Tools sehen (Buttons im Chat, Mod-UI)? Moderator+
  static bool canViewModTools(String? role) => _isModeratorOrAbove(role);

  /// Wer darf Voice-Kick / Mute in Live-Sessions? Moderator+
  static bool canModerateVoice(String? role) => _isModeratorOrAbove(role);

  /// Wer darf Announcements / Broadcasts erstellen? Admin+
  static bool canCreateAnnouncements(String? role) => _isAdminLike(role);

  /// Liste der Rollen die ein bestimmter Actor vergeben darf (fuer Bulk-Role-Dialog).
  static List<String> rolesForPromotion(String? actorRole) {
    if (_isRoot(actorRole)) {
      return [user, moderator, contentEditor, admin, rootAdmin];
    }
    if (actorRole == admin) {
      return [user, moderator, contentEditor];
    }
    return [user];
  }

  /// Wer darf Feature-Flags aendern? Root-Admin only.
  static bool canManageKillSwitch(String? role) => _isRoot(role);

  // ============================================================================
  // BADGES + LABELS (ersetzt AdminPermissions.getAdminBadge etc.)
  // ============================================================================

  /// Emoji-Badge fuer eine Rolle. Leer-String wenn 'user'/unbekannt.
  static String getBadgeEmoji(String? role) {
    if (_isRoot(role)) return '👑';
    if (role == admin) return '🛡️';
    if (role == contentEditor) return '✍️';
    if (role == moderator) return '⚔️';
    return '';
  }

  /// Klartext-Title fuer Rollen-Anzeige in UI.
  static String getRoleTitle(String? role) {
    if (_isRoot(role)) return 'Root-Admin';
    if (role == admin) return 'Administrator';
    if (role == contentEditor) return 'Content-Editor';
    if (role == moderator) return 'Moderator';
    if (role == user) return 'Benutzer';
    return 'Benutzer';
  }

  // ============================================================================
  // BERECHTIGUNGS-CHECKS - CONTENT MANAGEMENT
  // ============================================================================

  /// Kann Content bearbeiten (Tabs, Tools, Marker, Medien)
  static bool canEditContent(String? role) =>
      _isRoot(role) || role == contentEditor;
  static bool canManageTabs(String? role) =>
      _isRoot(role) || role == contentEditor;
  static bool canManageTools(String? role) =>
      _isRoot(role) || role == contentEditor;
  static bool canManageMarkers(String? role) =>
      _isRoot(role) || role == contentEditor;
  static bool canManageMedia(String? role) =>
      _isRoot(role) || role == contentEditor;
  static bool canManageFeatureFlags(String? role) =>
      _isRoot(role) || role == contentEditor;
  static bool canPublishContent(String? role) =>
      _isRoot(role) || role == contentEditor;
  static bool canManageVersions(String? role) =>
      _isRoot(role) || role == contentEditor;
  static bool canViewChangeLog(String? role) =>
      _isRoot(role) || role == contentEditor;
  static bool canUseSandbox(String? role) =>
      _isRoot(role) || role == contentEditor;

  // ============================================================================
  // HELPER FUNCTIONS
  // ============================================================================

  /// Ist der User ein Admin (irgendeine Admin-Rolle)
  static bool isAdmin(String? role) =>
      role == admin ||
      _isRoot(role) ||
      role == contentEditor ||
      role == moderator;

  /// Ist der User Root-Admin (volle Rechte)
  static bool isRootAdmin(String? role) => _isRoot(role);

  /// Ist der User Content-Editor (nur Content-Rechte)
  static bool isContentEditor(String? role) => role == contentEditor;

  /// Helper für Offline-Fallback - Check by Username.
  /// AUDIT-FIX B9: trim + lowercase damit polluted SharedPrefs
  /// (' Weltenbibliothek\n') noch korrekt erkannt werden.
  static bool isRootAdminByUsername(String? username) =>
      username?.trim().toLowerCase() == rootAdminUsername.toLowerCase();

  /// Helper für Offline-Fallback - Check by Username
  static bool isContentEditorByUsername(String? username) =>
      username?.trim().toLowerCase() == contentEditorUsername.toLowerCase();

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

    return user; // Fallback für normale User
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
