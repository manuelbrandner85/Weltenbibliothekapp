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
                  '${rows.length} Einträge',
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
                    _sortAsc ? 'Älteste zuerst' : 'Neueste zuerst',
                    style: const TextStyle(color: _kAccent, fontSize: 11),
                  ),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
                if (rows.isNotEmpty)
                  IconButton(
                    tooltip: 'Gesamten Verlauf löschen',
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

          // Card list
          Expanded(
            child: rows.isEmpty
                ? _EmptyState(
                    icon: Icons.history_toggle_off,
                    message: 'Noch keine Recherchen gespeichert.\n'
                        'Starte eine Suche im Recherche-Tab.',
                    actionLabel: 'Zur Recherche',
                    onAction: widget.onTabSwitch,
                  )
                : RefreshIndicator(
                    color: _kAccent,
                    backgroundColor: _kSurface,
                    onRefresh: () async => setState(() {}),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final entry = rows[index];
                        return _HistoryCard(
                          key: ValueKey(entry.id),
                          entry: entry,
                          onReplay: () => widget.onReplay(entry.query),
                          onDelete: () async {
                            await SearchHistoryService.deleteEntry(entry.id);
                            if (mounted) setState(() {});
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurface,
        title: const Text(
          'Verlauf löschen',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Wirklich den gesamten Recherche-Verlauf löschen?',
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
              'Löschen',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if ((ok ?? false) && mounted) {
      await SearchHistoryService.clearAllHistory();
      setState(() {});
    }
  }
}

// ---------------------------------------------------------------------------
// Single history entry card with swipe-to-delete and replay button
// ---------------------------------------------------------------------------

class _HistoryCard extends StatelessWidget {
  final SearchHistoryEntry entry;
  final VoidCallback onReplay;
  final VoidCallback onDelete;

  const _HistoryCard({
    super.key,
    required this.entry,
    required this.onReplay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tags = entry.tags ?? [];

    return Dismissible(
      key: ValueKey('dismiss_${entry.id}'),
      direction: DismissDirection.endToStart,
      background: _SwipeDeleteBackground(),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onReplay,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Replay icon
                Padding(
                  padding: const EdgeInsets.only(top: 1, right: 12),
                  child: Icon(
                    Icons.manage_search_rounded,
                    color: _kAccent.withValues(alpha: 0.7),
                    size: 20,
                  ),
                ),

                // Main content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.query,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Date
                          Text(
                            entry.formattedDate,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Result count badge
                          if (entry.resultCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: _kAccent.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${entry.resultCount} Treffer',
                                style: TextStyle(
                                  color: _kAccent.withValues(alpha: 0.9),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      // Tags
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: tags.take(3).map((t) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                t,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                // Delete button
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white30,
                  ),
                  tooltip: 'Eintrag löschen',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeDeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(
        Icons.delete_outline,
        color: Colors.redAccent,
        size: 22,
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
                  label: 'Ø Treffer / Suche',
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
              'Häufigste Suchanfragen',
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
