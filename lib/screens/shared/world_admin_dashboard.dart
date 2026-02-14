import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/world_admin_service.dart';
import '../../services/content_management_service.dart'; // ✅ PHASE 3: CONTENT MANAGEMENT
import '../../features/admin/state/admin_state.dart';
import '../../features/admin/ui/moderation_dashboard_screen.dart';
import '../../features/admin/ui/user_management_screen.dart'; // ✅ PHASE 2: USER MANAGEMENT
import '../admin/health_dashboard_screen.dart'; // 🏥 HEALTH DASHBOARD (NEW Phase 3)
import '../admin/user_moderation_screen_v16_list.dart'; // 🔧 V16.2 ADMIN APIs (MIT USER-LISTE!)
import '../../core/storage/unified_storage_service.dart'; // ✅ FALLBACK: Storage Service

/// 🛡️ WORLD ADMIN DASHBOARD (RIVERPOD VERSION)
/// 
/// Vollständig migriert zu Riverpod State Management:
/// ✅ Admin-Status kommt von adminStateProvider
/// ✅ Kein separater Backend-Check mehr
/// ✅ Automatische Updates bei Profil-Änderungen
/// ✅ Type-safe Admin-Berechtigungen
/// 
/// USAGE:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => WorldAdminDashboard(world: 'materie'),
///   ),
/// );
/// ```

class WorldAdminDashboard extends ConsumerStatefulWidget {
  final String world;  // 'materie' oder 'energie'
  
  const WorldAdminDashboard({
    super.key,
    required this.world,
  });

  @override
  ConsumerState<WorldAdminDashboard> createState() => _WorldAdminDashboardState();
}

class _WorldAdminDashboardState extends ConsumerState<WorldAdminDashboard> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Data State
  bool _isLoading = true;
  List<WorldUser> _users = [];
  List<AuditLogEntry> _auditLog = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this); // ✅ PHASE 3 + V16.2: 7 Tabs (User Mgmt, Users, Content, Audit-Log, Moderation, Health, V16.2 Moderation)
    
    // 🔥 SIMPLIFIED: State wurde bereits VOR Navigation geladen
    // Direkt Dashboard-Daten laden (State ist garantiert frisch)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadDashboardData();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  /// Load Dashboard Data
  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      // 🔥 SIMPLIFIED: State wurde bereits VOR Navigation frisch geladen
      // Kein Delay nötig - State ist garantiert aktuell
      final admin = ref.read(adminStateProvider(widget.world));
      
      if (kDebugMode) {
        debugPrint('🔍 DASHBOARD ADMIN-CHECK (FRISCHER STATE):');
        debugPrint('   World: ${widget.world}');
        debugPrint('   Username: ${admin.username}');
        debugPrint('   isAdmin: ${admin.isAdmin}');
        debugPrint('   isRootAdmin: ${admin.isRootAdmin}');
        debugPrint('   backendVerified: ${admin.backendVerified}');
      }
      
      // Validierung: Profil vorhanden?
      if (admin.username == null || admin.username!.isEmpty) {
        if (kDebugMode) {
          debugPrint('❌ DASHBOARD: Kein Username gefunden!');
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Kein Profil gefunden. Bitte erstelle zuerst ein Profil.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pop(context);
        }
        return;
      }
      
      // Validierung: Admin-Rechte vorhanden?
      if (!admin.isAdmin) {
        if (kDebugMode) {
          debugPrint('❌ DASHBOARD: User "${admin.username}" ist kein Admin!');
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Kein Admin-Zugriff. Diese Seite ist nur für Admins.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pop(context);
        }
        return;
      }
      
      if (kDebugMode) {
        debugPrint('✅ DASHBOARD: Admin-Check erfolgreich! User: ${admin.username}');
      }
      
      // Daten laden
      await Future.wait([
        _loadUsers(),
        _loadAuditLog(),
      ]);
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden der Dashboard-Daten: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  /// Load Users List
  Future<void> _loadUsers() async {
    try {
      // 🚀 PRODUCTION: Echte API verwenden
      final admin = ref.read(adminStateProvider(widget.world));
      final users = await WorldAdminService.getUsersByWorld(
        widget.world,
        role: admin.isRootAdmin ? 'root_admin' : 'admin',
      );
      
      if (mounted) {
        setState(() {
          _users = users;
        });
      }
      
      if (kDebugMode) {
        debugPrint('✅ Loaded ${users.length} users from backend');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden der User: $e');
      }
    }
  }
  
  /// Load Audit Log
  Future<void> _loadAuditLog() async {
    try {
      final logs = await WorldAdminService.getAuditLog(widget.world, limit: 100);
      if (mounted) {
        setState(() {
          _auditLog = logs;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden des Audit-Logs: $e');
      }
    }
  }
  
  /// Promote User to Admin
  Future<void> _promoteUser(WorldUser user) async {
    // 🔥 RIVERPOD: Admin-Status prüfen
    final admin = ref.read(adminStateProvider(widget.world));
    
    if (!admin.isRootAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Nur Root-Admins können User befördern.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (user.isRootAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Root-Admins können nicht befördert werden.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Bestätigung
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User zu Admin befördern?'),
        content: Text('Möchtest du ${user.username} zu Admin befördern?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Befördern'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    // Promote
    if (kDebugMode) {
      debugPrint('🔥 PROMOTE DEBUG:');
      debugPrint('   World: ${widget.world}');
      debugPrint('   UserId: ${user.userId}');
      debugPrint('   Admin Role: ${admin.role}');
      debugPrint('   Admin Username: ${admin.username}');
      debugPrint('   Admin isRootAdmin: ${admin.isRootAdmin}');
    }
    
    // 🔥 FIX: Fallback auf "root_admin" wenn role NULL
    final effectiveRole = admin.role ?? (admin.isRootAdmin ? 'root_admin' : 'admin');
    
    final success = await WorldAdminService.promoteUser(widget.world, user.userId, role: effectiveRole);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${user.username} wurde zu Admin befördert'),
            backgroundColor: Colors.green,
          ),
        );
        
        // 🔥 CRITICAL: Wenn beförderter User der aktuell eingeloggte ist, Admin-State aktualisieren!
        if (user.username == admin.username) {
          if (kDebugMode) {
            debugPrint('🔄 Aktualisiere Admin-State für beförderten User: ${user.username}');
          }
          
          // Trigger Admin-State Reload
          await ref.read(adminStateProvider(widget.world).notifier).refreshAdminStatus();
        }
        
        await _loadUsers(); // Refresh User-Liste
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Beförderung fehlgeschlagen'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Demote Admin to User
  Future<void> _demoteUser(WorldUser user) async {
    // 🔥 RIVERPOD: Admin-Status prüfen
    final admin = ref.read(adminStateProvider(widget.world));
    
    if (!admin.isRootAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Nur Root-Admins können Admins degradieren.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (user.isRootAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Root-Admins können nicht degradiert werden.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Verhindere Selbst-Degradierung
    if (user.username == admin.username) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Du kannst dich nicht selbst degradieren.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Bestätigung
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin-Rechte entfernen?'),
        content: Text('Möchtest du ${user.username} zum normalen User machen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Degradieren'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    // Demote
    if (kDebugMode) {
      debugPrint('🔥 DEMOTE DEBUG:');
      debugPrint('   World: ${widget.world}');
      debugPrint('   UserId: ${user.userId}');
      debugPrint('   Admin Role: ${admin.role}');
      debugPrint('   Admin Username: ${admin.username}');
      debugPrint('   Admin isRootAdmin: ${admin.isRootAdmin}');
    }
    
    // 🔥 FIX: Fallback auf "root_admin" wenn role NULL
    final effectiveRole = admin.role ?? (admin.isRootAdmin ? 'root_admin' : 'admin');
    
    final success = await WorldAdminService.demoteUser(widget.world, user.userId, role: effectiveRole);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${user.username} wurde zu User degradiert'),
            backgroundColor: Colors.green,
          ),
        );
        
        // 🔥 CRITICAL: Wenn degradierter User der aktuell eingeloggte ist, Admin-State aktualisieren!
        if (user.username == admin.username) {
          if (kDebugMode) {
            debugPrint('🔄 Aktualisiere Admin-State für degradierten User: ${user.username}');
          }
          
          // Trigger Admin-State Reload
          await ref.read(adminStateProvider(widget.world).notifier).refreshAdminStatus();
        }
        
        await _loadUsers(); // Refresh User-Liste
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Degradierung fehlgeschlagen'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Delete User
  Future<void> _deleteUser(WorldUser user) async {
    // 🔥 RIVERPOD: Admin-Status prüfen
    final admin = ref.read(adminStateProvider(widget.world));
    
    if (!admin.isRootAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Nur Root-Admins können User löschen.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Verhindere Selbst-Löschung
    if (user.username == admin.username) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Du kannst dich nicht selbst löschen.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Bestätigung (kritische Aktion!)
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ User löschen?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Möchtest du ${user.username} wirklich löschen?'),
            const SizedBox(height: 8),
            const Text(
              '⚠️ Diese Aktion kann nicht rückgängig gemacht werden!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    // Delete
    if (kDebugMode) {
      debugPrint('🔥 DELETE DEBUG:');
      debugPrint('   World: ${widget.world}');
      debugPrint('   UserId: ${user.userId}');
      debugPrint('   Admin Role: ${admin.role}');
      debugPrint('   Admin Username: ${admin.username}');
      debugPrint('   Admin isRootAdmin: ${admin.isRootAdmin}');
    }
    
    // 🔥 FIX: Fallback auf "root_admin" wenn role NULL
    final effectiveRole = admin.role ?? (admin.isRootAdmin ? 'root_admin' : 'admin');
    
    final success = await WorldAdminService.deleteUser(widget.world, user.userId, role: effectiveRole);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${user.username} wurde gelöscht'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadUsers(); // Refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Löschung fehlgeschlagen'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // 🔥 RIVERPOD: Admin-Status aus State lesen
    final admin = ref.watch(adminStateProvider(widget.world));
    
    // Admin-Check: Wenn nicht Admin, zeige Fehlermeldung
    if (!admin.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.world.toUpperCase()}-Admin'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Kein Admin-Zugriff',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Diese Seite ist nur für Admins zugänglich.'),
            ],
          ),
        ),
      );
    }
    
    // Dashboard UI
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings, color: Colors.amber),
            const SizedBox(width: 8),
            Text('${widget.world.toUpperCase()}-Admin Dashboard'),
          ],
        ),
        actions: [
          // Root-Admin Badge
          if (admin.isRootAdmin)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                avatar: const Icon(Icons.shield, size: 16, color: Colors.amber),
                label: const Text('ROOT', style: TextStyle(fontSize: 12)),
                backgroundColor: Colors.amber.withValues(alpha: 0.2),
              ),
            ),
          
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // 🔥 RIVERPOD: Admin-Status refresh triggern
              ref.read(adminStateProvider(widget.world).notifier).refresh();
              _loadDashboardData();
            },
            tooltip: 'Aktualisieren',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.manage_accounts), text: 'User Mgmt'), // ✅ PHASE 2: User Management (Detail View)
            Tab(icon: Icon(Icons.people), text: 'Users'), // ✅ PHASE 1: Quick Actions (Promote/Demote/Delete)
            Tab(icon: Icon(Icons.article), text: 'Content'), // ✅ PHASE 3: Content Management
            Tab(icon: Icon(Icons.history), text: 'Audit-Log'),
            Tab(icon: Icon(Icons.shield), text: 'Moderation'),
            Tab(icon: Icon(Icons.health_and_safety), text: 'Health'), // 🏥 NEW: Health Dashboard
            Tab(icon: Icon(Icons.gavel), text: 'V16.2 Mod'), // 🔧 NEW: V16.2 Professional Admin APIs
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUserManagementTab(admin), // ✅ PHASE 2: Detail View
                _buildUsersTab(admin), // ✅ PHASE 1: Quick Actions
                _buildContentManagementTab(admin), // ✅ PHASE 3: Content Management
                _buildAuditLogTab(),
                _buildModerationTab(admin),
                const HealthDashboardScreen(), // 🏥 NEW: Health Dashboard
                UserModerationScreenV16List(world: widget.world), // 🔧 NEW: V16.2 Professional Admin APIs (MIT USER-LISTE!)
              ],
            ),
    );
  }
  
  /// Users Tab
  Widget _buildUsersTab(AdminState admin) {
    if (_users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Keine User gefunden'),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final isCurrentUser = user.username == admin.username;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            // Icon basierend auf Role
            leading: user.role != 'user'
                ? const Icon(Icons.shield, color: Colors.amber)
                : const Icon(Icons.person),
            
            // Username + Badge für aktuellen User
            title: Row(
              children: [
                Text(user.username),
                if (isCurrentUser) ...[
                  const SizedBox(width: 8),
                  const Chip(
                    label: Text('DU', style: TextStyle(fontSize: 10)),
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
            
            // Role
            subtitle: Text(user.role),
            
            // 🎯 QUICK-ACTION BUTTONS (NUR Root-Admin, nicht bei sich selbst!)
            trailing: admin.isRootAdmin && !isCurrentUser
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ⬆️ PROMOTE Button (nur für normale User)
                      if (user.role == 'user')
                        IconButton(
                          icon: const Icon(Icons.arrow_upward, color: Colors.green),
                          tooltip: 'Zum Admin machen',
                          onPressed: () => _promoteUser(user),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.green.withValues(alpha: 0.1),
                          ),
                        ),
                      
                      // ⬇️ DEMOTE Button (nur für Admins, nicht Root-Admins)
                      if (user.role == 'admin' && !user.isRootAdmin)
                        IconButton(
                          icon: const Icon(Icons.arrow_downward, color: Colors.orange),
                          tooltip: 'Admin entfernen',
                          onPressed: () => _demoteUser(user),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.orange.withValues(alpha: 0.1),
                          ),
                        ),
                      
                      // 🗑️ DELETE Button (für alle außer Root-Admins)
                      if (!user.isRootAdmin)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'User löschen',
                          onPressed: () => _deleteUser(user),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red.withValues(alpha: 0.1),
                          ),
                        ),
                    ],
                  )
                : null,
          ),
        );
      },
    );
  }
  
  /// Audit Log Tab
  Widget _buildAuditLogTab() {
    if (_auditLog.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Keine Audit-Log-Einträge'),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _auditLog.length,
      itemBuilder: (context, index) {
        final log = _auditLog[index];
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: _getAuditIcon(log.action),
            title: Text(log.action),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin: ${log.adminUsername}'),
                Text('Target: ${log.targetUsername}'),
                Text(_formatTimestamp(log.timestamp)),
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// Get Icon for Audit Action
  Icon _getAuditIcon(String action) {
    switch (action.toLowerCase()) {
      case 'promote':
        return const Icon(Icons.arrow_upward, color: Colors.green);
      case 'demote':
        return const Icon(Icons.arrow_downward, color: Colors.orange);
      case 'delete':
        return const Icon(Icons.delete, color: Colors.red);
      case 'login':
        return const Icon(Icons.login, color: Colors.blue);
      case 'logout':
        return const Icon(Icons.logout, color: Colors.grey);
      default:
        return const Icon(Icons.info, color: Colors.blue);
    }
  }
  
  /// Format Timestamp
  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      return '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute}';
    } catch (e) {
      return timestamp;
    }
  }
  
  /// ✅ PHASE 2: User Management Tab
  Widget _buildUserManagementTab(AdminState admin) {
    // ⚠️ CRITICAL FIX: IMMER aus Storage laden!
    // admin.username kann null oder empty sein, auch wenn isAdmin true ist
    final storage = UnifiedStorageService();
    final username = storage.getUsername(widget.world);
    final finalToken = username ?? '';
    
    // 🔍 DEBUG: Token-Check
    if (kDebugMode) {
      debugPrint('🔐 USER MANAGEMENT TAB:');
      debugPrint('   admin.username: ${admin.username}');
      debugPrint('   storage.username: $username');
      debugPrint('   finalToken: $finalToken');
      debugPrint('   isAdmin: ${admin.isAdmin}');
      debugPrint('   isRootAdmin: ${admin.isRootAdmin}');
    }
    
    return UserManagementScreen(
      world: widget.world,
      adminToken: finalToken,
      isRootAdmin: admin.isRootAdmin,
    );
  }
  
  /// 🛡️ Moderation Tab
  Widget _buildContentManagementTab(AdminState admin) {
    if (kDebugMode) {
      debugPrint('🛡️ Content Management Tab');
      debugPrint('   admin.username: ${admin.username}');
      debugPrint('   admin.isAdmin: ${admin.isAdmin}');
      debugPrint('   admin.isRootAdmin: ${admin.isRootAdmin}');
    }
    
    // ⚠️ CRITICAL FIX: IMMER aus Storage laden!
    final storage = UnifiedStorageService();
    final username = storage.getUsername(widget.world);
    final finalToken = username ?? '';
    
    if (kDebugMode) {
      debugPrint('   storage.username: $username');
      debugPrint('   finalToken: $finalToken');
    }
    
    return _ContentManagementTabContent(
      world: widget.world,
      adminToken: finalToken,
      isRootAdmin: admin.isRootAdmin,
    );
  }

  Widget _buildModerationTab(AdminState admin) {
    // ⚠️ CRITICAL FIX: IMMER aus Storage laden!
    final storage = UnifiedStorageService();
    final username = storage.getUsername(widget.world);
    final adminToken = username ?? '';
    
    return ModerationDashboardScreen(
      world: widget.world,
      adminToken: adminToken,
      isRootAdmin: admin.isRootAdmin,
    );
  }
}

// ========================================
// CONTENT MANAGEMENT TAB CONTENT
// ========================================
class _ContentManagementTabContent extends StatefulWidget {
  final String world;
  final String adminToken;
  final bool isRootAdmin;

  const _ContentManagementTabContent({
    required this.world,
    required this.adminToken,
    required this.isRootAdmin,
  });

  @override
  State<_ContentManagementTabContent> createState() => _ContentManagementTabContentState();
}

class _ContentManagementTabContentState extends State<_ContentManagementTabContent> {
  List<Map<String, dynamic>> _content = [];
  bool _isLoading = true;
  String _filterStatus = 'all';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final content = await ContentManagementService.getContent(
        widget.world,
        status: _filterStatus == 'all' ? null : _filterStatus,
      );

      if (mounted) {
        setState(() {
          _content = content;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Fehler beim Laden: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFeature(Map<String, dynamic> item) async {
    final success = await ContentManagementService.toggleFeature(
      widget.world,
      item['content_id'],
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item['is_featured'] == 1
                ? '✅ Nicht mehr hervorgehoben'
                : '✅ Hervorgehoben',
          ),
          backgroundColor: Colors.green,
        ),
      );
      await _loadContent();
    }
  }

  Future<void> _toggleVerify(Map<String, dynamic> item) async {
    final success = await ContentManagementService.toggleVerify(
      widget.world,
      item['content_id'],
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item['is_verified'] == 1
                ? '✅ Verifizierung entfernt'
                : '✅ Verifiziert',
          ),
          backgroundColor: Colors.green,
        ),
      );
      await _loadContent();
    }
  }

  Future<void> _deleteContent(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Content löschen?'),
        content: Text(
          'Möchtest du "${item['title']}" wirklich löschen?\n\n'
          '⚠️ Diese Aktion kann nicht rückgängig gemacht werden!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ContentManagementService.deleteContent(
      widget.world,
      item['content_id'],
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Content gelöscht'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter Chips
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Alle'),
                selected: _filterStatus == 'all',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _filterStatus = 'all');
                    _loadContent();
                  }
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('⭐ Featured'),
                selected: _filterStatus == 'featured',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _filterStatus = 'featured');
                    _loadContent();
                  }
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('✅ Verifiziert'),
                selected: _filterStatus == 'verified',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _filterStatus = 'verified');
                    _loadContent();
                  }
                },
              ),
            ],
          ),
        ),

        // Content List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(_error!),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadContent,
                            child: const Text('Erneut versuchen'),
                          ),
                        ],
                      ),
                    )
                  : _content.isEmpty
                      ? const Center(child: Text('Noch kein Content vorhanden'))
                      : RefreshIndicator(
                          onRefresh: _loadContent,
                          child: ListView.builder(
                            itemCount: _content.length,
                            itemBuilder: (context, index) {
                              final item = _content[index];
                              final isFeatured = item['is_featured'] == 1;
                              final isVerified = item['is_verified'] == 1;

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.article,
                                    color: isFeatured ? Colors.amber : Colors.grey,
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(child: Text(item['title'] ?? '')),
                                      if (isFeatured)
                                        const Icon(Icons.star, size: 16, color: Colors.amber),
                                      if (isVerified)
                                        const Icon(Icons.verified, size: 16, color: Colors.blue),
                                    ],
                                  ),
                                  subtitle: Text(
                                    'Von ${item['author_username']} • ${item['view_count']} Views',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          isFeatured ? Icons.star : Icons.star_border,
                                          color: Colors.amber,
                                        ),
                                        tooltip: isFeatured ? 'Nicht mehr hervorheben' : 'Hervorheben',
                                        onPressed: () => _toggleFeature(item),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          isVerified ? Icons.verified : Icons.verified_outlined,
                                          color: Colors.blue,
                                        ),
                                        tooltip: isVerified ? 'Verifizierung entfernen' : 'Verifizieren',
                                        onPressed: () => _toggleVerify(item),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        tooltip: 'Löschen',
                                        onPressed: () => _deleteContent(item),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}
