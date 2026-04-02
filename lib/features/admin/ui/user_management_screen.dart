import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../../../services/user_management_service.dart';
import '../../../models/user_management_models.dart';
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
  final UserManagementService _service = UserManagementService();
  final TextEditingController _searchController = TextEditingController();
  
  List<WorldUser> _users = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedRole; // null = all, 'user', 'admin', 'root_admin'
  int _total = 0;
  int _currentPage = 0;
  final int _pageSize = 50;

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

  Future<void> _loadUsers({bool append = false}) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // ⚠️ CRITICAL: Token-Validation
      if (widget.adminToken.isEmpty) {
        throw Exception('Kein Profil gefunden! Bitte erstelle zuerst ein Profil in deiner Welt.');
      }
      
      final result = await _service.getUsers(
        world: widget.world,
        adminToken: widget.adminToken,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        role: _selectedRole,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      final users = (result['users'] as List<dynamic>?)
          ?.map((json) => WorldUser.fromJson(json as Map<String, dynamic>))
          .toList() ?? [];

      setState(() {
        if (append) {
          _users.addAll(users);
        } else {
          _users = users;
        }
        _total = result['total'] as int? ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _search() {
    setState(() {
      _currentPage = 0;
      _users.clear();
    });
    _loadUsers();
  }

  void _loadMore() {
    if (_users.length < _total) {
      setState(() {
        _currentPage++;
      });
      _loadUsers(append: true);
    }
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
          _currentPage = 0;
          _users.clear();
        });
        _loadUsers();
      },
      backgroundColor: const Color(0xFF16213E),
      selectedColor: color.withValues(alpha: 0.3),
      checkmarkColor: color,
      side: BorderSide(color: color, width: 1),
    );
  }

  Widget _buildBody(Color worldColor) {
    if (_isLoading && _users.isEmpty) {
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
              onPressed: () {
                setState(() {
                  _currentPage = 0;
                  _users.clear();
                });
                _loadUsers();
              },
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

    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'Keine User gefunden',
              style: TextStyle(color: Colors.grey[400], fontSize: 18),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // TOTAL COUNT
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${_users.length} von $_total Usern',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
        
        // USER LIST
        Expanded(
          child: ListView.builder(
            itemCount: _users.length + (_users.length < _total ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _users.length) {
                // LOAD MORE BUTTON
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _loadMore,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_downward),
                      label: Text(_isLoading ? 'Laden...' : 'Mehr laden'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: worldColor,
                      ),
                    ),
                  ),
                );
              }

              final user = _users[index];
              return _buildUserCard(user, worldColor);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(WorldUser user, Color worldColor) {
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF16213E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: user.isSuspended ? Colors.red : worldColor.withValues(alpha: 0.3),
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
                world: widget.world,
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
                backgroundColor: worldColor.withValues(alpha: 0.2),
                child: user.avatarEmoji != null
                    ? Text(user.avatarEmoji!, style: const TextStyle(fontSize: 24))
                    : Text(
                        user.username[0].toUpperCase(),
                        style: TextStyle(
                          color: worldColor,
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
                        Text(
                          user.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
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
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${user.id}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    if (user.lastActivityAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Letzte Aktivität: ${_formatDateTime(user.lastActivityAt!)}',
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
    
    return '${dt.day}.${dt.month}.${dt.year}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
