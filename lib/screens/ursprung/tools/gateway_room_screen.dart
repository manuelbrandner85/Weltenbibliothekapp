import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 🚪 Gateway-Kammer — CIA Hemi-Sync Meditation Trainer
///
/// User wählt Focus Level (10/12/15/21) und Dauer (15/30/45 min).
/// Visualisierung pulsiert im Theta/Delta-Takt, optional binauraler Beat.
/// Session wird in `ursprung_gateway_sessions` geloggt.
class GatewayRoomScreen extends StatefulWidget {
  const GatewayRoomScreen({super.key});

  @override
  State<GatewayRoomScreen> createState() => _GatewayRoomScreenState();
}

class _GatewayRoomScreenState extends State<GatewayRoomScreen>
    with SingleTickerProviderStateMixin {
  static const _cyan = Color(0xFF00D4AA);
  static const _cyanAccent = Color(0xFF00FFD4);
  static const _bgDeep = Color(0xFF050510);

  final List<_FocusLevel> _levels = const [
    _FocusLevel(
      'Focus 10',
      'Mind Awake / Body Asleep',
      'Tiefe körperliche Entspannung bei wachem Geist. Tor zur erweiterten Wahrnehmung.',
      4.0,
      Color(0xFF8A2BE2),
    ),
    _FocusLevel(
      'Focus 12',
      'Expanded Awareness',
      'Erweiterung über physische Sinne hinaus. Frequenz-Programmierung wird möglich.',
      7.83,
      Color(0xFF00D4AA),
    ),
    _FocusLevel(
      'Focus 15',
      'No Time',
      'Zustand jenseits der Zeit. Zugang zu Vergangenheit und Zukunft.',
      6.0,
      Color(0xFFFFD700),
    ),
    _FocusLevel(
      'Focus 21',
      'Other Energy Systems',
      'Brücke zu nicht-physischen Bewusstseinsdimensionen.',
      4.5,
      Color(0xFFFF4081),
    ),
  ];

  int _selectedLevelIdx = 1;
  int _durationMinutes = 15;
  bool _isRunning = false;
  int _elapsedSeconds = 0;
  Timer? _timer;
  late final AnimationController _pulseController;
  final AudioPlayer _player = AudioPlayer();
  bool _audioOn = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    if (_audioOn) {
      await _player.stop();
      setState(() => _audioOn = false);
    } else {
      // We do not bundle binaural audio files; the toggle simulates the cue.
      // A future build may load a binaural tone matching the focus frequency.
      await _player.setReleaseMode(ReleaseMode.loop);
      setState(() => _audioOn = true);
    }
  }

  void _start() {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
      _elapsedSeconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
      if (_elapsedSeconds >= _durationMinutes * 60) {
        _finish();
      }
    });
  }

  Future<void> _stop() async {
    _timer?.cancel();
    if (_audioOn) await _player.stop();
    setState(() {
      _isRunning = false;
      _audioOn = false;
    });
  }

  Future<void> _finish() async {
    _timer?.cancel();
    final level = _levels[_selectedLevelIdx];
    final actualMinutes = (_elapsedSeconds / 60).round();
    setState(() {
      _isRunning = false;
      _audioOn = false;
    });
    if (_audioOn) await _player.stop();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('ursprung_gateway_sessions').insert({
          'user_id': user.id,
          'focus_level_reached': level.name,
          'duration_minutes': actualMinutes,
          'notes': null,
        });
      }
    } catch (_) {
      // Non-fatal: offline mode allowed
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _cyan.withValues(alpha: 0.9),
        content: Text(
          'Gateway-Session abgeschlossen: ${level.name} · $actualMinutes min',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final level = _levels[_selectedLevelIdx];
    final progress = _isRunning ? _elapsedSeconds / (_durationMinutes * 60) : 0.0;

    return Scaffold(
      backgroundColor: _bgDeep,
      appBar: AppBar(
        backgroundColor: _bgDeep,
        elevation: 0,
        iconTheme: const IconThemeData(color: _cyan),
        title: const Text(
          'Gateway-Kammer',
          style: TextStyle(color: _cyan, letterSpacing: 2.0, fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pulsing focus visual
              SizedBox(
                height: 220,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, __) {
                      final t = _pulseController.value;
                      final size = 140.0 + 40.0 * t;
                      return Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              level.color.withValues(alpha: 0.45),
                              level.color.withValues(alpha: 0.10),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: level.color.withValues(alpha: 0.5),
                              blurRadius: 60,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${level.frequencyHz.toStringAsFixed(2)} Hz',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                level.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  letterSpacing: 4.0,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                level.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: _cyan, fontSize: 12, letterSpacing: 1.5),
              ),
              const SizedBox(height: 12),
              Text(
                level.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              if (!_isRunning) ...[
                _sectionLabel('FOCUS LEVEL'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_levels.length, (i) {
                    final isSel = i == _selectedLevelIdx;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedLevelIdx = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSel
                              ? _levels[i].color.withValues(alpha: 0.18)
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSel
                                ? _levels[i].color
                                : Colors.white.withValues(alpha: 0.10),
                          ),
                        ),
                        child: Text(
                          _levels[i].name,
                          style: TextStyle(
                            color: isSel ? _levels[i].color : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                _sectionLabel('DAUER'),
                const SizedBox(height: 8),
                Row(
                  children: [15, 30, 45].map((m) {
                    final isSel = m == _durationMinutes;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () => setState(() => _durationMinutes = m),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? _cyan.withValues(alpha: 0.18)
                                  : Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSel
                                    ? _cyan
                                    : Colors.white.withValues(alpha: 0.10),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$m min',
                                style: TextStyle(
                                  color: isSel ? _cyan : Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
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
                    'GATEWAY ÖFFNEN',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3.0,
                    ),
                  ),
                ),
              ] else ...[
                // Running state
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    valueColor: AlwaysStoppedAnimation(level.color),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    '${_fmt(_elapsedSeconds)} / ${_fmt(_durationMinutes * 60)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 3.0,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _toggleAudio,
                        icon: Icon(
                          _audioOn ? Icons.volume_up : Icons.volume_off,
                          color: _cyan,
                        ),
                        label: Text(
                          _audioOn ? 'Audio AN' : 'Audio AUS',
                          style: const TextStyle(color: _cyan),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: _cyan.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _stop,
                        icon: const Icon(Icons.stop),
                        label: const Text('STOP'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withValues(
                            alpha: 0.8,
                          ),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String s) => Text(
    s,
    style: TextStyle(
      color: _cyanAccent.withValues(alpha: 0.7),
      fontSize: 10,
      letterSpacing: 3.0,
      fontWeight: FontWeight.w700,
    ),
  );

  String _fmt(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }
}

class _FocusLevel {
  final String name;
  final String subtitle;
  final String description;
  final double frequencyHz;
  final Color color;

  const _FocusLevel(
    this.name,
    this.subtitle,
    this.description,
    this.frequencyHz,
    this.color,
  );
}
