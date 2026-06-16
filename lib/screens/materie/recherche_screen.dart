/// Recherche-Hub -- tabbed overview screen for the Materie Recherche tab.
///
/// Tab 0: KaninchenbauScreen (deep research engine)
/// Tab 1: Verlauf -- card list of recent search-history entries (swipe to
///         delete, tap to replay)
/// Tab 2: Statistiken -- fl_chart BarChart with 7 / 30-day toggle
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/search_history.dart';
import '../../services/search_history_service.dart';
import '../../widgets/recherche_card.dart';
import '../../widgets/recherche_result_widget.dart';
import 'kaninchenbau/kaninchenbau_screen.dart';

// Materie accent / dark-background
const _kAccent = Color(0xFF2979FF);
const _kBg = Color(0xFF04080F);
const _kSurface = Color(0xFF0C0C1A);

class RechercheScreen extends StatefulWidget {
  const RechercheScreen({super.key});

  @override
  State<RechercheScreen> createState() => _RechercheScreenState();
}

class _RechercheScreenState extends State<RechercheScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _ready = false;

  // Replay support: key increments force KaninchenbauScreen rebuild so
  // initState picks up the new initialTopic.
  int _kaninchenbauKey = 0;
  String? _replayTopic;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _init();
  }

  Future<void> _init() async {
    await SearchHistoryService.init();
    if (mounted) setState(() => _ready = true);
  }

  /// Switch to Tab 0 and replay [query] in the research engine.
  void _replaySearch(String query) {
    setState(() {
      _replayTopic = query;
      _kaninchenbauKey++;
    });
    _tabController.animateTo(0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        ColoredBox(
          color: _kSurface,
          child: TabBar(
            controller: _tabController,
            indicatorColor: _kAccent,
            indicatorWeight: 3,
            labelColor: _kAccent,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            tabs: const [
              Tab(
                icon: Icon(Icons.travel_explore, size: 18),
                text: 'Recherche',
              ),
              Tab(icon: Icon(Icons.history, size: 18), text: 'Verlauf'),
              Tab(
                icon: Icon(Icons.analytics_outlined, size: 18),
                text: 'Statistiken',
              ),
            ],
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            // Swipe disabled to prevent gesture conflicts with KaninchenbauScreen.
            physics: const NeverScrollableScrollPhysics(),
            children: [
              KaninchenbauScreen(
                key: ValueKey(_kaninchenbauKey),
                initialTopic: _replayTopic,
              ),
              _ready
                  ? _HistoryTab(
                      onTabSwitch: () => _tabController.animateTo(0),
                      onReplay: _replaySearch,
                    )
                  : const _Loading(),
              _ready ? const _StatsTab() : const _Loading(),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1 -- Verlauf (card list, swipe-to-delete, tap-to-replay)
// ---------------------------------------------------------------------------

class _HistoryTab extends StatefulWidget {
  final VoidCallback onTabSwitch;
  final void Function(String query) onReplay;

  const _HistoryTab({required this.onTabSwitch, required this.onReplay});

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  String _filter = '';
  bool _sortAsc = false;
  // Grid view groups results by category; list view keeps the swipe-to-delete
  // card layout. Default to grid for the improved overview (issue #393).
  bool _grid = true;
  final TextEditingController _filterCtrl = TextEditingController();

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  List<SearchHistoryEntry> get _rows {
    var list = _filter.isEmpty
        ? SearchHistoryService.getAllHistory()
        : SearchHistoryService.searchHistory(_filter);
    if (_sortAsc) list = list.reversed.toList();
    return list;
  }

  List<String> get _recentChips => SearchHistoryService.getRecentHistory(
        limit: 5,
      ).map((e) => e.query).toList();

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    final chips = _recentChips;

    return ColoredBox(
      color: _kBg,
      child: Column(
        children: [
          // Search filter
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              controller: _filterCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Verlauf durchsuchen ...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                ),
                prefixIcon: const Icon(Icons.search, color: _kAccent, size: 18),
                suffixIcon: _filter.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          size: 16,
                          color: Colors.white54,
                        ),
                        onPressed: () {
                          _filterCtrl.clear();
                          setState(() => _filter = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: _kSurface,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _filter = v),
            ),
          ),

          // Recent-query chips (only shown when filter is empty)
          if (_filter.isEmpty && chips.isNotEmpty)
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: chips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => ActionChip(
                  label: Text(
                    chips[i],
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                  backgroundColor: _kSurface,
                  side: BorderSide(color: _kAccent.withValues(alpha: 0.35)),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  onPressed: () => widget.onReplay(chips[i]),
                ),
              ),
            ),

          // Row count + sort toggle + delete-all
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${rows.length} Eintraege',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const Spacer(),
                // Sort toggle
                TextButton.icon(
                  onPressed: () => setState(() => _sortAsc = !_sortAsc),
                  icon: Icon(
                    _sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 14,
                    color: _kAccent,
                  ),
                  label: Text(
                    _sortAsc ? 'Aelteste zuerst' : 'Neueste zuerst',
                    style: const TextStyle(color: _kAccent, fontSize: 11),
                  ),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
                // List / grid view toggle
                IconButton(
                  tooltip: _grid ? 'Listenansicht' : 'Rasteransicht',
                  icon: Icon(
                    _grid ? Icons.view_agenda_outlined : Icons.grid_view,
                    color: _kAccent,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _grid = !_grid),
                ),
                if (rows.isNotEmpty)
                  IconButton(
                    tooltip: 'Gesamten Verlauf loeschen',
                    icon: const Icon(
                      Icons.delete_sweep,
                      color: Colors.redAccent,
                      size: 18,
                    ),
                    onPressed: () => _confirmClearAll(context),
                  ),
              ],
            ),
          ),

          // Results -- empty state, grouped grid, or swipe-to-delete list
          Expanded(
            child: rows.isEmpty
                ? _EmptyState(
                    icon: Icons.history_toggle_off,
                    message: 'Noch keine Recherchen gespeichert.\n'
                        'Starte eine Suche im Recherche-Tab.',
                    actionLabel: 'Zur Recherche',
                    onAction: widget.onTabSwitch,
                  )
                : (_grid ? _buildGrid(rows) : _buildList(rows)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEntry(String id) async {
    await SearchHistoryService.deleteEntry(id);
    if (mounted) setState(() {});
  }

  // Swipe-to-delete card list.
  Widget _buildList(List<SearchHistoryEntry> rows) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final entry = rows[index];
        return RechercheCard(
          key: ValueKey(entry.id),
          entry: entry,
          onReplay: () => widget.onReplay(entry.query),
          onDelete: () => _deleteEntry(entry.id),
        );
      },
    );
  }

  // Category-grouped grid: a sticky-less section header (SliverList) followed by
  // a SliverGrid of compact result tiles per category.
  Widget _buildGrid(List<SearchHistoryEntry> rows) {
    final groups = groupRechercheByCategory(rows);
    final slivers = <Widget>[];

    for (final group in groups) {
      slivers.add(
        SliverToBoxAdapter(
          child: _CategoryHeader(
            label: group.category,
            count: group.entries.length,
          ),
        ),
      );
      slivers.add(
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.92,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final entry = group.entries[index];
            return RechercheResultTile(
              key: ValueKey(entry.id),
              entry: entry,
              onReplay: () => widget.onReplay(entry.query),
              onDelete: () => _deleteEntry(entry.id),
            );
          }, childCount: group.entries.length),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
          sliver: SliverMainAxisGroup(slivers: slivers),
        ),
      ],
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    // Capture the messenger before the first await so we never read
    // BuildContext across an async gap (use_build_context_synchronously).
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurface,
        title: const Text(
          'Verlauf loeschen',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Wirklich den gesamten Recherche-Verlauf loeschen?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Loeschen',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (!(ok ?? false) || !mounted) return;
    await SearchHistoryService.clearAllHistory();
    if (!mounted) return;
    setState(() {});
    // Use the captured messenger -- no BuildContext after the await chain.
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Recherche-Verlauf geloescht.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _kSurface,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2 -- Statistiken (fl_chart BarChart with 7/30-day toggle)
// ---------------------------------------------------------------------------

class _StatsTab extends StatefulWidget {
  const _StatsTab();

  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab> {
  int _days = 7;

  /// Counts searches per day for the last [days] days.
  List<_DayCount> _dailyCounts(int days) {
    final now = DateTime.now();
    final history = SearchHistoryService.getAllHistory();

    final result = <_DayCount>[];
    for (int i = days - 1; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final count = history.where((e) {
        final d = e.timestamp;
        return d.year == day.year && d.month == day.month && d.day == day.day;
      }).length;
      result.add(_DayCount(day, count));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final stats = SearchHistoryService.getStatistics();
    final counts = _dailyCounts(_days);
    final maxCount = counts.fold<int>(0, (m, d) => d.count > m ? d.count : m);

    return ColoredBox(
      color: _kBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary metric cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: [
                _MetricCard(
                  icon: Icons.search,
                  label: 'Recherchen gesamt',
                  value: '${stats['totalSearches']}',
                ),
                _MetricCard(
                  icon: Icons.fingerprint,
                  label: 'Einzigartige Suchen',
                  value: '${stats['uniqueQueries']}',
                ),
                _MetricCard(
                  icon: Icons.find_in_page,
                  label: 'Oe Treffer / Suche',
                  value: '${stats['averageResultCount']}',
                ),
                _MetricCard(
                  icon: Icons.today,
                  label: 'Aktiv seit',
                  value: stats['oldestSearch'] != null
                      ? _formatDate(stats['oldestSearch'] as DateTime)
                      : '--',
                  small: true,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Section header + time-range toggle
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recherchen der letzten $_days Tage',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Anzahl gestarteter Suchanfragen pro Tag',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // 7 / 30 toggle
                Container(
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DayToggleBtn(
                        label: '7T',
                        selected: _days == 7,
                        onTap: () => setState(() => _days = 7),
                      ),
                      _DayToggleBtn(
                        label: '30T',
                        selected: _days == 30,
                        onTap: () => setState(() => _days = 30),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bar chart
            SizedBox(
              height: 200,
              child: maxCount == 0
                  ? Center(
                      child: Text(
                        'Noch keine Daten fuer diesen Zeitraum.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                    )
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (maxCount + 1).toDouble(),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final label = counts[groupIndex].count;
                              return BarTooltipItem(
                                '$label Suche${label == 1 ? '' : 'n'}',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= counts.length) {
                                  return const SizedBox.shrink();
                                }
                                // Show fewer labels for 30-day view to avoid overlap.
                                if (_days == 30 && idx % 5 != 0) {
                                  return const SizedBox.shrink();
                                }
                                final d = counts[idx].day;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    '${d.day}.${d.month}',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) {
                                if (value == value.floorToDouble() &&
                                    value >= 0) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 10,
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: Colors.white.withValues(alpha: 0.07),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(counts.length, (i) {
                          final c = counts[i].count;
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: c.toDouble(),
                                color: c == 0
                                    ? Colors.white12
                                    : _kAccent.withValues(
                                        alpha: 0.75 + 0.25 * c / maxCount,
                                      ),
                                // Thinner bars for 30-day view to fit.
                                width: _days == 30 ? 8 : 20,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
            ),

            const SizedBox(height: 28),

            // Top queries list
            const Text(
              'Haeufigste Suchanfragen',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ..._topQueries(),
          ],
        ),
      ),
    );
  }

  List<Widget> _topQueries() {
    final top = SearchHistoryService.getMostSearchedQueries(limit: 5);
    if (top.isEmpty) {
      return [
        Text(
          'Noch keine Daten vorhanden.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 12,
          ),
        ),
      ];
    }
    return top.asMap().entries.map((entry) {
      final rank = entry.key + 1;
      final query = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rank == 1
                    ? _kAccent.withValues(alpha: 0.25)
                    : Colors.white10,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$rank',
                style: TextStyle(
                  color: rank == 1 ? _kAccent : Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                query,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  static String _formatDate(DateTime d) => '${d.day}.${d.month}.${d.year}';
}

// ---------------------------------------------------------------------------
// Helper: 7T / 30T toggle button
// ---------------------------------------------------------------------------

class _DayToggleBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DayToggleBtn({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              selected ? _kAccent.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _kAccent : Colors.white54,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Plain helper class (not a Dart 3 record -- CLAUDE.md rule #8)
// ---------------------------------------------------------------------------

class _DayCount {
  final DateTime day;
  final int count;
  const _DayCount(this.day, this.count);
}

// ---------------------------------------------------------------------------
// Reusable sub-widgets
// ---------------------------------------------------------------------------

class _CategoryHeader extends StatelessWidget {
  final String label;
  final int count;

  const _CategoryHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 12, 2, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: _kAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool small;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: _kAccent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: small ? 13 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAction,
              style: FilledButton.styleFrom(backgroundColor: _kAccent),
              icon: const Icon(Icons.search, size: 16),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: _kBg,
      child: Center(
        child: CircularProgressIndicator(color: _kAccent, strokeWidth: 2),
      ),
    );
  }
}
