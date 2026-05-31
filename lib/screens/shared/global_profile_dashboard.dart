// GlobalProfileDashboard -- welten-uebergreifende Fortschritts-Uebersicht.
//
// FEATURE (P5): Zeigt Gesamt-XP, globales Level, Level/XP pro Welt
// (Materie/Energie/Vorhang/Ursprung), Lern-Streak und Achievements.
// Ein zentraler "Trophaeen-Raum" der den Gesamt-Fortschritt sichtbar
// macht -- ein Kern-Element fuer Engagement & Premium-Feel.
//
// Route: '/global_profile'

import 'package:flutter/material.dart';

import '../../services/achievement_service.dart';
import '../../services/gamification_service.dart';
import '../../services/user_service.dart';

// dart2js-Bug-Workaround: Named Records kompilieren nicht zuverlaessig.
class _WorldMeta {
  final String label;
  final String emoji;
  final Color color;
  const _WorldMeta(
      {required this.label, required this.emoji, required this.color});
}

class GlobalProfileDashboard extends StatefulWidget {
  const GlobalProfileDashboard({super.key});

  @override
  State<GlobalProfileDashboard> createState() => _GlobalProfileDashboardState();
}

class _GlobalProfileDashboardState extends State<GlobalProfileDashboard> {
  final _gam = GamificationService();
  final _ach = AchievementService();

  static const _worldMeta = <String, _WorldMeta>{
    'materie':
        _WorldMeta(label: 'Materie', emoji: '🌍', color: Color(0xFF2979FF)),
    'energie':
        _WorldMeta(label: 'Energie', emoji: '✨', color: Color(0xFF9B51E0)),
    'vorhang':
        _WorldMeta(label: 'Vorhang', emoji: '🎭', color: Color(0xFFC9A84C)),
    'ursprung':
        _WorldMeta(label: 'Ursprung', emoji: '🌌', color: Color(0xFF00D4AA)),
  };

  @override
  Widget build(BuildContext context) {
    final username = UserService.getCurrentUsername();
    final totalXp = _gam.totalXpAllWorlds;
    final globalLevel = _gam.globalLevel;
    final unlocked = _ach.unlockedAchievements.length;
    final totalAch = _ach.allAchievements.length;

    // Hoechster Streak ueber alle Welten.
    var bestStreak = 0;
    for (final w in GamificationService.allWorlds) {
      final s = _gam.getProgress(w).streakDays;
      if (s > bestStreak) bestStreak = s;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF06060C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Mein Fortschritt'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Hero: globales Level + Gesamt-XP ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1438), Color(0xFF0A0A1A)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C4DFF).withValues(alpha: 0.5),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text('$globalLevel',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username.isNotEmpty ? username : 'Forscher',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text('Globales Level $globalLevel · $totalXp XP',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Stat-Kacheln: Streak + Achievements ──
          Row(
            children: [
              Expanded(
                child: _statTile(
                  emoji: '🔥',
                  value: '$bestStreak',
                  label: 'Tage-Streak',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statTile(
                  emoji: '🏆',
                  value: '$unlocked/$totalAch',
                  label: 'Achievements',
                  color: const Color(0xFFFFD54F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Fortschritt pro Welt ──
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text('Fortschritt pro Welt',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
          ..._worldMeta.entries.map((e) => _worldRow(e.key, e.value)),

          const SizedBox(height: 20),
          // ── Achievement-Galerie (freigeschaltete) ──
          if (unlocked > 0) ...[
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 10),
              child: Text('Freigeschaltete Achievements',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _ach.unlockedAchievements
                  .map((a) => _achBadge(a))
                  .toList(),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _statTile({
    required String emoji,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _worldRow(String world, _WorldMeta meta) {
    final p = _gam.getProgress(world);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: meta.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: meta.color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(meta.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(meta.label,
                    style: TextStyle(
                        color: meta.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
              Text('Lvl ${p.level} · ${p.totalXp} XP',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(
                    height: 6, color: Colors.white.withValues(alpha: 0.08)),
                FractionallySizedBox(
                  widthFactor: p.progressToNext,
                  child: Container(height: 6, color: meta.color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _achBadge(Achievement a) {
    return Container(
      width: 76,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(a.icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 6),
          Text(
            a.name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 9),
          ),
        ],
      ),
    );
  }
}
