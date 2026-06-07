// v124: Sensitive Admin Sheets -- Impersonation + Linked Accounts.
// Both are root_admin only and trigger a Worker audit entry on open.
// Read-only views; no destructive actions.
part of '../world_admin_dashboard.dart';

// ═════════════════════════════════════════════════════════════════════════════
// IMPERSONATION SHEET -- "View as User"
// Pre-loaded snapshot. Red banner indicates read-only mode.
// Audit log on every open via WorldAdminServiceV162.startImpersonation().
// ═════════════════════════════════════════════════════════════════════════════
Future<void> showImpersonationSheet(
  BuildContext context, {
  required WorldUser user,
  required Color accent,
  required Color accentBright,
}) async {
  // Step 1: audit BEFORE we render the data. Failing here means root-admin
  // role couldn't be verified -- we still abort, never silently allow.
  final ok = await WorldAdminServiceV162.startImpersonation(
    targetUserId: user.userId,
  );
  if (!context.mounted) return;
  if (!ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vorgang nicht erlaubt (nur Root-Admin).'),
        backgroundColor: Colors.redAccent,
      ),
    );
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0E0E18),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final mq = MediaQuery.of(ctx);
      return Padding(
        padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
        child: FractionallySizedBox(
          heightFactor: 0.88,
          child: _ImpersonationView(
            user: user,
            accent: accent,
            accentBright: accentBright,
          ),
        ),
      );
    },
  );
}

class _ImpersonationView extends StatefulWidget {
  final WorldUser user;
  final Color accent;
  final Color accentBright;
  const _ImpersonationView({
    required this.user,
    required this.accent,
    required this.accentBright,
  });

  @override
  State<_ImpersonationView> createState() => _ImpersonationViewState();
}

class _ImpersonationViewState extends State<_ImpersonationView> {
  Map<String, dynamic>? _snap;
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
    final data = await WorldAdminServiceV162
        .getImpersonationSnapshot(widget.user.userId);
    if (!mounted) return;
    if (data == null) {
      setState(() {
        _loading = false;
        _error = 'Snapshot konnte nicht geladen werden.';
      });
    } else {
      setState(() {
        _snap = data;
        _loading = false;
      });
    }
  }

  String _fmt(dynamic v) {
    if (v == null) return '-';
    try {
      final dt = DateTime.parse(v.toString()).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Drag handle
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Red read-only banner -- visible at all times.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.redAccent.withValues(alpha: 0.18),
          child: Row(children: [
            const Icon(Icons.visibility_rounded,
                color: Colors.redAccent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Du betrachtest @${widget.user.username} - SCHREIBGESCHUETZT',
                style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded,
                  color: Colors.white54, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ]),
        ),
        const Divider(color: Colors.white10, height: 1),
        Expanded(
          child: _loading
              ? Center(
                  child: CircularProgressIndicator(color: widget.accent),
                )
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Colors.redAccent, size: 36),
                          const SizedBox(height: 8),
                          Text(_error!,
                              style:
                                  const TextStyle(color: Colors.white54)),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _load,
                            child: Text('Erneut versuchen',
                                style: TextStyle(color: widget.accent)),
                          ),
                        ],
                      ),
                    )
                  : _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final activity = (_snap?['activity'] as List?) ?? const [];
    final prefs = (_snap?['prefs'] as Map?) ?? const {};
    final modules = (_snap?['modules'] as List?) ?? const [];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Header: who am I viewing?
        Row(children: [
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
        ]),
        const SizedBox(height: 18),

        // Activity (most recent first)
        _SensSectionLabel('Aktivitaet (${activity.length})',
            Icons.timeline_rounded, widget.accentBright),
        const SizedBox(height: 8),
        if (activity.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Keine Aktivitaeten.',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
          )
        else
          ...activity.take(20).map((a) {
            final m = a as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF14141F),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                Icon(Icons.chevron_right_rounded,
                    color: widget.accent.withValues(alpha: 0.5), size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${m['kind'] ?? '-'} - ${m['label'] ?? ''}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Text(_fmt(m['created_at']),
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 10)),
              ]),
            );
          }),
        const SizedBox(height: 16),

        // Notification prefs / locale / xp
        _SensSectionLabel(
            'Profil-Einstellungen', Icons.tune_rounded, widget.accentBright),
        const SizedBox(height: 8),
        _kv('XP', '${prefs['xp'] ?? '-'}'),
        _kv('Welt', prefs['world']?.toString() ?? '-'),
        _kv('Mitglied seit', _fmt(prefs['created_at'])),
        _kv('Zuletzt gesehen', _fmt(prefs['last_seen_at'])),
        const SizedBox(height: 16),

        // Modules
        _SensSectionLabel('Module (${modules.length})',
            Icons.school_rounded, widget.accentBright),
        const SizedBox(height: 8),
        if (modules.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Kein Fortschritt.',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
          )
        else
          ...modules.take(10).map((m) {
            final map = m as Map<String, dynamic>;
            final pct =
                ((map['progress_percent'] as num?)?.toInt() ?? 0).clamp(0, 100);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                          map['module_code']?.toString() ?? '-',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                        ),
                      ),
                      Text('$pct%',
                          style: TextStyle(
                              color: widget.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: pct / 100.0,
                        minHeight: 4,
                        backgroundColor: Colors.white12,
                        valueColor:
                            AlwaysStoppedAnimation(widget.accentBright),
                      ),
                    ),
                  ]),
            );
          }),
      ],
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(
          width: 140,
          child: Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LINKED ACCOUNTS SHEET -- IP/Device fingerprint matches
// Pseudonymous matches only; no raw IPs shown. DSGVO notice prominent.
// Audit-logged on every query (worker side).
// ═════════════════════════════════════════════════════════════════════════════
Future<void> showLinkedAccountsSheet(
  BuildContext context, {
  required WorldUser user,
  required Color accent,
  required Color accentBright,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0E0E18),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final mq = MediaQuery.of(ctx);
      return Padding(
        padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
        child: FractionallySizedBox(
          heightFactor: 0.85,
          child: _LinkedAccountsView(
            user: user,
            accent: accent,
            accentBright: accentBright,
          ),
        ),
      );
    },
  );
}

class _LinkedAccountsView extends StatefulWidget {
  final WorldUser user;
  final Color accent;
  final Color accentBright;
  const _LinkedAccountsView({
    required this.user,
    required this.accent,
    required this.accentBright,
  });

  @override
  State<_LinkedAccountsView> createState() => _LinkedAccountsViewState();
}

class _LinkedAccountsViewState extends State<_LinkedAccountsView> {
  Map<String, dynamic>? _data;
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
    final data = await WorldAdminServiceV162.getLinkedAccounts(widget.user.userId);
    if (!mounted) return;
    if (data == null) {
      setState(() {
        _loading = false;
        _error = 'Abfrage fehlgeschlagen (Root-Admin erforderlich).';
      });
    } else {
      setState(() {
        _data = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final linked = (_data?['linked'] as List?) ?? const [];
    final ownSessions = (_data?['own_sessions'] as num?)?.toInt() ?? 0;
    return Column(children: [
      Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      // DSGVO notice (always shown)
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: Colors.amber.withValues(alpha: 0.12),
        child: Row(children: [
          const Icon(Icons.privacy_tip_rounded,
              color: Colors.amber, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'DSGVO-Hinweis: Pseudonyme Hash-Werte, keine Klartext-IPs. '
              'Aufbewahrung 90 Tage. Jede Abfrage wird im Audit-Log protokolliert.',
              style: TextStyle(
                  color: Colors.amber.shade100,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                color: Colors.white54, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ]),
      ),
      const Divider(color: Colors.white10, height: 1),
      // Header
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Row(children: [
          Icon(Icons.devices_rounded, color: widget.accentBright, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Verknuepfte Konten - @${widget.user.username}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded,
                color: widget.accentBright, size: 18),
            onPressed: _load,
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Text(
            '$ownSessions eigene Sessions in 90d',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const Spacer(),
          if (!_loading && _error == null)
            Text(
              '${linked.length} Treffer',
              style: TextStyle(
                  color: widget.accentBright,
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
        ]),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: widget.accent))
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 13)),
                    ),
                  )
                : linked.isEmpty
                    ? const Center(
                        child: Text(
                          'Keine weiteren Konten mit gleichem Geraete-Fingerprint.',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: linked.length,
                        itemBuilder: (ctx, i) {
                          final m =
                              Map<String, dynamic>.from(linked[i] as Map);
                          return _LinkedTile(
                            data: m,
                            accent: widget.accent,
                            accentBright: widget.accentBright,
                          );
                        },
                      ),
      ),
    ]);
  }
}

class _LinkedTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color accent;
  final Color accentBright;
  const _LinkedTile({
    required this.data,
    required this.accent,
    required this.accentBright,
  });

  String _fmt(dynamic v) {
    if (v == null) return '-';
    try {
      final dt = DateTime.parse(v.toString()).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = data['username'] as String? ?? '(unbekannt)';
    final displayName = data['display_name'] as String?;
    final role = data['role'] as String? ?? 'user';
    final emoji = data['avatar_emoji'] as String?;
    final sharedIp = (data['shared_ip_count'] as num?)?.toInt() ?? 0;
    final sharedUa = (data['shared_ua_count'] as num?)?.toInt() ?? 0;
    final hits = (data['hit_count'] as num?)?.toInt() ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF14141F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: accent.withValues(alpha: 0.15),
                child: Text(
                  emoji?.isNotEmpty == true
                      ? emoji!
                      : username.isEmpty ? '?' : username[0].toUpperCase(),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName?.isNotEmpty == true ? displayName! : username,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      Row(children: [
                        Text('@$username',
                            style: TextStyle(color: accent, fontSize: 11)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(role,
                              style: TextStyle(
                                  color: accentBright,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ]),
                    ]),
              ),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              _Pill(
                  icon: Icons.wifi_rounded,
                  label: 'IP-Hash: $sharedIp',
                  color: accentBright),
              _Pill(
                  icon: Icons.smartphone_rounded,
                  label: 'UA-Hash: $sharedUa',
                  color: accentBright),
              _Pill(
                  icon: Icons.repeat_rounded,
                  label: '$hits Treffer',
                  color: accentBright),
              _Pill(
                  icon: Icons.access_time_rounded,
                  label: 'zuletzt ${_fmt(data['last_seen'])}',
                  color: Colors.white54),
            ]),
          ]),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Pill(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label,
            style:
                TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// Shared section label (sensitive sheets only -- own copy to avoid coupling).
class _SensSectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _SensSectionLabel(this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: color, size: 14),
      const SizedBox(width: 6),
      Text(label,
          style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4)),
    ]);
  }
}
