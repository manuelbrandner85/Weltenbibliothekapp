// 🪞 REALITAETS-HOPPER - App-Theme-Override fuer 60s zu paralleler Realitaet
//
// 4 Schichten: Glitch-Dim (RGB-Shift), Red-Dim (Mars), Mirror-World (horizontal-flip),
// Quantum-Foam (sin-wave-displacement). Aktiv fuer 60 Sekunden, dann auto-zurueck.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_ambient_particles.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';

class RealitaetsHopperScreen extends StatefulWidget {
  const RealitaetsHopperScreen({super.key});

  @override
  State<RealitaetsHopperScreen> createState() => _RealitaetsHopperScreenState();
}

class _RealitaetsHopperScreenState extends State<RealitaetsHopperScreen>
    with TickerProviderStateMixin {
  static const Color _bg = Color(0xFF050010);

  _Realm? _activeRealm;
  int _secondsLeft = 0;
  Timer? _hopTimer;
  late final AnimationController _glitchCtrl;
  late final AnimationController _ambientCtrl;

  @override
  void initState() {
    super.initState();
    _glitchCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat();
    _ambientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  }

  @override
  void dispose() {
    _hopTimer?.cancel();
    _glitchCtrl.dispose();
    _ambientCtrl.dispose();
    super.dispose();
  }

  void _hop(_Realm r) {
    HapticFeedback.heavyImpact();
    _hopTimer?.cancel();
    setState(() {
      _activeRealm = r;
      _secondsLeft = 60;
    });
    _hopTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        HapticFeedback.mediumImpact();
        setState(() => _activeRealm = null);
      }
    });
  }

  void _exit() {
    _hopTimer?.cancel();
    HapticFeedback.lightImpact();
    setState(() { _activeRealm = null; _secondsLeft = 0; });
  }

  @override
  Widget build(BuildContext context) {
    final realm = _activeRealm;
    final body = realm == null ? _realmPicker() : _activeRealmView(realm);
    return Scaffold(
      backgroundColor: realm?.bg ?? _bg,
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        world: WBWorld.neutral,
        titleWidget: ShaderMask(
          shaderCallback: (r) => LinearGradient(colors: [realm?.accent ?? const Color(0xFF7C4DFF), Colors.white]).createShader(r),
          child: const Text('REALITAETS-HOPPER',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 3)),
        ),
        actions: [
          if (realm != null)
            IconButton(
              icon: const Icon(Icons.exit_to_app_rounded, color: Colors.white),
              tooltip: 'Zurück zur Heimwelt',
              onPressed: _exit,
            ),
        ],
      ),
      body: body,
    );
  }

  Widget _realmPicker() {
    return Stack(fit: StackFit.expand, children: [
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center, radius: 1.6,
            colors: [Color(0x55311B92), Color(0x33120833), _bg],
          ),
        ),
      ),
      IgnorePointer(
        child: AnimatedBuilder(
          animation: _ambientCtrl,
          builder: (_, __) => CustomPaint(
            painter: _RealmOrbsPainter(_ambientCtrl.value),
            size: Size.infinite,
          ),
        ),
      ),
      const IgnorePointer(child: WBAmbientParticles(world: WBWorld.neutral, count: 50)),
      SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            Center(
              child: Text('🪞',
                  style: TextStyle(fontSize: 70, shadows: [
                    Shadow(color: Colors.white.withValues(alpha: 0.3), blurRadius: 20),
                  ])),
            ),
            const SizedBox(height: 10),
            const Text(
              'Wechsle für 60 Sekunden in eine parallele Realität.\n'
              'Sieh wie sich dein Wahrnehmen verschiebt.',
              style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            ..._realms.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _hop(r),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [r.accent.withValues(alpha: 0.2), r.bg.withValues(alpha: 0.05)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: r.accent.withValues(alpha: 0.4)),
                            ),
                            child: Row(children: [
                              Text(r.emoji, style: const TextStyle(fontSize: 40)),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.name,
                                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 3),
                                    Text(r.description,
                                        style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.3)),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_rounded, color: r.accent),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    ]);
  }

  Widget _activeRealmView(_Realm realm) {
    return Stack(fit: StackFit.expand, children: [
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center, radius: 1.5,
            colors: [realm.accent.withValues(alpha: 0.4), realm.accent.withValues(alpha: 0.15), realm.bg],
          ),
        ),
      ),
      // Realm-spezifischer Glitch-Effect
      AnimatedBuilder(
        animation: _glitchCtrl,
        builder: (_, __) => CustomPaint(
          size: Size.infinite,
          painter: _GlitchPainter(realm, _glitchCtrl.value),
        ),
      ),
      const IgnorePointer(child: WBAmbientParticles(world: WBWorld.neutral, count: 80)),
      SafeArea(
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(realm.emoji,
                style: TextStyle(
                    fontSize: 120,
                    shadows: [Shadow(color: realm.accent, blurRadius: 40)])),
            const SizedBox(height: 18),
            ShaderMask(
              shaderCallback: (r) => LinearGradient(colors: [realm.accent, Colors.white]).createShader(r),
              child: Text(realm.name.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 4)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: realm.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: realm.accent),
              ),
              child: Text('$_secondsLeft s zurück zur Heimwelt',
                  style: TextStyle(color: realm.accent, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(realm.affirmation,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic, height: 1.6),
                  textAlign: TextAlign.center),
            ),
          ]),
        ),
      ),
    ]);
  }
}

class _Realm {
  final String name;
  final String emoji;
  final String description;
  final String affirmation;
  final Color bg;
  final Color accent;
  const _Realm(this.name, this.emoji, this.description, this.affirmation, this.bg, this.accent);
}

const List<_Realm> _realms = [
  _Realm(
    'Glitch-Dim', '⚡',
    'RGB-Verschiebung · Glitch in der Matrix · Was nicht passt schimmert.',
    'Was du gerade siehst ist ein Code. Du darfst durchschauen.',
    Color(0xFF0A0014), Color(0xFFE91E63),
  ),
  _Realm(
    'Mars-Dim', '🔴',
    'Rote Sonne · 2x Schwerkraft · alte Krieger-Erinnerung erwacht.',
    'Hier wohnt die Kraft die du im Alltag dimmst. Spür sie kurz.',
    Color(0xFF260606), Color(0xFFFF7043),
  ),
  _Realm(
    'Spiegelwelt', '🪞',
    'Alles ist umgedreht · was du suchst sucht dich · Gegenuhrzeigersinn.',
    'Die Lösung liegt im Gegenteil von dem was du planst.',
    Color(0xFF0A0E1C), Color(0xFF42A5F5),
  ),
  _Realm(
    'Quanten-Schaum', '🌊',
    'Realität wackelt · Wahrscheinlichkeitswolke · alle Versionen koexistieren.',
    'In diesem Moment existieren tausend Versionen von dir. Du wählst.',
    Color(0xFF001A1A), Color(0xFF00BCD4),
  ),
];

class _RealmOrbsPainter extends CustomPainter {
  final double t;
  _RealmOrbsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFFE91E63),
      const Color(0xFFFF7043),
      const Color(0xFF42A5F5),
      const Color(0xFF00BCD4),
    ];
    for (int i = 0; i < 4; i++) {
      final angle = (t * 2 + i * 0.5) * math.pi;
      _draw(canvas,
          Offset(size.width * (0.2 + 0.6 * (i / 3.0)),
              size.height * (0.3 + math.sin(angle) * 0.05)),
          90 + i * 8.0, colors[i]);
    }
  }

  void _draw(Canvas canvas, Offset c, double r, Color color) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5);
    canvas.drawCircle(c, r, p);
  }

  @override
  bool shouldRepaint(_RealmOrbsPainter old) => old.t != t;
}

class _GlitchPainter extends CustomPainter {
  final _Realm realm;
  final double t;
  _GlitchPainter(this.realm, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(42);
    if (realm.name.startsWith('Glitch')) {
      // RGB-shift bars
      for (int i = 0; i < 12; i++) {
        final y = (rand.nextDouble() * size.height + t * size.height) % size.height;
        canvas.drawRect(
          Rect.fromLTWH(0, y, size.width, 2),
          Paint()..color = realm.accent.withValues(alpha: 0.3 * math.sin(t * 2 * math.pi).abs()),
        );
      }
    } else if (realm.name == 'Quanten-Schaum') {
      // Wave displacement
      for (int i = 0; i < 8; i++) {
        final angle = (t * 4 + i * 0.7) * math.pi;
        canvas.drawCircle(
          Offset(size.width / 2 + math.sin(angle) * 80, size.height / 2 + math.cos(angle) * 60),
          50 + math.sin(t * 6) * 20,
          Paint()
            ..color = realm.accent.withValues(alpha: 0.08)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GlitchPainter old) => old.t != t;
}
