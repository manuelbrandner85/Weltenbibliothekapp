import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/wb_cinematic_tokens.dart';

/// Wiederverwendbare Premium-Glass-Card.
///
/// Verwendet einen einzelnen `BackdropFilter` (medium blur) und genau
/// 2 BoxShadows (drop + welt-glow), damit GPU-Last minimal bleibt.
/// Top-Edge Specular simuliert echtes Glas-Licht.
/// Wrap-bar mit `RepaintBoundary` von außen, falls dauerhaft animiert.
class WBGlassCard extends StatelessWidget {
  final Widget child;
  final WBWorld world;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool elevated;
  final bool showGlow;
  final VoidCallback? onTap;

  const WBGlassCard({
    super.key,
    required this.child,
    this.world = WBWorld.neutral,
    this.padding = const EdgeInsets.all(WBSpace.lg),
    this.radius = WBRadius.lg,
    this.elevated = false,
    this.showGlow = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final wb = context.wb;
    final palette = wb.palette(world);
    final bg = elevated ? wb.glassElevated : wb.glassBase;

    final cardContent = Stack(
      children: [
        // Content layer
        Container(
          padding: padding,
          child: child,
        ),
        // Top-edge specular highlight — simulates glass refractive index
        IgnorePointer(
          child: Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: radius + 2,
            child: Container(
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(radius)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.07),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );

    final card = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: wb.blurMedium, sigmaY: wb.blurMedium),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: wb.glassStroke, width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.40),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
              if (showGlow && world != WBWorld.neutral)
                BoxShadow(
                  color: palette.primary.withValues(alpha: 0.18),
                  blurRadius: 28,
                  spreadRadius: 0,
                ),
            ],
          ),
          child: cardContent,
        ),
      ),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        splashColor: palette.primary.withValues(alpha: 0.12),
        highlightColor: palette.primary.withValues(alpha: 0.06),
        child: card,
      ),
    );
  }
}
