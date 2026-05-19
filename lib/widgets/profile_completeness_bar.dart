// Profile-Completeness-Bar — gamifizierter Fortschritt im Profil-Editor.
//
// Zeigt: "Profil 60%" + Progressbar + Mini-Checklist welche Felder noch
// fehlen. Optisch ein Glass-Banner oben im Editor; motiviert User die
// fehlenden Felder auszufüllen.
//
// Bewusst PRESENT-ONLY: kein Auto-XP-Trigger hier (Side-Effect-frei).
// Der Editor-Save selber kann später bei Completion-Increase einen
// GamificationService.addXp() absetzen.

import 'package:flutter/material.dart';

class ProfileField {
  final String key;
  final String label;
  final bool filled;
  const ProfileField({
    required this.key,
    required this.label,
    required this.filled,
  });
}

class ProfileCompletenessBar extends StatelessWidget {
  final List<ProfileField> fields;
  final Color accent;

  const ProfileCompletenessBar({
    super.key,
    required this.fields,
    this.accent = const Color(0xFFC9A84C),
  });

  double get _ratio {
    if (fields.isEmpty) return 0;
    final filled = fields.where((f) => f.filled).length;
    return filled / fields.length;
  }

  int get _percent => (_ratio * 100).round();

  String get _hint {
    if (_percent >= 100) return '✨ Profil komplett!';
    if (_percent >= 70) return 'Fast geschafft.';
    if (_percent >= 30) return 'Auf gutem Weg.';
    return 'Lege los — jedes Feld hilft.';
  }

  Color get _barColor {
    if (_percent >= 100) return const Color(0xFF4CAF50);
    if (_percent >= 70) return accent;
    return accent.withValues(alpha: 0.8);
  }

  @override
  Widget build(BuildContext context) {
    final missing = fields.where((f) => !f.filled).take(3).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.18),
            accent.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _barColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_percent%',
                  style: TextStyle(
                    color: _barColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Profil-Fortschritt',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _hint,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: _ratio),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation(_barColor),
              ),
            ),
          ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: missing
                  .map((f) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded,
                                size: 12, color: accent.withValues(alpha: 0.7)),
                            const SizedBox(width: 3),
                            Text(
                              f.label,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
