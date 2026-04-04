import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../../../services/world_admin_service.dart'; // WorldUser + WorldAdminService
import 'user_detail_screen.dart';

/// User Management Screen - Übersicht aller User
/// 
/// Features:
/// - User-Liste mit Avatar & Role-Badge
/// - Suche & Filter (Role, Status)
/// - Pagination
/// - Tap → User Detail Screen
class UserManagementScreen extends StatefulWidget {
  final String world; // 'materie' or 'energie'
  final String adminToken;
  final bool isRootAdmin;

  const UserManagementScreen({
    super.key,
    required this.world,
    required this.adminToken,
    required this.isRootAdmin,
  });

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  List<WorldUser> _allUsers = []; // Alle User aus beiden Welten
  List<WorldUser> _filteredUsers = []; // Gefilterte Ansicht
  bool _isLoading = false;
  String? _error;
  String? _selectedRole; // null = all, 'user', 'admin', 'root_admin'

  @override
  void initState() {
    super.initState();
    
    // 🔍 DEBUG: Token-Check
    if (kDebugMode) {
      debugPrint('🚀 [UserManagementScreen] initState:');
      debugPrint('   World: ${widget.world}');
      debugPrint('   Token: "${widget.adminToken}" (length: ${widget.adminToken.length})');
      debugPrint('   isRootAdmin: ${widget.isRootAdmin}');
    }
    
    _loadUsers();
  }

  /// FIXED: Laedt User aus BEIDEN Welten - Admin sieht alle mit Welt-Vermerk
  Future<void> _loadUsers() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (kDebugMode) {
        debugPrint('Lade User aus BEIDEN Welten fuer User Management...');
      }
      
      // FIXED: getAllUsers() laedt parallel Materie + Energie
      final users = await WorldAdminService.getAllUsers();
      
      if (kDebugMode) {
        final materieCount = users.where((u) => u.world == 'materie').length;
        final energieCount = users.where((u) => u.world == 'energie').length;
        debugPrint('Loaded ${users.length} users (Materie: $materieCount, Energie: $energieCount)');
      }

      setState(() {
        _allUsers = users;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Filter und Suche anwenden
  void _applyFilters() {
    List<WorldUser> filtered = List.from(_allUsers);
    
    // Filter by role
    if (_selectedRole != null) {
      filtered = filtered.where((user) {
        if (_selectedRole == 'root_admin') return user.isRootAdmin;
        if (_selectedRole == 'admin') return user.isAdmin && !user.isRootAdmin;
        if (_selectedRole == 'user') return !user.isAdmin;
        return true;
      }).toList();
    }
    
    // Filter by search query
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((user) {
        return user.username.toLowerCase().contains(query) ||
               (user.displayName ?? '').toLowerCase().contains(query);
      }).toList();
    }
    
    setState(() {
      _filteredUsers = filtered;
    });
  }

  void _search() {
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final worldColor = widget.world == 'materie' 
        ? const Color(0xFFFF6B35) 
        : const Color(0xFF4ECDC4);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Row(
          children: [
            Icon(Icons.people, color: worldColor),
            const SizedBox(width: 8),
            Text(
              'User Management',
              style: TextStyle(color: worldColor),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // SEARCH BAR
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Suche nach Username...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: worldColor),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white),
                            onPressed: () {
                              _searchController.clear();
                              _search();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF16213E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              
              // ROLE FILTER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Filter:',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('Alle', null, worldColor),
                            const SizedBox(width: 8),
                            _buildFilterChip('User', 'user', Colors.grey),
                            const SizedBox(width: 8),
                            _buildFilterChip('Admin', 'admin', Colors.orange),
                            const SizedBox(width: 8),
                            _buildFilterChip('Root-Admin', 'root_admin', Colors.red),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _buildBody(worldColor),
    );
  }

  Widget _buildFilterChip(String label, String? role, Color color) {
    final isSelected = _selectedRole == role;
    return FilterChip(
      label: Text(label),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : color,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedRole = role;
        });
        _applyFilters();
      },
      backgroundColor: const Color(0xFF16213E),
      selectedColor: color.withValues(alpha: 0.3),
      checkmarkColor: color,
      side: BorderSide(color: color, width: 1),
    );
  }

  Widget _buildBody(Color worldColor) {
    if (_isLoading && _allUsers.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: worldColor),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Fehler beim Laden',
              style: TextStyle(color: Colors.grey[300], fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: worldColor,
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Keine User gefunden fuer "${_searchController.text}"'
                  : 'Keine User gefunden',
              style: TextStyle(color: Colors.grey[400], fontSize: 18),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // USER-ZAEHLER MIT WELT-AUFSCHLUESSELUNG
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_filteredUsers.length} User',
                style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              _buildWorldCountBadge('Materie', _allUsers.where((u) => u.world == 'materie').length, const Color(0xFFFF6B35)),
              const SizedBox(width: 8),
              _buildWorldCountBadge('Energie', _allUsers.where((u) => u.world == 'energie').length, const Color(0xFF4ECDC4)),
            ],
          ),
        ),
        
        // USER LIST
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadUsers,
            child: ListView.builder(
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return _buildUserCard(user, worldColor);
              },
            ),
          ),
        ),
      ],
    );
  }
  
  /// Welt-Zaehler Badge
  Widget _buildWorldCountBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildUserCard(WorldUser user, Color defaultWorldColor) {
    // ROLE BADGE COLOR
    Color roleBadgeColor = Colors.grey;
    String roleLabel = 'User';
    if (user.isRootAdmin) {
      roleBadgeColor = Colors.red;
      roleLabel = 'ROOT';
    } else if (user.isAdmin) {
      roleBadgeColor = Colors.orange;
      roleLabel = 'ADMIN';
    }
    
    // WELT-FARBE basierend auf User-Welt
    final userWorldColor = user.world == 'energie' 
        ? const Color(0xFF4ECDC4) 
        : const Color(0xFFFF6B35);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF16213E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: user.isSuspended ? Colors.red : userWorldColor.withValues(alpha: 0.3),
          width: user.isSuspended ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserDetailScreen(
                user: user,
                world: user.world ?? widget.world, // FIXED: Nutze User-Welt
                adminToken: widget.adminToken,
                isRootAdmin: widget.isRootAdmin,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // AVATAR
              CircleAvatar(
                radius: 28,
                backgroundColor: userWorldColor.withValues(alpha: 0.2),
                child: user.avatarEmoji != null
                    ? Text(user.avatarEmoji!, style: const TextStyle(fontSize: 24))
                    : Text(
                        user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: userWorldColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              
              // USER INFO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.username,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // ROLE BADGE
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: roleBadgeColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: roleBadgeColor, width: 1),
                          ),
                          child: Text(
                            roleLabel,
                            style: TextStyle(
                              color: roleBadgeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // WELT-BADGE
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: userWorldColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: userWorldColor, width: 1),
                          ),
                          child: Text(
                            user.worldLabel,
                            style: TextStyle(fontSize: 9, color: userWorldColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${user.userId}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    if (user.lastActivityAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Letzte Aktivitaet: ${_formatDateTime(user.lastActivityAt!)}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                    if (user.isSuspended) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.block, color: Colors.red[300], size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'GESPERRT',
                            style: TextStyle(
                              color: Colors.red[300],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // CHEVRON
              Icon(Icons.chevron_right, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Jetzt';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std';
    if (diff.inDays < 7) return 'vor ${diff.inDays} Tagen';
    
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
