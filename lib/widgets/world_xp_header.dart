// WorldXpHeader -- zeigt Level, XP-Fortschrittsbalken und Lern-Streak
// fuer eine Welt. Wird oben in den Home-Tabs der Welten eingebunden.
//
// FEATURE (V1 / U1): Macht die Gamification sichtbar. Vorher lief XP
// im Hintergrund mit, aber der User sah seinen Fortschritt nirgends ->
// kein Anreiz weiterzumachen. Jetzt: Level-Badge + Progress-Bar zum
// naechsten Level + Streak-Flamme ("X Tage in Folge").
//
// Verwendung:
//   WorldXpHeader(world: 'vorhang', accent: gold)

import 'package:flutter/material.dart';

import '../services/gamification_service.dart';

class WorldXpHeader extends StatefulWidget {
  final String world;
  final Color accent;

  const WorldXpHeader({
    super.key,
    required this.world,
    required this.accent,
  });

  @override
  State<WorldXpHeader> createState() => _WorldXpHeaderState();
}

class _WorldXpHeaderState extends State<WorldXpHeader> {
  final _gam = GamificationService();
  PlayerProgress? _progress;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Streak beim Oeffnen pruefen/aktualisieren, dann Progress lesen.
      await _gam.checkAndUpdateStreak(widget.world);
    } catch (_) {/* best-effort */}
    if (!mounted) return;
    setState(() => _progress = _gam.getProgress(widget.world));
  }

  @override
  Widget build(BuildContext context) {
    final p = _progress;
    if (p == null) {
      return const SizedBox(height: 64);
    }
    final pct = p.progressToNext;
    final xpInLevel = p.totalXp - p.xpForCurrentLevel;
    final xpNeeded = p.xpForNextLevel - p.xpForCurrentLevel;

    return GestureDetector(
      // Tap auf den Header oeffnet das welten-uebergreifende Dashboard (P5).
      onTap: () => Navigator.of(context).pushNamed('/global_profile'),
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.accent.withValues(alpha: 0.16),
            widget.accent.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Level-Badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      widget.accent,
                      widget.accent.withValues(alpha: 0.6),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.accent.withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${p.level}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level ${p.level}',
                      style: TextStyle(
                        color: widget.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${p.totalXp} XP gesamt',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Streak-Flamme
              if (p.streakDays > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        '${p.streakDays}',
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress-Bar zum naechsten Level
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.accent,
                          widget.accent.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Noch ${(xpNeeded - xpInLevel).clamp(0, xpNeeded)} XP bis Level ${p.level + 1}',
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
