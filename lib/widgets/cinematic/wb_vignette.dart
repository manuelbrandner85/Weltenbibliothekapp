import 'package:flutter/material.dart';

/// Globales Cinemascope-Vignette-Overlay.
///
/// Statisch (kein repaint), `IgnorePointer`, in `RepaintBoundary` gewrappt.
/// Über den gesamten Screen-Stack legen, vor UI-Layern.
class WBVignette extends StatelessWidget {
  final double intensity; // 0..1, default 0.55 = 55% Edges-Black
  final double innerRadius; // wo Schwarz ansetzt (0..1)

  const WBVignette({
    super.key,
    this.intensity = 0.55,
    this.innerRadius = 0.55,
  });

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: _VignetteImpl(),
    );
  }
}

class _VignetteImpl extends StatelessWidget {
  const _VignetteImpl();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.05,
            colors: [
              Colors.transparent,
              const Color(0xFF000000).withValues(alpha: 0.55),
              const Color(0xFF000000).withValues(alpha: 0.92),
            ],
            stops: const [0.55, 0.85, 1.0],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
