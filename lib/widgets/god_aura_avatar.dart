/// Animated deity avatar for the Goetterdialog: a KI-pre-rendered light-being
/// portrait with a gentle living aura (breathing scale + pulsing glow + rim).
/// Self-contained (own ticker) so it works in lists and headers alike.
/// Falls back to the god's emoji if the asset is missing.
library;

import 'package:flutter/material.dart';

class GodAuraAvatar extends StatefulWidget {
  final String assetPath;
  final Color accent;
  final double size;
  final String fallbackEmoji;
  final bool animate;

  const GodAuraAvatar({
    super.key,
    required this.assetPath,
    required this.accent,
    required this.fallbackEmoji,
    this.size = 56,
    this.animate = true,
  });

  @override
  State<GodAuraAvatar> createState() => _GodAuraAvatarState();
}

class _GodAuraAvatarState extends State<GodAuraAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
    if (widget.animate) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final img = ClipOval(
      child: ShaderMask(
        shaderCallback: (rect) => const RadialGradient(
          colors: [Colors.white, Colors.white, Colors.transparent],
          stops: [0.0, 0.76, 1.0],
        ).createShader(rect),
        blendMode: BlendMode.dstIn,
        child: Image.asset(
          widget.assetPath,
          width: s * 0.86,
          height: s * 0.86,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => Container(
            width: s * 0.86,
            height: s * 0.86,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [widget.accent, widget.accent.withValues(alpha: 0.3)],
              ),
            ),
            child: Text(widget.fallbackEmoji,
                style: TextStyle(fontSize: s * 0.42)),
          ),
        ),
      ),
    );

    return SizedBox(
      width: s,
      height: s,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value; // 0..1
          final pulse = 0.5 + 0.5 * _sin01(t); // smooth 0..1
          final breathe = 0.95 + 0.045 * pulse;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing accent glow.
              Container(
                width: s,
                height: s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.accent.withValues(alpha: 0.18 + 0.16 * pulse),
                      widget.accent.withValues(alpha: 0.0),
                    ],
                    stops: const [0.45, 1.0],
                  ),
                ),
              ),
              // Breathing portrait.
              Transform.scale(scale: breathe, child: img),
              // Rim.
              Container(
                width: s * 0.86,
                height: s * 0.86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.accent.withValues(alpha: 0.45 + 0.2 * pulse),
                    width: 1.4,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Smooth sine-based 0..1 (no dart:math import needed for one use).
  double _sin01(double t) {
    // Triangle-ish smoothstep approximation of a sine pulse.
    final x = t < 0.5 ? t * 2 : (1 - t) * 2; // 0..1..0
    return x * x * (3 - 2 * x); // smoothstep
  }
}
