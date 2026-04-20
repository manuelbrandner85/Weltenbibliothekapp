/// Mondkalender (Tool 8, Phase 8C)
///
/// Screen-Gerüst mit 4 Tabs:
///   1) Heute – aktueller Mond-Snapshot + Tagesempfehlungen
///   2) Monatskalender – Grid (Phase 8C.2)
///   3) Rituale – 8 Mondphasen-Rituale aus Supabase (Phase 8C.3)
///   4) Tagebuch – user-spezifische Einträge (Phase 8C.4)
///
/// Nutzt moon_calculator.dart (Meeus-Algorithmen) +
/// moon_recommendations.dart (Zeichen × Phase Matrix).
library;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/moon_calculator.dart';
import '../../../services/moon_recommendations.dart';

class MoonCalendarToolScreen extends StatefulWidget {
  const MoonCalendarToolScreen({super.key});

  @override
  State<MoonCalendarToolScreen> createState() => _MoonCalendarToolScreenState();
}

class _MoonCalendarToolScreenState extends State<MoonCalendarToolScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  /// Live aktualisierter Snapshot (für den Heute-Tab).
  MoonSnapshot _snapshot = calculateMoonSnapshot(DateTime.now().toUtc());

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _refreshSnapshot() {
    setState(() {
      _snapshot = calculateMoonSnapshot(DateTime.now().toUtc());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF37474F),
        foregroundColor: Colors.white,
        title: const Text('Mondkalender'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.today), text: 'Heute'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Monat'),
            Tab(icon: Icon(Icons.self_improvement), text: 'Rituale'),
            Tab(icon: Icon(Icons.book), text: 'Tagebuch'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Aktualisieren',
            icon: const Icon(Icons.refresh),
            onPressed: _refreshSnapshot,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _TodayTab(snapshot: _snapshot),
          const _MonthTab(),
          _RitualsTab(currentPhaseKey: _snapshot.phaseKey),
          _JournalTab(snapshot: _snapshot),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Tab 1: Heute
// ═══════════════════════════════════════════════════════════

class _TodayTab extends StatelessWidget {
  const _TodayTab({required this.snapshot});

  final MoonSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final tips = getDailyMoonTips(snapshot);
    final headline = buildMoonHeadline(snapshot);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MoonHeroCard(snapshot: snapshot, headline: headline),
        const SizedBox(height: 16),
        _FactsRow(snapshot: snapshot),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Tagesempfehlungen',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        for (final tip in tips) _TipCard(tip: tip),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _MoonHeroCard extends StatelessWidget {
  const _MoonHeroCard({required this.snapshot, required this.headline});

  final MoonSnapshot snapshot;
  final String headline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF37474F)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(snapshot.phaseEmoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${snapshot.phaseLabel}   •   ${snapshot.illuminationPercent} beleuchtet',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mond in ${snapshot.moonSignName} ${snapshot.moonSignSymbol}   '
                  '(${snapshot.moonSignDegree.toStringAsFixed(1)}°)',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FactsRow extends StatelessWidget {
  const _FactsRow({required this.snapshot});

  final MoonSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Fact(
            icon: Icons.wb_sunny,
            label: 'Element',
            value: snapshot.moonElement,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Fact(
            icon: snapshot.isWaxing
                ? Icons.trending_up
                : Icons.trending_down,
            label: 'Tendenz',
            value: snapshot.isWaxing ? 'zunehmend' : 'abnehmend',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Fact(
            icon: Icons.light_mode,
            label: 'Beleuchtung',
            value: snapshot.illuminationPercent,
          ),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});

  final MoonDailyTip tip;

  @override
  Widget build(BuildContext context) {
    final warn = !tip.positive;
    final bg = warn
        ? const Color(0xFF3E2723).withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.06);
    final border = warn
        ? Colors.orange.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.08);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tip.emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.topic,
                  style: TextStyle(
                    color: warn ? Colors.orangeAccent : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip.text,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Tab 2: Monatskalender
// ═══════════════════════════════════════════════════════════

class _MonthTab extends StatefulWidget {
  const _MonthTab();

  @override
  State<_MonthTab> createState() => _MonthTabState();
}

class _MonthTabState extends State<_MonthTab> {
  /// Anzeigemonat (nur Jahr + Monat relevant).
  DateTime _month = _firstOfMonth(DateTime.now());

  /// Ausgewählter Tag im angezeigten Monat.
  DateTime _selected = _stripTime(DateTime.now());

  static DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month, 1);
  static DateTime _stripTime(DateTime d) => DateTime(d.year, d.month, d.day);

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta, 1);
    });
  }

  void _selectDay(DateTime day) {
    setState(() => _selected = day);
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = calculateMoonSnapshot(
      DateTime.utc(_selected.year, _selected.month, _selected.day, 12),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MonthHeader(
          month: _month,
          onPrev: () => _shiftMonth(-1),
          onNext: () => _shiftMonth(1),
        ),
        const SizedBox(height: 12),
        _WeekdayRow(),
        const SizedBox(height: 6),
        _MonthGrid(
          month: _month,
          selected: _selected,
          onTap: _selectDay,
        ),
        const SizedBox(height: 20),
        _SelectedDayCard(day: _selected, snapshot: snapshot),
      ],
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  static const _names = [
    'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
    'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left, color: Colors.white),
        ),
        Text(
          '${_names[month.month - 1]} ${month.year}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right, color: Colors.white),
        ),
      ],
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  static const _labels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final l in _labels)
          Expanded(
            child: Center(
              child: Text(
                l,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.onTap,
  });

  final DateTime month;
  final DateTime selected;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    // Monday=1, Sunday=7 → leading empty cells
    final leading = month.weekday - 1;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final totalCells = ((leading + daysInMonth + 6) ~/ 7) * 7;
    final today = _MonthTabState._stripTime(DateTime.now());

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 0.85,
      ),
      itemCount: totalCells,
      itemBuilder: (_, i) {
        final dayNum = i - leading + 1;
        if (dayNum < 1 || dayNum > daysInMonth) {
          return const SizedBox.shrink();
        }
        final day = DateTime(month.year, month.month, dayNum);
        final snap = calculateMoonSnapshot(
          DateTime.utc(day.year, day.month, day.day, 12),
        );
        final isSelected = day == selected;
        final isToday = day == today;

        return _DayCell(
          day: dayNum,
          emoji: snap.phaseEmoji,
          isSelected: isSelected,
          isToday: isToday,
          onTap: () => onTap(day),
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.emoji,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final int day;
  final String emoji;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = isSelected
        ? Colors.amberAccent
        : (isToday ? Colors.lightBlueAccent : Colors.white12);
    final bg = isSelected
        ? Colors.amberAccent.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.04);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                color: isSelected ? Colors.amberAccent : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(emoji, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class _SelectedDayCard extends StatelessWidget {
  const _SelectedDayCard({required this.day, required this.snapshot});

  final DateTime day;
  final MoonSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(snapshot.phaseEmoji, style: const TextStyle(fontSize: 44)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(day),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  buildMoonHeadline(snapshot),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${snapshot.phaseLabel}  •  ${snapshot.illuminationPercent}  •  ${snapshot.moonElement}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _monthNames = [
    'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
    'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
  ];

  static String _formatDate(DateTime d) =>
      '${d.day}. ${_monthNames[d.month - 1]} ${d.year}';
}

// ═══════════════════════════════════════════════════════════
// Tab 3: Rituale (Supabase: moon_rituals)
// ═══════════════════════════════════════════════════════════

class _MoonRitual {
  final String phaseKey;
  final String title;
  final String description;
  final List<String> steps;
  final int sortOrder;

  _MoonRitual({
    required this.phaseKey,
    required this.title,
    required this.description,
    required this.steps,
    required this.sortOrder,
  });

  factory _MoonRitual.fromRow(Map<String, dynamic> row) {
    final rawSteps = (row['steps'] as String? ?? '').trim();
    final parsed = rawSteps
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return _MoonRitual(
      phaseKey: row['moon_phase'] as String,
      title: row['title'] as String,
      description: row['description'] as String,
      steps: parsed,
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

class _RitualsTab extends StatefulWidget {
  const _RitualsTab({required this.currentPhaseKey});

  final String currentPhaseKey;

  @override
  State<_RitualsTab> createState() => _RitualsTabState();
}

class _RitualsTabState extends State<_RitualsTab> {
  late Future<List<_MoonRitual>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadRituals();
  }

  Future<List<_MoonRitual>> _loadRituals() async {
    final rows = await Supabase.instance.client
        .from('moon_rituals')
        .select('moon_phase,title,description,steps,sort_order')
        .order('sort_order', ascending: true);
    return (rows as List)
        .map((r) => _MoonRitual.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadRituals();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: Colors.amberAccent,
      backgroundColor: const Color(0xFF1A237E),
      child: FutureBuilder<List<_MoonRitual>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white70),
            );
          }
          if (snap.hasError) {
            return ListView(
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_off,
                            size: 48, color: Colors.white38),
                        const SizedBox(height: 12),
                        const Text(
                          'Rituale konnten nicht geladen werden.',
                          style: TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snap.error}',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refresh,
                          child: const Text('Erneut versuchen'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          final rituals = snap.data ?? const [];
          if (rituals.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 80),
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Noch keine Rituale hinterlegt.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rituals.length,
            itemBuilder: (_, i) => _RitualCard(
              ritual: rituals[i],
              isCurrent: rituals[i].phaseKey == widget.currentPhaseKey,
              initiallyExpanded: rituals[i].phaseKey == widget.currentPhaseKey,
            ),
          );
        },
      ),
    );
  }
}

class _RitualCard extends StatelessWidget {
  const _RitualCard({
    required this.ritual,
    required this.isCurrent,
    required this.initiallyExpanded,
  });

  final _MoonRitual ritual;
  final bool isCurrent;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final emoji = moonPhaseEmojis[ritual.phaseKey] ?? '🌙';
    final phaseLabel = moonPhaseLabels[ritual.phaseKey] ?? ritual.phaseKey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent
              ? Colors.amberAccent.withValues(alpha: 0.75)
              : Colors.white12,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          unselectedWidgetColor: Colors.white70,
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Colors.amberAccent,
              ),
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: Colors.white70,
          collapsedIconColor: Colors.white54,
          leading: Text(emoji, style: const TextStyle(fontSize: 32)),
          title: Text(
            ritual.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          subtitle: Row(
            children: [
              Text(
                phaseLabel,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              if (isCurrent) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amberAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'HEUTE',
                    style: TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          children: [
            Text(
              ritual.description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Ablauf',
              style: TextStyle(
                color: Colors.amberAccent,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            for (final step in ritual.steps)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  step,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Tab 4: Mond-Tagebuch (Supabase: moon_journal, RLS pro User)
// ═══════════════════════════════════════════════════════════

class _JournalEntry {
  final String id;
  final DateTime entryDate;
  final String? phaseKey;
  final String? moonSign;
  final String content;
  final bool ritualCompleted;

  _JournalEntry({
    required this.id,
    required this.entryDate,
    required this.phaseKey,
    required this.moonSign,
    required this.content,
    required this.ritualCompleted,
  });

  factory _JournalEntry.fromRow(Map<String, dynamic> row) {
    return _JournalEntry(
      id: row['id'] as String,
      entryDate: DateTime.parse(row['entry_date'] as String),
      phaseKey: row['moon_phase'] as String?,
      moonSign: row['moon_sign'] as String?,
      content: (row['content'] as String?) ?? '',
      ritualCompleted: (row['ritual_completed'] as bool?) ?? false,
    );
  }
}

class _JournalTab extends StatefulWidget {
  const _JournalTab({required this.snapshot});

  final MoonSnapshot snapshot;

  @override
  State<_JournalTab> createState() => _JournalTabState();
}

class _JournalTabState extends State<_JournalTab> {
  SupabaseClient get _db => Supabase.instance.client;

  Future<List<_JournalEntry>>? _future;

  @override
  void initState() {
    super.initState();
    if (_db.auth.currentUser != null) {
      _future = _loadEntries();
    }
  }

  Future<List<_JournalEntry>> _loadEntries() async {
    final rows = await _db
        .from('moon_journal')
        .select('id,entry_date,moon_phase,moon_sign,content,ritual_completed')
        .order('entry_date', ascending: false)
        .limit(200);
    return (rows as List)
        .map((r) => _JournalEntry.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> _refresh() async {
    if (_db.auth.currentUser == null) return;
    setState(() => _future = _loadEntries());
    await _future;
  }

  Future<void> _openNewEntrySheet() async {
    final user = _db.auth.currentUser;
    if (user == null) {
      _showLoginRequired();
      return;
    }

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _NewEntrySheet(snapshot: widget.snapshot),
    );

    if (saved == true) {
      _refresh();
    }
  }

  Future<void> _confirmDelete(_JournalEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Eintrag löschen?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Dieser Tagebuch-Eintrag wird dauerhaft aus der Cloud gelöscht.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _db.from('moon_journal').delete().eq('id', entry.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Eintrag gelöscht.'),
          backgroundColor: Color(0xFF1A237E),
        ),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Löschen fehlgeschlagen: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showLoginRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bitte melde dich an, um das Mond-Tagebuch zu nutzen.'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _db.auth.currentUser;

    if (user == null) {
      return const _JournalLoggedOut();
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _refresh,
          color: Colors.amberAccent,
          backgroundColor: const Color(0xFF1A237E),
          child: FutureBuilder<List<_JournalEntry>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white70),
                );
              }
              if (snap.hasError) {
                return ListView(
                  children: [
                    const SizedBox(height: 80),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Icon(Icons.cloud_off,
                                size: 48, color: Colors.white38),
                            const SizedBox(height: 12),
                            Text(
                              'Einträge konnten nicht geladen werden:\n${snap.error}',
                              style: const TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _refresh,
                              child: const Text('Erneut versuchen'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
              final entries = snap.data ?? const [];
              if (entries.isEmpty) {
                return ListView(
                  children: const [
                    SizedBox(height: 80),
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: [
                            Text('📖', style: TextStyle(fontSize: 64)),
                            SizedBox(height: 12),
                            Text(
                              'Dein Mond-Tagebuch ist noch leer.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Notiere deine Reflexionen, Träume oder Ritual-Erlebnisse zu jedem Mondzyklus. '
                              'Tippe auf +, um den ersten Eintrag anzulegen.',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: entries.length,
                itemBuilder: (_, i) => _JournalEntryCard(
                  entry: entries[i],
                  onDelete: () => _confirmDelete(entries[i]),
                ),
              );
            },
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            backgroundColor: Colors.amberAccent,
            foregroundColor: Colors.black,
            onPressed: _openNewEntrySheet,
            icon: const Icon(Icons.add),
            label: const Text('Eintrag'),
          ),
        ),
      ],
    );
  }
}

class _JournalLoggedOut extends StatelessWidget {
  const _JournalLoggedOut();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔒', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text(
              'Anmeldung erforderlich',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Das Mond-Tagebuch speichert deine Einträge verschlüsselt in deinem persönlichen Account.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalEntryCard extends StatelessWidget {
  const _JournalEntryCard({required this.entry, required this.onDelete});

  final _JournalEntry entry;
  final VoidCallback onDelete;

  static const _monthNames = [
    'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
    'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez',
  ];

  String _formatDate(DateTime d) =>
      '${d.day}. ${_monthNames[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final emoji = moonPhaseEmojis[entry.phaseKey ?? ''] ?? '🌙';
    final phaseLabel =
        moonPhaseLabels[entry.phaseKey ?? ''] ?? (entry.phaseKey ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(entry.entryDate),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (phaseLabel.isNotEmpty || entry.moonSign != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          [
                            if (phaseLabel.isNotEmpty) phaseLabel,
                            if (entry.moonSign != null) 'Mond in ${entry.moonSign}',
                          ].join('  •  '),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (entry.ritualCompleted)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Tooltip(
                    message: 'Ritual ausgeführt',
                    child: Icon(Icons.check_circle,
                        color: Colors.greenAccent, size: 20),
                  ),
                ),
              IconButton(
                tooltip: 'Löschen',
                icon: const Icon(Icons.delete_outline,
                    color: Colors.white54, size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _NewEntrySheet extends StatefulWidget {
  const _NewEntrySheet({required this.snapshot});

  final MoonSnapshot snapshot;

  @override
  State<_NewEntrySheet> createState() => _NewEntrySheetState();
}

class _NewEntrySheetState extends State<_NewEntrySheet> {
  final _controller = TextEditingController();
  bool _ritualDone = false;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte etwas schreiben.')),
      );
      return;
    }

    setState(() => _saving = true);

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      Navigator.pop(context, false);
      return;
    }

    try {
      final today = DateTime.now();
      await client.from('moon_journal').insert({
        'user_id': user.id,
        'entry_date':
            '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}',
        'moon_phase': widget.snapshot.phaseKey,
        'moon_sign': widget.snapshot.moonSignName,
        'content': content,
        'ritual_completed': _ritualDone,
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Speichern fehlgeschlagen: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(widget.snapshot.phaseEmoji,
                  style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Neuer Tagebuch-Eintrag',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${widget.snapshot.phaseLabel}  •  Mond in ${widget.snapshot.moonSignName}',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 4,
            maxLines: 10,
            maxLength: 4000,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Was bewegt dich heute? Träume, Gedanken, Ritual-Erlebnisse…',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              counterStyle: const TextStyle(color: Colors.white38),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _ritualDone,
            onChanged: (v) => setState(() => _ritualDone = v),
            activeThumbColor: Colors.amberAccent,
            title: const Text(
              'Ritual wurde heute ausgeführt',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Abbrechen'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black),
                        )
                      : const Text('Speichern'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
