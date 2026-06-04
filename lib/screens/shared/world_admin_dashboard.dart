import 'dart:async';
import 'dart:convert';
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart'
    show RealtimeChannel, PostgresChangeEvent, Supabase;

import '../../config/api_config.dart';
import '../../core/constants/roles.dart';
import '../../features/admin/state/admin_state.dart';
import '../../core/auth/admin_resolver.dart';
import '../../services/admin_api_client.dart';
import '../../services/admin_auth_service.dart';
import '../../services/activity_heatmap_service.dart'; // 🔥 M2
import '../../services/cloudflare_api_service.dart';
import '../../services/health_check_service.dart';
import '../../services/moderation_queue_service.dart'; // 🚨 M3
import '../../services/push_notification_helper.dart';
import '../../services/storage_service.dart';
import '../../services/supabase_service.dart';
import '../../services/world_admin_service.dart';
import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';

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
  TabController? _tabController;
  int _tabsLen = 0;

  // v103: Dashboard ist ein globales Tool fuer ALLE Welten gleichzeitig.
  // Kein Welt-Filter, kein Welt-Switcher, keine welt-spezifischen Farben.
  // widget.world bleibt nur als Cache-Key fuer adminStateProvider erhalten
  // (damit Rolle/Username aus dem bereits geladenen World-Wrapper-State
  // gelesen werden kann -- sonst muesste das Dashboard neu laden).
  static const Color _primary = Color(0xFF6A1B9A);
  static const Color _accent = Color(0xFFCE93D8);
  static const Color _accentBright = Color(0xFFEA80FC);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _waitForState();
    });
  }

  /// v103: Ermittelt erlaubte Tabs anhand der Rolle.
  /// Moderator sieht nur Uebersicht/Chat/Audit, Admin+ alles.
  List<_AdminTabDef> _availableTabs(String? role) {
    final tabs = <_AdminTabDef>[
      const _AdminTabDef(
          icon: Icons.dashboard_rounded, label: 'Übersicht', kind: 'overview'),
    ];
    if (AppRoles.canViewUserList(role)) {
      tabs.add(const _AdminTabDef(
          icon: Icons.people_rounded, label: 'Nutzer', kind: 'users'));
    }
    tabs.add(const _AdminTabDef(
        icon: Icons.chat_bubble_rounded, label: 'Chat', kind: 'chat'));
    if (AppRoles.canEditContent(role)) {
      tabs.add(const _AdminTabDef(
          icon: Icons.analytics_rounded, label: 'Content', kind: 'content'));
    }
    if (AppRoles.canCreateAnnouncements(role)) {
      tabs.add(const _AdminTabDef(
          icon: Icons.notifications_active_rounded,
          label: 'Push',
          kind: 'push'));
    }
    tabs.add(const _AdminTabDef(
        icon: Icons.history_rounded, label: 'Audit', kind: 'audit'));
    if (AppRoles.isAdmin(role)) {
      tabs.add(const _AdminTabDef(
          icon: Icons.monitor_heart_rounded, label: 'System', kind: 'system'));
    }
    return tabs;
  }

  void _ensureTabController(int length) {
    if (_tabController != null && _tabsLen == length) return;
    _tabController?.dispose();
    _tabController = TabController(length: length, vsync: this);
    _tabsLen = length;
  }

  /// Fallback: pick highest role from backend state + local profile cache.
  /// Role-based only -- no username override (that would allow privilege
  /// escalation by setting a local username to a known admin name).
  /// AdminStateNotifier already handles the username->role mapping via
  /// isRootAdminByUsername in step 2.5, so the role is correct by the
  /// time it reaches here.
  AdminState _resolveLocalFallback(AdminState provider) {
    try {
      // TEIL 1A: single unified profile -- one local source.
      final storage = StorageService();
      final profile = storage.getProfile();

      final allUsernames = <String>[
        provider.username ?? '',
        profile?.username ?? '',
      ].where((u) => u.isNotEmpty).toList();

      if (allUsernames.isEmpty) return provider;

      final localUser = allUsernames.first;

      // Pick highest role from backend state + local cache (role-based only).
      final candidates = <String?>[
        provider.role,
        profile?.role,
      ].where((r) => r != null && r.isNotEmpty).cast<String>().toList();

      final effectiveRole = _highestRole(candidates) ?? provider.role;

      return AdminState(
        isAdmin: AppRoles.canAccessAdminDashboard(effectiveRole),
        isRootAdmin: AppRoles.isRootAdmin(effectiveRole),
        isModerator: AppRoles.isModerator(effectiveRole),
        world: provider.world,
        backendVerified: provider.backendVerified,
        username: localUser,
        role: effectiveRole,
      );
    } catch (_) {
      return provider;
    }
  }

  /// Rangliste der Rollen (hoechste zuerst): root_admin > admin >
  /// content_editor > moderator > user.
  String? _highestRole(List<String> roles) {
    const order = [
      'root_admin',
      'root-admin',
      'admin',
      'content_editor',
      'moderator',
      'user'
    ];
    for (final candidate in order) {
      if (roles.contains(candidate)) return candidate;
    }
    return roles.isEmpty ? null : roles.first;
  }

  Future<void> _waitForState() async {
    // v101: adminStateProvider wird NUR mit der Original-Welt (widget.world)
    // aufgerufen, damit der Cache aus dem World-Wrapper getroffen wird.
    // _selectedWorld dient nur dazu, Daten zu filtern -- nicht die Rolle
    // zu ermitteln. Sonst wuerde adminStateProvider('all') einen neuen
    // Notifier starten ohne lokalen Cache und das Dashboard haengt im
    // Loading-State.
    for (int i = 0; i < 8; i++) {
      final a = ref.read(adminStateProvider(widget.world));
      if (a.username != null && a.username!.isNotEmpty) return;
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // v101: Rolle/Zugriff IMMER aus der Original-Welt lesen.
    // _selectedWorld wird nur an die Tabs weitergegeben fuer Daten-Filter,
    // beeinflusst aber nie die Auth-State-Resolution.
    final providerAdmin = ref.watch(adminStateProvider(widget.world));

    // v102: Lokaler Fallback falls Provider noch nicht geladen oder
    // Backend nicht erreichbar. Pruft Materie/Energie-Username gegen
    // den hardcoded Root-Admin-Username sowie das lokale role-Feld.
    final admin = _resolveLocalFallback(providerAdmin);

    // ⚠️ Supabase-Session NICHT mehr Pflicht — Root-Admin via InvisibleAuth
    // oder Web-Login (WebAuthGate) hat keine Supabase-Session, ist aber
    // trotzdem berechtigt (AdminResolver erkennt via Username).
    // Operationen die echte Auth brauchen, gehen über Worker mit SERVICE_ROLE.
    if (admin.username == null || admin.username!.isEmpty) {
      return _loadingScaffold();
    }
    // Access gate: role-based only. Username-based bypasses removed to
    // prevent privilege escalation via locally-manipulated profile data.
    final hasAccess = admin.isAdmin ||
        admin.isRootAdmin ||
        admin.isModerator ||
        AppRoles.canAccessAdminDashboard(admin.role ?? '');
    if (!hasAccess) return _accessDeniedScaffold();

    // v103: Tabs dynamisch -- Rollen-Permission steuert Sichtbarkeit.
    final tabDefs = _availableTabs(admin.role);
    _ensureTabController(tabDefs.length);

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
            child: const Icon(Icons.admin_panel_settings,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Admin-Dashboard',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(admin.username ?? '',
                  style: const TextStyle(fontSize: 10, color: _accent)),
              const SizedBox(width: 6),
              if (AppRoles.getBadgeEmoji(admin.role).isNotEmpty)
                Text(AppRoles.getBadgeEmoji(admin.role),
                    style: const TextStyle(fontSize: 10)),
            ]),
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
                admin.backendVerified
                    ? Icons.verified_rounded
                    : Icons.sync_rounded,
                size: 11,
                color: admin.backendVerified ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 3),
              Text(
                admin.backendVerified ? 'Live' : 'Offline',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color:
                        admin.backendVerified ? Colors.green : Colors.orange),
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
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
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
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white70, size: 20),
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
          labelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
          tabs: tabDefs
              .map((t) => Tab(icon: Icon(t.icon, size: 18), text: t.label))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: tabDefs.map((t) => _buildTabBody(t.kind, admin)).toList(),
      ),
    );
  }

  Widget _buildTabBody(String kind, AdminState admin) {
    switch (kind) {
      case 'overview':
        return _OverviewTab(
            world: 'all',
            admin: admin,
            accent: _accent,
            accentBright: _accentBright);
      case 'users':
        return _UsersTab(
            world: 'all',
            admin: admin,
            accent: _accent,
            accentBright: _accentBright);
      case 'chat':
        return _ChatModerationTab(
            world: 'all',
            admin: admin,
            accent: _accent,
            accentBright: _accentBright);
      case 'content':
        return _ContentInsightsTab(
            accent: _accent, accentBright: _accentBright);
      case 'push':
        return _PushBroadcastTab(accent: _accent, accentBright: _accentBright);
      case 'audit':
        return _AuditReportsWrapper(
            world: 'all',
            accent: _accent,
            accentBright: _accentBright,
            isRootAdmin: admin.isRootAdmin);
      case 'system':
        return _SystemTab(
            accent: _accent, accentBright: _accentBright, admin: admin);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _loadingScaffold() => Scaffold(
        backgroundColor: const Color(0xFF08080F),
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                color: _accent,
                strokeWidth: 3,
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
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: Colors.white70, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.red.withValues(alpha: 0.4), width: 2),
              ),
              child:
                  const Icon(Icons.lock_rounded, size: 40, color: Colors.red),
            ),
            const SizedBox(height: 20),
            const Text('Kein Zugriff',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
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
      {required this.world,
      required this.admin,
      required this.accent,
      required this.accentBright});
  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  Map<String, dynamic> _stats = {};
  List<AuditLogEntry> _activity = [];
  bool _loading = true;
  String? _loadError; // FIX (#6): Fehler im Overview-Tab sichtbar machen
  RealtimeChannel? _channel;
  // v115 (Feature E): Anzahl offener User-Reports fuer die Moderationsqueue.
  int _openReports = 0;

  @override
  void initState() {
    super.initState();
    _load();
    // v103 Phase 4c: Statt Timer.periodic alle 30s -> Realtime auf
    // profiles + admin_actions. Spart Netzwerk-Traffic + sofortige
    // Updates wenn neue Aktionen passieren.
    try {
      _channel = supabase
          .channel('admin-overview-realtime')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'profiles',
            callback: (_) => _load(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'admin_actions',
            callback: (_) => _load(),
          )
          .subscribe();
    } catch (_) {/* RT optional */}
  }

  @override
  void didUpdateWidget(covariant _OverviewTab oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    try {
      _channel?.unsubscribe();
    } catch (_) {}
    super.dispose();
  }

  // v98: Sync-Endpoint -- backfillt fehlende profiles aus auth.users.
  Future<void> _syncUsers() async {
    _toast('🔄 Synchronisation gestartet...');
    int totalInserted = 0;
    int totalAuthSeen = 0;
    try {
      final result = await WorldAdminServiceV162.syncUsers();
      if (result != null) {
        totalInserted += (result['profiles_inserted'] as int?) ?? 0;
        totalAuthSeen += (result['auth_users_seen'] as int?) ?? 0;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Auth-Sync: $e');
    }
    int legacySynced = 0;
    try {
      final legacyResult =
          await WorldAdminServiceV162.syncUsers(extraUsers: []);
      if (legacyResult != null) {
        legacySynced = (legacyResult['legacy_profiles_synced'] as int?) ?? 0;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Legacy-Sync: $e');
    }
    if (!mounted) return;
    final total = totalInserted + legacySynced;
    if (total > 0) {
      _toast(
          '✅ $total neue Profile synchronisiert (Auth: $totalInserted, Legacy: $legacySynced)');
    } else {
      _toast('✅ Alle Profile sind aktuell ($totalAuthSeen Auth-User geprueft)');
    }
    _load();
  }

  /// PHASE-3 FIX: Live-Diagnose der Worker-Verbindung. Zeigt das
  /// vollstaendige Ergebnis im Modal damit Admins selbst sehen koennen
  /// WAS schiefgelaufen ist (Worker erreichbar? HMAC-Header da? Profile
  /// gefunden? Welcher Status-Code kam zurueck?).
  /// PHASE-4: + Repair-Buttons (Cache leeren, Rolle neu aufloesen).
  Future<void> _runDiagnose(BuildContext context) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    Map<String, dynamic> diag;
    try {
      diag = await AdminApiClient.instance.diagnose();
    } catch (e) {
      diag = {'error': e.toString()};
    }
    if (!context.mounted) return;
    Navigator.of(context).pop(); // Loading-Dialog schliessen
    final pretty = const JsonEncoder.withIndent('  ').convert(diag);
    final adminUsers = diag['admin_users'] as Map?;
    final hasError = adminUsers != null && adminUsers['ok'] != true;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12121E),
        title: Row(children: [
          Icon(
            hasError ? Icons.warning_rounded : Icons.check_circle_rounded,
            color: hasError ? Colors.orange : const Color(0xFF26A69A),
          ),
          const SizedBox(width: 8),
          const Text('Worker-Diagnose',
              style: TextStyle(color: Colors.white, fontSize: 16)),
        ]),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasError)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'Admin-Endpoint lieferte HTTP '
                      '${adminUsers['status']}. Probier "Reparieren" '
                      'unten -- das laedt deine Rolle neu, leert den '
                      'Cache und versucht es nochmal.',
                      style: const TextStyle(
                          color: Colors.orangeAccent, fontSize: 12),
                    ),
                  ),
                if (hasError) const SizedBox(height: 12),
                SelectableText(
                  pretty,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.build_rounded, size: 16),
            label: const Text('Reparieren'),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _runRepair(context);
            },
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Schliessen'),
          ),
        ],
      ),
    );
  }

  /// PHASE-4: Reparatur-Sequenz wenn Admin-Calls fehlschlagen.
  /// 1) AdminApi-Cache leeren
  /// 2) AdminResolver.resolveCurrentRole() forciert neu aufloesen
  ///    (persistiert wieder den Username in UnifiedStorageService)
  /// 3) Dashboard-Daten neu laden
  Future<void> _runRepair(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    AdminApiClient.instance.invalidateCache();
    try {
      await AdminResolver.resolveCurrentRole();
    } catch (_) {/* best-effort */}
    if (!context.mounted) return;
    messenger.showSnackBar(const SnackBar(
      content: Text('🛠 Cache geleert + Rolle neu aufgeloest. Lade neu...'),
      duration: Duration(seconds: 2),
    ));
    await _load();
    if (!context.mounted) return;
    messenger.showSnackBar(const SnackBar(
      content: Text('✓ Reparatur abgeschlossen'),
      duration: Duration(seconds: 2),
    ));
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
      // v115 (Feature E): offene Reports-Anzahl fuer die Moderationsqueue.
      final reportsData =
          await WorldAdminServiceV162.getReports(status: 'open', limit: 1);
      final openReports = reportsData == null
          ? 0
          : ((reportsData['counts'] as Map?)?['open'] as num?)?.toInt() ?? 0;
      if (mounted) {
        setState(() {
          _stats = stats;
          _activity = logs;
          _openReports = openReports;
          _loading = false;
          // FIX (#6): bei 'error'-Feld in stats den Fehler anzeigen.
          final statErr = stats['error'];
          _loadError = (statErr is String && statErr.isNotEmpty)
              ? 'Statistiken konnten nicht geladen werden ($statErr). '
                  'Tipp: Diagnose-Button pruefen.'
              : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'Uebersicht konnte nicht geladen werden.\n'
              'Tipp: "Diagnose"-Button weiter unten pruefen.';
        });
      }
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
            style: TextStyle(
                color: widget.accentBright, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$value',
              style: TextStyle(
                  color: widget.accent,
                  fontSize: 48,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Aktuelle Anzahl ueber ALLE WELTEN',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
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

    final totalUsers = _stats['totalUsers'] ?? _stats['total_users'] ?? 0;
    final totalMsgs = _stats['totalMessages'] ?? _stats['total_messages'] ?? 0;
    final newUsers = _stats['newUsers'] ?? _stats['new_users'] ?? 0;
    final interactions = _stats['interactions'] ?? 0;

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
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Live-Übersicht · Alle Welten',
                          style: TextStyle(
                              color: widget.accentBright,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      const Text('Letzte 7 Tage · Automatische Aktualisierung',
                          style:
                              TextStyle(color: Colors.white38, fontSize: 11)),
                    ]),
              ),
              GestureDetector(
                onTap: _syncUsers,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.cloud_sync_rounded,
                      color: Colors.greenAccent, size: 18),
                ),
              ),
              GestureDetector(
                onTap: _load,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.refresh_rounded,
                      color: widget.accent, size: 18),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // FIX (#6): Fehler-Banner wenn Stats nicht geladen werden konnten.
          if (_loadError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_loadError!,
                      style: const TextStyle(
                          color: Colors.orangeAccent, fontSize: 12)),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 12),

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
                    onTap: () =>
                        _showStatsDetail('Nutzer gesamt', totalUsers))),
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
                    onTap: () =>
                        _showStatsDetail('Nachrichten gesamt', totalMsgs))),
            const SizedBox(width: 12),
            Expanded(
                child: _ClickableStatCard(
                    icon: Icons.touch_app_rounded,
                    label: 'Interaktionen',
                    value: '$interactions',
                    color: const Color(0xFFE53935),
                    onTap: () =>
                        _showStatsDetail('Interaktionen', interactions))),
          ]),

          const SizedBox(height: 24),

          // ── v115 (Feature E): Moderationsqueue ──────────────────────
          _SectionLabel('Moderation', Icons.gpp_maybe_rounded, widget.accent),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => showModalBottomSheet<void>(
              context: context,
              backgroundColor: const Color(0xFF12121E),
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => _ModerationSheet(accent: widget.accent),
            ).then((_) => _load()),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _openReports > 0
                      ? [
                          Colors.red.withValues(alpha: 0.18),
                          Colors.orange.withValues(alpha: 0.10),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.05),
                          Colors.white.withValues(alpha: 0.02),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _openReports > 0
                      ? Colors.redAccent.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (_openReports > 0 ? Colors.redAccent : widget.accent)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.flag_rounded,
                      color:
                          _openReports > 0 ? Colors.redAccent : widget.accent,
                      size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _openReports > 0
                            ? '$_openReports offene Meldung${_openReports == 1 ? '' : 'en'}'
                            : 'Keine offenen Meldungen',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      const Text('User-Reports pruefen + bearbeiten',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white38),
              ]),
            ),
          ),

          const SizedBox(height: 24),

          // ── Quick Actions ──────────────────────────────────────────
          _SectionLabel(
              'Schnellaktionen', Icons.flash_on_rounded, widget.accent),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: _QuickActionBtn(
                icon: Icons.people_rounded,
                label: 'Nutzer verwalten',
                color: const Color(0xFF1E88E5),
                onTap: () {
                  // Navigate to Users tab
                  final scaffold = context
                      .findAncestorStateOfType<_WorldAdminDashboardState>();
                  scaffold?._tabController?.animateTo(1);
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
                  final scaffold = context
                      .findAncestorStateOfType<_WorldAdminDashboardState>();
                  scaffold?._tabController?.animateTo(2);
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
                  final scaffold = context
                      .findAncestorStateOfType<_WorldAdminDashboardState>();
                  scaffold?._tabController?.animateTo(3);
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
          // PHASE-3 FIX: Diagnose-Button -- prueft Worker-Erreichbarkeit,
          // HMAC-Header und Profile-Setup live. Bei 403/Fehler sieht der
          // Admin sofort WAS schiefgelaufen ist statt nur "Keine Nutzer".
          _QuickActionBtn(
            icon: Icons.bug_report_rounded,
            label: 'Diagnose: Worker-Verbindung pruefen',
            color: const Color(0xFF26A69A),
            onTap: () => _runDiagnose(context),
          ),
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
          _SectionLabel('Live-Aktivität (7 Tage)',
              Icons.local_fire_department_rounded, widget.accent),
          const SizedBox(height: 10),
          _ActivityHeatmapBlock(accent: widget.accent),

          const SizedBox(height: 24),

          // ── 🟢 Live-Online-Roster ───────────────────────────────
          _SectionLabel('Aktuell online', Icons.bolt_rounded, widget.accent),
          const SizedBox(height: 10),
          _OnlineNowBlock(
              accent: widget.accent, accentBright: widget.accentBright),

          const SizedBox(height: 24),

          // ── Letzte Aktivitäten ─────────────────────────────────────
          Row(children: [
            Expanded(
                child: _SectionLabel(
                    'Letzte Aktionen', Icons.history_rounded, widget.accent)),
            if (_activity.isNotEmpty)
              GestureDetector(
                onTap: _exportActivityCsv,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: widget.accent.withValues(alpha: 0.35)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.download_rounded,
                        color: widget.accent, size: 14),
                    const SizedBox(width: 6),
                    Text('CSV',
                        style: TextStyle(
                            color: widget.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
          ]),
          const SizedBox(height: 10),

          if (_activity.isEmpty)
            _EmptyHint(
                'Noch keine Admin-Aktionen aufgezeichnet.\nAktionen erscheinen nach Nutzer-Interaktionen.')
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
      {required this.world,
      required this.admin,
      required this.accent,
      required this.accentBright});
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  List<WorldUser> _all = [];
  List<WorldUser> _filtered = [];
  bool _loading = true;
  bool _processing = false;
  String? _errorMessage;
  DateTime? _lastLoadedAt;
  String _search = '';
  String _roleFilter = 'all';
  String _sourceFilter = 'all'; // 'all' | 'web' | 'app'
  String _sortMode = 'role'; // 'role' | 'newest' | 'oldest' | 'az' | 'online'
  bool _hideGhosts = true; // hide auto-generated user_* accounts
  final _searchCtrl = TextEditingController();

  // Bulk-Selection — UserIDs der angehakten User. Bulk-Action-Bar erscheint
  // wenn nicht leer (FAB-ähnlich am unteren Rand).
  final Set<String> _selectedIds = {};

  // Real-time-Subscription auf profiles — Liste aktualisiert sich live wenn
  // ein User promotet/gebannt/gelöscht/erstellt wird (egal welcher Admin).
  RealtimeChannel? _profilesChannel;
  Timer? _realtimeDebounce;

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
    _realtimeDebounce?.cancel();
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
              if (kDebugMode)
                debugPrint('🔄 profiles change → reload (debounced)');
              // AUDIT-FIX B11: Debounce damit ein Schwall von Profile-
              // Aenderungen (z.B. 10 User joinen gleichzeitig) nicht 10
              // Reloads ausloest. 800ms Quiet-Period.
              _realtimeDebounce?.cancel();
              _realtimeDebounce = Timer(const Duration(milliseconds: 800), () {
                if (mounted) _load();
              });
            },
          )
          .subscribe();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Realtime-Subscribe failed: $e');
    }
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }
    try {
      final users = await WorldAdminService.getAllUsers();
      if (mounted) {
        setState(() {
          _all = users;
          _lastLoadedAt = DateTime.now();
          _applyFilter();
          _loading = false;
          if (users.isEmpty) {
            // PHASE-4 FIX: Bei leerer Liste den LETZTEN Worker-Fehler aus
            // dem Diag-Log holen damit der Admin sieht WAS schiefging.
            final lastCall = AdminApiClient.instance.diagLog
                .where((c) => c.path == '/api/admin/users')
                .toList()
                .reversed
                .firstOrNull;
            if (lastCall != null && lastCall.statusCode >= 400) {
              _errorMessage = 'Worker-Fehler: HTTP ${lastCall.statusCode}\n'
                  '${lastCall.message}\n\n'
                  'Tipp: Tap auf "Diagnose" in der Uebersicht fuer Details.';
            } else if (lastCall != null && lastCall.statusCode == 0) {
              _errorMessage = 'Netzwerk-Fehler: ${lastCall.message}\n\n'
                  'Tipp: Internet pruefen + Diagnose-Button in der Uebersicht.';
            } else {
              _errorMessage = 'Keine Nutzer gefunden.\n\n'
                  'Falls das nicht stimmt, tap auf "Diagnose" in der '
                  'Uebersicht um die Worker-Verbindung zu pruefen.';
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        setState(() {
          _loading = false;
          _errorMessage =
              'Laden fehlgeschlagen: ${msg.length > 120 ? '${msg.substring(0, 120)}...' : msg}';
        });
      }
    }
  }

  void _applyFilter() {
    var list = _all;
    if (_hideGhosts) {
      list = list.where((u) => !u.isGhostUser).toList();
    }
    if (_roleFilter == 'banned') {
      list = list.where((u) => u.isSuspended).toList();
    } else if (_roleFilter != 'all') {
      list = list.where((u) => u.role == _roleFilter).toList();
    }
    if (_sourceFilter != 'all') {
      list = list.where((u) => u.source == _sourceFilter).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where((u) =>
              u.username.toLowerCase().contains(q) ||
              (u.displayName ?? '').toLowerCase().contains(q))
          .toList();
    }
    // Sortier-Mode anwenden (nicht-mutativ, Kopie).
    final sortable = [...list];
    switch (_sortMode) {
      case 'newest':
        sortable.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        sortable.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'az':
        sortable.sort((a, b) =>
            a.username.toLowerCase().compareTo(b.username.toLowerCase()));
        break;
      case 'online':
        sortable.sort((a, b) {
          final ad = a.lastSeenAt ?? '';
          final bd = b.lastSeenAt ?? '';
          return bd.compareTo(ad);
        });
        break;
      case 'role':
      default:
        // Default-Sortierung aus dem Service ist bereits Rollen-basiert.
        break;
    }
    _filtered = sortable;
  }

  String _formatRelative(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inSeconds < 60) return 'gerade eben';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'vor ${diff.inHours} h';
    return 'vor ${diff.inDays} Tagen';
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
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17)),
        content: Text(msg,
            style: const TextStyle(
                color: Colors.white70, fontSize: 14, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child:
                const Text('Bestätigen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _ban(WorldUser u) async {
    if (u.username.trim().toLowerCase() ==
        (widget.admin.username ?? '').trim().toLowerCase()) {
      _snack('Du kannst dich nicht selbst sperren.', color: Colors.orange);
      return;
    }
    final result = await _showBanDialog(u.username);
    if (result == null) return;

    setState(() => _processing = true);
    final ok = await WorldAdminServiceV162.banUser(
      userId: u.userId,
      reason: result['reason'] as String,
      expiresAt: result['expiresAt'] as String?,
      adminUserId: widget.admin.username,
    );
    if (!mounted) return;
    setState(() => _processing = false);
    if (ok) {
      final label = result['durationLabel'] as String;
      _snack('🚫 @${u.username} gesperrt ($label)', color: Colors.red.shade700);
      _load();
    } else {
      final errMsg = AdminApiClient.instance.diagLog.isNotEmpty
          ? AdminApiClient.instance.diagLog.last.message
          : 'Unbekannter Fehler';
      _snack('❌ Sperren fehlgeschlagen: $errMsg', color: Colors.orange);
    }
  }

  /// v117: Granulare Bereichs-Sperren -- oeffnet einen Scope-Picker.
  Future<void> _restrict(WorldUser u) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RestrictionSheet(
        user: u,
        accent: widget.accent,
        accentBright: widget.accentBright,
        adminUsername: widget.admin.username ?? '',
        onChanged: _load,
      ),
    );
  }

  /// Shows a dialog to pick ban reason and duration.
  /// Returns {'reason': String, 'expiresAt': String?, 'durationLabel': String}
  /// or null if cancelled.
  Future<Map<String, Object?>?> _showBanDialog(String username) async {
    final reasonCtrl = TextEditingController(text: 'Regelverstoß');
    int selectedIdx = 2; // default: 24h
    const durationLabels = [
      '1 Stunde',
      '6 Stunden',
      '24 Stunden',
      '7 Tage',
      'Permanent'
    ];
    const durationHours = [1, 6, 24, 168, 0]; // 0 = permanent

    return showDialog<Map<String, Object?>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDs) => AlertDialog(
          backgroundColor: const Color(0xFF12121E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.block_rounded,
                  color: Colors.redAccent, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nutzer sperren',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  Text('@$username',
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dauer',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(durationLabels.length, (i) {
                    final sel = selectedIdx == i;
                    final isPerm = durationHours[i] == 0;
                    return GestureDetector(
                      onTap: () => setDs(() => selectedIdx = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: sel
                              ? (isPerm ? Colors.red : Colors.orange)
                                  .withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel
                                ? (isPerm ? Colors.red : Colors.orange)
                                    .withValues(alpha: 0.7)
                                : Colors.white12,
                          ),
                        ),
                        child: Text(
                          durationLabels[i],
                          style: TextStyle(
                            color: sel
                                ? (isPerm
                                    ? Colors.red.shade200
                                    : Colors.orange.shade200)
                                : Colors.white70,
                            fontSize: 12,
                            fontWeight:
                                sel ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: reasonCtrl,
                  maxLength: 200,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Grund (fuer Audit-Log + Push)',
                    labelStyle: const TextStyle(color: Colors.white54),
                    counterStyle:
                        const TextStyle(color: Colors.white24, fontSize: 10),
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
                      borderSide: BorderSide(
                          color: Colors.redAccent.withValues(alpha: 0.6)),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ban wird im Audit-Log protokolliert und an den Nutzer gesendet.',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Abbrechen',
                  style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final reason = reasonCtrl.text.trim().isEmpty
                    ? 'Regelverstoß'
                    : reasonCtrl.text.trim();
                final hours = durationHours[selectedIdx];
                String? expiresAt;
                if (hours > 0) {
                  expiresAt = DateTime.now()
                      .add(Duration(hours: hours))
                      .toUtc()
                      .toIso8601String();
                }
                Navigator.pop<Map<String, Object?>>(ctx, {
                  'reason': reason,
                  'expiresAt': expiresAt,
                  'durationLabel': durationLabels[selectedIdx],
                });
              },
              icon: const Icon(Icons.block_rounded,
                  color: Colors.white, size: 16),
              label:
                  const Text('Sperren', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _unban(WorldUser u) async {
    final confirmed = await _confirm(
      'Sperre aufheben',
      'Soll die Sperre fuer @${u.username} wirklich aufgehoben werden?',
      confirmColor: Colors.teal,
    );
    if (!confirmed) return;

    setState(() => _processing = true);
    final ok = await WorldAdminServiceV162.unbanUser(
        userId: u.userId, adminUserId: widget.admin.username ?? 'admin');
    if (!mounted) return;
    setState(() => _processing = false);
    if (ok) {
      _snack('✅ @${u.username} wurde entsperrt', color: Colors.teal);
      _load();
    } else {
      final errMsg = AdminApiClient.instance.diagLog.isNotEmpty
          ? AdminApiClient.instance.diagLog.last.message
          : 'Unbekannter Fehler';
      _snack('❌ Entsperren fehlgeschlagen: $errMsg', color: Colors.orange);
    }
  }

  // v115 (Feature B): Verwarnung aussprechen. Dialog mit Grund-Feld.
  // Bei der 3. Verwarnung bannt der Worker automatisch fuer 7 Tage.
  Future<void> _warn(WorldUser u) async {
    if (u.username.trim().toLowerCase() ==
        (widget.admin.username ?? '').trim().toLowerCase()) {
      _snack('Du kannst dich nicht selbst verwarnen.', color: Colors.orange);
      return;
    }
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            String? errorText;
            return StatefulBuilder(
              builder: (ctx2, setDs) => AlertDialog(
                backgroundColor: const Color(0xFF12121E),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Row(children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.orangeAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Verwarnen (${u.warningCount}/3)',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ]),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${u.username} verwarnen. Ab der 3. Verwarnung wird der '
                      'Nutzer automatisch fuer 7 Tage gesperrt.',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonCtrl,
                      autofocus: true,
                      maxLength: 200,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Grund (Pflicht, min. 3 Zeichen)',
                        labelStyle: const TextStyle(color: Colors.white54),
                        errorText: errorText,
                        counterStyle: const TextStyle(color: Colors.white38),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx2, false),
                    child: const Text('Abbrechen',
                        style: TextStyle(color: Colors.white54)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (reasonCtrl.text.trim().length < 3) {
                        setDs(() =>
                            errorText = 'Mindestens 3 Zeichen erforderlich');
                        return;
                      }
                      Navigator.pop(ctx2, true);
                    },
                    icon: const Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 16),
                    label: const Text('Verwarnen',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            );
          },
        ) ??
        false;
    if (!confirmed) return;

    setState(() => _processing = true);
    final res = await WorldAdminServiceV162.warnUser(
      userId: u.userId,
      reason: reasonCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _processing = false);
    if (res != null && res['success'] == true) {
      final count = res['warning_count'] ?? 0;
      final autoBanned = res['auto_banned'] == true;
      _snack(
        autoBanned
            ? '🚫 @${u.username}: $count. Verwarnung -> Auto-Ban (7 Tage)'
            : '⚠️ @${u.username} verwarnt ($count/3)',
        color: autoBanned ? Colors.red.shade700 : Colors.orange,
      );
      _load();
    } else {
      final errMsg = AdminApiClient.instance.diagLog.isNotEmpty
          ? AdminApiClient.instance.diagLog.last.message
          : 'Unbekannter Fehler';
      _snack('❌ Verwarnung fehlgeschlagen: $errMsg', color: Colors.orange);
    }
  }

  // v115 (Feature D): CSV-Export der aktuell gefilterten Nutzerliste.
  // Baut einen RFC-4180-konformen CSV-String und kopiert ihn in die
  // Zwischenablage (kein Datei-IO noetig -> funktioniert auf Web + App).
  Future<void> _exportCsv() async {
    final rows = _filtered.isEmpty ? _all : _filtered;
    if (rows.isEmpty) {
      _snack('Keine Nutzer zum Exportieren');
      return;
    }
    String esc(String? v) {
      final s = (v ?? '').replaceAll('"', '""');
      return '"$s"';
    }

    final buf = StringBuffer();
    buf.writeln(
        'username,display_name,role,banned,warnings,source,created_at,last_seen');
    for (final u in rows) {
      buf.writeln([
        esc(u.username),
        esc(u.displayName),
        esc(u.role),
        esc(u.isSuspended ? 'ja' : 'nein'),
        esc('${u.warningCount}'),
        esc(u.source),
        esc(u.createdAt),
        esc(u.lastSeenAt ?? ''),
      ].join(','));
    }
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    if (!mounted) return;
    _snack('📋 ${rows.length} Nutzer als CSV in Zwischenablage kopiert',
        color: Colors.green.shade700);
  }

  // v115 (Feature C): Interne Admin-Notizen. BottomSheet mit Liste +
  // Eingabefeld. Notizen sind NUR fuer Admins sichtbar (RLS-geschuetzt).
  Future<void> _showNotes(WorldUser u) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF12121E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _NotesSheet(
        user: u,
        accent: widget.accent,
      ),
    );
  }

  // v116: Modul-Freischaltungs-Sheet
  Future<void> _showModuleAccess(WorldUser u) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF12121E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ModuleAccessSheet(
        user: u,
        accent: widget.accent,
        adminUsername: widget.admin.username ?? '',
      ),
    );
  }

  // Feiner-granularer Rollenwechsel (v5.44.3+): erlaubt user|moderator|
  // content_editor|admin|root_admin. Promote/Demote bleiben fuer
  // Rueckwaerts-Kompatibilitaet bestehen.
  Future<void> _changeRole(WorldUser u, String newRole) async {
    if (u.role == newRole) {
      _snack('@${u.username} hat bereits diese Rolle');
      return;
    }
    // FIX (#8): Client-seitiger Hierarchie-Pre-Check. Verhindert den
    // Umweg ueber einen Worker-403 (der nur "fehlgeschlagen" zeigte).
    if (!AppRoles.canPromoteToRole(widget.admin.role, newRole)) {
      _snack(
        'Deine Rolle (${_prettyRole(widget.admin.role ?? 'user')}) darf '
        '"${_prettyRole(newRole)}" nicht vergeben.',
        color: Colors.orange,
      );
      return;
    }
    // Selbst-Aenderung blockieren (Worker macht das auch, aber sofort
    // klarere Meldung). Vergleich ueber Username da AdminState keine
    // userId fuehrt.
    final adminName = widget.admin.username?.trim().toLowerCase();
    if (adminName != null &&
        adminName.isNotEmpty &&
        u.username.trim().toLowerCase() == adminName) {
      _snack('Du kannst deine eigene Rolle nicht aendern.',
          color: Colors.orange);
      return;
    }
    final pretty = _prettyRole(newRole);
    final confirmed = await _confirm(
      'Rolle aendern',
      '@${u.username} zu Rolle "$pretty" setzen?\n\nAktuell: ${_prettyRole(u.role)}',
      confirmColor: widget.accent,
    );
    if (!confirmed) return;

    setState(() => _processing = true);
    final ok = await WorldAdminServiceV162.changeUserRole(
      userId: u.userId,
      newRole: newRole,
      adminUsername: widget.admin.username,
    );
    if (!mounted) return;
    setState(() => _processing = false);
    if (ok) {
      _snack('🛡️ @${u.username} ist jetzt $pretty', color: Colors.green);
      _load();
    } else {
      final errMsg = AdminApiClient.instance.diagLog.isNotEmpty
          ? AdminApiClient.instance.diagLog.last.message
          : 'Unbekannter Fehler';
      _snack('❌ Rollenwechsel fehlgeschlagen: $errMsg', color: Colors.orange);
    }
  }

  String _prettyRole(String r) => switch (r) {
        'root_admin' => '👑 Root-Admin',
        'admin' => '🛡️ Admin',
        'content_editor' => '✍️ Content-Editor',
        'moderator' => '🧹 Moderator',
        'user' => '👤 User',
        _ => r,
      };

  Future<void> _demote(WorldUser u) async {
    final confirmed = await _confirm(
      'Degradieren',
      'Soll @${u.username} wirklich degradiert werden?\n\nRolle wird auf "User" zurueckgesetzt.',
      confirmColor: Colors.orange,
    );
    if (!confirmed) return;

    setState(() => _processing = true);
    final ok = await WorldAdminServiceV162.changeUserRole(
      userId: u.userId,
      newRole: 'user',
      adminUsername: widget.admin.username,
    );
    if (!mounted) return;
    setState(() => _processing = false);
    if (ok) {
      _snack('⬇️ @${u.username} degradiert', color: Colors.orange);
      _load();
    } else {
      final errMsg = AdminApiClient.instance.diagLog.isNotEmpty
          ? AdminApiClient.instance.diagLog.last.message
          : 'Unbekannter Fehler';
      _snack('❌ Degradieren fehlgeschlagen: $errMsg', color: Colors.red);
    }
  }

  // v98: Hard-Delete eines Users. Nur Root-Admin. Verlangt Eingabe des
  // exakten Usernames zur Bestaetigung (Fat-Finger-Schutz).
  Future<void> _deleteUser(WorldUser u) async {
    if (!widget.admin.isRootAdmin) return;
    final confirmCtrl = TextEditingController();
    // AUDIT-FIX B13: Reason-Feld bei Hard-Delete fuer Audit-Trail.
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12121E),
        title: const Row(children: [
          Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
          SizedBox(width: 8),
          Text('Hard-Delete', style: TextStyle(color: Colors.white)),
        ]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '@${u.username} wird unwiderruflich geloescht.\n\n'
                'Profile-Zeile + auth.users (falls vorhanden) werden geloescht. '
                'XP, Chat-Eintraege und alle abhaengigen Daten gehen verloren.',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 14),
              const Text(
                'Grund (Pflicht, fuer Audit-Trail):',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: reasonCtrl,
                maxLength: 200,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'z.B. Account-Loeschung auf Wunsch',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: const Color(0xFF1A1A26),
                  counterStyle: const TextStyle(color: Colors.white38),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tippe "${u.username}" zur Bestaetigung:',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: confirmCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: u.username,
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: const Color(0xFF1A1A26),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: Colors.redAccent.withValues(alpha: 0.4)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen',
                  style: TextStyle(color: Colors.white60))),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white),
            icon: const Icon(Icons.delete_forever_rounded, size: 16),
            label: const Text('Endgueltig loeschen'),
            onPressed: () {
              if (reasonCtrl.text.trim().length < 3) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                  content: Text('Grund (min. 3 Zeichen) ist Pflicht.'),
                ));
                return;
              }
              if (confirmCtrl.text.trim() == u.username) {
                Navigator.pop(ctx, true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                  content: Text(
                      'Username stimmt nicht ueberein -- Bestaetigung abgebrochen.'),
                ));
              }
            },
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _processing = true);
    final success = await WorldAdminServiceV162.deleteUser(
      userId: u.userId,
      adminUsername: widget.admin.username,
      reason: reasonCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _processing = false);
    if (success) {
      _snack('🗑️ @${u.username} geloescht', color: Colors.red);
      _load();
    } else {
      final last = AdminApiClient.instance.diagLog
          .where((e) => e.path.contains('/admin/users/'))
          .toList()
          .reversed
          .firstOrNull;
      final errMsg = (last != null && last.message != 'ok')
          ? last.message
          : 'Nutzer nicht gefunden oder Datenbankfehler';
      _snack('❌ Loeschen fehlgeschlagen: $errMsg', color: Colors.orange);
    }
  }

  // v98: Sync-Endpoint -- backfillt fehlende profiles aus auth.users.
  Future<void> _syncUsers() async {
    setState(() => _processing = true);
    final result = await WorldAdminServiceV162.syncUsers();
    if (!mounted) return;
    setState(() => _processing = false);
    if (result == null) {
      _snack('❌ Sync fehlgeschlagen', color: Colors.red);
      return;
    }
    final inserted = result['profiles_inserted'] ?? 0;
    final authSeen = result['auth_users_seen'] ?? 0;
    _snack(
      '🔄 $inserted neue Profile (von $authSeen auth-Usern)',
      color: Colors.green,
    );
    _load();
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFFFC107), Color(0xFFFF9800)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('XP-Vergabe',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
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
                        color: Colors.white54,
                        fontSize: 11,
                        letterSpacing: 1.2)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: presets.map((p) {
                    final sel = selectedPreset == p;
                    final neg = p < 0;
                    return GestureDetector(
                      onTap: () => setDialogState(() {
                        selectedPreset = p;
                        amountCtrl.text = p.toString();
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: sel
                              ? (neg ? Colors.red : const Color(0xFFFFC107))
                                  .withValues(alpha: 0.2)
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
                                ? (neg
                                    ? Colors.red.shade100
                                    : const Color(0xFFFFE082))
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
                  keyboardType:
                      const TextInputType.numberWithOptions(signed: true),
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
                    counterStyle:
                        const TextStyle(color: Colors.white24, fontSize: 10),
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
              child: const Text('Abbrechen',
                  style: TextStyle(color: Colors.white54)),
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
              icon:
                  const Icon(Icons.send_rounded, color: Colors.white, size: 16),
              label:
                  const Text('Vergeben', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
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
    if (!mounted) return;
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
              // User count + Quellen-Aufschluesselung + Refresh-Hint
              if (!_loading) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    // Hauptzahl: X von Y -- klar verstaendlich
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: widget.accent.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _filtered.length == _all.length
                            ? '${_all.length} Nutzer'
                            : '${_filtered.length} von ${_all.length}',
                        style: TextStyle(
                            color: widget.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Quellen-Aufschluesselung
                    Tooltip(
                      message: 'Web-Profile (via Anmeldung)',
                      child: _MiniPill(
                        label:
                            '🌐 ${_all.where((u) => u.source == 'web').length}',
                        color: const Color(0xFF4FC3F7),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'App-Profile (InvisibleAuth)',
                      child: _MiniPill(
                        label:
                            '📱 ${_all.where((u) => u.source == 'app').length}',
                        color: const Color(0xFF81C784),
                      ),
                    ),
                    const Spacer(),
                    if (_lastLoadedAt != null)
                      Text(
                        'Aktualisiert ${_formatRelative(_lastLoadedAt!)}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10),
                      ),
                    const SizedBox(width: 8),
                    // v115 (Feature D): CSV-Export der (gefilterten) Liste.
                    GestureDetector(
                      onTap: _exportCsv,
                      child: Row(children: [
                        const Icon(Icons.download_rounded,
                            color: Colors.white54, size: 14),
                        const SizedBox(width: 3),
                        const Text('Export',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 11)),
                      ]),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _load,
                      child: Row(children: [
                        Icon(Icons.refresh_rounded,
                            color: Colors.white54, size: 14),
                        const SizedBox(width: 3),
                        const Text('Neu laden',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 11)),
                      ]),
                    ),
                  ]),
                ),
                // Fehler-Banner mit Retry, falls Last-Load fehlgeschlagen ist
                if (_errorMessage != null)
                  _ErrorBanner(message: _errorMessage!, onRetry: _load),
              ],
              // Search field
              TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nutzer suchen…',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon:
                      const Icon(Icons.search_rounded, color: Colors.white38),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              color: Colors.white38),
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
                      borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: widget.accent.withValues(alpha: 0.4))),
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
                  children:
                      ['all', 'user', 'admin', 'root_admin', 'banned'].map((r) {
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel
                                ? widget.accent.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: sel ? widget.accent : Colors.transparent,
                                width: 1.5),
                          ),
                          child: Text(labels[r]!,
                              style: TextStyle(
                                  color: sel
                                      ? widget.accentBright
                                      : Colors.white54,
                                  fontSize: 12,
                                  fontWeight: sel
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 6),
              // Ghost-User toggle + Sort-Dropdown
              Row(children: [
                GestureDetector(
                  onTap: () => setState(() {
                    _hideGhosts = !_hideGhosts;
                    _applyFilter();
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _hideGhosts
                          ? Colors.orange.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _hideGhosts
                              ? Colors.orange.withValues(alpha: 0.5)
                              : Colors.transparent,
                          width: 1.5),
                    ),
                    child: Text(
                      _hideGhosts ? '👥 Echte Profile' : '👻 Alle inkl. Ghosts',
                      style: TextStyle(
                          color: _hideGhosts
                              ? Colors.orange.shade200
                              : Colors.white54,
                          fontSize: 11,
                          fontWeight: _hideGhosts
                              ? FontWeight.bold
                              : FontWeight.normal),
                    ),
                  ),
                ),
                const Spacer(),
                // Sort-Dropdown
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortMode,
                      dropdownColor: const Color(0xFF1A1A2E),
                      iconEnabledColor: Colors.white54,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      isDense: true,
                      items: const [
                        DropdownMenuItem(value: 'role', child: Text('↕ Rolle')),
                        DropdownMenuItem(
                            value: 'newest', child: Text('🕒 Neueste')),
                        DropdownMenuItem(
                            value: 'oldest', child: Text('📜 Aelteste')),
                        DropdownMenuItem(value: 'az', child: Text('🔤 A-Z')),
                        DropdownMenuItem(
                            value: 'online', child: Text('🟢 Online zuerst')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _sortMode = v;
                            _applyFilter();
                          });
                        }
                      },
                    ),
                  ),
                ),
              ]),
            ]),
          ),

          // ── Ghost-Bereinigung (root_admin only, nur wenn Ghosts vorhanden) ──
          Builder(builder: (ctx) {
            final ghosts = _all.where((u) => u.isGhostUser).toList();
            if (!widget.admin.isRootAdmin || ghosts.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: GestureDetector(
                onTap: () => _bulkDeleteGhosts(ghosts),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Row(children: [
                    const Icon(Icons.delete_sweep_rounded,
                        color: Colors.redAccent, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      '${ghosts.length} Ghost-Profile bereinigen',
                      style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const Text('(Hard-Delete)',
                        style: TextStyle(color: Colors.red, fontSize: 10)),
                  ]),
                ),
              ),
            );
          }),

          // ── Antrags-Inbox (Reaktivierung/Einspruch/Selbstloesch) ──────
          if (AppRoles.canBanUsers(widget.admin.role))
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: GestureDetector(
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _AccountRequestsSheet(
                    accent: widget.accent,
                    accentBright: widget.accentBright,
                  ),
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: widget.accent.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Row(children: [
                    Icon(Icons.inbox_rounded,
                        color: widget.accentBright, size: 15),
                    const SizedBox(width: 6),
                    Text('Antraege (Reaktivierung / Einspruch / Loeschung)',
                        style: TextStyle(
                            color: widget.accentBright,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    const Icon(Icons.chevron_right,
                        color: Colors.white38, size: 16),
                  ]),
                ),
              ),
            ),

          // ── User List ─────────────────────────────────────────────
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: widget.accent))
                : RefreshIndicator(
                    onRefresh: _load,
                    color: widget.accent,
                    child: _filtered.isEmpty
                        ? ListView(children: [
                            const SizedBox(height: 40),
                            _EmptyHint(
                              _all.isEmpty
                                  ? 'Noch keine Profile geladen.\nZiehe nach unten zum Aktualisieren.'
                                  : 'Keine Treffer bei den aktuellen Filtern.\nLeere Suche oder waehle "Alle".',
                            ),
                          ])
                        : ListView.builder(
                            itemCount: _filtered.length,
                            padding: EdgeInsets.only(
                                top: 4,
                                bottom: _selectedIds.isNotEmpty ? 90 : 16),
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
                                    actorRole: widget.admin.role,
                                    accent: widget.accent,
                                    accentBright: widget.accentBright,
                                    onBan: () => _ban(u),
                                    onUnban: () => _unban(u),
                                    onPromote: () => _changeRole(u, 'admin'),
                                    onDemote: () => _demote(u),
                                    onGrantXp:
                                        AppRoles.canGrantXp(widget.admin.role)
                                            ? () => _grantXp(u)
                                            : null,
                                    onDelete: AppRoles.canDeleteUsers(
                                            widget.admin.role)
                                        ? () => _deleteUser(u)
                                        : null,
                                    onWarn: () => _warn(u),
                                    onNotes: () => _showNotes(u),
                                    onModuleAccess:
                                        AppRoles.canBanUsers(widget.admin.role)
                                            ? () => _showModuleAccess(u)
                                            : null,
                                    onChangeRole: AppRoles.canPromoteDemote(
                                            widget.admin.role)
                                        ? (newRole) => _changeRole(u, newRole)
                                        : null,
                                    onViewDetail: () => _viewDetail(u),
                                    onRestrict:
                                        AppRoles.canBanUsers(widget.admin.role)
                                            ? () => _restrict(u)
                                            : null,
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
            left: 12,
            right: 12,
            bottom: 12,
            child: _BulkActionBar(
              count: _selectedIds.length,
              accent: widget.accent,
              accentBright: widget.accentBright,
              onSelectAll: () => setState(() {
                _selectedIds
                  ..clear()
                  ..addAll(_filtered
                      .map((u) => u.userId)
                      .where((id) => id.isNotEmpty));
              }),
              onPromote: _bulkPromote,
              onDemote: _bulkDemote,
              onBan: _bulkBan,
              onUnban: _bulkUnban,
              onDelete: widget.admin.isRootAdmin ? _bulkDelete : null,
              onClear: () => setState(_selectedIds.clear),
            ),
          ),

        // Processing overlay -- AbsorbPointer blockiert Doppel-Taps
        if (_processing)
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: true,
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: widget.accent),
                        const SizedBox(height: 16),
                        const Text('Wird verarbeitet…',
                            style: TextStyle(color: Colors.white70)),
                      ]),
                ),
              ),
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
    _snack(
        '✅ $success erfolgreich${failed > 0 ? ', $failed fehlgeschlagen' : ''}');
    _load();
  }

  Future<void> _bulkPromote() => _bulkApply(
        label: 'Befoerdern (Bulk)',
        action: (u) async => WorldAdminServiceV162.changeUserRole(
          userId: u.userId,
          newRole: 'admin',
          adminUsername: widget.admin.username,
        ),
      );
  Future<void> _bulkDemote() => _bulkApply(
        label: 'Degradieren (Bulk)',
        action: (u) async => WorldAdminServiceV162.changeUserRole(
          userId: u.userId,
          newRole: 'user',
          adminUsername: widget.admin.username,
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

  // Hard-Delete der aktuell ausgewaehlten Nutzer (root_admin only).
  // Separate Methode statt _bulkApply weil Loeschen destruktiv ist und einen
  // roten Bestaetigungs-Dialog braucht.
  Future<void> _bulkDelete() async {
    if (!widget.admin.isRootAdmin) return;
    final targets = _all.where((u) => _selectedIds.contains(u.userId)).toList();
    if (targets.isEmpty) return;
    final confirmed = await _confirm(
      'Nutzer loeschen',
      '${targets.length} Nutzer werden unwiderruflich geloescht.\n\n'
          'Profil, Fortschritt und alle zugehoerigen Daten gehen verloren.',
      confirmColor: Colors.red,
    );
    if (!confirmed) return;

    setState(() => _processing = true);
    int deleted = 0, failed = 0;
    for (final u in targets) {
      try {
        if (await WorldAdminServiceV162.deleteUser(
          userId: u.userId,
          reason: 'Bulk-Loeschung',
          adminUsername: widget.admin.username,
        )) {
          deleted++;
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
    _snack(
      failed == 0
          ? '🗑️ $deleted Nutzer geloescht'
          : '🗑️ $deleted geloescht, $failed fehlgeschlagen',
      color: deleted > 0 ? Colors.orange : Colors.red,
    );
    _load();
  }

  // Hard-Delete aller uebergebenen Ghost-Profile nach Bestaetigungs-Dialog.
  Future<void> _bulkDeleteGhosts(List<WorldUser> ghosts) async {
    if (!widget.admin.isRootAdmin) return;
    final confirmed = await _confirm(
      'Ghost-Profile loeschen',
      '${ghosts.length} automatisch generierte Profile (user_<ts>) werden '
          'unwiderruflich geloescht.\n\nDiese Nutzer haben sich nie '
          'eingeloggt / kein echtes Profil angelegt.',
      confirmColor: Colors.red,
    );
    if (!confirmed) return;

    setState(() => _processing = true);
    int deleted = 0;
    for (final u in ghosts) {
      final ok = await WorldAdminServiceV162.deleteUser(
        userId: u.userId,
        reason: 'Bulk Ghost-Bereinigung',
        adminUsername: widget.admin.username,
      );
      if (ok) deleted++;
    }
    if (!mounted) return;
    setState(() => _processing = false);
    _snack(
      deleted == ghosts.length
          ? '🗑️ $deleted Ghost-Profile geloescht'
          : '🗑️ $deleted/${ghosts.length} geloescht (${ghosts.length - deleted} Fehler)',
      color: deleted > 0 ? Colors.orange : Colors.red,
    );
    _load();
  }

  Future<void> _viewDetail(WorldUser u) async {
    if (u.isWebOnly) {
      _snack('Noch kein vollstaendiges Profil -- Detail nicht verfuegbar.',
          color: Colors.orange);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserDetailSheet(
        user: u,
        accent: widget.accent,
        accentBright: widget.accentBright,
        isRootAdmin: widget.admin.isRootAdmin,
        adminUsername: widget.admin.username ?? '',
      ),
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
      {required this.world,
      required this.admin,
      required this.accent,
      required this.accentBright});
  @override
  State<_ChatModerationTab> createState() => _ChatModerationTabState();
}

class _ChatModerationTabState extends State<_ChatModerationTab> {
  List<String> _rooms = [];
  String _selectedRoom = '';
  List<Map<String, dynamic>> _messages = [];
  bool _loadingMsgs = false;
  bool _loadingRooms = true;
  bool _autoRefresh = true;
  final _api = CloudflareApiService();
  Timer? _pollTimer;

  // Fallback-Raeume falls DB nicht erreichbar.
  static const List<String> _fallbackRooms = [
    'materie-politik',
    'materie-geschichte',
    'materie-ufo',
    'materie-verschwoerung',
    'materie-wissenschaft',
    'materie-tech',
    'materie-gesundheit',
    'materie-medien',
    'materie-finanzen',
    'energie-meditation',
    'energie-chakra',
    'energie-bewusstsein',
    'energie-heilung',
    'energie-kristalle',
    'energie-astrologie',
    'energie-traumdeutung',
    'vorhang-strategie',
    'vorhang-macht',
    'vorhang-medien',
    'vorhang-geopolitik',
    'ursprung-bewusstsein',
    'ursprung-quanten',
    'ursprung-realitaet',
  ];

  @override
  void initState() {
    super.initState();
    _loadRooms();
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_autoRefresh && _selectedRoom.isNotEmpty) _loadMessages();
    });
  }

  @override
  void didUpdateWidget(covariant _ChatModerationTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.world != widget.world) {
      _loadRooms();
    }
  }

  Future<void> _loadRooms() async {
    if (!mounted) return;
    setState(() => _loadingRooms = true);
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.workerUrl}/api/chat/rooms'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data is List)
            ? data
            : (data is Map ? (data['rooms'] ?? data['data'] ?? []) : []);
        final names = (list as List)
            .map((r) => (r['id'] ?? r['room_id'] ?? r['name'] ?? '').toString())
            .where((s) => s.isNotEmpty)
            .toList();
        if (names.isNotEmpty && mounted) {
          setState(() {
            _rooms = names;
            _selectedRoom = names.first;
            _loadingRooms = false;
          });
          _loadMessages();
          return;
        }
      }
    } catch (_) {}
    // Fallback to hardcoded list
    if (mounted) {
      setState(() {
        _rooms = _fallbackRooms;
        _selectedRoom = _fallbackRooms.first;
        _loadingRooms = false;
      });
      _loadMessages();
    }
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

    if (id.isEmpty) {
      _snack('❌ Keine Nachrichten-ID vorhanden');
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('🗑️ Nachricht löschen',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Von: @$username',
                      style: TextStyle(
                          color: widget.accent, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      content.length > 100
                          ? '${content.substring(0, 100)}…'
                          : content,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                      'Diese Aktion kann nicht rückgängig gemacht werden.',
                      style: TextStyle(color: Colors.white38, fontSize: 12)),
                ]),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Abbrechen',
                    style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.delete_rounded,
                    color: Colors.white, size: 16),
                label: const Text('Löschen',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await _api.deleteChatMessage(
        messageId: id,
        roomId: _selectedRoom,
        userId: (msg['user_id'] ?? msg['userId'] ?? '').toString(),
        username: widget.admin.username ?? 'Weltenbibliothek',
        isAdmin: true,
      );
      _snack('🗑️ Nachricht von $username gelöscht',
          color: Colors.red.shade700);
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

    // AUDIT-FIX B12: Reason-Field statt hardcodedem 'Regelverstoß'
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('🚫 Sender sperren',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Soll @$username für Chat-Verstöße gesperrt werden?\n'
                  'Der Nutzer kann 24 Stunden lang nicht mehr chatten.',
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  autofocus: true,
                  maxLength: 200,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Grund (Pflicht)',
                    labelStyle: TextStyle(color: Colors.white54),
                    counterStyle: TextStyle(color: Colors.white38),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Abbrechen',
                    style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (reasonCtrl.text.trim().length < 3) return;
                  Navigator.pop(context, true);
                },
                icon: const Icon(Icons.block_rounded,
                    color: Colors.white, size: 16),
                label: const Text('Sperren',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    final reason = reasonCtrl.text.trim().isEmpty
        ? 'Chat-Moderation'
        : 'Chat-Moderation: ${reasonCtrl.text.trim()}';
    final ok = await WorldAdminServiceV162.banUser(
        userId: userId, reason: reason, adminUserId: widget.admin.username);
    if (ok) {
      _snack('🚫 @$username gesperrt', color: Colors.red.shade700);
    } else {
      final errMsg = AdminApiClient.instance.diagLog.isNotEmpty
          ? AdminApiClient.instance.diagLog.last.message
          : 'Unbekannter Fehler';
      _snack('❌ Sperren fehlgeschlagen: $errMsg', color: Colors.orange);
    }
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
              style: TextStyle(
                  color: widget.accentBright,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          // Auto-refresh toggle
          Row(children: [
            const Text('Auto',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(width: 4),
            Switch(
              value: _autoRefresh,
              onChanged: (v) => setState(() => _autoRefresh = v),
              activeColor: widget.accent,
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
              child:
                  Icon(Icons.refresh_rounded, color: widget.accent, size: 16),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                decoration: BoxDecoration(
                  color: sel
                      ? widget.accent.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: sel ? widget.accent : Colors.transparent,
                      width: 1.5),
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
                    ? _EmptyHint(
                        'Keine Nachrichten in diesem Raum.\nZiehe nach unten zum Aktualisieren.')
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
  final AdminState admin;
  const _SystemTab(
      {required this.accent, required this.accentBright, required this.admin});
  @override
  State<_SystemTab> createState() => _SystemTabState();
}

class _SystemTabState extends State<_SystemTab> {
  final _health = HealthCheckService();
  bool _ready = false;
  bool _checking = false;

  // App-Config state
  List<Map<String, dynamic>>? _appConfigRows;
  bool _appConfigLoading = false;

  @override
  void initState() {
    super.initState();
    _init();
    // PERF-FIX (#1): Statt Timer.periodic alle 2s (= bis zu 1800 leere
    // Rebuilds/Stunde, Akku-Drain) hoeren wir auf den ChangeNotifier.
    // Rebuild nur wenn sich der Health-Status tatsaechlich aendert.
    _health.addListener(_onHealthChanged);
    if (widget.admin.isRootAdmin) _loadAppConfig();
  }

  void _onHealthChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _init() async {
    await _health.initialize();
    _health.startMonitoring(interval: const Duration(seconds: 30));
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _loadAppConfig() async {
    if (!mounted) return;
    setState(() => _appConfigLoading = true);
    final rows = await WorldAdminServiceV162.getAppConfig();
    if (mounted)
      setState(() {
        _appConfigRows = rows;
        _appConfigLoading = false;
      });
  }

  Future<void> _editAppConfig(Map<String, dynamic> row) async {
    final platform = row['platform'] as String? ?? 'android';
    final latestCtrl =
        TextEditingController(text: row['latest_version'] as String? ?? '');
    final minCtrl =
        TextEditingController(text: row['min_version'] as String? ?? '');
    final urlCtrl =
        TextEditingController(text: row['apk_download_url'] as String? ?? '');
    final changelogCtrl =
        TextEditingController(text: row['changelog'] as String? ?? '');
    final patchCtrl =
        TextEditingController(text: row['patch_changelog'] as String? ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12121E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.system_update_rounded, color: widget.accent, size: 20),
          const SizedBox(width: 8),
          Text('App-Config ($platform)',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildConfigField(latestCtrl, 'Aktuelle Version (latest_version)',
                  '1.0.0', Icons.new_releases_rounded),
              const SizedBox(height: 10),
              _buildConfigField(minCtrl, 'Mindestversion (min_version)',
                  '0.9.0', Icons.block_rounded),
              const SizedBox(height: 10),
              _buildConfigField(urlCtrl, 'APK-Download-URL', 'https://',
                  Icons.download_rounded),
              const SizedBox(height: 10),
              _buildConfigField(changelogCtrl, 'Changelog (Release)',
                  'Was ist neu?', Icons.notes_rounded,
                  maxLines: 4),
              const SizedBox(height: 10),
              _buildConfigField(patchCtrl, 'Patch-Changelog (OTA)',
                  'Bugfixes...', Icons.auto_fix_high_rounded,
                  maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: widget.accent),
            child:
                const Text('Speichern', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) return;

    setState(() => _appConfigLoading = true);
    final ok = await WorldAdminServiceV162.updateAppConfig(
      platform: platform,
      updates: {
        'latest_version': latestCtrl.text.trim(),
        'min_version': minCtrl.text.trim(),
        'apk_download_url': urlCtrl.text.trim(),
        'changelog': changelogCtrl.text.trim(),
        'patch_changelog': patchCtrl.text.trim(),
      },
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? '✅ app_config ($platform) gespeichert'
          : '❌ Speichern fehlgeschlagen'),
      backgroundColor: ok ? Colors.green : Colors.orange,
    ));
    _loadAppConfig();
  }

  Widget _buildConfigField(
      TextEditingController ctrl, String label, String hint, IconData icon,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: Colors.white38, size: 16),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
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
    _health.removeListener(_onHealthChanged);
    _health.stopMonitoring();
    super.dispose();
  }

  // FIX (#2): Metric-Cards hatten leere onTap-Handler (tote Buttons).
  // Jetzt zeigen sie eine kurze Erklaerung der jeweiligen Metrik.
  void _explainMetric(String title, String body) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12121E),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(body,
            style: const TextStyle(color: Colors.white70, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Verstanden'),
          ),
        ],
      ),
    );
  }

  Color _latencyColor(double ms) {
    if (ms < 300) return Colors.green;
    if (ms < 800) return Colors.orange;
    return Colors.red;
  }

  Color _statusColor(HealthStatus s) {
    switch (s) {
      case HealthStatus.healthy:
        return Colors.green;
      case HealthStatus.degraded:
        return Colors.orange;
      case HealthStatus.unhealthy:
        return Colors.red;
      case HealthStatus.unknown:
        return Colors.grey;
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

    final overallColor = anyUnhealthy
        ? Colors.red
        : allOk
            ? Colors.green
            : Colors.orange;
    final overallLabel = anyUnhealthy
        ? 'Probleme erkannt'
        : allOk
            ? 'Alle Systeme OK'
            : 'Eingeschränkt';
    final overallIcon = anyUnhealthy
        ? Icons.error_rounded
        : allOk
            ? Icons.check_circle_rounded
            : Icons.warning_amber_rounded;

    final uptime = _calcUptime();
    final errRate = _health.errorRate;
    final avgLatency = _health.averageLatency;

    return RefreshIndicator(
      onRefresh: _checkAll,
      color: widget.accent,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionLabel(
              'System-Status', Icons.monitor_heart_rounded, widget.accent),
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
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: overallColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(overallIcon, color: overallColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(overallLabel,
                            style: TextStyle(
                                color: overallColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        Text(
                            '${svcs.length} Dienste überwacht · Tippen zum Prüfen',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                      ]),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: overallColor.withValues(alpha: 0.6), size: 14),
              ]),
            ),
          ),

          const SizedBox(height: 20),

          // ── Metriken ──────────────────────────────────────────────
          _SectionLabel('Metriken', Icons.speed_rounded, widget.accent),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: _ClickableMetricCard(
                    label: 'Ø Latenz',
                    value: '${avgLatency.round()} ms',
                    icon: Icons.timer_rounded,
                    color: _latencyColor(avgLatency),
                    onTap: () => _explainMetric(
                        'Ø Latenz',
                        'Durchschnittliche Antwortzeit aller ueberwachten '
                            'Dienste. Unter 300 ms = sehr gut, ueber 800 ms '
                            '= langsam.'))),
            const SizedBox(width: 10),
            Expanded(
                child: _ClickableMetricCard(
                    label: 'Fehlerrate',
                    value: '${errRate.toStringAsFixed(1)} %',
                    icon: Icons.error_outline_rounded,
                    color: errRate > 10 ? Colors.red : Colors.green,
                    onTap: () => _explainMetric(
                        'Fehlerrate',
                        'Anteil der Dienste die aktuell nicht erreichbar '
                            'sind. 0 % = alle gesund.'))),
            const SizedBox(width: 10),
            Expanded(
                child: _ClickableMetricCard(
                    label: 'Uptime',
                    value: '${uptime.toStringAsFixed(0)} %',
                    icon: Icons.power_rounded,
                    color: uptime > 95 ? Colors.green : Colors.orange,
                    onTap: () => _explainMetric(
                        'Uptime',
                        'Anteil der erfolgreichen Health-Checks seit App-'
                            'Start. Ueber 95 % = stabil.'))),
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        title: Text(e.key,
                            style: TextStyle(
                                color: widget.accentBright,
                                fontWeight: FontWeight.bold)),
                        content:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          _InfoRow2(Icons.speed_rounded,
                              'Latenz: ${e.value.latencyMs} ms'),
                          const SizedBox(height: 6),
                          _InfoRow2(
                              Icons.circle, 'Status: ${e.value.statusText}'),
                        ]),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('OK',
                                style: TextStyle(color: widget.accent)),
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
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.refresh_rounded, color: Colors.white),
              label: Text(_checking ? 'Prüfe…' : 'Jetzt prüfen',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── App-Update-Konfiguration (nur root_admin) ─────────────
          if (widget.admin.isRootAdmin) ...[
            _SectionLabel('App-Update-Konfiguration',
                Icons.system_update_rounded, widget.accent),
            const SizedBox(height: 10),
            if (_appConfigLoading)
              const Center(child: CircularProgressIndicator())
            else if (_appConfigRows == null)
              _EmptyHint(
                  'Fehler beim Laden. Zum Aktualisieren nach unten ziehen.')
            else if (_appConfigRows!.isEmpty)
              _EmptyHint(
                  'Keine app_config-Eintraege gefunden.\nTabelle evtl. leer.')
            else
              ..._appConfigRows!.map((row) {
                final platform = row['platform'] as String? ?? '?';
                final latest = row['latest_version'] as String? ?? '-';
                final minV = row['min_version'] as String? ?? '-';
                final url =
                    (row['apk_download_url'] as String? ?? '').isNotEmpty;
                return GestureDetector(
                  onTap: () => _editAppConfig(row),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: widget.accent.withValues(alpha: 0.25)),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          platform == 'android'
                              ? Icons.android_rounded
                              : Icons.apple_rounded,
                          color: widget.accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              platform.toUpperCase(),
                              style: TextStyle(
                                  color: widget.accentBright,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Aktuell: $latest  |  Min: $minV  |  APK: ${url ? "gesetzt" : "fehlt"}',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.edit_rounded, color: Colors.white38, size: 16),
                    ]),
                  ),
                );
              }),
            const SizedBox(height: 8),
          ],

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
                color: accent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.3)),
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
                style: const TextStyle(
                    color: Colors.white38, fontSize: 14, height: 1.5),
                textAlign: TextAlign.center),
          ]),
        ),
      );
}

// ── Kompakter Toggle-Chip fuer Source-Filter / Sub-Filter ────────────────
class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final Color accentBright;
  final VoidCallback onTap;
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.accentBright,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? accentBright : Colors.white54,
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Wiederverwendbare Mini-Pille fuer Welt/Quelle/Status-Badges ──────────
class _MiniPill extends StatelessWidget {
  final String label;
  final Color color;
  final String? tooltip;
  const _MiniPill({required this.label, required this.color, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
    if (tooltip != null) return Tooltip(message: tooltip!, child: pill);
    return pill;
  }
}

// ── Fehler-Banner mit Retry-Button (User-Tab + Audit-Tab) ────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, height: 1.4),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Erneut'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.85),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 32),
              textStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ]),
      );
}

// ── Klickbare Statistik-Karte ─────────────────────────────────────────────
class _ClickableStatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  final VoidCallback onTap;
  const _ClickableStatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color,
      required this.onTap});

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
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
              Icon(Icons.open_in_new_rounded,
                  color: color.withValues(alpha: 0.4), size: 12),
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
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

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
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600))),
            Icon(Icons.arrow_forward_ios_rounded,
                color: color.withValues(alpha: 0.5), size: 12),
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
    'edit_message': (Icons.edit_rounded, const Color(0xFF1E88E5)),
    'delete_message': (Icons.delete_rounded, const Color(0xFFE53935)),
    'promote': (Icons.arrow_upward_rounded, const Color(0xFF43A047)),
    'demote': (Icons.arrow_downward_rounded, const Color(0xFFFB8C00)),
    'ban': (Icons.block_rounded, const Color(0xFFE53935)),
    'unban': (Icons.check_circle_rounded, const Color(0xFF00ACC1)),
  };

  static const _labels = {
    'edit_message': 'Nachricht bearbeitet',
    'delete_message': 'Nachricht gelöscht',
    'promote': 'Zum Admin befördert',
    'demote': 'Degradiert',
    'ban': 'Nutzer gesperrt',
    'unban': 'Sperre aufgehoben',
  };

  @override
  Widget build(BuildContext context) {
    final key = entry.action.toLowerCase();
    final iconData = _icons[key]?.$1 ?? Icons.info_outline_rounded;
    final color = _icons[key]?.$2 ?? Colors.grey;
    final label = _labels[key] ?? entry.action;
    final ts = _fmt(entry.timestamp);

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
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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

// ── v115 (Feature C): Admin-Notizen-Sheet ────────────────────────────────
class _NotesSheet extends StatefulWidget {
  final WorldUser user;
  final Color accent;
  const _NotesSheet({required this.user, required this.accent});

  @override
  State<_NotesSheet> createState() => _NotesSheetState();
}

class _NotesSheetState extends State<_NotesSheet> {
  List<Map<String, dynamic>> _notes = [];
  bool _loading = true;
  bool _saving = false;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final notes = await WorldAdminServiceV162.getNotes(widget.user.userId);
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    final ok = await WorldAdminServiceV162.addNote(
        userId: widget.user.userId, note: text);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      _ctrl.clear();
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notiz konnte nicht gespeichert werden')),
      );
    }
  }

  Future<void> _delete(String noteId) async {
    final ok = await WorldAdminServiceV162.deleteNote(
        userId: widget.user.userId, noteId: noteId);
    if (!mounted) return;
    if (ok) _load();
  }

  String _fmt(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return ts;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.sticky_note_2_rounded,
                  color: Color(0xFF9575CD), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Notizen zu @${widget.user.username}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white54),
              ),
            ]),
            const Text('Nur fuer Admins sichtbar -- der Nutzer sieht das nie.',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 12),
            Flexible(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : _notes.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text('Noch keine Notizen.',
                              style: TextStyle(color: Colors.white38)),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _notes.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final n = _notes[i];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.08)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(n['note']?.toString() ?? '',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 13)),
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    Expanded(
                                      child: Text(
                                        '${n['author_username'] ?? 'admin'} · ${_fmt(n['created_at']?.toString() ?? '')}',
                                        style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 10),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () =>
                                          _delete(n['id']?.toString() ?? ''),
                                      child: const Icon(Icons.delete_outline,
                                          size: 16, color: Colors.white38),
                                    ),
                                  ]),
                                ],
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  maxLength: 1000,
                  minLines: 1,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Neue Notiz...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _saving ? null : _add,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send_rounded, color: Color(0xFF9575CD)),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── v115 (Feature E): Moderationsqueue-Sheet ─────────────────────────────
class _ModerationSheet extends StatefulWidget {
  final Color accent;
  const _ModerationSheet({required this.accent});

  @override
  State<_ModerationSheet> createState() => _ModerationSheetState();
}

class _ModerationSheetState extends State<_ModerationSheet> {
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;
  String _statusFilter = 'open';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await WorldAdminServiceV162.getReports(
        status: _statusFilter, limit: 100);
    if (!mounted) return;
    setState(() {
      _reports = data == null
          ? []
          : ((data['reports'] as List?) ?? const [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
      _loading = false;
    });
  }

  Future<void> _resolve(String id, String status) async {
    final ok =
        await WorldAdminServiceV162.updateReport(reportId: id, status: status);
    if (!mounted) return;
    if (ok) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktion fehlgeschlagen')),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.flag_rounded, color: Colors.redAccent, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Moderationsqueue',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: Colors.white54),
            ),
          ]),
          const SizedBox(height: 8),
          // Status-Filter
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final s in const [
                  ('open', 'Offen'),
                  ('reviewing', 'In Pruefung'),
                  ('resolved', 'Erledigt'),
                  ('dismissed', 'Verworfen'),
                  ('all', 'Alle'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(s.$2, style: const TextStyle(fontSize: 11)),
                      selected: _statusFilter == s.$1,
                      onSelected: (_) {
                        setState(() => _statusFilter = s.$1);
                        _load();
                      },
                      selectedColor: widget.accent,
                      backgroundColor: const Color(0xFF1A1A26),
                      labelStyle: TextStyle(
                        color: _statusFilter == s.$1
                            ? Colors.white
                            : Colors.white70,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : _reports.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text('Keine Meldungen in dieser Kategorie.',
                              style: TextStyle(color: Colors.white38)),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _reports.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final r = _reports[i];
                          final id = r['id']?.toString() ?? '';
                          final type = r['type']?.toString() ?? 'report';
                          final title =
                              r['title']?.toString() ?? '(ohne Titel)';
                          final body = r['body']?.toString() ?? '';
                          final reporter = r['username']?.toString() ?? '?';
                          final status = r['status']?.toString() ?? 'open';
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  _MiniPill(
                                    label: type,
                                    color: widget.accent,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(title,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ]),
                                if (body.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(body,
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 12),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  'von @$reporter · ${_fmt(r['created_at']?.toString() ?? '')}',
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 10),
                                ),
                                if (status == 'open' ||
                                    status == 'reviewing') ...[
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    _ActionBtn(
                                        Icons.check_circle_rounded,
                                        'Erledigt',
                                        Colors.green,
                                        () => _resolve(id, 'resolved')),
                                    const SizedBox(width: 8),
                                    _ActionBtn(
                                        Icons.cancel_rounded,
                                        'Verwerfen',
                                        Colors.white38,
                                        () => _resolve(id, 'dismissed')),
                                  ]),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Modul-Zugangs-Sheet (v116) ────────────────────────────────────────────
// Zeigt alle Vorhang- und Ursprung-Module fuer einen User mit den aktuellen
// Admin-Overrides. Admins koennen einzelne Module freischalten (Force-Unlock)
// oder sperren (Force-Block), unabhaengig vom normalen Prerequisite-System.
class _ModuleAccessSheet extends StatefulWidget {
  final WorldUser user;
  final Color accent;
  final String adminUsername;
  const _ModuleAccessSheet({
    required this.user,
    required this.accent,
    required this.adminUsername,
  });
  @override
  State<_ModuleAccessSheet> createState() => _ModuleAccessSheetState();
}

class _ModuleAccessSheetState extends State<_ModuleAccessSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _loading = true;

  // Alle Module aus DB (map: module_code -> row)
  List<Map<String, dynamic>> _vorhangModules = [];
  List<Map<String, dynamic>> _ursprungModules = [];

  // Admin-Overrides (map: module_code -> is_granted bool)
  final Map<String, bool> _overrides = {};

  // Laufende Aktionen
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final supa = Supabase.instance.client;

    // Module + aktuelle Overrides parallel laden
    final vorhangFuture = supa
        .from('vorhang_modules')
        .select('module_code,branch,title,is_boss_module,prerequisites')
        .order('module_code', ascending: true);
    final ursprungFuture = supa
        .from('ursprung_modules')
        .select('module_code,branch,title,is_boss_module,prerequisites')
        .order('module_code', ascending: true);
    final overrideFuture =
        WorldAdminServiceV162.getModuleAccess(widget.user.userId);

    final vorhangRaw =
        ((await vorhangFuture) as List).cast<Map<String, dynamic>>();
    final ursprungRaw =
        ((await ursprungFuture) as List).cast<Map<String, dynamic>>();
    final overrideList = await overrideFuture;

    if (!mounted) return;

    final overrides = <String, bool>{};
    for (final o in overrideList) {
      final code = o['module_code'] as String?;
      final granted = o['is_granted'] as bool?;
      if (code != null && granted != null) overrides[code] = granted;
    }

    setState(() {
      _vorhangModules = vorhangRaw;
      _ursprungModules = ursprungRaw;
      _overrides
        ..clear()
        ..addAll(overrides);
      _loading = false;
    });
  }

  Future<void> _setAccess(
      String moduleCode, String moduleType, bool isGranted) async {
    setState(() => _busy.add(moduleCode));
    final ok = await WorldAdminServiceV162.setModuleAccess(
      userId: widget.user.userId,
      moduleCode: moduleCode,
      moduleType: moduleType,
      isGranted: isGranted,
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _overrides[moduleCode] = isGranted);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktion fehlgeschlagen')),
      );
    }
    setState(() => _busy.remove(moduleCode));
  }

  Future<void> _removeAccess(String moduleCode) async {
    setState(() => _busy.add(moduleCode));
    final ok = await WorldAdminServiceV162.removeModuleAccess(
      userId: widget.user.userId,
      moduleCode: moduleCode,
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _overrides.remove(moduleCode));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktion fehlgeschlagen')),
      );
    }
    setState(() => _busy.remove(moduleCode));
  }

  Widget _buildModuleList(
      List<Map<String, dynamic>> modules, String moduleType) {
    if (modules.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Keine Module gefunden',
              style: TextStyle(color: Colors.white38)),
        ),
      );
    }

    // Module nach Branch gruppieren
    final byBranch = <String, List<Map<String, dynamic>>>{};
    for (final m in modules) {
      final branch = (m['branch'] as String?) ?? 'Weitere';
      byBranch.putIfAbsent(branch, () => []).add(m);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (final entry in byBranch.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Text(
              entry.key,
              style: TextStyle(
                color: widget.accent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
          for (final m in entry.value) _buildModuleRow(m, moduleType),
        ],
      ],
    );
  }

  Widget _buildModuleRow(Map<String, dynamic> m, String moduleType) {
    final code = m['module_code'] as String;
    final title = m['title'] as String? ?? code;
    final isBoss = m['is_boss_module'] as bool? ?? false;
    final prereqs = (m['prerequisites'] as List?)?.cast<String>() ?? [];
    final override = _overrides[code]; // null = kein Override
    final isBusy = _busy.contains(code);

    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    if (override == true) {
      statusColor = Colors.green;
      statusLabel = 'Freigeschaltet';
      statusIcon = Icons.lock_open_rounded;
    } else if (override == false) {
      statusColor = Colors.red;
      statusLabel = 'Gesperrt';
      statusIcon = Icons.lock_rounded;
    } else {
      statusColor = Colors.white24;
      statusLabel = prereqs.isEmpty ? 'Immer offen' : 'Voraussetzungen';
      statusIcon = Icons.hdr_auto_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: override == null
              ? Colors.white10
              : (override ? Colors.green : Colors.red).withValues(alpha: 0.35),
        ),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isBoss
                ? Colors.amber.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isBoss ? Colors.amber.withValues(alpha: 0.4) : Colors.white10,
            ),
          ),
          child: Center(
            child: Text(
              isBoss ? '⭐' : code.split('-').last,
              style: TextStyle(
                fontSize: isBoss ? 14 : 10,
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(children: [
          Icon(statusIcon, size: 10, color: statusColor),
          const SizedBox(width: 4),
          Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10)),
        ]),
        trailing: isBusy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white38))
            : PopupMenuButton<String>(
                color: const Color(0xFF1A1A30),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tooltip: 'Zugang steuern',
                itemBuilder: (_) => [
                  if (override != true)
                    PopupMenuItem(
                      value: 'grant',
                      child: Row(children: [
                        const Icon(Icons.lock_open_rounded,
                            size: 14, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text('Freischalten',
                            style:
                                TextStyle(color: Colors.white, fontSize: 13)),
                      ]),
                    ),
                  if (override != false)
                    PopupMenuItem(
                      value: 'block',
                      child: Row(children: [
                        const Icon(Icons.lock_rounded,
                            size: 14, color: Colors.red),
                        const SizedBox(width: 8),
                        const Text('Sperren',
                            style:
                                TextStyle(color: Colors.white, fontSize: 13)),
                      ]),
                    ),
                  if (override != null)
                    PopupMenuItem(
                      value: 'reset',
                      child: Row(children: [
                        const Icon(Icons.restart_alt_rounded,
                            size: 14, color: Colors.white54),
                        const SizedBox(width: 8),
                        const Text('Zuruecksetzen (Standard)',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 13)),
                      ]),
                    ),
                ],
                onSelected: (action) {
                  if (action == 'grant') {
                    _setAccess(code, moduleType, true);
                  } else if (action == 'block') {
                    _setAccess(code, moduleType, false);
                  } else if (action == 'reset') {
                    _removeAccess(code);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.more_vert_rounded,
                      size: 14, color: Colors.white54),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final overrideCount = _overrides.length;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF26C6DA).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF26C6DA).withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.school_rounded,
                    color: Color(0xFF26C6DA), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Modul-Zugang',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Text(
                      '@${widget.user.username}'
                      '${overrideCount > 0 ? ' · $overrideCount Override${overrideCount != 1 ? "s" : ""}' : ''}',
                      style: TextStyle(
                          color: widget.accent.withValues(alpha: 0.8),
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (_loading)
                const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white38)),
            ]),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabs,
            indicatorColor: const Color(0xFF26C6DA),
            labelColor: const Color(0xFF26C6DA),
            unselectedLabelColor: Colors.white38,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(
                  text:
                      'Vorhang${_vorhangModules.isNotEmpty ? " (${_vorhangModules.length})" : ""}'),
              Tab(
                  text:
                      'Ursprung${_ursprungModules.isNotEmpty ? " (${_ursprungModules.length})" : ""}'),
            ],
          ),
          const Divider(color: Colors.white10, height: 1),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF26C6DA)))
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _buildModuleList(_vorhangModules, 'vorhang'),
                      _buildModuleList(_ursprungModules, 'ursprung'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Nutzer-Kachel ─────────────────────────────────────────────────────────
class _UserTile extends StatelessWidget {
  final WorldUser user;
  final bool isRootAdmin;
  // v100: Rolle des aktuell eingeloggten Admins. Bestimmt welche Aktionen
  // angezeigt werden (canBan, canDeleteMessages, canPromoteDemote ...).
  final String? actorRole;
  final Color accent, accentBright;
  final VoidCallback onBan, onUnban, onPromote, onDemote;
  final VoidCallback? onGrantXp;
  // v98: Hard-Delete -- nur Root-Admin sieht den Button.
  final VoidCallback? onDelete;
  // v115 Feature B/C: Verwarnen + interne Notizen.
  final VoidCallback? onWarn;
  final VoidCallback? onNotes;
  // v116: Modul-Freischaltung / -Sperre.
  final VoidCallback? onModuleAccess;
  // Additiv (v5.44.3+): feinere Rollen-Auswahl via PopupMenuButton.
  // Bleibt optional, damit andere Caller nicht brechen.
  final void Function(String newRole)? onChangeRole;
  final VoidCallback? onViewDetail;
  // v117: Granulare Bereichs-Sperren.
  final VoidCallback? onRestrict;
  const _UserTile({
    required this.user,
    required this.isRootAdmin,
    this.actorRole,
    required this.accent,
    required this.accentBright,
    required this.onBan,
    required this.onUnban,
    required this.onPromote,
    required this.onDemote,
    this.onGrantXp,
    this.onDelete,
    this.onWarn,
    this.onNotes,
    this.onModuleAccess,
    this.onChangeRole,
    this.onViewDetail,
    this.onRestrict,
  });

  Color get _roleColor => switch (user.role) {
        'root_admin' => Colors.amber,
        'admin' => Colors.blue,
        'content_editor' => Colors.purpleAccent,
        'moderator' => Colors.tealAccent,
        _ => Colors.white38,
      };

  String get _roleLabel => switch (user.role) {
        'root_admin' => '👑 ROOT',
        'admin' => '🛡️ Admin',
        'content_editor' => '✍️ Editor',
        'moderator' => '🧹 Mod',
        _ => '👤 User',
      };

  // Erlaubte Rollen-Ziele abhaengig von Berechtigung. Root-Admin darf zu
  // 'admin' und 'root_admin' setzen; Standard-Admin nur user/moderator/
  // content_editor.
  List<String> get _availableRoles {
    final base = ['user', 'moderator', 'content_editor'];
    if (isRootAdmin) {
      base.addAll(['admin', 'root_admin']);
    }
    return base;
  }

  static String _roleMenuLabel(String r) => switch (r) {
        'root_admin' => '👑 Root-Admin',
        'admin' => '🛡️ Admin',
        'content_editor' => '✍️ Content-Editor',
        'moderator' => '🧹 Moderator',
        'user' => '👤 User',
        _ => r,
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
                      : (user.username.isEmpty
                          ? '?'
                          : user.username[0].toUpperCase()),
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
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
          subtitle: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('@${user.username}',
                  style: TextStyle(
                      color: accent.withValues(alpha: 0.7), fontSize: 11)),
              if (user.world != null)
                _MiniPill(
                  // AUDIT-FIX C7: Symbol + Buchstabe statt nur color/letter
                  // damit Farbenblinde die Welt erkennen.
                  label: user.world == 'materie' ? '🌍 M' : '✨ E',
                  color: user.world == 'materie' ? Colors.orange : Colors.teal,
                  tooltip:
                      user.world == 'materie' ? 'Materie-Welt' : 'Energie-Welt',
                ),
              // 🔑 Herkunfts-Badge: Web (Supabase-Auth) vs. App (InvisibleAuth)
              if (user.isWebOnly)
                const _MiniPill(
                  label: '🌐 Web-Antrag',
                  color: Color(0xFFC9A84C),
                  tooltip: 'Web-Zugang genehmigt, noch kein vollstaendiges '
                      'Profil. User-Aktionen greifen hier nicht.',
                )
              else if (user.source == 'web')
                const _MiniPill(
                  label: '🌐 Web',
                  color: Color(0xFF4FC3F7),
                  tooltip: 'Profil ueber Web-Anmeldung erstellt',
                )
              else if (user.source == 'app')
                const _MiniPill(
                  label: '📱 App',
                  color: Color(0xFF81C784),
                  tooltip: 'Profil ueber die Flutter-App erstellt',
                ),
              // v115: Gesperrt-Badge
              if (user.isSuspended)
                const _MiniPill(
                  label: '🚫 Gesperrt',
                  color: Colors.redAccent,
                  tooltip: 'Dieser Nutzer ist aktuell gesperrt',
                ),
              // v115 (Feature B): Verwarnungs-Badge mit Count
              if (user.warningCount > 0)
                _MiniPill(
                  label: '⚠️ ${user.warningCount}/3',
                  color:
                      user.warningCount >= 3 ? Colors.red : Colors.orangeAccent,
                  tooltip: '${user.warningCount} Verwarnung(en)',
                ),
            ],
          ),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            if (onChangeRole != null && !user.isWebOnly)
              PopupMenuButton<String>(
                tooltip: 'Rolle aendern',
                color: const Color(0xFF12121E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: accent.withValues(alpha: 0.25)),
                ),
                position: PopupMenuPosition.under,
                onSelected: (r) => onChangeRole!(r),
                itemBuilder: (ctx) => _availableRoles.map((r) {
                  final isCurrent = r == user.role;
                  return PopupMenuItem<String>(
                    value: r,
                    enabled: !isCurrent,
                    child: Row(children: [
                      Text(_roleMenuLabel(r),
                          style: TextStyle(
                              color: isCurrent ? Colors.white38 : Colors.white,
                              fontWeight:
                                  isCurrent ? FontWeight.w400 : FontWeight.w600,
                              fontSize: 13)),
                      if (isCurrent) ...[
                        const Spacer(),
                        const Icon(Icons.check_rounded,
                            size: 14, color: Colors.white38),
                      ],
                    ]),
                  );
                }).toList(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _roleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: _roleColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(_roleLabel,
                        style: TextStyle(
                            color: _roleColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 3),
                    Icon(Icons.arrow_drop_down_rounded,
                        size: 14, color: _roleColor),
                  ]),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _roleColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _roleColor.withValues(alpha: 0.3)),
                ),
                child: Text(_roleLabel,
                    style: TextStyle(
                        color: _roleColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more_rounded,
                color: Colors.white38, size: 18),
          ]),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(children: [
                const Divider(color: Colors.white10, height: 16),
                _InfoRow(Icons.access_time_rounded,
                    'Erstellt: ${_fmtDate(user.createdAt)}'),
                const SizedBox(height: 4),
                _InfoRow(Icons.fingerprint_rounded,
                    'ID: ${user.userId.isEmpty ? "Unbekannt" : user.userId}'),
                const SizedBox(height: 12),
                if (user.isWebOnly)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Web-Zugangs-Antrag -- noch kein vollstaendiges Profil erstellt.\nAktionen sind nicht verfuegbar.',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    // v100: Promote/Demote nur fuer Admin+ (canPromoteDemote).
                    if (AppRoles.canPromoteDemote(actorRole) && !user.isAdmin)
                      _ActionBtn(Icons.arrow_upward_rounded, 'Befoerdern',
                          Colors.green, onPromote),
                    if (AppRoles.canPromoteDemote(actorRole) &&
                        user.isAdmin &&
                        !user.isRootAdmin)
                      _ActionBtn(Icons.arrow_downward_rounded, 'Degradieren',
                          Colors.orange, onDemote),
                    // Ban/Unban fuer Moderator+.
                    if (AppRoles.canBanUsers(actorRole))
                      _ActionBtn(
                          Icons.block_rounded, 'Sperren', Colors.red, onBan),
                    if (AppRoles.canBanUsers(actorRole))
                      _ActionBtn(Icons.check_circle_outline_rounded,
                          'Entsperren', Colors.teal, onUnban),
                    // v117: Granulare Bereichs-Sperren (Chat/Live/XP ...).
                    if (onRestrict != null && AppRoles.canBanUsers(actorRole))
                      _ActionBtn(Icons.tune_rounded, 'Bereiche',
                          const Color(0xFFEF6C9A), onRestrict!),
                    // v115 (Feature B): Verwarnen -- Moderator+.
                    if (onWarn != null && AppRoles.canBanUsers(actorRole))
                      _ActionBtn(Icons.warning_amber_rounded, 'Verwarnen',
                          Colors.orangeAccent, onWarn!),
                    // v115 (Feature C): Interne Notizen -- Moderator+.
                    if (onNotes != null && AppRoles.canViewUserList(actorRole))
                      _ActionBtn(Icons.sticky_note_2_rounded, 'Notizen',
                          const Color(0xFF9575CD), onNotes!),
                    if (onModuleAccess != null &&
                        AppRoles.canBanUsers(actorRole))
                      _ActionBtn(Icons.school_rounded, 'Module',
                          const Color(0xFF26C6DA), onModuleAccess!),
                    if (onGrantXp != null)
                      _ActionBtn(Icons.auto_awesome_rounded, 'XP vergeben',
                          const Color(0xFFFFC107), onGrantXp!),
                    if (onViewDetail != null)
                      _ActionBtn(Icons.person_search_rounded, 'Detail',
                          const Color(0xFF42A5F5), onViewDetail!),
                    if (onDelete != null)
                      _ActionBtn(Icons.delete_forever_rounded, 'Loeschen',
                          Colors.redAccent, onDelete!),
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
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w600)),
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
  final VoidCallback? onSelectAll;
  final VoidCallback? onDelete;
  const _BulkActionBar({
    required this.count,
    required this.accent,
    required this.accentBright,
    required this.onPromote,
    required this.onDemote,
    required this.onBan,
    required this.onUnban,
    required this.onClear,
    this.onSelectAll,
    this.onDelete,
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
          border: Border.all(
              color: accentBright.withValues(alpha: 0.45), width: 1.2),
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
                  style: TextStyle(
                      color: accentBright,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            if (onSelectAll != null) ...[
              TextButton.icon(
                onPressed: onSelectAll,
                icon: const Icon(Icons.select_all_rounded,
                    size: 16, color: Colors.white70),
                label: const Text('Alle waehlen',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(0, 28),
                ),
              ),
              const SizedBox(width: 4),
            ],
            _ActionBtn(
                Icons.arrow_upward, 'Befördern', Colors.green, onPromote),
            const SizedBox(width: 6),
            _ActionBtn(
                Icons.arrow_downward, 'Degradieren', Colors.orange, onDemote),
            const SizedBox(width: 6),
            _ActionBtn(Icons.block, 'Bannen', Colors.red, onBan),
            const SizedBox(width: 6),
            _ActionBtn(Icons.lock_open, 'Entbannen', Colors.teal, onUnban),
            if (onDelete != null) ...[
              const SizedBox(width: 6),
              _ActionBtn(
                  Icons.delete_forever, 'Löschen', Colors.redAccent, onDelete!),
            ],
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
      {required this.msg,
      required this.accent,
      required this.accentBright,
      required this.onDelete,
      required this.onBan});

  @override
  Widget build(BuildContext context) {
    final username = (msg['username'] ?? 'Anonym').toString();
    final content = (msg['content'] ?? msg['message'] ?? '').toString();
    final ts = _fmt(msg['created_at'] ?? msg['timestamp'] ?? '');
    final emoji =
        (msg['avatarEmoji'] ?? msg['avatar_emoji'] ?? '👤').toString();

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
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              // FIX (#9): langer Username darf den Timestamp nicht
              // rausdruecken / Overflow verursachen -> Expanded + ellipsis.
              Expanded(
                child: Text(username,
                    style: TextStyle(
                        color: accentBright,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text(ts,
                  style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ]),
            const SizedBox(height: 4),
            Text(content,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13, height: 1.4),
                maxLines: 5,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
        const SizedBox(width: 6),
        Column(children: [
          IconButton(
            icon: const Icon(Icons.delete_rounded,
                color: Colors.redAccent, size: 20),
            tooltip: 'Nachricht löschen',
            onPressed: onDelete,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(height: 4),
          IconButton(
            icon:
                const Icon(Icons.block_rounded, color: Colors.orange, size: 20),
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
    } catch (_) {
      return '';
    }
  }
}

// ── Klickbare Service-Zeile ───────────────────────────────────────────────
class _ClickableServiceRow extends StatelessWidget {
  final String name;
  final ServiceHealth health;
  final Color statusColor;
  final VoidCallback onTap;
  const _ClickableServiceRow(
      {required this.name,
      required this.health,
      required this.statusColor,
      required this.onTap});

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
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: statusColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(name,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${health.latencyMs} ms',
                  style: TextStyle(
                      color: statusColor.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Text(health.statusText,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
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
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      required this.onTap});

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
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
                textAlign: TextAlign.center),
          ]),
        ),
      );
}

// ── Online-Status-Dot am Avatar ────────────────────────────────────
class _OnlineDotState {
  final Color color;
  final String tooltip;
  const _OnlineDotState(this.color, this.tooltip);
}

class _OnlineDot extends StatelessWidget {
  final String? lastSeenAtIso;
  const _OnlineDot({required this.lastSeenAtIso});

  _OnlineDotState _state() {
    if (lastSeenAtIso == null) {
      return _OnlineDotState(Colors.grey.shade700, 'Nie online');
    }
    final t = DateTime.tryParse(lastSeenAtIso!);
    if (t == null) {
      return _OnlineDotState(Colors.grey.shade700, 'Offline');
    }
    final delta = DateTime.now().toUtc().difference(t.toUtc());
    if (delta.inMinutes < 2) {
      return const _OnlineDotState(Color(0xFF4CAF50), 'Online');
    }
    if (delta.inMinutes < 15) {
      return _OnlineDotState(
          const Color(0xFFFFC107), 'Vor ${delta.inMinutes} Min');
    }
    final h = delta.inHours;
    if (h < 24) {
      return _OnlineDotState(Colors.grey.shade500, 'Vor ${h}h');
    }
    return _OnlineDotState(Colors.grey.shade700, 'Vor ${delta.inDays} Tagen');
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
      if (mounted) {
        setState(() {
          _all = users;
          _loading = false;
        });
      }
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
                width: 42,
                height: 4,
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
                  style: TextStyle(
                      color: widget.accentBright,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const Spacer(),
              Text('< $_onlineCutoffMin min: ${online.length}',
                  style:
                      const TextStyle(color: Color(0xFF4CAF50), fontSize: 11)),
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
              Text(
                  'Vor $_onlineCutoffMin–$_recentCutoffMin min · ${recent.length}',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11, letterSpacing: 1)),
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
      worldLabel = 'M';
      worldColor = Colors.orange;
    } else if (u.world == 'energie') {
      worldLabel = 'E';
      worldColor = Colors.teal;
    } else {
      worldLabel = '?';
      worldColor = Colors.white24;
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
            right: -2,
            bottom: -2,
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
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
              Text('@${u.username}',
                  style: TextStyle(
                      color: widget.accent.withValues(alpha: 0.7),
                      fontSize: 10),
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
        child: Center(
            child: CircularProgressIndicator(
                color: widget.accent, strokeWidth: 2)),
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
          border: Border.all(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF4CAF50),
                  boxShadow: [
                    BoxShadow(
                        color: Color(0x884CAF50),
                        blurRadius: 6,
                        spreadRadius: 1),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('${onlineNow.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              const Text('online',
                  style: TextStyle(color: Colors.white60, fontSize: 13)),
              const Spacer(),
              Text('E ${byWorld['energie']}  ·  M ${byWorld['materie']}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  color: Colors.white38, size: 18),
            ]),
            const SizedBox(height: 10),
            if (preview.isEmpty)
              const Text('Niemand aktiv in den letzten 5 Minuten.',
                  style: TextStyle(color: Colors.white54, fontSize: 12))
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: preview.map((u) {
                  final ageMin = _ageMin(u);
                  final initial =
                      u.username.isEmpty ? '?' : u.username[0].toUpperCase();
                  return Tooltip(
                    message:
                        '@${u.username} · ${ageMin == null ? "?" : ageMin < 1 ? "jetzt" : "${ageMin}m"}',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
                            u.avatarEmoji?.isNotEmpty == true
                                ? u.avatarEmoji!
                                : initial,
                            style: const TextStyle(
                                fontSize: 9, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(u.username,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11)),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            if (onlineNow.length > preview.length) ...[
              const SizedBox(height: 6),
              Text(
                  '+${onlineNow.length - preview.length} weitere · Tippen für Liste',
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
          child:
              CircularProgressIndicator(color: widget.accent, strokeWidth: 2),
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
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 0.5),
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
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
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
// ═════════════════════════════════════════════════════════════════════════════
// TAB – CONTENT INSIGHTS (Wrapper · Module + Spirit-Tools)
// ═════════════════════════════════════════════════════════════════════════════
class _ContentInsightsTab extends StatefulWidget {
  final Color accent;
  final Color accentBright;
  const _ContentInsightsTab({required this.accent, required this.accentBright});

  @override
  State<_ContentInsightsTab> createState() => _ContentInsightsTabState();
}

class _ContentInsightsTabState extends State<_ContentInsightsTab>
    with SingleTickerProviderStateMixin {
  late TabController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: const Color(0xFF0D0D1A),
        child: TabBar(
          controller: _ctrl,
          isScrollable: true,
          indicatorColor: widget.accent,
          labelColor: widget.accentBright,
          unselectedLabelColor: Colors.white38,
          labelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(
                icon: Icon(Icons.school_rounded, size: 16),
                text: 'Fortschritt'),
            Tab(icon: Icon(Icons.edit_note_rounded, size: 16), text: 'Editor'),
            Tab(icon: Icon(Icons.report_rounded, size: 16), text: 'Meldungen'),
            Tab(icon: Icon(Icons.article_rounded, size: 16), text: 'Artikel'),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: _ctrl,
          children: [
            _ModuleProgressTab(
                accent: widget.accent, accentBright: widget.accentBright),
            _ModuleEditorTab(
                accent: widget.accent, accentBright: widget.accentBright),
            _PostReportsTab(
                accent: widget.accent, accentBright: widget.accentBright),
            _ArticleManagerTab(
                accent: widget.accent, accentBright: widget.accentBright),
          ],
        ),
      ),
    ]);
  }
}

// =============================================================================
// SUB-TAB – ARTIKEL-MANAGER (Content-Tab)
// =============================================================================
class _ArticleManagerTab extends StatefulWidget {
  final Color accent, accentBright;
  const _ArticleManagerTab({required this.accent, required this.accentBright});
  @override
  State<_ArticleManagerTab> createState() => _ArticleManagerTabState();
}

class _ArticleManagerTabState extends State<_ArticleManagerTab> {
  List<Map<String, dynamic>>? _articles;
  bool _loading = true;
  String _worldFilter = 'all';
  String _statusFilter = 'all';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final rows = await WorldAdminServiceV162.getArticles(
      world: _worldFilter == 'all' ? null : _worldFilter,
      status: _statusFilter,
      limit: 100,
    );
    if (mounted)
      setState(() {
        _articles = rows;
        _loading = false;
      });
  }

  void _snack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color ?? const Color(0xFF1A1A2E),
    ));
  }

  String _fmtDate(dynamic v) {
    if (v == null) return '–';
    try {
      final dt = DateTime.parse(v.toString()).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return '–';
    }
  }

  Future<void> _togglePublished(Map<String, dynamic> article) async {
    final id = article['id'] as String? ?? '';
    if (id.isEmpty) return;
    final cur = article['is_published'] as bool? ?? false;
    final ok = await WorldAdminServiceV162.updateArticle(
      articleId: id,
      fields: {'is_published': !cur},
    );
    _snack(
        ok ? (cur ? 'Artikel depubliziert' : 'Artikel publiziert') : '❌ Fehler',
        color: ok ? Colors.green : Colors.orange);
    if (ok) _load();
  }

  Future<void> _toggleFeatured(Map<String, dynamic> article) async {
    final id = article['id'] as String? ?? '';
    if (id.isEmpty) return;
    final cur = article['is_featured'] as bool? ?? false;
    final ok = await WorldAdminServiceV162.updateArticle(
      articleId: id,
      fields: {'is_featured': !cur},
    );
    _snack(
        ok ? (cur ? 'Featured entfernt' : 'Als Featured markiert') : '❌ Fehler',
        color: ok ? Colors.teal : Colors.orange);
    if (ok) _load();
  }

  Future<void> _editArticle(Map<String, dynamic> article) async {
    final id = article['id'] as String? ?? '';
    if (id.isEmpty) return;
    final titleCtrl =
        TextEditingController(text: article['title'] as String? ?? '');
    final contentCtrl =
        TextEditingController(text: article['content'] as String? ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12121E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.edit_rounded, color: widget.accent, size: 18),
          const SizedBox(width: 8),
          const Expanded(
              child: Text('Artikel bearbeiten',
                  style: TextStyle(color: Colors.white, fontSize: 15))),
        ]),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Titel',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                maxLines: 12,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Content (Markdown)',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white12)),
                ),
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen',
                  style: TextStyle(color: Colors.white54))),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: widget.accent),
              child: const Text('Speichern',
                  style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (saved != true || !mounted) return;
    final ok = await WorldAdminServiceV162.updateArticle(
      articleId: id,
      fields: {
        'title': titleCtrl.text.trim(),
        'content': contentCtrl.text.trim(),
      },
    );
    _snack(ok ? '✅ Artikel gespeichert' : '❌ Speichern fehlgeschlagen',
        color: ok ? Colors.green : Colors.orange);
    if (ok) _load();
  }

  @override
  Widget build(BuildContext context) {
    final articles = _articles ?? [];
    return Column(children: [
      // Filter-Leiste
      Container(
        color: const Color(0xFF0D0D1A),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          // World-Filter
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _worldFilter,
              dropdownColor: const Color(0xFF1A1A2E),
              iconEnabledColor: Colors.white54,
              style: const TextStyle(color: Colors.white, fontSize: 11),
              isDense: true,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Alle Welten')),
                DropdownMenuItem(value: 'materie', child: Text('Materie')),
                DropdownMenuItem(value: 'energie', child: Text('Energie')),
                DropdownMenuItem(value: 'vorhang', child: Text('Vorhang')),
                DropdownMenuItem(value: 'ursprung', child: Text('Ursprung')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _worldFilter = v);
                _load();
              },
            ),
          ),
          const SizedBox(width: 12),
          // Status-Filter
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _statusFilter,
              dropdownColor: const Color(0xFF1A1A2E),
              iconEnabledColor: Colors.white54,
              style: const TextStyle(color: Colors.white, fontSize: 11),
              isDense: true,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Alle')),
                DropdownMenuItem(value: 'published', child: Text('Publiziert')),
                DropdownMenuItem(value: 'unpublished', child: Text('Entwurf')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _statusFilter = v);
                _load();
              },
            ),
          ),
          const Spacer(),
          Text('${articles.length} Artikel',
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: widget.accent, size: 18),
            onPressed: _load,
            tooltip: 'Aktualisieren',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ]),
      ),
      // Liste
      Expanded(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: widget.accent))
            : _articles == null
                ? const _EmptyHint(
                    'Laden fehlgeschlagen. Ziehe zum Aktualisieren.')
                : articles.isEmpty
                    ? const _EmptyHint('Keine Artikel gefunden.')
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: widget.accent,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: articles.length,
                          itemBuilder: (ctx, i) {
                            final a = articles[i];
                            final title = a['title'] as String? ?? '–';
                            final world = a['world'] as String? ?? '–';
                            final author = (a['profiles'] as Map?)?['username']
                                    as String? ??
                                '–';
                            final published =
                                a['is_published'] as bool? ?? false;
                            final featured = a['is_featured'] as bool? ?? false;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF12121E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.06)),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                title: Text(title,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(children: [
                                    _MiniPill(
                                        label: world,
                                        color: widget.accent
                                            .withValues(alpha: 0.8)),
                                    const SizedBox(width: 6),
                                    Text(
                                        '@$author · ${_fmtDate(a['created_at'])}',
                                        style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 10)),
                                  ]),
                                ),
                                trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Featured toggle
                                      IconButton(
                                        icon: Icon(
                                          featured
                                              ? Icons.star_rounded
                                              : Icons.star_border_rounded,
                                          color: featured
                                              ? Colors.amber
                                              : Colors.white24,
                                          size: 18,
                                        ),
                                        tooltip: featured
                                            ? 'Featured entfernen'
                                            : 'Als Featured markieren',
                                        onPressed: () => _toggleFeatured(a),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                            minWidth: 32, minHeight: 32),
                                      ),
                                      // Published toggle
                                      IconButton(
                                        icon: Icon(
                                          published
                                              ? Icons.visibility_rounded
                                              : Icons.visibility_off_rounded,
                                          color: published
                                              ? Colors.green
                                              : Colors.white24,
                                          size: 18,
                                        ),
                                        tooltip: published
                                            ? 'Depublizieren'
                                            : 'Publizieren',
                                        onPressed: () => _togglePublished(a),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                            minWidth: 32, minHeight: 32),
                                      ),
                                      // Edit
                                      IconButton(
                                        icon: const Icon(Icons.edit_rounded,
                                            color: Colors.white38, size: 16),
                                        tooltip: 'Bearbeiten',
                                        onPressed: () => _editArticle(a),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                            minWidth: 32, minHeight: 32),
                                      ),
                                    ]),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SUB-TAB – MODULE-EDITOR (Vorhang + Ursprung Felder bearbeiten)
// ═════════════════════════════════════════════════════════════════════════════
class _ModuleEditorTab extends StatefulWidget {
  final Color accent;
  final Color accentBright;
  const _ModuleEditorTab({required this.accent, required this.accentBright});

  @override
  State<_ModuleEditorTab> createState() => _ModuleEditorTabState();
}

class _ModuleEditorTabState extends State<_ModuleEditorTab> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  String _typeFilter = 'all';
  String _search = '';
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // AUDIT-FIX (Bug-Sweep 2): Admin-Auth-Header anhaengen.
      final headers = await AdminAuthService.instance.headers();
      final res = await http
          .get(Uri.parse('${ApiConfig.workerUrl}/api/admin/progress'),
              headers: headers)
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _data = jsonDecode(res.body) as Map<String, dynamic>;
          _loading = false;
        });
      } else if (mounted) {
        setState(() {
          _error =
              'HTTP ${res.statusCode}: ${res.body.length > 120 ? res.body.substring(0, 120) : res.body}';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Netzwerk: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _openEditor(String moduleType, String moduleCode) async {
    // Volles Modul vom Worker laden
    try {
      final headers = await AdminAuthService.instance.headers();
      final res = await http
          .get(
              Uri.parse(
                  '${ApiConfig.workerUrl}/api/admin/module/$moduleType/$moduleCode'),
              headers: headers)
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (res.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Modul laden: HTTP ${res.statusCode}'),
          backgroundColor: Colors.redAccent,
        ));
        return;
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final module = data['module'] as Map<String, dynamic>?;
      if (module == null) return;
      if (!mounted) return;
      await _showEditorSheet(moduleType, moduleCode, module);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Netzwerk. Bitte erneut versuchen.'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  Future<void> _showEditorSheet(
      String moduleType, String moduleCode, Map<String, dynamic> module) async {
    final title =
        TextEditingController(text: module['title']?.toString() ?? '');
    final subtitle =
        TextEditingController(text: module['subtitle']?.toString() ?? '');
    final theory =
        TextEditingController(text: module['theory_content']?.toString() ?? '');
    final caseStudy =
        TextEditingController(text: module['case_study']?.toString() ?? '');
    final exercise = TextEditingController(
        text: module['exercise_description']?.toString() ?? '');
    final duration = TextEditingController(
        text: '${module['exercise_duration_minutes'] ?? 15}');
    final xp = TextEditingController(text: '${module['xp_reward'] ?? 50}');
    final youtube = TextEditingController(
        text: module['youtube_search_query']?.toString() ?? '');
    final freq = TextEditingController(
        text: module['audio_frequency_hz']?.toString() ?? '');
    // test_questions als formatiertes JSON (Array)
    final testQraw = module['test_questions'];
    final testQJson = testQraw == null
        ? '[]'
        : (testQraw is String
            ? testQraw
            : const JsonEncoder.withIndent('  ').convert(testQraw));
    final testQ = TextEditingController(text: testQJson);

    bool saving = false;

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A18),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            children: [
              Center(
                  child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              )),
              const SizedBox(height: 14),
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(moduleCode,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(moduleType.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          letterSpacing: 1)),
                ),
              ]),
              const SizedBox(height: 14),
              _editorField('Title', title),
              _editorField('Subtitle', subtitle),
              _editorField('Theory Content (Markdown OK)', theory, maxLines: 8),
              _editorField('Case Study', caseStudy, maxLines: 4),
              _editorField('Exercise Description', exercise, maxLines: 5),
              Row(children: [
                Expanded(
                    child: _editorField('Dauer (Min.)', duration,
                        keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(
                    child: _editorField('XP-Reward', xp,
                        keyboardType: TextInputType.number)),
              ]),
              _editorField('YouTube-Suchquery', youtube),
              _editorField('Audio-Frequenz Hz (z.B. 432)', freq,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              _editorField(
                'Test-Fragen (JSON-Array)',
                testQ,
                maxLines: 10,
                hint:
                    '[{"question":"...","options":["A","B","C"],"correct_index":0}]',
              ),
              const SizedBox(height: 22),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: saving ? null : () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Abbrechen'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                            setSheet(() => saving = true);
                            final payload = <String, dynamic>{
                              'title': title.text.trim(),
                              'subtitle': subtitle.text.trim(),
                              'theory_content': theory.text.trim(),
                              'case_study': caseStudy.text.trim(),
                              'exercise_description': exercise.text.trim(),
                              'youtube_search_query': youtube.text.trim(),
                              'admin': 'admin',
                            };
                            final d = int.tryParse(duration.text.trim());
                            if (d != null) {
                              payload['exercise_duration_minutes'] = d;
                            }
                            final x = int.tryParse(xp.text.trim());
                            if (x != null) payload['xp_reward'] = x;
                            final f = double.tryParse(freq.text.trim());
                            if (f != null) payload['audio_frequency_hz'] = f;
                            // test_questions: parse JSON, fallback to raw string
                            final tqRaw = testQ.text.trim();
                            if (tqRaw.isNotEmpty) {
                              try {
                                payload['test_questions'] = jsonDecode(tqRaw);
                              } catch (_) {
                                payload['test_questions'] = tqRaw;
                              }
                            }

                            try {
                              final adminHeaders =
                                  await AdminAuthService.instance.headers();
                              final res = await http
                                  .patch(
                                    Uri.parse(
                                        '${ApiConfig.workerUrl}/api/admin/module/$moduleType/$moduleCode'),
                                    headers: {
                                      'Content-Type': 'application/json',
                                      ...adminHeaders,
                                    },
                                    body: jsonEncode(payload),
                                  )
                                  .timeout(const Duration(seconds: 12));
                              if (!mounted) return;
                              if (res.statusCode == 200) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text('✅ $moduleCode gespeichert'),
                                  backgroundColor: widget.accent,
                                ));
                                _load();
                              } else {
                                setSheet(() => saving = false);
                                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                  content: Text(
                                      '❌ HTTP ${res.statusCode}: ${res.body.length > 100 ? res.body.substring(0, 100) : res.body}'),
                                  backgroundColor: Colors.redAccent,
                                ));
                              }
                            } catch (e) {
                              setSheet(() => saving = false);
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                content:
                                    Text('Netzwerk. Bitte erneut versuchen.'),
                                backgroundColor: Colors.redAccent,
                              ));
                            }
                          },
                    icon: saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded),
                    label: Text(saving ? 'Speichere…' : 'Speichern'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editorField(String label, TextEditingController ctrl,
      {int maxLines = 1, TextInputType? keyboardType, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(
            color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 11),
          isDense: true,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.04),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: widget.accent));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Neu laden')),
          ]),
        ),
      );
    }
    final vorhangModules =
        (((_data?['vorhang'] as Map?)?['modules'] as List?) ?? const [])
            .cast<Map<String, dynamic>>();
    final ursprungModules =
        (((_data?['ursprung'] as Map?)?['modules'] as List?) ?? const [])
            .cast<Map<String, dynamic>>();

    final all = <Map<String, dynamic>>[
      ...vorhangModules.map((m) => {...m, '__type': 'vorhang'}),
      ...ursprungModules.map((m) => {...m, '__type': 'ursprung'}),
    ];

    final filtered = all.where((m) {
      if (_typeFilter != 'all' && m['__type'] != _typeFilter) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final blob =
            '${m['code'] ?? ''} ${m['title'] ?? ''} ${m['branch'] ?? ''}'
                .toLowerCase();
        if (!blob.contains(q)) return false;
      }
      return true;
    }).toList();

    return Column(children: [
      // Filter-Leiste
      Container(
        color: const Color(0xFF0D0D1A),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(children: [
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Suche Code / Title / Branch',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: Colors.white38, size: 18),
              isDense: true,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              suffixIcon: _search.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          color: Colors.white38, size: 16),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _search = '');
                      },
                    ),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 8),
          Row(children: [
            ...['all', 'vorhang', 'ursprung'].map((t) {
              final sel = _typeFilter == t;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _typeFilter = t),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel
                          ? widget.accent.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: sel ? widget.accent : Colors.transparent),
                    ),
                    child: Text(
                        t == 'all'
                            ? 'Alle'
                            : t[0].toUpperCase() + t.substring(1),
                        style: TextStyle(
                          color: sel ? widget.accentBright : Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ),
              );
            }),
            const Spacer(),
            Text('${filtered.length}/${all.length}',
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ]),
        ]),
      ),
      Expanded(
        child: RefreshIndicator(
          color: widget.accent,
          onRefresh: () async => _load(),
          child: filtered.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 60),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Keine Module für diesen Filter.',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 13)),
                    ),
                  ),
                ])
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final m = filtered[i];
                    final type = m['__type'] as String;
                    final code = m['code']?.toString() ?? '';
                    final title = m['title']?.toString() ?? code;
                    final branch = m['branch']?.toString() ?? '';
                    final xpReward = (m['xp_reward'] ?? 0) as int;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _openEditor(type, code),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF12121E),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: type == 'vorhang'
                                      ? Colors.purple.withValues(alpha: 0.2)
                                      : Colors.teal.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(code,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(title,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 1),
                                      Text(branch,
                                          style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 9,
                                              letterSpacing: 0.6),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ]),
                              ),
                              if (xpReward > 0)
                                Text('+$xpReward',
                                    style: const TextStyle(
                                        color: Color(0xFFFFC107),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              const SizedBox(width: 6),
                              const Icon(Icons.edit_rounded,
                                  color: Colors.white38, size: 16),
                            ]),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB – SPIRIT-TOOLS-STATS (aus spirit_readings)
// ═════════════════════════════════════════════════════════════════════════════
class _SpiritStatsTab extends StatefulWidget {
  final Color accent;
  final Color accentBright;
  const _SpiritStatsTab({required this.accent, required this.accentBright});

  @override
  State<_SpiritStatsTab> createState() => _SpiritStatsTabState();
}

class _SpiritStatsTabState extends State<_SpiritStatsTab> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  int _days = 7;

  static const _toolLabels = {
    'numerology': '🔢 Numerologie',
    'chakra': '🔮 Chakra',
    'aura': '✨ Aura',
    'godoracle': '🏛️ Götter-Orakel',
    'mantra': '🕉️ Mantra',
    'iching': '☯️ I-Ging',
    'tarot': '🃏 Tarot',
    'runes': '🪨 Runen',
    'birth_chart': '🌌 Geburtshoroskop',
    'biorhythm': '🌊 Biorhythmus',
    'moon': '🌙 Mondkalender',
    'crystal': '💎 Kristall',
    'akasha': '📖 Akasha',
    'shamanic': '🪶 Schamanen-Reise',
  };

  String _labelFor(String tool) => _toolLabels[tool] ?? tool;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final headers = await AdminAuthService.instance.headers();
      final res = await http
          .get(
              Uri.parse(
                  '${ApiConfig.workerUrl}/api/admin/spirit-stats?days=$_days'),
              headers: headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _data = jsonDecode(res.body) as Map<String, dynamic>;
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error =
                'HTTP ${res.statusCode}: ${res.body.substring(0, res.body.length > 120 ? 120 : res.body.length)}';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Netzwerk: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: widget.accent));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Neu laden'),
              style: ElevatedButton.styleFrom(backgroundColor: widget.accent),
            ),
          ]),
        ),
      );
    }

    final totalReadings = (_data?['total_readings'] ?? 0) as int;
    final totalUsers = (_data?['total_users'] ?? 0) as int;
    final recentReadings = (_data?['recent_readings'] ?? 0) as int;
    final toolsAll = ((_data?['tools_all'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();
    final toolsRecent = ((_data?['tools_recent'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();
    final daily =
        ((_data?['daily'] as List?) ?? const []).cast<Map<String, dynamic>>();

    final maxAllTotal = toolsAll.isEmpty ? 1 : toolsAll.first['total'] as int;
    final maxRecentTotal =
        toolsRecent.isEmpty ? 1 : (toolsRecent.first['total'] as int);
    final maxDaily = daily.fold<int>(
        0, (m, d) => (d['count'] as int) > m ? (d['count'] as int) : m);

    return RefreshIndicator(
      color: widget.accent,
      onRefresh: () async => _load(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Top stats
          Row(children: [
            Expanded(
                child: _MiniMetric('Readings gesamt', '$totalReadings',
                    Icons.auto_awesome_rounded, widget.accent)),
            const SizedBox(width: 10),
            Expanded(
                child: _MiniMetric('Unique User', '$totalUsers',
                    Icons.people_rounded, const Color(0xFF1E88E5))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: _MiniMetric('Letzte $_days Tage', '$recentReadings',
                    Icons.bolt_rounded, const Color(0xFF43A047))),
            const SizedBox(width: 10),
            Expanded(
                child: _MiniMetric('Aktive Tools', '${toolsRecent.length}',
                    Icons.category_rounded, const Color(0xFFFFC107))),
          ]),
          const SizedBox(height: 18),

          // Window-Switch
          Row(children: [
            const Text('Zeitraum:',
                style: TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(width: 10),
            ...[7, 30, 90].map((d) {
              final sel = d == _days;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _days = d);
                    _load();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel
                          ? widget.accent.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: sel ? widget.accent : Colors.transparent),
                    ),
                    child: Text('${d}d',
                        style: TextStyle(
                          color: sel ? widget.accentBright : Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ),
              );
            }),
          ]),
          const SizedBox(height: 16),

          // Sparkline
          _SectionLabel(
              'Readings pro Tag', Icons.show_chart_rounded, widget.accent),
          const SizedBox(height: 8),
          Container(
            height: 80,
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            decoration: BoxDecoration(
              color: const Color(0xFF12121E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: daily.isEmpty
                ? const Center(
                    child: Text('Keine Daten',
                        style: TextStyle(color: Colors.white38)))
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: daily.map((d) {
                      final c = d['count'] as int;
                      final h = maxDaily > 0 ? (c / maxDaily) * 60 : 0.0;
                      return Expanded(
                        child: Tooltip(
                          message: '${d['date']}: $c',
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: h.clamp(2, 60),
                                  decoration: BoxDecoration(
                                    color: widget.accent.withValues(alpha: 0.7),
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(2)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),

          const SizedBox(height: 22),
          _SectionLabel('Top-Tools · Letzte $_days Tage',
              Icons.local_fire_department_rounded, widget.accent),
          const SizedBox(height: 8),
          if (toolsRecent.isEmpty)
            _EmptyHint(
                'In den letzten $_days Tagen wurden keine Readings gespeichert.')
          else
            ...toolsRecent.take(10).map((t) => _SpiritToolBar(
                  label: _labelFor(t['tool'] as String),
                  total: t['total'] as int,
                  users: t['unique_users'] as int,
                  max: maxRecentTotal,
                  accent: widget.accent,
                )),

          const SizedBox(height: 22),
          _SectionLabel('Top-Tools · All-Time', Icons.emoji_events_rounded,
              widget.accent),
          const SizedBox(height: 8),
          if (toolsAll.isEmpty)
            _EmptyHint('Noch keine Readings gespeichert.')
          else
            ...toolsAll.take(15).map((t) => _SpiritToolBar(
                  label: _labelFor(t['tool'] as String),
                  total: t['total'] as int,
                  users: t['unique_users'] as int,
                  max: maxAllTotal,
                  accent: widget.accent,
                )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MiniMetric(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label,
                    style: const TextStyle(color: Colors.white60, fontSize: 10),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      );
}

class _SpiritToolBar extends StatelessWidget {
  final String label;
  final int total;
  final int users;
  final int max;
  final Color accent;
  const _SpiritToolBar({
    required this.label,
    required this.total,
    required this.users,
    required this.max,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = max > 0 ? total / max : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF12121E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
          Text('$total',
              style: TextStyle(
                  color: accent, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('$users user',
                style: const TextStyle(color: Colors.white54, fontSize: 9)),
          ),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.02, 1.0),
            minHeight: 4,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            color: accent,
          ),
        ),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB – MODULE-PROGRESS (Vorhang + Ursprung Completion-Stats)
// ═════════════════════════════════════════════════════════════════════════════
class _ModuleProgressTab extends StatefulWidget {
  final Color accent;
  final Color accentBright;
  const _ModuleProgressTab({required this.accent, required this.accentBright});

  @override
  State<_ModuleProgressTab> createState() => _ModuleProgressTabState();
}

class _ModuleProgressTabState extends State<_ModuleProgressTab>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  late TabController _inner;

  @override
  void initState() {
    super.initState();
    _inner = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _inner.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final headers = await AdminAuthService.instance.headers();
      final res = await http
          .get(Uri.parse('${ApiConfig.workerUrl}/api/admin/progress'),
              headers: headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _data = jsonDecode(res.body) as Map<String, dynamic>;
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error =
                'HTTP ${res.statusCode}: ${res.body.substring(0, res.body.length > 120 ? 120 : res.body.length)}';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Netzwerk: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: widget.accent));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Neu laden'),
              style: ElevatedButton.styleFrom(backgroundColor: widget.accent),
            ),
          ]),
        ),
      );
    }
    final vorhang = (_data?['vorhang'] as Map<String, dynamic>?) ?? const {};
    final ursprung = (_data?['ursprung'] as Map<String, dynamic>?) ?? const {};

    return Column(children: [
      Container(
        color: const Color(0xFF0D0D1A),
        child: TabBar(
          controller: _inner,
          indicatorColor: widget.accent,
          labelColor: widget.accentBright,
          unselectedLabelColor: Colors.white38,
          labelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          tabs: [
            Tab(text: 'Vorhang (${vorhang['total'] ?? 0})'),
            Tab(text: 'Ursprung (${ursprung['total'] ?? 0})'),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: _inner,
          children: [
            _ProgressBranch(
                data: vorhang,
                accent: widget.accent,
                accentBright: widget.accentBright,
                onReload: _load),
            _ProgressBranch(
                data: ursprung,
                accent: widget.accent,
                accentBright: widget.accentBright,
                onReload: _load),
          ],
        ),
      ),
    ]);
  }
}

class _ProgressBranch extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color accent;
  final Color accentBright;
  final VoidCallback onReload;
  const _ProgressBranch({
    required this.data,
    required this.accent,
    required this.accentBright,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final total = data['total'] ?? 0;
    final branches = (data['branches'] as List?) ?? const [];
    final top = (data['top'] as List?) ?? const [];
    final stuck = (data['stuck'] as List?) ?? const [];

    return RefreshIndicator(
      color: accent,
      onRefresh: () async => onReload(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.15),
                  accent.withValues(alpha: 0.05)
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Icon(Icons.school_rounded, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$total Module verfügbar',
                          style: TextStyle(
                              color: accentBright,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      Text(
                          branches.isEmpty
                              ? 'Keine Branches'
                              : branches
                                  .map(
                                      (b) => '${b['branch']} (${b['modules']})')
                                  .join(' · '),
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11)),
                    ]),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Branch-Stats
          _SectionLabel('Branches', Icons.account_tree_rounded, accent),
          const SizedBox(height: 10),
          if (branches.isEmpty)
            _EmptyHint('Keine Branch-Daten.')
          else
            ...branches.map((b) {
              final m = b as Map<String, dynamic>;
              final modules = (m['modules'] ?? 0) as int;
              final started = (m['users_started'] ?? 0) as int;
              final completed = (m['users_completed'] ?? 0) as int;
              final rate =
                  started > 0 ? (completed * 100 / started).round() : 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF12121E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(children: [
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['branch']?.toString().toUpperCase() ?? '?',
                              style: TextStyle(
                                  color: accentBright,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text(
                              '$modules Module · $started gestartet · $completed komplett durch',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11)),
                        ]),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: rate >= 50
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.orange.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: (rate >= 50 ? Colors.green : Colors.orange)
                              .withValues(alpha: 0.5)),
                    ),
                    child: Text('$rate%',
                        style: TextStyle(
                          color: rate >= 50
                              ? Colors.green.shade300
                              : Colors.orange.shade300,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        )),
                  ),
                ]),
              );
            }),

          const SizedBox(height: 22),
          _SectionLabel('Top-Module · höchste Completion-Rate',
              Icons.trending_up_rounded, accent),
          const SizedBox(height: 10),
          if (top.isEmpty)
            _EmptyHint('Noch nicht genug Daten (≥3 Starter pro Modul nötig).')
          else
            ...top.map<Widget>((m) => _ModuleStatTile(
                  m: m as Map<String, dynamic>,
                  accent: accent,
                  goodColor: Colors.green,
                )),

          const SizedBox(height: 22),
          _SectionLabel('Hängen-bleiben · niedrigste Completion-Rate',
              Icons.trending_down_rounded, accent),
          const SizedBox(height: 10),
          if (stuck.isEmpty)
            _EmptyHint('Keine kritischen Module gefunden.')
          else
            ...stuck.map<Widget>((m) => _ModuleStatTile(
                  m: m as Map<String, dynamic>,
                  accent: accent,
                  goodColor: Colors.orange,
                )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ModuleStatTile extends StatelessWidget {
  final Map<String, dynamic> m;
  final Color accent;
  final MaterialColor goodColor;
  const _ModuleStatTile(
      {required this.m, required this.accent, required this.goodColor});

  @override
  Widget build(BuildContext context) {
    final code = m['code']?.toString() ?? '';
    final title = m['title']?.toString() ?? code;
    final branch = m['branch']?.toString() ?? '';
    final started = (m['users_started'] ?? 0) as int;
    final completed = (m['users_completed'] ?? 0) as int;
    final rate = (m['completion_rate'] ?? 0) as int;
    final xpReward = (m['xp_reward'] ?? 0) as int;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF12121E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(code,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(branch,
                style: const TextStyle(
                    color: Colors.white60, fontSize: 9, letterSpacing: 1)),
          ),
          const Spacer(),
          if (xpReward > 0)
            Text('+$xpReward XP',
                style: const TextStyle(
                    color: Color(0xFFFFC107),
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 6),
        Text(title,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$completed/$started',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
              const Text('komplett/gestartet',
                  style: TextStyle(color: Colors.white38, fontSize: 9)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: goodColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: goodColor.withValues(alpha: 0.5)),
            ),
            child: Text('$rate%',
                style: TextStyle(
                    color: goodColor.shade300,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        ]),
      ]),
    );
  }
}

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

  // Direct push to single user
  final _directUsername = TextEditingController();
  final _directTitle = TextEditingController();
  final _directBody = TextEditingController();
  bool _sendingDirect = false;

  // Push delivery stats
  Map<String, dynamic>? _pushStats;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _loadingStats = true);
    final stats = await WorldAdminServiceV162.getPushStats();
    if (mounted)
      setState(() {
        _pushStats = stats;
        _loadingStats = false;
      });
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _deeplink.dispose();
    _directUsername.dispose();
    _directTitle.dispose();
    _directBody.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final headers = await AdminAuthService.instance.headers();
      final res = await http
          .get(
            Uri.parse('${ApiConfig.workerUrl}/api/admin/push/history'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));
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

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Verlauf leeren',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
            'Alle gesendeten Broadcasts aus dem Verlauf loeschen?\nDie Nachrichten wurden bereits zugestellt.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leeren', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final adminHeaders = await AdminAuthService.instance.headers();
      final res = await http
          .delete(
            Uri.parse('${ApiConfig.workerUrl}/api/admin/push/history'),
            headers: adminHeaders,
          )
          .timeout(const Duration(seconds: 15));
      if (mounted) {
        if (res.statusCode == 200) {
          setState(() => _history = []);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Verlauf geleert'),
            backgroundColor: widget.accent,
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Fehler ${res.statusCode}'),
            backgroundColor: Colors.redAccent,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Netzwerkfehler'),
          backgroundColor: Colors.redAccent,
        ));
      }
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
      final adminHeaders = await AdminAuthService.instance.headers();
      final res = await http
          .post(
            Uri.parse('${ApiConfig.workerUrl}/api/admin/push/broadcast'),
            headers: {
              'Content-Type': 'application/json',
              ...adminHeaders,
            },
            body: jsonEncode({
              'target': _target,
              'title': _title.text.trim(),
              'body': _body.text.trim(),
              if (_deeplink.text.trim().isNotEmpty)
                'deeplink': _deeplink.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final enq = data['enqueued'] ?? 0;
        // v103 (5.1): Zusaetzlicher Broadcast ueber den neuen Endpoint --
        // schreibt admin_audit_log mit Admin-Username und sendet via
        // sendPushToUser direkt an alle aktiven Subscriptions.
        // Fire-and-forget, blockiert die UI nicht.
        if (_target == 'all') {
          final adminName = StorageService().getMaterieProfile()?.username ??
              StorageService().getEnergieProfile()?.username ??
              supabase.auth.currentUser?.email ??
              'admin';
          PushNotificationHelper.instance
              .sendBroadcast(
                title: _title.text.trim(),
                body: _body.text.trim(),
                adminUsername: adminName,
                data: _deeplink.text.trim().isEmpty
                    ? null
                    : {'deeplink': _deeplink.text.trim()},
              )
              .ignore();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '✅ $enq Empfänger in Queue · Cron sendet via FCM (max 5min)'),
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
          content: Text('Netzwerk. Bitte erneut versuchen.'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendDirect() async {
    final username = _directUsername.text.trim();
    final title = _directTitle.text.trim();
    final body = _directBody.text.trim();
    if (username.isEmpty || title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Username, Titel und Body sind Pflichtfelder'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    setState(() => _sendingDirect = true);
    final ok = await WorldAdminServiceV162.sendDirectPush(
      username: username,
      title: title,
      body: body,
    );
    if (!mounted) return;
    setState(() => _sendingDirect = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? '✅ Push an @$username gesendet'
          : '❌ Fehler: Nutzer nicht gefunden oder Push fehlgeschlagen'),
      backgroundColor: ok ? Colors.green : Colors.redAccent,
    ));
    if (ok) {
      _directTitle.clear();
      _directBody.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _pushStats;
    final totalSent = stats?['total_sent'] as int? ?? 0;
    final totalFailed = stats?['total_failed'] as int? ?? 0;
    final totalPending = stats?['total_pending'] as int? ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Push-Zustellstatistik ─────────────────────────────────
          Row(children: [
            Expanded(
                child: _PushStatCard('Zugestellt', totalSent.toString(),
                    Icons.check_circle_rounded, Colors.green, widget.accent)),
            const SizedBox(width: 8),
            Expanded(
                child: _PushStatCard('Fehlgeschlagen', totalFailed.toString(),
                    Icons.error_rounded, Colors.red, widget.accent)),
            const SizedBox(width: 8),
            Expanded(
                child: _PushStatCard('Ausstehend', totalPending.toString(),
                    Icons.schedule_rounded, Colors.orange, widget.accent)),
          ]),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                widget.accent.withValues(alpha: 0.35),
                widget.accent.withValues(alpha: 0.1)
              ]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.accent.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PUSH BROADCAST',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _field('Empfänger-Zielgruppe', children: [
                  for (final t in [
                    'all',
                    'admins',
                    'active',
                    'materie',
                    'energie',
                    'vorhang',
                    'ursprung'
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(t.toUpperCase(),
                            style: const TextStyle(fontSize: 10)),
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
                  decoration:
                      _inputDeco('Deeplink (optional, z.B. /vorhang/module)'),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send),
                    label: Text(_sending ? 'Sende…' : 'BROADCAST SENDEN',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, letterSpacing: 1.5)),
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

          // ── Direktnachricht an einzelnen Nutzer ───────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: widget.accent.withValues(alpha: 0.25), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.person_pin_rounded,
                      color: widget.accent, size: 18),
                  const SizedBox(width: 8),
                  Text('DIREKTNACHRICHT',
                      style: TextStyle(
                          color: widget.accentBright,
                          fontSize: 11,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 12),
                TextField(
                  controller: _directUsername,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDeco('@Username des Empfaengers'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _directTitle,
                  style: const TextStyle(color: Colors.white),
                  maxLength: 60,
                  decoration: _inputDeco('Titel'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _directBody,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  maxLength: 200,
                  decoration: _inputDeco('Nachricht'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _sendingDirect ? null : _sendDirect,
                    icon: _sendingDirect
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, size: 16),
                    label: Text(_sendingDirect ? 'Sende...' : 'DIREKT SENDEN',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, letterSpacing: 1.2)),
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
            Text('VERLAUF · ${_history.length} Broadcasts',
                style: TextStyle(
                    color: widget.accentBright,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            if (_history.isNotEmpty)
              TextButton.icon(
                onPressed: _clearHistory,
                icon: const Icon(Icons.delete_sweep_rounded, size: 14),
                label: const Text('Leeren', style: TextStyle(fontSize: 11)),
                style:
                    TextButton.styleFrom(foregroundColor: Colors.red.shade300),
              ),
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
                child: Text('Noch keine Broadcasts',
                    style: TextStyle(color: Colors.white60)),
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
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          Text((b['body'] as String?) ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
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
        decoration: BoxDecoration(
            color: c.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8)),
        child: Text('$icon $n',
            style:
                TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)),
      );

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
        isDense: true,
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.4),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        counterStyle: const TextStyle(color: Colors.white38, fontSize: 10),
      );

  Widget _field(String label, {required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: widget.accentBright,
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        SingleChildScrollView(
            scrollDirection: Axis.horizontal, child: Row(children: children)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 📜 AUDIT-LOG TAB
// ═══════════════════════════════════════════════════════════
// ═════════════════════════════════════════════════════════════════════════════
// TAB – AUDIT + REPORTS WRAPPER (zwei Sub-Tabs)
// ═════════════════════════════════════════════════════════════════════════════
class _AuditReportsWrapper extends StatefulWidget {
  final String world;
  final Color accent;
  final Color accentBright;
  final bool isRootAdmin;
  const _AuditReportsWrapper({
    required this.world,
    required this.accent,
    required this.accentBright,
    this.isRootAdmin = false,
  });

  @override
  State<_AuditReportsWrapper> createState() => _AuditReportsWrapperState();
}

class _AuditReportsWrapperState extends State<_AuditReportsWrapper>
    with SingleTickerProviderStateMixin {
  late TabController _ctrl;
  int _openReports = 0;
  int _openUsernameRequests = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = TabController(length: 3, vsync: this);
    _loadReportsCount();
    _loadUsernameRequestsCount();
  }

  Future<void> _loadReportsCount() async {
    try {
      final headers = await AdminAuthService.instance.headers();
      final res = await http
          .get(
              Uri.parse(
                  '${ApiConfig.workerUrl}/api/admin/reports?status=open&limit=1'),
              headers: headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final counts =
            (data['counts'] as Map?)?.cast<String, dynamic>() ?? const {};
        setState(() => _openReports = (counts['open'] as int?) ?? 0);
      }
    } catch (_) {}
  }

  Future<void> _loadUsernameRequestsCount() async {
    try {
      final headers = await AdminAuthService.instance.headers();
      final res = await http
          .get(
              Uri.parse(
                  '${ApiConfig.workerUrl}/api/admin/username-change-requests'),
              headers: headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final total =
            (data['total'] as int?) ?? (data['requests'] as List?)?.length ?? 0;
        setState(() => _openUsernameRequests = total);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: const Color(0xFF0D0D1A),
        child: TabBar(
          controller: _ctrl,
          indicatorColor: widget.accent,
          labelColor: widget.accentBright,
          unselectedLabelColor: Colors.white38,
          labelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          tabs: [
            const Tab(
                icon: Icon(Icons.history_rounded, size: 16), text: 'Audit-Log'),
            Tab(
              icon: Stack(clipBehavior: Clip.none, children: [
                const Icon(Icons.flag_rounded, size: 16),
                if (_openReports > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$_openReports',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ]),
              text: 'Reports',
            ),
            Tab(
              icon: Stack(clipBehavior: Clip.none, children: [
                const Icon(Icons.edit_note_rounded, size: 16),
                if (_openUsernameRequests > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.amberAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$_openUsernameRequests',
                          style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 8,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ]),
              text: 'Usernamen',
            ),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: _ctrl,
          children: [
            _AuditLogTab(
                world: widget.world,
                accent: widget.accent,
                accentBright: widget.accentBright,
                isRootAdmin: widget.isRootAdmin),
            _ReportsInboxTab(
              accent: widget.accent,
              accentBright: widget.accentBright,
              isRootAdmin: widget.isRootAdmin,
              onChanged: _loadReportsCount,
            ),
            _UsernameRequestsTab(
              world: widget.world,
              accent: widget.accent,
              accentBright: widget.accentBright,
              onChanged: _loadUsernameRequestsCount,
            ),
          ],
        ),
      ),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB – REPORTS-INBOX
// ═════════════════════════════════════════════════════════════════════════════
class _ReportsInboxTab extends StatefulWidget {
  final Color accent;
  final Color accentBright;
  final VoidCallback onChanged;
  final bool isRootAdmin;
  const _ReportsInboxTab({
    required this.accent,
    required this.accentBright,
    required this.onChanged,
    this.isRootAdmin = false,
  });

  @override
  State<_ReportsInboxTab> createState() => _ReportsInboxTabState();
}

class _ReportsInboxTabState extends State<_ReportsInboxTab> {
  List<Map<String, dynamic>> _reports = [];
  Map<String, int> _counts = {};
  Map<String, int> _byType = {};
  bool _loading = true;
  String _filterStatus = 'open';
  String _filterType = 'all';
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse('${ApiConfig.workerUrl}/api/admin/reports')
          .replace(queryParameters: {
        if (_filterStatus != 'all') 'status': _filterStatus,
        if (_filterType != 'all') 'type': _filterType,
        'limit': '100',
      });
      final headers = await AdminAuthService.instance.headers();
      final res = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _reports = ((data['reports'] as List?) ?? const [])
              .cast<Map<String, dynamic>>();
          _counts =
              ((data['counts'] as Map?)?.cast<String, dynamic>() ?? const {})
                  .map((k, v) => MapEntry(k, (v as num).toInt()));
          _byType =
              ((data['by_type'] as Map?)?.cast<String, dynamic>() ?? const {})
                  .map((k, v) => MapEntry(k, (v as num).toInt()));
          _loading = false;
        });
      } else if (mounted) {
        setState(() {
          _error =
              'HTTP ${res.statusCode}: ${res.body.substring(0, res.body.length > 120 ? 120 : res.body.length)}';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Netzwerk: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _setStatus(Map<String, dynamic> report, String status,
      {String? note}) async {
    final id = report['id'] as String?;
    if (id == null) return;
    try {
      final adminHeaders = await AdminAuthService.instance.headers();
      final res = await http
          .patch(
            Uri.parse('${ApiConfig.workerUrl}/api/admin/reports/$id'),
            headers: {
              'Content-Type': 'application/json',
              ...adminHeaders,
            },
            body: jsonEncode({
              'status': status,
              if (note != null) 'resolution_note': note,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Status: $status'),
          backgroundColor: widget.accent,
        ));
        _load();
        widget.onChanged();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ HTTP ${res.statusCode}'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Netzwerk. Bitte erneut versuchen.'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  // Meldung loeschen (nur root_admin -- Worker prueft Rolle zusaetzlich).
  Future<void> _deleteReport(Map<String, dynamic> report) async {
    final id = report['id'] as String?;
    if (id == null) return;
    final ok = await WorldAdminServiceV162.deleteReport(id);
    if (!mounted) return;
    if (ok) {
      setState(() => _reports.removeWhere((e) => e['id'] == id));
      widget.onChanged();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Meldung geloescht'), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Loeschen fehlgeschlagen'),
          backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _clearReports() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF12121E),
            title: const Text('Meldungen leeren',
                style: TextStyle(color: Colors.white)),
            content: Text(
                _filterStatus == 'all'
                    ? 'Wirklich ALLE Meldungen unwiderruflich loeschen?'
                    : 'Wirklich alle Meldungen mit Status "$_filterStatus" loeschen?',
                style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Abbrechen')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Loeschen',
                      style: TextStyle(color: Colors.redAccent))),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    final ok = await WorldAdminServiceV162.clearReports(status: _filterStatus);
    if (!mounted) return;
    if (ok) {
      widget.onChanged();
      _load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Meldungen geleert'), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Leeren fehlgeschlagen'),
          backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _showDetail(Map<String, dynamic> r) async {
    final noteCtrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A18),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          children: [
            Center(
                child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 16),
            Row(children: [
              _typeChip(r['type'] as String? ?? '?', big: true),
              const SizedBox(width: 8),
              _severityChip(r['severity'] as String? ?? 'medium'),
              const Spacer(),
              _statusChip(r['status'] as String? ?? 'open'),
            ]),
            const SizedBox(height: 14),
            Text(r['title']?.toString() ?? '',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
                '@${r['username'] ?? 'anonym'} · ${_fmt(r['created_at'] as String? ?? '')}',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            if ((r['body'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SelectableText(r['body'].toString(),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13, height: 1.5)),
              ),
            ],
            if ((r['target_id'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              _InfoRow(Icons.gps_fixed_rounded, 'Target: ${r['target_id']}'),
            ],
            if ((r['context'] != null) &&
                (r['context'] is Map) &&
                (r['context'] as Map).isNotEmpty) ...[
              const SizedBox(height: 10),
              _InfoRow(Icons.info_outline_rounded,
                  'Context: ${jsonEncode(r['context'])}'),
            ],
            if ((r['resolution_note'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 14),
              const Text('AUFLÖSUNG',
                  style: TextStyle(
                      color: Colors.white38, fontSize: 10, letterSpacing: 2)),
              const SizedBox(height: 4),
              Text(r['resolution_note'].toString(),
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              Text(
                  '— @${r['reviewed_by'] ?? '?'} · ${_fmt(r['reviewed_at'] as String? ?? '')}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ],
            const SizedBox(height: 22),
            const Text('Bearbeiten',
                style: TextStyle(
                    color: Colors.white54, fontSize: 11, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              maxLength: 400,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Notiz/Lösung (optional)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _setStatus(r, 'reviewing',
                      note: noteCtrl.text.trim().isEmpty
                          ? null
                          : noteCtrl.text.trim());
                },
                icon: const Icon(Icons.remove_red_eye_rounded, size: 16),
                label: const Text('In Bearbeitung'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: Colors.black),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _setStatus(r, 'resolved',
                      note: noteCtrl.text.trim().isEmpty
                          ? null
                          : noteCtrl.text.trim());
                },
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: const Text('Erledigt'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _setStatus(r, 'dismissed',
                      note: noteCtrl.text.trim().isEmpty
                          ? null
                          : noteCtrl.text.trim());
                },
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Verwerfen'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade700,
                    foregroundColor: Colors.white),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _setStatus(r, 'open');
                },
                icon: const Icon(Icons.replay_rounded, size: 16),
                label: const Text('Erneut öffnen'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white),
              ),
              if (widget.isRootAdmin)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _deleteReport(r);
                  },
                  icon: const Icon(Icons.delete_forever_rounded, size: 16),
                  label: const Text('Loeschen'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900,
                      foregroundColor: Colors.white),
                ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String type, {bool big = false}) {
    final String label;
    final Color color;
    switch (type) {
      case 'bug':
        label = '🐛 Bug';
        color = Colors.red;
        break;
      case 'content':
        label = '🚩 Inhalt';
        color = Colors.orange;
        break;
      case 'feedback':
        label = '💬 Feedback';
        color = Colors.blue;
        break;
      case 'voice':
        label = '🎙️ Voice';
        color = Colors.purple;
        break;
      default:
        label = '?';
        color = Colors.grey;
    }
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: big ? 10 : 6, vertical: big ? 5 : 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(big ? 10 : 6),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: big ? 12 : 10,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _severityChip(String sev) {
    final String label;
    final Color color;
    switch (sev) {
      case 'low':
        label = 'Niedrig';
        color = Colors.grey;
        break;
      case 'high':
        label = 'Hoch';
        color = Colors.orange;
        break;
      case 'critical':
        label = 'KRITISCH';
        color = Colors.red;
        break;
      case 'medium':
      default:
        label = 'Medium';
        color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5)),
    );
  }

  Widget _statusChip(String status) {
    final String label;
    final Color color;
    switch (status) {
      case 'reviewing':
        label = 'IN BEARB.';
        color = const Color(0xFFFFC107);
        break;
      case 'resolved':
        label = 'ERLEDIGT';
        color = Colors.green;
        break;
      case 'dismissed':
        label = 'VERWORFEN';
        color = Colors.grey;
        break;
      case 'open':
      default:
        label = 'OFFEN';
        color = Colors.redAccent;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1)),
    );
  }

  String _fmt(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}. ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  Widget _filterPill(String label, String value, String current, int? count,
      void Function(String) onTap) {
    final sel = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sel
              ? widget.accent.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? widget.accent : Colors.transparent),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: TextStyle(
                  color: sel ? widget.accentBright : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          if (count != null && count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$count',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Filter-Leiste
      Container(
        color: const Color(0xFF0D0D1A),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('STATUS',
                style: TextStyle(
                    color: Colors.white38, fontSize: 9, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            SizedBox(
                height: 30,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _filterPill('Offen', 'open', _filterStatus, _counts['open'],
                        (v) {
                      setState(() => _filterStatus = v);
                      _load();
                    }),
                    _filterPill('In Bearb.', 'reviewing', _filterStatus,
                        _counts['reviewing'], (v) {
                      setState(() => _filterStatus = v);
                      _load();
                    }),
                    _filterPill('Erledigt', 'resolved', _filterStatus,
                        _counts['resolved'], (v) {
                      setState(() => _filterStatus = v);
                      _load();
                    }),
                    _filterPill('Verworfen', 'dismissed', _filterStatus,
                        _counts['dismissed'], (v) {
                      setState(() => _filterStatus = v);
                      _load();
                    }),
                    _filterPill('Alle', 'all', _filterStatus, null, (v) {
                      setState(() => _filterStatus = v);
                      _load();
                    }),
                  ],
                )),
            const SizedBox(height: 8),
            const Text('TYP',
                style: TextStyle(
                    color: Colors.white38, fontSize: 9, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            SizedBox(
                height: 30,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _filterPill('Alle', 'all', _filterType, null, (v) {
                      setState(() => _filterType = v);
                      _load();
                    }),
                    _filterPill('🐛 Bug', 'bug', _filterType, _byType['bug'],
                        (v) {
                      setState(() => _filterType = v);
                      _load();
                    }),
                    _filterPill(
                        '🚩 Inhalt', 'content', _filterType, _byType['content'],
                        (v) {
                      setState(() => _filterType = v);
                      _load();
                    }),
                    _filterPill('💬 Feedback', 'feedback', _filterType,
                        _byType['feedback'], (v) {
                      setState(() => _filterType = v);
                      _load();
                    }),
                    _filterPill(
                        '🎙️ Voice', 'voice', _filterType, _byType['voice'],
                        (v) {
                      setState(() => _filterType = v);
                      _load();
                    }),
                  ],
                )),
            // Root-Admin: alle (gefilterten) Meldungen loeschen.
            if (widget.isRootAdmin && _reports.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _clearReports,
                  icon: const Icon(Icons.delete_sweep_rounded,
                      size: 16, color: Colors.redAccent),
                  label: Text(
                      _filterStatus == 'all'
                          ? 'Alle Meldungen loeschen'
                          : 'Gefilterte loeschen',
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12)),
                ),
              ),
            ],
          ],
        ),
      ),

      Expanded(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: widget.accent))
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Colors.redAccent, size: 40),
                        const SizedBox(height: 12),
                        Text(_error!,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                            onPressed: _load, child: const Text('Neu laden')),
                      ]),
                    ),
                  )
                : _reports.isEmpty
                    ? RefreshIndicator(
                        color: widget.accent,
                        onRefresh: () async => _load(),
                        child: ListView(children: const [
                          SizedBox(height: 80),
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Column(children: [
                                Icon(Icons.inbox_rounded,
                                    color: Colors.white24, size: 60),
                                SizedBox(height: 12),
                                Text('Keine Reports in diesem Filter.',
                                    style: TextStyle(
                                        color: Colors.white54, fontSize: 13)),
                              ]),
                            ),
                          ),
                        ]),
                      )
                    : RefreshIndicator(
                        color: widget.accent,
                        onRefresh: () async => _load(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _reports.length,
                          itemBuilder: (_, i) {
                            final r = _reports[i];
                            final card = Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _showDetail(r),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF12121E),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          _typeChip(
                                              r['type'] as String? ?? '?'),
                                          const SizedBox(width: 6),
                                          _severityChip(
                                              r['severity'] as String? ??
                                                  'medium'),
                                          const Spacer(),
                                          _statusChip(
                                              r['status'] as String? ?? 'open'),
                                        ]),
                                        const SizedBox(height: 8),
                                        Text(r['title']?.toString() ?? '',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis),
                                        if ((r['body'] as String?)
                                                ?.isNotEmpty ==
                                            true) ...[
                                          const SizedBox(height: 4),
                                          Text(r['body'].toString(),
                                              style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 11,
                                                  height: 1.3),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis),
                                        ],
                                        const SizedBox(height: 6),
                                        Text(
                                            '@${r['username'] ?? 'anonym'} · ${_fmt(r['created_at'] as String? ?? '')}',
                                            style: const TextStyle(
                                                color: Colors.white38,
                                                fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                            if (!widget.isRootAdmin) return card;
                            final id = r['id'] as String?;
                            if (id == null) return card;
                            // Root-Admin: per Swipe loeschbar.
                            return Dismissible(
                              key: ValueKey('report_$id'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.only(right: 20, bottom: 8),
                                child: const Icon(Icons.delete_forever_rounded,
                                    color: Colors.redAccent),
                              ),
                              confirmDismiss: (_) async {
                                await _deleteReport(r);
                                return false; // _deleteReport pflegt Liste selbst.
                              },
                              child: card,
                            );
                          },
                        ),
                      ),
      ),
    ]);
  }
}

class _AuditLogTab extends StatefulWidget {
  final String world;
  final Color accent;
  final Color accentBright;
  final bool isRootAdmin;
  const _AuditLogTab(
      {required this.world,
      required this.accent,
      required this.accentBright,
      this.isRootAdmin = false});

  @override
  State<_AuditLogTab> createState() => _AuditLogTabState();
}

class _AuditLogTabState extends State<_AuditLogTab> {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;
  String _filterAction = 'all';
  // v103 Phase 4f: zusaetzlicher Zeitraum-Filter.
  String _filterRange = 'all'; // 'today' | '7d' | '30d' | 'all'

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _matchesRange(DateTime? created) {
    if (_filterRange == 'all' || created == null) return true;
    final now = DateTime.now();
    switch (_filterRange) {
      case 'today':
        return created.year == now.year &&
            created.month == now.month &&
            created.day == now.day;
      case '7d':
        return now.difference(created).inDays <= 7;
      case '30d':
        return now.difference(created).inDays <= 30;
      default:
        return true;
    }
  }

  DateTime? _parseLogTs(Map<String, dynamic> l) {
    final ts = l['created_at'] ?? l['timestamp'];
    if (ts is String) return DateTime.tryParse(ts);
    return null;
  }

  List<int> _last7DaysCounts() {
    final counts = List<int>.filled(7, 0);
    final now = DateTime.now();
    for (final l in _logs) {
      final ts = _parseLogTs(l);
      if (ts == null) continue;
      final delta = now.difference(ts).inDays;
      if (delta >= 0 && delta < 7) {
        counts[6 - delta]++;
      }
    }
    return counts;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final headers = await AdminAuthService.instance.headers();
      final res = await http
          .get(
            Uri.parse(
                '${ApiConfig.workerUrl}/api/admin/audit/${widget.world}?limit=200'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 12));
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
    return _logs.where((l) {
      if (_filterAction != 'all' &&
          !(l['action'] as String? ?? '').contains(_filterAction)) {
        return false;
      }
      if (!_matchesRange(_parseLogTs(l))) return false;
      return true;
    }).toList();
  }

  void _toast(String m, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m), backgroundColor: color));
  }

  // Einzelnen Audit-Eintrag loeschen (nur root_admin). edit_/del_-Eintraege
  // stammen aus chat_messages und sind hier nicht loeschbar.
  Future<void> _deleteEntry(Map<String, dynamic> l) async {
    final logId = (l['log_id'] as String?) ?? '';
    if (!logId.startsWith('audit_')) {
      _toast('Dieser Eintrag (Chat-Historie) ist nicht loeschbar.',
          color: Colors.orange);
      return;
    }
    final ok = await WorldAdminServiceV162.deleteAuditEntry(
        world: widget.world, logId: logId);
    if (!mounted) return;
    if (ok) {
      setState(() => _logs.removeWhere((e) => e['log_id'] == logId));
      _toast('Eintrag geloescht', color: Colors.green);
    } else {
      _toast('Loeschen fehlgeschlagen', color: Colors.red);
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF12121E),
            title: const Text('Audit-Log leeren',
                style: TextStyle(color: Colors.white)),
            content: const Text(
                'Wirklich ALLE Audit-/Log-Eintraege unwiderruflich loeschen?',
                style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Abbrechen')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Alles loeschen',
                      style: TextStyle(color: Colors.redAccent))),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    final ok = await WorldAdminServiceV162.clearAuditLog(world: widget.world);
    if (!mounted) return;
    if (ok) {
      setState(() => _logs.clear());
      _toast('Audit-Log geleert', color: Colors.green);
    } else {
      _toast('Leeren fehlgeschlagen', color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = {
      'all',
      ..._logs.map((l) => (l['action'] as String? ?? 'unknown')).toSet()
    };
    final dayCounts = _last7DaysCounts();
    final maxCount = dayCounts.isEmpty
        ? 1
        : (dayCounts.reduce((a, b) => a > b ? a : b).clamp(1, 9999));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(children: [
            Text('${_filtered.length}/${_logs.length} EINTRÄGE',
                style: TextStyle(
                    color: widget.accentBright,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            if (widget.isRootAdmin && _logs.isNotEmpty)
              IconButton(
                  tooltip: 'Audit-Log leeren',
                  icon: const Icon(Icons.delete_sweep_rounded,
                      color: Colors.redAccent),
                  onPressed: _clearAll),
            IconButton(
                icon: Icon(Icons.refresh, color: widget.accent),
                onPressed: _load),
          ]),
        ),
        // v103 Phase 4f: Mini-Balkendiagramm letzte 7 Tage.
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: widget.accent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: widget.accent.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aktionen pro Tag (letzte 7 Tage)',
                style: TextStyle(
                    color: widget.accentBright,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 36,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (int i = 0; i < dayCounts.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                height: (dayCounts[i] / maxCount) * 28,
                                decoration: BoxDecoration(
                                  color: dayCounts[i] > 0
                                      ? widget.accent
                                      : widget.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${dayCounts[i]}',
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 8),
                              ),
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
        // Zeitraum-Filter (Phase 4f).
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final r in [
                ('all', 'Alle'),
                ('today', 'Heute'),
                ('7d', '7 Tage'),
                ('30d', '30 Tage'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(r.$2, style: const TextStyle(fontSize: 10)),
                    selected: _filterRange == r.$1,
                    onSelected: (_) => setState(() => _filterRange = r.$1),
                    selectedColor: widget.accentBright,
                  ),
                ),
            ],
          ),
        ),
        // v115 (Feature F): Kategorie-Schnellfilter. Setzt _filterAction auf
        // einen Substring, der via .contains() mehrere Aktionstypen matcht
        // (z.B. 'role' -> role_promote + role_change_explicit).
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final c in const [
                ('all', '📋 Alle'),
                ('role', '🛡️ Rollen'),
                ('ban', '🚫 Bans'),
                ('warning', '⚠️ Verwarnungen'),
                ('message', '💬 Nachrichten'),
                ('xp', '✨ XP'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(c.$2, style: const TextStyle(fontSize: 10)),
                    selected: _filterAction == c.$1,
                    onSelected: (_) => setState(() => _filterAction = c.$1),
                    selectedColor: widget.accentBright,
                    backgroundColor: const Color(0xFF1A1A26),
                    labelStyle: TextStyle(
                      color:
                          _filterAction == c.$1 ? Colors.black : Colors.white70,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Action-Filter -- nur rendern wenn echte Aktionen im Audit-Log
        // existieren. Bei leerem Log hat actions nur 'all' und der Chip
        // wirkt redundant zum Zeitraum-Filter darueber.
        if (actions.length > 1)
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
                      label: Text(
                        a == 'all' ? 'Alle Aktionen' : a,
                        style: const TextStyle(fontSize: 10),
                      ),
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
                  ? const Center(
                      child: Text('Keine Einträge',
                          style: TextStyle(color: Colors.white60)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final l = _filtered[i];
                        if (!widget.isRootAdmin) return _buildLogRow(l);
                        // Root-Admin: per Swipe loeschbar (nur audit_-Eintraege).
                        final logId = (l['log_id'] as String?) ?? '';
                        final deletable = logId.startsWith('audit_');
                        if (!deletable) return _buildLogRow(l);
                        return Dismissible(
                          key: ValueKey(logId),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding:
                                const EdgeInsets.only(right: 20, bottom: 6),
                            child: const Icon(Icons.delete_forever_rounded,
                                color: Colors.redAccent),
                          ),
                          confirmDismiss: (_) async {
                            await _deleteEntry(l);
                            return false; // _deleteEntry pflegt die Liste selbst.
                          },
                          child: _buildLogRow(l),
                        );
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
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(
                    ts
                        .substring(0, ts.length >= 16 ? 16 : ts.length)
                        .replaceAll('T', ' '),
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 10)),
              ]),
              Text('$admin → $target',
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
              if (details.isNotEmpty)
                Text(details,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
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

// ═════════════════════════════════════════════════════════════════════════════
// TAB - USERNAME-AENDERUNGSANTRAEGE
// Liste pending Antraege aus /api/admin/username-change-requests.
// Approve/Reject senden POST an Worker. Reload + SnackBar nach Aktion.
// ═════════════════════════════════════════════════════════════════════════════
class _UsernameRequestsTab extends ConsumerStatefulWidget {
  final String world;
  final Color accent;
  final Color accentBright;
  final VoidCallback onChanged;
  const _UsernameRequestsTab({
    required this.world,
    required this.accent,
    required this.accentBright,
    required this.onChanged,
  });

  @override
  ConsumerState<_UsernameRequestsTab> createState() =>
      _UsernameRequestsTabState();
}

class _UsernameRequestsTabState extends ConsumerState<_UsernameRequestsTab> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _adminUsername {
    final admin = ref.read(adminStateProvider(widget.world));
    return admin.username ?? 'admin';
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final headers = await AdminAuthService.instance.headers();
      final res = await http
          .get(
              Uri.parse(
                  '${ApiConfig.workerUrl}/api/admin/username-change-requests'),
              headers: headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final raw = (data['requests'] as List?) ?? const [];
        final list =
            raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
        if (mounted) {
          setState(() {
            _requests = list;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
        _snack('Laden fehlgeschlagen: HTTP ${res.statusCode}',
            color: Colors.orange);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      _snack('Fehler beim Laden: $e', color: Colors.orange);
    }
    widget.onChanged();
  }

  void _snack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color ?? const Color(0xFF1A1A2E),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<bool> _confirm(String title, String msg, {Color? confirmColor}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17)),
        content: Text(msg,
            style: const TextStyle(
                color: Colors.white70, fontSize: 14, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? widget.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Bestaetigen',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _approve(Map<String, dynamic> req) async {
    final id = (req['id'] ?? '').toString();
    if (id.isEmpty) {
      _snack('Antrags-ID fehlt', color: Colors.red);
      return;
    }
    final cur = (req['current_username'] ?? '').toString();
    final neu = (req['requested_username'] ?? '').toString();
    final ok = await _confirm(
      'Username dauerhaft aendern?',
      '@$cur -> @$neu\n\nDie Aenderung wird sofort wirksam und ist nicht zurueckholbar.',
      confirmColor: Colors.green,
    );
    if (!ok) return;
    setState(() => _processing = true);
    try {
      final adminHeaders = await AdminAuthService.instance.headers();
      final res = await http
          .post(
            Uri.parse(
                '${ApiConfig.workerUrl}/api/admin/username-change-requests/$id/approve'),
            headers: {
              'Content-Type': 'application/json',
              ...adminHeaders,
            },
            body: jsonEncode(const {}),
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        _snack('✅ @$cur ist jetzt @$neu', color: Colors.green);
      } else {
        _snack('Genehmigen fehlgeschlagen: HTTP ${res.statusCode}',
            color: Colors.orange);
      }
    } catch (e) {
      _snack('Genehmigen Fehler: $e', color: Colors.orange);
    } finally {
      if (mounted) setState(() => _processing = false);
      await _load();
    }
  }

  Future<void> _reject(Map<String, dynamic> req) async {
    final id = (req['id'] ?? '').toString();
    if (id.isEmpty) {
      _snack('Antrags-ID fehlt', color: Colors.red);
      return;
    }
    final cur = (req['current_username'] ?? '').toString();
    final neu = (req['requested_username'] ?? '').toString();
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Antrag ablehnen',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('@$cur -> @$neu',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: noteCtrl,
            maxLength: 200,
            maxLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Notiz (optional, sichtbar fuer den User)',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF0D0D1A),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child:
                const Text('Ablehnen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final note = noteCtrl.text.trim();
    setState(() => _processing = true);
    try {
      final adminHeaders = await AdminAuthService.instance.headers();
      final res = await http
          .post(
            Uri.parse(
                '${ApiConfig.workerUrl}/api/admin/username-change-requests/$id/reject'),
            headers: {
              'Content-Type': 'application/json',
              ...adminHeaders,
            },
            body: jsonEncode({
              if (note.isNotEmpty) 'note': note,
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        _snack('Antrag von @$cur abgelehnt', color: Colors.orange);
      } else {
        _snack('Ablehnen fehlgeschlagen: HTTP ${res.statusCode}',
            color: Colors.orange);
      }
    } catch (e) {
      _snack('Ablehnen Fehler: $e', color: Colors.orange);
    } finally {
      if (mounted) setState(() => _processing = false);
      await _load();
    }
  }

  String _relativeTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'gerade eben';
      if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'vor ${diff.inHours} h';
      if (diff.inDays < 30) return 'vor ${diff.inDays} d';
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D1A),
            border: Border(
                bottom:
                    BorderSide(color: Colors.white.withValues(alpha: 0.05))),
          ),
          child: Row(children: [
            const Text('📝', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            const Text('Username-Aenderungsantraege',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: widget.accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: widget.accent.withValues(alpha: 0.4)),
              ),
              child: Text(
                '${_requests.length}',
                style: TextStyle(
                    color: widget.accentBright,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.refresh_rounded,
                  color: widget.accentBright, size: 20),
              tooltip: 'Aktualisieren',
              onPressed: _loading ? null : _load,
            ),
          ]),
        ),
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: widget.accent))
              : _requests.isEmpty
                  ? Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          Icon(Icons.inbox_rounded,
                              size: 56, color: Colors.white24),
                          const SizedBox(height: 12),
                          const Text('Keine offenen Antraege',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 14)),
                        ]))
                  : RefreshIndicator(
                      color: widget.accent,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
                        itemCount: _requests.length,
                        itemBuilder: (ctx, i) =>
                            _buildRequestCard(_requests[i]),
                      ),
                    ),
        ),
      ]),
      if (_processing)
        Container(
          color: Colors.black54,
          child: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CircularProgressIndicator(color: widget.accent),
              const SizedBox(height: 12),
              const Text('Wird verarbeitet...',
                  style: TextStyle(color: Colors.white70)),
            ]),
          ),
        ),
    ]);
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final cur = (req['current_username'] ?? '').toString();
    final neu = (req['requested_username'] ?? '').toString();
    final reason = (req['reason'] ?? '').toString();
    final created = req['created_at']?.toString();
    final avatar = (req['avatar_url'] ?? '').toString();
    final role = (req['profile_role'] ?? 'user').toString();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.accent.withValues(alpha: 0.18)),
      ),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF12121E).withValues(alpha: 0.88),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: widget.accent.withValues(alpha: 0.18),
                  backgroundImage:
                      avatar.isNotEmpty ? NetworkImage(avatar) : null,
                  child: avatar.isEmpty
                      ? Text(
                          cur.isNotEmpty ? cur[0].toUpperCase() : '?',
                          style: TextStyle(
                              color: widget.accentBright,
                              fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('@$cur',
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      Icon(Icons.arrow_forward_rounded,
                          size: 16, color: widget.accentBright),
                      Text('@$neu',
                          style: TextStyle(
                              color: widget.accentBright,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      if (role != 'user')
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.4)),
                          ),
                          child: Text(role,
                              style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
                Text(_relativeTime(created),
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 11)),
              ]),
              if (reason.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Reason: $reason',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12, height: 1.35)),
                ),
              ],
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.cancel_outlined,
                        size: 16, color: Colors.redAccent),
                    label: const Text('Ablehnen',
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: Colors.redAccent.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: _processing ? null : () => _reject(req),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text('Genehmigen',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: _processing ? null : () => _approve(req),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminTabDef {
  final IconData icon;
  final String label;
  final String kind;
  const _AdminTabDef(
      {required this.icon, required this.label, required this.kind});
}

// ═════════════════════════════════════════════════════════════════════════════
// COMMUNITY POST REPORTS TAB (v103 Phase 4d + 4h)
// ═════════════════════════════════════════════════════════════════════════════
class _PostReportsTab extends StatefulWidget {
  final Color accent;
  final Color accentBright;
  const _PostReportsTab({required this.accent, required this.accentBright});

  @override
  State<_PostReportsTab> createState() => _PostReportsTabState();
}

class _PostReportsTabState extends State<_PostReportsTab> {
  List<PostReport> _reports = const [];
  bool _loading = true;
  String _status = 'open';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await ModerationQueueService.instance
        .postQueue(status: _status, limit: 100);
    if (!mounted) return;
    setState(() {
      _reports = list;
      _loading = false;
    });
  }

  Future<void> _review(String id, String newStatus) async {
    final adminUser = supabase.auth.currentUser?.email ?? 'admin';
    final ok = await ModerationQueueService.instance.reviewPost(
      reportId: id,
      status: newStatus,
      reviewedBy: adminUser,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Status aktualisiert' : 'Fehler')),
    );
    if (ok) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Row(children: [
          for (final s in ['open', 'reviewed', 'actioned', 'dismissed'])
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(s, style: const TextStyle(fontSize: 10)),
                selected: _status == s,
                onSelected: (_) {
                  setState(() => _status = s);
                  _load();
                },
                selectedColor: widget.accent,
              ),
            ),
          const Spacer(),
          IconButton(
              icon: Icon(Icons.refresh, color: widget.accent),
              onPressed: _load),
        ]),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _reports.isEmpty
                ? const Center(
                    child: Text('Keine Meldungen',
                        style: TextStyle(color: Colors.white60)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                    itemCount: _reports.length,
                    itemBuilder: (_, i) {
                      final r = _reports[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12121E),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: widget.accent.withValues(alpha: 0.18)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                    color:
                                        widget.accent.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(4)),
                                child: Text(r.reason.toUpperCase(),
                                    style: TextStyle(
                                        color: widget.accentBright,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ),
                              const Spacer(),
                              Text(
                                r.createdAt
                                    .toLocal()
                                    .toIso8601String()
                                    .substring(0, 16),
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 10),
                              ),
                            ]),
                            const SizedBox(height: 6),
                            Text('Post: ${r.postId}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            if (r.authorUsername != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text('Von: @${r.authorUsername}',
                                    style: const TextStyle(
                                        color: Colors.white60, fontSize: 11)),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                  'Reporter: @${r.reporterName ?? r.reporterId}',
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 11)),
                            ),
                            if (r.notes != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(r.notes!,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 11)),
                              ),
                            if (r.status == 'open') ...[
                              const SizedBox(height: 8),
                              Row(children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _review(r.id, 'dismissed'),
                                    style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white60,
                                        side: const BorderSide(
                                            color: Colors.white24)),
                                    child: const Text('Verwerfen',
                                        style: TextStyle(fontSize: 11)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _review(r.id, 'actioned'),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent),
                                    child: const Text('Aktion',
                                        style: TextStyle(fontSize: 11)),
                                  ),
                                ),
                              ]),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
      ),
    ]);
  }
}

// =============================================================================
// USER DETAIL SHEET
// =============================================================================
class _UserDetailSheet extends StatefulWidget {
  final WorldUser user;
  final Color accent, accentBright;
  final bool isRootAdmin;
  final String adminUsername;
  const _UserDetailSheet({
    required this.user,
    required this.accent,
    required this.accentBright,
    required this.isRootAdmin,
    required this.adminUsername,
  });

  @override
  State<_UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends State<_UserDetailSheet> {
  Map<String, dynamic>? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final data = await WorldAdminServiceV162.getUserDetail(widget.user.userId);
    if (!mounted) return;
    if (data == null) {
      setState(() {
        _loading = false;
        _error = 'Laden fehlgeschlagen';
      });
    } else {
      setState(() {
        _detail = data;
        _loading = false;
      });
    }
  }

  String _fmtDate(dynamic v) {
    if (v == null) return '–';
    try {
      final dt = DateTime.parse(v.toString()).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return '–';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF12121E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: widget.accent.withValues(alpha: 0.15),
                child: Text(
                  widget.user.avatarEmoji?.isNotEmpty == true
                      ? widget.user.avatarEmoji!
                      : widget.user.username.isEmpty
                          ? '?'
                          : widget.user.username[0].toUpperCase(),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.displayName ?? widget.user.username,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    Text('@${widget.user.username}',
                        style: TextStyle(color: widget.accent, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white38),
                onPressed: () => Navigator.pop(ctx),
              ),
            ]),
          ),
          const Divider(color: Colors.white10, height: 1),
          // Body
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: widget.accent))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: Colors.red, size: 36),
                            const SizedBox(height: 8),
                            Text(_error!,
                                style: const TextStyle(color: Colors.white54)),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _load,
                              child: Text('Erneut versuchen',
                                  style: TextStyle(color: widget.accent)),
                            ),
                          ],
                        ),
                      )
                    : _buildContent(scroll),
          ),
        ]),
      ),
    );
  }

  Widget _buildContent(ScrollController scroll) {
    final profile = _detail?['profile'] as Map<String, dynamic>? ?? {};
    final progress =
        _detail?['progress_summary'] as Map<String, dynamic>? ?? {};
    final warnings = (_detail?['warnings'] as List?) ?? [];
    final actions = (_detail?['recent_actions'] as List?) ?? [];

    final xp = profile['xp'] as int? ?? 0;
    final level = profile['level'] as int? ?? 1;
    final started = progress['started_modules'] as int? ?? 0;
    final completed = progress['completed_modules'] as int? ?? 0;

    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        // Stats row
        Row(children: [
          _DetailStat('XP', xp.toString(), Icons.auto_awesome_rounded,
              Colors.amber, widget.accent),
          const SizedBox(width: 10),
          _DetailStat('Level', level.toString(), Icons.star_rounded,
              Colors.orangeAccent, widget.accent),
          const SizedBox(width: 10),
          _DetailStat('Module', '$completed/$started', Icons.school_rounded,
              widget.accentBright, widget.accent),
        ]),
        const SizedBox(height: 16),

        // Profile meta
        _SectionLabel('Profil', Icons.person_rounded, widget.accent),
        const SizedBox(height: 8),
        _DetailRow('ID', widget.user.userId, Icons.fingerprint_rounded),
        _DetailRow('Rolle', widget.user.role, Icons.shield_rounded),
        _DetailRow(
            'Welt', profile['world'] as String? ?? '–', Icons.public_rounded),
        _DetailRow('Mitglied seit', _fmtDate(profile['created_at']),
            Icons.calendar_today_rounded),
        _DetailRow('Zuletzt gesehen', _fmtDate(profile['last_seen_at']),
            Icons.access_time_rounded),
        if ((profile['bio'] as String? ?? '').isNotEmpty)
          _DetailRow('Bio', profile['bio'] as String, Icons.info_rounded),

        if (warnings.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionLabel('Verwarnungen (${warnings.length})',
              Icons.warning_amber_rounded, Colors.orange),
          const SizedBox(height: 8),
          ...warnings.take(5).map((w) {
            final wMap = w as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wMap['reason'] as String? ?? '–',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_fmtDate(wMap['created_at'])} · ${wMap['admin_username'] ?? 'Admin'}',
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ]),
            );
          }),
        ],

        if (actions.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionLabel('Letzte Admin-Aktionen (${actions.length})',
              Icons.history_rounded, widget.accentBright),
          const SizedBox(height: 8),
          ...actions.take(5).map((a) {
            final aMap = a as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(children: [
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.white24, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${aMap['action'] ?? '–'} · ${aMap['admin_username'] ?? 'Admin'} · ${_fmtDate(aMap['created_at'])}',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ),
              ]),
            );
          }),
        ],
      ],
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color, accent;
  const _DetailStat(this.label, this.value, this.icon, this.color, this.accent);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ]),
        ),
      );
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _DetailRow(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Icon(icon, size: 13, color: Colors.white24),
          const SizedBox(width: 6),
          Text('$label: ',
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: Colors.white60, fontSize: 11),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      );
}

class _PushStatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color, accent;
  const _PushStatCard(
      this.label, this.value, this.icon, this.color, this.accent);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 9),
              textAlign: TextAlign.center),
        ]),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// v117: RESTRICTION-SHEET -- granulare Bereichs-Sperren waehlen
// ═════════════════════════════════════════════════════════════════════════════

// Kategorien -> Scopes. Reihenfolge bestimmt die Anzeige.
const Map<String, List<List<String>>> _kRestrictionCategories = {
  'Kommunikation': [
    ['chat', 'Chat', '💬'],
    ['livestream', 'Livestream', '🎥'],
    ['direct_messages', 'Direktnachrichten', '✉️'],
    ['shadow_mute', 'Shadow-Mute', '👻'],
  ],
  'Content': [
    ['create_articles', 'Artikel erstellen', '📝'],
    ['create_pins', 'Pins erstellen', '📍'],
    ['comment', 'Kommentieren', '💭'],
  ],
  'Gamification': [
    ['earn_xp', 'XP verdienen', '⭐'],
  ],
  'Werkzeuge': [
    ['spirit_tools', 'Spirit-Tools (alle)', '🔮'],
    ['research_tools', 'Recherche-Tools (alle)', '🔍'],
  ],
};

class _RestrictionSheet extends StatefulWidget {
  final WorldUser user;
  final Color accent, accentBright;
  final String adminUsername;
  final VoidCallback onChanged;
  const _RestrictionSheet({
    required this.user,
    required this.accent,
    required this.accentBright,
    required this.adminUsername,
    required this.onChanged,
  });

  @override
  State<_RestrictionSheet> createState() => _RestrictionSheetState();
}

class _RestrictionSheetState extends State<_RestrictionSheet> {
  final Set<String> _selected = {};
  final Map<String, Map<String, dynamic>> _active = {}; // scope -> row
  final _reasonCtrl = TextEditingController(text: 'Regelverstoss');
  bool _loading = true;
  bool _busy = false;
  int _durationIdx = 2; // default 24h
  bool _all = false;

  static const _durLabels = [
    '1 Std',
    '24 Std',
    '7 Tage',
    '30 Tage',
    'Permanent'
  ];
  static const _durHours = [1, 24, 168, 720, 0];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final rows =
        await WorldAdminServiceV162.getRestrictions(widget.user.userId);
    if (!mounted) return;
    setState(() {
      _active.clear();
      for (final r in rows) {
        final scope = r['scope'] as String?;
        if (scope != null) _active[scope] = r;
      }
      _all = _active.containsKey('all');
      _loading = false;
    });
  }

  String _expiryLabel(Map<String, dynamic> row) {
    if (row['is_permanent'] == true || row['expires_at'] == null) {
      return 'permanent';
    }
    final exp = DateTime.tryParse(row['expires_at'] as String? ?? '');
    if (exp == null) return '';
    final diff = exp.difference(DateTime.now());
    if (diff.isNegative) return 'abgelaufen';
    if (diff.inDays > 0) return 'noch ${diff.inDays}d';
    if (diff.inHours > 0) return 'noch ${diff.inHours}h';
    return 'noch ${diff.inMinutes}min';
  }

  Future<void> _applyNew() async {
    final scopes = _all ? ['all'] : _selected.toList();
    if (scopes.isEmpty) {
      _toast('Keine Bereiche ausgewaehlt');
      return;
    }
    setState(() => _busy = true);
    final ok = await WorldAdminServiceV162.restrictUser(
      userId: widget.user.userId,
      scopes: scopes,
      reason: _reasonCtrl.text.trim().isEmpty
          ? 'Admin-Sperre'
          : _reasonCtrl.text.trim(),
      durationHours: _durHours[_durationIdx],
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      _toast('Bereiche gesperrt');
      _selected.clear();
      widget.onChanged();
      await _load();
    } else {
      _toast('Sperren fehlgeschlagen');
    }
  }

  Future<void> _lift(String scope) async {
    setState(() => _busy = true);
    final ok = await WorldAdminServiceV162.unrestrictUser(
      userId: widget.user.userId,
      scopes: scope == 'all' ? const [] : [scope],
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      widget.onChanged();
      await _load();
    } else {
      _toast('Aufheben fehlgeschlagen');
    }
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m), duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scroll) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0B0817),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: _loading
            ? Center(child: CircularProgressIndicator(color: widget.accent))
            : ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(children: [
                    Icon(Icons.tune_rounded, color: widget.accentBright),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Bereiche sperren - @${widget.user.username}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  const Text(
                    'Waehle einzelne Bereiche oder Vollsperrung. Bestehende '
                    'Sperren werden mit Ablauf angezeigt und koennen aufgehoben '
                    'werden.',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  const SizedBox(height: 16),

                  // Vollsperrung-Toggle
                  _buildAllToggle(),
                  const SizedBox(height: 8),

                  if (!_all)
                    for (final entry in _kRestrictionCategories.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 4),
                        child: Text(entry.key.toUpperCase(),
                            style: TextStyle(
                                color: widget.accentBright,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5)),
                      ),
                      for (final scope in entry.value) _buildScopeRow(scope),
                    ],

                  const SizedBox(height: 18),
                  if (!_all || !_active.containsKey('all')) ...[
                    const Text('Grund',
                        style: TextStyle(color: Colors.white60, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _reasonCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFF15111F),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Dauer',
                        style: TextStyle(color: Colors.white60, fontSize: 12)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        for (int i = 0; i < _durLabels.length; i++)
                          ChoiceChip(
                            label: Text(_durLabels[i],
                                style: const TextStyle(fontSize: 11)),
                            selected: _durationIdx == i,
                            onSelected: (_) => setState(() => _durationIdx = i),
                            selectedColor: widget.accent.withValues(alpha: 0.4),
                            backgroundColor: const Color(0xFF15111F),
                            labelStyle: TextStyle(
                                color: _durationIdx == i
                                    ? Colors.white
                                    : Colors.white54),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _busy ? null : _applyNew,
                        icon: const Icon(Icons.lock_outline, size: 18),
                        label: Text(_all
                            ? 'Vollsperrung anwenden'
                            : 'Ausgewaehlte sperren'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF6C9A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ],
                  if (_active.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _busy ? null : () => _lift('all'),
                      icon: const Icon(Icons.lock_open_rounded,
                          size: 18, color: Colors.tealAccent),
                      label: const Text('Alle Sperren aufheben',
                          style: TextStyle(color: Colors.tealAccent)),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildAllToggle() {
    final active = _active.containsKey('all');
    return Container(
      decoration: BoxDecoration(
        color:
            _all ? Colors.red.withValues(alpha: 0.14) : const Color(0xFF15111F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _all ? Colors.red.withValues(alpha: 0.5) : Colors.white12),
      ),
      child: SwitchListTile(
        value: _all,
        onChanged: (v) => setState(() => _all = v),
        activeColor: Colors.red,
        title: const Text('🚫 Vollsperrung (alles)',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
        subtitle: Text(
          active
              ? 'Aktiv - ${_expiryLabel(_active['all']!)}'
              : 'Sperrt saemtliche Funktionen (klassischer Ban)',
          style: TextStyle(
              color: active ? Colors.redAccent : Colors.white38, fontSize: 11),
        ),
      ),
    );
  }

  Widget _buildScopeRow(List<String> scope) {
    final key = scope[0];
    final label = scope[1];
    final emoji = scope[2];
    final active = _active.containsKey(key);
    final checked = _selected.contains(key);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: active
            ? Colors.orange.withValues(alpha: 0.1)
            : const Color(0xFF12101C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color:
                active ? Colors.orange.withValues(alpha: 0.4) : Colors.white10),
      ),
      child: ListTile(
        dense: true,
        leading: Text(emoji, style: const TextStyle(fontSize: 18)),
        title: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 13)),
        subtitle: active
            ? Text('Aktiv - ${_expiryLabel(_active[key]!)}',
                style:
                    const TextStyle(color: Colors.orangeAccent, fontSize: 10))
            : null,
        trailing: active
            ? TextButton(
                onPressed: _busy ? null : () => _lift(key),
                child: const Text('Aufheben',
                    style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
              )
            : Checkbox(
                value: checked,
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _selected.add(key);
                  } else {
                    _selected.remove(key);
                  }
                }),
                activeColor: const Color(0xFFEF6C9A),
              ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// v117: ACCOUNT-REQUESTS-SHEET -- Antraege + Loesch-Blacklist verwalten
// ═════════════════════════════════════════════════════════════════════════════
class _AccountRequestsSheet extends StatefulWidget {
  final Color accent, accentBright;
  const _AccountRequestsSheet(
      {required this.accent, required this.accentBright});

  @override
  State<_AccountRequestsSheet> createState() => _AccountRequestsSheetState();
}

class _AccountRequestsSheetState extends State<_AccountRequestsSheet> {
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _blacklist = [];
  bool _loading = true;
  bool _busy = false;
  int _tab = 0; // 0 = Antraege, 1 = Blacklist

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final reqs =
        await WorldAdminServiceV162.getAccountRequests(status: 'pending');
    final bl = await WorldAdminServiceV162.getDeletedIdentities();
    if (!mounted) return;
    setState(() {
      _requests = reqs;
      _blacklist = bl;
      _loading = false;
    });
  }

  Future<void> _resolve(Map<String, dynamic> req, bool approve) async {
    final id = req['id'] as String?;
    if (id == null) return;
    setState(() => _busy = true);
    final ok = await WorldAdminServiceV162.resolveAccountRequest(
        requestId: id, approve: approve);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      _toast(approve ? 'Angenommen' : 'Abgelehnt');
      await _load();
    } else {
      _toast('Fehlgeschlagen');
    }
  }

  Future<void> _freeBlacklist(Map<String, dynamic> row) async {
    final id = row['id'] as String?;
    if (id == null) return;
    setState(() => _busy = true);
    final ok = await WorldAdminServiceV162.removeDeletedIdentity(id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      _toast('Freigegeben');
      await _load();
    } else {
      _toast('Fehlgeschlagen');
    }
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m), duration: const Duration(seconds: 2)));
  }

  String _typeLabel(String? t) => switch (t) {
        'reactivation' => '🔓 Reaktivierung',
        'appeal' => '⚖️ Einspruch',
        'self_deletion' => '🗑️ Selbst-Loeschung',
        _ => t ?? '?',
      };

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scroll) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0B0817),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _tabChip('Antraege (${_requests.length})', 0),
                const SizedBox(width: 8),
                _tabChip('Blacklist (${_blacklist.length})', 1),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(color: widget.accent))
                  : _tab == 0
                      ? _buildRequests(scroll)
                      : _buildBlacklist(scroll),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabChip(String label, int idx) => ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: _tab == idx,
        onSelected: (_) => setState(() => _tab = idx),
        selectedColor: widget.accent.withValues(alpha: 0.4),
        backgroundColor: const Color(0xFF15111F),
        labelStyle:
            TextStyle(color: _tab == idx ? Colors.white : Colors.white54),
      );

  Widget _buildRequests(ScrollController scroll) {
    if (_requests.isEmpty) {
      return const Center(
        child: Text('Keine offenen Antraege.',
            style: TextStyle(color: Colors.white38)),
      );
    }
    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
      itemCount: _requests.length,
      itemBuilder: (ctx, i) {
        final r = _requests[i];
        final msg = (r['message'] as String?) ?? '';
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF12101C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(_typeLabel(r['type'] as String?),
                    style: TextStyle(
                        color: widget.accentBright,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                const Spacer(),
                Text('@${r['username'] ?? r['user_id'] ?? '?'}',
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 11)),
              ]),
              if (r['restriction_scope'] != null) ...[
                const SizedBox(height: 3),
                Text('Bereich: ${r['restriction_scope']}',
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
              if (msg.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(msg,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _resolve(r, false),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Ablehnen'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : () => _resolve(r, true),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Annehmen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBlacklist(ScrollController scroll) {
    if (_blacklist.isEmpty) {
      return const Center(
        child: Text('Blacklist ist leer.',
            style: TextStyle(color: Colors.white38)),
      );
    }
    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
      itemCount: _blacklist.length,
      itemBuilder: (ctx, i) {
        final b = _blacklist[i];
        final status = (b['reactivation_status'] as String?) ?? 'blocked';
        final statusColor = status == 'requested'
            ? Colors.orangeAccent
            : status == 'approved'
                ? Colors.greenAccent
                : Colors.white38;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF12101C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('@${b['username_lower'] ?? '?'}',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text('Status: $status',
                      style: TextStyle(color: statusColor, fontSize: 10)),
                  if (b['reason'] != null)
                    Text('Grund: ${b['reason']}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10)),
                ],
              ),
            ),
            TextButton(
              onPressed: _busy ? null : () => _freeBlacklist(b),
              child: const Text('Freigeben',
                  style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
            ),
          ]),
        );
      },
    );
  }
}
