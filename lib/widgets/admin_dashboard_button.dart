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

import '../core/constants/roles.dart';
import '../features/admin/state/admin_state.dart';
import '../screens/shared/world_admin_dashboard.dart';

class AdminDashboardButton extends StatelessWidget {
  const AdminDashboardButton({
    super.key,
    required this.adminState,
    required this.world,
  });

  final AdminState adminState;
  final String world;

  @override
  Widget build(BuildContext context) {
    if (!adminState.isAdmin) return const SizedBox.shrink();

    final scheme = _resolveScheme(adminState.role);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WorldAdminDashboard(world: world),
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
              border: Border.all(color: scheme.accent.withValues(alpha: 0.4), width: 1),
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
                      Text(
                        'Admin-Dashboard öffnen',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: scheme.accentBright.withValues(alpha: 0.9), size: 24),
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
