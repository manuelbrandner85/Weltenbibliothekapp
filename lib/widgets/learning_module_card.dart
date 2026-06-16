// 📚 LEARNING-MODULE-CARD — Uebersichts-Widget fuer eine Lernreihe.
//
// Renders one learning module in the overview: emoji avatar, module name,
// description, completion progress bar, lesson count and a navigation
// affordance. Used in both the narrow (list) and wide (grid) layouts of
// LernreihenIndexScreen, so it stays self-contained and fits a bounded cell.

import 'package:flutter/material.dart';

import '../services/learning_module_service.dart';

class LearningModuleCard extends StatelessWidget {
  final LearningModule module;
  final LearningModuleProgress progress;
  final VoidCallback onTap;

  const LearningModuleCard({
    super.key,
    required this.module,
    required this.progress,
    required this.onTap,
  });

  static const Color _surface = Color(0xFF100B1E);

  @override
  Widget build(BuildContext context) {
    final accent = module.accent;
    final done = progress.completed;
    final total = progress.total;

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _Avatar(emoji: module.emoji, accent: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              module.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (progress.isComplete)
                            Icon(Icons.verified, size: 16, color: accent),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        module.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _LessonBadge(count: module.lessonCount, accent: accent),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress.fraction,
                                minHeight: 4,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.08,
                                ),
                                valueColor: AlwaysStoppedAnimation(accent),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '$done/$total',
                            style: TextStyle(
                              color: accent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: accent.withValues(alpha: 0.7)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String emoji;
  final Color accent;
  const _Avatar({required this.emoji, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            accent.withValues(alpha: 0.45),
            accent.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 22)),
    );
  }
}

// Small pill showing the number of daily lessons (e.g. "7 Tage").
class _LessonBadge extends StatelessWidget {
  final int count;
  final Color accent;
  const _LessonBadge({required this.count, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count Tage',
        style: TextStyle(
          color: accent,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
