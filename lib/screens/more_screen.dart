import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/user_provider.dart';
import '../widgets/role_badge.dart';
import 'admin_dashboard_screen.dart';
import 'moderator_dashboard_screen.dart';
import 'user_profile_screen.dart';
import 'user_list_screen.dart';
import 'user_search_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  final AuthService _authService = AuthService();

  Map<String, dynamic>? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text(
          'Mehr',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildProfileCard(),
                const SizedBox(height: 24),

                // ═══════════════════════════════════════════════════
                // USER PROFILE SECTION (Phase 3)
                // ═══════════════════════════════════════════════════
                _buildSectionTitle('Profil'),
                _buildMenuItem(
                  icon: Icons.person,
                  title: 'Mein Profil',
                  subtitle: 'Profil anzeigen und bearbeiten',
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    final userProvider = context.read<UserProvider>();
                    final currentUser = userProvider.currentUser;
                    if (currentUser != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              UserProfileScreen(username: currentUser.username),
                        ),
                      );
                    }
                  },
                ),
                _buildMenuItem(
                  icon: Icons.people,
                  title: 'Benutzer',
                  subtitle: 'Alle Benutzer anzeigen',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserListScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.search,
                  title: 'Benutzer suchen',
                  subtitle: 'Nach Benutzern suchen',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserSearchScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // ═══════════════════════════════════════════════════
                // ADMIN & MODERATOR SECTION (Conditional)
                // ═══════════════════════════════════════════════════
                if (_hasAdminOrModAccess()) ...[
                  _buildSectionTitle('Administration'),

                  // Super-Admin Dashboard
                  if (_currentUser?['role'] == 'super_admin')
                    _buildMenuItem(
                      icon: Icons.admin_panel_settings,
                      title: '👑 Super-Admin Dashboard',
                      subtitle: 'Volle Kontrolle über das System',
                      color: const Color(0xFFFFD700),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminDashboardScreen(),
                          ),
                        );
                      },
                    ),

                  // Admin Dashboard (for super_admin and admin)
                  if (_currentUser?['role'] == 'super_admin' ||
                      _currentUser?['role'] == 'admin')
                    _buildMenuItem(
                      icon: Icons.shield,
                      title: '🛡️ Admin Dashboard',
                      subtitle: 'Benutzer- und Rechteverwaltung',
                      color: const Color(0xFF4169E1),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminDashboardScreen(),
                          ),
                        );
                      },
                    ),

                  // Moderatoren Dashboard (for super_admin, admin, moderator)
                  if (_hasModeratorAccess())
                    _buildMenuItem(
                      icon: Icons.build,
                      title: '🔧 Moderatoren Dashboard',
                      subtitle: 'Content-Moderation und User-Verwaltung',
                      color: const Color(0xFF32CD32),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ModeratorDashboardScreen(),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 24),
                ],

                _buildSectionTitle('Einstellungen'),
                _buildMenuItem(
                  icon: Icons.notifications,
                  title: 'Benachrichtigungen',
                  subtitle: 'Push-Nachrichten verwalten',
                  onTap: () {},
                ),
                _buildMenuItem(
                  icon: Icons.language,
                  title: 'Sprache',
                  subtitle: 'Deutsch',
                  onTap: () {},
                ),
                _buildMenuItem(
                  icon: Icons.dark_mode,
                  title: 'Design',
                  subtitle: 'Dunkles Theme (Standard)',
                  onTap: () {},
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Information'),
                _buildMenuItem(
                  icon: Icons.info,
                  title: 'Über die App',
                  subtitle: 'Version 3.6.0',
                  onTap: () => _showAboutDialog(context),
                ),
                _buildMenuItem(
                  icon: Icons.privacy_tip,
                  title: 'Datenschutz',
                  subtitle: 'Datenschutzrichtlinien',
                  onTap: () {},
                ),
                _buildMenuItem(
                  icon: Icons.description,
                  title: 'Nutzungsbedingungen',
                  subtitle: 'AGB und Richtlinien',
                  onTap: () {},
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Support'),
                _buildMenuItem(
                  icon: Icons.help,
                  title: 'Hilfe & Support',
                  subtitle: 'FAQ und Kontakt',
                  onTap: () {},
                ),
                _buildMenuItem(
                  icon: Icons.bug_report,
                  title: 'Fehler melden',
                  subtitle: 'Problem oder Bug melden',
                  onTap: () {},
                ),
              ],
            ),
    );
  }

  bool _hasAdminOrModAccess() {
    final role = _currentUser?['role'] as String?;
    return role == 'super_admin' || role == 'admin' || role == 'moderator';
  }

  bool _hasModeratorAccess() {
    final role = _currentUser?['role'] as String?;
    return role == 'super_admin' || role == 'admin' || role == 'moderator';
  }

  Widget _buildProfileCard() {
    final username = _currentUser?['username'] as String? ?? 'Benutzer';
    final role = _currentUser?['role'] as String?;

    String roleText;
    switch (role) {
      case 'super_admin':
        roleText = '👑 Super-Administrator';
        break;
      case 'admin':
        roleText = '🛡️ Administrator';
        break;
      case 'moderator':
        roleText = '🔧 Moderator';
        break;
      default:
        roleText = 'Weltenbibliothek Mitglied';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9B59B6), Color(0xFF3498DB)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 36, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (role != null && role != 'user') ...[
                      const SizedBox(width: 8),
                      RoleBadge(role: role, size: 20),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  roleText,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF9B59B6),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final iconColor = color ?? const Color(0xFF9B59B6);

    return Card(
      color: const Color(0xFF1A1A2E),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white38,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Über Weltenbibliothek',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Version 3.6.0',
              style: TextStyle(
                color: Color(0xFF9B59B6),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Weltenbibliothek ist eine digitale Plattform zur Erkundung mystischer Orte und alternativer Forschung weltweit.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            const Text(
              '• 141 mystische Orte\n'
              '• Interaktive Karte\n'
              '• Live-Streaming System\n'
              '• Chat-System mit WebRTC\n'
              '• Admin & Moderator System\n'
              '• Historische Timeline',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Schließen',
              style: TextStyle(color: Color(0xFF9B59B6)),
            ),
          ),
        ],
      ),
    );
  }
}
