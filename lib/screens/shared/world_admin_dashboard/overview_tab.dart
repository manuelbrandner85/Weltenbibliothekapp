// GENERATED SPLIT (TEIL 1B): part of world_admin_dashboard library.
// No logic changes -- structural extraction only.
part of '../world_admin_dashboard.dart';

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

          // ── Rollen-Hinweis: was darf welche Rolle? ──────────────────
          _RoleGuideCard(
            currentRole: widget.admin.isRootAdmin
                ? 'root_admin'
                : (widget.admin.role ?? 'admin'),
            accent: widget.accent,
            accentBright: widget.accentBright,
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
// ROLLEN-HINWEIS  ·  Was darf welche Rolle im Admin-Dashboard?
// ═════════════════════════════════════════════════════════════════════════════
// Quelle der Wahrheit ist AppRoles (lib/core/constants/roles.dart). Diese
// Karte fasst die Capability-Checks benutzerfreundlich zusammen und hebt die
// Rolle des aktuell eingeloggten Admins hervor. Aufklappbar, default zu.
class _RoleGuideCard extends StatefulWidget {
  final String currentRole;
  final Color accent, accentBright;
  const _RoleGuideCard({
    required this.currentRole,
    required this.accent,
    required this.accentBright,
  });

  @override
  State<_RoleGuideCard> createState() => _RoleGuideCardState();
}

class _RoleGuideCardState extends State<_RoleGuideCard> {
  bool _expanded = false;

  // Statische Rollen-Beschreibungen (abgeleitet aus AppRoles-Logik).
  static const List<Map<String, Object>> _roles = [
    {
      'key': 'user',
      'emoji': '👤',
      'name': 'Benutzer',
      'summary': 'Normale App-Nutzung, keine Admin-Rechte.',
      'can': <String>[],
      'cannot': <String>['Kein Zugriff auf das Admin-Dashboard'],
    },
    {
      'key': 'moderator',
      'emoji': '🧹',
      'name': 'Moderator',
      'summary': 'Community-Aufsicht: Chat + Nutzer-Maßnahmen.',
      'can': <String>[
        'Nutzer sperren / entsperren',
        'Verwarnen (3 Strikes -> Auto-Ban)',
        'Bereiche einschränken (Chat/Live/XP)',
        'Chat-Nachrichten löschen + anpinnen',
        'Voice-Moderation (Kick/Mute)',
        'Interne Notizen + Nutzerliste sehen',
      ],
      'cannot': <String>[
        'Keine Rollen ändern',
        'Kein XP vergeben',
        'Nutzer nicht löschen',
        'Keine Inhalte bearbeiten',
      ],
    },
    {
      'key': 'content_editor',
      'emoji': '✍️',
      'name': 'Content-Editor',
      'summary': 'Inhalte pflegen, kein Nutzer-Management.',
      'can': <String>[
        'Tabs / Tools / Marker / Medien verwalten',
        'Module + Versionen + Feature-Flags',
        'Inhalte veröffentlichen + Changelog',
        'Sandbox nutzen',
      ],
      'cannot': <String>[
        'Nutzer nicht sperren/verwarnen',
        'Keine Rollen ändern',
        'Nutzer nicht löschen',
      ],
    },
    {
      'key': 'admin',
      'emoji': '🛡️',
      'name': 'Administrator',
      'summary': 'Moderator-Rechte + XP, Rollen, Audit.',
      'can': <String>[
        'Alle Moderator-Rechte',
        'XP vergeben / abziehen',
        'Rollen ändern bis Moderator / Content-Editor',
        'Modul-Freischaltungen (Overrides)',
        'Ankündigungen + Audit-Log einsehen',
        'Profil-Sync auslösen',
      ],
      'cannot': <String>[
        'Nutzer nicht endgültig löschen',
        'Keine Admin-/Root-Rolle vergeben',
      ],
    },
    {
      'key': 'root_admin',
      'emoji': '👑',
      'name': 'Root-Admin',
      'summary': 'Vollzugriff auf alles.',
      'can': <String>[
        'Alle Admin- + Content-Editor-Rechte',
        'Nutzer endgültig löschen (Hard-Delete)',
        'Rollen bis Admin / Root-Admin vergeben',
        'System-Verwaltung komplett',
      ],
      'cannot': <String>[],
    },
  ];

  bool _isCurrent(String key) {
    final r = widget.currentRole.replaceAll('-', '_');
    return r == key || (key == 'root_admin' && r == 'root_admin');
  }

  @override
  Widget build(BuildContext context) {
    final current = _roles.firstWhere(
      (r) => _isCurrent(r['key'] as String),
      orElse: () => _roles[3], // fallback: admin
    );
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Header (immer sichtbar, toggelt Expand)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.shield_moon_rounded,
                      color: widget.accent, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rollen & Rechte',
                          style: TextStyle(
                              color: widget.accentBright,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                        'Deine Rolle: ${current['emoji']} ${current['name']}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: Colors.white38,
                ),
              ]),
            ),
          ),
          if (_expanded) ...[
            const Divider(color: Colors.white10, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
              child: Column(
                children: _roles
                    .map((r) => _buildRoleRow(r, _isCurrent(r['key'] as String)))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleRow(Map<String, Object> r, bool isCurrent) {
    final can = (r['can'] as List).cast<String>();
    final cannot = (r['cannot'] as List).cast<String>();
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrent
            ? widget.accent.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? widget.accent.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.07),
          width: isCurrent ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('${r['emoji']} ${r['name']}',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            if (isCurrent) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.accent.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('DU',
                    style: TextStyle(
                        color: widget.accentBright,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5)),
              ),
            ],
          ]),
          const SizedBox(height: 3),
          Text(r['summary'] as String,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 8),
          ...can.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.check_rounded,
                      color: Color(0xFF43A047), size: 13),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(c,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11.5, height: 1.3)),
                  ),
                ]),
              )),
          ...cannot.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.close_rounded,
                      color: Colors.red.withValues(alpha: 0.7), size: 13),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(c,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11.5,
                            height: 1.3)),
                  ),
                ]),
              )),
        ],
      ),
    );
  }
}
