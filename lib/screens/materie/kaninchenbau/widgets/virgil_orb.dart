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

class _VirgilOrbState extends State<VirgilOrb>
    with TickerProviderStateMixin {
  late final AnimationController _breathe;
  late final AnimationController _think;
  bool _showBubble = false;

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
    if (widget.insight != null && old.insight != widget.insight) {
      _flashBubble();
    }
  }

  void _flashBubble() {
    setState(() => _showBubble = true);
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) setState(() => _showBubble = false);
    });
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
        return Stack(
          alignment: Alignment.bottomRight,
          clipBehavior: Clip.none,
          children: [
            if (_showBubble && widget.insight != null)
              Positioned(
                right: 70,
                bottom: 0,
                child: _buildBubble(widget.insight!),
              ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (widget.insight != null) {
                  setState(() => _showBubble = !_showBubble);
                }
                widget.onTap?.call();
              },
              child: Transform.scale(
                scale: thinkPulse,
                child: _buildOrb(pulse),
              ),
            ),
          ],
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

  Widget _buildBubble(String text) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: KbDesign.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: KbDesign.neonRed.withValues(alpha: 0.55),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: KbDesign.neonRed.withValues(alpha: 0.25),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    size: 14, color: KbDesign.goldAccent),
                const SizedBox(width: 6),
                const Text(
                  'VIRGIL',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
