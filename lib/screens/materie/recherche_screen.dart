/// Recherche-Hub -- tabbed overview screen for the Materie Recherche tab.
///
/// Tab 0: KaninchenbauScreen (deep research engine, unchanged)
/// Tab 1: Verlauf -- DataTable listing recent search-history entries
/// Tab 2: Statistiken -- fl_chart BarChart showing searches per day (7 days)
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
            labelColor: _kAccent,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
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
              const KaninchenbauScreen(),
              _ready
                  ? _HistoryTab(onTabSwitch: () => _tabController.animateTo(0))
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
// Tab 1 -- Verlauf (DataTable)
// ---------------------------------------------------------------------------

class _HistoryTab extends StatefulWidget {
  final VoidCallback onTabSwitch;
  const _HistoryTab({required this.onTabSwitch});

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  String _filter = '';
  bool _sortAsc = false;

  List<SearchHistoryEntry> get _rows {
    var list = _filter.isEmpty
        ? SearchHistoryService.getAllHistory()
        : SearchHistoryService.searchHistory(_filter);
    if (_sortAsc) list = list.reversed.toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;

    return ColoredBox(
      color: _kBg,
      child: Column(
        children: [
          // Search filter + clear button
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Verlauf durchsuchen ...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                ),
                prefixIcon: const Icon(Icons.search, color: _kAccent, size: 18),
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

          // DataTable
          Expanded(
            child: rows.isEmpty
                ? _EmptyState(
                    icon: Icons.history_toggle_off,
                    message: 'Noch keine Recherchen gespeichert.\n'
                        'Starte eine Suche im Recherche-Tab.',
                    actionLabel: 'Zur Recherche',
                    onAction: widget.onTabSwitch,
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 16,
                        dataRowMinHeight: 40,
                        dataRowMaxHeight: 52,
                        headingRowColor: WidgetStateProperty.all(
                          _kSurface.withValues(alpha: 0.9),
                        ),
                        dataRowColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return _kAccent.withValues(alpha: 0.12);
                          }
                          return Colors.transparent;
                        }),
                        border: TableBorder(
                          horizontalInside: BorderSide(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Suchanfrage',
                              style: TextStyle(
                                color: _kAccent,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Datum',
                              style: TextStyle(
                                color: _kAccent,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            numeric: true,
                            label: Text(
                              'Treffer',
                              style: TextStyle(
                                color: _kAccent,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Tags',
                              style: TextStyle(
                                color: _kAccent,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Aktion',
                              style: TextStyle(
                                color: _kAccent,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        rows: rows.map((e) => _buildRow(context, e)).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  DataRow _buildRow(BuildContext context, SearchHistoryEntry entry) {
    final tags = entry.tags ?? [];
    return DataRow(
      cells: [
        // Query text -- truncated
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              entry.query,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // Formatted date
        DataCell(
          Text(
            entry.formattedDate,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 11,
            ),
          ),
        ),
        // Result count badge
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: entry.resultCount > 0
                  ? _kAccent.withValues(alpha: 0.18)
                  : Colors.white12,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${entry.resultCount}',
              style: TextStyle(
                color: entry.resultCount > 0 ? _kAccent : Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        // Tags
        DataCell(
          tags.isEmpty
              ? Text(
                  '—',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 11,
                  ),
                )
              : Wrap(
                  spacing: 4,
                  children: tags
                      .take(2)
                      .map(
                        (t) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            t,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        // Delete action
        DataCell(
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
            tooltip: 'Eintrag löschen',
            onPressed: () async {
              await SearchHistoryService.deleteEntry(entry.id);
              if (mounted) setState(() {});
            },
          ),
        ),
      ],
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
// Tab 2 -- Statistiken (fl_chart BarChart)
// ---------------------------------------------------------------------------

class _StatsTab extends StatelessWidget {
  const _StatsTab();

  /// Counts searches per day for the last [days] days.
  /// Returns a plain list (plain class used instead of Record type).
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
    final counts = _dailyCounts(7);
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
                      : '—',
                  small: true,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Section header
            const Text(
              'Recherchen der letzten 7 Tage',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Anzahl gestarteter Suchanfragen pro Tag',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
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
                                width: 20,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(5),
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
