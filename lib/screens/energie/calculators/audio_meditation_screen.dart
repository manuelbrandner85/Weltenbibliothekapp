// 🧘 GEFÜHRTE AUDIO-MEDITATIONEN (TTS)
//
// 5 Themen × 5-15 Min via flutter_tts:
// 1. Atem-Bewusstheit (Anapanasati)
// 2. Loving-Kindness (Metta)
// 3. Berg-Meditation (Stabilität)
// 4. Vergebung
// 5. Dankbarkeit

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AudioMeditationScreen extends StatefulWidget {
  const AudioMeditationScreen({super.key});

  @override
  State<AudioMeditationScreen> createState() => _AudioMeditationScreenState();
}

class _AudioMeditationScreenState extends State<AudioMeditationScreen> {
  static const _bg = Color(0xFF06040F);
  static const _accent = Color(0xFF4527A0);

  static final List<({String emoji, String title, String duration, int stepDurationSec, List<String> script})> _meditations = [
    (
      emoji: '🌬️', title: 'Atem-Bewusstheit', duration: '7 Min',
      stepDurationSec: 60,
      script: [
        'Setze dich aufrecht hin. Schließe sanft die Augen. Bringe deine Aufmerksamkeit zum natürlichen Atem.',
        'Beobachte einfach. Steuere nicht. Wo spürst du den Atem am deutlichsten? Nase, Brust, Bauch?',
        'Wenn Gedanken auftauchen, sieh sie wie Wolken am Himmel. Kehre sanft zum Atem zurück.',
        'Beim Einatmen sagst du innerlich: ICH ATME EIN. Beim Ausatmen: ICH ATME AUS.',
        'Vertiefe nun den Ausatem um 2 Sekunden. Aktiviere den Vagusnerv.',
        'Lass die Worte los. Nur noch der Atem selbst.',
        'Komme zurück. Bewege Finger und Zehen. Öffne wenn bereit die Augen.',
      ],
    ),
    (
      emoji: '💞', title: 'Loving-Kindness (Metta)', duration: '8 Min',
      stepDurationSec: 90,
      script: [
        'Bring eine Hand auf dein Herz. Spüre die Wärme. Wiederhole innerlich: Möge ich glücklich sein. Möge ich gesund sein. Möge ich in Frieden sein.',
        'Bring nun eine geliebte Person ins Bewusstsein. Sende ihr dieselben Wünsche: Mögest du glücklich sein. Mögest du gesund sein. Mögest du in Frieden sein.',
        'Wähle eine neutrale Person — jemand, den du nur oberflächlich kennst. Auch ihr: Mögest du glücklich sein. Gesund. In Frieden.',
        'Nun jemand Schwieriger. Jemand, mit dem du im Konflikt bist. Wenn es schwer fällt, atme tiefer. Versuche es trotzdem: Mögest auch du glücklich sein.',
        'Erweitere zu allen Wesen. Möge alles, was atmet, glücklich sein. Möge jeder Mensch sicher sein.',
        'Komme zurück zu dir. Spüre deinen Herzraum. Ruhe darin.',
      ],
    ),
    (
      emoji: '⛰️', title: 'Berg-Meditation', duration: '6 Min',
      stepDurationSec: 60,
      script: [
        'Setze dich aufrecht. Stell dir vor, du bist ein Berg. Massiv, alt, stabil.',
        'Deine Basis ist breit, tief in die Erde verwurzelt. Nichts erschüttert sie.',
        'An deinen Hängen wechseln Jahreszeiten. Wolken ziehen, manchmal Sturm. Der Berg bleibt.',
        'Auch in dir ziehen Stimmungen und Gedanken vorüber wie Wetter. Du bist nicht das Wetter — du bist der Berg.',
        'Komme zurück zur natürlichen Sitzhaltung. Trage diese Stabilität in den Tag.',
      ],
    ),
    (
      emoji: '🕊️', title: 'Vergebung', duration: '10 Min',
      stepDurationSec: 90,
      script: [
        'Atme tief ein und aus. Bring eine Person ins Bewusstsein, der du dich gerade nicht öffnen kannst.',
        'Erinnere dich an die konkrete Situation. Spüre deinen Körper — wo verkrampft er sich?',
        'Sage innerlich: Ich erkenne den Schmerz an. Ich ehre, was ich gefühlt habe.',
        'Sage nun: Festhalten kostet mich Energie. Ich darf die Last loslassen — nicht für sie, für mich.',
        'Wiederhole: Ich vergebe dir nicht, weil du es verdienst. Ich vergebe, weil ich Frieden verdiene.',
        'Atme den Knoten aus. Stell dir vor, ein Faden zwischen euch löst sich sanft.',
        'Komme zurück. Bewege dich. Trinke Wasser. Die Arbeit ist getan.',
      ],
    ),
    (
      emoji: '🙏', title: 'Dankbarkeit', duration: '5 Min',
      stepDurationSec: 60,
      script: [
        'Bring eine Hand auf dein Herz. Spüre den Schlag.',
        'Nenne innerlich drei Dinge, für die du heute dankbar bist. Spüre wie das Herz darauf reagiert.',
        'Erinnere dich an einen Menschen, der dich kürzlich berührt hat. Sende ihm in Gedanken Dank.',
        'Spüre die Dankbarkeit für deinen eigenen Körper. Für jeden Atemzug. Jede Bewegung, die er heute schaffte.',
        'Atme die Dankbarkeit aus, in den Raum um dich. Komme zurück zur Anwesenheit.',
      ],
    ),
  ];

  late final FlutterTts _tts;
  bool _running = false;
  int _meditationIdx = 0;
  int _stepIdx = 0;
  Timer? _timer;
  Timer? _countdown;
  int _remainingSec = 0;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _setupTts();
  }

  Future<void> _setupTts() async {
    await _tts.setLanguage('de-DE');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(0.95);
    await _tts.setVolume(0.9);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdown?.cancel();
    _tts.stop();
    super.dispose();
  }

  Future<void> _start(int idx) async {
    await _stop();
    setState(() {
      _meditationIdx = idx;
      _stepIdx = 0;
      _running = true;
    });
    await _speakStep();
    _scheduleNext();
  }

  Future<void> _speakStep() async {
    if (!_running) return;
    final med = _meditations[_meditationIdx];
    if (_stepIdx >= med.script.length) return;
    await _tts.speak(med.script[_stepIdx]);
  }

  void _scheduleNext() {
    _timer?.cancel();
    _countdown?.cancel();
    final med = _meditations[_meditationIdx];
    final total = med.stepDurationSec;
    setState(() => _remainingSec = total);
    // Sichtbarer Countdown, damit User weiß dass es weitergeht.
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || !_running) {
        t.cancel();
        return;
      }
      setState(() => _remainingSec = (_remainingSec - 1).clamp(0, total));
    });
    _timer = Timer(Duration(seconds: total), () async {
      if (!_running) return;
      await _advance();
    });
  }

  Future<void> _advance() async {
    _timer?.cancel();
    _countdown?.cancel();
    final med = _meditations[_meditationIdx];
    if (_stepIdx >= med.script.length - 1) {
      await _stop();
      return;
    }
    setState(() => _stepIdx++);
    await _speakStep();
    _scheduleNext();
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _countdown?.cancel();
    await _tts.stop();
    if (!mounted) return;
    setState(() {
      _running = false;
      _remainingSec = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_running) return _buildSession();
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _accent,
        title: const Row(children: [
          Text('🧘', style: TextStyle(fontSize: 22)),
          SizedBox(width: 10),
          Text('Geführte Meditationen',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: _meditations.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_accent, _accent.withValues(alpha: 0.4)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Geleitete Meditationen mit deutscher Stimme (TTS). Setz Kopfhörer auf, '
                'finde eine ruhige Sitzhaltung. Tippe auf eine Meditation um zu starten.',
                style: TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
              ),
            );
          }
          final m = _meditations[i - 1];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1530),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _accent.withValues(alpha: 0.3)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _start(i - 1),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Text(m.emoji, style: const TextStyle(fontSize: 36)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.title,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('${m.duration} · ${m.script.length} Schritte',
                              style: TextStyle(color: _accent.withValues(alpha: 0.9), fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(Icons.play_circle_fill, color: _accent, size: 36),
                  ]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSession() {
    final m = _meditations[_meditationIdx];
    final progress = (_stepIdx + 1) / m.script.length;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _accent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _stop,
        ),
        title: Text(m.title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(m.emoji, style: const TextStyle(fontSize: 80)),
                      const SizedBox(height: 18),
                      Text('Schritt ${_stepIdx + 1} / ${m.script.length}',
                          style: TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(m.script[_stepIdx],
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.7)),
                      ),
                    ],
                  ),
                ),
              ),
              // Sichtbarer Schritt-Countdown
              if (_remainingSec > 0 && _stepIdx < m.script.length - 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Nächster Schritt in ${_remainingSec}s',
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
                  valueColor: AlwaysStoppedAnimation(_accent),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton.icon(
                      onPressed: _stop,
                      icon: const Icon(Icons.stop, color: Colors.white),
                      label: const Text('Beenden', style: TextStyle(color: Colors.white)),
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
                      onPressed: _stepIdx < m.script.length - 1 ? _advance : _stop,
                      icon: Icon(_stepIdx < m.script.length - 1
                          ? Icons.arrow_forward
                          : Icons.check),
                      label: Text(
                        _stepIdx < m.script.length - 1
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
