import 'package:flutter/material.dart';

/// Lightweight one-shot fade+slide entrance animation.
///
/// Designed for staggered list/grid entrances (Portal world cards, module
/// lists). Uses a single [AnimationController] and triggers only ONCE on
/// first build — keine 60fps-Dauerlast.
///
/// Performance-Hinweise:
/// - Animation läuft genau einmal (`forward()` ohne `repeat`).
/// - Nach Abschluss wird kein `AnimatedBuilder` mehr neu gebaut.
/// - Curve: `Curves.easeOutCubic` für ruhige, edle Anmutung.
class StaggeredFadeIn extends StatefulWidget {
  /// Position des Elements in der Liste/Grid (0-basiert).
  final int index;

  /// Verzögerung pro Index (z.B. 150ms für Portal-Karten, 50ms für Listen).
  final Duration perItemDelay;

  /// Dauer der einzelnen Animation.
  final Duration duration;

  /// Slide-Offset (z.B. `Offset(0.15, 0)` = 15% von rechts).
  /// `Offset.zero` => reines Fade.
  final Offset slideFrom;

  /// Initial-Verzögerung vor dem ersten Element.
  final Duration initialDelay;

  /// Curve für Fade + Slide.
  final Curve curve;

  final Widget child;

  const StaggeredFadeIn({
    super.key,
    required this.index,
    required this.child,
    this.perItemDelay = const Duration(milliseconds: 80),
    this.duration = const Duration(milliseconds: 420),
    this.slideFrom = const Offset(0, 0.08),
    this.initialDelay = Duration.zero,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _ctrl, curve: widget.curve);
    _slide = Tween<Offset>(begin: widget.slideFrom, end: Offset.zero)
        .animate(_fade);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    final totalDelay =
        widget.initialDelay + widget.perItemDelay * widget.index;
    Future.delayed(totalDelay, () {
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
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
