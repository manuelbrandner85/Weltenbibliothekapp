import 'package:flutter/material.dart';
import '../services/gamification_service.dart';

/// A2: Kompakte Cross-World-Uebersicht.
///
/// Zeigt Level + XP + Fortschritt aller 4 Welten auf einen Blick,
/// plus das globale Gesamtlevel. Wird im Profil-Screen eingebunden.
class CrossWorldOverviewCard extends StatelessWidget {
  const CrossWorldOverviewCard({super.key});

  static const _worlds = <_WorldMeta>[
    _WorldMeta('materie', 'Materie', Color(0xFFE53935), Icons.public),
    _WorldMeta('energie', 'Energie', Color(0xFF7C4DFF), Icons.auto_awesome),
    _WorldMeta('vorhang', 'Vorhang', Color(0xFFC9A84C), Icons.theater_comedy),
    _WorldMeta('ursprung', 'Ursprung', Color(0xFF00D4AA), Icons.blur_on),
  ];

  @override
  Widget build(BuildContext context) {
    final gam = GamificationService();
    final globalLevel = gam.globalLevel;
    final totalXp = gam.totalXpAllWorlds;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF7C4DFF).withValues(alpha: 0.10),
            const Color(0xFF00D4AA).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.military_tech,
                    color: Colors.amber, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Globales Level $globalLevel',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$totalXp XP gesamt',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ..._worlds.map((w) {
            final p = gam.getProgress(w.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _worldRow(w, p),
            );
          }),
        ],
      ),
    );
  }

  Widget _worldRow(_WorldMeta w, PlayerProgress p) {
    return Row(
      children: [
        Icon(w.icon, color: w.color, size: 18),
        const SizedBox(width: 10),
        SizedBox(
          width: 64,
          child: Text(
            w.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: p.progressToNext,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation(w.color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Lv ${p.level}',
          style: TextStyle(
            color: w.color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _WorldMeta {
  final String id;
  final String label;
  final Color color;
  final IconData icon;
  const _WorldMeta(this.id, this.label, this.color, this.icon);
}
