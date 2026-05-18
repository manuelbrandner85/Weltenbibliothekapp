// 🧘 AUDIO-GEFÜHRTER KÖRPERSCAN
//
// 10-Min-Body-Scan-Meditation gesprochen via flutter_tts. Vipassana-Stil:
// Aufmerksamkeit von Füßen zum Kopf wandern, jede Region beobachten ohne zu
// verändern. Mit Atem-Bridges zwischen den Regionen.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AudioBodyScanScreen extends StatefulWidget {
  const AudioBodyScanScreen({super.key});

  @override
  State<AudioBodyScanScreen> createState() => _AudioBodyScanScreenState();
}

class _AudioBodyScanScreenState extends State<AudioBodyScanScreen> {
  static const _bg = Color(0xFF06040F);
  static const _accent = Color(0xFFE91E63);

  late final FlutterTts _tts;
  bool _running = false;
  int _stepIdx = 0;
  Timer? _timer;
  Timer? _countdown;
  int _remainingSec = 0;

  // 20 Schritte × 30 Sek = 10 Min. Jede Region einmal 30s.
  static final List<({String body, String emoji, String script})> _steps = [
    (emoji: '🦶', body: 'Linker Fuß',
        script: 'Lenke deine Aufmerksamkeit zum linken Fuß. Spüre die Sohle, die Zehen, die Ferse. Beobachte einfach, was da ist — Wärme, Druck, Kribbeln oder Stille.'),
    (emoji: '🦶', body: 'Rechter Fuß',
        script: 'Nun zum rechten Fuß. Dieselbe sanfte Aufmerksamkeit. Was bemerkst du, was du sonst übergehst?'),
    (emoji: '🦵', body: 'Linkes Bein',
        script: 'Wandere zum linken Unterschenkel, Knie, Oberschenkel. Lass den Atem durch das ganze Bein fließen. Atme ein in das Bein. Atme aus durch das Bein.'),
    (emoji: '🦵', body: 'Rechtes Bein',
        script: 'Jetzt das rechte Bein. Spüre, wie es auf der Unterlage ruht. Schwer oder leicht? Warm oder kühl?'),
    (emoji: '🪨', body: 'Becken & Hüften',
        script: 'Becken und Hüften. Dieser Bereich speichert oft alte Spannung. Lass den Atem hier länger verweilen.'),
    (emoji: '⬇️', body: 'Unterer Rücken',
        script: 'Der untere Rücken — Lendenwirbelsäule. Beobachte ohne zu beurteilen. Bei jedem Ausatmen: weicher werden.'),
    (emoji: '🫃', body: 'Bauch',
        script: 'Der Bauch — der Sitz vieler Emotionen. Lege wenn nötig eine Hand darauf. Wie hebt und senkt er sich beim Atmen?'),
    (emoji: '🫀', body: 'Brustkorb',
        script: 'Der Brustkorb. Spüre wie er sich beim Einatmen weitet, beim Ausatmen sinkt. Vielleicht das Herz darin schlagen.'),
    (emoji: '⬆️', body: 'Oberer Rücken',
        script: 'Der obere Rücken zwischen den Schulterblättern. Diese Stelle, die du selten siehst, aber die dich täglich trägt.'),
    (emoji: '🧥', body: 'Schultern',
        script: 'Die Schultern. Lass sie sinken, ein paar Zentimeter tiefer. Was haben sie heute alles getragen?'),
    (emoji: '💪', body: 'Linker Arm',
        script: 'Der linke Arm. Vom Oberarm über den Ellbogen, Unterarm, bis zur Hand.'),
    (emoji: '💪', body: 'Rechter Arm',
        script: 'Der rechte Arm. Spüre die Finger einzeln nacheinander. Kribbelt etwas? Pulsiert etwas?'),
    (emoji: '🫶', body: 'Hände',
        script: 'Beide Hände gleichzeitig. Die Werkzeuge des Tages. Lass sie schwer werden.'),
    (emoji: '🧠', body: 'Nacken',
        script: 'Der Nacken — die Brücke zwischen Kopf und Körper. Lass den Kiefer locker werden, die Zunge hinter den Zähnen ruhen.'),
    (emoji: '😶', body: 'Gesicht',
        script: 'Das Gesicht. Lass die Stirn glatt werden, die Augenlider schwer, die Wangen weich.'),
    (emoji: '👁️', body: 'Augen',
        script: 'Die Augen, hinter den geschlossenen Lidern. Lass die Augäpfel sanft in den Höhlen ruhen.'),
    (emoji: '🧠', body: 'Kopf & Stirn',
        script: 'Die Stirn, die Schläfen, der ganze Schädel. Beobachte ob Gedanken auftauchen — lass sie ziehen wie Wolken.'),
    (emoji: '👑', body: 'Kopfkrone',
        script: 'Der Scheitel, die Krone. Stell dir vor, ein sanftes Licht strömt von oben in den Körper hinein.'),
    (emoji: '🌟', body: 'Ganzer Körper',
        script: 'Spüre nun den ganzen Körper auf einmal. Als ein einziges atmendes Wesen. Jede Zelle.'),
    (emoji: '🙏', body: 'Abschluss',
        script: 'Bedanke dich bei deinem Körper, der dich heute getragen hat. Bewege langsam Finger und Zehen. Öffne wenn bereit die Augen.'),
  ];

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _setupTts();
  }

  Future<void> _setupTts() async {
    await _tts.setLanguage('de-DE');
    await _tts.setSpeechRate(0.42); // langsamer für Meditation
    await _tts.setPitch(0.92);
    await _tts.setVolume(0.9);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tts.stop();
    super.dispose();
  }

  Future<void> _start() async {
    if (_running) return;
    setState(() {
      _running = true;
      _stepIdx = 0;
    });
    await _speakStep();
    _scheduleNext();
  }

  Future<void> _speakStep() async {
    if (!_running || _stepIdx >= _steps.length) return;
    final s = _steps[_stepIdx];
    await _tts.speak(s.script);
  }

  void _scheduleNext() {
    _timer?.cancel();
    _countdown?.cancel();
    const total = 30;
    setState(() => _remainingSec = total);
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || !_running) {
        t.cancel();
        return;
      }
      setState(() => _remainingSec = (_remainingSec - 1).clamp(0, total));
    });
    _timer = Timer(const Duration(seconds: total), () async {
      if (!_running) return;
      await _advance();
    });
  }

  Future<void> _advance() async {
    _timer?.cancel();
    _countdown?.cancel();
    if (_stepIdx >= _steps.length - 1) {
      await _stop(completed: true);
      return;
    }
    setState(() => _stepIdx++);
    await _speakStep();
    _scheduleNext();
  }

  Future<void> _stop({bool completed = false}) async {
    _timer?.cancel();
    _countdown?.cancel();
    await _tts.stop();
    if (!mounted) return;
    setState(() {
      _running = false;
      _remainingSec = 0;
      if (completed) _stepIdx = _steps.length - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = _steps[_stepIdx];
    final progress = (_stepIdx + 1) / _steps.length;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _accent,
        title: const Row(children: [
          Text('🧘', style: TextStyle(fontSize: 22)),
          SizedBox(width: 10),
          Text('Audio-Körperscan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Aktueller Schritt
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(s.emoji, style: const TextStyle(fontSize: 96)),
                      const SizedBox(height: 18),
                      Text(s.body,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('Schritt ${_stepIdx + 1} von ${_steps.length}',
                            style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(s.script,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6, fontStyle: FontStyle.italic)),
                      ),
                    ],
                  ),
                ),
              ),
              if (_running && _remainingSec > 0 && _stepIdx < _steps.length - 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Nächste Region in ${_remainingSec}s',
                    style: TextStyle(
                      color: _accent.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation(_accent),
                ),
              ),
              const SizedBox(height: 14),
              if (_running)
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        onPressed: () => _stop(),
                        icon: const Icon(Icons.stop, color: Colors.white),
                        label: const Text('Stoppen', style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _stepIdx < _steps.length - 1
                            ? _advance
                            : () => _stop(completed: true),
                        icon: Icon(_stepIdx < _steps.length - 1
                            ? Icons.arrow_forward
                            : Icons.check),
                        label: Text(
                          _stepIdx < _steps.length - 1
                              ? 'Weiter →'
                              : 'Abschließen',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _start,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Körperscan starten',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              const Text(
                'Sprache: Deutsch (TTS) · 10 Min · 20 Körperregionen · Vipassana-Stil',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
