// Daily-Challenges-Banner — heutige Welt-Challenges (K2).
//
// Holt aktive Challenges via GamificationExtendedService.todayChallenges,
// zeigt sie als horizontale Karten-Reihe im Portal-Home. Tap auf Karte
// kann Welt öffnen (Callback). Versteckt sich wenn keine Challenges
// für heute angelegt sind.

import 'package:flutter/material.dart';

import '../services/gamification_extended_service.dart';

class DailyChallengesBanner extends StatefulWidget {
  final void Function(String world)? onWorldTap;
  const DailyChallengesBanner({super.key, this.onWorldTap});

  @override
  State<DailyChallengesBanner> createState() => _DailyChallengesBannerState();
}

class _DailyChallengesBannerState extends State<DailyChallengesBanner> {
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;

  static const _worldColors = {
    'materie': Color(0xFF3B82F6),
    'energie': Color(0xFFA855F7),
    'vorhang': Color(0xFFC9A84C),
    'ursprung': Color(0xFF00D4AA),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await GamificationExtendedService.instance.todayChallenges();
    if (mounted) {
      setState(() {
        _items = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 8),
            child: Row(
              children: [
                const Text('⚔️', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  'TAGES-CHALLENGES',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_items.length}',
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _items.length,
              padding: const EdgeInsets.only(right: 16),
              itemBuilder: (_, i) {
                final c = _items[i];
                final world =
                    (c['world'] as String? ?? 'materie').toLowerCase();
                final color = _worldColors[world] ?? Colors.white;
                return _ChallengeCard(
                  title: c['title'] as String? ?? '',
                  description: c['description'] as String?,
                  xp: c['xp_reward'] as int? ?? 0,
                  world: world,
                  color: color,
                  onTap: () => widget.onWorldTap?.call(world),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final String title;
  final String? description;
  final int xp;
  final String world;
  final Color color;
  final VoidCallback onTap;

  const _ChallengeCard({
    required this.title,
    required this.description,
    required this.xp,
    required this.world,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.22),
                  color.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        world.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '+$xp XP',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                if (description?.isNotEmpty ?? false)
                  Text(
                    description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
