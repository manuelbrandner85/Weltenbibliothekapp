import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// 🎬 Professioneller Übergang zwischen allen 4 Welten
///
/// Materie ↔ Energie: Echte MP4-Video-Übergänge (bestehendes Asset)
/// Alle anderen Kombinationen (Vorhang, Ursprung, Cross-World):
///   Cinematic programmatische Animation mit Welt-Farben, Vortex-Effekt,
///   Partikel-Explosion und Fade — gleiche Qualität wie die Videos.
///
/// Welt-Farben:
///   - MATERIE:  Blau #3B82F6 auf Deep Dark #040D1F
///   - ENERGIE:  Lila #A855F7 auf Deep Dark #0C0318
///   - VORHANG:  Gold #C9A84C auf Schwarz #000000
///   - URSPRUNG: Cyan #00D4AA auf Deep Dark #050510
class WorldTransitionVideo extends StatefulWidget {
  final Widget targetScreen;

  /// Ziel-Welt: 'materie', 'energie', 'vorhang', 'ursprung'
  final String targetWorld;

  // ── Legacy-API (Rückwärtskompatibilität für alten 2-Welten-Code) ──
  /// @deprecated — Benutze [targetWorld] stattdessen.
  final bool? isMaterieToEnergie;

  const WorldTransitionVideo({
    super.key,
    required this.targetScreen,
    this.targetWorld = '',
    this.isMaterieToEnergie,
  });

  @override
  State<WorldTransitionVideo> createState() => _WorldTransitionVideoState();
}

class _WorldTransitionVideoState extends State<WorldTransitionVideo>
    with TickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isVideoInitialized = false;
  bool _hasNavigated = false;
  bool _hasError = false;
  Timer? _errorRescueTimer;

  // Programmatische Animation (für Welten ohne Video-Asset)
  late AnimationController _animController;
  late Animation<double> _progress;
  bool _useProceduralAnimation = false;

  /// Bestimme die effektive Ziel-Welt aus neuer oder alter API.
  String get _effectiveTargetWorld {
    if (widget.targetWorld.isNotEmpty) return widget.targetWorld;
    // Legacy-Fallback
    if (widget.isMaterieToEnergie == true) return 'energie';
    return 'materie';
  }

  /// Video-Asset-Pfad ODER null wenn programmatische Animation nötig.
  String? get _videoAssetPath {
    final target = _effectiveTargetWorld;
    // Nur Materie ↔ Energie haben echte Video-Assets
    if (target == 'energie') {
      return 'assets/videos/transition_materie_to_energie.mp4';
    }
    if (target == 'materie') {
      return 'assets/videos/transition_energie_to_materie.mp4';
    }
    return null; // Vorhang, Ursprung → programmatisch
  }

  /// Welt-Farb-Palette für die Ziel-Welt.
  _WorldColors get _targetColors {
    switch (_effectiveTargetWorld) {
      case 'materie':
        return const _WorldColors(
          primary: Color(0xFF3B82F6),
          secondary: Color(0xFF7DA7FF),
          deep: Color(0xFF040D1F),
          glow: Color(0xFF0D47A1),
        );
      case 'energie':
        return const _WorldColors(
          primary: Color(0xFFA855F7),
          secondary: Color(0xFFC79AFF),
          deep: Color(0xFF0C0318),
          glow: Color(0xFF4A148C),
        );
      case 'vorhang':
        return const _WorldColors(
          primary: Color(0xFFC9A84C),
          secondary: Color(0xFFE0C872),
          deep: Color(0xFF0D0B00),
          glow: Color(0xFF8B7532),
        );
      case 'ursprung':
        return const _WorldColors(
          primary: Color(0xFF00D4AA),
          secondary: Color(0xFF40E8C0),
          deep: Color(0xFF050510),
          glow: Color(0xFF008866),
        );
      default:
        return const _WorldColors(
          primary: Color(0xFF3B82F6),
          secondary: Color(0xFF7DA7FF),
          deep: Color(0xFF040D1F),
          glow: Color(0xFF0D47A1),
        );
    }
  }

  @override
  void initState() {
    super.initState();

    // Programmatische Animation (2.5s Dauer — fühlt sich genauso an wie die Videos)
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _progress = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    );

    final videoPath = _videoAssetPath;
    if (videoPath != null) {
      _initializeAndPlayVideo(videoPath);
    } else {
      _useProceduralAnimation = true;
      _startProceduralAnimation();
    }

    // 🛡️ SAFETY NET: Falls weder Video noch Animation abschließt,
    // navigieren wir nach 6s trotzdem weiter.
    _errorRescueTimer = Timer(const Duration(seconds: 6), () {
      if (!mounted || _hasNavigated) return;
      if (kDebugMode) {
        debugPrint('⏱️ Transition Rescue-Timeout → navigiere zum Target');
      }
      _navigateToTarget();
    });
  }

  // ── Video-basierter Übergang (Materie ↔ Energie) ──

  Future<void> _initializeAndPlayVideo(String videoPath) async {
    try {
      final controller = VideoPlayerController.asset(videoPath);
      _controller = controller;

      await controller.initialize().timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          throw TimeoutException('video initialize() > 4s');
        },
      );

      if (!mounted) return;

      setState(() => _isVideoInitialized = true);
      await controller.play();
      controller.addListener(_checkVideoProgress);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Transition-Video Fehler: $e — Fallback auf Animation');
      }
      if (!mounted) return;
      // Fallback: programmatische Animation
      setState(() {
        _hasError = true;
        _useProceduralAnimation = true;
      });
      _startProceduralAnimation();
    }
  }

  void _checkVideoProgress() {
    final c = _controller;
    if (c == null) return;
    if (c.value.isInitialized && c.value.position >= c.value.duration) {
      _navigateToTarget();
    }
  }

  // ── Programmatische Animation (Vorhang, Ursprung, Fallback) ──

  void _startProceduralAnimation() {
    _animController.forward();
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToTarget();
      }
    });
  }

  // ── Navigation ──

  void _navigateToTarget() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            widget.targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  void dispose() {
    _errorRescueTimer?.cancel();
    _animController.dispose();
    final c = _controller;
    if (c != null) {
      c.removeListener(_checkVideoProgress);
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _targetColors;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Haupt-Transition ──
          if (_useProceduralAnimation)
            _ProceduralTransition(
              animation: _progress,
              colors: colors,
              worldName: _effectiveTargetWorld,
            )
          else if (_isVideoInitialized && _controller != null)
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            )
          else
            Container(color: colors.glow),

          // ⏭️ SKIP-BUTTON
          Positioned(
            top: 50,
            right: 20,
            child: SafeArea(
              child: ElevatedButton.icon(
                onPressed: _navigateToTarget,
                icon: const Icon(Icons.skip_next, size: 20),
                label: Text(_hasError ? 'Fortfahren' : 'Überspringen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  foregroundColor: Colors.black87,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROGRAMMATISCHE CINEMATIC TRANSITION
// ═══════════════════════════════════════════════════════════════════════════

/// Cinematic Portal-Animation die ein Video ersetzt:
///
/// Phase 1 (0.0–0.3): Schwarzer Screen → Vortex-Glow entsteht in der Mitte
/// Phase 2 (0.3–0.6): Vortex expandiert, Partikel-Ringe rotieren, Welt-Name blendet ein
/// Phase 3 (0.6–0.9): Flash-Explosion in der Welt-Farbe, Screen wird hell
/// Phase 4 (0.9–1.0): Fade-out zu schwarz → Target-Screen kommt per PageRoute-Fade
class _ProceduralTransition extends StatelessWidget {
  final Animation<double> animation;
  final _WorldColors colors;
  final String worldName;

  const _ProceduralTransition({
    required this.animation,
    required this.colors,
    required this.worldName,
  });

  String get _worldDisplayName {
    switch (worldName) {
      case 'materie':
        return 'MATERIE';
      case 'energie':
        return 'ENERGIE';
      case 'vorhang':
        return 'VORHANG';
      case 'ursprung':
        return 'URSPRUNG';
      default:
        return worldName.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius =
        math.sqrt(size.width * size.width + size.height * size.height) / 2;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value;

        // Phase-Berechnungen
        final vortexGrow = (t / 0.6).clamp(0.0, 1.0); // 0→1 über Phase 1+2
        final flashIntensity = t < 0.6
            ? 0.0
            : t < 0.85
                ? ((t - 0.6) / 0.25).clamp(0.0, 1.0) // Aufblenden
                : 1.0 - ((t - 0.85) / 0.15).clamp(0.0, 1.0); // Abblenden
        final nameOpacity = t < 0.25
            ? 0.0
            : t < 0.7
                ? ((t - 0.25) / 0.15).clamp(0.0, 1.0)
                : 1.0 - ((t - 0.7) / 0.15).clamp(0.0, 1.0);
        final fadeToBlack =
            t < 0.85 ? 0.0 : ((t - 0.85) / 0.15).clamp(0.0, 1.0);

        return Stack(
          children: [
            // Hintergrund: Deep-Color der Ziel-Welt
            Container(color: colors.deep),

            // Vortex-Glow (radial expandierend)
            if (vortexGrow > 0)
              Positioned.fill(
                child: CustomPaint(
                  painter: _VortexPainter(
                    center: center,
                    progress: vortexGrow,
                    maxRadius: maxRadius,
                    primaryColor: colors.primary,
                    secondaryColor: colors.secondary,
                  ),
                ),
              ),

            // Rotierende Partikel-Ringe
            if (t > 0.1 && t < 0.9)
              Positioned.fill(
                child: CustomPaint(
                  painter: _ParticleRingPainter(
                    center: center,
                    progress: t,
                    color: colors.primary,
                    secondaryColor: colors.secondary,
                  ),
                ),
              ),

            // Flash-Explosion
            if (flashIntensity > 0)
              Container(
                color: colors.primary.withValues(alpha: flashIntensity * 0.7),
              ),

            // Welt-Name
            if (nameOpacity > 0)
              Center(
                child: Opacity(
                  opacity: nameOpacity.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.8 + vortexGrow * 0.4,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Welt-Icon-Ring
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.primary.withValues(alpha: 0.6),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colors.primary.withValues(alpha: 0.4),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            _worldIcon,
                            color: colors.primary,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _worldDisplayName,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w200,
                            letterSpacing: 12,
                            color: Colors.white.withValues(alpha: 0.95),
                            shadows: [
                              Shadow(
                                color: colors.primary.withValues(alpha: 0.8),
                                blurRadius: 30,
                              ),
                              Shadow(
                                color: colors.glow.withValues(alpha: 0.5),
                                blurRadius: 60,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Fade to black (Ende)
            if (fadeToBlack > 0)
              Container(
                color: Colors.black.withValues(alpha: fadeToBlack),
              ),
          ],
        );
      },
    );
  }

  IconData get _worldIcon {
    switch (worldName) {
      case 'materie':
        return Icons.public;
      case 'energie':
        return Icons.auto_awesome;
      case 'vorhang':
        return Icons.psychology;
      case 'ursprung':
        return Icons.all_inclusive;
      default:
        return Icons.explore;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════════════════════════

/// Expandierender Vortex-Glow — wie ein Portal das sich öffnet.
class _VortexPainter extends CustomPainter {
  final Offset center;
  final double progress;
  final double maxRadius;
  final Color primaryColor;
  final Color secondaryColor;

  _VortexPainter({
    required this.center,
    required this.progress,
    required this.maxRadius,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Äußerer Glow-Ring
    final outerRadius = maxRadius * progress * 0.8;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: 0.0),
          primaryColor.withValues(alpha: 0.15 * progress),
          secondaryColor.withValues(alpha: 0.25 * progress),
          primaryColor.withValues(alpha: 0.4 * progress),
          Colors.white.withValues(alpha: 0.6 * progress),
        ],
        stops: const [0.0, 0.35, 0.55, 0.8, 1.0],
      ).createShader(Rect.fromCircle(
          center: center, radius: outerRadius.clamp(1.0, double.infinity)));

    canvas.drawCircle(center, outerRadius, paint);

    // Innerer heller Kern
    final coreRadius = 30 + 50 * progress;
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.9 * progress),
          primaryColor.withValues(alpha: 0.5 * progress),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: coreRadius));

    canvas.drawCircle(center, coreRadius, corePaint);

    // Rotierender Spiral-Ring
    final spiralPaint = Paint()
      ..color = secondaryColor.withValues(alpha: 0.3 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (var i = 0; i < 3; i++) {
      final angle = progress * math.pi * 4 + i * (math.pi * 2 / 3);
      final r = coreRadius + 20 + i * 15;
      final path = Path();
      for (var a = 0.0; a < math.pi * 1.5; a += 0.1) {
        final x = center.dx + math.cos(angle + a) * (r + a * 8);
        final y = center.dy + math.sin(angle + a) * (r + a * 8);
        if (a == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, spiralPaint);
    }
  }

  @override
  bool shouldRepaint(_VortexPainter old) => old.progress != progress;
}

/// Rotierende Partikel-Ringe — Lichtpunkte die um das Portal kreisen.
class _ParticleRingPainter extends CustomPainter {
  final Offset center;
  final double progress;
  final Color color;
  final Color secondaryColor;

  _ParticleRingPainter({
    required this.center,
    required this.progress,
    required this.color,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42); // Deterministisch für konsistente Partikel
    final particleCount = 60;
    final ringProgress = ((progress - 0.1) / 0.7).clamp(0.0, 1.0);
    final fade =
        progress > 0.8 ? 1.0 - ((progress - 0.8) / 0.1).clamp(0.0, 1.0) : 1.0;

    for (var i = 0; i < particleCount; i++) {
      final baseAngle = rng.nextDouble() * math.pi * 2;
      final baseRadius = 60 + rng.nextDouble() * 200;
      final speed = 0.5 + rng.nextDouble() * 2.0;
      final particleSize = 1.5 + rng.nextDouble() * 3.0;

      final angle = baseAngle + progress * speed * math.pi * 2;
      final radius = baseRadius * ringProgress;

      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;

      final isSecondary = i % 3 == 0;
      final c = isSecondary ? secondaryColor : color;
      final alpha = (0.3 + rng.nextDouble() * 0.7) * fade;

      final paint = Paint()..color = c.withValues(alpha: alpha.clamp(0.0, 1.0));

      canvas.drawCircle(Offset(x, y), particleSize, paint);

      // Glow um jeden Partikel
      final glowPaint = Paint()
        ..color = c.withValues(alpha: (alpha * 0.3).clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(x, y), particleSize * 2.5, glowPaint);
    }
  }

  @override
  bool shouldRepaint(_ParticleRingPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPER
// ═══════════════════════════════════════════════════════════════════════════

class _WorldColors {
  final Color primary;
  final Color secondary;
  final Color deep;
  final Color glow;

  const _WorldColors({
    required this.primary,
    required this.secondary,
    required this.deep,
    required this.glow,
  });
}
