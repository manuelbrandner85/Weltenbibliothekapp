// v123: Insights Tab -- Live-Counter, Growth, Heatmap, World-Vergleich, Top-Content.
part of '../world_admin_dashboard.dart';

// ═══════════════════════════════════════════════════════════════════════════
// INSIGHTS TAB
// ═══════════════════════════════════════════════════════════════════════════
class _InsightsTab extends StatefulWidget {
  final Color accent, accentBright;
  final AdminState admin;
  const _InsightsTab({required this.accent, required this.accentBright, required this.admin});

  @override
  State<_InsightsTab> createState() => _InsightsTabState();
}

class _InsightsTabState extends State<_InsightsTab> {
  bool _loading = true;
  Map<String, dynamic> _data = {};
  // v124 2026-06-07: Analytics aus dem Uebersicht-Tab nach hier verschoben.
  Map<String, dynamic> _analytics = {};
  // Realtime online-counter channel.
  RealtimeChannel? _channel;
  int _onlineNow = 0;
  final List<String> _activeWorlds = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeOnline();
    // Refresh every 60s to keep charts current.
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await WorldAdminServiceV162.getInsights();
      // Analytics zusaetzlich laden (Nutzer/Nachrichten/Interaktionen 7 Tage).
      Map<String, dynamic> analytics = const {};
      try {
        analytics = await WorldAdminServiceV162.getAnalytics(
          realm: 'all',
          days: 7,
          adminUserId: widget.admin.username,
        );
      } catch (_) {/* analytics optional -- best effort */}
      if (!mounted) return;
      setState(() {
        _data = data;
        _analytics = analytics;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _subscribeOnline() {
    try {
      final fiveMinAgo = DateTime.now().toUtc().subtract(const Duration(minutes: 5));
      _channel = supabase
          .channel('admin-insights-online-${DateTime.now().millisecondsSinceEpoch}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'profiles',
            callback: (payload) async {
              if (!mounted) return;
              // Count rows with last_seen_at > 5 min ago.
              try {
                final res = await supabase
                    .from('profiles')
                    .select('world')
                    .gte('last_seen_at', fiveMinAgo.toIso8601String());
                if (!mounted) return;
                final rows = res as List? ?? [];
                final worlds = rows
                    .map((r) => r['world']?.toString() ?? '')
                    .where((w) => w.isNotEmpty)
                    .toSet()
                    .toList();
                setState(() {
                  _onlineNow = rows.length;
                  _activeWorlds
                    ..clear()
                    ..addAll(worlds);
                });
              } catch (_) {}
            },
          )
          .subscribe();
    } catch (_) {}
  }

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
          // ── Live Online Counter ──────────────────────────────────────
          _SectionHeader(Icons.sensors_rounded, 'Live', widget.accent),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: _InsightCard(
                icon: Icons.circle,
                iconColor: Colors.greenAccent,
                title: 'Jetzt online',
                value: '$_onlineNow',
                subtitle: 'Aktiv in letzten 5 min',
                accent: widget.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InsightCard(
                icon: Icons.public_rounded,
                iconColor: Colors.blueAccent,
                title: 'Aktive Welten',
                value: _activeWorlds.isEmpty ? '–' : _activeWorlds.length.toString(),
                subtitle: _activeWorlds.isEmpty ? 'Keine Daten' : _activeWorlds.join(', '),
                accent: widget.accent,
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Statistiken (aus Uebersicht verschoben) ─────────────────
          _SectionHeader(Icons.analytics_rounded, 'Statistiken', widget.accent),
          const SizedBox(height: 8),
          _AnalyticsSection(
              analytics: _analytics,
              accent: widget.accent,
              accentBright: widget.accentBright),
          const SizedBox(height: 16),

          // ── Growth ──────────────────────────────────────────────────
          _SectionHeader(Icons.trending_up_rounded, 'Wachstum', widget.accent),
          const SizedBox(height: 8),
          _GrowthSection(data: _data, accent: widget.accent, accentBright: widget.accentBright),
          const SizedBox(height: 16),

          // ── Activity Heatmap ─────────────────────────────────────────
          _SectionHeader(Icons.grid_on_rounded, 'Aktivitaets-Heatmap', widget.accent),
          const SizedBox(height: 8),
          _HeatmapSection(data: _data, accent: widget.accent),
          const SizedBox(height: 16),

          // ── World Comparison ────────────────────────────────────────
          _SectionHeader(Icons.compare_arrows_rounded, 'Welten-Vergleich', widget.accent),
          const SizedBox(height: 8),
          _WorldComparisonSection(data: _data, accent: widget.accent, accentBright: widget.accentBright),
          const SizedBox(height: 16),

          // ── Top Content ─────────────────────────────────────────────
          _SectionHeader(Icons.star_rounded, 'Top-Inhalte', widget.accent),
          const SizedBox(height: 8),
          _TopContentSection(data: _data, accent: widget.accent),
          const SizedBox(height: 16),

          // ── Modul-Fortschritt (aus Content verschoben) ──────────────
          // Embed mit fester Hoehe damit die innere TabBar des Progress-
          // Widgets nicht ueber die gesamte Insights-Seite scrollt.
          _SectionHeader(
              Icons.school_rounded, 'Modul-Fortschritt', widget.accent),
          const SizedBox(height: 8),
          SizedBox(
            height: 520,
            child: _ModuleProgressTab(
                accent: widget.accent, accentBright: widget.accentBright),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Analytics section (Statistiken aus Uebersicht) ────────────────────────
class _AnalyticsSection extends StatelessWidget {
  final Map<String, dynamic> analytics;
  final Color accent, accentBright;
  const _AnalyticsSection(
      {required this.analytics,
      required this.accent,
      required this.accentBright});

  int _i(String a, String b) {
    final v = analytics[a] ?? analytics[b];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final totalUsers = _i('totalUsers', 'total_users');
    final newUsers = _i('newUsers', 'new_users');
    final totalMsgs = _i('totalMessages', 'total_messages');
    final interactions = _i('interactions', 'interactions');
    return Column(children: [
      Row(children: [
        Expanded(
            child: _InsightCard(
                icon: Icons.people_rounded,
                iconColor: const Color(0xFF1E88E5),
                title: 'Nutzer gesamt',
                value: '$totalUsers',
                accent: accent)),
        const SizedBox(width: 12),
        Expanded(
            child: _InsightCard(
                icon: Icons.person_add_rounded,
                iconColor: const Color(0xFF43A047),
                title: 'Neu (7 Tage)',
                value: '+$newUsers',
                accent: accent)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
            child: _InsightCard(
                icon: Icons.chat_rounded,
                iconColor: const Color(0xFF8E24AA),
                title: 'Nachrichten',
                value: '$totalMsgs',
                accent: accent)),
        const SizedBox(width: 12),
        Expanded(
            child: _InsightCard(
                icon: Icons.touch_app_rounded,
                iconColor: const Color(0xFFE53935),
                title: 'Interaktionen',
                value: '$interactions',
                accent: accent)),
      ]),
    ]);
  }
}

// ── Growth charts ──────────────────────────────────────────────────────────
class _GrowthSection extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color accent, accentBright;
  const _GrowthSection({required this.data, required this.accent, required this.accentBright});

  @override
  Widget build(BuildContext context) {
    final growth = data['growth'] as Map? ?? {};
    final usersToday = (growth['users_today'] as num?)?.toInt() ?? 0;
    final usersWeek = (growth['users_week'] as num?)?.toInt() ?? 0;
    final totalUsers = (growth['total_users'] as num?)?.toInt() ?? 0;
    final retention7d = (growth['retention_7d'] as num?)?.toDouble() ?? 0.0;
    final dailyNew = growth['daily_new'] as List? ?? [];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: _InsightCard(
          icon: Icons.person_add_rounded, iconColor: Colors.greenAccent,
          title: 'Heute neu', value: '+$usersToday', accent: accent,
        )),
        const SizedBox(width: 12),
        Expanded(child: _InsightCard(
          icon: Icons.calendar_view_week_rounded, iconColor: Colors.blueAccent,
          title: 'Diese Woche', value: '+$usersWeek', accent: accent,
        )),
        const SizedBox(width: 12),
        Expanded(child: _InsightCard(
          icon: Icons.group_rounded, iconColor: Colors.purpleAccent,
          title: 'Gesamt', value: '$totalUsers', accent: accent,
        )),
      ]),
      if (retention7d > 0) ...[
        const SizedBox(height: 8),
        _InsightCard(
          icon: Icons.loop_rounded, iconColor: Colors.orangeAccent,
          title: '7-Tage-Retention',
          value: '${retention7d.toStringAsFixed(1)}%',
          subtitle: 'Nutzer die nach 7 Tagen zurueckkamen',
          accent: accent,
        ),
      ],
      if (dailyNew.isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Neue Nutzer (letzte 7 Tage)',
                style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            _MiniBarChart(items: dailyNew, accent: accent),
          ]),
        ),
      ],
    ]);
  }
}

// ── Heatmap (hour x weekday) ──────────────────────────────────────────────
class _HeatmapSection extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color accent;
  const _HeatmapSection({required this.data, required this.accent});

  @override
  Widget build(BuildContext context) {
    final heatmap = data['heatmap'] as List? ?? [];
    if (heatmap.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('Keine Heatmap-Daten verfuegbar',
            style: TextStyle(color: Colors.white38, fontSize: 12)),
      );
    }
    // Build 7x24 grid from flat list [{weekday, hour, count}].
    final Map<String, int> cells = {};
    int maxVal = 1;
    for (final row in heatmap) {
      final wd = row['weekday']?.toString() ?? '0';
      final h = row['hour']?.toString() ?? '0';
      final c = (row['count'] as num?)?.toInt() ?? 0;
      cells['$wd-$h'] = c;
      if (c > maxVal) maxVal = c;
    }
    const days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const SizedBox(width: 22),
            for (int h = 0; h < 24; h += 3)
              SizedBox(
                width: 24,
                child: Text('${h}h', style: const TextStyle(color: Colors.white38, fontSize: 7)),
              ),
          ]),
          for (int wd = 1; wd <= 7; wd++)
            Row(children: [
              SizedBox(
                width: 22,
                child: Text(days[wd - 1], style: const TextStyle(color: Colors.white38, fontSize: 9)),
              ),
              for (int h = 0; h < 24; h++)
                Builder(builder: (ctx) {
                  final c = cells['$wd-$h'] ?? 0;
                  final alpha = c == 0 ? 0.05 : (c / maxVal).clamp(0.1, 1.0);
                  return Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: alpha),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
            ]),
          const SizedBox(height: 6),
          Row(children: [
            const SizedBox(width: 22),
            const Text('wenig ', style: TextStyle(color: Colors.white30, fontSize: 9)),
            for (double a in [0.1, 0.3, 0.5, 0.75, 1.0])
              Container(
                width: 10, height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: a),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            const Text(' viel', style: TextStyle(color: Colors.white30, fontSize: 9)),
          ]),
        ]),
      ),
    );
  }
}

// ── World Comparison ──────────────────────────────────────────────────────
class _WorldComparisonSection extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color accent, accentBright;
  const _WorldComparisonSection({required this.data, required this.accent, required this.accentBright});

  @override
  Widget build(BuildContext context) {
    final worlds = data['worlds'] as Map? ?? {};
    if (worlds.isEmpty) {
      return _emptyCard('Keine Welten-Daten verfuegbar');
    }
    return Column(
      children: worlds.entries.map((entry) {
        final w = entry.key;
        final info = entry.value as Map? ?? {};
        final users = (info['users'] as num?)?.toInt() ?? 0;
        final active = (info['active_today'] as num?)?.toInt() ?? 0;
        final topTool = info['top_tool']?.toString() ?? '–';
        final topModule = info['top_module']?.toString() ?? '–';
        final wColor = _worldColor(w);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: wColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: wColor.withValues(alpha: 0.25)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(_worldLabel(w), style: TextStyle(color: wColor, fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              Text('$users Nutzer', style: const TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(width: 8),
              Text('$active heute aktiv', style: TextStyle(color: wColor.withValues(alpha: 0.8), fontSize: 11)),
            ]),
            if (topTool != '–') ...[
              const SizedBox(height: 6),
              Text('Top-Tool: $topTool', style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
            if (topModule != '–') ...[
              const SizedBox(height: 2),
              Text('Top-Modul: $topModule', style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ]),
        );
      }).toList(),
    );
  }

  Color _worldColor(String w) => switch (w) {
    'materie' => const Color(0xFFFF7043),
    'energie' => const Color(0xFF42A5F5),
    'vorhang' => const Color(0xFFAB47BC),
    'ursprung' => const Color(0xFF66BB6A),
    _ => Colors.white38,
  };

  String _worldLabel(String w) => switch (w) {
    'materie' => '🌍 Materie',
    'energie' => '✨ Energie',
    'vorhang' => '🌙 Vorhang',
    'ursprung' => '🌱 Ursprung',
    _ => w,
  };

  Widget _emptyCard(String msg) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(12)),
    child: Text(msg, style: const TextStyle(color: Colors.white38, fontSize: 12)),
  );
}

// ── Top Content ───────────────────────────────────────────────────────────
class _TopContentSection extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color accent;
  const _TopContentSection({required this.data, required this.accent});

  @override
  Widget build(BuildContext context) {
    final topArticles = data['top_articles'] as List? ?? [];
    final topVideos = data['top_videos'] as List? ?? [];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (topArticles.isNotEmpty) ...[
        Text('Meist-gelesene Artikel', style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        ...topArticles.take(5).map((a) {
          final m = a as Map;
          return _TopItem(
            label: m['title']?.toString() ?? '–',
            count: (m['views'] as num?)?.toInt() ?? 0,
            unit: 'Aufrufe',
            accent: accent,
          );
        }),
        const SizedBox(height: 12),
      ],
      if (topVideos.isNotEmpty) ...[
        Text('Beliebteste Videos', style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        ...topVideos.take(5).map((v) {
          final m = v as Map;
          return _TopItem(
            label: m['title']?.toString() ?? '–',
            count: (m['plays'] as num?)?.toInt() ?? 0,
            unit: 'Plays',
            accent: accent,
          );
        }),
      ],
      if (topArticles.isEmpty && topVideos.isEmpty)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(12)),
          child: const Text('Noch keine Content-Statistiken verfuegbar',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
        ),
    ]);
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  const _SectionHeader(this.icon, this.label, this.accent);
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: accent, size: 16),
    const SizedBox(width: 6),
    Text(label, style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
  ]);
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String? subtitle;
  final Color accent;
  const _InsightCard({
    required this.icon, required this.iconColor,
    required this.title, required this.value,
    this.subtitle, required this.accent,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white10),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: iconColor, size: 14),
        const SizedBox(width: 5),
        Expanded(child: Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10), overflow: TextOverflow.ellipsis)),
      ]),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      if (subtitle != null) ...[
        const SizedBox(height: 2),
        Text(subtitle!, style: const TextStyle(color: Colors.white38, fontSize: 9), overflow: TextOverflow.ellipsis),
      ],
    ]),
  );
}

class _TopItem extends StatelessWidget {
  final String label;
  final int count;
  final String unit;
  final Color accent;
  const _TopItem({required this.label, required this.count, required this.unit, required this.accent});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis)),
      Text('$count $unit', style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600)),
    ]),
  );
}

// Simple bar chart using just Containers (no fl_chart dependency).
class _MiniBarChart extends StatelessWidget {
  final List items;
  final Color accent;
  const _MiniBarChart({required this.items, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final values = items.map((e) {
      final m = e as Map;
      return (m['count'] as num?)?.toInt() ?? 0;
    }).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return const SizedBox.shrink();
    return SizedBox(
      height: 60,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(items.length, (i) {
          final m = items[i] as Map;
          final count = values[i];
          final label = m['date']?.toString().substring(5) ?? '$i'; // MM-DD
          final frac = count / maxVal;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text('$count', style: TextStyle(color: accent, fontSize: 7)),
                const SizedBox(height: 2),
                Container(
                  height: (40 * frac).clamp(2.0, 40.0),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 2),
                Text(label, style: const TextStyle(color: Colors.white30, fontSize: 7)),
              ]),
            ),
          );
        }),
      ),
    );
  }
}
