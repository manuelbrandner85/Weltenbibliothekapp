import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/world_admin_service.dart';
import '../../services/cloudflare_api_service.dart';
import '../../services/health_check_service.dart';
import '../../features/admin/state/admin_state.dart';
import '../../services/supabase_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WORLD ADMIN DASHBOARD – V2 PREMIUM
// Alle Klicks funktionieren · Bestätigungsdialoge · Intelligente UX
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

  // ── Theme per World ────────────────────────────────────────────────────
  Color get _primary =>
      widget.world == 'materie' ? const Color(0xFF1565C0) : const Color(0xFF6A1B9A);
  Color get _accent =>
      widget.world == 'materie' ? const Color(0xFF42A5F5) : const Color(0xFFCE93D8);
  Color get _accentBright =>
      widget.world == 'materie' ? const Color(0xFF82B1FF) : const Color(0xFFEA80FC);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _waitForState();
    });
  }

  Future<void> _waitForState() async {
    for (int i = 0; i < 8; i++) {
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

    // Supabase-Session ist Pflicht für Admin-Zugriff
    if (supabase.auth.currentUser == null) {
      return _accessDeniedScaffold(reason: 'Bitte melde dich zuerst an.');
    }
    if (admin.username == null || admin.username!.isEmpty) {
      return _loadingScaffold();
    }
    if (!admin.isAdmin) return _accessDeniedScaffold();

    return Scaffold(
      backgroundColor: const Color(0xFF08080F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Zurück',
        ),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_primary, _accent]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              '${widget.world.toUpperCase()} Admin',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(admin.username ?? '',
                style: TextStyle(fontSize: 10, color: _accent)),
          ]),
        ]),
        actions: [
          // Backend-Verifikations-Badge
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: admin.backendVerified
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: admin.backendVerified
                    ? Colors.green.withValues(alpha: 0.5)
                    : Colors.orange.withValues(alpha: 0.5),
              ),
            ),
            child: Row(children: [
              Icon(
                admin.backendVerified ? Icons.verified_rounded : Icons.sync_rounded,
                size: 11,
                color: admin.backendVerified ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 3),
              Text(
                admin.backendVerified ? 'Live' : 'Offline',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: admin.backendVerified ? Colors.green : Colors.orange),
              ),
            ]),
          ),
          if (admin.isRootAdmin)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        fontSize: 10, fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ]),
            ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: _accentBright),
            tooltip: 'Alles neu laden',
            onPressed: () {
              ref.read(adminStateProvider(widget.world).notifier).refresh();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Daten werden aktualisiert…'),
                  backgroundColor: _primary,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _accent,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: _accentBright,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded, size: 18), text: 'Übersicht'),
            Tab(icon: Icon(Icons.people_rounded, size: 18), text: 'Nutzer'),
            Tab(icon: Icon(Icons.chat_bubble_rounded, size: 18), text: 'Chat'),
            Tab(icon: Icon(Icons.monitor_heart_rounded, size: 18), text: 'System'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(world: widget.world, admin: admin, accent: _accent, accentBright: _accentBright),
          _UsersTab(world: widget.world, admin: admin, accent: _accent, accentBright: _accentBright),
          _ChatModerationTab(world: widget.world, admin: admin, accent: _accent, accentBright: _accentBright),
          _SystemTab(accent: _accent, accentBright: _accentBright),
        ],
      ),
    );
  }

  Widget _loadingScaffold() => Scaffold(
        backgroundColor: const Color(0xFF08080F),
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              width: 56, height: 56,
              child: CircularProgressIndicator(
                color: _accent, strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Admin-Bereich wird geladen…',
                style: TextStyle(color: Colors.white70, fontSize: 15)),
            const SizedBox(height: 8),
            const Text('Bitte warten',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
          ]),
        ),
      );

  Widget _accessDeniedScaffold({String? reason}) => Scaffold(
        backgroundColor: const Color(0xFF08080F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D0D1A),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Admin-Dashboard',
              style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red.withValues(alpha: 0.4), width: 2),
              ),
              child: const Icon(Icons.lock_rounded, size: 40, color: Colors.red),
            ),
            const SizedBox(height: 20),
            const Text('Kein Zugriff',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              reason ?? 'Dieser Bereich ist nur für Admins zugänglich.',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 1 – ÜBERSICHT
// ═════════════════════════════════════════════════════════════════════════════
class _OverviewTab extends StatefulWidget {
  final String world;
  final AdminState admin;
  final Color accent, accentBright;
  const _OverviewTab(
      {required this.world, required this.admin,
       required this.accent, required this.accentBright});
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
      final stats = await WorldAdminServiceV162.getAnalytics(
        realm: widget.world,
        days: 7,
        adminUserId: widget.admin.username,
      );
      final logs = await WorldAdminService.getAuditLog(
        widget.world,
        limit: 15,
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

  void _showStatsDetail(String label, dynamic value) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(label,
            style: TextStyle(color: widget.accentBright, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$value',
              style: TextStyle(color: widget.accent, fontSize: 48, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Aktuelle Anzahl für ${widget.world.toUpperCase()}',
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Schließen', style: TextStyle(color: widget.accent)),
          ),
        ],
      ),
    );
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
          // Header banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.accent.withValues(alpha: 0.15),
                  widget.accent.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: widget.accent.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              Icon(Icons.bar_chart_rounded, color: widget.accent, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Live-Übersicht · ${widget.world.toUpperCase()}',
                      style: TextStyle(
                          color: widget.accentBright,
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const Text('Letzte 7 Tage · Automatische Aktualisierung',
                      style: TextStyle(color: Colors.white38, fontSize: 11)),
                ]),
              ),
              GestureDetector(
                onTap: _load,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.refresh_rounded, color: widget.accent, size: 18),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // ── 2×2 Statistik-Karten (ALLE KLICKBAR) ─────────────────
          _SectionLabel('Statistiken', Icons.analytics_rounded, widget.accent),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: _ClickableStatCard(
                    icon: Icons.people_rounded,
                    label: 'Nutzer gesamt',
                    value: '$totalUsers',
                    color: const Color(0xFF1E88E5),
                    onTap: () => _showStatsDetail('Nutzer gesamt', totalUsers))),
            const SizedBox(width: 12),
            Expanded(
                child: _ClickableStatCard(
                    icon: Icons.person_add_rounded,
                    label: 'Neu (7 Tage)',
                    value: '$newUsers',
                    color: const Color(0xFF43A047),
                    onTap: () => _showStatsDetail('Neue Nutzer', newUsers))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _ClickableStatCard(
                    icon: Icons.chat_rounded,
                    label: 'Nachrichten',
                    value: '$totalMsgs',
                    color: const Color(0xFF8E24AA),
                    onTap: () => _showStatsDetail('Nachrichten gesamt', totalMsgs))),
            const SizedBox(width: 12),
            Expanded(
                child: _ClickableStatCard(
                    icon: Icons.touch_app_rounded,
                    label: 'Interaktionen',
                    value: '$interactions',
                    color: const Color(0xFFE53935),
                    onTap: () => _showStatsDetail('Interaktionen', interactions))),
          ]),

          const SizedBox(height: 24),

          // ── Quick Actions ──────────────────────────────────────────
          _SectionLabel('Schnellaktionen', Icons.flash_on_rounded, widget.accent),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: _QuickActionBtn(
                icon: Icons.people_rounded,
                label: 'Nutzer verwalten',
                color: const Color(0xFF1E88E5),
                onTap: () {
                  // Navigate to Users tab
                  final scaffold = context.findAncestorStateOfType<_WorldAdminDashboardState>();
                  scaffold?._tabController.animateTo(1);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionBtn(
                icon: Icons.chat_rounded,
                label: 'Chat moderieren',
                color: const Color(0xFF8E24AA),
                onTap: () {
                  final scaffold = context.findAncestorStateOfType<_WorldAdminDashboardState>();
                  scaffold?._tabController.animateTo(2);
                },
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: _QuickActionBtn(
                icon: Icons.monitor_heart_rounded,
                label: 'System prüfen',
                color: const Color(0xFF00897B),
                onTap: () {
                  final scaffold = context.findAncestorStateOfType<_WorldAdminDashboardState>();
                  scaffold?._tabController.animateTo(3);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionBtn(
                icon: Icons.refresh_rounded,
                label: 'Daten laden',
                color: const Color(0xFFE65100),
                onTap: _load,
              ),
            ),
          ]),

          const SizedBox(height: 24),

          // ── Letzte Aktivitäten ─────────────────────────────────────
          _SectionLabel('Letzte Aktionen', Icons.history_rounded, widget.accent),
          const SizedBox(height: 10),

          if (_activity.isEmpty)
            _EmptyHint('Noch keine Admin-Aktionen aufgezeichnet.\nAktionen erscheinen nach Nutzer-Interaktionen.')
          else
            ..._activity.map((e) => _ActivityTile(entry: e)),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 2 – NUTZER
// ═════════════════════════════════════════════════════════════════════════════
class _UsersTab extends StatefulWidget {
  final String world;
  final AdminState admin;
  final Color accent, accentBright;
  const _UsersTab(
      {required this.world, required this.admin,
       required this.accent, required this.accentBright});
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  List<WorldUser> _all = [];
  List<WorldUser> _filtered = [];
  bool _loading = true;
  bool _processing = false;
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
    if (mounted) setState(() => _loading = true);
    try {
      // ✅ FIX: Lade ALLE User aus beiden Welten
      final users = await WorldAdminService.getAllUsers();
      if (mounted) {
        setState(() {
          _all = users;
          _applyFilter();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _snack('❌ Fehler beim Laden: ${e.toString().substring(0, 60)}');
      }
    }
  }

  void _applyFilter() {
    var list = _all;
    if (_roleFilter != 'all') {
      list = list.where((u) => u.role == _roleFilter).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((u) =>
          u.username.toLowerCase().contains(q) ||
          (u.displayName ?? '').toLowerCase().contains(q)).toList();
    }
    _filtered = list;
  }

  void _snack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color ?? const Color(0xFF1A1A2E),
      duration: const Duration(seconds: 3),
    ));
  }

  // Confirmation dialog helper
  Future<bool> _confirm(String title, String msg, {Color? confirmColor}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
        content: Text(msg, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Bestätigen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _ban(WorldUser u) async {
    final confirmed = await _confirm(
      '🚫 Nutzer sperren',
      'Soll @${u.username} wirklich für 24 Stunden gesperrt werden?\n\nDer Nutzer kann danach nicht mehr chatten.',
      confirmColor: Colors.red,
    );
    if (!confirmed) return;

    setState(() => _processing = true);
    final ok = await WorldAdminServiceV162.banUser(
        userId: u.userId,
        reason: 'Admin-Aktion',
        adminUserId: widget.admin.username);
    setState(() => _processing = false);
    _snack(ok ? '🚫 ${u.username} wurde gesperrt' : '❌ Fehler beim Sperren',
        color: ok ? Colors.red.shade700 : Colors.orange);
    if (ok) _load();
  }

  Future<void> _unban(WorldUser u) async {
    final confirmed = await _confirm(
      '✅ Sperre aufheben',
      'Soll die Sperre für @${u.username} wirklich aufgehoben werden?',
      confirmColor: Colors.teal,
    );
    if (!confirmed) return;

    setState(() => _processing = true);
    final ok = await WorldAdminServiceV162.unbanUser(
        userId: u.userId, adminUserId: widget.admin.username ?? 'admin');
    setState(() => _processing = false);
    _snack(ok ? '✅ ${u.username} wurde entsperrt' : '❌ Fehler',
        color: ok ? Colors.teal : Colors.orange);
    if (ok) _load();
  }

  Future<void> _promote(WorldUser u) async {
    final confirmed = await _confirm(
      '⬆️ Zum Admin befördern',
      'Soll @${u.username} wirklich zum Admin befördert werden?\n\nDer Nutzer erhält Zugriff auf das Admin-Dashboard.',
      confirmColor: Colors.green,
    );
    if (!confirmed) return;

    setState(() => _processing = true);
    final ok = await WorldAdminService.promoteUser(
        u.world ?? widget.world, u.userId,
        role: widget.admin.isRootAdmin ? 'root_admin' : 'admin');
    setState(() => _processing = false);
    _snack(ok ? '⬆️ ${u.username} ist jetzt Admin' : '❌ Fehler',
        color: ok ? Colors.green : Colors.orange);
    if (ok) _load();
  }

  Future<void> _demote(WorldUser u) async {
    final confirmed = await _confirm(
      '⬇️ Degradieren',
      'Soll @${u.username} wirklich degradiert werden?\n\nDer Admin-Zugriff wird entzogen.',
      confirmColor: Colors.orange,
    );
    if (!confirmed) return;

    setState(() => _processing = true);
    final ok = await WorldAdminService.demoteUser(
        u.world ?? widget.world, u.userId,
        role: widget.admin.isRootAdmin ? 'root_admin' : 'admin');
    setState(() => _processing = false);
    _snack(ok ? '⬇️ ${u.username} degradiert' : '❌ Fehler',
        color: ok ? Colors.orange : Colors.red);
    if (ok) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(children: [
          // ── Suchleiste + Filter ──────────────────────────────────
          Container(
            color: const Color(0xFF0D0D1A),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(children: [
              // User count badge
              if (!_loading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: widget.accent.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${_filtered.length} Nutzer',
                        style: TextStyle(color: widget.accent, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _load,
                      child: Row(children: [
                        Icon(Icons.refresh_rounded, color: Colors.white38, size: 14),
                        const SizedBox(width: 4),
                        const Text('Aktualisieren',
                            style: TextStyle(color: Colors.white38, fontSize: 11)),
                      ]),
                    ),
                  ]),
                ),
              // Search field
              TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nutzer suchen…',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Colors.white38),
                          onPressed: () => setState(() {
                            _search = '';
                            _searchCtrl.clear();
                            _applyFilter();
                          }))
                      : null,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: widget.accent.withValues(alpha: 0.4))),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (v) => setState(() {
                  _search = v;
                  _applyFilter();
                }),
              ),
              const SizedBox(height: 8),
              // Role filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['all', 'user', 'admin', 'root_admin', 'banned'].map((r) {
                    final labels = {
                      'all': '✦ Alle',
                      'user': '👤 User',
                      'admin': '🛡️ Admin',
                      'root_admin': '👑 Root',
                      'banned': '🚫 Gesperrt',
                    };
                    final sel = _roleFilter == r;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _roleFilter = r;
                          _applyFilter();
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? widget.accent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: sel ? widget.accent : Colors.transparent, width: 1.5),
                          ),
                          child: Text(labels[r]!,
                              style: TextStyle(
                                  color: sel ? widget.accentBright : Colors.white54,
                                  fontSize: 12, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ]),
          ),

          // ── User List ─────────────────────────────────────────────
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: widget.accent))
                : RefreshIndicator(
                    onRefresh: _load,
                    color: widget.accent,
                    child: _filtered.isEmpty
                        ? _EmptyHint('Keine Nutzer gefunden.\nProbiere einen anderen Filter.')
                        : ListView.builder(
                            itemCount: _filtered.length,
                            padding: const EdgeInsets.only(top: 4, bottom: 16),
                            itemBuilder: (ctx, i) {
                              final u = _filtered[i];
                              return _UserTile(
                                user: u,
                                isRootAdmin: widget.admin.isRootAdmin,
                                accent: widget.accent,
                                accentBright: widget.accentBright,
                                onBan: () => _ban(u),
                                onUnban: () => _unban(u),
                                onPromote: () => _promote(u),
                                onDemote: () => _demote(u),
                              );
                            },
                          ),
                  ),
          ),
        ]),

        // Processing overlay
        if (_processing)
          Container(
            color: Colors.black54,
            child: Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                CircularProgressIndicator(color: widget.accent),
                const SizedBox(height: 16),
                const Text('Wird verarbeitet…',
                    style: TextStyle(color: Colors.white70)),
              ]),
            ),
          ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 3 – CHAT-MODERATION
// ═════════════════════════════════════════════════════════════════════════════
class _ChatModerationTab extends StatefulWidget {
  final String world;
  final AdminState admin;
  final Color accent, accentBright;
  const _ChatModerationTab(
      {required this.world, required this.admin,
       required this.accent, required this.accentBright});
  @override
  State<_ChatModerationTab> createState() => _ChatModerationTabState();
}

class _ChatModerationTabState extends State<_ChatModerationTab> {
  late List<String> _rooms;
  late String _selectedRoom;
  List<Map<String, dynamic>> _messages = [];
  bool _loadingMsgs = false;
  bool _autoRefresh = true;
  final _api = CloudflareApiService();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _rooms = widget.world == 'materie'
        ? [
            'materie-politik', 'materie-geschichte', 'materie-ufo',
            'materie-verschwoerung', 'materie-wissenschaft', 'materie-tech',
            'materie-gesundheit', 'materie-medien', 'materie-finanzen',
          ]
        : [
            'energie-meditation', 'energie-chakra', 'energie-bewusstsein',
            'energie-heilung', 'energie-kristalle', 'energie-astrologie',
            'energie-traumdeutung',
          ];
    _selectedRoom = _rooms.first;
    _loadMessages();
    _pollTimer = Timer.periodic(const Duration(seconds: 20),
        (_) { if (_autoRefresh) _loadMessages(); });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    if (mounted) setState(() => _loadingMsgs = true);
    try {
      final msgs = await _api.getChatMessages(_selectedRoom, limit: 50);
      if (mounted) setState(() => _messages = msgs);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Chat laden: $e');
    } finally {
      if (mounted) setState(() => _loadingMsgs = false);
    }
  }

  void _snack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color ?? const Color(0xFF1A1A2E),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _deleteMsg(Map<String, dynamic> msg) async {
    final id = (msg['id'] ?? msg['message_id'] ?? '').toString();
    final username = (msg['username'] ?? 'Unbekannt').toString();
    final content = (msg['content'] ?? msg['message'] ?? '').toString();

    if (id.isEmpty) { _snack('❌ Keine Nachrichten-ID vorhanden'); return; }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🗑️ Nachricht löschen',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Von: @$username',
              style: TextStyle(color: widget.accent, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              content.length > 100 ? '${content.substring(0, 100)}…' : content,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Diese Aktion kann nicht rückgängig gemacht werden.',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_rounded, color: Colors.white, size: 16),
            label: const Text('Löschen', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    try {
      await _api.deleteChatMessage(
        messageId: id,
        roomId: _selectedRoom,
        userId: (msg['user_id'] ?? msg['userId'] ?? '').toString(),
        username: widget.admin.username ?? 'Weltenbibliothek',
        isAdmin: true,
      );
      _snack('🗑️ Nachricht von $username gelöscht', color: Colors.red.shade700);
      _loadMessages();
    } catch (e) {
      _snack('❌ Löschen fehlgeschlagen: $e', color: Colors.orange);
    }
  }

  Future<void> _banSender(Map<String, dynamic> msg) async {
    final userId = (msg['user_id'] ?? msg['userId'] ?? '').toString();
    final username = (msg['username'] ?? 'Unbekannt').toString();

    if (userId.isEmpty || userId.startsWith('user_')) {
      _snack('⚠️ Kein gültiger Account – Ban nicht möglich');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🚫 Sender sperren',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Soll @$username für Chat-Verstöße gesperrt werden?\n\n'
          'Der Nutzer kann 24 Stunden lang nicht mehr chatten.',
          style: const TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.block_rounded, color: Colors.white, size: 16),
            label: const Text('Sperren', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    final ok = await WorldAdminServiceV162.banUser(
        userId: userId,
        reason: 'Chat-Moderation: Regelverstoß',
        adminUserId: widget.admin.username);
    _snack(ok ? '🚫 @$username gesperrt' : '❌ Fehler beim Sperren',
        color: ok ? Colors.red.shade700 : Colors.orange);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Header mit Auto-Refresh Toggle ───────────────────────────
      Container(
        color: const Color(0xFF0D0D1A),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Row(children: [
          Icon(Icons.chat_bubble_rounded, color: widget.accent, size: 16),
          const SizedBox(width: 8),
          Text('${_messages.length} Nachrichten',
              style: TextStyle(color: widget.accentBright, fontSize: 12, fontWeight: FontWeight.w600)),
          const Spacer(),
          // Auto-refresh toggle
          Row(children: [
            const Text('Auto', style: TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(width: 4),
            Switch(
              value: _autoRefresh,
              onChanged: (v) => setState(() => _autoRefresh = v),
              activeThumbColor: widget.accent,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ]),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _loadMessages,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: widget.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.refresh_rounded, color: widget.accent, size: 16),
            ),
          ),
        ]),
      ),

      // ── Raum-Auswahl ─────────────────────────────────────────────
      Container(
        color: const Color(0xFF0D0D1A),
        height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          itemCount: _rooms.length,
          itemBuilder: (ctx, i) {
            final r = _rooms[i];
            final rawLabel = r.split('-').last;
            final cap = rawLabel[0].toUpperCase() + rawLabel.substring(1);
            final sel = r == _selectedRoom;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedRoom = r);
                _loadMessages();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                decoration: BoxDecoration(
                  color: sel ? widget.accent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: sel ? widget.accent : Colors.transparent, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(cap,
                    style: TextStyle(
                        color: sel ? widget.accentBright : Colors.white54,
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
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
                    ? _EmptyHint('Keine Nachrichten in diesem Raum.\nZiehe nach unten zum Aktualisieren.')
                    : ListView.builder(
                        reverse: true,
                        itemCount: _messages.length,
                        itemBuilder: (ctx, i) {
                          final msg = _messages[_messages.length - 1 - i];
                          return _ChatMsgTile(
                            msg: msg,
                            accent: widget.accent,
                            accentBright: widget.accentBright,
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
  final Color accent, accentBright;
  const _SystemTab({required this.accent, required this.accentBright});
  @override
  State<_SystemTab> createState() => _SystemTabState();
}

class _SystemTabState extends State<_SystemTab> {
  final _health = HealthCheckService();
  Timer? _uiTimer;
  bool _ready = false;
  bool _checking = false;

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

  Future<void> _checkAll() async {
    setState(() => _checking = true);
    await _health.checkAllServices();
    if (mounted) setState(() => _checking = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('✅ System-Check abgeschlossen'),
        backgroundColor: widget.accent,
        duration: const Duration(seconds: 2),
      ));
    }
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
    final healthy = svcs.values.where((s) => s.status == HealthStatus.healthy).length;
    return (healthy / svcs.length) * 100;
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Center(child: CircularProgressIndicator(color: widget.accent));
    }

    final svcs = _health.serviceHealth;
    final anyUnhealthy = svcs.values.any((s) => s.status == HealthStatus.unhealthy);
    final allOk = svcs.values.every((s) => s.status == HealthStatus.healthy);

    final overallColor = anyUnhealthy ? Colors.red : allOk ? Colors.green : Colors.orange;
    final overallLabel = anyUnhealthy ? 'Probleme erkannt'
        : allOk ? 'Alle Systeme OK' : 'Eingeschränkt';
    final overallIcon = anyUnhealthy ? Icons.error_rounded
        : allOk ? Icons.check_circle_rounded : Icons.warning_amber_rounded;

    final uptime = _calcUptime();
    final errRate = _health.errorRate;
    final avgLatency = _health.averageLatency;

    return RefreshIndicator(
      onRefresh: _checkAll,
      color: widget.accent,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionLabel('System-Status', Icons.monitor_heart_rounded, widget.accent),
          const SizedBox(height: 12),

          // ── Gesamt-Status ─────────────────────────────────────────
          GestureDetector(
            onTap: _checkAll,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: overallColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: overallColor.withValues(alpha: 0.4)),
              ),
              child: Row(children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: overallColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(overallIcon, color: overallColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(overallLabel,
                        style: TextStyle(color: overallColor, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${svcs.length} Dienste überwacht · Tippen zum Prüfen',
                        style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ]),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: overallColor.withValues(alpha: 0.6), size: 14),
              ]),
            ),
          ),

          const SizedBox(height: 20),

          // ── Metriken ──────────────────────────────────────────────
          _SectionLabel('Metriken', Icons.speed_rounded, widget.accent),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _ClickableMetricCard(
                label: 'Ø Latenz',
                value: '${avgLatency.round()} ms',
                icon: Icons.timer_rounded,
                color: _latencyColor(avgLatency),
                onTap: () {})),
            const SizedBox(width: 10),
            Expanded(child: _ClickableMetricCard(
                label: 'Fehlerrate',
                value: '${errRate.toStringAsFixed(1)} %',
                icon: Icons.error_outline_rounded,
                color: errRate > 10 ? Colors.red : Colors.green,
                onTap: () {})),
            const SizedBox(width: 10),
            Expanded(child: _ClickableMetricCard(
                label: 'Uptime',
                value: '${uptime.toStringAsFixed(0)} %',
                icon: Icons.power_rounded,
                color: uptime > 95 ? Colors.green : Colors.orange,
                onTap: () {})),
          ]),

          const SizedBox(height: 20),

          // ── Einzelne Dienste ──────────────────────────────────────
          _SectionLabel('Dienste', Icons.dns_rounded, widget.accent),
          const SizedBox(height: 10),

          if (svcs.isEmpty)
            _EmptyHint('Keine Dienste überwacht.\nTippe auf „Jetzt prüfen".')
          else
            ...svcs.entries.map((e) => _ClickableServiceRow(
                  name: e.key,
                  health: e.value,
                  statusColor: _statusColor(e.value.status),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A2E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Text(e.key,
                            style: TextStyle(color: widget.accentBright, fontWeight: FontWeight.bold)),
                        content: Column(mainAxisSize: MainAxisSize.min, children: [
                          _InfoRow2(Icons.speed_rounded, 'Latenz: ${e.value.latencyMs} ms'),
                          const SizedBox(height: 6),
                          _InfoRow2(Icons.circle, 'Status: ${e.value.statusText}'),
                        ]),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('OK', style: TextStyle(color: widget.accent)),
                          ),
                        ],
                      ),
                    );
                  },
                )),

          const SizedBox(height: 20),

          // ── Check-Button ──────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _checking ? null : _checkAll,
              icon: _checking
                  ? SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.refresh_rounded, color: Colors.white),
              label: Text(_checking ? 'Prüfe…' : 'Jetzt prüfen',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),

          const SizedBox(height: 16),
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
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: accent, size: 14),
        ),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(
                color: accent, fontWeight: FontWeight.bold,
                fontSize: 13, letterSpacing: 0.3)),
      ]);
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(children: [
            Icon(Icons.inbox_rounded, color: Colors.white24, size: 48),
            const SizedBox(height: 12),
            Text(text,
                style: const TextStyle(color: Colors.white38, fontSize: 14, height: 1.5),
                textAlign: TextAlign.center),
          ]),
        ),
      );
}

// ── Klickbare Statistik-Karte ─────────────────────────────────────────────
class _ClickableStatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  final VoidCallback onTap;
  const _ClickableStatCard(
      {required this.icon, required this.label, required this.value,
       required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Icon(Icons.open_in_new_rounded, color: color.withValues(alpha: 0.4), size: 12),
            ]),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ]),
        ),
      );
}

// ── Quick Action Button ────────────────────────────────────────────────────
class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionBtn(
      {required this.icon, required this.label,
       required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(label,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600))),
            Icon(Icons.arrow_forward_ios_rounded, color: color.withValues(alpha: 0.5), size: 12),
          ]),
        ),
      );
}

// ── Aktivitäts-Eintrag ────────────────────────────────────────────────────
class _ActivityTile extends StatelessWidget {
  final AuditLogEntry entry;
  const _ActivityTile({required this.entry});

  static const _icons = {
    'edit_message':   (Icons.edit_rounded,           Color(0xFF1E88E5)),
    'delete_message': (Icons.delete_rounded,          Color(0xFFE53935)),
    'promote':        (Icons.arrow_upward_rounded,    Color(0xFF43A047)),
    'demote':         (Icons.arrow_downward_rounded,  Color(0xFFFB8C00)),
    'ban':            (Icons.block_rounded,           Color(0xFFE53935)),
    'unban':          (Icons.check_circle_rounded,    Color(0xFF00ACC1)),
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
    final iconData = _icons[key]?.$1 ?? Icons.info_outline_rounded;
    final color    = _icons[key]?.$2 ?? Colors.grey;
    final label    = _labels[key] ?? entry.action;
    final ts       = _fmt(entry.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
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
                    color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
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
    } catch (_) { return ts; }
  }
}

// ── Nutzer-Kachel ─────────────────────────────────────────────────────────
class _UserTile extends StatelessWidget {
  final WorldUser user;
  final bool isRootAdmin;
  final Color accent, accentBright;
  final VoidCallback onBan, onUnban, onPromote, onDemote;
  const _UserTile({
    required this.user,
    required this.isRootAdmin,
    required this.accent,
    required this.accentBright,
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
        'root_admin' => '👑 ROOT',
        'admin'      => '🛡️ Admin',
        _            => '👤 User',
      };

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF12121E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: CircleAvatar(
            radius: 20,
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
                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Row(
            children: [
              Text('@${user.username}',
                  style: TextStyle(color: accent.withValues(alpha: 0.7), fontSize: 11)),
              if (user.world != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: user.world == 'materie'
                        ? Colors.orange.withValues(alpha: 0.15)
                        : Colors.teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: user.world == 'materie'
                          ? Colors.orange.withValues(alpha: 0.4)
                          : Colors.teal.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    user.world == 'materie' ? 'M' : 'E',
                    style: TextStyle(
                      color: user.world == 'materie' ? Colors.orange : Colors.teal,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _roleColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _roleColor.withValues(alpha: 0.3)),
              ),
              child: Text(_roleLabel,
                  style: TextStyle(
                      color: _roleColor, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more_rounded, color: Colors.white38, size: 18),
          ]),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(children: [
                const Divider(color: Colors.white10, height: 16),
                _InfoRow(Icons.access_time_rounded, 'Erstellt: ${_fmtDate(user.createdAt)}'),
                const SizedBox(height: 4),
                _InfoRow(Icons.fingerprint_rounded,
                    'ID: ${user.userId.isEmpty ? "Unbekannt" : user.userId}'),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  if (isRootAdmin && !user.isAdmin)
                    _ActionBtn(
                        Icons.arrow_upward_rounded, 'Zum Admin', Colors.green, onPromote),
                  if (isRootAdmin && user.isAdmin && !user.isRootAdmin)
                    _ActionBtn(
                        Icons.arrow_downward_rounded, 'Degradieren', Colors.orange, onDemote),
                  _ActionBtn(Icons.block_rounded, 'Sperren', Colors.red, onBan),
                  _ActionBtn(Icons.check_circle_outline_rounded, 'Entsperren', Colors.teal, onUnban),
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
    } catch (_) { return '–'; }
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
        Expanded(child: Text(text,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
            overflow: TextOverflow.ellipsis)),
      ]);
}

class _InfoRow2 extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow2(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 14, color: Colors.white54),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

// ── Chat-Nachrichten-Kachel ───────────────────────────────────────────────
class _ChatMsgTile extends StatelessWidget {
  final Map<String, dynamic> msg;
  final Color accent, accentBright;
  final VoidCallback onDelete, onBan;
  const _ChatMsgTile(
      {required this.msg, required this.accent, required this.accentBright,
       required this.onDelete, required this.onBan});

  @override
  Widget build(BuildContext context) {
    final username = (msg['username'] ?? 'Anonym').toString();
    final content  = (msg['content'] ?? msg['message'] ?? '').toString();
    final ts       = _fmt(msg['created_at'] ?? msg['timestamp'] ?? '');
    final emoji    = (msg['avatarEmoji'] ?? msg['avatar_emoji'] ?? '👤').toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF12121E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(username,
                  style: TextStyle(
                      color: accentBright, fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              Text(ts, style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ]),
            const SizedBox(height: 4),
            Text(content,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                maxLines: 5, overflow: TextOverflow.ellipsis),
          ]),
        ),
        const SizedBox(width: 6),
        Column(children: [
          IconButton(
            icon: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 20),
            tooltip: 'Nachricht löschen',
            onPressed: onDelete,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(height: 4),
          IconButton(
            icon: const Icon(Icons.block_rounded, color: Colors.orange, size: 20),
            tooltip: 'Sender sperren',
            onPressed: onBan,
            padding: const EdgeInsets.all(4),
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
    } catch (_) { return ''; }
  }
}

// ── Klickbare Service-Zeile ───────────────────────────────────────────────
class _ClickableServiceRow extends StatelessWidget {
  final String name;
  final ServiceHealth health;
  final Color statusColor;
  final VoidCallback onTap;
  const _ClickableServiceRow(
      {required this.name, required this.health,
       required this.statusColor, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF12121E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Row(children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(name,
                style: const TextStyle(color: Colors.white70, fontSize: 13))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${health.latencyMs} ms',
                  style: TextStyle(color: statusColor.withValues(alpha: 0.8), fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Text(health.statusText,
                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 16),
          ]),
        ),
      );
}

// ── Klickbare Metrik-Karte ────────────────────────────────────────────────
class _ClickableMetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ClickableMetricCard(
      {required this.label, required this.value, required this.icon,
       required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Column(children: [
            Icon(icon, color: color.withValues(alpha: 0.8), size: 18),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
                textAlign: TextAlign.center),
          ]),
        ),
      );
}
