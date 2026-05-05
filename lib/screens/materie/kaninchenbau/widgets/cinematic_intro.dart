/// 🐇 RABBIT-HOLE-PORTAL — Cinematic Entry zum Kaninchenbau.
///
/// Mehrschichtige Tiefenanimation:
///   1. Deep Starfield (langsam rotierende Hintergrund-Sterne)
///   2. Nebula Clouds (3 farbige Glow-Orbe, parallaktisch)
///   3. Tunnel-Spirale (perspektivische Ringe ziehen sich zur Mitte)
///   4. Foreground Sparks (gold/rote Funken die nach außen fliegen)
///   5. Glow-Suchring (pulsierender Portalrand)
///   6. Virgil-Typewriter ("Was möchtest du erforschen?")
///   7. Vorgeschlagene Themen (Hot Topics als Chips)
///
/// Beim Submit: Suchring kollabiert, Portal-Tunnel schießt nach vorne, dann fade.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/my_investigations_screen.dart';
import 'kb_design.dart';

class CinematicIntro extends StatefulWidget {
  final void Function(String topic) onSubmit;
  const CinematicIntro({super.key, required this.onSubmit});

  @override
  State<CinematicIntro> createState() => _CinematicIntroState();
}

class _CinematicIntroState extends State<CinematicIntro>
    with TickerProviderStateMixin {
  late final AnimationController _intro; // 0→1 Aufbau-Animation
  late final AnimationController _ambient; // Endlos-Loop für Sterne/Nebel
  late final AnimationController _portal; // Pulsierender Suchring
  late final AnimationController _collapse; // Submit → Portal-Kollaps

  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _ready = false;
  bool _typewriterDone = false;
  String _typed = '';
  static const String _virgilLine = 'Was möchtest du erforschen?';

  // Vorgeschlagene Themen (rotieren)
  static const List<String> _suggestions = [
    'WEF',
    'Pfizer',
    'BlackRock',
    'MK Ultra',
    'Bilderberg',
    'Klaus Schwab',
    'Bohemian Grove',
    'Operation Mockingbird',
    'Epstein-Insel',
    'JFK Akten',
    'Tartaria',
    'CERN',
  ];

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
    _portal = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _collapse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _intro.forward().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      _runTypewriter();
    });
  }

  Future<void> _runTypewriter() async {
    for (var i = 1; i <= _virgilLine.length; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 38));
      setState(() => _typed = _virgilLine.substring(0, i));
    }
    if (!mounted) return;
    setState(() => _typewriterDone = true);
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    _portal.dispose();
    _collapse.dispose();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _skip() {
    if (_intro.isAnimating) {
      _intro.value = 1.0;
    }
    if (!_typewriterDone) {
      setState(() {
        _typed = _virgilLine;
        _typewriterDone = true;
      });
      _focus.requestFocus();
    }
  }

  Future<void> _submit([String? override]) async {
    final v = (override ?? _ctrl.text).trim();
    if (v.isEmpty) return;
    HapticFeedback.heavyImpact();
    _focus.unfocus();
    await _collapse.forward();
    if (!mounted) return;
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
          animation: Listenable.merge([_intro, _ambient, _portal, _collapse]),
          builder: (_, __) {
            final p = _intro.value;
            final ambient = _ambient.value;
            final portal = _portal.value;
            final collapse = _collapse.value;

            // Beim Kollaps: Skala explodiert, Opacity fällt
            final masterScale = 1.0 + collapse * 6.0;
            final masterOpacity = 1.0 - collapse;

            return Opacity(
              opacity: masterOpacity.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: masterScale,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. Deep Starfield (immer da)
                    CustomPaint(
                      painter: _DeepStarfieldPainter(
                        progress: p,
                        rotation: ambient * 2 * math.pi,
                      ),
                    ),
                    // 2. Nebula Clouds
                    CustomPaint(
                      painter: _NebulaPainter(
                        progress: p,
                        time: ambient,
                      ),
                    ),
                    // 3. Tunnel-Spirale
                    CustomPaint(
                      painter: _TunnelPainter(
                        progress: p,
                        time: ambient,
                        collapse: collapse,
                      ),
                    ),
                    // 4. Foreground Sparks
                    if (p > 0.4)
                      CustomPaint(
                        painter: _SparksPainter(
                          progress: p,
                          time: ambient,
                        ),
                      ),
                    // 5. Portal-Center: Glow-Ring oder Suchfeld
                    Center(
                      child: _ready
                          ? _buildPrompt(portal)
                          : _buildPortalRing(p),
                    ),
                    // Close-Button
                    if (_ready && collapse < 0.05)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 8,
                        child: IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white60, size: 26),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                    // "Meine Ermittlungen"-Button oben rechts
                    if (_ready && collapse < 0.05)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 12,
                        right: 12,
                        child: TextButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) =>
                                  const MyInvestigationsScreen(),
                            ));
                          },
                          icon: Icon(Icons.bookmark_rounded,
                              size: 16, color: KbDesign.goldAccent),
                          label: Text(
                            'Ermittlungen',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Vor-Bereitschafts-Animation: leuchtender Punkt → Portal-Ring
  Widget _buildPortalRing(double p) {
    final size = 30 + p * 240;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            KbDesign.neonRedSoft.withValues(alpha: 0.0),
            KbDesign.neonRed.withValues(alpha: 0.0),
            KbDesign.neonRed.withValues(alpha: 0.85 * p),
          ],
          stops: const [0.0, 0.78, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: KbDesign.neonRed.withValues(alpha: 0.5 * p),
            blurRadius: 30 + p * 80,
            spreadRadius: 4,
          ),
        ],
      ),
    );
  }

  /// Bereitschafts-Prompt: Virgil-Text + Glas-Suchring + Suggestion-Chips
  Widget _buildPrompt(double portalT) {
    final pulse = 0.85 + 0.15 * portalT;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 24 + MediaQuery.of(context).padding.top,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Virgil-Logo / Rabbit-Hole-Marker
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  KbDesign.neonRedSoft.withValues(alpha: 0.95 * pulse),
                  KbDesign.neonRed.withValues(alpha: 0.7 * pulse),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: KbDesign.neonRed.withValues(alpha: 0.5 * pulse),
                  blurRadius: 40 + 20 * pulse,
                  spreadRadius: 4,
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4 * pulse),
                width: 1.2,
              ),
            ),
            child: const Center(
              child: Text('🐇', style: TextStyle(fontSize: 44)),
            ),
          ),
          const SizedBox(height: 26),
          // Virgil-Label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome_rounded,
                  size: 14, color: KbDesign.goldAccent),
              const SizedBox(width: 6),
              Text(
                'VIRGIL',
                style: TextStyle(
                  color: KbDesign.goldAccent.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Typewriter
          SizedBox(
            height: 60,
            child: Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.96),
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0.4,
                    height: 1.3,
                  ),
                  children: [
                    TextSpan(text: _typed),
                    if (!_typewriterDone)
                      TextSpan(
                        text: '▍',
                        style: TextStyle(
                          color: KbDesign.neonRedSoft.withValues(
                              alpha: portalT > 0.5 ? 1.0 : 0.2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Suchring (Glas + Glow)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: _typewriterDone ? 1.0 : 0.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF14141F),
                    Color(0xFF0A0A12),
                  ],
                ),
                border: Border.all(
                  color: KbDesign.neonRed.withValues(alpha: pulse * 0.65),
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        KbDesign.neonRed.withValues(alpha: 0.28 * pulse),
                    blurRadius: 30 + 14 * pulse,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _submit(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  letterSpacing: 0.3,
                ),
                cursorColor: KbDesign.neonRedSoft,
                decoration: InputDecoration(
                  hintText: 'Personen, Firmen, Ereignisse, Theorien…',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.32),
                    fontSize: 15,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 8),
                    child: Icon(Icons.travel_explore_rounded,
                        color: KbDesign.neonRedSoft.withValues(alpha: 0.85)),
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, size: 24),
                    color: KbDesign.neonRedSoft,
                    onPressed: () => _submit(),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          // Hot-Topic Chips
          AnimatedOpacity(
            duration: const Duration(milliseconds: 600),
            opacity: _typewriterDone ? 1.0 : 0.0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_fire_department_rounded,
                        size: 14,
                        color: KbDesign.goldAccent.withValues(alpha: 0.7)),
                    const SizedBox(width: 6),
                    Text(
                      'HEISSE PFADE',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestions
                      .map((s) => _SuggestionChip(
                            label: s,
                            onTap: () => _submit(s),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Tap zum Überspringen · Enter zum Eintauchen',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.28),
              fontSize: 11,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  State<_SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<_SuggestionChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: _hover
                ? KbDesign.neonRed.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: _hover
                  ? KbDesign.neonRed.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: KbDesign.neonRed.withValues(alpha: 0.25),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: _hover ? Colors.white : Colors.white70,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PAINTERS
// ═══════════════════════════════════════════════════════════════

class _DeepStarfieldPainter extends CustomPainter {
  final double progress;
  final double rotation;
  _DeepStarfieldPainter({required this.progress, required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation * 0.06);
    canvas.translate(-center.dx, -center.dy);

    final rng = math.Random(42);
    final paint = Paint();
    for (var i = 0; i < 280; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 1.6 + 0.3;
      final twinkle = 0.5 + 0.5 * math.sin(rotation * 4 + i * 1.7);
      final alpha = (rng.nextDouble() * 0.65 + 0.15) * progress * twinkle;
      paint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DeepStarfieldPainter old) =>
      old.progress != progress || old.rotation != rotation;
}

class _NebulaPainter extends CustomPainter {
  final double progress;
  final double time;
  _NebulaPainter({required this.progress, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final orbs = [
      _NebulaOrb(
        color: KbDesign.neonRed,
        baseX: 0.18,
        baseY: 0.22,
        radius: size.shortestSide * 0.55,
        speed: 1.0,
      ),
      _NebulaOrb(
        color: const Color(0xFF7C4DFF),
        baseX: 0.82,
        baseY: 0.30,
        radius: size.shortestSide * 0.45,
        speed: -0.7,
      ),
      _NebulaOrb(
        color: KbDesign.goldAccent,
        baseX: 0.5,
        baseY: 0.85,
        radius: size.shortestSide * 0.5,
        speed: 0.5,
      ),
    ];

    for (final orb in orbs) {
      final angle = time * 2 * math.pi * orb.speed;
      final dx = orb.baseX * size.width + math.cos(angle) * 30;
      final dy = orb.baseY * size.height + math.sin(angle) * 20;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            orb.color.withValues(alpha: 0.18 * progress),
            orb.color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(
          Rect.fromCircle(center: Offset(dx, dy), radius: orb.radius),
        );
      canvas.drawCircle(Offset(dx, dy), orb.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NebulaPainter old) =>
      old.progress != progress || old.time != time;
}

class _NebulaOrb {
  final Color color;
  final double baseX;
  final double baseY;
  final double radius;
  final double speed;
  _NebulaOrb({
    required this.color,
    required this.baseX,
    required this.baseY,
    required this.radius,
    required this.speed,
  });
}

class _TunnelPainter extends CustomPainter {
  final double progress;
  final double time;
  final double collapse;
  _TunnelPainter({
    required this.progress,
    required this.time,
    required this.collapse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.shortestSide * 0.95;

    // Perspektivische Ringe ziehen sich zur Mitte
    for (var i = 0; i < 14; i++) {
      // i=0 = innerster Ring, i=13 = äußerster
      final base = i / 14.0;
      // Ringe bewegen sich kontinuierlich nach innen (vorwärts-Tiefenfahrt)
      final t = (base - time) % 1.0;
      final radius = maxR * (0.05 + t * 1.0);
      // Beim Kollaps: alle Ringe nach außen schießen
      final collapsedR = radius + collapse * maxR * 1.4;
      final fade = (1.0 - t) * progress * (1.0 - collapse * 0.7);
      if (fade <= 0) continue;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 + (1.0 - t) * 1.5
        ..color = KbDesign.neonRed.withValues(alpha: 0.18 * fade);
      canvas.drawCircle(center, collapsedR, paint);

      // Innerer Glow-Ring (heller)
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = KbDesign.neonRedSoft.withValues(alpha: 0.35 * fade * (1 - t));
      canvas.drawCircle(center, collapsedR, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TunnelPainter old) =>
      old.progress != progress ||
      old.time != time ||
      old.collapse != collapse;
}

class _SparksPainter extends CustomPainter {
  final double progress;
  final double time;
  _SparksPainter({required this.progress, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rng = math.Random(123);
    final paint = Paint();

    for (var i = 0; i < 40; i++) {
      final angle = rng.nextDouble() * 2 * math.pi;
      final speed = 0.4 + rng.nextDouble() * 0.6;
      // Funken fliegen vom Zentrum nach außen
      final t = (time * speed + rng.nextDouble()) % 1.0;
      final dist = t * size.shortestSide * 0.6;
      final dx = center.dx + math.cos(angle) * dist;
      final dy = center.dy + math.sin(angle) * dist;
      final fade = (1.0 - t) * progress;
      final color =
          rng.nextBool() ? KbDesign.neonRedSoft : KbDesign.goldAccent;
      paint.color = color.withValues(alpha: fade * 0.8);
      canvas.drawCircle(Offset(dx, dy), 1.4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparksPainter old) =>
      old.progress != progress || old.time != time;
}
