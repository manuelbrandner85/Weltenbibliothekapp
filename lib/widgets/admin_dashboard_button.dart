/// 🛡️ ADMIN-DASHBOARD-BUTTON
///
/// Hübscher, prominenter Button für den Schnellzugriff auf das
/// World-Admin-Dashboard. Wird in allen 4 Welten-Screens (Materie,
/// Energie, Vorhang, Ursprung) zwischen AppBar und Tab-Inhalt gerendert
/// — nur sichtbar wenn `adminState.isAdmin == true`.
///
/// Farben:
///   - Root-Admin     → Gold-Akzent (Krone)
///   - Admin          → Blau-Akzent (Shield)
///   - Moderator      → Grün-Akzent (Gavel)
///   - Content-Editor → Lila-Akzent (Edit)
///
/// Tappable → navigiert zum WorldAdminDashboard mit MaterialPageRoute.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/roles.dart';
import '../features/admin/state/admin_state.dart';
import '../screens/shared/world_admin_dashboard.dart';
import '../services/storage_service.dart';

class AdminDashboardButton extends StatefulWidget {
  const AdminDashboardButton({
    super.key,
    required this.adminState,
    required this.world,
  });

  final AdminState adminState;
  final String world;

  @override
  State<AdminDashboardButton> createState() => _AdminDashboardButtonState();
}

class _AdminDashboardButtonState extends State<AdminDashboardButton> {
  bool _fallbackIsAdmin = false;
  String? _fallbackRole;
  // v103 FIX 2: Race-Condition-Schutz. _resolveFallback() ist async.
  // Beim ersten build() ist _fallbackIsAdmin/_fallbackRole noch leer.
  // Mit _fallbackResolved=false rendern wir einen 0-Pixel-Platzhalter
  // statt SizedBox.shrink() -- so verschwindet der Button nicht
  // dauerhaft falls der Provider spaeter erst auflost.
  bool _fallbackResolved = false;

  @override
  void initState() {
    super.initState();
    _resolveFallback();
  }

  /// v102: Falls adminStateProvider noch nicht geladen ist (Provider haengt,
  /// Network-Timeout, Cache leer), checken wir parallel:
  ///   - Lokales Materie/Energie-Profil: Username == Root-Admin?
  ///   - Lokales Profil: Role-Feld bereits 'admin'/'root_admin'/...?
  ///   - Web-SharedPref: web_is_admin == true?
  /// Damit ist der Dashboard-Button auch dann sichtbar, wenn der
  /// adminStateProvider noch im Loading-State steht.
  Future<void> _resolveFallback() async {
    try {
      final storage = StorageService();
      final mUser = storage.getMaterieProfile()?.username;
      final eUser = storage.getEnergieProfile()?.username;
      final mRole = storage.getMaterieProfile()?.role;
      final eRole = storage.getEnergieProfile()?.role;

      final usernameMatch = AppRoles.isRootAdminByUsername(mUser) ||
          AppRoles.isRootAdminByUsername(eUser) ||
          AppRoles.isContentEditorByUsername(mUser) ||
          AppRoles.isContentEditorByUsername(eUser);
      final roleMatch = AppRoles.isAdmin(mRole) || AppRoles.isAdmin(eRole);

      bool webMatch = false;
      String? webRole;
      try {
        final prefs = await SharedPreferences.getInstance();
        webMatch = prefs.getBool('web_is_admin') ?? false;
        if (webMatch) {
          // Web-Login schreibt manchmal die Rolle in web_user_role.
          webRole = prefs.getString('web_user_role');
        }
      } catch (e) { if (kDebugMode) debugPrint('admin_dashboard_button: silent catch -> $e'); }

      String? resolvedRole;
      if (mRole != null && mRole.isNotEmpty) resolvedRole = mRole;
      if (resolvedRole == null && eRole != null && eRole.isNotEmpty) {
        resolvedRole = eRole;
      }
      if (resolvedRole == null &&
          (AppRoles.isRootAdminByUsername(mUser) ||
              AppRoles.isRootAdminByUsername(eUser))) {
        resolvedRole = AppRoles.rootAdmin;
      }
      if (resolvedRole == null &&
          (AppRoles.isContentEditorByUsername(mUser) ||
              AppRoles.isContentEditorByUsername(eUser))) {
        resolvedRole = AppRoles.contentEditor;
      }
      if (resolvedRole == null && webMatch) {
        resolvedRole = webRole ?? AppRoles.admin;
      }

      if (!mounted) return;
      setState(() {
        _fallbackIsAdmin = usernameMatch || roleMatch || webMatch;
        _fallbackRole = resolvedRole;
        _fallbackResolved = true;
      });
    } catch (_) {
      // Auch im Fehlerfall als resolved markieren -- sonst haengen wir
      // ewig im Placeholder-State.
      if (mounted) setState(() => _fallbackResolved = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // v103 FIX 2: Multi-Source-Access-Check. Button erscheint sobald
    // EINE Quelle Admin-Zugriff signalisiert (Provider-Role,
    // Provider-Flags, lokales Profil, Username-Match, Web-Pref). Damit
    // ist der Button auch dann da, wenn das Backend langsam ist oder
    // einer der Pfade noch nicht aufgeloest hat.
    final role = widget.adminState.role ?? _fallbackRole;
    final hasAccess = AppRoles.canAccessAdminDashboard(role) ||
        widget.adminState.isAdmin ||
        widget.adminState.isRootAdmin ||
        widget.adminState.isModerator ||
        _fallbackIsAdmin;

    // Solange weder Provider noch Fallback fertig sind: unsichtbarer
    // Platzhalter (SizedBox.shrink) statt 0-Pixel-Container. Beide werden
    // beim naechsten setState neu evaluiert; .shrink() entfernt den Knoten
    // aber sauber aus dem Semantik-Baum/Tab-Order.
    if (!hasAccess && role == null && !_fallbackResolved) {
      return const SizedBox.shrink();
    }
    if (!hasAccess) return const SizedBox.shrink();

    final scheme = _resolveScheme(role);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WorldAdminDashboard(world: widget.world),
              ),
            );
          },
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  scheme.deep,
                  scheme.deep.withValues(alpha: 0.85),
                ],
              ),
              border: Border.all(
                  color: scheme.accent.withValues(alpha: 0.4), width: 1),
              boxShadow: [
                BoxShadow(
                  color: scheme.accent.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [scheme.accent, scheme.accentBright],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.accent.withValues(alpha: 0.55),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(scheme.icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scheme.title,
                        style: TextStyle(
                          color: scheme.accentBright,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Admin-Dashboard · Alle Welten',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: scheme.accentBright.withValues(alpha: 0.9),
                    size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _AdminBtnScheme _resolveScheme(String? role) {
    if (role == AppRoles.rootAdmin || role == AppRoles.rootAdminLegacy) {
      return const _AdminBtnScheme(
        title: 'ROOT-ADMINISTRATOR',
        icon: Icons.workspace_premium_rounded, // Krone-ähnlich
        accent: Color(0xFFC9A84C),
        accentBright: Color(0xFFE0C872),
        deep: Color(0xFF1A1305),
      );
    }
    if (role == AppRoles.contentEditor) {
      return const _AdminBtnScheme(
        title: 'CONTENT-EDITOR',
        icon: Icons.edit_note_rounded,
        accent: Color(0xFFA855F7),
        accentBright: Color(0xFFC79AFF),
        deep: Color(0xFF1A0D2E),
      );
    }
    if (role == AppRoles.moderator) {
      return const _AdminBtnScheme(
        title: 'MODERATOR',
        icon: Icons.gavel_rounded,
        accent: Color(0xFF22C55E),
        accentBright: Color(0xFF55E089),
        deep: Color(0xFF0A1F11),
      );
    }
    // Admin (Standard)
    return const _AdminBtnScheme(
      title: 'ADMINISTRATOR',
      icon: Icons.shield_rounded,
      accent: Color(0xFF3B82F6),
      accentBright: Color(0xFF7DA7FF),
      deep: Color(0xFF050D1F),
    );
  }
}

class _AdminBtnScheme {
  const _AdminBtnScheme({
    required this.title,
    required this.icon,
    required this.accent,
    required this.accentBright,
    required this.deep,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final Color accentBright;
  final Color deep;
}
