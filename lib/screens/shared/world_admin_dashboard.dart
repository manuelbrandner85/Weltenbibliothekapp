import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' show RealtimeChannel, PostgresChangeEvent;

import '../../config/api_config.dart';
import '../../features/admin/state/admin_state.dart';
import '../../services/activity_heatmap_service.dart'; // 🔥 M2
import '../../services/cloudflare_api_service.dart';
import '../../services/health_check_service.dart';
import '../../services/moderation_queue_service.dart'; // 🚨 M3
import '../../services/supabase_service.dart';
import '../../services/world_admin_service.dart';
import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/cinematic/wb_vignette.dart';

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
    _tabController = TabController(length: 6, vsync: this);
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

    // ⚠️ Supabase-Session NICHT mehr Pflicht — Root-Admin via InvisibleAuth
    // oder Web-Login (WebAuthGate) hat keine Supabase-Session, ist aber
    // trotzdem berechtigt (AdminResolver erkennt via Username).
    // Operationen die echte Auth brauchen, gehen über Worker mit SERVICE_ROLE.
    if (admin.username == null || admin.username!.isEmpty) {
      return _loadingScaffold();
    }
    if (!admin.isAdmin) return _accessDeniedScaffold();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: WBGlassAppBar(
        world: WBWorld.neutral,
        titleWidget: Row(children: [
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Zurück',
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
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
            Tab(icon: Icon(Icons.notifications_active_rounded, size: 18), text: 'Push'),
            Tab(icon: Icon(Icons.history_rounded, size: 18), text: 'Audit'),
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
          _PushBroadcastTab(accent: _accent, accentBright: _accentBright),
          _AuditLogTab(world: widget.world, accent: _accent, accentBright: _accentBright),
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
        appBar: WBGlassAppBar(
        world: WBWorld.neutral,
        title: 'Admin-Dashboard',
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
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

  // CSV-Export — kopiert volles Audit-Log (bis 500 Einträge) in die
  // Zwischenablage. Web: SnackBar weist auf Clipboard hin. App: gleicher
  // Weg, weil Share-Plugin nicht installiert ist und Clipboard universell
  // funktioniert.
  Future<void> _exportActivityCsv() async {
    try {
      final logs = await WorldAdminService.getAuditLog(
        widget.world,
        limit: 500,
        role: widget.admin.isRootAdmin ? 'root_admin' : 'admin',
      );
      if (logs.isEmpty) {
        _toast('Keine Einträge zum Export.');
        return;
      }
      String esc(String? v) {
        final s = v ?? '';
        if (s.contains(',') || s.contains('"') || s.contains('\n')) {
          return '"${s.replaceAll('"', '""')}"';
        }
        return s;
      }
      final buf = StringBuffer()
        ..writeln('timestamp,admin,action,target,old_role,new_role');
      for (final e in logs) {
        buf.writeln([
          esc(e.timestamp),
          esc(e.adminUsername),
          esc(e.action),
          esc(e.targetUsername),
          esc(e.oldRole),
          esc(e.newRole),
        ].join(','));
      }
      await Clipboard.setData(ClipboardData(text: buf.toString()));
      _toast('📋 ${logs.length} Einträge als CSV in Zwischenablage kopiert');
    } catch (e) {
      _toast('❌ Export fehlgeschlagen: $e');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF1A1428),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showStatsDetail(String label, dynamic value) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF050310),
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
          const SizedBox(height: 10),
          // Web-User-Verwaltung (für alle Admins sichtbar)
          if (widget.admin.isAdmin) ...[
            _QuickActionBtn(
              icon: Icons.manage_accounts_rounded,
              label: 'Web-User verwalten',
              color: const Color(0xFFC9A84C),
              onTap: () => Navigator.of(context).pushNamed('/admin/web-users'),
            ),
            const SizedBox(height: 10),
            // 🚨 M3: Moderation-Queue
            _QuickActionBtn(
              icon: Icons.flag_rounded,
              label: 'Moderation-Queue',
              color: const Color(0xFFE53935),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _ModerationQueueScreen(
                    accent: widget.accent,
                    adminUsername: widget.admin.username ?? 'admin',
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ── 🔥 Live-User-Heatmap (M2): Welt × Stunde ────────────
          _SectionLabel('Live-Aktivität (7 Tage)', Icons.local_fire_department_rounded, widget.accent),
          const SizedBox(height: 10),
          _ActivityHeatmapBlock(accent: widget.accent),

          const SizedBox(height: 24),

          // ── 🟢 Live-Online-Roster ───────────────────────────────
          _SectionLabel('Aktuell online', Icons.bolt_rounded, widget.accent),
          const SizedBox(height: 10),
          _OnlineNowBlock(accent: widget.accent, accentBright: widget.accentBright),

          const SizedBox(height: 24),

          // ── Letzte Aktivitäten ─────────────────────────────────────
          Row(children: [
            Expanded(child: _SectionLabel('Letzte Aktionen', Icons.history_rounded, widget.accent)),
            if (_activity.isNotEmpty)
              GestureDetector(
                onTap: _exportActivityCsv,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: widget.accent.withValues(alpha: 0.35)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.download_rounded, color: widget.accent, size: 14),
                    const SizedBox(width: 6),
                    Text('CSV',
                        style: TextStyle(color: widget.accent, fontSize: 11, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
          ]),
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

  // Bulk-Selection — UserIDs der angehakten User. Bulk-Action-Bar erscheint
  // wenn nicht leer (FAB-ähnlich am unteren Rand).
  final Set<String> _selectedIds = {};

  // Real-time-Subscription auf profiles — Liste aktualisiert sich live wenn
  // ein User promotet/gebannt/gelöscht/erstellt wird (egal welcher Admin).
  RealtimeChannel? _profilesChannel;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _profilesChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeRealtime() {
    try {
      _profilesChannel = supabase
          .channel('admin-profiles-${DateTime.now().millisecondsSinceEpoch}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'profiles',
            callback: (_) {
              if (kDebugMode) debugPrint('🔄 profiles change → reload');
              if (mounted) _load();
            },
          )
          .subscribe();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Realtime-Subscribe failed: $e');
    }
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

  // Manual XP-Vergabe: Dialog mit Quick-Buttons (+10/+50/+100/+500/-50) und
  // freiem Eingabefeld + Begründung. Sendet an Worker → audit_log + Push.
  Future<void> _grantXp(WorldUser u) async {
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    int? selectedPreset;
    final presets = [10, 50, 100, 250, 500, -50];

    final result = await showDialog<Map<String, Object>>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF12121E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFFFC107), Color(0xFFFF9800)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('XP-Vergabe',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Empfänger: @${u.username}',
                    style: TextStyle(color: widget.accent, fontSize: 12)),
                const SizedBox(height: 14),
                const Text('Schnell-Wahl',
                    style: TextStyle(
                        color: Colors.white54, fontSize: 11, letterSpacing: 1.2)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: presets.map((p) {
                    final sel = selectedPreset == p;
                    final neg = p < 0;
                    return GestureDetector(
                      onTap: () => setDialogState(() {
                        selectedPreset = p;
                        amountCtrl.text = p.toString();
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: sel
                              ? (neg ? Colors.red : const Color(0xFFFFC107)).withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel
                                ? (neg ? Colors.red : const Color(0xFFFFC107))
                                : Colors.white12,
                          ),
                        ),
                        child: Text(
                          p > 0 ? '+$p' : '$p',
                          style: TextStyle(
                            color: sel
                                ? (neg ? Colors.red.shade100 : const Color(0xFFFFE082))
                                : Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(signed: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Betrag (±, max 10000)',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: widget.accent),
                    ),
                  ),
                  onChanged: (_) => setDialogState(() => selectedPreset = null),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reasonCtrl,
                  maxLength: 80,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Begründung (sichtbar in Push)',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    counterStyle: const TextStyle(color: Colors.white24, fontSize: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: widget.accent),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Vergabe wird im Audit-Log protokolliert.',
                    style: TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, null),
              child: const Text('Abbrechen', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final a = int.tryParse(amountCtrl.text.trim());
                if (a == null || a == 0) {
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(const SnackBar(
                    content: Text('Bitte gültigen Betrag eingeben'),
                    backgroundColor: Colors.redAccent,
                  ));
                  return;
                }
                final r = reasonCtrl.text.trim().isEmpty
                    ? 'Admin-Anpassung'
                    : reasonCtrl.text.trim();
                Navigator.pop<Map<String, Object>>(
                    dialogCtx, {'amount': a, 'reason': r});
              },
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
              label: const Text('Vergeben', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;
    final amount = result['amount'] as int;
    final reason = result['reason'] as String;

    setState(() => _processing = true);
    final res = await WorldAdminServiceV162.grantXp(
      userId: u.userId,
      amount: amount,
      reason: reason,
      adminUsername: widget.admin.username,
    );
    setState(() => _processing = false);
    if (res != null && (res['success'] == true)) {
      final newXp = res['new_xp'];
      _snack(
        amount > 0
            ? '✨ +$amount XP an @${u.username} (neu: $newXp)'
            : '⚠️ $amount XP für @${u.username} (neu: $newXp)',
        color: amount > 0 ? Colors.green.shade700 : Colors.orange,
      );
    } else {
      _snack('❌ XP-Vergabe fehlgeschlagen', color: Colors.red);
    }
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
                            padding: EdgeInsets.only(top: 4, bottom: _selectedIds.isNotEmpty ? 90 : 16),
                            itemBuilder: (ctx, i) {
                              final u = _filtered[i];
                              final selected = _selectedIds.contains(u.userId);
                              return Row(children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Checkbox(
                                    value: selected,
                                    activeColor: widget.accent,
                                    onChanged: (v) => setState(() {
                                      if (v == true) {
                                        _selectedIds.add(u.userId);
                                      } else {
                                        _selectedIds.remove(u.userId);
                                      }
                                    }),
                                  ),
                                ),
                                Expanded(
                                  child: _UserTile(
                                    user: u,
                                    isRootAdmin: widget.admin.isRootAdmin,
                                    accent: widget.accent,
                                    accentBright: widget.accentBright,
                                    onBan: () => _ban(u),
                                    onUnban: () => _unban(u),
                                    onPromote: () => _promote(u),
                                    onDemote: () => _demote(u),
                                    onGrantXp: () => _grantXp(u),
                                  ),
                                ),
                              ]);
                            },
                          ),
                  ),
          ),
        ]),

        // Bulk-Action-Bar — schwebt unten wenn _selectedIds nicht leer
        if (_selectedIds.isNotEmpty)
          Positioned(
            left: 12, right: 12, bottom: 12,
            child: _BulkActionBar(
              count: _selectedIds.length,
              accent: widget.accent,
              accentBright: widget.accentBright,
              onPromote: _bulkPromote,
              onDemote: _bulkDemote,
              onBan: _bulkBan,
              onUnban: _bulkUnban,
              onClear: () => setState(_selectedIds.clear),
            ),
          ),

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

  // ── Bulk-Actions ────────────────────────────────────────────────────
  Future<void> _bulkApply({
    required String label,
    required Future<bool> Function(WorldUser u) action,
  }) async {
    final targets = _all.where((u) => _selectedIds.contains(u.userId)).toList();
    if (targets.isEmpty) return;
    final ok = await _confirm(
      label,
      'Aktion auf ${targets.length} Nutzer anwenden?',
    );
    if (!ok) return;
    setState(() => _processing = true);
    int success = 0, failed = 0;
    for (final u in targets) {
      try {
        if (await action(u)) {
          success++;
        } else {
          failed++;
        }
      } catch (_) {
        failed++;
      }
    }
    if (!mounted) return;
    setState(() {
      _processing = false;
      _selectedIds.clear();
    });
    _snack('✅ $success erfolgreich${failed > 0 ? ', $failed fehlgeschlagen' : ''}');
    _load();
  }

  Future<void> _bulkPromote() => _bulkApply(
        label: 'Befördern (Bulk)',
        action: (u) async => WorldAdminService.promoteUser(
          u.world ?? widget.world,
          u.userId,
          role: widget.admin.isRootAdmin ? 'root_admin' : 'admin',
        ),
      );
  Future<void> _bulkDemote() => _bulkApply(
        label: 'Degradieren (Bulk)',
        action: (u) async => WorldAdminService.demoteUser(
          u.world ?? widget.world,
          u.userId,
          role: widget.admin.isRootAdmin ? 'root_admin' : 'admin',
        ),
      );
  Future<void> _bulkBan() => _bulkApply(
        label: 'Bannen (Bulk)',
        action: (u) async => WorldAdminServiceV162.banUser(
          userId: u.userId,
          reason: 'Bulk-Admin-Aktion',
          adminUserId: widget.admin.username,
        ),
      );
  Future<void> _bulkUnban() => _bulkApply(
        label: 'Entbannen (Bulk)',
        action: (u) async => WorldAdminServiceV162.unbanUser(
          userId: u.userId,
          adminUserId: widget.admin.username,
        ),
      );
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

  // dart2js stolpert über const Map<String, Record> → final Map mit
  // expliziten Tupel-Klassen umgangen.
  static final Map<String, (IconData, Color)> _icons = {
    'edit_message':   (Icons.edit_rounded,           const Color(0xFF1E88E5)),
    'delete_message': (Icons.delete_rounded,          const Color(0xFFE53935)),
    'promote':        (Icons.arrow_upward_rounded,    const Color(0xFF43A047)),
    'demote':         (Icons.arrow_downward_rounded,  const Color(0xFFFB8C00)),
    'ban':            (Icons.block_rounded,           const Color(0xFFE53935)),
    'unban':          (Icons.check_circle_rounded,    const Color(0xFF00ACC1)),
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
  final VoidCallback? onGrantXp;
  const _UserTile({
    required this.user,
    required this.isRootAdmin,
    required this.accent,
    required this.accentBright,
    required this.onBan,
    required this.onUnban,
    required this.onPromote,
    required this.onDemote,
    this.onGrantXp,
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
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _roleColor.withValues(alpha: 0.15),
                child: Text(
                  user.avatarEmoji?.isNotEmpty == true
                      ? user.avatarEmoji!
                      : user.username[0].toUpperCase(),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              // 🟢 Online-Status-Dot rechts unten am Avatar
              Positioned(
                right: -2,
                bottom: -2,
                child: _OnlineDot(lastSeenAtIso: user.lastSeenAt),
              ),
            ],
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
                  if (onGrantXp != null)
                    _ActionBtn(Icons.auto_awesome_rounded, 'XP vergeben',
                        const Color(0xFFFFC107), onGrantXp!),
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

// ── Bulk-Action-Bar (schwebt am unteren Rand, wenn Nutzer angehakt sind) ──
class _BulkActionBar extends StatelessWidget {
  final int count;
  final Color accent;
  final Color accentBright;
  final VoidCallback onPromote;
  final VoidCallback onDemote;
  final VoidCallback onBan;
  final VoidCallback onUnban;
  final VoidCallback onClear;
  const _BulkActionBar({
    required this.count,
    required this.accent,
    required this.accentBright,
    required this.onPromote,
    required this.onDemote,
    required this.onBan,
    required this.onUnban,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0817).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentBright.withValues(alpha: 0.45), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.35),
              blurRadius: 22,
              spreadRadius: 1,
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentBright.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$count ausgewählt',
                  style: TextStyle(color: accentBright, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            _ActionBtn(Icons.arrow_upward, 'Befördern', Colors.green, onPromote),
            const SizedBox(width: 6),
            _ActionBtn(Icons.arrow_downward, 'Degradieren', Colors.orange, onDemote),
            const SizedBox(width: 6),
            _ActionBtn(Icons.block, 'Bannen', Colors.red, onBan),
            const SizedBox(width: 6),
            _ActionBtn(Icons.lock_open, 'Entbannen', Colors.teal, onUnban),
            const SizedBox(width: 10),
            IconButton(
              tooltip: 'Auswahl aufheben',
              icon: const Icon(Icons.close, color: Colors.white60, size: 18),
              onPressed: onClear,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ]),
        ),
      ),
    );
  }
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

// ── Online-Status-Dot am Avatar ────────────────────────────────────
class _OnlineDot extends StatelessWidget {
  final String? lastSeenAtIso;
  const _OnlineDot({required this.lastSeenAtIso});

  ({Color color, String tooltip}) _state() {
    if (lastSeenAtIso == null) {
      return (color: Colors.grey.shade700, tooltip: 'Nie online');
    }
    final t = DateTime.tryParse(lastSeenAtIso!);
    if (t == null) {
      return (color: Colors.grey.shade700, tooltip: 'Offline');
    }
    final delta = DateTime.now().toUtc().difference(t.toUtc());
    if (delta.inMinutes < 2) {
      return (color: const Color(0xFF4CAF50), tooltip: 'Online');
    }
    if (delta.inMinutes < 15) {
      return (color: const Color(0xFFFFC107), tooltip: 'Vor ${delta.inMinutes} Min');
    }
    final h = delta.inHours;
    if (h < 24) {
      return (color: Colors.grey.shade500, tooltip: 'Vor ${h}h');
    }
    return (color: Colors.grey.shade700, tooltip: 'Vor ${delta.inDays} Tagen');
  }

  @override
  Widget build(BuildContext context) {
    final s = _state();
    return Tooltip(
      message: s.tooltip,
      child: Container(
        width: 13,
        height: 13,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: s.color,
          border: Border.all(color: const Color(0xFF12121E), width: 2),
          boxShadow: s.color == const Color(0xFF4CAF50)
              ? [
                  BoxShadow(
                    color: s.color.withValues(alpha: 0.6),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

// ── 🟢 Live-Online-Roster: zeigt User aktiv in den letzten 5/15 min
class _OnlineNowBlock extends StatefulWidget {
  final Color accent;
  final Color accentBright;
  const _OnlineNowBlock({required this.accent, required this.accentBright});

  @override
  State<_OnlineNowBlock> createState() => _OnlineNowBlockState();
}

class _OnlineNowBlockState extends State<_OnlineNowBlock> {
  List<WorldUser> _all = const [];
  bool _loading = true;
  Timer? _t;
  // Cutoff in Minuten — "Online jetzt"
  static const _onlineCutoffMin = 5;
  static const _recentCutoffMin = 15;

  @override
  void initState() {
    super.initState();
    _load();
    _t = Timer.periodic(const Duration(seconds: 45), (_) => _load());
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    try {
      final users = await WorldAdminService.getAllUsers();
      if (mounted) setState(() { _all = users; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Liefert Delta in Minuten (oder null bei kein lastSeen).
  int? _ageMin(WorldUser u) {
    if (u.lastSeenAt == null) return null;
    final t = DateTime.tryParse(u.lastSeenAt!);
    if (t == null) return null;
    return DateTime.now().toUtc().difference(t.toUtc()).inMinutes;
  }

  void _showFullList() {
    final online = _all.where((u) {
      final a = _ageMin(u);
      return a != null && a < _onlineCutoffMin;
    }).toList()
      ..sort((a, b) => (_ageMin(a) ?? 99999).compareTo(_ageMin(b) ?? 99999));
    final recent = _all.where((u) {
      final a = _ageMin(u);
      return a != null && a >= _onlineCutoffMin && a < _recentCutoffMin;
    }).toList()
      ..sort((a, b) => (_ageMin(a) ?? 99999).compareTo(_ageMin(b) ?? 99999));

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A18),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            Center(
              child: Container(
                width: 42, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Icon(Icons.bolt_rounded, color: widget.accent, size: 20),
              const SizedBox(width: 8),
              Text('Live-Roster',
                  style: TextStyle(color: widget.accentBright, fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Text('< $_onlineCutoffMin min: ${online.length}',
                  style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 11)),
            ]),
            const SizedBox(height: 14),
            if (online.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Niemand aktuell online.',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
              )
            else
              ...online.map((u) => _rosterTile(u, isOnline: true)),
            if (recent.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Vor $_onlineCutoffMin–$_recentCutoffMin min · ${recent.length}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1)),
              const SizedBox(height: 6),
              ...recent.map((u) => _rosterTile(u, isOnline: false)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _rosterTile(WorldUser u, {required bool isOnline}) {
    final age = _ageMin(u);
    final String worldLabel;
    final Color worldColor;
    if (u.world == 'materie') {
      worldLabel = 'M'; worldColor = Colors.orange;
    } else if (u.world == 'energie') {
      worldLabel = 'E'; worldColor = Colors.teal;
    } else {
      worldLabel = '?'; worldColor = Colors.white24;
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOnline
              ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
              : Colors.white12,
        ),
      ),
      child: Row(children: [
        Stack(clipBehavior: Clip.none, children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: widget.accent.withValues(alpha: 0.18),
            child: Text(
              u.avatarEmoji?.isNotEmpty == true
                  ? u.avatarEmoji!
                  : (u.username.isEmpty ? '?' : u.username[0].toUpperCase()),
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
          Positioned(
            right: -2, bottom: -2,
            child: _OnlineDot(lastSeenAtIso: u.lastSeenAt),
          ),
        ]),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(u.displayName ?? u.username,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
              Text('@${u.username}',
                  style: TextStyle(color: widget.accent.withValues(alpha: 0.7), fontSize: 10),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: worldColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: worldColor.withValues(alpha: 0.4)),
          ),
          child: Text(worldLabel,
              style: TextStyle(
                  color: worldColor, fontSize: 9, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        if (age != null)
          Text(age < 1 ? 'jetzt' : '${age}m',
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 92,
        decoration: BoxDecoration(
          color: const Color(0xFF12121E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Center(child: CircularProgressIndicator(color: widget.accent, strokeWidth: 2)),
      );
    }

    final onlineNow = _all.where((u) {
      final a = _ageMin(u);
      return a != null && a < _onlineCutoffMin;
    }).toList()
      ..sort((a, b) => (_ageMin(a) ?? 99999).compareTo(_ageMin(b) ?? 99999));

    final byWorld = <String, int>{'energie': 0, 'materie': 0, 'andere': 0};
    for (final u in onlineNow) {
      final w = u.world;
      if (w == 'energie') {
        byWorld['energie'] = byWorld['energie']! + 1;
      } else if (w == 'materie') {
        byWorld['materie'] = byWorld['materie']! + 1;
      } else {
        byWorld['andere'] = byWorld['andere']! + 1;
      }
    }

    final preview = onlineNow.take(6).toList();

    return GestureDetector(
      onTap: _showFullList,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF4CAF50).withValues(alpha: 0.10),
              widget.accent.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 10, height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF4CAF50),
                  boxShadow: [
                    BoxShadow(color: Color(0x884CAF50), blurRadius: 6, spreadRadius: 1),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('${onlineNow.length}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              const Text('online',
                  style: TextStyle(color: Colors.white60, fontSize: 13)),
              const Spacer(),
              Text('E ${byWorld['energie']}  ·  M ${byWorld['materie']}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 18),
            ]),
            const SizedBox(height: 10),
            if (preview.isEmpty)
              const Text('Niemand aktiv in den letzten 5 Minuten.',
                  style: TextStyle(color: Colors.white54, fontSize: 12))
            else
              Wrap(
                spacing: 6, runSpacing: 6,
                children: preview.map((u) {
                  final ageMin = _ageMin(u);
                  final initial = u.username.isEmpty
                      ? '?'
                      : u.username[0].toUpperCase();
                  return Tooltip(
                    message: '@${u.username} · ${ageMin == null ? "?" : ageMin < 1 ? "jetzt" : "${ageMin}m"}',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        CircleAvatar(
                          radius: 9,
                          backgroundColor: widget.accent.withValues(alpha: 0.2),
                          child: Text(
                            u.avatarEmoji?.isNotEmpty == true ? u.avatarEmoji! : initial,
                            style: const TextStyle(fontSize: 9, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(u.username,
                            style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            if (onlineNow.length > preview.length) ...[
              const SizedBox(height: 6),
              Text('+${onlineNow.length - preview.length} weitere · Tippen für Liste',
                  style: TextStyle(color: widget.accent, fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── M2: Live-Aktivitäts-Heatmap (Welt × Stunde) ────────────────────
class _ActivityHeatmapBlock extends StatefulWidget {
  final Color accent;
  const _ActivityHeatmapBlock({required this.accent});

  @override
  State<_ActivityHeatmapBlock> createState() => _ActivityHeatmapBlockState();
}

class _ActivityHeatmapBlockState extends State<_ActivityHeatmapBlock> {
  ActivityHeatmap? _data;
  bool _loading = true;

  static const _worldColors = {
    'materie': Color(0xFF3B82F6),
    'energie': Color(0xFFA855F7),
    'vorhang': Color(0xFFC9A84C),
    'ursprung': Color(0xFF00D4AA),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await ActivityHeatmapService.instance.compute(days: 7);
    if (mounted) {
      setState(() {
        _data = d;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF12121E),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: widget.accent, strokeWidth: 2),
        ),
      );
    }
    final data = _data!;
    final maxVal = data.data.values
        .expand((row) => row)
        .fold<int>(0, (m, v) => v > m ? v : m);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF12121E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: widget.accent, size: 14),
              const SizedBox(width: 6),
              Text(
                '${data.totalMessages} Nachrichten · ${data.fromTime.day}.${data.fromTime.month}. bis heute',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // X-Achse: Stunden 0-23 (alle 6h beschriftet)
          Padding(
            padding: const EdgeInsets.only(left: 70),
            child: Row(
              children: List.generate(24, (h) {
                return Expanded(
                  child: Text(
                    h % 6 == 0 ? '$h' : '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 9,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 4),
          // Heatmap-Zeilen pro Welt
          for (final w in const ['materie', 'energie', 'vorhang', 'ursprung'])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _worldColors[w],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          w[0].toUpperCase() + w.substring(1, 3),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: List.generate(24, (h) {
                        final v = data.data[w]?[h] ?? 0;
                        final intensity = maxVal == 0 ? 0.0 : v / maxVal;
                        return Expanded(
                          child: Tooltip(
                            message: '$w · ${h}h: $v Msg',
                            child: Container(
                              height: 22,
                              margin: const EdgeInsets.symmetric(horizontal: 0.5),
                              decoration: BoxDecoration(
                                color: _worldColors[w]!.withValues(
                                    alpha: 0.08 + (intensity * 0.85)),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── M3: Moderation-Queue-Screen ────────────────────────────────────
class _ModerationQueueScreen extends StatefulWidget {
  final Color accent;
  final String adminUsername;
  const _ModerationQueueScreen({
    required this.accent,
    required this.adminUsername,
  });

  @override
  State<_ModerationQueueScreen> createState() => _ModerationQueueScreenState();
}

class _ModerationQueueScreenState extends State<_ModerationQueueScreen> {
  List<MessageReport> _reports = const [];
  bool _loading = true;
  String _filter = 'open';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await ModerationQueueService.instance.queue(status: _filter);
    if (mounted) {
      setState(() {
        _reports = list;
        _loading = false;
      });
    }
  }

  Future<void> _act(MessageReport r, String status) async {
    final ok = await ModerationQueueService.instance.review(
      reportId: r.id,
      status: status,
      reviewedBy: widget.adminUsername,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? (status == 'actioned' ? '✅ Bearbeitet' : '✓ Verworfen')
          : '❌ Fehler'),
      backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade700,
    ));
    if (ok) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050310),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Moderation-Queue',
            style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: widget.accent),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list_rounded, color: widget.accent),
            onSelected: (v) {
              setState(() => _filter = v);
              _load();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'open', child: Text('Offen')),
              PopupMenuItem(value: 'actioned', child: Text('Bearbeitet')),
              PopupMenuItem(value: 'dismissed', child: Text('Verworfen')),
            ],
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: widget.accent),
            )
          : _reports.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: Colors.white24, size: 56),
                        const SizedBox(height: 14),
                        Text(
                          'Keine Reports im Status "$_filter"',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55)),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: widget.accent,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: _reports.length,
                    itemBuilder: (_, i) => _reportCard(_reports[i]),
                  ),
                ),
    );
  }

  Widget _reportCard(MessageReport r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF12121E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: Colors.red, size: 16),
              const SizedBox(width: 6),
              Text(
                r.reason.toUpperCase(),
                style: const TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5),
              ),
              const Spacer(),
              Text(
                _relTime(r.createdAt),
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Gemeldet von @${r.reporterName ?? r.reporterId}'
            '${r.targetUser != null ? " · gegen @${r.targetUser}" : ""}',
            style:
                TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
          ),
          if (r.notes?.isNotEmpty ?? false) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(r.notes!,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          ],
          const SizedBox(height: 4),
          Text('Message-ID: ${r.messageId}',
              style: const TextStyle(color: Colors.white24, fontSize: 10)),
          if (r.status == 'open') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _act(r, 'actioned'),
                    icon: const Icon(Icons.gavel, size: 16),
                    label: const Text('Maßnahme'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _act(r, 'dismissed'),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Verwerfen'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _relTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'jetzt';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'vor ${diff.inHours}h';
    return 'vor ${diff.inDays}d';
  }
}

// ═══════════════════════════════════════════════════════════
// 🔔 PUSH-BROADCAST TAB
// ═══════════════════════════════════════════════════════════
class _PushBroadcastTab extends StatefulWidget {
  final Color accent;
  final Color accentBright;
  const _PushBroadcastTab({required this.accent, required this.accentBright});

  @override
  State<_PushBroadcastTab> createState() => _PushBroadcastTabState();
}

class _PushBroadcastTabState extends State<_PushBroadcastTab> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _deeplink = TextEditingController();
  String _target = 'all';
  bool _sending = false;
  List<Map<String, dynamic>> _history = [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _deeplink.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.workerUrl}/api/admin/push/history'),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (data['broadcasts'] as List?) ?? const [];
        if (mounted) {
          setState(() {
            _history = list.cast<Map<String, dynamic>>();
            _loadingHistory = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _send() async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Titel und Body sind pflicht'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    setState(() => _sending = true);
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.workerUrl}/api/admin/push/broadcast'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'target': _target,
          'title': _title.text.trim(),
          'body': _body.text.trim(),
          if (_deeplink.text.trim().isNotEmpty) 'deeplink': _deeplink.text.trim(),
        }),
      ).timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final enq = data['enqueued'] ?? 0;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('✅ $enq Empfänger in Queue · Cron sendet via FCM (max 5min)'),
            backgroundColor: widget.accent,
          ));
          _title.clear();
          _body.clear();
          _deeplink.clear();
          await _loadHistory();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('❌ Fehler ${res.statusCode}: ${res.body}'),
            backgroundColor: Colors.redAccent,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Netzwerk: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [widget.accent.withValues(alpha: 0.35), widget.accent.withValues(alpha: 0.1)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.accent.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🔔 PUSH BROADCAST',
                    style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _field('Empfänger-Zielgruppe',
                    children: [
                      for (final t in ['all', 'materie', 'energie', 'vorhang', 'ursprung'])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(t.toUpperCase(), style: const TextStyle(fontSize: 10)),
                            selected: _target == t,
                            onSelected: (_) => setState(() => _target = t),
                            selectedColor: widget.accent,
                          ),
                        ),
                    ]),
                const SizedBox(height: 10),
                TextField(
                  controller: _title,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDeco('Titel (max 60 Zeichen)'),
                  maxLength: 60,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _body,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  maxLength: 200,
                  decoration: _inputDeco('Body (max 200 Zeichen)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _deeplink,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDeco('Deeplink (optional, z.B. /vorhang/module)'),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send),
                    label: Text(_sending ? 'Sende…' : 'BROADCAST SENDEN',
                        style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(children: [
            Text('VERLAUF · letzte ${_history.length}',
                style: TextStyle(color: widget.accentBright, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.refresh, color: widget.accent),
              onPressed: _loadHistory,
            ),
          ]),
          const SizedBox(height: 8),
          if (_loadingHistory)
            const Center(child: CircularProgressIndicator())
          else if (_history.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Noch keine Broadcasts', style: TextStyle(color: Colors.white60)),
              ),
            )
          else
            for (final b in _history) _buildHistoryCard(b),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> b) {
    final sent = (b['sent'] as num?)?.toInt() ?? 0;
    final failed = (b['failed'] as num?)?.toInt() ?? 0;
    final pending = (b['pending'] as num?)?.toInt() ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text((b['title'] as String?) ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          Text((b['body'] as String?) ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Row(children: [
            Text((b['created_at'] as String?)?.substring(0, 16) ?? '',
                style: const TextStyle(color: Colors.white54, fontSize: 10)),
            const Spacer(),
            _stat('✓', sent, Colors.green),
            const SizedBox(width: 6),
            _stat('⏳', pending, Colors.amber),
            const SizedBox(width: 6),
            _stat('✗', failed, Colors.redAccent),
          ]),
        ],
      ),
    );
  }

  Widget _stat(String icon, int n, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
        child: Text('$icon $n', style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)),
      );

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
        isDense: true,
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        counterStyle: const TextStyle(color: Colors.white38, fontSize: 10),
      );

  Widget _field(String label, {required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: widget.accentBright, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: children)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 📜 AUDIT-LOG TAB
// ═══════════════════════════════════════════════════════════
class _AuditLogTab extends StatefulWidget {
  final String world;
  final Color accent;
  final Color accentBright;
  const _AuditLogTab({required this.world, required this.accent, required this.accentBright});

  @override
  State<_AuditLogTab> createState() => _AuditLogTabState();
}

class _AuditLogTabState extends State<_AuditLogTab> {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;
  String _filterAction = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.workerUrl}/api/admin/audit/${widget.world}?limit=200'),
      ).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (data['logs'] as List?) ?? const [];
        if (mounted) {
          setState(() {
            _logs = list.cast<Map<String, dynamic>>();
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filterAction == 'all') return _logs;
    return _logs.where((l) => (l['action'] as String? ?? '').contains(_filterAction)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final actions = {'all', ..._logs.map((l) => (l['action'] as String? ?? 'unknown')).toSet()};
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(children: [
            Text('${_filtered.length}/${_logs.length} EINTRÄGE',
                style: TextStyle(color: widget.accentBright, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(icon: Icon(Icons.refresh, color: widget.accent), onPressed: _load),
          ]),
        ),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final a in actions)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(a, style: const TextStyle(fontSize: 10)),
                    selected: _filterAction == a,
                    onSelected: (_) => setState(() => _filterAction = a),
                    selectedColor: widget.accent,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? const Center(child: Text('Keine Einträge', style: TextStyle(color: Colors.white60)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final l = _filtered[i];
                        return _buildLogRow(l);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildLogRow(Map<String, dynamic> l) {
    final action = (l['action'] as String?) ?? '';
    final admin = (l['admin_username'] as String?) ?? 'unknown';
    final target = (l['target_username'] as String?) ?? '';
    final details = (l['details'] as String?) ?? '';
    final ts = (l['timestamp'] as String?) ?? '';
    final icon = _iconFor(action);
    final color = _colorFor(action);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(action,
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(ts.substring(0, ts.length >= 16 ? 16 : ts.length).replaceAll('T', ' '),
                    style: const TextStyle(color: Colors.white54, fontSize: 10)),
              ]),
              Text('$admin → $target',
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
              if (details.isNotEmpty)
                Text(details,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                    maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ]),
    );
  }

  IconData _iconFor(String a) {
    if (a.contains('ban')) return Icons.block;
    if (a.contains('delete')) return Icons.delete;
    if (a.contains('edit')) return Icons.edit;
    if (a.contains('role')) return Icons.shield;
    if (a.contains('mute')) return Icons.volume_off;
    return Icons.history;
  }

  Color _colorFor(String a) {
    if (a.contains('ban') || a.contains('delete')) return Colors.redAccent;
    if (a.contains('role') || a.contains('admin')) return Colors.amber;
    if (a.contains('edit')) return Colors.lightBlueAccent;
    if (a.contains('mute')) return Colors.orangeAccent;
    return Colors.white60;
  }
}
