import 'package:flutter/material.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/world_admin_service.dart';
import '../../features/admin/state/admin_state.dart';

/// 🛡️ USER MODERATION SCREEN V16.2 (MIT USER-LISTE)
/// 
/// FEATURES:
/// - ✅ User-Liste aus Backend laden (keine manuelle Eingabe!)
/// - ✅ Ban/Unban direkt aus der Liste
/// - ✅ Mute-Funktion
/// - ✅ User-Status anzeigen
/// - ✅ Filter nach Rolle (Alle, User, Admin, Root-Admin)
/// - ✅ Suche nach Username
/// 
/// ROLLEN-PRÜFUNG:
/// - Nur Root-Admins haben Zugriff
/// - adminStateProvider wird respektiert

class UserModerationScreenV16List extends ConsumerStatefulWidget {
  final String world;
  
  const UserModerationScreenV16List({
    super.key,
    required this.world,
  });

  @override
  ConsumerState<UserModerationScreenV16List> createState() => _UserModerationScreenV16ListState();
}

class _UserModerationScreenV16ListState extends ConsumerState<UserModerationScreenV16List> {
  List<WorldUser> _allUsers = [];
  List<WorldUser> _filteredUsers = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'user', 'admin', 'root_admin'
  
  // User Status Cache
  final Map<String, Map<String, dynamic>> _userStatusCache = {};
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsers();
    });
  }
  
  /// Load Users from Backend
  Future<void> _loadUsers() async {
    // ✅ ROLLEN-PRÜFUNG
    final admin = ref.read(adminStateProvider(widget.world));
    
    if (!admin.isRootAdmin) {
      setState(() {
        _error = 'Keine Root Admin Berechtigung';
        _isLoading = false;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final users = await WorldAdminService.getUsersByWorld(
        widget.world,
        role: admin.role ?? 'root_admin',
      );
      
      setState(() {
        _allUsers = users;
        _applyFilters();
        _isLoading = false;
      });
      
      if (kDebugMode) {
        debugPrint('✅ Loaded ${users.length} users');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      
      if (kDebugMode) {
        debugPrint('❌ Load users error: $e');
      }
    }
  }
  
  /// Apply Filters
  void _applyFilters() {
    List<WorldUser> filtered = List.from(_allUsers);
    
    // Filter by role
    if (_selectedFilter != 'all') {
      filtered = filtered.where((user) {
        if (_selectedFilter == 'root_admin') return user.isRootAdmin;
        if (_selectedFilter == 'admin') return user.isAdmin && !user.isRootAdmin;
        if (_selectedFilter == 'user') return !user.isAdmin;
        return true;
      }).toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        final username = user.username.toLowerCase();
        final displayName = (user.displayName ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return username.contains(query) || displayName.contains(query);
      }).toList();
    }
    
    setState(() {
      _filteredUsers = filtered;
    });
  }
  
  /// Load User Status
  Future<void> _loadUserStatus(String userId) async {
    try {
      final status = await WorldAdminServiceV162.checkUserStatus(userId: userId);
      setState(() {
        _userStatusCache[userId] = status;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Status load error: $e');
      }
    }
  }
  
  /// Ban User
  Future<void> _banUser(WorldUser user) async {
    final reasonController = TextEditingController();
    int durationHours = 24;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('🚫 ${user.username} bannen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Grund',
                  hintText: 'Warum wird dieser User gebannt?',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: durationHours,
                decoration: const InputDecoration(labelText: 'Dauer'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 Stunde')),
                  DropdownMenuItem(value: 24, child: Text('24 Stunden')),
                  DropdownMenuItem(value: 168, child: Text('7 Tage')),
                  DropdownMenuItem(value: 720, child: Text('30 Tage')),
                  DropdownMenuItem(value: 0, child: Text('Permanent')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    durationHours = value ?? 24;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Bannen'),
            ),
          ],
        ),
      ),
    );
    
    if (result != true) return;
    
    try {
      final success = await WorldAdminServiceV162.banUser(
        userId: user.userId,
        reason: reasonController.text.isNotEmpty ? reasonController.text : 'Kein Grund angegeben',
        durationHours: durationHours,
      );
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${user.username} wurde gebannt'),
              backgroundColor: Colors.green,
            ),
          );
          _loadUserStatus(user.userId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Ban fehlgeschlagen'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Unban User
  Future<void> _unbanUser(WorldUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('✅ ${user.username} entbannen?'),
        content: const Text('Möchtest du den Ban aufheben?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Entbannen'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    try {
      final success = await WorldAdminServiceV162.unbanUser(userId: user.userId);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${user.username} wurde entbannt'),
              backgroundColor: Colors.green,
            ),
          );
          _loadUserStatus(user.userId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Unban fehlgeschlagen'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Unmute User
  Future<void> _unmuteUser(WorldUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🔊 ${user.username} entstummen?'),
        content: const Text('Möchtest du die Stummschaltung aufheben?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Entstummen'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    try {
      final success = await WorldAdminServiceV162.unmuteUser(userId: user.userId);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${user.username} wurde entstummt'),
              backgroundColor: Colors.green,
            ),
          );
          _loadUserStatus(user.userId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Unmute fehlgeschlagen'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Mute User
  Future<void> _muteUser(WorldUser user) async {
    final reasonController = TextEditingController();
    int durationMinutes = 30;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('🔇 ${user.username} stumm schalten'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Grund',
                  hintText: 'Warum wird dieser User stumm geschaltet?',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: durationMinutes,
                decoration: const InputDecoration(labelText: 'Dauer'),
                items: const [
                  DropdownMenuItem(value: 10, child: Text('10 Minuten')),
                  DropdownMenuItem(value: 30, child: Text('30 Minuten')),
                  DropdownMenuItem(value: 60, child: Text('1 Stunde')),
                  DropdownMenuItem(value: 1440, child: Text('24 Stunden')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    durationMinutes = value ?? 30;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Stumm schalten'),
            ),
          ],
        ),
      ),
    );
    
    if (result != true) return;
    
    try {
      final success = await WorldAdminServiceV162.muteUser(
        userId: user.userId,
        reason: reasonController.text.isNotEmpty ? reasonController.text : 'Kein Grund angegeben',
        durationMinutes: durationMinutes,
      );
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${user.username} wurde stumm geschaltet'),
              backgroundColor: Colors.green,
            ),
          );
          _loadUserStatus(user.userId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Mute fehlgeschlagen'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // ✅ ROLLEN-PRÜFUNG
    final admin = ref.watch(adminStateProvider(widget.world));
    
    if (!admin.isRootAdmin) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Keine Root Admin Berechtigung',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Nur Root Admins können User moderieren', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }
    
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.manage_accounts, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      'User Moderation',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadUsers,
                      tooltip: 'Neu laden',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Search
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Suche nach Username...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Filter Buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      _buildFilterChip('Alle', 'all'),
                      _buildFilterChip('User', 'user'),
                      _buildFilterChip('Admin', 'admin'),
                      _buildFilterChip('Root-Admin', 'root_admin'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // User List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text('Fehler beim Laden', style: TextStyle(fontSize: 18)),
                            const SizedBox(height: 8),
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadUsers,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Erneut versuchen'),
                            ),
                          ],
                        ),
                      )
                    : _filteredUsers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'Keine User gefunden für "$_searchQuery"'
                                      : 'Keine User gefunden',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              return _buildUserTile(user);
                            },
                          ),
          ),
        ],
      ),
    );
  }
  
  /// Filter Chip
  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
            _applyFilters();
          });
        },
        selectedColor: Colors.blue,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
    );
  }
  
  /// User Tile
  Widget _buildUserTile(WorldUser user) {
    final status = _userStatusCache[user.userId];
    final isBanned = status?['banned'] == true;
    final isMuted = status?['muted'] == true;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: user.isRootAdmin
              ? Colors.amber
              : user.isAdmin
                  ? Colors.blue
                  : Colors.grey,
          child: Text(user.avatarEmoji ?? '👤'),
        ),
        title: Row(
          children: [
            Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            if (user.isRootAdmin)
              const Chip(
                label: Text('ROOT', style: TextStyle(fontSize: 10)),
                padding: EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
                backgroundColor: Colors.amber,
              ),
            if (user.isAdmin && !user.isRootAdmin)
              const Chip(
                label: Text('ADMIN', style: TextStyle(fontSize: 10)),
                padding: EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
                backgroundColor: Colors.blue,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.displayName ?? user.username),
            if (isBanned)
              const Text('🚫 GEBANNT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            if (isMuted)
              const Text('🔇 STUMM', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Info
                _buildInfoRow('User-ID:', user.userId),
                _buildInfoRow('Display Name:', user.displayName ?? user.username),
                _buildInfoRow('Rolle:', user.role),
                _buildInfoRow('Erstellt:', user.createdAt.split('T')[0] ?? 'N/A'),
                
                const Divider(height: 24),
                
                // Status
                if (status != null) ...[
                  const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (isBanned) ...[
                    _buildInfoRow('Ban Grund:', status['banDetails']?['reason'] ?? 'N/A'),
                    _buildInfoRow('Gebannt von:', status['banDetails']?['bannedBy'] ?? 'N/A'),
                    _buildInfoRow('Läuft ab:', status['banDetails']?['expiresAt']?.split('T')[0] ?? 'Permanent'),
                  ],
                  if (isMuted) ...[
                    _buildInfoRow('Mute Grund:', status['muteDetails']?['reason'] ?? 'N/A'),
                    _buildInfoRow('Stumm von:', status['muteDetails']?['mutedBy'] ?? 'N/A'),
                  ],
                ] else
                  ElevatedButton.icon(
                    onPressed: () => _loadUserStatus(user.userId),
                    icon: const Icon(Icons.info, size: 16),
                    label: const Text('Status laden'),
                  ),
                
                const SizedBox(height: 16),
                
                // Actions
                Wrap(
                  spacing: 8,
                  children: [
                    if (!isBanned)
                      ElevatedButton.icon(
                        onPressed: () => _banUser(user),
                        icon: const Icon(Icons.block, size: 16),
                        label: const Text('Bannen'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      ),
                    if (isBanned)
                      ElevatedButton.icon(
                        onPressed: () => _unbanUser(user),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Entbannen'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                    if (!isMuted)
                      ElevatedButton.icon(
                        onPressed: () => _muteUser(user),
                        icon: const Icon(Icons.volume_off, size: 16),
                        label: const Text('Stumm schalten'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      ),
                    if (isMuted)
                      ElevatedButton.icon(
                        onPressed: () => _unmuteUser(user),
                        icon: const Icon(Icons.volume_up, size: 16),
                        label: const Text('Entstummen'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Info Row
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
