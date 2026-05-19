// 🎬 CINEMATIC SPLASH SCREEN - Hyperrealistisches Intro vor App-Start
//
// 5-Sekunden-Sequenz beim allerersten App-Start (und optional bei jedem Start):
//
//   0.0 - 0.8s: Schwarzer Void, Particles erwachen
//   0.8 - 2.2s: 4 Welt-Orbs fliegen aus den Ecken in die Mitte
//   2.2 - 3.0s: Konvergenz-Burst (goldener Lichtblitz)
//   3.0 - 4.2s: Logo-Reveal mit Scale + Glow
//   4.2 - 5.0s: Subtitle "Wo die Wahrheit aus 4 Perspektiven ans Licht kommt"
//                + Fade-Out zum naechsten Screen
//
// User kann mit Tap ueberspringen (HapticFeedback).

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 4 Welt-Akzentfarben fuer die Konvergenz.
const _materieColor = Color(0xFFE53935);   // Rot
const _energieColor = Color(0xFF7C4DFF);   // Lila
const _vorhangColor = Color(0xFFC9A84C);   // Gold
const _ursprungColor = Color(0xFF00D4AA);  // Cyan
const _bgVoid = Color(0xFF02010A);
const _gold = Color(0xFFFFD700);

class CinematicSplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final Duration totalDuration;

  const CinematicSplashScreen({
    super.key,
    required this.onComplete,
    this.totalDuration = const Duration(milliseconds: 7000),
  });

  @override
  State<CinematicSplashScreen> createState() => _CinematicSplashScreenState();
}

class _CinematicSplashScreenState extends State<CinematicSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _master;
  late final AnimationController _ambient;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _master = AnimationController(vsync: this, duration: widget.totalDuration)
      ..forward();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _master.addStatusListener((s) {
      if (s == AnimationStatus.completed && !_completed) {
        _completed = true;
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _master.dispose();
    _ambient.dispose();
    super.dispose();
  }

  void _skip() {
    if (_completed) return;
    HapticFeedback.lightImpact();
    _completed = true;
    _master.stop();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    // Wall-time-Schwellen (in ms). Buildup laeuft genauso schnell wie vorher,
    // der Logo-Reveal wird nur ~2s laenger gehalten, bevor er ausfadet.
    final totalMs = widget.totalDuration.inMilliseconds;
    final size = MediaQuery.of(context).size;

    return Material(
      color: _bgVoid,
      child: GestureDetector(
        onTap: _skip,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _master,
          builder: (context, _) {
            final ms = _master.value * totalMs;
            // Lokale Phasenwerte (0..1).
            final particleAlpha =
                ((ms - 250) / 500).clamp(0.0, 0.4);
            final orbP =
                Curves.easeInOutCubic.transform(((ms - 750) / 2500).clamp(0.0, 1.0));
            final burstP = ((ms - 2000) / 1250).clamp(0.0, 1.0);
            final logoP = ((ms - 2750) / 1150).clamp(0.0, 1.0);
            final subtitleP = ((ms - 3900) / 1000).clamp(0.0, 1.0);
            final fadeP = ((ms - (totalMs - 500)) / 500).clamp(0.0, 1.0);

            return Stack(fit: StackFit.expand, children: [
              // Layer 1: Particles (subtil, ambient)
              if (particleAlpha > 0)
                Opacity(
                  opacity: particleAlpha,
                  child: AnimatedBuilder(
                    animation: _ambient,
                    builder: (_, __) => CustomPaint(
                      painter: _ParticleField(_ambient.value),
                      size: Size.infinite,
                    ),
                  ),
                ),

              // Layer 2: 4 Welt-Orbs Konvergenz (waehrend Buildup)
              if (ms > 750 && ms < 3250)
                CustomPaint(
                  painter: _WeltOrbsConverge(orbP),
                  size: Size.infinite,
                ),

              // Layer 3: Konvergenz-Burst (goldener Lichtblitz)
              if (ms > 2000 && ms < 3250)
                Center(child: _BurstFlash(progress: burstP)),

              // Layer 4: Logo + Title Reveal (haelt bis Fade beginnt)
              if (ms > 2750)
                SafeArea(
                  minimum: const EdgeInsets.symmetric(horizontal: 24),
                  child: Center(
                    child: _LogoReveal(
                      progress: logoP,
                      maxWidth: size.width - 48,
                    ),
                  ),
                ),

              // Layer 5: Subtitle
              if (ms > 3900)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 80 + MediaQuery.of(context).padding.bottom,
                  child: _Subtitle(progress: subtitleP),
                ),

              // Layer 6: Skip hint (waehrend Buildup + Hold)
              if (ms > 250 && ms < totalMs - 500)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  right: 16,
                  child: Opacity(
                    opacity: 0.45,
                    child: Text(
                      'TIPPEN ZUM UEBERSPRINGEN',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

              // Layer 7: Final fade-out overlay
              if (fadeP > 0)
                IgnorePointer(
                  child: Container(color: _bgVoid.withValues(alpha: fadeP)),
                ),
            ]);
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LAYER PAINTERS
// ─────────────────────────────────────────────────────────────────────────────

class _ParticleField extends CustomPainter {
  final double t;
  _ParticleField(this.t);
  static const _count = 80;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint();
    for (var i = 0; i < _count; i++) {
      final baseX = rng.nextDouble();
      final baseY = rng.nextDouble();
      final phase = rng.nextDouble() * 2 * math.pi;
      final speed = 0.05 + rng.nextDouble() * 0.15;
      final x = ((baseX + t * speed) % 1.0) * size.width;
      final y = ((baseY + t * speed * 0.6) % 1.0) * size.height;
      final alpha = 0.15 + 0.40 * math.sin(t * 2 * math.pi + phase).abs();
      final radius = 0.6 + rng.nextDouble() * 1.4;
      paint.color = const Color(0xFFFFD700).withValues(alpha: alpha * 0.5);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleField old) => old.t != t;
}

class _WeltOrbsConverge extends CustomPainter {
  final double progress; // 0..1
  _WeltOrbsConverge(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final orbs = <(Color, Offset)>[
      (_materieColor, Offset.zero), // top-left
      (_energieColor, Offset(size.width, 0)), // top-right
      (_vorhangColor, Offset(0, size.height)), // bottom-left
      (_ursprungColor, Offset(size.width, size.height)), // bottom-right
    ];
    for (final (color, start) in orbs) {
      final pos = Offset.lerp(start, center, progress)!;
      // Glow halo
      final haloRadius = 60 + (1 - progress) * 40;
      canvas.drawCircle(
        pos,
        haloRadius,
        Paint()
          ..color = color.withValues(alpha: 0.35 + progress * 0.30)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, haloRadius * 0.6),
      );
      // Core
      canvas.drawCircle(
        pos,
        14 + progress * 6,
        Paint()..color = color.withValues(alpha: 0.95),
      );
      // Trailing line back to start (cinematic light trail)
      final trail = Paint()
        ..shader = LinearGradient(
          colors: [color.withValues(alpha: 0.0), color.withValues(alpha: 0.55)],
        ).createShader(Rect.fromPoints(start, pos))
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, pos, trail);
    }
  }

  @override
  bool shouldRepaint(covariant _WeltOrbsConverge old) => old.progress != progress;
}

class _BurstFlash extends StatelessWidget {
  final double progress;
  const _BurstFlash({required this.progress});

  @override
  Widget build(BuildContext context) {
    final scale = 0.4 + progress * 3.0;
    final opacity = progress < 0.5
        ? (progress * 2)
        : (1.0 - (progress - 0.5) * 2);
    return IgnorePointer(
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _gold.withValues(alpha: 0.95),
                  _gold.withValues(alpha: 0.55),
                  _gold.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
              boxShadow: [
                BoxShadow(color: _gold.withValues(alpha: 0.6), blurRadius: 80, spreadRadius: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoReveal extends StatelessWidget {
  final double progress; // 0..1
  final double maxWidth;
  const _LogoReveal({required this.progress, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    final scale = 0.7 + Curves.easeOutBack.transform(progress.clamp(0.0, 1.0)) * 0.45;
    final fade = (progress * 1.8).clamp(0.0, 1.0);
    // Responsive logo size: max 220 auf grossen Bildschirmen, sonst 55% Breite.
    final logoSize = math.min(220.0, maxWidth * 0.55);
    return Opacity(
      opacity: fade,
      child: Transform.scale(
        scale: scale,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo image with cinematic glow
            Container(
              width: logoSize,
              height: logoSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.45 * fade),
                    blurRadius: 60,
                    spreadRadius: 10,
                  ),
                  BoxShadow(
                    color: _energieColor.withValues(alpha: 0.30 * fade),
                    blurRadius: 90,
                    spreadRadius: 15,
                  ),
                ],
              ),
              child: ClipOval(
                child: Stack(fit: StackFit.expand, children: [
                  Image.asset(
                    'assets/images/intro_weltenbibliothek_new.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/intro_weltenbibliothek.webp',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: _bgVoid,
                        alignment: Alignment.center,
                        child: Text(
                          'W',
                          style: TextStyle(
                            fontSize: 120,
                            fontWeight: FontWeight.w900,
                            color: _gold.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Subtle vignette inside the circle
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Colors.transparent, Color(0x55000000)],
                        stops: [0.6, 1.0],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            // Title with shader gradient -- skaliert sich auf schmalen Screens
            FittedBox(
              fit: BoxFit.scaleDown,
              child: ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  colors: [_gold, _energieColor, _ursprungColor],
                ).createShader(rect),
                child: Text(
                  'WELTENBIBLIOTHEK',
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8.0 * fade,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  final double progress;
  const _Subtitle({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset(0, 20 * (1 - progress)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              'Wo die Wahrheit aus 4 Perspektiven ans Licht kommt',
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.fade,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12,
                letterSpacing: 3,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            // 4 mini dots in welt colors
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                _MiniDot(color: _materieColor),
                SizedBox(width: 12),
                _MiniDot(color: _energieColor),
                SizedBox(width: 12),
                _MiniDot(color: _vorhangColor),
                SizedBox(width: 12),
                _MiniDot(color: _ursprungColor),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}

class _MiniDot extends StatelessWidget {
  final Color color;
  const _MiniDot({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8)],
      ),
    );
  }
}

