// 🔢 NUMEROLOGIE-REALTIME - Live-Anzeige der aktuellen Tages/Stunden/Minuten-Zahl
//
// Zeigt durchgehend (1Hz-Update): Tages-Quersumme, Stunden-Zahl, Minuten-Zahl,
// kombinierte Master-Zahl, plus AI-Deutung der aktuellen Konstellation.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_ambient_particles.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/cinematic/wb_vignette.dart';

class NumerologieRealtimeScreen extends StatefulWidget {
  const NumerologieRealtimeScreen({super.key});

  @override
  State<NumerologieRealtimeScreen> createState() => _NumerologieRealtimeScreenState();
}

class _NumerologieRealtimeScreenState extends State<NumerologieRealtimeScreen>
    with TickerProviderStateMixin {
  static const Color _bg = Color(0xFF080313);
  static const Color _primary = Color(0xFFAB47BC);
  static const Color _gold = Color(0xFFFFD54F);

  Timer? _tickTimer;
  DateTime _now = DateTime.now();
  late final AnimationController _glowCtrl;
  late final AnimationController _ambientCtrl;

  static const _meanings = {
    1: 'Aufbruch · Pionier · Wille',
    2: 'Dualität · Wahl · Spiegel',
    3: 'Ausdruck · Schöpfung · Trinität',
    4: 'Struktur · Fundament · Erde',
    5: 'Wandel · Freiheit · Pulse',
    6: 'Harmonie · Pflege · Liebe',
    7: 'Mystik · Innenschau · Geheimnis',
    8: 'Macht · Manifestation · Karma',
    9: 'Vollendung · Loslassen · Universum',
    11: 'Meister-Inspiration · Tor zwischen Welten',
    22: 'Meister-Bauer · Vision wird konkret',
    33: 'Meister-Lehrer · Mitgefühls-Avatar',
  };

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _ambientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _glowCtrl.dispose();
    _ambientCtrl.dispose();
    super.dispose();
  }

  int _digitSum(int n) {
    int s = n.abs();
    while (s > 9 && s != 11 && s != 22 && s != 33) {
      s = s.toString().split('').map(int.parse).reduce((a, b) => a + b);
    }
    return s;
  }

  String _meaning(int n) => _meanings[n] ?? '—';

  @override
  Widget build(BuildContext context) {
    final dateNum = _digitSum(_now.year + _now.month + _now.day);
    final hourNum = _digitSum(_now.hour == 0 ? 24 : _now.hour);
    final minuteNum = _digitSum(_now.minute == 0 ? 60 : _now.minute);
    final masterNum = _digitSum(dateNum + hourNum + minuteNum);

    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        world: WBWorld.neutral,
        titleWidget: ShaderMask(
          shaderCallback: (r) => const LinearGradient(colors: [_gold, _primary]).createShader(r),
          child: const Text('HEUTE IN ZAHLEN',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 3)),
        ),
      ),
      body: Stack(fit: StackFit.expand, children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center, radius: 1.5,
              colors: [Color(0x554A148C), Color(0x331A0B33), _bg],
            ),
          ),
        ),
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _ambientCtrl,
            builder: (_, __) => CustomPaint(
              painter: _NumOrbsPainter(_ambientCtrl.value),
              size: Size.infinite,
            ),
          ),
        ),
        const IgnorePointer(child: WBAmbientParticles(world: WBWorld.neutral, count: 40)),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
            child: Column(children: [
              // Master-Zahl prominent
              AnimatedBuilder(
                animation: _glowCtrl,
                builder: (_, __) => Container(
                  width: 180, height: 180,
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      _gold.withValues(alpha: 0.3 + 0.15 * _glowCtrl.value),
                      _primary.withValues(alpha: 0.18),
                      Colors.transparent,
                    ]),
                  ),
                  child: Center(
                    child: ShaderMask(
                      shaderCallback: (r) => const LinearGradient(colors: [_gold, _primary]).createShader(r),
                      child: Text(
                        '$masterNum',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 100,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Text('JETZT',
                  style: TextStyle(
                      color: _gold.withValues(alpha: 0.8), fontSize: 11, letterSpacing: 4, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(_meaning(masterNum),
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),

              const SizedBox(height: 26),
              // Drei Komponenten
              _component('📅 TAG', dateNum, '${_now.day}.${_now.month}.${_now.year}'),
              const SizedBox(height: 8),
              _component('🕐 STUNDE', hourNum, '${_now.hour.toString().padLeft(2, '0')} Uhr'),
              const SizedBox(height: 8),
              _component('⏱️ MINUTE', minuteNum, '${_now.minute.toString().padLeft(2, '0')}\''),

              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('ENERGIE-DEUTUNG',
                          style: TextStyle(color: _gold, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(_interpretation(dateNum, hourNum, minuteNum, masterNum),
                          style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.6)),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ),
        const IgnorePointer(child: WBVignette()),
      ]),
    );
  }

  Widget _component(String label, int num, String detail) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primary.withValues(alpha: 0.25),
                border: Border.all(color: _primary.withValues(alpha: 0.6)),
              ),
              child: Center(
                child: Text('$num',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label,
                    style: const TextStyle(color: _gold, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(detail, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                Text(_meaning(num),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _interpretation(int day, int hour, int min, int master) {
    final dayE = _meaning(day);
    final hourE = _meaning(hour);
    final masterE = _meaning(master);
    return 'Das Energiefeld dieses Augenblicks vibriert auf der Master-Zahl $master '
        '($masterE). Über die Stunde wirkt $hourE, der Tag trägt die Schwingung von $dayE. '
        'Auch die Minute $min steuert subtil bei. '
        'Nutze diesen Moment bewusst — die Konstellation kehrt nicht identisch zurück.';
  }
}

class _NumOrbsPainter extends CustomPainter {
  final double t;
  _NumOrbsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    _draw(canvas, Offset(size.width * 0.2, size.height * (0.3 + math.sin(t * 2 * math.pi) * 0.05)),
        100, const Color(0xFFAB47BC));
    _draw(canvas, Offset(size.width * 0.85, size.height * (0.55 + math.cos(t * 2 * math.pi) * 0.04)),
        90, const Color(0xFFFFD54F));
    _draw(canvas, Offset(size.width * 0.5, size.height * (0.92 + math.sin(t * math.pi) * 0.03)),
        70, const Color(0xFF7C4DFF));
  }

  void _draw(Canvas canvas, Offset c, double r, Color color) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5);
    canvas.drawCircle(c, r, p);
  }

  @override
  bool shouldRepaint(_NumOrbsPainter old) => old.t != t;
}
