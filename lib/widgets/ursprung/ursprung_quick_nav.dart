import 'package:flutter/material.dart';

import '../animations/wb_tap_scale.dart';

/// A single entry in [UrsprungQuickNav].
///
/// Plain data class -- NOT a Dart-3 record type (named records crash dart2js
/// on the web build, see CLAUDE.md rule 8).
class UrsprungQuickNavItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const UrsprungQuickNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

/// 🌀 Schnellzugriff-Streifen fuer den Ursprung-Home-Tab.
///
/// Renders a horizontally scrollable row of accent-colored chips that let the
/// user jump straight to a content section instead of scrolling the whole
/// (very long) page. This is purely a navigation aid -- it owns no content and
/// no state; each chip just triggers its [UrsprungQuickNavItem.onTap] (the host
/// wires those to `Scrollable.ensureVisible` on the target section).
class UrsprungQuickNav extends StatelessWidget {
  final List<UrsprungQuickNavItem> items;
  final Color accent;

  const UrsprungQuickNav({
    super.key,
    required this.items,
    this.accent = const Color(0xFF00D4AA),
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = items[i];
          return WbTapScale(
            onTap: item.onTap,
            child: Semantics(
              button: true,
              label: item.label,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, size: 15, color: accent),
                    const SizedBox(width: 6),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
