// GLOBAL ADMIN SEARCH: part of world_admin_dashboard library.
//
// Opens a bottom sheet with ONE search field that fans out to:
//   - Users      (username / display_name)
//   - Articles   (title)
//   - Videos     (title)
//   - Audit log  (action / target)
//
// Tapping a result either prefills the corresponding section or navigates
// to that area. All queries are debounced by 300ms and capped per group.
// Reuses existing service methods only -- no new worker endpoints needed.
part of '../world_admin_dashboard.dart';

class _GlobalSearchResult {
  final String group; // 'users' | 'articles' | 'videos' | 'audit'
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const _GlobalSearchResult({
    required this.group,
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
  });
}

Future<void> showGlobalAdminSearch(
  BuildContext context, {
  required Color accent,
  required Color accentBright,
  required void Function(String section, {String? query}) onJump,
}) {
  return showModalBottomSheet<void>(
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
          child: _GlobalSearchSheet(
            accent: accent,
            accentBright: accentBright,
            onJump: onJump,
          ),
        ),
      );
    },
  );
}

class _GlobalSearchSheet extends StatefulWidget {
  final Color accent;
  final Color accentBright;
  final void Function(String section, {String? query}) onJump;
  const _GlobalSearchSheet({
    required this.accent,
    required this.accentBright,
    required this.onJump,
  });

  @override
  State<_GlobalSearchSheet> createState() => _GlobalSearchSheetState();
}

class _GlobalSearchSheetState extends State<_GlobalSearchSheet> {
  final TextEditingController _ctrl = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool _loading = false;
  List<_GlobalSearchResult> _results = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _run(v.trim());
    });
  }

  Future<void> _run(String q) async {
    if (q.length < 2) {
      setState(() {
        _query = q;
        _results = [];
        _loading = false;
      });
      return;
    }
    setState(() {
      _query = q;
      _loading = true;
    });
    final results = <_GlobalSearchResult>[];
    final lower = q.toLowerCase();

    // Run all groups in parallel, each capped + best-effort.
    final futures = await Future.wait([
      _searchUsers(lower),
      _searchArticles(lower),
      _searchVideos(lower),
      _searchAudit(lower),
    ]);

    for (final group in futures) {
      results.addAll(group);
    }
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  Future<List<_GlobalSearchResult>> _searchUsers(String lower) async {
    try {
      final users = await WorldAdminService.getAllUsers();
      final hits = users.where((u) {
        final un = (u.username).toLowerCase();
        final dn = (u.displayName ?? '').toLowerCase();
        return un.contains(lower) || dn.contains(lower);
      }).take(5);
      return hits.map((u) {
        return _GlobalSearchResult(
          group: 'users',
          title: '@${u.username}',
          subtitle: u.displayName ?? u.role,
          icon: Icons.person_rounded,
          onTap: () {
            Navigator.of(context).pop();
            widget.onJump('users', query: u.username);
          },
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<_GlobalSearchResult>> _searchArticles(String lower) async {
    try {
      final list = await WorldAdminServiceV162.getArticles();
      if (list == null) return const [];
      final hits = list.where((a) {
        final t = (a['title'] as String? ?? '').toLowerCase();
        return t.contains(lower);
      }).take(5);
      return hits.map((a) {
        return _GlobalSearchResult(
          group: 'articles',
          title: a['title'] as String? ?? '(ohne Titel)',
          subtitle: a['world'] as String?,
          icon: Icons.article_rounded,
          onTap: () {
            Navigator.of(context).pop();
            widget.onJump('content');
          },
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<_GlobalSearchResult>> _searchVideos(String lower) async {
    try {
      final list = await WorldAdminServiceV162.getArchiveVideos();
      if (list == null) return const [];
      final hits = list.where((v) {
        final t = (v['title'] as String? ?? '').toLowerCase();
        return t.contains(lower);
      }).take(5);
      return hits.map((v) {
        return _GlobalSearchResult(
          group: 'videos',
          title: v['title'] as String? ?? '(ohne Titel)',
          subtitle: v['world'] as String?,
          icon: Icons.play_circle_outline_rounded,
          onTap: () {
            Navigator.of(context).pop();
            widget.onJump('videos');
          },
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<_GlobalSearchResult>> _searchAudit(String lower) async {
    try {
      final list = await WorldAdminServiceV162.getAuditLogFiltered(
        action: lower,
        limit: 5,
      );
      return list.map((e) {
        final action = e['action'] as String? ?? 'unknown';
        final actor = e['actor_username'] as String? ??
            e['admin_username'] as String? ??
            '?';
        return _GlobalSearchResult(
          group: 'audit',
          title: action,
          subtitle: 'durch @$actor',
          icon: Icons.history_rounded,
          onTap: () {
            Navigator.of(context).pop();
            widget.onJump('audit');
          },
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  Map<String, List<_GlobalSearchResult>> get _grouped {
    final map = <String, List<_GlobalSearchResult>>{};
    for (final r in _results) {
      map.putIfAbsent(r.group, () => []).add(r);
    }
    return map;
  }

  String _groupLabel(String group) {
    switch (group) {
      case 'users':
        return 'Nutzer';
      case 'articles':
        return 'Artikel';
      case 'videos':
        return 'Videos';
      case 'audit':
        return 'Audit-Log';
      default:
        return group;
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _ctrl,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            onChanged: _onChanged,
            decoration: InputDecoration(
              hintText: 'Suche nach Nutzer, Artikel, Video, Audit…',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded, color: widget.accentBright),
              suffixIcon: _loading
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: widget.accentBright,
                        ),
                      ),
                    )
                  : (_query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              color: Colors.white54, size: 18),
                          onPressed: () {
                            _ctrl.clear();
                            _run('');
                          },
                        )
                      : null),
              filled: true,
              fillColor: const Color(0xFF14141F),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: widget.accent.withValues(alpha: 0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: widget.accent.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: widget.accentBright, width: 1.5),
              ),
            ),
          ),
        ),
        const Divider(color: Colors.white10, height: 1),
        Expanded(
          child: _query.length < 2
              ? Center(
                  child: Text(
                    'Mindestens 2 Zeichen eingeben',
                    style:
                        TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                )
              : _results.isEmpty && !_loading
                  ? const Center(
                      child: Text('Keine Treffer',
                          style: TextStyle(color: Colors.white38)),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: grouped.entries.expand((entry) {
                        return <Widget>[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                            child: Text(
                              _groupLabel(entry.key),
                              style: TextStyle(
                                color: widget.accentBright,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          ...entry.value.map((r) => ListTile(
                                dense: true,
                                leading:
                                    Icon(r.icon, color: widget.accent, size: 20),
                                title: Text(r.title,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 14)),
                                subtitle: r.subtitle == null
                                    ? null
                                    : Text(r.subtitle!,
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12)),
                                onTap: r.onTap,
                              )),
                        ];
                      }).toList(),
                    ),
        ),
      ],
    );
  }
}
