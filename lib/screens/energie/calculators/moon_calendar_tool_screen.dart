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
          const _PlaceholderTab(
            emoji: '🕯️',
            title: 'Rituale',
            hint: 'Kommt in Phase 8C.3',
          ),
          const _PlaceholderTab(
            emoji: '📖',
            title: 'Mond-Tagebuch',
            hint: 'Kommt in Phase 8C.4',
          ),
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
// Platzhalter für die noch nicht gebauten Tabs
// ═══════════════════════════════════════════════════════════

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.emoji,
    required this.title,
    required this.hint,
  });

  final String emoji;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
