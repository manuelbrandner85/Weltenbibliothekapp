// Galdr-Meditation: Runen-Gesang fuer alle 24 Elder Futhark.
// Bereich D2 -- Atemzyklus + visuelle Runen-Pulsation.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/streak_tracking_service.dart';
import '../../../widgets/cinematic/wb_ambient_particles.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/cinematic/wb_vignette.dart';
import '../../../theme/wb_cinematic_tokens.dart';

class _GaldrRune {
  final String glyph;
  final String name;
  final String galdrSound;
  final String shortMeaning;
  const _GaldrRune(this.glyph, this.name, this.galdrSound, this.shortMeaning);
}

const List<_GaldrRune> _galdrRunes = [
  _GaldrRune('ᚠ', 'Fehu', 'Feee-huuu', 'Reichtum, Wohlstand, Vieh'),
  _GaldrRune('ᚢ', 'Uruz', 'Uuuu-ruuuz', 'Urkraft, Vitalitaet, Ur-Stier'),
  _GaldrRune('ᚦ', 'Thurisaz', 'Thuuuu-rii-saaz', 'Thors Hammer, Schutz, Tor'),
  _GaldrRune('ᚨ', 'Ansuz', 'Aaaan-suuuz', 'Odins Atem, Wort, Inspiration'),
  _GaldrRune('ᚱ', 'Raidho', 'Rrrrai-dhooo', 'Reise, Rhythmus, Weg'),
  _GaldrRune('ᚲ', 'Kenaz', 'Keeee-naaz', 'Fackel, Erkenntnis, Kunst'),
  _GaldrRune('ᚷ', 'Gebo', 'Geee-booo', 'Gabe, Ausgleich, Partnerschaft'),
  _GaldrRune('ᚹ', 'Wunjo', 'Wuuun-jooo', 'Freude, Harmonie, Erfuellung'),
  _GaldrRune('ᚺ', 'Hagalaz', 'Haaa-ga-laaz', 'Hagel, Disruption, Wandlung'),
  _GaldrRune('ᚾ', 'Nauthiz', 'Nauu-thiiz', 'Not, Notwendigkeit, Geduld'),
  _GaldrRune('ᛁ', 'Isa', 'Iiiii-saaaa', 'Eis, Stillstand, Konzentration'),
  _GaldrRune('ᛃ', 'Jera', 'Yeee-raaa', 'Jahr, Ernte, Zyklus'),
  _GaldrRune('ᛇ', 'Eihwaz', 'Eiiii-waaz', 'Eibe, Weltenbaum, Transformation'),
  _GaldrRune(
      'ᛈ', 'Perthro', 'Peeer-throoo', 'Wuerfelbecher, Schicksal, Mysterium'),
  _GaldrRune('ᛉ', 'Algiz', 'Aaal-giiz', 'Elch, Schutz, Verbindung Oben'),
  _GaldrRune('ᛊ', 'Sowilo', 'Sooo-wiiii-looo', 'Sonne, Sieg, Lebensenergie'),
  _GaldrRune('ᛏ', 'Tiwaz', 'Tiiii-waaz', 'Tyr, Gerechtigkeit, Mut'),
  _GaldrRune('ᛒ', 'Berkano', 'Beeer-kaa-nooo', 'Birke, Naehren, Wachstum'),
  _GaldrRune('ᛖ', 'Ehwaz', 'Eeeh-waaz', 'Pferd, Partnerschaft, Bewegung'),
  _GaldrRune('ᛗ', 'Mannaz', 'Maaan-naaz', 'Mensch, Selbst, Gemeinschaft'),
  _GaldrRune('ᛚ', 'Laguz', 'Laaa-guuz', 'Wasser, Intuition, Fluss'),
  _GaldrRune('ᛜ', 'Ingwaz', 'Iiing-waaz', 'Ing/Freyr, Frieden, Reife'),
  _GaldrRune('ᛞ', 'Dagaz', 'Daaa-gaaz', 'Tag, Erwachen, Wende'),
  _GaldrRune('ᛟ', 'Othala', 'Ooo-tha-laaa', 'Erbe, Heimat, Ahnen'),
];

class GaldrMeditationScreen extends StatefulWidget {
  const GaldrMeditationScreen({super.key});

  @override
  State<GaldrMeditationScreen> createState() => _GaldrMeditationScreenState();
}

class _GaldrMeditationScreenState extends State<GaldrMeditationScreen>
    with TickerProviderStateMixin {
  _GaldrRune _selected = _galdrRunes[0];
  late final AnimationController _breath;
  late final AnimationController _glow;
  bool _running = false;
  int _selectedMinutes = 3;
  int _remainingSec = 0;
  Timer? _timer;

  static const _gold = Color(0xFFC9A84C);
  static const _norse = Color(0xFF1B5E7F);

  @override
  void initState() {
    super.initState();
    StreakTrackingService().trackToolUsage('galdr_meditation');
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16), // 4s ein + 8s ton + 4s aus
    );
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breath.dispose();
    _glow.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _running = true;
      _remainingSec = _selectedMinutes * 60;
    });
    _breath.repeat();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remainingSec--;
      });
      if (_remainingSec <= 0) _stop(completed: true);
    });
  }

  void _stop({bool completed = false}) {
    _timer?.cancel();
    _breath.stop();
    setState(() => _running = false);
    if (completed && mounted) {
      HapticFeedback.heavyImpact();
      StreakTrackingService().trackToolUsage('galdr_completed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${_selected.name}-Meditation abgeschlossen · +${_selectedMinutes * 2} XP'),
          backgroundColor: _norse,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _phaseLabel() {
    final t = _breath.value;
    if (t < 0.25) return 'EINATMEN';
    if (t < 0.75) return 'GALDR · ${_selected.galdrSound}';
    return 'AUSATMEN';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030610),
      extendBodyBehindAppBar: true,
      appBar: const WBGlassAppBar(
        title: 'Galdr-Meditation',
        world: WBWorld.energie,
      ),
      body: Stack(
        children: [
          const IgnorePointer(
            child: WBAmbientParticles(world: WBWorld.energie, count: 24),
          ),
          const WBVignette(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 64, 20, 24),
              child: _running ? _runningView() : _setupView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _setupView() {
    return Column(
      children: [
        const Text('Waehle eine Rune',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4)),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: _galdrRunes.length,
            itemBuilder: (_, i) {
              final r = _galdrRunes[i];
              final sel = r.glyph == _selected.glyph;
              return GestureDetector(
                onTap: () => setState(() => _selected = r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: sel
                          ? [
                              _gold.withValues(alpha: 0.25),
                              _norse.withValues(alpha: 0.15),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.05),
                              Colors.white.withValues(alpha: 0.02),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sel ? _gold : Colors.white.withValues(alpha: 0.1),
                      width: sel ? 1.6 : 1,
                    ),
                    boxShadow: sel
                        ? [
                            BoxShadow(
                              color: _gold.withValues(alpha: 0.35),
                              blurRadius: 14,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(r.glyph,
                          style: TextStyle(
                              fontSize: 28,
                              color: sel ? _gold : Colors.white70,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(r.name,
                          style: TextStyle(
                              fontSize: 9,
                              color: sel ? Colors.white : Colors.white54,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _gold.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            Text(_selected.glyph,
                style: const TextStyle(fontSize: 36, color: _gold)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_selected.name} · ${_selected.galdrSound}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(_selected.shortMeaning,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12, height: 1.4)),
                ],
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [3, 5, 9].map((m) {
            final sel = m == _selectedMinutes;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: GestureDetector(
                onTap: () => setState(() => _selectedMinutes = m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel
                        ? _gold.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: sel ? _gold : Colors.white24, width: 1.2),
                  ),
                  child: Text('$m min',
                      style: TextStyle(
                          color: sel ? _gold : Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5)),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _start,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Galdr starten'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _runningView() {
    final mm = (_remainingSec ~/ 60).toString().padLeft(2, '0');
    final ss = (_remainingSec % 60).toString().padLeft(2, '0');
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(_phaseLabel(),
            style: const TextStyle(
                color: _gold,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.5)),
        const SizedBox(height: 6),
        Text('$mm:$ss',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1)),
        const SizedBox(height: 30),
        Expanded(
          child: AnimatedBuilder(
            animation: Listenable.merge([_breath, _glow]),
            builder: (_, __) {
              final t = _breath.value;
              double s = 1.0;
              if (t < 0.25) {
                s = 0.85 + (t * 4) * 0.35;
              } else if (t < 0.75) {
                s = 1.2;
              } else {
                s = 1.2 - ((t - 0.75) * 4) * 0.35;
              }
              return Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: s + _glow.value * 0.05,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            _gold.withValues(alpha: 0.55 + _glow.value * 0.2),
                            _norse.withValues(alpha: 0.25),
                            Colors.transparent,
                          ]),
                          boxShadow: [
                            BoxShadow(
                              color: _gold.withValues(alpha: 0.4),
                              blurRadius: 60,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      _selected.glyph,
                      style: TextStyle(
                        fontSize: 140 * s,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: _gold, blurRadius: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(_selected.galdrSound,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 4)),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _stop(),
            icon: const Icon(Icons.stop_rounded),
            label: const Text('Beenden'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
