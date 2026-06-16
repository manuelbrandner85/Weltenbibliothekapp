import 'package:flutter/material.dart';
import '../core/responsive.dart';

/// One segment in a [WbSegmentedTabs] bar.
///
/// [label] is the visible German caption (may contain an emoji prefix).
/// [icon] is shown left of the label in the [WbTabsStyle.underline] style.
/// [accent] overrides the bar-wide accent for the selected state of this
/// single segment (used e.g. for colour-coded community filters).
class WbTabItem {
  final String label;
  final IconData? icon;
  final Color? accent;

  const WbTabItem({required this.label, this.icon, this.accent});
}

/// Visual variants for [WbSegmentedTabs].
enum WbTabsStyle {
  /// Rounded, horizontally scrollable pills (e.g. community feed filters).
  pills,

  /// Equal-width segments with an animated underline (e.g. detail panels).
  underline,
}

/// A polished, responsive segmented tab bar shared across the ENERGIE screens.
///
/// This unifies the previously hand-rolled, inconsistent filter/tab rows into
/// one accessible component: animated selection, per-segment accent colours,
/// `Semantics` for screen readers and responsive sizing via
/// [ResponsiveContext]. It is purely presentational — selection state stays in
/// the parent via [selectedIndex] / [onChanged], so behaviour is unchanged.
class WbSegmentedTabs extends StatelessWidget {
  final List<WbTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final WbTabsStyle style;

  /// Fallback accent used when a [WbTabItem] does not define its own.
  final Color accent;

  /// Outer padding around the whole bar.
  final EdgeInsetsGeometry padding;

  const WbSegmentedTabs({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    this.style = WbTabsStyle.pills,
    this.accent = const Color(0xFFAB47BC),
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final bar = style == WbTabsStyle.pills
        ? _buildPills(context)
        : _buildUnderline(context);
    return Padding(padding: padding, child: bar);
  }

  // ── Pills (scrollable) ───────────────────────────────────────────────────
  Widget _buildPills(BuildContext context) {
    final gap = context.rw(8);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            _PillSegment(
              item: items[i],
              selected: i == selectedIndex,
              accent: items[i].accent ?? accent,
              onTap: () => onChanged(i),
            ),
          ],
        ],
      ),
    );
  }

  // ── Underline (equal width) ──────────────────────────────────────────────
  Widget _buildUnderline(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++)
          Expanded(
            child: _UnderlineSegment(
              item: items[i],
              selected: i == selectedIndex,
              accent: items[i].accent ?? accent,
              onTap: () => onChanged(i),
            ),
          ),
      ],
    );
  }
}

class _PillSegment extends StatelessWidget {
  final WbTabItem item;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _PillSegment({
    required this.item,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: context.rw(16),
            vertical: context.rw(9),
          ),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.10),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.2),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.icon != null) ...[
                Icon(
                  item.icon,
                  size: context.rf(15),
                  color: selected ? Colors.white : Colors.white54,
                ),
                SizedBox(width: context.rw(6)),
              ],
              Text(
                item.label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white54,
                  fontSize: context.rf(13),
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnderlineSegment extends StatelessWidget {
  final WbTabItem item;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _UnderlineSegment({
    required this.item,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : Colors.white.withValues(alpha: 0.5);
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(vertical: context.rw(8)),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (item.icon != null) ...[
                Icon(item.icon, color: fg, size: context.rf(18)),
                SizedBox(width: context.rw(6)),
              ],
              Flexible(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: context.rf(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
