import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../widgets/user_list_tile.dart';
import 'user_profile_screen.dart';
import 'user_search_screen.dart';

/// ═══════════════════════════════════════════════════════════════
/// USER LIST SCREEN - Weltenbibliothek
/// ═══════════════════════════════════════════════════════════════
/// Zeigt alle Benutzer der Weltenbibliothek
/// Features:
/// - Alle Benutzer anzeigen
/// - Gruppierung: Online → Offline
/// - Sortierung: Rolle (Admin → Moderator → User) + Alphabetisch
/// - Online-Status live anzeigen
/// - Pull-to-Refresh
/// - Tap → User-Profil öffnen
/// - Suchbutton → User-Search-Screen
/// ═══════════════════════════════════════════════════════════════

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final userProvider = context.read<UserProvider>();
    await userProvider.fetchAllUsers();
  }

  void _navigateToProfile(User user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(username: user.username),
      ),
    );
  }

  void _navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserSearchScreen()),
    );
  }

  List<User> _sortUsers(List<User> users) {
    // Kopie erstellen, um Original nicht zu verändern
    final sortedUsers = List<User>.from(users);

    sortedUsers.sort((a, b) {
      // 1. Erst nach Online-Status
      if (a.isOnline && !b.isOnline) return -1;
      if (!a.isOnline && b.isOnline) return 1;

      // 2. Dann nach Rolle
      final roleOrder = {
        'super_admin': 0,
        'admin': 1,
        'moderator': 2,
        'user': 3,
      };
      final roleComparison = (roleOrder[a.role] ?? 3).compareTo(
        roleOrder[b.role] ?? 3,
      );
      if (roleComparison != 0) return roleComparison;

      // 3. Dann alphabetisch nach Username
      return a.username.toLowerCase().compareTo(b.username.toLowerCase());
    });

    return sortedUsers;
  }

  Map<String, List<User>> _groupUsers(List<User> users) {
    final sortedUsers = _sortUsers(users);

    final Map<String, List<User>> groups = {'online': [], 'offline': []};

    for (final user in sortedUsers) {
      if (user.isOnline) {
        groups['online']!.add(user);
      } else {
        groups['offline']!.add(user);
      }
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final allUsers = userProvider.allUsers;
    final isLoading = userProvider.isLoading;
    final error = userProvider.error;

    final groupedUsers = _groupUsers(allUsers);
    final onlineUsers = groupedUsers['online']!;
    final offlineUsers = groupedUsers['offline']!;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Benutzer', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: _navigateToSearch,
          ),
        ],
      ),
      body: _buildBody(
        isLoading: isLoading,
        error: error,
        onlineUsers: onlineUsers,
        offlineUsers: offlineUsers,
      ),
    );
  }

  Widget _buildBody({
    required bool isLoading,
    required String? error,
    required List<User> onlineUsers,
    required List<User> offlineUsers,
  }) {
    if (isLoading && onlineUsers.isEmpty && offlineUsers.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
        ),
      );
    }

    if (error != null && onlineUsers.isEmpty && offlineUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              error,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUsers,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
              ),
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    if (onlineUsers.isEmpty && offlineUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Benutzer gefunden',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      color: const Color(0xFF8B5CF6),
      backgroundColor: const Color(0xFF1E293B),
      child: ListView(
        children: [
          // Statistiken-Header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.people,
                  label: 'Gesamt',
                  value: '${onlineUsers.length + offlineUsers.length}',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _buildStatItem(
                  icon: Icons.circle,
                  label: 'Online',
                  value: '${onlineUsers.length}',
                  iconColor: Colors.greenAccent,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _buildStatItem(
                  icon: Icons.circle_outlined,
                  label: 'Offline',
                  value: '${offlineUsers.length}',
                  iconColor: Colors.grey,
                ),
              ],
            ),
          ),

          // Online-Benutzer
          if (onlineUsers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ONLINE (${onlineUsers.length})',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            ...onlineUsers.map(
              (user) => UserListTile(
                user: user,
                onTap: () => _navigateToProfile(user),
                showOnlineStatus: true,
                showRoleBadge: true,
              ),
            ),
          ],

          // Offline-Benutzer
          if (offlineUsers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'OFFLINE (${offlineUsers.length})',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            ...offlineUsers.map(
              (user) => UserListTile(
                user: user,
                onTap: () => _navigateToProfile(user),
                showOnlineStatus: true,
                showRoleBadge: true,
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor ?? Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
