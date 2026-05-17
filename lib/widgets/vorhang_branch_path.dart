// Vorhang-Branch-Path — vertikaler Skill-Tree-Pfad statt ListTile-Liste.
//
// Rendert eine Branch (5 Module) als verbundene Knotenkette: links die
// Lichtspur mit Status-Dots (gold = completed, dimmed = available,
// grau = locked), rechts die Modul-Karte. Boss-Module bekommen einen
// größeren Dot mit Krone.

import 'package:flutter/material.dart';

class VorhangBranchPath extends StatelessWidget {
  final List<Map<String, dynamic>> modules;
  final void Function(Map<String, dynamic> module) onTap;
  final Color accent;
  final Color accentDim;

  const VorhangBranchPath({
    super.key,
    required this.modules,
    required this.onTap,
    this.accent = const Color(0xFFC9A84C),
    this.accentDim = const Color(0xFF8A7531),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      child: Column(
        children: [
          for (int i = 0; i < modules.length; i++)
            _PathRow(
              module: modules[i],
              isFirst: i == 0,
              isLast: i == modules.length - 1,
              accent: accent,
              accentDim: accentDim,
              onTap: onTap,
            ),
        ],
      ),
    );
  }
}

class _PathRow extends StatelessWidget {
  final Map<String, dynamic> module;
  final bool isFirst;
  final bool isLast;
  final Color accent;
  final Color accentDim;
  final void Function(Map<String, dynamic> module) onTap;

  const _PathRow({
    required this.module,
    required this.isFirst,
    required this.isLast,
    required this.accent,
    required this.accentDim,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = module['is_completed'] == true;
    final isUnlocked = module['is_unlocked'] == true;
    final isBoss = module['is_boss_module'] == true;
    final title = (module['title'] as String?) ?? '?';
    final subtitle = (module['subtitle'] as String?) ?? '';
    final code = (module['module_code'] as String?) ?? '';
    final xp = (module['xp_reward'] as num?)?.toInt() ?? 50;

    final dotColor = isCompleted
        ? accent
        : isUnlocked
            ? accentDim
            : Colors.white.withValues(alpha: 0.15);
    final lineColor = isCompleted
        ? accent.withValues(alpha: 0.7)
        : accentDim.withValues(alpha: 0.3);
    final dotSize = isBoss ? 28.0 : 18.0;
    final canTap = isUnlocked || isCompleted;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Path-Spur: oben/unten Linie + Status-Dot in der Mitte
          SizedBox(
            width: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isFirst ? Colors.transparent : lineColor,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isLast ? Colors.transparent : lineColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor.withValues(alpha: isCompleted ? 1.0 : 0.85),
                    border: Border.all(
                      color: isBoss
                          ? accent
                          : isCompleted
                              ? accent
                              : dotColor.withValues(alpha: 0.5),
                      width: isBoss ? 2 : 1.5,
                    ),
                    boxShadow: isCompleted
                        ? [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.6),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      isCompleted
                          ? Icons.check_rounded
                          : isUnlocked
                              ? (isBoss
                                  ? Icons.workspace_premium_rounded
                                  : Icons.lock_open_rounded)
                              : Icons.lock_rounded,
                      color: isUnlocked || isCompleted ? Colors.black : Colors.white24,
                      size: isBoss ? 16 : 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Modul-Karte
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: canTap ? () => onTap(module) : null,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: isCompleted
                          ? accent.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.02),
                      border: Border.all(
                        color: isBoss
                            ? accent.withValues(alpha: 0.55)
                            : isCompleted
                                ? accent.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.06),
                        width: isBoss ? 1.2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                code,
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            if (isBoss) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    accent,
                                    accent.withValues(alpha: 0.7),
                                  ]),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'BOSS',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              '+$xp XP',
                              style: TextStyle(
                                color: accent.withValues(alpha: 0.9),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: TextStyle(
                            color: canTap
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.4),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
