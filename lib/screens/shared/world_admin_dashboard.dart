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
import 'package:youtube_player_flutter/youtube_player_flutter.dart'
    show
        YoutubePlayerController,
        YoutubePlayerFlags,
        YoutubePlayer,
        YoutubePlayerBuilder;

import '../../config/api_config.dart';
import '../../core/constants/roles.dart';
import '../../widgets/chat/chat_markdown_text.dart'; // W6: Modul-Vorschau
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

part 'world_admin_dashboard/overview_tab.dart';
part 'world_admin_dashboard/users_tab.dart';
part 'world_admin_dashboard/chat_moderation_tab.dart';
part 'world_admin_dashboard/system_tab.dart';
part 'world_admin_dashboard/widgets.dart';
part 'world_admin_dashboard/notes_sheet.dart';
part 'world_admin_dashboard/moderation_sheet.dart';
part 'world_admin_dashboard/module_access_sheet.dart';
part 'world_admin_dashboard/moderation_queue_screen.dart';
part 'world_admin_dashboard/content_tabs.dart';
part 'world_admin_dashboard/spirit_module_tabs.dart';
part 'world_admin_dashboard/push_broadcast_tab.dart';
part 'world_admin_dashboard/audit_tabs.dart';
part 'world_admin_dashboard/requests_tabs.dart';
part 'world_admin_dashboard/user_detail_sheet.dart';
part 'world_admin_dashboard/restriction_sheet.dart';
part 'world_admin_dashboard/account_requests_sheet.dart';
part 'world_admin_dashboard/admin_hub.dart';
part 'world_admin_dashboard/insights_tab.dart';
part 'world_admin_dashboard/control_tab.dart';
part 'world_admin_dashboard/search_sheet.dart';
part 'world_admin_dashboard/sensitive_sheets.dart';
part 'world_admin_dashboard/module_workshop_tab.dart';

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

  // HUB navigation: null = hub landing, otherwise a section key
  // (matches _sectionBody). The hub is the default entry surface.
  String? _activeSection;

  // Pre-filled search query when the hub global search opens the Users section.
  String _pendingUserSearch = '';

  // Best-effort "Zu erledigen" badge counts (default 0, never block/crash).
  int _badgeOpenReports = 0;
  int _badgePendingUsernameRequests = 0;
  int _badgeFailedPushes = 0;
  // v123: pending content (videos waiting for confirm) + maintenance-flag.
  int _badgePendingVideos = 0;
  bool _badgeMaintenanceActive = false;

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
      if (mounted) _loadHubBadges();
    });
  }

  /// Best-effort hub badge fetch. Reuses the SAME endpoints the existing tabs
  /// use (overview_tab.dart:236 / audit_tabs.dart:47/65, push_broadcast_tab
  /// .dart:43). Each count is wrapped in try/catch and defaults to 0 -- never
  /// blocks the UI or crashes. No heavy/new backend calls are introduced.
  Future<void> _loadHubBadges() async {
    // Open reports (moderation queue) -> /api/admin/reports?status=open.
    try {
      final reportsData =
          await WorldAdminServiceV162.getReports(status: 'open', limit: 1);
      final open = reportsData == null
          ? 0
          : ((reportsData['counts'] as Map?)?['open'] as num?)?.toInt() ?? 0;
      if (mounted) setState(() => _badgeOpenReports = open);
    } catch (_) {/* degrade gracefully */}

    // Pending username-change requests -> /api/admin/username-change-requests.
    try {
      final headers = await AdminAuthService.instance.headers();
      final res = await http
          .get(
              Uri.parse(
                  '${ApiConfig.workerUrl}/api/admin/username-change-requests'),
              headers: headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final total =
            (data['total'] as int?) ?? (data['requests'] as List?)?.length ?? 0;
        if (mounted) setState(() => _badgePendingUsernameRequests = total);
      }
    } catch (_) {/* degrade gracefully */}

    // Failed pushes -> /api/admin/push/stats -> total_failed.
    try {
      final stats = await WorldAdminServiceV162.getPushStats();
      final failed = (stats?['total_failed'] as num?)?.toInt() ?? 0;
      if (mounted) setState(() => _badgeFailedPushes = failed);
    } catch (_) {/* degrade gracefully */}

    // v123: pending content videos awaiting approval.
    try {
      final pending = await WorldAdminServiceV162.getPendingVideos();
      if (mounted) setState(() => _badgePendingVideos = pending.length);
    } catch (_) {/* degrade gracefully */}

    // v123: maintenance flag active -> show warning chip.
    try {
      final flags = await WorldAdminServiceV162.getFeatureFlags();
      final maint = flags.any((f) =>
          (f['key'] as String?) == 'maintenance' &&
          (f['enabled'] as bool? ?? false));
      if (mounted) setState(() => _badgeMaintenanceActive = maint);
    } catch (_) {/* degrade gracefully */}
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
      // Volle Content-Rechte (Root-Admin + Content-Editor): kompletter
      // Content-Tab inkl. Module/Editor/Meldungen/Artikel/Videos.
      tabs.add(const _AdminTabDef(
          icon: Icons.analytics_rounded, label: 'Content', kind: 'content'));
      // v128 (Task 3): KI-gestuetzte Modul-Werkstatt (Admin+ kann Lern-
      // Module ohne Code erstellen + editieren).
      tabs.add(const _AdminTabDef(
          icon: Icons.auto_awesome,
          label: 'Modul-Werkstatt',
          kind: 'module_workshop'));
    } else if (AppRoles.canAccessAdminDashboard(role)) {
      // Moderator: nur Video-Verwaltung, keine sonstigen Content-Funktionen.
      tabs.add(const _AdminTabDef(
          icon: Icons.play_circle_outline_rounded,
          label: 'Videos',
          kind: 'videos'));
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

    // HUB-first entry: the default surface is the _AdminHub landing (see body
    // below). The legacy TabBar/TabController wiring is intentionally no longer
    // built here; _availableTabs/_ensureTabController/_buildTabBody remain in
    // the file (unused by build) to avoid touching unrelated references.
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
              _loadHubBadges();
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
        // Back button: from a section -> return to hub; from hub -> leave.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white70, size: 20),
          onPressed: () {
            if (_activeSection != null) {
              setState(() => _activeSection = null);
            } else {
              Navigator.pop(context);
            }
          },
          tooltip: _activeSection != null ? 'Zur Übersicht' : 'Zurück',
        ),
      ),
      // null -> hub landing, otherwise the selected section widget.
      body: _activeSection == null
          ? _AdminHub(
              role: admin.role,
              accent: _accent,
              accentBright: _accentBright,
              openReports: _badgeOpenReports,
              pendingUsernameRequests: _badgePendingUsernameRequests,
              failedPushes: _badgeFailedPushes,
              pendingVideos: _badgePendingVideos,
              maintenanceActive: _badgeMaintenanceActive,
              onOpen: (section) => setState(() => _activeSection = section),
              onSearch: (query) => setState(() {
                _pendingUserSearch = query;
                _activeSection = 'users';
              }),
              onOpenGlobalSearch: () => showGlobalAdminSearch(
                context,
                accent: _accent,
                accentBright: _accentBright,
                onJump: (section, {String? query}) {
                  setState(() {
                    if (query != null) _pendingUserSearch = query;
                    _activeSection = section;
                  });
                },
              ),
            )
          : _sectionBody(_activeSection!, admin),
    );
  }

  /// Maps a hub section key to the existing (unchanged) section widget.
  /// Reuses exactly the same constructors as [_buildTabBody]; 'moderation'
  /// uses the [_ModerationHub] wrapper (Chat + Meldungen sub-tabs).
  Widget _sectionBody(String section, AdminState admin) {
    switch (section) {
      case 'overview':
        return _OverviewTab(
            world: 'all',
            admin: admin,
            accent: _accent,
            accentBright: _accentBright);
      case 'users':
        return _UsersTab(
            key: ValueKey(
                'users-${_pendingUserSearch.isEmpty ? '_' : _pendingUserSearch}'),
            world: 'all',
            admin: admin,
            accent: _accent,
            accentBright: _accentBright,
            initialQuery: _pendingUserSearch);
      case 'moderation':
        return _ModerationHub(
            world: 'all',
            admin: admin,
            accent: _accent,
            accentBright: _accentBright);
      case 'content':
        return _ContentInsightsTab(
            accent: _accent, accentBright: _accentBright);
      case 'videos':
        return _ContentInsightsTab(
            accent: _accent, accentBright: _accentBright, videosOnly: true);
      case 'module_workshop':
        return _ModuleWorkshopTab(accent: _accent, accentBright: _accentBright);
      case 'push':
        return _PushBroadcastTab(accent: _accent, accentBright: _accentBright);
      case 'audit':
        return _AuditReportsWrapper(
            world: 'all',
            accent: _accent,
            accentBright: _accentBright,
            isRootAdmin: admin.isRootAdmin);
      case 'insights':
        return _InsightsTab(
            accent: _accent, accentBright: _accentBright, admin: admin);
      case 'control':
        return _ControlTab(
            accent: _accent, accentBright: _accentBright, admin: admin);
      case 'system':
        return _SystemTab(
            accent: _accent, accentBright: _accentBright, admin: admin);
      default:
        return const SizedBox.shrink();
    }
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
      case 'videos':
        return _ContentInsightsTab(
            accent: _accent, accentBright: _accentBright, videosOnly: true);
      case 'module_workshop':
        return _ModuleWorkshopTab(accent: _accent, accentBright: _accentBright);
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

class _AdminTabDef {
  final IconData icon;
  final String label;
  final String kind;
  const _AdminTabDef(
      {required this.icon, required this.label, required this.kind});
}
