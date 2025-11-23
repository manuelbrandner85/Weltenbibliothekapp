import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../widgets/role_badge.dart';
import '../widgets/moderation_tab.dart';
import '../widgets/user_moderation_dialog.dart';

/// ═══════════════════════════════════════════════════════════════
/// ADMIN DASHBOARD SCREEN - Weltenbibliothek
/// ═══════════════════════════════════════════════════════════════
/// Nur für Super-Admin und Admin sichtbar
/// Features:
/// - Alle User anzeigen
/// - User befördern/degradieren
/// - Admin-Aktionen-Log
/// ═══════════════════════════════════════════════════════════════

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();

  late TabController _tabController;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _actions = [];
  bool _isLoading = true;
  String? _currentUserRole;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkPermissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    try {
      final user = await _authService.getCurrentUser();
      final role = user?['role'] as String?;

      if (role != 'super_admin' && role != 'admin') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⛔ Keine Berechtigung für Admin-Dashboard'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      setState(() {
        _currentUserRole = role;
      });

      await _loadData();
    } catch (e) {
      setState(() {
        _error = 'Fehler beim Laden der Berechtigungen: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await _adminService.getAllUsers();
      final actions = await _adminService.getAdminActions(limit: 50);

      setState(() {
        _users = users;
        _actions = actions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Fehler beim Laden: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings, color: Colors.white),
            const SizedBox(width: 12),
            const Text('Admin Dashboard'),
            const SizedBox(width: 8),
            if (_currentUserRole == 'super_admin')
              const Icon(Icons.star, color: Color(0xFFFFD700), size: 20),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Benutzer'),
            Tab(icon: Icon(Icons.shield), text: 'Moderation'),
            Tab(icon: Icon(Icons.history), text: 'Aktionen'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorView()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUsersTab(),
                const ModerationTab(),
                _buildActionsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        backgroundColor: const Color(0xFF1E293B),
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    if (_users.isEmpty) {
      return const Center(child: Text('Keine Benutzer gefunden'));
    }

    // Gruppiere nach Rolle
    final superAdmins = _users
        .where((u) => u['role'] == 'super_admin')
        .toList();
    final admins = _users.where((u) => u['role'] == 'admin').toList();
    final moderators = _users.where((u) => u['role'] == 'moderator').toList();
    final users = _users
        .where((u) => u['role'] == 'user' || u['role'] == null)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (superAdmins.isNotEmpty) ...[
          _buildRoleSection(
            '👑 Super-Admins',
            superAdmins,
            const Color(0xFFFFD700),
          ),
          const SizedBox(height: 16),
        ],
        if (admins.isNotEmpty) ...[
          _buildRoleSection('🛡️ Admins', admins, const Color(0xFF4169E1)),
          const SizedBox(height: 16),
        ],
        if (moderators.isNotEmpty) ...[
          _buildRoleSection(
            '🔧 Moderatoren',
            moderators,
            const Color(0xFF32CD32),
          ),
          const SizedBox(height: 16),
        ],
        if (users.isNotEmpty) ...[
          _buildRoleSection('👤 Benutzer', users, Colors.grey),
        ],
      ],
    );
  }

  Widget _buildRoleSection(
    String title,
    List<Map<String, dynamic>> users,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        // ✅ ListView.builder statt Spread Operator (Memory Optimierung)
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: users.length,
          itemBuilder: (context, index) => _buildUserCard(users[index]),
        ),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final role = user['role'] as String?;
    final isSuperAdmin = role == 'super_admin';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFF1E293B),
      child: ListTile(
        leading: RoleBadge(role: role, size: 28),
        title: Text(
          user['username'],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          user['email'] ?? 'Keine E-Mail',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: isSuperAdmin
            ? const Chip(
                label: Text('Unantastbar', style: TextStyle(fontSize: 10)),
                backgroundColor: Color(0xFFFFD700),
              )
            : _buildActionMenu(user),
      ),
    );
  }

  Widget? _buildActionMenu(Map<String, dynamic> user) {
    final role = user['role'] as String?;
    final userId = user['id'] as int;

    List<PopupMenuEntry<String>> menuItems = [];

    // Nur Super-Admin kann zu Admin befördern
    if (_currentUserRole == 'super_admin') {
      if (role == 'user' || role == null) {
        menuItems.add(
          const PopupMenuItem(
            value: 'promote_admin',
            child: Row(
              children: [
                Icon(Icons.shield, color: Color(0xFF4169E1)),
                SizedBox(width: 8),
                Text('Zu Admin befördern'),
              ],
            ),
          ),
        );
      }
      if (role == 'admin') {
        menuItems.add(
          const PopupMenuItem(
            value: 'demote',
            child: Row(
              children: [
                Icon(Icons.arrow_downward, color: Colors.red),
                SizedBox(width: 8),
                Text('Zu User degradieren'),
              ],
            ),
          ),
        );
      }
    }

    // Super-Admin und Admin können Moderatoren verwalten
    if (_currentUserRole == 'super_admin' || _currentUserRole == 'admin') {
      if (role == 'user' || role == null) {
        menuItems.add(
          const PopupMenuItem(
            value: 'promote_moderator',
            child: Row(
              children: [
                Icon(Icons.build, color: Color(0xFF32CD32)),
                SizedBox(width: 8),
                Text('Zu Moderator befördern'),
              ],
            ),
          ),
        );
      }
      if (role == 'moderator') {
        menuItems.add(
          const PopupMenuItem(
            value: 'demote',
            child: Row(
              children: [
                Icon(Icons.arrow_downward, color: Colors.red),
                SizedBox(width: 8),
                Text('Zu User degradieren'),
              ],
            ),
          ),
        );
      }
    }

    // Moderation option (für Admins auf normale User/Moderatoren)
    if (_currentUserRole == 'super_admin' || _currentUserRole == 'admin') {
      if (role != 'super_admin' && role != 'admin') {
        if (menuItems.isNotEmpty) {
          menuItems.add(const PopupMenuDivider());
        }
        menuItems.add(
          const PopupMenuItem(
            value: 'moderation',
            child: Row(
              children: [
                Icon(Icons.security, color: Colors.orange),
                SizedBox(width: 8),
                Text('Moderation'),
              ],
            ),
          ),
        );
      }
    }

    if (menuItems.isEmpty) return null;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (value) =>
          _handleUserAction(value, userId, user['username'], role),
      itemBuilder: (context) => menuItems,
    );
  }

  Future<void> _handleUserAction(
    String action,
    int userId,
    String username,
    String? role,
  ) async {
    if (action == 'promote_admin') {
      await _promoteUser(userId, username, 'admin');
    } else if (action == 'promote_moderator') {
      await _promoteUser(userId, username, 'moderator');
    } else if (action == 'demote') {
      await _demoteUser(userId, username);
    } else if (action == 'moderation') {
      await showUserModerationDialog(
        context,
        userId: userId,
        username: username,
        currentUserRole: _currentUserRole ?? 'user',
      );
      // Reload data after moderation dialog closes
      await _loadData();
    }
  }

  Future<void> _promoteUser(int userId, String username, String role) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          '$username zu ${role == 'admin' ? 'Admin' : 'Moderator'} befördern?',
        ),
        content: Text(
          role == 'admin'
              ? 'Admins können Moderatoren ernennen und User verwalten.'
              : 'Moderatoren können Content moderieren und User kicken/muten.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Befördern'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final permissions = role == 'admin'
          ? [
              'manage_moderators',
              'manage_users',
              'view_analytics',
              'moderate_content',
            ]
          : ['moderate_content', 'kick_users', 'mute_users'];

      await _adminService.promoteUser(userId, role, permissions);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $username wurde zu $role befördert'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _demoteUser(int userId, String username) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('$username degradieren?'),
        content: const Text(
          'Der Benutzer wird alle Admin-/Moderator-Rechte verlieren.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Degradieren'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _adminService.demoteUser(userId);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $username wurde zu User degradiert'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildActionsTab() {
    if (_actions.isEmpty) {
      return const Center(child: Text('Keine Aktionen vorhanden'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _actions.length,
      itemBuilder: (context, index) {
        final action = _actions[index];
        return _buildActionCard(action);
      },
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action) {
    final actionType = action['action_type'] as String;
    final adminUsername = action['admin_username'] as String;
    final targetUsername = action['target_username'] as String?;
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
      (action['created_at'] as int) * 1000,
    );

    IconData icon;
    Color color;
    String text;

    if (actionType == 'promote_user') {
      icon = Icons.arrow_upward;
      color = Colors.green;
      text = '$adminUsername hat $targetUsername befördert';
    } else if (actionType == 'demote_user') {
      icon = Icons.arrow_downward;
      color = Colors.red;
      text = '$adminUsername hat $targetUsername degradiert';
    } else {
      icon = Icons.info;
      color = Colors.blue;
      text = '$adminUsername: $actionType';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFF1E293B),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(text, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          _formatTimestamp(timestamp),
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Gerade eben';
    if (difference.inMinutes < 60) return 'vor ${difference.inMinutes} Min';
    if (difference.inHours < 24) return 'vor ${difference.inHours} Std';
    return '${timestamp.day}.${timestamp.month}.${timestamp.year}';
  }
}
