// WbTapScale -- universal tap-feedback wrapper.
//
// Wrap any tappable surface (card, button, tile, icon) to get a consistent
// premium press feel: a subtle scale-down on press + haptic feedback, springing
// back on release. This is the single source of truth for "tap feels alive".
//
// Accessibility / performance:
//   - Honours OS reduce-motion (MediaQuery.disableAnimations): skips the scale
//     animation but keeps the tap + haptic, so behaviour stays intact.
//   - Cheap: a single implicit AnimatedScale, no controllers, no overdraw.
//
// Pure Dart, no extra dependencies.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Haptic strength fired on press.
enum WbHaptic { none, selection, light, medium, heavy }

class WbTapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Scale applied while pressed (0..1). 0.96 is a subtle, premium default.
  final double pressedScale;

  /// Haptic fired on tap-down. Defaults to a light selection click.
  final WbHaptic haptic;

  /// Animation duration for the press/release.
  final Duration duration;

  /// Disables interaction + feedback when false (still renders the child).
  final bool enabled;

  const WbTapScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.96,
    this.haptic = WbHaptic.selection,
    this.duration = const Duration(milliseconds: 110),
    this.enabled = true,
  });

  @override
  State<WbTapScale> createState() => _WbTapScaleState();
}

class _WbTapScaleState extends State<WbTapScale> {
  bool _pressed = false;

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  void _setPressed(bool v) {
    if (!widget.enabled) return;
    if (_pressed != v) setState(() => _pressed = v);
  }

  void _fireHaptic() {
    switch (widget.haptic) {
      case WbHaptic.none:
        break;
      case WbHaptic.selection:
        HapticFeedback.selectionClick();
      case WbHaptic.light:
        HapticFeedback.lightImpact();
      case WbHaptic.medium:
        HapticFeedback.mediumImpact();
      case WbHaptic.heavy:
        HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = (_pressed && widget.enabled && !_reduceMotion)
        ? widget.pressedScale
        : 1.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        _setPressed(true);
        if (widget.enabled) _fireHaptic();
      },
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.enabled ? widget.onTap : null,
      onLongPress: widget.enabled ? widget.onLongPress : null,
      child: AnimatedScale(
        scale: target,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
