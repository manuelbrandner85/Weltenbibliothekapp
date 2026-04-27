import 'package:flutter/material.dart';

/// 🎨 WB SHIMMER — Geteilter Loading-Skelett-Effekt im Home-Tab-Stil.
///
/// Konsolidiert die zwei alten Implementierungen:
/// - `_Shimmer` in `screens/materie/home_tab_v5.dart`
/// - `_cosmicShimmer` in `screens/energie/home_tab_v5.dart`
///
/// Verwendung:
/// ```dart
/// WbShimmer(width: 80, height: 16, radius: 4)
/// // oder welt-aware:
/// WbShimmer.world('energie', width: 100, height: 20)
/// ```
///
/// Animiert über 1.5s einen subtilen Glow-Loop. Touch-Target wird nicht
/// blockiert (IgnorePointer-Wrap empfohlen wenn nötig).
class WbShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  final Color? baseColor;
  final Color? highlightColor;

  const WbShimmer({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
    this.baseColor,
    this.highlightColor,
  });

  /// Welt-aware Konstruktor — passt baseColor/highlightColor an.
  factory WbShimmer.world(
    String world, {
    Key? key,
    required double width,
    required double height,
    double radius = 8,
  }) {
    final isEnergie = world == 'energie';
    return WbShimmer(
      key: key,
      width: width,
      height: height,
      radius: radius,
      baseColor: isEnergie
          ? const Color(0xFFAB47BC).withValues(alpha: 0.08)
          : const Color(0xFF1E88E5).withValues(alpha: 0.08),
      highlightColor: isEnergie
          ? const Color(0xFFCE93D8).withValues(alpha: 0.18)
          : const Color(0xFF64B5F6).withValues(alpha: 0.18),
    );
  }

  @override
  State<WbShimmer> createState() => _WbShimmerState();
}

class _WbShimmerState extends State<WbShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ?? Colors.white.withValues(alpha: 0.06);
    final highlight = widget.highlightColor ?? Colors.white.withValues(alpha: 0.14);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(base, highlight, _ctrl.value),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}
