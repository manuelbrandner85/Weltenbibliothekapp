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

  // 2026-06-07 Konsolidierung: _syncUsers / _runDiagnose / _runRepair
  // leben jetzt einmalig unter System (system_tab.dart). Uebersicht ist
  // wieder reine Anzeige.
  //
  // _exportActivityCsv lebt nur noch im Audit-Log unter Protokoll
  // (audit_tabs.dart > _AuditLogTab._exportCsv).

  Future<void> _load() async {
    if (!mounted) return;
    try {
      // 2026-06-07: Analytics + Audit-Log nicht mehr hier laden -- leben unter
      // Insights bzw. Protokoll. Hier nur noch die offenen Reports fuer die
      // Moderationsqueue-Card.
      final reportsData =
          await WorldAdminServiceV162.getReports(status: 'open', limit: 1);
      final openReports = reportsData == null
          ? 0
          : ((reportsData['counts'] as Map?)?['open'] as num?)?.toInt() ?? 0;
      if (mounted) {
        setState(() {
          _openReports = openReports;
          _loading = false;
          _loadError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'Uebersicht konnte nicht geladen werden.\n'
              'Tipp: System > Wartung > Diagnose nutzen.';
        });
      }
      if (kDebugMode) debugPrint('❌ Overview load: $e');
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

  // 2026-06-07: _showStatsDetail entfernt -- Statistik-Cards leben jetzt
  // unter Insights.

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: widget.accent));
    }

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
              // 2026-06-07: Sync-Icon entfernt (Wartung lebt unter System).
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

          // 2026-06-07: Statistik-Karten (totalUsers/newUsers/totalMsgs/
          // interactions) leben jetzt unter Insights > Statistiken.
          // Uebersicht ist reine Startseite ohne analytische Cards.

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
          // 2026-06-07: Diagnose-Button raus -- lebt jetzt unter
          // System > Wartung.
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

          // 2026-06-07: Aktivitaets-Heatmap raus -- lebt unter Insights.

          // ── 🟢 Live-Online-Roster ───────────────────────────────
          _SectionLabel('Aktuell online', Icons.bolt_rounded, widget.accent),
          const SizedBox(height: 10),
          _OnlineNowBlock(
              accent: widget.accent, accentBright: widget.accentBright),

          // 2026-06-07: "Letzte Aktionen" + CSV-Export entfernt -- Audit-Log
          // mit CSV-Export lebt einmalig unter Protokoll.

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
