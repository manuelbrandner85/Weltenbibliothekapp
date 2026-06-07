/// Virgil — der schwebende AI-Begleiter unten rechts.
/// Pulsierender Glas-Kristall, der bei AI-Insights aufleuchtet.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'kb_design.dart';

class VirgilOrb extends StatefulWidget {
  final String? insight;
  final bool thinking;
  final VoidCallback? onTap;

  const VirgilOrb({
    super.key,
    this.insight,
    this.thinking = false,
    this.onTap,
  });

  @override
  State<VirgilOrb> createState() => _VirgilOrbState();
}

class _VirgilOrbState extends State<VirgilOrb> with TickerProviderStateMixin {
  late final AnimationController _breathe;
  late final AnimationController _think;

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _think = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (widget.thinking) _think.repeat();
  }

  @override
  void didUpdateWidget(covariant VirgilOrb old) {
    super.didUpdateWidget(old);
    if (widget.thinking && !_think.isAnimating) {
      _think.repeat();
    } else if (!widget.thinking && _think.isAnimating) {
      _think.stop();
    }
    // 2026-06-07: Auto-Popup-Bubble entfernt (User-Feedback): die
    // KI-Einsicht wird ohnehin als AiInsightCard in der Recherche
    // angezeigt -- die Overlay-Bubble war redundant und blockierte
    // ein paar Sekunden lang die darunter liegenden Karten.
  }

  @override
  void dispose() {
    _breathe.dispose();
    _think.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_breathe, _think]),
      builder: (_, __) {
        final pulse = 0.85 + 0.15 * math.sin(_breathe.value * math.pi);
        final thinkPulse = widget.thinking
            ? 1.0 + 0.15 * math.sin(_think.value * math.pi * 2)
            : 1.0;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onTap?.call();
          },
          child: Transform.scale(
            scale: thinkPulse,
            child: _buildOrb(pulse),
          ),
        );
      },
    );
  }

  Widget _buildOrb(double pulse) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            KbDesign.neonRedSoft.withValues(alpha: 0.95 * pulse),
            KbDesign.neonRed.withValues(alpha: 0.85 * pulse),
            const Color(0xFF300012).withValues(alpha: 0.95),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: KbDesign.neonRed.withValues(alpha: 0.6 * pulse),
            blurRadius: 30 + 12 * pulse,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.45 * pulse),
          width: 1.5,
        ),
      ),
      child: const Center(
        child: Text(
          'V',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w300,
            fontSize: 26,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
