// ✨ HERMETIK · REALITY-CHECK
//
// User beschreibt eine aktuelle Lebenssituation als Text. Tool fragt
// passende Fragen aus den 7 hermetischen Prinzipien (Kybalion) und
// gibt eine strukturierte Analyse zurück mit der vorherrschenden
// Gesetzmäßigkeit + konkretem Praxis-Vorschlag.

import 'package:flutter/material.dart';

class _HermeticCheck {
  final String prinzip;
  final String emoji;
  final String frage;
  final List<String> antworten;
  final String hinweis;
  const _HermeticCheck({
    required this.prinzip,
    required this.emoji,
    required this.frage,
    required this.antworten,
    required this.hinweis,
  });
}

class HermeticRealityCheckScreen extends StatefulWidget {
  const HermeticRealityCheckScreen({super.key});

  @override
  State<HermeticRealityCheckScreen> createState() =>
      _HermeticRealityCheckScreenState();
}

class _HermeticRealityCheckScreenState
    extends State<HermeticRealityCheckScreen> {
  static const _bg = Color(0xFF06040F);
  static const _surface = Color(0xFF100B1E);
  static const _accent = Color(0xFFFF9800);

  final _situation = TextEditingController();
  final Map<int, int> _answers = {};
  bool _submitted = false;

  static final List<_HermeticCheck> _checks = [
    _HermeticCheck(
      prinzip: 'Mentalismus',
      emoji: '🧠',
      frage: 'Wie oft denkst du an diese Situation pro Tag?',
      antworten: ['Selten', '2-3x', 'Ständig', 'Obsessiv'],
      hinweis:
          'Hohe Frequenz = mentale Verfestigung. Das Außen entsteht aus dem Inneren — '
          'was du oft denkst, manifestiert sich. Beobachte deinen Gedankenstrom als wäre er nicht "du".',
    ),
    _HermeticCheck(
      prinzip: 'Entsprechung',
      emoji: '🔁',
      frage: 'Hattest du in deinem Leben schon ähnliche Situationen?',
      antworten: ['Nie', 'Einmal', '2-3x', 'Immer wieder'],
      hinweis:
          'Wiederholung = Muster. Wie oben, so unten — die äußere Situation '
          'spiegelt ein inneres Thema. Frage: was lebt in mir, das dieses Außen anzieht?',
    ),
    _HermeticCheck(
      prinzip: 'Schwingung',
      emoji: '〰️',
      frage: 'Welche Emotion dominiert wenn du an die Situation denkst?',
      antworten: ['Angst', 'Wut', 'Trauer', 'Ruhe'],
      hinweis:
          'Emotion = Schwingungsfrequenz. Niedrige Frequenzen (Angst/Wut) ziehen ähnliche '
          'Situationen an. Bewege dich aktiv in höhere Frequenz (Atemarbeit, Bewegung, Musik).',
    ),
    _HermeticCheck(
      prinzip: 'Polarität',
      emoji: '⚖️',
      frage: 'Wo siehst du im Aktuellen einen positiven Aspekt?',
      antworten: ['Keinen', 'Schwach', 'Deutlich', 'Beide gleichwertig'],
      hinweis:
          'Wenn du nur eine Seite siehst, fehlt der andere Pol. Heiß und kalt sind '
          'auf gleicher Skala — du kannst dich auf der Skala BEWEGEN, indem du den Gegenpol bewusst denkst.',
    ),
    _HermeticCheck(
      prinzip: 'Rhythmus',
      emoji: '🌊',
      frage: 'In welcher Phase fühlst du dich gerade?',
      antworten: ['Aufstieg', 'Höhepunkt', 'Abstieg', 'Tiefpunkt'],
      hinweis:
          'Alles fließt. Tiefe ist gefolgt von Aufschwung. Forciere nicht, was Reife '
          'braucht. Surfe die Welle, kämpfe nicht gegen sie.',
    ),
    _HermeticCheck(
      prinzip: 'Ursache & Wirkung',
      emoji: '🎯',
      frage:
          'Welche deiner Handlungen vor 3-12 Monaten könnte diese Situation verursacht haben?',
      antworten: [
        'Keine erkennbar',
        'Unklar',
        '1-2 mögliche',
        'Klar erkennbar'
      ],
      hinweis:
          'Jede Wirkung hat ihre Ursache. Was du gesät hast (auch Unbewusstes), erntest '
          'du jetzt. Identifiziere die Wurzel — dort liegt der Hebel für Veränderung.',
    ),
    _HermeticCheck(
      prinzip: 'Geschlecht',
      emoji: '☯️',
      frage:
          'Bist du in der Situation eher aktiv-projizierend oder empfangend-aufnehmend?',
      antworten: [
        'Sehr aktiv',
        'Eher aktiv',
        'Eher empfangend',
        'Sehr empfangend'
      ],
      hinweis:
          'Schöpfung braucht beide Pole. Wenn du nur aktiv bist: erschöpft. Wenn nur '
          'empfangend: gestaut. Frage: welchen Pol nutze ich aktuell weniger?',
    ),
  ];

  void _submit() {
    if (_situation.text.trim().isEmpty || _answers.length < _checks.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Bitte Situation beschreiben und alle 7 Fragen beantworten'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(() => _submitted = true);
  }

  void _reset() {
    setState(() {
      _submitted = false;
      _answers.clear();
      _situation.clear();
    });
  }

  // Liefert die 2 Prinzipien mit höchstem Score (= stärkste Wirkung).
  List<int> _topPrinciples() {
    final scored = <MapEntry<int, int>>[];
    for (final e in _answers.entries) {
      // Score = Antwort-Index 0..3. Score 3 = stärkste hermetische Wirkung.
      scored.add(MapEntry(e.key, e.value));
    }
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(2).map((e) => e.key).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _accent.withValues(alpha: 0.9),
        foregroundColor: Colors.black,
        title: const Row(
          children: [
            Text('✨', style: TextStyle(fontSize: 22)),
            SizedBox(width: 10),
            Text('Reality-Check',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
      ),
      body: _submitted ? _buildResult() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [_accent.withValues(alpha: 0.35), _surface]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _accent.withValues(alpha: 0.4)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hermetische Reality-Check',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                'Beschreibe eine aktuelle Lebenssituation. Beantworte dann die 7 Fragen — '
                'jede entspricht einem hermetischen Prinzip. Du erfährst, welche Gesetze gerade '
                'am stärksten in deinem Leben wirken und wie du den Hebel ansetzen kannst.',
                style:
                    TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'AKTUELLE SITUATION',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _situation,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText:
                'z.B. Konflikt mit Kollege, Geld-Sorgen, Beziehungs-Krise...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: _surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _accent.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _accent, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < _checks.length; i++) _buildQuestion(i, _checks[i]),
        const SizedBox(height: 18),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              'AUSWERTEN',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestion(
    int i,
    _HermeticCheck c,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(c.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                c.prinzip,
                style: TextStyle(
                  color: _accent,
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            c.frage,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          for (var j = 0; j < c.antworten.length; j++)
            GestureDetector(
              onTap: () => setState(() => _answers[i] = j),
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: _answers[i] == j
                      ? _accent.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _answers[i] == j
                        ? _accent
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _answers[i] == j
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 16,
                      color: _answers[i] == j ? _accent : Colors.white38,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c.antworten[j],
                        style: TextStyle(
                          color:
                              _answers[i] == j ? Colors.white : Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final top = _topPrinciples();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [_accent, _accent.withValues(alpha: 0.5)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DEINE HERMETISCHE ANALYSE',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Die 2 stärksten Prinzipien in deiner Situation',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final i in top) _buildResultCard(_checks[i], _answers[i]!),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: const Text(
            '💡 Tipp: Speichere die 2 Hinweise als Tagesfokus für die nächste Woche. '
            'Eine konkrete Praxis pro Tag aus dem Hinweis ableiten. Reflexion abends.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh, color: _accent),
            label: const Text(
              'Neuer Check',
              style: TextStyle(color: _accent, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _accent.withValues(alpha: 0.6)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(
    _HermeticCheck c,
    int answerIdx,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(c.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRINZIP DES ${c.prinzip.toUpperCase()}',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Deine Antwort: ${c.antworten[answerIdx]}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(c.hinweis,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, height: 1.6)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _situation.dispose();
    super.dispose();
  }
}
