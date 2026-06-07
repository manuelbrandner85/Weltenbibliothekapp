// HUB LANDING: part of world_admin_dashboard library.
// Clean entry/organization that reuses all existing section widgets.
part of '../world_admin_dashboard.dart';

// ═════════════════════════════════════════════════════════════════════════════
// ADMIN HUB – Clean landing surface
// Role-filtered area cards + global user search + "Zu erledigen" badge chips.
// All cards/chips simply switch the active section in the parent State, which
// then renders the existing (unchanged) section widgets.
// ═════════════════════════════════════════════════════════════════════════════

/// Definition of a single area card on the hub.
/// Plain class (no Dart 3 named record types -- those crash dart2js).
class _AdminAreaDef {
  final IconData icon;
  final String title;
  final String subtitle;
  final String section;
  final int badge;
  const _AdminAreaDef({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.section,
    this.badge = 0,
  });
}

class _AdminHub extends StatefulWidget {
  final String? role;
  final Color accent;
  final Color accentBright;

  /// Open a section (key matches [_WorldAdminDashboardState._sectionBody]).
  final void Function(String section) onOpen;

  /// Run a global user search -> opens Users section with the query.
  final void Function(String query) onSearch;

  /// Open the global search bottom sheet (users + content + audit).
  final VoidCallback onOpenGlobalSearch;

  // Best-effort badge counts (0 = hide number).
  final int openReports;
  final int pendingUsernameRequests;
  final int failedPushes;
  // v123: pending content + maintenance-mode flag.
  final int pendingVideos;
  final bool maintenanceActive;

  const _AdminHub({
    required this.role,
    required this.accent,
    required this.accentBright,
    required this.onOpen,
    required this.onSearch,
    required this.onOpenGlobalSearch,
    this.openReports = 0,
    this.pendingUsernameRequests = 0,
    this.failedPushes = 0,
    this.pendingVideos = 0,
    this.maintenanceActive = false,
  });

  @override
  State<_AdminHub> createState() => _AdminHubState();
}

class _AdminHubState extends State<_AdminHub> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Build the role-filtered list of area cards.
  List<_AdminAreaDef> _areas() {
    final role = widget.role;
    final areas = <_AdminAreaDef>[];

    if (AppRoles.canViewUserList(role)) {
      areas.add(const _AdminAreaDef(
        icon: Icons.people_rounded,
        title: 'Nutzer',
        subtitle: 'Bannen, Rollen, XP, Notizen',
        section: 'users',
      ));
    }
    if (AppRoles.canDeleteMessages(role) || AppRoles.canViewModTools(role)) {
      areas.add(_AdminAreaDef(
        icon: Icons.gpp_good_rounded,
        title: 'Moderation',
        subtitle: 'Chat & Meldungen',
        section: 'moderation',
        badge: widget.openReports,
      ));
    }
    if (AppRoles.canCreateAnnouncements(role)) {
      areas.add(_AdminAreaDef(
        icon: Icons.notifications_active_rounded,
        title: 'Mitteilungen',
        subtitle: 'Push-Broadcasts & Verlauf',
        section: 'push',
        badge: widget.failedPushes,
      ));
    }
    if (AppRoles.canEditContent(role)) {
      areas.add(const _AdminAreaDef(
        icon: Icons.menu_book_rounded,
        title: 'Inhalte',
        subtitle: 'Module, Artikel, Videos',
        section: 'content',
      ));
      // v128: KI-gestuetzte Modul-Werkstatt -- Module erstellen, erweitern,
      // KI-Vorschlaege annehmen. Eigene Hub-Karte damit sie auffindbar ist.
      areas.add(const _AdminAreaDef(
        icon: Icons.auto_awesome,
        title: 'Modul-Werkstatt',
        subtitle: 'Module per KI erstellen, erweitern & Vorschlaege',
        section: 'module_workshop',
      ));
    }
    if (AppRoles.isAdmin(role)) {
      areas.add(const _AdminAreaDef(
        icon: Icons.insights_rounded,
        title: 'Insights',
        subtitle: 'Live-Nutzer, Wachstum, Heatmap',
        section: 'insights',
      ));
    }
    if (AppRoles.canCreateAnnouncements(role)) {
      areas.add(const _AdminAreaDef(
        icon: Icons.tune_rounded,
        title: 'Steuerung',
        subtitle: 'Feature-Flags, Ankuendigungen, Freigaben',
        section: 'control',
      ));
    }
    if (AppRoles.isAdmin(role)) {
      areas.add(const _AdminAreaDef(
        icon: Icons.monitor_heart_rounded,
        title: 'System',
        subtitle: 'Health, Sync, Diagnose',
        section: 'system',
      ));
    }
    if (AppRoles.canViewAuditLog(role) || AppRoles.isAdmin(role)) {
      areas.add(_AdminAreaDef(
        icon: Icons.history_rounded,
        title: 'Protokoll',
        subtitle: 'Audit-Log & Antraege',
        section: 'audit',
        badge: widget.pendingUsernameRequests,
      ));
    }
    return areas;
  }

  @override
  Widget build(BuildContext context) {
    final areas = _areas();
    return Container(
      color: const Color(0xFF0A0A0A),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchField(),
            const SizedBox(height: 16),
            _buildBadgeRow(),
            const SizedBox(height: 20),
            LayoutBuilder(builder: (context, constraints) {
              // Two columns on wide screens, one on narrow.
              final crossAxisCount = constraints.maxWidth >= 520 ? 2 : 1;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: crossAxisCount == 1 ? 3.6 : 1.7,
                children: areas.map(_buildAreaCard).toList(),
              );
            }),
            const SizedBox(height: 16),
            _buildOverviewLink(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Row(children: [
      Expanded(
        child: TextField(
          controller: _searchCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          textInputAction: TextInputAction.search,
          onSubmitted: (v) {
            final q = v.trim();
            widget.onSearch(q);
          },
          decoration: InputDecoration(
            hintText: 'Nutzer suchen (@name)…',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: widget.accentBright),
            filled: true,
            fillColor: const Color(0xFF14141F),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: widget.accent.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: widget.accent.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: widget.accentBright, width: 1.5),
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Material(
        color: const Color(0xFF14141F),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: widget.onOpenGlobalSearch,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: widget.accentBright.withValues(alpha: 0.5)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.travel_explore_rounded,
                  size: 18, color: widget.accentBright),
              const SizedBox(width: 6),
              Text('Global',
                  style: TextStyle(
                      color: widget.accentBright,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _buildBadgeRow() {
    // Only show chips that are relevant to the role + have a positive count.
    final role = widget.role;
    final chips = <Widget>[];

    if ((AppRoles.canDeleteMessages(role) || AppRoles.canViewModTools(role)) &&
        widget.openReports > 0) {
      chips.add(_buildBadgeChip(
        icon: Icons.flag_rounded,
        label: 'Meldungen',
        count: widget.openReports,
        onTap: () => widget.onOpen('moderation'),
      ));
    }
    if ((AppRoles.canViewAuditLog(role) || AppRoles.isAdmin(role)) &&
        widget.pendingUsernameRequests > 0) {
      chips.add(_buildBadgeChip(
        icon: Icons.badge_rounded,
        label: 'Username-Antraege',
        count: widget.pendingUsernameRequests,
        onTap: () => widget.onOpen('audit'),
      ));
    }
    if (AppRoles.canCreateAnnouncements(role) && widget.failedPushes > 0) {
      chips.add(_buildBadgeChip(
        icon: Icons.error_outline_rounded,
        label: 'Push-Fehler',
        count: widget.failedPushes,
        onTap: () => widget.onOpen('push'),
      ));
    }
    // v123: pending content videos -> jump to Steuerung (content-queue panel).
    if (AppRoles.canCreateAnnouncements(role) && widget.pendingVideos > 0) {
      chips.add(_buildBadgeChip(
        icon: Icons.play_circle_outline_rounded,
        label: 'Videos pruefen',
        count: widget.pendingVideos,
        onTap: () => widget.onOpen('control'),
      ));
    }
    // v123: maintenance flag active -> red warning chip.
    if (AppRoles.canCreateAnnouncements(role) && widget.maintenanceActive) {
      chips.add(_buildBadgeChip(
        icon: Icons.warning_amber_rounded,
        label: 'Wartung aktiv',
        count: 1,
        warning: true,
        onTap: () => widget.onOpen('control'),
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Zu erledigen',
            style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
      ],
    );
  }

  Widget _buildBadgeChip({
    required IconData icon,
    required String label,
    required int count,
    required VoidCallback onTap,
    bool warning = false,
  }) {
    final base = warning ? Colors.redAccent : widget.accent;
    final bright = warning ? Colors.redAccent.shade100 : widget.accentBright;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: base.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: base.withValues(alpha: 0.4)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: bright),
            const SizedBox(width: 6),
            Text(warning ? label : '$label ($count)',
                style: TextStyle(
                    color: bright,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }

  Widget _buildAreaCard(_AdminAreaDef area) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => widget.onOpen(area.section),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF14141F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.accent.withValues(alpha: 0.2)),
          ),
          child: Stack(children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      widget.accent.withValues(alpha: 0.25),
                      widget.accentBright.withValues(alpha: 0.15),
                    ]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Icon(area.icon, color: widget.accentBright, size: 24),
                ),
                const SizedBox(height: 12),
                Text(area.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(area.subtitle,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
            if (area.badge > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${area.badge}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _buildOverviewLink() {
    // Secondary entry: keeps the overview tab's diagnose/repair/sync/heatmap/
    // CSV/online-roster functions reachable without competing with the areas.
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => widget.onOpen('overview'),
        icon: Icon(Icons.dashboard_rounded,
            size: 18, color: widget.accentBright),
        label: Text('Uebersicht & Diagnose',
            style: TextStyle(
                color: widget.accentBright,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MODERATION HUB – two sub-tabs reusing existing widgets.
//  - "Chat"      -> _ChatModerationTab (live chat moderation)
//  - "Meldungen" -> _AuditReportsWrapper (existing reports inbox)
//
// Choice for "Meldungen": _ModerationQueueScreen builds its OWN Scaffold+AppBar
// (moderation_queue_screen.dart:58), so embedding it inside a TabBarView would
// produce a double header. _AuditReportsWrapper is the lowest-risk reuse -- it
// already hosts the reports/flags inbox without a nested Scaffold, compiles
// cleanly, and preserves the moderation queue function.
// ═════════════════════════════════════════════════════════════════════════════
class _ModerationHub extends StatelessWidget {
  final String world;
  final AdminState admin;
  final Color accent;
  final Color accentBright;
  const _ModerationHub({
    required this.world,
    required this.admin,
    required this.accent,
    required this.accentBright,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(children: [
        Container(
          color: const Color(0xFF0D0D1A),
          child: TabBar(
            indicatorColor: accent,
            labelColor: accentBright,
            unselectedLabelColor: Colors.white38,
            labelStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(
                  icon: Icon(Icons.chat_bubble_rounded, size: 16),
                  text: 'Chat'),
              Tab(icon: Icon(Icons.flag_rounded, size: 16), text: 'Meldungen'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(children: [
            _ChatModerationTab(
                world: world,
                admin: admin,
                accent: accent,
                accentBright: accentBright),
            // Reports-Inbox lebt direkt unter Moderation -- KEIN
            // _AuditReportsWrapper hier mehr, damit Audit-Log und
            // Username-Antraege nicht doppelt erscheinen (die liegen unter
            // Protokoll). 2026-06-07 Konsolidierung.
            _ReportsInboxTab(
              accent: accent,
              accentBright: accentBright,
              isRootAdmin: admin.isRootAdmin,
              onChanged: () {},
            ),
          ]),
        ),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SHARED CONFIRM HELPER
// ═════════════════════════════════════════════════════════════════════════════

/// Shared confirmation dialog for destructive admin actions.
/// Returns the entered reason if confirmed, or null if cancelled.
/// Provided for consistency for future/hub actions; existing call sites are
/// intentionally left untouched (out of scope).
Future<String?> showAdminConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Bestaetigen',
  bool requireReason = false,
  Color accent = const Color(0xFFCE93D8),
}) async {
  final reasonCtrl = TextEditingController();
  final result = await showDialog<String?>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setLocal) {
        return AlertDialog(
          backgroundColor: const Color(0xFF14141F),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text(title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message,
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
              if (requireReason) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: reasonCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 2,
                  onChanged: (_) => setLocal(() {}),
                  decoration: InputDecoration(
                    hintText: 'Begruendung (Pflicht)…',
                    hintStyle:
                        const TextStyle(color: Colors.white38, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF0A0A0A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: accent.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: accent.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: accent, width: 1.5),
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Abbrechen',
                  style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.black,
              ),
              onPressed: (requireReason && reasonCtrl.text.trim().isEmpty)
                  ? null
                  : () => Navigator.of(ctx)
                      .pop(reasonCtrl.text.trim().isEmpty
                          ? ''
                          : reasonCtrl.text.trim()),
              child: Text(confirmLabel),
            ),
          ],
        );
      });
    },
  );
  reasonCtrl.dispose();
  return result;
}
