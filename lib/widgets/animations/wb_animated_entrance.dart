// WbAnimatedEntrance -- staggered fade + slide-in on first build.
//
// Thin, reusable wrapper around flutter_animate for consistent entrance
// choreography across the app. Pass an [index] to stagger a list/grid so items
// cascade in instead of popping at once.
//
// Accessibility:
//   - Honours OS reduce-motion (MediaQuery.disableAnimations): renders the
//     child instantly with no animation.
//
// Example:
//   ListView(children: [
//     for (var i = 0; i < cards.length; i++)
//       WbAnimatedEntrance(index: i, child: cards[i]),
//   ]);

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WbAnimatedEntrance extends StatelessWidget {
  final Widget child;

  /// Position in a list/grid -- multiplies [stagger] for a cascade. 0 = first.
  final int index;

  /// Per-index delay added on top of [baseDelay].
  final Duration stagger;

  /// Delay before the first item animates.
  final Duration baseDelay;

  /// Duration of the fade/slide.
  final Duration duration;

  /// Vertical slide distance in logical pixels (positive = up into place).
  final double slideY;

  const WbAnimatedEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.stagger = const Duration(milliseconds: 60),
    this.baseDelay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.slideY = 16,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return child;

    final delay = baseDelay + stagger * index;
    final begin =
        Offset(0, slideY / 100); // flutter_animate uses fractional offset

    return child
        .animate()
        .fadeIn(delay: delay, duration: duration, curve: Curves.easeOut)
        .slide(
          begin: begin,
          end: Offset.zero,
          delay: delay,
          duration: duration,
          curve: Curves.easeOutCubic,
        );
  }
}
