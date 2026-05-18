// ♾️ COSMIC-RESET-RITUAL - Zeremonieller App-Daten-Reset in 3 Stufen
//
// Vermeidet versehentlichen 1-Klick-Reset durch bewusst gestalteten Flow:
// 1. Was lässt du los? (Text-Eingabe als Intention)
// 2. Was wünschst du dir stattdessen? (Wunsch-Eingabe)
// 3. Loslass-Atmung + 3-Sekunden-Hold-Button → Reset

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_ambient_particles.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/cinematic/wb_vignette.dart';

class CosmicResetRitualScreen extends StatefulWidget {
  const CosmicResetRitualScreen({super.key});

  @override
  State<CosmicResetRitualScreen> createState() => _CosmicResetRitualScreenState();
}

class _CosmicResetRitualScreenState extends State<CosmicResetRitualScreen>
    with TickerProviderStateMixin {
  static const Color _bg = Color(0xFF0A0205);
  static const Color _primary = Color(0xFFE53935);
  static const Color _accent = Color(0xFFFFB300);

  int _step = 0; // 0=intro, 1=release, 2=wish, 3=hold, 4=done
  final _releaseCtrl = TextEditingController();
  final _wishCtrl = TextEditingController();
  bool _holding = false;
  double _holdProgress = 0.0;
  late final AnimationController _holdAnimCtrl;
  late final AnimationController _ambientCtrl;
  late final AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _holdAnimCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..addListener(() {
        setState(() => _holdProgress = _holdAnimCtrl.value);
        if (_holdAnimCtrl.isCompleted) _performReset();
      });
    _ambientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _releaseCtrl.dispose();
    _wishCtrl.dispose();
    _holdAnimCtrl.dispose();
    _ambientCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  Future<void> _performReset() async {
    HapticFeedback.heavyImpact();
    final prefs = await SharedPreferences.getInstance();
    // Reset spirit-tool-specific keys (nicht Auth/Profile)
    final keys = prefs.getKeys().where((k) =>
        k.contains('journal') ||
        k.contains('tarot') ||
        k.contains('runes') ||
        k.contains('akasha') ||
        k.contains('history') ||
        k.contains('streak') ||
        k.contains('biorhythm') ||
        k.contains('transformation') ||
        k.contains('shamanic') ||
        k.contains('photo_progress') ||
        k.contains('mantra_counter') ||
        k.contains('iching') ||
        k.contains('glitch') ||
        k.contains('time_capsule') ||
        k.contains('synchronizit')
    ).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
    if (!mounted) return;
    setState(() => _step = 4);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        world: WBWorld.neutral,
        titleWidget: ShaderMask(
          shaderCallback: (r) => const LinearGradient(colors: [_accent, _primary]).createShader(r),
          child: const Text('COSMIC RESET',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 3)),
        ),
      ),
      body: Stack(fit: StackFit.expand, children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center, radius: 1.6,
              colors: [Color(0x66B71C1C), Color(0x33420C0C), _bg],
            ),
          ),
        ),
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _ambientCtrl,
            builder: (_, __) => CustomPaint(
              painter: _ResetOrbsPainter(_ambientCtrl.value),
              size: Size.infinite,
            ),
          ),
        ),
        const IgnorePointer(child: WBAmbientParticles(world: WBWorld.neutral, count: 40)),
        SafeArea(child: _stepView()),
        const IgnorePointer(child: WBVignette()),
      ]),
    );
  }

  Widget _stepView() {
    switch (_step) {
      case 0: return _intro();
      case 1: return _ask(
        'Was lässt du jetzt los?',
        'Schreib es bewusst auf — Gewohnheit, Erinnerung, alte Daten…',
        _releaseCtrl,
        '🔥', _primary,
        () => setState(() => _step = 2),
      );
      case 2: return _ask(
        'Was wünschst du dir stattdessen?',
        'Was darf entstehen wenn dieser Raum frei wird?',
        _wishCtrl,
        '🌱', _accent,
        () => setState(() => _step = 3),
      );
      case 3: return _holdView();
      case 4: return _done();
      default: return const SizedBox.shrink();
    }
  }

  Widget _intro() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedBuilder(
          animation: _glowCtrl,
          builder: (_, __) => Text('♾️',
              style: TextStyle(
                  fontSize: 100,
                  shadows: [Shadow(color: _accent.withValues(alpha: 0.4 + 0.3 * _glowCtrl.value), blurRadius: 30)])),
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (r) => const LinearGradient(colors: [_accent, _primary]).createShader(r),
          child: const Text('COSMIC RESET',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 4)),
        ),
        const SizedBox(height: 14),
        const Text(
          'Ein zeremonieller Reset deiner Spirit-Tool-Daten:\n'
          'Tarot-Verlauf · Runen · Akasha-Tagebuch · Streaks · Mood-Chart\n'
          'Profile bleiben unverändert.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _primary.withValues(alpha: 0.3)),
          ),
          child: const Row(children: [
            Icon(Icons.warning_amber_rounded, color: _primary, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Dieser Schritt ist nicht rückgängig.\n'
                'Erst ziehen wir Intention, dann wird gelöscht.',
                style: TextStyle(color: Colors.white, fontSize: 11, height: 1.4),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () { HapticFeedback.mediumImpact(); setState(() => _step = 1); },
            icon: const Icon(Icons.local_fire_department_rounded),
            label: const Text('RITUAL BEGINNEN',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Doch nicht', style: TextStyle(color: Colors.white54)),
        ),
      ]),
    );
  }

  Widget _ask(String title, String hint, TextEditingController ctrl, String emoji, Color color, VoidCallback onNext) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(emoji, style: const TextStyle(fontSize: 60)),
        const SizedBox(height: 14),
        Text(title,
            style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(hint,
            style: const TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center),
        const SizedBox(height: 20),
        TextField(
          controller: ctrl,
          maxLines: 4,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: '...',
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color.withValues(alpha: 0.4)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: ctrl.text.trim().isEmpty
                ? null
                : () { HapticFeedback.selectionClick(); onNext(); },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('WEITER',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ),
        ),
      ]),
    );
  }

  Widget _holdView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🌊',
            style: TextStyle(fontSize: 80)),
        const SizedBox(height: 14),
        const Text('HALTE 3 SEKUNDEN',
            style: TextStyle(color: _accent, fontSize: 16, letterSpacing: 3, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        const Text(
          'Atme ein. Atme aus. Drücke und halte.\n'
          'Im Loslassen vollendet sich der Reset.',
          style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTapDown: (_) {
            setState(() => _holding = true);
            HapticFeedback.mediumImpact();
            _holdAnimCtrl.forward();
          },
          onTapUp: (_) {
            setState(() => _holding = false);
            _holdAnimCtrl.reset();
          },
          onTapCancel: () {
            setState(() => _holding = false);
            _holdAnimCtrl.reset();
          },
          child: Container(
            width: 180, height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _primary.withValues(alpha: _holding ? 0.7 : 0.3),
                _primary.withValues(alpha: 0.1),
                Colors.transparent,
              ]),
              border: Border.all(color: _primary, width: _holding ? 3 : 2),
            ),
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 170, height: 170,
                child: CircularProgressIndicator(
                  value: _holdProgress,
                  strokeWidth: 6,
                  color: _accent,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${(_holdProgress * 100).toInt()}%',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                Text(_holding ? 'HALTEN' : 'DRÜCKEN',
                    style: TextStyle(color: _accent, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700)),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _done() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedBuilder(
          animation: _glowCtrl,
          builder: (_, __) => Text('✨',
              style: TextStyle(
                  fontSize: 100,
                  shadows: [Shadow(color: _accent.withValues(alpha: 0.5 + 0.3 * _glowCtrl.value), blurRadius: 30)])),
        ),
        const SizedBox(height: 14),
        ShaderMask(
          shaderCallback: (r) => const LinearGradient(colors: [_accent, _primary]).createShader(r),
          child: const Text('VOLLBRACHT',
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 5)),
        ),
        const SizedBox(height: 16),
        Text(
          'Du hast losgelassen:\n"${_releaseCtrl.text.trim()}"',
          style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        Text(
          'Raum für:\n"${_wishCtrl.text.trim()}"',
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          ),
          child: const Text('ZURÜCK',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ),
      ]),
    );
  }
}

class _ResetOrbsPainter extends CustomPainter {
  final double t;
  _ResetOrbsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    _draw(canvas, Offset(size.width * 0.2, size.height * (0.3 + math.sin(t * 2 * math.pi) * 0.05)),
        110, const Color(0xFFE53935));
    _draw(canvas, Offset(size.width * 0.85, size.height * (0.55 + math.cos(t * 2 * math.pi) * 0.04)),
        100, const Color(0xFFFFB300));
    _draw(canvas, Offset(size.width * 0.5, size.height * (0.92 + math.sin(t * math.pi) * 0.03)),
        75, const Color(0xFFFFD54F));
  }

  void _draw(Canvas canvas, Offset c, double r, Color color) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5);
    canvas.drawCircle(c, r, p);
  }

  @override
  bool shouldRepaint(_ResetOrbsPainter old) => old.t != t;
}
