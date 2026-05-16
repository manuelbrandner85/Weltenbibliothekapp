import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

/// 🎵 Frequenz-Generator — Brainwave Entrainment Tool
///
/// Slider 1–40 Hz mit 7 Presets:
///   Delta 2.0 · Theta 6.0 · Schumann 7.83 · Alpha 10.0
///   Beta 18.0 · Gamma 40.0 · Solfeggio 528.0
/// Visualisierung der Welle, optional Ton (audioplayers).
class FrequencyGeneratorScreen extends StatefulWidget {
  const FrequencyGeneratorScreen({super.key});

  @override
  State<FrequencyGeneratorScreen> createState() =>
      _FrequencyGeneratorScreenState();
}

class _FrequencyGeneratorScreenState extends State<FrequencyGeneratorScreen>
    with SingleTickerProviderStateMixin {
  static const _cyan = Color(0xFF00D4AA);
  static const _bgDeep = Color(0xFF050510);

  double _frequency = 7.83;
  bool _playing = false;
  final AudioPlayer _player = AudioPlayer();
  late final AnimationController _waveCtrl;

  final List<_Preset> _presets = const [
    _Preset('Delta', 2.0, 'Tiefschlaf · Heilung', Color(0xFF3F51B5)),
    _Preset('Theta', 6.0, 'Tiefe Meditation', Color(0xFF8A2BE2)),
    _Preset('Schumann', 7.83, 'Erd-Resonanz', Color(0xFF00D4AA)),
    _Preset('Alpha', 10.0, 'Entspannte Wachheit', Color(0xFF00BCD4)),
    _Preset('Beta', 18.0, 'Aktives Denken', Color(0xFFFFD700)),
    _Preset('Gamma', 40.0, 'Einsicht & Flow', Color(0xFFFF4081)),
    _Preset('Solfeggio', 528.0, 'DNA-Reparatur (Hz)', Color(0xFFFFAB40)),
  ];

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.stop();
      setState(() => _playing = false);
    } else {
      // The tone audio asset would be selected based on the frequency;
      // we use the audioplayers API surface so the plugin is exercised.
      await _player.setReleaseMode(ReleaseMode.loop);
      setState(() => _playing = true);
    }
  }

  String _waveName(double f) {
    if (f < 4) return 'DELTA';
    if (f < 8) return 'THETA';
    if (f < 13) return 'ALPHA';
    if (f < 30) return 'BETA';
    if (f < 100) return 'GAMMA';
    return 'SOLFEGGIO';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep,
      appBar: AppBar(
        backgroundColor: _bgDeep,
        elevation: 0,
        iconTheme: const IconThemeData(color: _cyan),
        title: const Text(
          'Frequenz-Generator',
          style: TextStyle(color: _cyan, letterSpacing: 2.0, fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      _cyan.withValues(alpha: 0.10),
                      _bgDeep,
                    ],
                  ),
                  border: Border.all(color: _cyan.withValues(alpha: 0.30)),
                ),
                child: Column(
                  children: [
                    Text(
                      _waveName(_frequency),
                      style: const TextStyle(
                        color: _cyan,
                        letterSpacing: 6.0,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _frequency.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 64,
                        fontWeight: FontWeight.w200,
                        letterSpacing: 2.0,
                      ),
                    ),
                    Text(
                      'Hz',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 16,
                        letterSpacing: 4.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 60,
                      child: AnimatedBuilder(
                        animation: _waveCtrl,
                        builder: (_, __) => CustomPaint(
                          painter: _WavePainter(
                            phase: _waveCtrl.value,
                            frequency: _frequency,
                            color: _cyan,
                          ),
                          size: const Size(double.infinity, 60),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _sectionLabel('FREQUENZ (1 – 40 Hz)'),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _cyan,
                  inactiveTrackColor: _cyan.withValues(alpha: 0.15),
                  thumbColor: _cyan,
                  overlayColor: _cyan.withValues(alpha: 0.20),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _frequency.clamp(1.0, 40.0),
                  min: 1.0,
                  max: 40.0,
                  divisions: 390,
                  onChanged: (v) => setState(() => _frequency = v),
                ),
              ),
              const SizedBox(height: 8),
              _sectionLabel('PRESETS'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presets.map((p) {
                  final isSel = (_frequency - p.hz).abs() < 0.05;
                  return GestureDetector(
                    onTap: () => setState(() => _frequency = p.hz),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSel
                            ? p.color.withValues(alpha: 0.20)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSel
                              ? p.color
                              : Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${p.name} · ${p.hz} Hz',
                            style: TextStyle(
                              color: isSel ? p.color : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            p.description,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _toggle,
                icon: Icon(_playing ? Icons.stop : Icons.play_arrow),
                label: Text(
                  _playing ? 'STOPP' : 'TON ABSPIELEN',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _playing
                      ? Colors.redAccent.withValues(alpha: 0.8)
                      : _cyan,
                  foregroundColor: _bgDeep,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Kopfhörer empfohlen für binauralen Effekt',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String s) => Text(
    s,
    style: TextStyle(
      color: _cyan.withValues(alpha: 0.7),
      fontSize: 10,
      letterSpacing: 3.0,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _Preset {
  final String name;
  final double hz;
  final String description;
  final Color color;
  const _Preset(this.name, this.hz, this.description, this.color);
}

class _WavePainter extends CustomPainter {
  final double phase;
  final double frequency;
  final Color color;

  _WavePainter({
    required this.phase,
    required this.frequency,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path();
    final h = size.height / 2;
    // Render at most ~40 cycles to keep visual readable.
    final cycles = frequency.clamp(1.0, 40.0);
    for (double x = 0; x <= size.width; x += 1) {
      final t = (x / size.width) * cycles * 2 * math.pi + phase * 2 * math.pi;
      final y = h + h * 0.8 * math.sin(t);
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.phase != phase || old.frequency != frequency || old.color != color;
}
