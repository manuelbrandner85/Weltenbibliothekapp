// GENERATED SPLIT (TEIL 1B): part of world_admin_dashboard library.
// No logic changes -- structural extraction only.
part of '../world_admin_dashboard.dart';

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
