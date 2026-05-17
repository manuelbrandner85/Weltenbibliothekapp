// Shimmer-Skeleton-Loader im Weltenbibliothek-Design.
//
// Verwendung statt CircularProgressIndicator für gefühlte Performance:
//   WBSkeleton(width: double.infinity, height: 18)        // Textzeile
//   WBSkeleton.circle(size: 40)                           // Avatar
//   WBSkeletonCard(height: 120, accent: widget.accent)    // Karten
//
// Animation läuft global synchron, damit mehrere Skeletons im selben
// Frame pulsieren — wirkt ruhiger als unabhängige Phasen.

import 'package:flutter/material.dart';

class WBSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Color? accent;

  const WBSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.accent,
  });

  factory WBSkeleton.circle({Key? key, required double size, Color? accent}) {
    return WBSkeleton(
      key: key,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
      accent: accent,
    );
  }

  @override
  State<WBSkeleton> createState() => _WBSkeletonState();
}

class _WBSkeletonState extends State<WBSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.accent ?? const Color(0xFFC9A84C);
    final radius = widget.borderRadius ?? BorderRadius.circular(8);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * t, 0),
              end: Alignment(1 + 2 * t, 0),
              colors: [
                base.withValues(alpha: 0.04),
                base.withValues(alpha: 0.14),
                base.withValues(alpha: 0.04),
              ],
              stops: const [0.2, 0.5, 0.8],
            ),
            border: Border.all(color: base.withValues(alpha: 0.08)),
          ),
        );
      },
    );
  }
}

/// Compound-Skeleton für Karten-Layouts (Avatar + 2 Textzeilen).
/// Nutze überall wo eine Liste von Items lädt.
class WBSkeletonListTile extends StatelessWidget {
  final Color? accent;
  final bool showAvatar;

  const WBSkeletonListTile({super.key, this.accent, this.showAvatar = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          if (showAvatar) ...[
            WBSkeleton.circle(size: 40, accent: accent),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WBSkeleton(width: 140, height: 14, accent: accent),
                const SizedBox(height: 8),
                WBSkeleton(width: double.infinity, height: 10, accent: accent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WBSkeletonCard extends StatelessWidget {
  final double height;
  final Color? accent;
  final EdgeInsetsGeometry margin;

  const WBSkeletonCard({
    super.key,
    this.height = 120,
    this.accent,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: WBSkeleton(
        width: double.infinity,
        height: height,
        borderRadius: BorderRadius.circular(16),
        accent: accent,
      ),
    );
  }
}
