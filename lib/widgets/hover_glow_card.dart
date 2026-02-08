/// Interaktive Karte mit Glow-Effekt beim Hover
/// Verwendet für Spirit-Module und andere interaktive Elemente
library;

import 'package:flutter/material.dart';

class HoverGlowCard extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double glowIntensity;
  final Duration duration;

  const HoverGlowCard({
    super.key,
    required this.child,
    required this.glowColor,
    this.glowIntensity = 12.0,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<HoverGlowCard> createState() => _HoverGlowCardState();
}

class _HoverGlowCardState extends State<HoverGlowCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: widget.duration,
        decoration: BoxDecoration(
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: widget.glowColor.withValues(alpha: 0.5),
                    blurRadius: widget.glowIntensity,
                    spreadRadius: widget.glowIntensity / 2,
                  ),
                ]
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}
