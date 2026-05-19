import 'package:flutter/material.dart';
import '../../theme/wb_cinematic_tokens.dart';

/// Staggered fade+slide reveal for list/grid children.
///
/// Wrap a `Column` or `ListView` child to animate it in with a staggered delay.
/// ```dart
/// Column(children: [
///   WBStaggerReveal(index: 0, child: MyCard()),
///   WBStaggerReveal(index: 1, child: MyCard()),
/// ])
/// ```
class WBStaggerReveal extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration baseDelay;
  final Duration staggerStep;
  final Duration duration;
  final Curve curve;
  final double slideOffset;

  const WBStaggerReveal({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = const Duration(milliseconds: 100),
    this.staggerStep = const Duration(milliseconds: 60),
    this.duration = WBMotion.card,
    this.curve = Curves.easeOutCubic,
    this.slideOffset = 24.0,
  });

  @override
  State<WBStaggerReveal> createState() => _WBStaggerRevealState();
}

class _WBStaggerRevealState extends State<WBStaggerReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);

    final curved = CurvedAnimation(parent: _ctrl, curve: widget.curve);
    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.slideOffset),
      end: Offset.zero,
    ).animate(curved);

    final delay = widget.baseDelay + widget.staggerStep * widget.index;

    Future.delayed(delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(
          offset: _slide.value,
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
