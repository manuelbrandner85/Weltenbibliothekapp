// 🛡️ PORTAL DEFENSE - Cinematic Tap-Defense-Game
//
// Schatten-Orbs ziehen vom Rand zum Portal-Zentrum. Tap sie weg, bevor sie
// das Portal erreichen. Pro überstandener Welle: +1 HP, neues Power-Up,
// härtere nächste Welle. Spezial-Orbs (Golden = +50 Pkt, Heal = +1 HP).
// 60-FPS single-Ticker-Loop, alle Effekte via CustomPaint — keine externe
// Game-Engine.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/cinematic/wb_vignette.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Konstanten
// ─────────────────────────────────────────────────────────────────────────────

const Color _kBg = Color(0xFF030212);
const Color _kPortalGold = Color(0xFFFFD86B);
const Color _kPortalAmber = Color(0xFFC9A84C);
const Color _kShadowDeep = Color(0xFF1B0B2A);
const Color _kShadowRed = Color(0xFFB23A6B);
const Color _kShadowPurple = Color(0xFF5B2A8A);
const Color _kGoldenOrb = Color(0xFFFFE082);
const Color _kHealOrb = Color(0xFF66E3B0);
const Color _kHpHeart = Color(0xFFFF6E8A);

const double _kPortalRadius = 42.0;
const double _kPortalDeadzone = 50.0; // Orb gilt als am Portal angekommen
const double _kBaseOrbRadius = 22.0;

const Duration _kWaveDuration = Duration(seconds: 60);
const Duration _kBreakDuration = Duration(seconds: 5);

// ─────────────────────────────────────────────────────────────────────────────
//  Daten-Klassen (explizit, kein Record — dart2js-safe)
// ─────────────────────────────────────────────────────────────────────────────

enum _OrbType { shadow, golden, heal }

enum _PhaseKind { intro, wave, breakPause, gameOver }

enum _PowerUpKind { shield, lightning, slowTime, heal }

class _GameOrb {
  Offset position;
  Offset velocity; // Pixel pro Sekunde
  double radius;
  final _OrbType type;
  double pulse; // 0..1 phase for visual pulse
  bool dead;

  _GameOrb({
    required this.position,
    required this.velocity,
    required this.radius,
    required this.type,
    required this.pulse,
  }) : dead = false;
}

class _HitFx {
  final Offset center;
  final Color color;
  double age; // Sekunden
  final double maxAge;
  final List<_Spark> sparks;

  _HitFx({
    required this.center,
    required this.color,
    required this.maxAge,
    required this.sparks,
  }) : age = 0.0;
}

class _Spark {
  Offset offset; // current relative offset from center
  final Offset velocity; // px / sec relative
  _Spark({required this.offset, required this.velocity});
}

class _FloatingText {
  final String text;
  Offset position;
  double age;
  final double maxAge;
  final Color color;
  final double fontSize;

  _FloatingText({
    required this.text,
    required this.position,
    required this.maxAge,
    required this.color,
    required this.fontSize,
  }) : age = 0.0;
}

class _PowerUpOption {
  final _PowerUpKind kind;
  final String label;
  final String description;
  final IconData icon;
  final Color color;

  const _PowerUpOption({
    required this.kind,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });
}

const List<_PowerUpOption> _kAllPowerUps = [
  _PowerUpOption(
    kind: _PowerUpKind.shield,
    label: 'Aura-Schild',
    description: '+2 HP für die nächste Welle',
    icon: Icons.shield_moon_outlined,
    color: Color(0xFF8AA3FF),
  ),
  _PowerUpOption(
    kind: _PowerUpKind.lightning,
    label: 'Blitz',
    description: 'Ein Tap zerstört alle Schatten',
    icon: Icons.flash_on_rounded,
    color: Color(0xFFFFD86B),
  ),
  _PowerUpOption(
    kind: _PowerUpKind.slowTime,
    label: 'Zeit-Anker',
    description: 'Schatten 50% langsamer für 10s',
    icon: Icons.hourglass_bottom_rounded,
    color: Color(0xFF66E3B0),
  ),
  _PowerUpOption(
    kind: _PowerUpKind.heal,
    label: 'Heilung',
    description: '+2 HP sofort wirksam',
    icon: Icons.favorite_rounded,
    color: Color(0xFFFF6E8A),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
//  Public Screen
// ─────────────────────────────────────────────────────────────────────────────

class PortalDefenseGameScreen extends StatefulWidget {
  const PortalDefenseGameScreen({super.key});

  @override
  State<PortalDefenseGameScreen> createState() =>
      _PortalDefenseGameScreenState();
}

class _PortalDefenseGameScreenState extends State<PortalDefenseGameScreen>
    with TickerProviderStateMixin {
  // ── Game-State ────────────────────────────────────────────────────────────
  _PhaseKind _phase = _PhaseKind.intro;
  int _wave = 0;
  int _score = 0;
  int _hp = 5;
  int _maxHp = 5;
  int _orbsKilledTotal = 0;
  int _orbsSpawnedThisWave = 0;
  int _orbsToSpawnThisWave = 0;
  double _waveRemaining = 0; // Sekunden
  double _breakRemaining = 0;
  double _slowTimeRemaining = 0;
  bool _hasLightningCharge = false;
  bool _shieldNextWave = false;
  bool _paused = false;

  int _highScore = 0;
  int _totalGames = 0;
  bool _isNewHighscore = false;

  // ── Combo-System ──────────────────────────────────────────────────────────
  final List<DateTime> _recentKills = [];
  int _comboMultiplier = 1;

  // ── Welt / Felder ─────────────────────────────────────────────────────────
  Size _fieldSize = Size.zero;
  Offset get _portalCenter => Offset(_fieldSize.width / 2, _fieldSize.height / 2);

  final List<_GameOrb> _orbs = [];
  final List<_HitFx> _fx = [];
  final List<_FloatingText> _floats = [];

  // ── Animation ─────────────────────────────────────────────────────────────
  late final AnimationController _tickerCtrl;
  late final AnimationController _portalPulseCtrl;
  late final AnimationController _backgroundCtrl;
  late final AnimationController _overlayCtrl;
  Duration _lastTick = Duration.zero;

  // ── Spawning ──────────────────────────────────────────────────────────────
  Timer? _spawnTimer;
  Timer? _phaseTimer;

  // ── Power-Ups zur Auswahl in der Pause ────────────────────────────────────
  List<_PowerUpOption> _powerUpChoices = const [];

  final math.Random _rng = math.Random();

  // ──────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tickerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    );
    _tickerCtrl.addListener(_onFrame);

    _portalPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _backgroundCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _overlayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _loadStats();
    _tickerCtrl.forward();
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _phaseTimer?.cancel();
    _tickerCtrl
      ..removeListener(_onFrame)
      ..stop()
      ..dispose();
    _portalPulseCtrl.dispose();
    _backgroundCtrl.dispose();
    _overlayCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _highScore = prefs.getInt('portal_defense_highscore') ?? 0;
      _totalGames = prefs.getInt('portal_defense_total_games') ?? 0;
      _orbsKilledTotal = prefs.getInt('portal_defense_total_orbs_killed') ?? 0;
    });
  }

  Future<void> _persistStats({required bool gameFinished}) async {
    final prefs = await SharedPreferences.getInstance();
    if (_score > _highScore) {
      _highScore = _score;
      _isNewHighscore = true;
      await prefs.setInt('portal_defense_highscore', _highScore);
    }
    if (gameFinished) {
      _totalGames++;
      await prefs.setInt('portal_defense_total_games', _totalGames);
    }
    await prefs.setInt('portal_defense_total_orbs_killed', _orbsKilledTotal);
  }

  // ── Lifecycle des Spiels ──────────────────────────────────────────────────

  void _startNewGame() {
    _spawnTimer?.cancel();
    _phaseTimer?.cancel();
    setState(() {
      _wave = 0;
      _score = 0;
      _maxHp = 5;
      _hp = 5;
      _orbs.clear();
      _fx.clear();
      _floats.clear();
      _comboMultiplier = 1;
      _recentKills.clear();
      _hasLightningCharge = false;
      _shieldNextWave = false;
      _slowTimeRemaining = 0;
      _paused = false;
      _isNewHighscore = false;
      _phase = _PhaseKind.breakPause;
      _breakRemaining = 2.0;
      _powerUpChoices = const [];
    });
    HapticFeedback.mediumImpact();
    _phaseTimer = Timer(const Duration(seconds: 2), _beginNextWave);
  }

  void _beginNextWave() {
    if (!mounted) return;
    _wave++;
    _orbsSpawnedThisWave = 0;
    _orbsToSpawnThisWave = _orbsForWave(_wave);
    final spawnIntervalMs = _spawnIntervalMs(_wave);

    if (_shieldNextWave) {
      _maxHp += 2;
      _hp = math.min(_hp + 2, _maxHp);
      _shieldNextWave = false;
    }

    setState(() {
      _phase = _PhaseKind.wave;
      _waveRemaining = _kWaveDuration.inSeconds.toDouble();
    });
    HapticFeedback.mediumImpact();

    _spawnTimer?.cancel();
    _spawnTimer = Timer.periodic(
      Duration(milliseconds: spawnIntervalMs),
      (_) => _spawnOneOrb(),
    );
    _phaseTimer?.cancel();
    _phaseTimer = Timer(_kWaveDuration, _endWaveAlive);
  }

  void _endWaveAlive() {
    if (!mounted) return;
    _spawnTimer?.cancel();
    // Welle überstanden: regen + Power-Up-Wahl.
    final regen = math.min(1, _maxHp - _hp);
    setState(() {
      _hp = math.min(_hp + regen, _maxHp);
      _hasLightningCharge = false;
      _orbs.clear();
      _phase = _PhaseKind.breakPause;
      _breakRemaining = _kBreakDuration.inSeconds.toDouble();
      _powerUpChoices = _pickPowerUpChoices();
    });
    HapticFeedback.lightImpact();
    _overlayCtrl
      ..reset()
      ..forward();
    _phaseTimer?.cancel();
    _phaseTimer = Timer(_kBreakDuration, () {
      // Falls Spieler nichts wählt → einfach weiter ohne Bonus.
      if (mounted && _phase == _PhaseKind.breakPause) {
        _beginNextWave();
      }
    });
  }

  void _endGameOver() {
    if (!mounted) return;
    _spawnTimer?.cancel();
    _phaseTimer?.cancel();
    _persistStats(gameFinished: true);
    HapticFeedback.heavyImpact();
    setState(() {
      _phase = _PhaseKind.gameOver;
    });
    _overlayCtrl
      ..reset()
      ..forward();
  }

  // ── Wave-Difficulty-Kurve ─────────────────────────────────────────────────

  int _orbsForWave(int w) {
    // 10, 15, 20, 30, 40, ...
    switch (w) {
      case 1:
        return 10;
      case 2:
        return 15;
      case 3:
        return 20;
      case 4:
        return 30;
      default:
        return 30 + (w - 4) * 12;
    }
  }

  int _spawnIntervalMs(int w) {
    // Frequenz pro Welle in ms zwischen Spawns. 60s / N + Polster.
    final orbs = _orbsForWave(w);
    final raw = (60000 / orbs).round();
    // Härter ab Welle 3.
    return math.max(450, raw - (w * 30));
  }

  double _orbSpeedForWave(int w) {
    // Pixel pro Sekunde bei einer Field-Höhe von ~700.
    return 55.0 + w * 18.0;
  }

  // ── Spawning ──────────────────────────────────────────────────────────────

  void _spawnOneOrb() {
    if (!mounted || _paused) return;
    if (_phase != _PhaseKind.wave) return;
    if (_fieldSize == Size.zero) return;
    if (_orbsSpawnedThisWave >= _orbsToSpawnThisWave) {
      _spawnTimer?.cancel();
      return;
    }
    _orbsSpawnedThisWave++;

    // Position auf Bildschirmrand (gleichmäßig auf Kanten verteilt).
    final w = _fieldSize.width;
    final h = _fieldSize.height;
    final edge = _rng.nextInt(4);
    Offset start;
    switch (edge) {
      case 0:
        start = Offset(_rng.nextDouble() * w, -20);
        break;
      case 1:
        start = Offset(w + 20, _rng.nextDouble() * h);
        break;
      case 2:
        start = Offset(_rng.nextDouble() * w, h + 20);
        break;
      default:
        start = Offset(-20, _rng.nextDouble() * h);
    }

    final dir = (_portalCenter - start);
    final norm = dir.distance == 0 ? const Offset(0, -1) : dir / dir.distance;
    final speed = _orbSpeedForWave(_wave) *
        (0.8 + _rng.nextDouble() * 0.5) *
        (_slowTimeRemaining > 0 ? 0.5 : 1.0);

    // Spezial-Typ: 10% Chance — davon 60% golden, 40% heal.
    _OrbType type = _OrbType.shadow;
    double radius = _kBaseOrbRadius;
    if (_rng.nextDouble() < 0.10) {
      if (_rng.nextDouble() < 0.6) {
        type = _OrbType.golden;
        radius = 18.0;
      } else {
        type = _OrbType.heal;
        radius = 18.0;
      }
    } else {
      // Mixed sizes ab Welle 3.
      if (_wave >= 3) {
        radius = _kBaseOrbRadius * (0.7 + _rng.nextDouble() * 0.8);
      }
    }

    _orbs.add(_GameOrb(
      position: start,
      velocity: norm * speed,
      radius: radius,
      type: type,
      pulse: _rng.nextDouble(),
    ));
  }

  // ── Frame-Update ──────────────────────────────────────────────────────────

  void _onFrame() {
    final now = _tickerCtrl.lastElapsedDuration ?? Duration.zero;
    final dt = (now - _lastTick).inMicroseconds / 1e6;
    _lastTick = now;
    if (dt <= 0 || dt > 0.25) {
      // Erster Frame oder grosser Sprung — überspringen.
      return;
    }
    if (_paused) return;
    if (_phase == _PhaseKind.wave) {
      _stepWave(dt);
    }
    _stepFx(dt);
    if (mounted) setState(() {});
  }

  void _stepWave(double dt) {
    _waveRemaining = math.max(0, _waveRemaining - dt);
    if (_slowTimeRemaining > 0) {
      _slowTimeRemaining = math.max(0, _slowTimeRemaining - dt);
    }

    // Combo-Fenster aufräumen (>3s alte Kills entfernen).
    final cutoff = DateTime.now().subtract(const Duration(seconds: 3));
    _recentKills.removeWhere((t) => t.isBefore(cutoff));
    _comboMultiplier = _recentKills.length >= 5 ? 2 : 1;

    // Orb-Bewegung + Hit-Test gegen Portal.
    for (final orb in _orbs) {
      if (orb.dead) continue;
      orb.position += orb.velocity * dt;
      orb.pulse = (orb.pulse + dt * 1.8) % 1.0;

      final distToPortal = (orb.position - _portalCenter).distance;
      if (distToPortal < _kPortalDeadzone) {
        orb.dead = true;
        _onOrbReachedPortal(orb);
      }
    }
    _orbs.removeWhere((o) => o.dead);

    // Welle-Ende? (alle gespawnt, alle weg).
    if (_orbsSpawnedThisWave >= _orbsToSpawnThisWave && _orbs.isEmpty) {
      _phaseTimer?.cancel();
      _endWaveAlive();
    }
  }

  void _stepFx(double dt) {
    for (final fx in _fx) {
      fx.age += dt;
      for (final s in fx.sparks) {
        s.offset += s.velocity * dt;
      }
    }
    _fx.removeWhere((f) => f.age >= f.maxAge);

    for (final t in _floats) {
      t.age += dt;
      t.position = Offset(t.position.dx, t.position.dy - dt * 35);
    }
    _floats.removeWhere((t) => t.age >= t.maxAge);
  }

  // ── Orb-Konsequenzen ──────────────────────────────────────────────────────

  void _onOrbReachedPortal(_GameOrb orb) {
    if (orb.type == _OrbType.heal) {
      // Heal-Orbs, die das Portal "erreichen" sind verloren — nicht heilen.
      return;
    }
    // Schaden!
    _hp = math.max(0, _hp - 1);
    HapticFeedback.mediumImpact();
    _spawnHitFx(_portalCenter, _kShadowRed, count: 14, big: true);
    if (_hp == 0) {
      _endGameOver();
    }
  }

  void _onOrbTapped(_GameOrb orb) {
    orb.dead = true;
    _orbsKilledTotal++;
    HapticFeedback.lightImpact();

    int pts;
    Color fxColor;
    switch (orb.type) {
      case _OrbType.shadow:
        pts = 10;
        fxColor = _kShadowPurple;
        break;
      case _OrbType.golden:
        pts = 50;
        fxColor = _kGoldenOrb;
        _floats.add(_FloatingText(
          text: '+50',
          position: orb.position,
          maxAge: 1.1,
          color: _kGoldenOrb,
          fontSize: 22,
        ));
        break;
      case _OrbType.heal:
        pts = 5;
        fxColor = _kHealOrb;
        _hp = math.min(_hp + 1, _maxHp);
        _floats.add(_FloatingText(
          text: '+1 HP',
          position: orb.position,
          maxAge: 1.2,
          color: _kHealOrb,
          fontSize: 18,
        ));
        break;
    }

    _recentKills.add(DateTime.now());
    final effective = pts * _wave * _comboMultiplier;
    _score += effective;

    if (_comboMultiplier > 1 && orb.type == _OrbType.shadow) {
      _floats.add(_FloatingText(
        text: 'COMBO x$_comboMultiplier',
        position: orb.position.translate(0, -20),
        maxAge: 0.9,
        color: _kPortalGold,
        fontSize: 14,
      ));
    }

    _spawnHitFx(orb.position, fxColor, count: 9, big: false);
  }

  void _spawnHitFx(Offset center, Color color,
      {int count = 8, bool big = false}) {
    final sparks = <_Spark>[];
    for (int i = 0; i < count; i++) {
      final ang = _rng.nextDouble() * math.pi * 2;
      final speed = 80 + _rng.nextDouble() * (big ? 220 : 150);
      sparks.add(_Spark(
        offset: Offset.zero,
        velocity: Offset(math.cos(ang) * speed, math.sin(ang) * speed),
      ));
    }
    _fx.add(_HitFx(
      center: center,
      color: color,
      maxAge: big ? 0.55 : 0.35,
      sparks: sparks,
    ));
  }

  // ── Power-Up-Auswahl ──────────────────────────────────────────────────────

  List<_PowerUpOption> _pickPowerUpChoices() {
    final pool = List<_PowerUpOption>.from(_kAllPowerUps)..shuffle(_rng);
    return pool.take(3).toList();
  }

  void _applyPowerUp(_PowerUpOption opt) {
    HapticFeedback.selectionClick();
    switch (opt.kind) {
      case _PowerUpKind.shield:
        _shieldNextWave = true;
        break;
      case _PowerUpKind.lightning:
        _hasLightningCharge = true;
        break;
      case _PowerUpKind.slowTime:
        _slowTimeRemaining = 10.0;
        break;
      case _PowerUpKind.heal:
        _hp = math.min(_hp + 2, _maxHp);
        break;
    }
    _phaseTimer?.cancel();
    _beginNextWave();
  }

  void _useLightning() {
    if (!_hasLightningCharge) return;
    _hasLightningCharge = false;
    HapticFeedback.heavyImpact();
    int knocked = 0;
    for (final orb in _orbs) {
      if (orb.dead) continue;
      orb.dead = true;
      knocked++;
      _orbsKilledTotal++;
      _spawnHitFx(orb.position, _kPortalGold, count: 6);
      final pts = (orb.type == _OrbType.golden ? 50 : 8) * _wave;
      _score += pts;
    }
    if (knocked > 0) {
      _floats.add(_FloatingText(
        text: 'BLITZ! x$knocked',
        position: _portalCenter.translate(0, -90),
        maxAge: 1.3,
        color: _kPortalGold,
        fontSize: 22,
      ));
    }
  }

  // ── Eingabe ───────────────────────────────────────────────────────────────

  void _handleTap(Offset localPos) {
    if (_paused) return;
    if (_phase != _PhaseKind.wave) return;

    // Treffer von "oben nach unten" prüfen (zuletzt gespawnte zuerst).
    for (int i = _orbs.length - 1; i >= 0; i--) {
      final orb = _orbs[i];
      if (orb.dead) continue;
      final hitRadius = orb.radius + 14; // grosszuegig fuer Fairness
      if ((orb.position - localPos).distance <= hitRadius) {
        _onOrbTapped(orb);
        _orbs.removeAt(i);
        return;
      }
    }
    // Miss: leichte Funken-Wolke an Tap-Position als Feedback.
    _spawnHitFx(localPos, const Color(0x44FFFFFF), count: 4);
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isPortrait = mq.size.height >= mq.size.width;

    return Scaffold(
      backgroundColor: _kBg,
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        title: 'PORTAL  DEFENSE',
        actions: [
          if (_phase == _PhaseKind.wave)
            IconButton(
              tooltip: _paused ? 'Fortsetzen' : 'Pause',
              icon: Icon(
                _paused
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() => _paused = !_paused);
                HapticFeedback.selectionClick();
              },
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Hintergrund: Radial-Gradient zur Portal-Mitte.
          AnimatedBuilder(
            animation: _backgroundCtrl,
            builder: (context, _) => CustomPaint(
              painter: _BackgroundPainter(t: _backgroundCtrl.value),
              size: Size.infinite,
            ),
          ),
          const WBVignette(),

          // Spielfeld + Eingabe.
          Padding(
            padding: EdgeInsets.only(top: kToolbarHeight + mq.padding.top),
            child: LayoutBuilder(
              builder: (context, constraints) {
                _fieldSize = constraints.biggest;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => _handleTap(d.localPosition),
                  child: AnimatedBuilder(
                    animation: Listenable.merge(
                        [_portalPulseCtrl, _backgroundCtrl, _tickerCtrl]),
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _GamePainter(
                          orbs: _orbs,
                          fx: _fx,
                          floats: _floats,
                          portalCenter: Offset(
                            constraints.maxWidth / 2,
                            constraints.maxHeight / 2,
                          ),
                          portalPulse: _portalPulseCtrl.value,
                          slowActive: _slowTimeRemaining > 0,
                        ),
                        size: Size.infinite,
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Top-HUD über dem Spielfeld.
          Positioned(
            top: kToolbarHeight + mq.padding.top + 8,
            left: 12,
            right: 12,
            child: IgnorePointer(
              ignoring: false,
              child: _HudBar(
                hp: _hp,
                maxHp: _maxHp,
                wave: _wave,
                score: _score,
                hasLightning: _hasLightningCharge,
                slowSeconds: _slowTimeRemaining,
                combo: _comboMultiplier,
                onLightning: _useLightning,
              ),
            ),
          ),

          if (!isPortrait)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Center(
                child: Text(
                  'Im Hochformat besser spielbar.',
                  style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12),
                ),
              ),
            ),

          // Overlays.
          if (_phase == _PhaseKind.intro) _IntroOverlay(
              highScore: _highScore,
              totalGames: _totalGames,
              orbsKilled: _orbsKilledTotal,
              onStart: _startNewGame,
            ),
          if (_phase == _PhaseKind.breakPause && _wave > 0)
            _WaveBreakOverlay(
              nextWave: _wave + 1,
              hp: _hp,
              maxHp: _maxHp,
              countdown: _breakRemaining.ceil(),
              choices: _powerUpChoices,
              onChoose: _applyPowerUp,
              fadeIn: _overlayCtrl,
            ),
          if (_phase == _PhaseKind.breakPause && _wave == 0)
            _PreparingOverlay(countdown: _breakRemaining.ceil()),
          if (_phase == _PhaseKind.gameOver)
            _GameOverOverlay(
              score: _score,
              wave: _wave,
              highScore: _highScore,
              isNewHighscore: _isNewHighscore,
              onRetry: _startNewGame,
              onLeave: () => Navigator.of(context).maybePop(),
              fadeIn: _overlayCtrl,
            ),

          if (_paused && _phase == _PhaseKind.wave) const _PausedOverlay(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HUD-Bar
// ─────────────────────────────────────────────────────────────────────────────

class _HudBar extends StatelessWidget {
  final int hp;
  final int maxHp;
  final int wave;
  final int score;
  final bool hasLightning;
  final double slowSeconds;
  final int combo;
  final VoidCallback onLightning;

  const _HudBar({
    required this.hp,
    required this.maxHp,
    required this.wave,
    required this.score,
    required this.hasLightning,
    required this.slowSeconds,
    required this.combo,
    required this.onLightning,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(WBRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(WBRadius.lg),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              // HP
              Expanded(
                flex: 3,
                child: _HpRow(hp: hp, maxHp: maxHp),
              ),
              const SizedBox(width: 8),
              // Wave / Score in der Mitte
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      wave == 0 ? 'BEREIT' : 'WELLE  $wave',
                      style: const TextStyle(
                        color: Color(0xFFEEC97A),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(
                        colors: [_kPortalGold, Color(0xFFFFB347), Color(0xFFFF8A65)],
                      ).createShader(rect),
                      child: Text(
                        '$score',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          fontFamilyFallback: ['Inter'],
                        ),
                      ),
                    ),
                    if (combo > 1)
                      Text(
                        'COMBO  x$combo',
                        style: const TextStyle(
                          color: _kPortalGold,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.5,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Power-Up rechts
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _PowerSlot(
                    hasLightning: hasLightning,
                    slowSeconds: slowSeconds,
                    onLightning: onLightning,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HpRow extends StatelessWidget {
  final int hp;
  final int maxHp;
  const _HpRow({required this.hp, required this.maxHp});

  @override
  Widget build(BuildContext context) {
    final shown = math.min(maxHp, 8); // max 8 sichtbare Herzen
    return Wrap(
      spacing: 3,
      runSpacing: 2,
      children: List.generate(shown, (i) {
        final filled = i < hp;
        return Icon(
          filled ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 16,
          color: filled ? _kHpHeart : Colors.white.withValues(alpha: 0.22),
        );
      }),
    );
  }
}

class _PowerSlot extends StatelessWidget {
  final bool hasLightning;
  final double slowSeconds;
  final VoidCallback onLightning;

  const _PowerSlot({
    required this.hasLightning,
    required this.slowSeconds,
    required this.onLightning,
  });

  @override
  Widget build(BuildContext context) {
    if (hasLightning) {
      return GestureDetector(
        onTap: onLightning,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _kPortalGold.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(WBRadius.pill),
            border: Border.all(color: _kPortalGold.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: _kPortalGold.withValues(alpha: 0.35),
                blurRadius: 14,
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flash_on_rounded, size: 16, color: _kPortalGold),
              SizedBox(width: 4),
              Text(
                'BLITZ',
                style: TextStyle(
                  color: _kPortalGold,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (slowSeconds > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _kHealOrb.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(WBRadius.pill),
          border: Border.all(color: _kHealOrb.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_bottom_rounded,
                size: 14, color: _kHealOrb),
            const SizedBox(width: 4),
            Text(
              '${slowSeconds.ceil()}s',
              style: const TextStyle(
                color: _kHealOrb,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Overlays
// ─────────────────────────────────────────────────────────────────────────────

class _IntroOverlay extends StatelessWidget {
  final int highScore;
  final int totalGames;
  final int orbsKilled;
  final VoidCallback onStart;

  const _IntroOverlay({
    required this.highScore,
    required this.totalGames,
    required this.orbsKilled,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(WBSpace.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    colors: [_kPortalGold, Color(0xFFFFB347)],
                  ).createShader(r),
                  child: const Text(
                    'PORTAL  DEFENSE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 6,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Schatten-Wesen ziehen zum Portal.\nTippe sie weg, bevor sie es erreichen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 13,
                    height: 1.5,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 24),
                _StatChip(label: 'HIGHSCORE', value: '$highScore'),
                const SizedBox(height: 6),
                _StatChip(label: 'SPIELE', value: '$totalGames'),
                const SizedBox(height: 6),
                _StatChip(label: 'BESIEGT', value: '$orbsKilled'),
                const SizedBox(height: 28),
                _GoldButton(
                  label: 'SPIEL  STARTEN',
                  onTap: onStart,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreparingOverlay extends StatelessWidget {
  final int countdown;
  const _PreparingOverlay({required this.countdown});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'WELLE  1  ✦',
                style: TextStyle(
                  color: _kPortalGold,
                  fontSize: 26,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 7,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$countdown',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w200,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaveBreakOverlay extends StatelessWidget {
  final int nextWave;
  final int hp;
  final int maxHp;
  final int countdown;
  final List<_PowerUpOption> choices;
  final ValueChanged<_PowerUpOption> onChoose;
  final AnimationController fadeIn;

  const _WaveBreakOverlay({
    required this.nextWave,
    required this.hp,
    required this.maxHp,
    required this.countdown,
    required this.choices,
    required this.onChoose,
    required this.fadeIn,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: fadeIn,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(fadeIn.value.clamp(0.0, 1.0));
        return Opacity(opacity: t, child: child);
      },
      child: Container(
        color: Colors.black.withValues(alpha: 0.62),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(WBSpace.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'WELLE  ÜBERSTANDEN',
                  style: TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4.5,
                  ),
                ),
                const SizedBox(height: 6),
                ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    colors: [_kPortalGold, Color(0xFFFFB347)],
                  ).createShader(r),
                  child: Text(
                    'WELLE  $nextWave  ✦',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 6,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Portal:  $hp / $maxHp HP   ·   $countdown s',
                  style: const TextStyle(
                    color: Color(0xAAFFFFFF),
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'WÄHLE  EINEN  SEGEN',
                  style: TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3.5,
                  ),
                ),
                const SizedBox(height: 14),
                ...choices.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PowerUpCard(option: c, onTap: () => onChoose(c)),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PowerUpCard extends StatelessWidget {
  final _PowerUpOption option;
  final VoidCallback onTap;
  const _PowerUpCard({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(WBRadius.md),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(WBRadius.md),
              border: Border.all(color: option.color.withValues(alpha: 0.45)),
              boxShadow: [
                BoxShadow(
                  color: option.color.withValues(alpha: 0.2),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: option.color.withValues(alpha: 0.18),
                    border:
                        Border.all(color: option.color.withValues(alpha: 0.6)),
                  ),
                  child: Icon(option.icon, color: option.color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.label,
                        style: TextStyle(
                          color: option.color,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option.description,
                        style: const TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 11.5,
                          letterSpacing: 0.3,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0x66FFFFFF)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameOverOverlay extends StatefulWidget {
  final int score;
  final int wave;
  final int highScore;
  final bool isNewHighscore;
  final VoidCallback onRetry;
  final VoidCallback onLeave;
  final AnimationController fadeIn;

  const _GameOverOverlay({
    required this.score,
    required this.wave,
    required this.highScore,
    required this.isNewHighscore,
    required this.onRetry,
    required this.onLeave,
    required this.fadeIn,
  });

  @override
  State<_GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<_GameOverOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _countCtrl;

  @override
  void initState() {
    super.initState();
    _countCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void dispose() {
    _countCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.fadeIn, _countCtrl]),
      builder: (context, _) {
        final t =
            Curves.easeOutCubic.transform(widget.fadeIn.value.clamp(0.0, 1.0));
        final counted = (widget.score * Curves.easeOutCubic
                .transform(_countCtrl.value.clamp(0.0, 1.0)))
            .round();
        return Opacity(
          opacity: t,
          child: Container(
            color: Colors.black.withValues(alpha: 0.72),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(WBSpace.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'PORTAL  GEFALLEN',
                      style: TextStyle(
                        color: Color(0xFFFF8A8A),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ShaderMask(
                      shaderCallback: (r) => const LinearGradient(
                        colors: [_kPortalGold, Color(0xFFFFB347)],
                      ).createShader(r),
                      child: Text(
                        '$counted',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          fontWeight: FontWeight.w200,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'PUNKTE',
                      style: TextStyle(
                        color: Color(0xAAFFFFFF),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _StatChip(
                      label: 'WELLE',
                      value: '${widget.wave}',
                    ),
                    const SizedBox(height: 8),
                    _StatChip(
                      label: widget.isNewHighscore
                          ? '⭐  NEUER  HIGHSCORE'
                          : 'HIGHSCORE',
                      value: '${widget.highScore}',
                      highlight: widget.isNewHighscore,
                    ),
                    const SizedBox(height: 36),
                    _GoldButton(
                      label: 'NOCHMAL',
                      onTap: widget.onRetry,
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: widget.onLeave,
                      child: const Text(
                        'VERLASSEN',
                        style: TextStyle(
                          color: Color(0xAAFFFFFF),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PausedOverlay extends StatelessWidget {
  const _PausedOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: const Center(
          child: Text(
            'PAUSE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w300,
              letterSpacing: 8,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _StatChip({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight ? _kPortalGold : const Color(0xAAFFFFFF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(WBRadius.pill),
        border: Border.all(
          color: highlight
              ? _kPortalGold.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(
              color: highlight ? _kPortalGold : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GoldButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(WBRadius.pill),
          gradient: const LinearGradient(
            colors: [_kPortalGold, _kPortalAmber],
          ),
          boxShadow: [
            BoxShadow(
              color: _kPortalGold.withValues(alpha: 0.45),
              blurRadius: 22,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1A0F00),
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Painter: Hintergrund (Radial-Puls)
// ─────────────────────────────────────────────────────────────────────────────

class _BackgroundPainter extends CustomPainter {
  final double t;
  const _BackgroundPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final pulse = 0.85 + 0.15 * math.sin(t * math.pi * 2);
    final rect = Rect.fromCircle(center: center, radius: size.longestSide * 0.6);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          _kPortalGold.withValues(alpha: 0.18 * pulse),
          _kPortalAmber.withValues(alpha: 0.08 * pulse),
          _kShadowDeep.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.35, 1.0],
      ).createShader(rect);
    canvas.drawRect(Offset.zero & size, Paint()..color = _kBg);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter old) => old.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Painter: Spielfeld (Portal + Orbs + FX + Floats)
// ─────────────────────────────────────────────────────────────────────────────

class _GamePainter extends CustomPainter {
  final List<_GameOrb> orbs;
  final List<_HitFx> fx;
  final List<_FloatingText> floats;
  final Offset portalCenter;
  final double portalPulse;
  final bool slowActive;

  _GamePainter({
    required this.orbs,
    required this.fx,
    required this.floats,
    required this.portalCenter,
    required this.portalPulse,
    required this.slowActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Slow-Time-Tönung.
    if (slowActive) {
      final overlay = Paint()..color = const Color(0x1A66E3B0);
      canvas.drawRect(Offset.zero & size, overlay);
    }

    _drawPortal(canvas);

    // Linien von Orbs zum Portal (subtile Trails).
    final trailPaint = Paint()
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (final orb in orbs) {
      final dir = portalCenter - orb.position;
      final dist = dir.distance;
      if (dist <= 0) continue;
      final t = (1.0 - (dist / 320).clamp(0.0, 1.0));
      if (t <= 0.05) continue;
      trailPaint.color = _orbColor(orb).withValues(alpha: 0.18 * t);
      canvas.drawLine(orb.position, portalCenter, trailPaint);
    }

    // Orbs.
    for (final orb in orbs) {
      _drawOrb(canvas, orb);
    }

    // Hit-FX.
    for (final f in fx) {
      final lifeT = (f.age / f.maxAge).clamp(0.0, 1.0);
      final alpha = (1.0 - lifeT);
      final paint = Paint()..color = f.color.withValues(alpha: alpha);
      for (final s in f.sparks) {
        canvas.drawCircle(f.center + s.offset, 2.5 * (1 - lifeT * 0.6), paint);
      }
      // Ring
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * (1 - lifeT)
        ..color = f.color.withValues(alpha: 0.55 * alpha);
      canvas.drawCircle(f.center, 8 + 60 * lifeT, ringPaint);
    }

    // Floating text.
    for (final t in floats) {
      final lifeT = (t.age / t.maxAge).clamp(0.0, 1.0);
      final alpha = (1.0 - lifeT);
      final tp = TextPainter(
        text: TextSpan(
          text: t.text,
          style: TextStyle(
            color: t.color.withValues(alpha: alpha),
            fontSize: t.fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.4 * alpha),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          t.position - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _drawPortal(Canvas canvas) {
    // Outer pulsing glow
    final glowRadius = _kPortalRadius + 22 + 8 * math.sin(portalPulse * math.pi * 2);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _kPortalGold.withValues(alpha: 0.45),
          _kPortalAmber.withValues(alpha: 0.18),
          _kPortalGold.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: portalCenter, radius: glowRadius));
    canvas.drawCircle(portalCenter, glowRadius, glowPaint);

    // Concentric rings.
    for (int i = 0; i < 3; i++) {
      final r = _kPortalRadius - i * 9 + math.sin(portalPulse * math.pi * 2 + i) * 2;
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = _kPortalGold.withValues(alpha: 0.7 - i * 0.18);
      canvas.drawCircle(portalCenter, r, p);
    }

    // Inner core.
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white, _kPortalGold, _kPortalAmber],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
          Rect.fromCircle(center: portalCenter, radius: _kPortalRadius * 0.5));
    canvas.drawCircle(portalCenter, _kPortalRadius * 0.45, corePaint);
  }

  Color _orbColor(_GameOrb orb) {
    switch (orb.type) {
      case _OrbType.shadow:
        return _kShadowRed;
      case _OrbType.golden:
        return _kGoldenOrb;
      case _OrbType.heal:
        return _kHealOrb;
    }
  }

  void _drawOrb(Canvas canvas, _GameOrb orb) {
    final color = _orbColor(orb);
    final pulse = 0.85 + 0.15 * math.sin(orb.pulse * math.pi * 2);
    final r = orb.radius * pulse;

    // Outer glow
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.55),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: orb.position, radius: r * 2.4));
    canvas.drawCircle(orb.position, r * 2.4, glow);

    // Body
    final body = Paint()
      ..shader = RadialGradient(
        colors: orb.type == _OrbType.shadow
            ? [_kShadowPurple, _kShadowDeep]
            : [Colors.white, color],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: orb.position, radius: r));
    canvas.drawCircle(orb.position, r, body);

    // Ring
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = color.withValues(alpha: 0.9);
    canvas.drawCircle(orb.position, r, ring);

    // Highlight dot
    final hp = Paint()..color = Colors.white.withValues(alpha: 0.55);
    canvas.drawCircle(
      orb.position.translate(-r * 0.3, -r * 0.35),
      r * 0.18,
      hp,
    );
  }

  @override
  bool shouldRepaint(covariant _GamePainter old) => true;
}
