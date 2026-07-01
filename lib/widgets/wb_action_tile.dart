/// Unified tappable tile for tools / actions across all four world home tabs.
///
/// Single source of truth so Vorhang, Ursprung, Materie and Energie render
/// tool/action rows identically: icon-badge + title + subtitle + trailing
/// chevron. Replaces the divergent per-world variants (Vorhang chevron vs.
/// Ursprung "ÖFFNEN" badge) with one consistent affordance (Feature A2).
///
/// Two visual weights:
/// - standard: flat surface card with a subtle accent border (default rows)
/// - featured: gradient card with glow, for a section's hero/core tool
library;

import 'package:flutter/material.dart';

class WbActionTile extends StatelessWidget {
  /// Leading glyph as an emoji string. Provide either [emoji] or [icon].
  final String? emoji;

  /// Leading glyph as a Material icon. Provide either [emoji] or [icon].
  final IconData? icon;

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// World accent color.
  final Color accent;

  /// Card background surface (world surface color).
  final Color surface;

  /// Featured (gradient + glow) styling for a section's core tool.
  final bool featured;

  const WbActionTile({
    super.key,
    this.emoji,
    this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.accent,
    required this.surface,
    this.featured = false,
  }) : assert(emoji != null || icon != null,
            'WbActionTile needs either an emoji or an icon');

  @override
  Widget build(BuildContext context) {
    final radius = featured ? 18.0 : 16.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(featured ? 18 : 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: featured ? null : surface,
            gradient: featured
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.18),
                      accent.withValues(alpha: 0.05),
                      surface,
                    ],
                  )
                : null,
            border: Border.all(
              color: accent.withValues(alpha: featured ? 0.45 : 0.3),
              width: featured ? 1.2 : 1,
            ),
            boxShadow: featured
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.15),
                      blurRadius: 26,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              _leading(featured),
              SizedBox(width: featured ? 16 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: featured ? 16 : 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right,
                  color: accent.withValues(alpha: 0.7), size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _leading(bool featured) {
    final double box = featured ? 52 : 46;
    return Container(
      width: box,
      height: box,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: featured ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: featured ? null : BorderRadius.circular(12),
        color: accent.withValues(alpha: featured ? 0.15 : 0.12),
        border: Border.all(color: accent.withValues(alpha: featured ? 0.5 : 0.4)),
      ),
      child: emoji != null
          ? Text(emoji!, style: TextStyle(fontSize: featured ? 26 : 22))
          : Icon(icon, color: accent, size: featured ? 26 : 22),
    );
  }
}
