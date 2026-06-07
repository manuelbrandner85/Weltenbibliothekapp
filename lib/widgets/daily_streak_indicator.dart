// Daily-Streak-Indicator — sichtbarer Anker für die XP-Mechanik.
//
// Zeigt die längste aktive Streak über alle 4 Welten in der Portal-AppBar.
// 🔥-Icon pulsiert wenn Streak ≥ 3 Tage. Tap → Stats-Dashboard.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

import '../services/gamification_service.dart';
import '../screens/shared/stats_dashboard_screen.dart';

class DailyStreakIndicator extends StatefulWidget {
  const DailyStreakIndicator({super.key});

  @override
  State<DailyStreakIndicator> createState() => _DailyStreakIndicatorState();
}

class _DailyStreakIndicatorState extends State<DailyStreakIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _refresh();
  }

  void _refresh() {
    try {
      final svc = GamificationService();
      // Maximum-Streak über alle 4 Welten (gleicher User, eine Streak-Wahrheit).
      int max = 0;
      for (final w in const ['materie', 'energie', 'vorhang', 'ursprung']) {
        final p = svc.getProgress(w);
        if (p.streakDays > max) max = p.streakDays;
      }
      if (mounted) setState(() => _streak = max);
    } catch (e) { if (kDebugMode) debugPrint('daily_streak_indicator: silent catch -> $e'); }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_streak <= 0) return const SizedBox.shrink();
    final hot = _streak >= 3;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const StatsDashboardScreen(world: 'materie'),
        ),
      ),
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) {
          final alpha = hot ? (0.6 + 0.4 * _pulse.value) : 0.7;
          return Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withValues(alpha: 0.18 * alpha),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFFF6B35).withValues(alpha: 0.6 * alpha),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🔥',
                  style: TextStyle(fontSize: hot ? 14 : 12),
                ),
                const SizedBox(width: 4),
                Text(
                  '$_streak',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
