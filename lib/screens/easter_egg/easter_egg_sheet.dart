// 🌀 EASTER-EGG-SHEET - Cinematic Full-Screen statt klassischer Dialog
//
// Wird vom Portal nach 10 Taps oder Long-Press geoeffnet. Zeigt 12 Optionen
// in cinematic Glassmorphism-Karten mit Radial-Nebula + 3 CineOrbs +
// 60 Ambient-Particles + Vignette.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_ambient_particles.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/cinematic/wb_vignette.dart';
import 'cosmic_reset_ritual_screen.dart';
import 'geheime_karte_screen.dart';
import 'glitch_matrix_detektor_screen.dart';
import 'hidden_facts_screen.dart';
import 'lichtsprache_decoder_screen.dart';
import 'numerologie_realtime_screen.dart';
import 'portal_defense_game_screen.dart';
import 'realitaets_hopper_screen.dart';
import 'synchronizitaeten_logger_screen.dart';
import 'time_capsule_screen.dart';

class EasterEggSheet extends StatefulWidget {
  // Callbacks zu bestehenden Funktionen im PortalHomeScreen.
  // (Cheat Codes + Dev-Stats wurden v5.43.1 entfernt - UX-Cleanup.)
  final VoidCallback onColorPicker;
  final VoidCallback onHiddenFacts;
  final VoidCallback onAchievements;
  final VoidCallback onSharePortalStats;
  final VoidCallback onAbout;

  const EasterEggSheet({
    super.key,
    required this.onColorPicker,
    required this.onHiddenFacts,
    required this.onAchievements,
    required this.onSharePortalStats,
    required this.onAbout,
  });

  @override
  State<EasterEggSheet> createState() => _EasterEggSheetState();
}

class _EasterEggSheetState extends State<EasterEggSheet>
    with TickerProviderStateMixin {
  static const Color _bg = Color(0xFF03020A);
  static const Color _primary = Color(0xFF7C4DFF);
  static const Color _accent = Color(0xFF00BCD4);
  static const Color _gold = Color(0xFFFFD700);

  late final AnimationController _ambientCtrl;
  late final AnimationController _enterCtrl;

  @override
  void initState() {
    super.initState();
    _ambientCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 14),
    )..repeat();
    _enterCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _ambientCtrl.dispose();
    _enterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items();
    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        world: WBWorld.neutral,
        titleWidget: ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [_gold, _primary, _accent],
          ).createShader(r),
          child: const Text(
            'PORTAL-GEHEIMNIS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
        ),
      ),
      body: Stack(fit: StackFit.expand, children: [
        // Layer 1: Tunnel-Zoom-Radial
        AnimatedBuilder(
          animation: _enterCtrl,
          builder: (_, __) => Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5 - _enterCtrl.value * 0.5,
                colors: [
                  _primary.withValues(alpha: 0.35 * _enterCtrl.value),
                  _accent.withValues(alpha: 0.18 * _enterCtrl.value),
                  _bg,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        // Layer 2: 3 CineOrbs
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _ambientCtrl,
            builder: (_, __) => CustomPaint(
              painter: _EgOrbsPainter(_ambientCtrl.value),
              size: Size.infinite,
            ),
          ),
        ),
        // Layer 3: Ambient Particles
        const IgnorePointer(
          child: WBAmbientParticles(world: WBWorld.neutral, count: 60),
        ),

        // Layer 4: Content (Tunnel-Zoom-In)
        SafeArea(
          child: FadeTransition(
            opacity: _enterCtrl,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Text('🌀',
                          style: TextStyle(
                              fontSize: 64,
                              shadows: [
                                Shadow(color: _gold.withValues(alpha: 0.6), blurRadius: 22),
                              ])),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Du hast das versteckte Portal-Menü entdeckt',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 22),
                    // Grid 2-spalts mit Glass-Karten
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.15,
                      ),
                      itemCount: items.length,
                      itemBuilder: (_, i) => _EgTile(item: items[i]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Layer 5: Vignette
        const IgnorePointer(child: WBVignette()),
      ]),
    );
  }

  List<_EgItem> _items() => [
        // ─── Spirit & Selbstreflexion ───
        _EgItem(
          emoji: '🌟',
          title: 'Symbol des Tages',
          subtitle: '1 Tap · 1 Symbol\nfür heute',
          color: const Color(0xFFFFD54F),
          onTap: () => _navigate(const LichtspracheDecoderScreen()),
        ),
        _EgItem(
          emoji: '✨',
          title: 'Magische Zufälle',
          subtitle: 'Sammle bedeutsame\nZufalls-Momente',
          color: const Color(0xFFEC407A),
          onTap: () => _navigate(const SynchronizitaetenLoggerScreen()),
        ),
        _EgItem(
          emoji: '🌀',
          title: 'Déjà-vu Sammlung',
          subtitle: 'Aha-Momente\nfesthalten',
          color: const Color(0xFFFF7043),
          onTap: () => _navigate(const GlitchMatrixDetektorScreen()),
        ),
        _EgItem(
          emoji: '⏳',
          title: 'Time-Capsule',
          subtitle: 'Brief an dich\nin 1-12 Monaten',
          color: const Color(0xFF42A5F5),
          onTap: () => _navigate(const TimeCapsuleScreen()),
        ),

        // ─── Entdecken & Quizzen ───
        _EgItem(
          emoji: '🪞',
          title: 'Welt-Quiz',
          subtitle: 'Welche Welt\ngehört zu dir?',
          color: const Color(0xFF7C4DFF),
          onTap: () => _navigate(const RealitaetsHopperScreen()),
        ),
        _EgItem(
          emoji: '🗺️',
          title: 'Mystische Orte',
          subtitle: '24 echte\nGeheimnisse der Welt',
          color: const Color(0xFF66BB6A),
          onTap: () => _navigate(const GeheimeKarteScreen()),
        ),
        _EgItem(
          emoji: '🔢',
          title: 'Heute in Zahlen',
          subtitle: 'Tag · Stunde · Minute\nin Numerologie',
          color: const Color(0xFFAB47BC),
          onTap: () => _navigate(const NumerologieRealtimeScreen()),
        ),
        _EgItem(
          emoji: '💡',
          title: 'Wussten Sie schon?',
          subtitle: 'Faszinierende\nFakten-Karten',
          color: const Color(0xFFFFA726),
          onTap: () => _navigate(const HiddenFactsScreen()),
        ),

        // ─── Fun & Spiel ───
        _EgItem(
          emoji: '🎮',
          title: 'Portal Defense',
          subtitle: 'Mini-Game · Wellen\nPower-Ups · Score',
          color: const Color(0xFF26A69A),
          onTap: () => _navigate(const PortalDefenseGameScreen()),
        ),
        _EgItem(
          emoji: '🏆',
          title: 'Achievements',
          subtitle: 'Deine Erfolge\nund Trophäen',
          color: const Color(0xFFFFC107),
          onTap: () { Navigator.pop(context); widget.onAchievements(); },
        ),

        // ─── App & Meta ───
        _EgItem(
          emoji: '♾️',
          title: 'Cosmic Reset',
          subtitle: 'Ritueller\nApp-Reset',
          color: const Color(0xFFE53935),
          onTap: () => _navigate(const CosmicResetRitualScreen()),
        ),
        _EgItem(
          emoji: '🎨',
          title: 'Portal-Farben',
          subtitle: 'Farbschema\nwechseln',
          color: const Color(0xFF26C6DA),
          onTap: () { Navigator.pop(context); widget.onColorPicker(); },
        ),
        _EgItem(
          emoji: '📤',
          title: 'Stats teilen',
          subtitle: 'Auf Social Media\nteilen',
          color: const Color(0xFF5C6BC0),
          onTap: () { Navigator.pop(context); widget.onSharePortalStats(); },
        ),
        _EgItem(
          emoji: '✨',
          title: 'Über',
          subtitle: 'Weltenbibliothek\nInfo & Credits',
          color: const Color(0xFF9C27B0),
          onTap: () { Navigator.pop(context); widget.onAbout(); },
        ),
      ];

  void _navigate(Widget screen) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

class _EgItem {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _EgItem({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class _EgTile extends StatefulWidget {
  final _EgItem item;
  const _EgTile({required this.item});

  @override
  State<_EgTile> createState() => _EgTileState();
}

class _EgTileState extends State<_EgTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.item.color;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.item.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    c.withValues(alpha: 0.28),
                    c.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.withValues(alpha: 0.45)),
                boxShadow: _pressed
                    ? [BoxShadow(color: c.withValues(alpha: 0.55), blurRadius: 18, spreadRadius: 1)]
                    : [BoxShadow(color: c.withValues(alpha: 0.18), blurRadius: 10)],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.item.emoji,
                        style: const TextStyle(fontSize: 32)),
                    const Spacer(),
                    Text(
                      widget.item.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.item.subtitle,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 10,
                          height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EgOrbsPainter extends CustomPainter {
  final double t;
  _EgOrbsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    _draw(canvas,
        Offset(size.width * 0.18,
            size.height * (0.3 + math.sin(t * 2 * math.pi) * 0.05)),
        120, const Color(0xFF7C4DFF));
    _draw(canvas,
        Offset(size.width * 0.85,
            size.height * (0.55 + math.cos(t * 2 * math.pi) * 0.04)),
        110, const Color(0xFF00BCD4));
    _draw(canvas,
        Offset(size.width * 0.5,
            size.height * (0.92 + math.sin(t * math.pi) * 0.03)),
        85, const Color(0xFFFFD700));
  }

  void _draw(Canvas canvas, Offset c, double r, Color color) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5);
    canvas.drawCircle(c, r, p);
  }

  @override
  bool shouldRepaint(_EgOrbsPainter old) => old.t != t;
}
