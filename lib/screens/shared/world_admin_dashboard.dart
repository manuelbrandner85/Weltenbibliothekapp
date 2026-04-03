import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/world_admin_service.dart';
import '../../services/cloudflare_api_service.dart';
import '../../services/health_check_service.dart';
import '../../features/admin/state/admin_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EINSTIEGSPUNKT – API unverändert, alle bestehenden Aufrufe bleiben gültig
// ─────────────────────────────────────────────────────────────────────────────
class WorldAdminDashboard extends ConsumerStatefulWidget {
  final String world;
  const WorldAdminDashboard({super.key, required this.world});

  @override
  ConsumerState<WorldAdminDashboard> createState() =>
      _WorldAdminDashboardState();
}

class _WorldAdminDashboardState extends ConsumerState<WorldAdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Color get _primary =>
      widget.world == 'materie' ? const Color(0xFF1565C0) : const Color(0xFF6A1B9A);
  Color get _accent =>
      widget.world == 'materie' ? const Color(0xFF42A5F5) : const Color(0xFFCE93D8);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _waitForState();
    });
  }

  Future<void> _waitForState() async {
    for (int i = 0; i < 6; i++) {
      final a = ref.read(adminStateProvider(widget.world));
      if (a.username != null && a.username!.isNotEmpty) return;
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(adminStateProvider(widget.world));

    if (admin.username == null) return _loadingScaffold();
    if (!admin.isAdmin) return _accessDeniedScaffold();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.admin_panel_settings, color: _accent, size: 22),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${widget.world.toUpperCase()} Admin',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Text(admin.username ?? '',
                style: TextStyle(fontSize: 11, color: _accent)),
          ]),
        ]),
        actions: [
          if (admin.isRootAdmin)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Colors.amber.shade700, Colors.orange.shade600]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(children: [
                Icon(Icons.shield, size: 12, color: Colors.white),
                SizedBox(width: 4),
                Text('ROOT',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ]),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () {
              ref.read(adminStateProvider(widget.world).notifier).refresh();
              setState(() {});
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _accent,
          indicatorWeight: 3,
          labelColor: _accent,
          unselectedLabelColor: Colors.white38,
          labelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard, size: 20), text: 'Übersicht'),
            Tab(icon: Icon(Icons.people, size: 20), text: 'Nutzer'),
            Tab(icon: Icon(Icons.chat_bubble, size: 20), text: 'Chat'),
            Tab(icon: Icon(Icons.monitor_heart, size: 20), text: 'System'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(world: widget.world, admin: admin, accent: _accent),
          _UsersTab(world: widget.world, admin: admin, accent: _accent),
          _ChatModerationTab(world: widget.world, admin: admin, accent: _accent),
          _SystemTab(accent: _accent),
        ],
      ),
    );
  }

  Widget _loadingScaffold() => Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            CircularProgressIndicator(color: _accent),
            const SizedBox(height: 16),
            const Text('Lade Admin-Dashboard…',
                style: TextStyle(color: Colors.white70)),
          ]),
        ),
      );

  Widget _accessDeniedScaffold() => Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        appBar: AppBar(
            backgroundColor: const Color(0xFF0D0D1A),
            title: const Text('Admin-Dashboard')),
        body: const Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.lock, size: 72, color: Colors.red),
            SizedBox(height: 16),
            Text('Kein Zugriff',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            SizedBox(height: 8),
            Text('Nur für Admins zugänglich.',
                style: TextStyle(color: Colors.white54)),
          ]),
        ),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 1 – ÜBERSICHT  (Live-Statistiken + letzte Aktivitäten)
// ═════════════════════════════════════════════════════════════════════════════
class _OverviewTab extends StatefulWidget {
  final String world;
  final AdminState admin;
  final Color accent;
  const _OverviewTab(
      {required this.world, required this.admin, required this.accent});
  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  Map<String, dynamic> _stats = {};
  List<AuditLogEntry> _activity = [];
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    try {
      // Analytics über Extension-Methode
      final stats = await WorldAdminServiceV162.getAnalytics(
        realm: widget.world,
        days: 7,
        adminUserId: widget.admin.username,
      );
      final logs = await WorldAdminService.getAuditLog(
        widget.world,
        limit: 10,
        role: widget.admin.isRootAdmin ? 'root_admin' : 'admin',
      );
      if (mounted) {
        setState(() {
          _stats = stats;
          _activity = logs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      if (kDebugMode) debugPrint('❌ Overview load: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: widget.accent));
    }

    final totalUsers   = _stats['totalUsers']   ?? _stats['total_users']   ?? 0;
    final totalMsgs    = _stats['totalMessages'] ?? _stats['total_messages'] ?? 0;
    final newUsers     = _stats['newUsers']      ?? _stats['new_users']      ?? 0;
    final interactions = _stats['interactions']  ?? 0;

    return RefreshIndicator(
      onRefresh: _load,
      color: widget.accent,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionLabel('Live-Übersicht · ${widget.world.toUpperCase()}',
              Icons.bar_chart, widget.accent),
          const SizedBox(height: 12),

          // ── 2×2 Statistik-Karten ────────────────────────────────────
          Row(children: [
            Expanded(
                child: _StatCard(
                    icon: Icons.people,
                    label: 'Nutzer gesamt',
                    value: '$totalUsers',
                    color: const Color(0xFF1E88E5))),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
                    icon: Icons.person_add,
                    label: 'Neu (7 Tage)',
                    value: '$newUsers',
                    color: const Color(0xFF43A047))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _StatCard(
                    icon: Icons.chat,
                    label: 'Nachrichten',
                    value: '$totalMsgs',
                    color: const Color(0xFF8E24AA))),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
                    icon: Icons.touch_app,
                    label: 'Interaktionen',
                    value: '$interactions',
                    color: const Color(0xFFE53935))),
          ]),

          const SizedBox(height: 24),
          _SectionLabel('Letzte Aktionen', Icons.history, widget.accent),
          const SizedBox(height: 8),

          if (_activity.isEmpty)
            const _EmptyHint('Noch keine Aktivitäten aufgezeichnet.')
          else
            ..._activity.map((e) => _ActivityTile(entry: e)),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 2 – NUTZER  (Suche · Filter · Ban/Unban · Rolle)
// ═════════════════════════════════════════════════════════════════════════════
class _UsersTab extends StatefulWidget {
  final String world;
  final AdminState admin;
  final Color accent;
  const _UsersTab(
      {required this.world, required this.admin, required this.accent});
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  List<WorldUser> _all = [];
  List<WorldUser> _filtered = [];
  bool _loading = true;
  String _search = '';
  String _roleFilter = 'all';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final users = await WorldAdminService.getUsersByWorld(
        widget.world,
        role: widget.admin.isRootAdmin ? 'root_admin' : 'admin',
      );
      if (mounted) {
        setState(() {
          _all = users;
          _applyFilter();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    var list = _all;
    if (_roleFilter != 'all') {
      list = list.where((u) => u.role == _roleFilter).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where((u) =>
              u.username.toLowerCase().contains(q) ||
              (u.displayName ?? '').toLowerCase().contains(q))
          .toList();
    }
    _filtered = list;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  Future<void> _ban(WorldUser u) async {
    final ok = await WorldAdminServiceV162.banUser(
        userId: u.userId,
        reason: 'Admin-Aktion',
        adminUserId: widget.admin.username);
    _snack(ok ? '🚫 ${u.username} gesperrt' : '❌ Fehler beim Sperren');
    if (ok) _load();
  }

  Future<void> _unban(WorldUser u) async {
    final ok = await WorldAdminServiceV162.unbanUser(
        userId: u.userId, adminUserId: widget.admin.username ?? 'admin');
    _snack(ok ? '✅ ${u.username} entsperrt' : '❌ Fehler');
    if (ok) _load();
  }

  Future<void> _promote(WorldUser u) async {
    final ok = await WorldAdminService.promoteUser(
        widget.world, u.userId,
        role: widget.admin.isRootAdmin ? 'root_admin' : 'admin');
    _snack(ok ? '⬆️ ${u.username} zum Admin befördert' : '❌ Fehler');
    if (ok) _load();
  }

  Future<void> _demote(WorldUser u) async {
    final ok = await WorldAdminService.demoteUser(
        widget.world, u.userId,
        role: widget.admin.isRootAdmin ? 'root_admin' : 'admin');
    _snack(ok ? '⬇️ ${u.username} degradiert' : '❌ Fehler');
    if (ok) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Suchleiste + Rolle-Filter ─────────────────────────────────
      Container(
        color: const Color(0xFF0D0D1A),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(children: [
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Nutzer suchen…',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white38),
                      onPressed: () => setState(() {
                            _search = '';
                            _searchCtrl.clear();
                            _applyFilter();
                          }))
                  : null,
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (v) => setState(() {
              _search = v;
              _applyFilter();
            }),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['all', 'user', 'admin', 'root_admin'].map((r) {
                final labels = {
                  'all': 'Alle',
                  'user': 'User',
                  'admin': 'Admin',
                  'root_admin': 'Root'
                };
                final sel = _roleFilter == r;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(labels[r]!,
                        style: TextStyle(
                            color: sel ? Colors.black : Colors.white70,
                            fontSize: 12)),
                    selected: sel,
                    selectedColor: widget.accent,
                    backgroundColor: Colors.white10,
                    onSelected: (_) => setState(() {
                      _roleFilter = r;
                      _applyFilter();
                    }),
                    checkmarkColor: Colors.black,
                    side: BorderSide.none,
                  ),
                );
              }).toList(),
            ),
          ),
        ]),
      ),

      // ── Nutzerliste ───────────────────────────────────────────────
      Expanded(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: widget.accent))
            : RefreshIndicator(
                onRefresh: _load,
                color: widget.accent,
                child: _filtered.isEmpty
                    ? const _EmptyHint('Keine Nutzer gefunden.')
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) {
                          final u = _filtered[i];
                          return _UserTile(
                            user: u,
                            isRootAdmin: widget.admin.isRootAdmin,
                            accent: widget.accent,
                            onBan: () => _ban(u),
                            onUnban: () => _unban(u),
                            onPromote: () => _promote(u),
                            onDemote: () => _demote(u),
                          );
                        },
                      ),
              ),
      ),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 3 – CHAT-MODERATION  (Live-Nachrichten · Löschen · Sender sperren)
// ═════════════════════════════════════════════════════════════════════════════
class _ChatModerationTab extends StatefulWidget {
  final String world;
  final AdminState admin;
  final Color accent;
  const _ChatModerationTab(
      {required this.world, required this.admin, required this.accent});
  @override
  State<_ChatModerationTab> createState() => _ChatModerationTabState();
}

class _ChatModerationTabState extends State<_ChatModerationTab> {
  late List<String> _rooms;
  late String _selectedRoom;
  List<Map<String, dynamic>> _messages = [];
  bool _loadingMsgs = false;
  final _api = CloudflareApiService();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _rooms = widget.world == 'materie'
        ? [
            'materie-politik',
            'materie-geschichte',
            'materie-ufo',
            'materie-verschwoerung',
            'materie-wissenschaft',
            'materie-tech',
            'materie-gesundheit',
            'materie-medien',
            'materie-finanzen',
          ]
        : [
            'energie-meditation',
            'energie-chakra',
            'energie-bewusstsein',
            'energie-heilung',
            'energie-kristalle',
            'energie-astrologie',
            'energie-traumdeutung',
          ];
    _selectedRoom = _rooms.first;
    _loadMessages();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 20), (_) => _loadMessages());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    setState(() => _loadingMsgs = true);
    try {
      final msgs = await _api.getChatMessages(_selectedRoom, limit: 50);
      if (mounted) setState(() => _messages = msgs);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Chat laden: $e');
    } finally {
      if (mounted) setState(() => _loadingMsgs = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  Future<void> _deleteMsg(Map<String, dynamic> msg) async {
    final id = (msg['id'] ?? msg['message_id'] ?? '').toString();
    final username = (msg['username'] ?? '').toString();
    if (id.isEmpty) { _snack('❌ Keine Nachrichten-ID'); return; }
    try {
      await _api.deleteChatMessage(
        messageId: id,
        roomId: _selectedRoom,
        userId: (msg['user_id'] ?? msg['userId'] ?? '').toString(),
        username: widget.admin.username ?? 'Weltenbibliothek',
        isAdmin: true,
      );
      _snack('🗑️ Nachricht von $username gelöscht');
      _loadMessages();
    } catch (e) {
      _snack('❌ Löschen fehlgeschlagen');
    }
  }

  Future<void> _banSender(Map<String, dynamic> msg) async {
    final userId = (msg['user_id'] ?? msg['userId'] ?? '').toString();
    final username = (msg['username'] ?? '').toString();
    if (userId.isEmpty || userId.startsWith('user_')) {
      _snack('⚠️ Kein gültiger Account – Ban nicht möglich');
      return;
    }
    final ok = await WorldAdminServiceV162.banUser(
        userId: userId,
        reason: 'Chat-Moderation',
        adminUserId: widget.admin.username);
    _snack(ok ? '🚫 $username gesperrt' : '❌ Fehler beim Sperren');
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Raum-Auswahl ─────────────────────────────────────────────
      Container(
        color: const Color(0xFF0D0D1A),
        height: 48,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          itemCount: _rooms.length,
          itemBuilder: (ctx, i) {
            final r = _rooms[i];
            final label = r.split('-').last;
            final cap = label[0].toUpperCase() + label.substring(1);
            final sel = r == _selectedRoom;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedRoom = r);
                _loadMessages();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: sel
                      ? widget.accent.withValues(alpha: 0.2)
                      : Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: sel ? widget.accent : Colors.transparent,
                      width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(cap,
                    style: TextStyle(
                        color: sel ? widget.accent : Colors.white54,
                        fontSize: 12,
                        fontWeight:
                            sel ? FontWeight.bold : FontWeight.normal)),
              ),
            );
          },
        ),
      ),

      // ── Nachrichten ───────────────────────────────────────────────
      Expanded(
        child: _loadingMsgs && _messages.isEmpty
            ? Center(child: CircularProgressIndicator(color: widget.accent))
            : RefreshIndicator(
                onRefresh: _loadMessages,
                color: widget.accent,
                child: _messages.isEmpty
                    ? const _EmptyHint('Keine Nachrichten in diesem Raum.')
                    : ListView.builder(
                        reverse: true,
                        itemCount: _messages.length,
                        itemBuilder: (ctx, i) {
                          final msg =
                              _messages[_messages.length - 1 - i];
                          return _ChatMsgTile(
                            msg: msg,
                            accent: widget.accent,
                            onDelete: () => _deleteMsg(msg),
                            onBan: () => _banSender(msg),
                          );
                        },
                      ),
              ),
      ),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 4 – SYSTEM / HEALTH
// ═════════════════════════════════════════════════════════════════════════════
class _SystemTab extends StatefulWidget {
  final Color accent;
  const _SystemTab({required this.accent});
  @override
  State<_SystemTab> createState() => _SystemTabState();
}

class _SystemTabState extends State<_SystemTab> {
  final _health = HealthCheckService();
  Timer? _uiTimer;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
    _uiTimer = Timer.periodic(
        const Duration(seconds: 2), (_) { if (mounted) setState(() {}); });
  }

  Future<void> _init() async {
    await _health.initialize();
    _health.startMonitoring(interval: const Duration(seconds: 30));
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _health.stopMonitoring();
    _uiTimer?.cancel();
    super.dispose();
  }

  Color _latencyColor(double ms) {
    if (ms < 300) return Colors.green;
    if (ms < 800) return Colors.orange;
    return Colors.red;
  }

  Color _statusColor(HealthStatus s) {
    switch (s) {
      case HealthStatus.healthy:   return Colors.green;
      case HealthStatus.degraded:  return Colors.orange;
      case HealthStatus.unhealthy: return Colors.red;
      case HealthStatus.unknown:   return Colors.grey;
    }
  }

  double _calcUptime() {
    final svcs = _health.serviceHealth;
    if (svcs.isEmpty) return 100;
    final healthy =
        svcs.values.where((s) => s.status == HealthStatus.healthy).length;
    return (healthy / svcs.length) * 100;
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Center(child: CircularProgressIndicator(color: widget.accent));
    }

    final svcs = _health.serviceHealth;
    final anyUnhealthy =
        svcs.values.any((s) => s.status == HealthStatus.unhealthy);
    final allOk = svcs.values.every((s) => s.status == HealthStatus.healthy);

    final overallColor =
        anyUnhealthy ? Colors.red : allOk ? Colors.green : Colors.orange;
    final overallLabel = anyUnhealthy
        ? 'Probleme erkannt'
        : allOk
            ? 'Alle Systeme OK'
            : 'Eingeschränkt';
    final overallIcon = anyUnhealthy
        ? Icons.error_outline
        : allOk
            ? Icons.check_circle_outline
            : Icons.warning_amber_outlined;

    final uptime = _calcUptime();
    final errRate = _health.errorRate;
    final avgLatency = _health.averageLatency;

    return RefreshIndicator(
      onRefresh: () => _health.checkAllServices(),
      color: widget.accent,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionLabel('System-Status', Icons.monitor_heart, widget.accent),
          const SizedBox(height: 12),

          // ── Gesamt-Status ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: overallColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: overallColor.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              Icon(overallIcon, color: overallColor, size: 36),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(overallLabel,
                    style: TextStyle(
                        color: overallColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text('${svcs.length} Dienste überwacht',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12)),
              ]),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Metriken ──────────────────────────────────────────────
          _SectionLabel('Metriken', Icons.speed, widget.accent),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: _MetricCard(
                    label: 'Ø Latenz',
                    value: '${avgLatency.round()} ms',
                    color: _latencyColor(avgLatency))),
            const SizedBox(width: 12),
            Expanded(
                child: _MetricCard(
                    label: 'Fehlerrate',
                    value: '${(errRate).toStringAsFixed(1)} %',
                    color: errRate > 10 ? Colors.red : Colors.green)),
            const SizedBox(width: 12),
            Expanded(
                child: _MetricCard(
                    label: 'Uptime',
                    value: '${uptime.toStringAsFixed(0)} %',
                    color: uptime > 95 ? Colors.green : Colors.orange)),
          ]),

          const SizedBox(height: 20),

          // ── Einzelne Dienste ──────────────────────────────────────
          _SectionLabel('Dienste', Icons.dns, widget.accent),
          const SizedBox(height: 8),
          ...svcs.entries.map((e) => _ServiceRow(
                name: e.key,
                health: e.value,
                statusColor: _statusColor(e.value.status),
              )),

          const SizedBox(height: 20),

          // ── Refresh-Button ────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _health.checkAllServices(),
              icon: Icon(Icons.refresh, color: widget.accent),
              label: Text('Jetzt prüfen',
                  style: TextStyle(color: widget.accent)),
              style: OutlinedButton.styleFrom(
                  side: BorderSide(color: widget.accent),
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// GEMEINSAME WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color accent;
  const _SectionLabel(this.text, this.icon, this.accent);

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: accent, size: 16),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(
                color: accent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.5)),
      ]);
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(text,
              style: const TextStyle(color: Colors.white38, fontSize: 14),
              textAlign: TextAlign.center),
        ),
      );
}

// ── Statistik-Karte ───────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ]),
      );
}

// ── Aktivitäts-Eintrag ────────────────────────────────────────────────────
class _ActivityTile extends StatelessWidget {
  final AuditLogEntry entry;
  const _ActivityTile({required this.entry});

  static const _icons = {
    'edit_message':   (Icons.edit,           Color(0xFF1E88E5)),
    'delete_message': (Icons.delete,          Color(0xFFE53935)),
    'promote':        (Icons.arrow_upward,    Color(0xFF43A047)),
    'demote':         (Icons.arrow_downward,  Color(0xFFFB8C00)),
    'ban':            (Icons.block,           Color(0xFFE53935)),
    'unban':          (Icons.check_circle,    Color(0xFF00ACC1)),
  };

  static const _labels = {
    'edit_message':   'Nachricht bearbeitet',
    'delete_message': 'Nachricht gelöscht',
    'promote':        'Zum Admin befördert',
    'demote':         'Degradiert',
    'ban':            'Nutzer gesperrt',
    'unban':          'Sperre aufgehoben',
  };

  @override
  Widget build(BuildContext context) {
    final key = entry.action.toLowerCase();
    final iconData = _icons[key]?.$1 ?? Icons.info_outline;
    final color    = _icons[key]?.$2 ?? Colors.grey;
    final label    = _labels[key] ?? entry.action;
    final ts       = _fmt(entry.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: Icon(iconData, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            Text('${entry.adminUsername} → ${entry.targetUsername}',
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ]),
        ),
        Text(ts, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ]),
    );
  }

  String _fmt(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return ts;
    }
  }
}

// ── Nutzer-Kachel ─────────────────────────────────────────────────────────
class _UserTile extends StatelessWidget {
  final WorldUser user;
  final bool isRootAdmin;
  final Color accent;
  final VoidCallback onBan, onUnban, onPromote, onDemote;
  const _UserTile({
    required this.user,
    required this.isRootAdmin,
    required this.accent,
    required this.onBan,
    required this.onUnban,
    required this.onPromote,
    required this.onDemote,
  });

  Color get _roleColor => switch (user.role) {
        'root_admin' => Colors.amber,
        'admin'      => Colors.blue,
        _            => Colors.white38,
      };

  String get _roleLabel => switch (user.role) {
        'root_admin' => 'ROOT',
        'admin'      => 'Admin',
        _            => 'User',
      };

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF12121E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: _roleColor.withValues(alpha: 0.15),
            child: Text(
              user.avatarEmoji?.isNotEmpty == true
                  ? user.avatarEmoji!
                  : user.username[0].toUpperCase(),
              style: const TextStyle(fontSize: 18),
            ),
          ),
          title: Text(user.displayName ?? user.username,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text('@${user.username}',
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _roleColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_roleLabel,
                  style: TextStyle(
                      color: _roleColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more, color: Colors.white38, size: 18),
          ]),
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(children: [
                _InfoRow(Icons.access_time, 'Erstellt: ${_fmtDate(user.createdAt)}'),
                const SizedBox(height: 4),
                _InfoRow(Icons.fingerprint,
                    'ID: ${user.userId.isEmpty ? "–" : user.userId}'),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  if (isRootAdmin && !user.isAdmin)
                    _ActionBtn(
                        Icons.arrow_upward, 'Zum Admin', Colors.green, onPromote),
                  if (isRootAdmin && user.isAdmin && !user.isRootAdmin)
                    _ActionBtn(
                        Icons.arrow_downward, 'Degradieren', Colors.orange, onDemote),
                  _ActionBtn(Icons.block, 'Sperren', Colors.red, onBan),
                  _ActionBtn(Icons.check_circle_outline, 'Entsperren',
                      Colors.teal, onUnban),
                ]),
              ]),
            ),
          ],
        ),
      );

  String _fmtDate(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return '–';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 12, color: Colors.white38),
        const SizedBox(width: 6),
        Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
                overflow: TextOverflow.ellipsis)),
      ]);
}

// ── Aktions-Button ────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

// ── Chat-Nachrichten-Kachel ───────────────────────────────────────────────
class _ChatMsgTile extends StatelessWidget {
  final Map<String, dynamic> msg;
  final Color accent;
  final VoidCallback onDelete, onBan;
  const _ChatMsgTile(
      {required this.msg,
      required this.accent,
      required this.onDelete,
      required this.onBan});

  @override
  Widget build(BuildContext context) {
    final username = (msg['username'] ?? 'Anonym').toString();
    final content  = (msg['content'] ?? msg['message'] ?? '').toString();
    final ts       = _fmt(msg['created_at'] ?? msg['timestamp'] ?? '');
    final emoji    = (msg['avatarEmoji'] ?? msg['avatar_emoji'] ?? '👤').toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF12121E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(username,
                  style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              const Spacer(),
              Text(ts,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 10)),
            ]),
            const SizedBox(height: 4),
            Text(content,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                maxLines: 5,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
        Column(children: [
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.redAccent, size: 20),
            tooltip: 'Löschen',
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(height: 4),
          IconButton(
            icon: const Icon(Icons.block, color: Colors.orange, size: 20),
            tooltip: 'Sender sperren',
            onPressed: onBan,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ]),
      ]),
    );
  }

  String _fmt(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

// ── System: Dienst-Zeile ──────────────────────────────────────────────────
class _ServiceRow extends StatelessWidget {
  final String name;
  final ServiceHealth health;
  final Color statusColor;
  const _ServiceRow(
      {required this.name,
      required this.health,
      required this.statusColor});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF12121E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(name,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13))),
          Text('${health.latencyMs} ms',
              style: const TextStyle(
                  color: Colors.white38, fontSize: 11)),
          const SizedBox(width: 8),
          Text(health.statusText,
              style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ]),
      );
}

// ── Metrik-Karte ──────────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MetricCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white38, fontSize: 10),
              textAlign: TextAlign.center),
        ]),
      );
}
