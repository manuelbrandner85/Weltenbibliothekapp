/// 4-Sekunden-Cinematic-Intro: Funke → Sternfeld → Spirale → Sucheingabe.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'kb_design.dart';

class CinematicIntro extends StatefulWidget {
  final void Function(String topic) onSubmit;
  const CinematicIntro({super.key, required this.onSubmit});

  @override
  State<CinematicIntro> createState() => _CinematicIntroState();
}

class _CinematicIntroState extends State<CinematicIntro>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _pulse;
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _intro.forward().then((_) {
      if (mounted) {
        setState(() => _ready = true);
        _focus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _skip() {
    if (_intro.isAnimating) {
      _intro.value = 1.0;
    }
  }

  void _submit() {
    final v = _ctrl.text.trim();
    if (v.isEmpty) return;
    HapticFeedback.heavyImpact();
    widget.onSubmit(v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _skip,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: KbDesign.voidBlack,
        child: AnimatedBuilder(
          animation: Listenable.merge([_intro, _pulse]),
          builder: (_, __) {
            final p = _intro.value;
            return Stack(
              children: [
                // Sternfeld-Hintergrund
                Positioned.fill(
                  child: CustomPaint(
                    painter: _StarfieldPainter(progress: p),
                  ),
                ),
                // Glow-Spirale → Suchfeld
                Center(
                  child: Opacity(
                    opacity: p < 0.2 ? p * 5 : 1.0,
                    child: Transform.scale(
                      scale: 0.7 + p * 0.3,
                      child: _ready ? _buildPrompt() : _buildSpiral(p),
                    ),
                  ),
                ),
                if (_ready)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 12,
                    left: 12,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white54),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSpiral(double p) {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            KbDesign.neonRed.withValues(alpha: 0.8 * p),
            KbDesign.neonRed.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 8 + p * 60,
          height: 8 + p * 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: KbDesign.neonRedSoft,
            boxShadow: [
              BoxShadow(
                color: KbDesign.neonRed.withValues(alpha: 0.8),
                blurRadius: 30 + p * 60,
                spreadRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrompt() {
    final pulse = 0.85 + 0.15 * _pulse.value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🐇',
            style: TextStyle(fontSize: 52),
          ),
          const SizedBox(height: 20),
          Text(
            'Worüber willst du tiefer graben?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 22,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 28),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: KbDesign.neonRed.withValues(alpha: pulse * 0.5),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      KbDesign.neonRed.withValues(alpha: 0.2 * pulse),
                  blurRadius: 24 + 12 * pulse,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                letterSpacing: 0.3,
              ),
              decoration: InputDecoration(
                hintText: 'z.B. Pfizer, WEF, Bourla, MK Ultra…',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 16,
                ),
                prefixIcon: Icon(Icons.search_rounded,
                    color: KbDesign.neonRedSoft.withValues(alpha: 0.85)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded),
                  color: KbDesign.neonRedSoft,
                  onPressed: _submit,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 18),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Tap to search · Enter zum Senden',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.32),
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  final double progress;
  _StarfieldPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint();
    for (var i = 0; i < 220; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 1.6 + 0.3;
      final alpha = (rng.nextDouble() * 0.7 + 0.2) * progress;
      paint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter old) =>
      old.progress != progress;
}
