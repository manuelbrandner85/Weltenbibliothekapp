import 'dart:async';
import 'package:flutter/material.dart';

/// Atemmeister -- HeartMath / CIA Resonant Tuning Breathing
///
/// 4 Techniken:
///   - Resonant Tuning -- 5 s ein / 5 s aus (Kohärenz-Atmung)
///   - Coherent Breathing -- 6 s / 6 s
///   - Energy Gathering -- 4 s ein / 4 s halten / 8 s aus
///   - Click-Out -- 7 s ein / 4 s halten / 8 s aus
class BreathmasterScreen extends StatefulWidget {
  const BreathmasterScreen({super.key});

  @override
  State<BreathmasterScreen> createState() => _BreathmasterScreenState();
}

class _BreathmasterScreenState extends State<BreathmasterScreen>
    with SingleTickerProviderStateMixin {
  static const _cyan = Color(0xFF00D4AA);
  static const _bgDeep = Color(0xFF050510);

  final List<_BreathPattern> _patterns = const [
    _BreathPattern(
      'Resonant Tuning',
      'CIA-Standard · 5s/5s',
      [_BreathStep('Einatmen', 5), _BreathStep('Ausatmen', 5)],
      Color(0xFF00D4AA),
    ),
    _BreathPattern(
      'Coherent Breathing',
      '6s ein / 6s aus',
      [_BreathStep('Einatmen', 6), _BreathStep('Ausatmen', 6)],
      Color(0xFF00BCD4),
    ),
    _BreathPattern(
      'Energy Gathering',
      '4-4-8 · Energie sammeln',
      [
        _BreathStep('Einatmen', 4),
        _BreathStep('Halten', 4),
        _BreathStep('Ausatmen', 8),
      ],
      Color(0xFFFFD700),
    ),
    _BreathPattern(
      'Click-Out',
      '7-4-8 · Tiefe Trance',
      [
        _BreathStep('Einatmen', 7),
        _BreathStep('Halten', 4),
        _BreathStep('Ausatmen', 8),
      ],
      Color(0xFF8A2BE2),
    ),
  ];

  int _patternIdx = 0;
  bool _running = false;
  int _stepIdx = 0;
  int _stepRemaining = 0;
  int _cycleCount = 0;
  Timer? _timer;
  late final AnimationController _scaleCtrl;

  // Session-Tracking fuer Abschluss-Statistik (U3)
  DateTime? _sessionStartedAt;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _start() {
    final pattern = _patterns[_patternIdx];
    setState(() {
      _running = true;
      _stepIdx = 0;
      _cycleCount = 0;
      _stepRemaining = pattern.steps[0].seconds;
      _sessionStartedAt = DateTime.now();
    });
    _animateStep();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _stepRemaining--);
      if (_stepRemaining <= 0) _advance();
    });
  }

  void _animateStep() {
    final pattern = _patterns[_patternIdx];
    final step = pattern.steps[_stepIdx];
    _scaleCtrl.duration = Duration(seconds: step.seconds);
    _scaleCtrl.reset();
    if (step.label == 'Einatmen') {
      _scaleCtrl.forward();
    } else if (step.label == 'Ausatmen') {
      _scaleCtrl.value = 1.0;
      _scaleCtrl.reverse();
    } else {
      _scaleCtrl.value = 1.0;
    }
  }

  void _advance() {
    final pattern = _patterns[_patternIdx];
    final nextIdx = (_stepIdx + 1) % pattern.steps.length;
    setState(() {
      if (nextIdx == 0) _cycleCount++;
      _stepIdx = nextIdx;
      _stepRemaining = pattern.steps[nextIdx].seconds;
    });
    _animateStep();
  }

  void _stop() {
    _timer?.cancel();
    _scaleCtrl.stop();
    final pattern = _patterns[_patternIdx];
    final cycles = _cycleCount;
    final start = _sessionStartedAt;
    final durationSec =
        start != null ? DateTime.now().difference(start).inSeconds : 0;
    setState(() => _running = false);
    // U3: Abschluss-Statistik anzeigen (nur bei nennenswerter Session)
    if (durationSec >= 5) {
      _showSummary(pattern, cycles, durationSec);
    }
  }

  void _showSummary(_BreathPattern pattern, int cycles, int durationSec) {
    final mins = durationSec ~/ 60;
    final secs = durationSec % 60;
    final durLabel = mins > 0 ? '$mins min $secs s' : '$secs s';
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF080818),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Icon(Icons.spa_rounded, color: pattern.color, size: 40),
            const SizedBox(height: 12),
            const Text(
              'Atem-Session abgeschlossen',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _summaryStat('$cycles', 'Zyklen', pattern.color),
                _summaryStat(durLabel, 'Dauer', pattern.color),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: pattern.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                pattern.name,
                style: TextStyle(
                  color: pattern.color,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: pattern.color,
                  foregroundColor: _bgDeep,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Schliessen',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 26,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pattern = _patterns[_patternIdx];
    final step = _running ? pattern.steps[_stepIdx] : null;

    return Scaffold(
      backgroundColor: _bgDeep,
      appBar: AppBar(
        backgroundColor: _bgDeep,
        elevation: 0,
        iconTheme: const IconThemeData(color: _cyan),
        title: const Text(
          'Atemmeister',
          style: TextStyle(color: _cyan, letterSpacing: 2.0, fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _scaleCtrl,
                    builder: (_, __) {
                      final scale =
                          _running ? (0.55 + 0.45 * _scaleCtrl.value) : 0.7;
                      return Container(
                        width: 240 * scale,
                        height: 240 * scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              pattern.color.withValues(alpha: 0.45),
                              pattern.color.withValues(alpha: 0.10),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: pattern.color.withValues(alpha: 0.4),
                              blurRadius: 60,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                step?.label ?? 'BEREIT',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  letterSpacing: 3.0,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              if (_running) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '$_stepRemaining',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.w200,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (_running) ...[
                Text(
                  'Zyklus $_cycleCount',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _stop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'STOP',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3.0,
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'TECHNIK',
                  style: TextStyle(
                    color: _cyan.withValues(alpha: 0.7),
                    letterSpacing: 3.0,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(_patterns.length, (i) {
                  final p = _patterns[i];
                  final isSel = i == _patternIdx;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _patternIdx = i),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSel
                              ? p.color.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSel
                                ? p.color
                                : Colors.white.withValues(alpha: 0.10),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: p.color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: TextStyle(
                                      color: isSel ? p.color : Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    p.subtitle,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.5),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _start,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cyan,
                    foregroundColor: _bgDeep,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'STARTE ATMUNG',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3.0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BreathStep {
  final String label;
  final int seconds;
  const _BreathStep(this.label, this.seconds);
}

class _BreathPattern {
  final String name;
  final String subtitle;
  final List<_BreathStep> steps;
  final Color color;
  const _BreathPattern(this.name, this.subtitle, this.steps, this.color);
}
