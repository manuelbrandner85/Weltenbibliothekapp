/// Collapsible home-screen section (Feature B).
///
/// Wraps a secondary block so it can be folded away by default, cutting the
/// visual overload on the home tabs WITHOUT removing any content or breaking
/// any function — everything is one tap away. Header reuses the unified
/// section-header look (accent bar + UPPERCASE) plus an animated chevron.
library;

import 'package:flutter/material.dart';
import 'wb_section_header.dart';

class WbCollapsibleSection extends StatefulWidget {
  final String label;
  final Color accent;
  final Color? accentBright;

  /// Optional muted trailing hint shown next to the title.
  final String? trailing;

  /// Section body, built lazily only while expanded.
  final WidgetBuilder bodyBuilder;

  /// Whether the section starts open. Secondary sections default to closed.
  final bool initiallyExpanded;

  const WbCollapsibleSection({
    super.key,
    required this.label,
    required this.accent,
    required this.bodyBuilder,
    this.accentBright,
    this.trailing,
    this.initiallyExpanded = false,
  });

  @override
  State<WbCollapsibleSection> createState() => _WbCollapsibleSectionState();
}

class _WbCollapsibleSectionState extends State<WbCollapsibleSection> {
  late bool _open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: WbSectionHeader(
                    label: widget.label,
                    accent: widget.accent,
                    accentBright: widget.accentBright,
                    trailing: widget.trailing,
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: widget.accent.withValues(alpha: 0.8),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _open
                ? widget.bodyBuilder(context)
                : const SizedBox.shrink(),
          ),
          crossFadeState:
              _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 240),
          sizeCurve: Curves.easeInOut,
        ),
      ],
    );
  }
}
