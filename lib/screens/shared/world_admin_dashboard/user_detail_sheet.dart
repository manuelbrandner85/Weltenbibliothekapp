// GENERATED SPLIT (TEIL 1B): part of world_admin_dashboard library.
// No logic changes -- structural extraction only.
part of '../world_admin_dashboard.dart';

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

        // v124: Sensitive actions -- root_admin only.
        if (widget.isRootAdmin) ...[
          const SizedBox(height: 18),
          _SectionLabel('Sensitive Aktionen (Root-Admin)',
              Icons.security_rounded, Colors.redAccent),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.visibility_rounded,
                    color: Colors.redAccent, size: 16),
                label: const Text('Als Nutzer ansehen',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                onPressed: () => showImpersonationSheet(
                  context,
                  user: widget.user,
                  accent: widget.accent,
                  accentBright: widget.accentBright,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.amber),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.devices_rounded,
                    color: Colors.amber, size: 16),
                label: const Text('Verknuepfte Konten',
                    style: TextStyle(color: Colors.amber, fontSize: 12)),
                onPressed: () => showLinkedAccountsSheet(
                  context,
                  user: widget.user,
                  accent: widget.accent,
                  accentBright: widget.accentBright,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          const Text(
            'Jeder Klick wird im Audit-Log erfasst. Snapshot ist schreibgeschuetzt.',
            style: TextStyle(color: Colors.white38, fontSize: 10),
          ),
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
