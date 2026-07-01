/// Unified section header for all four world home tabs.
///
/// Single source of truth for the "SECTION LABEL" look so Materie, Energie,
/// Vorhang and Ursprung render section titles identically (only the accent
/// color differs per world). Style: a short vertical accent bar + an
/// UPPERCASE, letter-spaced label, with an optional muted trailing hint.
///
/// Adopted from the clean Vorhang/Ursprung `_sectionLabel` style (Feature A1).
library;

import 'package:flutter/material.dart';

class WbSectionHeader extends StatelessWidget {
  /// Section title. Rendered UPPERCASE by the widget itself — pass normal text.
  final String label;

  /// World accent color (gold / cyan / purple / blue).
  final Color accent;

  /// Optional brighter accent for the top of the bar gradient. Defaults to
  /// [accent] when omitted.
  final Color? accentBright;

  /// Optional muted trailing hint (e.g. "6 Pfade · 30 Module").
  final String? trailing;

  const WbSectionHeader({
    super.key,
    required this.label,
    required this.accent,
    this.accentBright,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final bright = accentBright ?? accent;
    return Row(
      children: [
        Container(
          width: 3,
          height: 13,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [bright, accent.withValues(alpha: 0.2)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 4.0,
              color: accent.withValues(alpha: 0.85),
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Text(
            trailing!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}
