import 'package:flutter/material.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/world_admin_service.dart';
import '../../features/admin/state/admin_state.dart';

/// 🛡️ USER MODERATION SCREEN V16.2 (MIT USER-LISTE)
/// 
/// Zeigt vorhandene User an und ermöglicht Admin-Aktionen:
/// - User Ban/Unban
/// - User Mute
/// - User Status Check
/// 
/// ⚠️ WICHTIG: ROLLEN-PRÜFUNG
/// Screen prüft Admin-Status via adminStateProvider
/// Nur Root Admins können zugreifen

class UserModerationScreenV16 extends ConsumerStatefulWidget {
  final String world;
  
  const UserModerationScreenV16({
    super.key,
    required this.world,
  });

  @override
  ConsumerState<UserModerationScreenV16> createState() => _UserModerationScreenV16State();
}

class _UserModerationScreenV16State extends ConsumerState<UserModerationScreenV16> {
  List<WorldUser> _users = [];
  bool _isLoading = true;
  String? _error;
  
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
        _users = users;
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
        debugPrint('❌ Failed to load users: $e');
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
          title: Text('User ${user.username} bannen'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Grund',
                    hintText: 'Warum wird dieser User gebannt?',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Dauer: '),
                    Expanded(
                      child: Slider(
                        value: durationHours.toDouble(),
                        min: 1,
                        max: 168, // 7 Tage
                        divisions: 167,
                        label: '$durationHours Stunden',
                        onChanged: (value) {
                          setDialogState(() {
                            durationHours = value.toInt();
                          });
                        },
                      ),
                    ),
                    Text('$durationHours h'),
                  ],
                ),
              ],
            ),
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
    
    final reason = reasonController.text.trim();
    if (reason.isEmpty) {
      _showError('Bitte gib einen Grund an');
      return;
    }
    
    try {
      final success = await WorldAdminServiceV162.banUser(
        userId: user.userId,
        reason: reason,
        durationHours: durationHours,
      );
      
      if (mounted) {
        if (success) {
          _showSuccess('${user.username} wurde für $durationHours Stunden gebannt');
          _loadUsers(); // Refresh
        } else {
          _showError('Ban fehlgeschlagen');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Fehler: $e');
      }
    }
  }
  
  /// Unban User
  Future<void> _unbanUser(WorldUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user.username} entbannen?'),
        content: const Text('Möchtest du diesen User wirklich entbannen?'),
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
      final success = await WorldAdminServiceV162.unbanUser(
        userId: user.userId,
      );
      
      if (mounted) {
        if (success) {
          _showSuccess('${user.username} wurde entbannt');
          _loadUsers(); // Refresh
        } else {
          _showError('Entbannen fehlgeschlagen');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Fehler: $e');
      }
    }
  }
  
  /// Check User Status
  Future<void> _checkUserStatus(WorldUser user) async {
    try {
      final status = await WorldAdminServiceV162.checkUserStatus(
        userId: user.userId,
      );
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Status: ${user.username}'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatusRow('Gebannt', status['banned'] == true ? 'Ja' : 'Nein'),
                  _buildStatusRow('Stumm', status['muted'] == true ? 'Ja' : 'Nein'),
                  if (status['banDetails'] != null) ...[
                    const Divider(),
                    const Text('Ban Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                    _buildStatusRow('Grund', status['banDetails']['reason'] ?? 'N/A'),
                    _buildStatusRow('Gebannt von', status['banDetails']['bannedBy'] ?? 'N/A'),
                    _buildStatusRow('Ablauf', status['banDetails']['expiresAt'] ?? 'Permanent'),
                  ],
                  if (status['muteDetails'] != null) ...[
                    const Divider(),
                    const Text('Mute Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                    _buildStatusRow('Grund', status['muteDetails']['reason'] ?? 'N/A'),
                    _buildStatusRow('Stumm von', status['muteDetails']['mutedBy'] ?? 'N/A'),
                    _buildStatusRow('Ablauf', status['muteDetails']['expiresAt'] ?? 'Permanent'),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Schließen'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Fehler: $e');
      }
    }
  }
  
  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // ✅ ROLLEN-PRÜFUNG
    final admin = ref.watch(adminStateProvider(widget.world));
    
    if (!admin.isRootAdmin) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Keine Root Admin Berechtigung',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Fehler: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUsers,
              child: const Text('Erneut versuchen'),
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
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Keine User gefunden'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUsers,
              child: const Text('Neu laden'),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.people, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'User Management',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text('${_users.length} User gefunden'),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadUsers,
                tooltip: 'Neu laden',
              ),
            ],
          ),
        ),
        
        // User List
        Expanded(
          child: ListView.builder(
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: user.isRootAdmin
                        ? Colors.amber
                        : user.isAdmin
                            ? Colors.blue
                            : Colors.grey,
                    child: Text(
                      user.avatarEmoji ?? '👤',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(user.username),
                      if (user.isRootAdmin) ...[
                        const SizedBox(width: 8),
                        const Chip(
                          label: Text('ROOT', style: TextStyle(fontSize: 10)),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          backgroundColor: Colors.amber,
                        ),
                      ] else if (user.isAdmin) ...[
                        const SizedBox(width: 8),
                        const Chip(
                          label: Text('ADMIN', style: TextStyle(fontSize: 10)),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          backgroundColor: Colors.blue,
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text('Rolle: ${user.role}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'ban':
                          _banUser(user);
                          break;
                        case 'unban':
                          _unbanUser(user);
                          break;
                        case 'status':
                          _checkUserStatus(user);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'status',
                        child: Row(
                          children: [
                            Icon(Icons.info_outline),
                            SizedBox(width: 8),
                            Text('Status prüfen'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'ban',
                        child: Row(
                          children: [
                            Icon(Icons.block, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Bannen'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'unban',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Entbannen'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
