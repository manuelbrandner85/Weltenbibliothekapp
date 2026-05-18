// 🌈 AURA-QUIZ
//
// 12 Multiple-Choice-Fragen → wahrscheinlichste dominante Aura-Farbe.
// Basiert auf Farbpsychologie + Chakra-Korrespondenz. Ehrlich als
// "psychologisches Profil" deklariert, nicht als esoterischer Scan.

import 'package:flutter/material.dart';

class AuraQuizScreen extends StatefulWidget {
  const AuraQuizScreen({super.key});

  @override
  State<AuraQuizScreen> createState() => _AuraQuizScreenState();
}

class _AuraQuizScreenState extends State<AuraQuizScreen> {
  static const _bg = Color(0xFF06040F);
  static const _surface = Color(0xFF100B1E);

  // 7 Aura-Farben (entsprechen den 7 Hauptchakren).
  // Jede Antwort gibt Punkte auf 1-3 Farben (Indizes 0..6 für Rot..Violett/Weiß).
  static final _colors = [
    (
      name: 'Rot',
      emoji: '❤️',
      color: Color(0xFFE53935),
      trait: 'Erdung & Lebenskraft',
      description:
          'Du bist geerdet, körperlich präsent, leidenschaftlich. Pragmatisch, mutig, in Bewegung. '
          'Schatten: Reizbarkeit, Ungeduld, Aggression bei Stress. Stärken: Resilienz, Mut, Handlungsfähigkeit.',
    ),
    (
      name: 'Orange',
      emoji: '🧡',
      color: Color(0xFFFB8C00),
      trait: 'Kreativität & Sinnlichkeit',
      description:
          'Du lebst sinnlich, kreativ, in Beziehung. Spaß, Erotik, Freude am Schöpfen. '
          'Schatten: Unverbindlichkeit, Süchte. Stärken: Lebensfreude, künstlerische Ader, Spontanität.',
    ),
    (
      name: 'Gelb',
      emoji: '💛',
      color: Color(0xFFFDD835),
      trait: 'Willenskraft & Klarheit',
      description:
          'Strahlende Persönlichkeit, optimistisch, intellektuell scharf. Du strebst nach Wachstum. '
          'Schatten: Ego, Selbst-Wichtigkeit. Stärken: Selbstvertrauen, Sonnigkeit, klarer Verstand.',
    ),
    (
      name: 'Grün',
      emoji: '💚',
      color: Color(0xFF43A047),
      trait: 'Heilung & Mitgefühl',
      description:
          'Du heilst Räume, hörst tief zu, sorgst gern. Verbindung zur Natur stark. '
          'Schatten: Aufopferung, Co-Abhängigkeit. Stärken: Empathie, Heilkraft, Harmonie-Stiften.',
    ),
    (
      name: 'Blau',
      emoji: '💙',
      color: Color(0xFF1E88E5),
      trait: 'Kommunikation & Wahrheit',
      description:
          'Du sprichst klar, schreibst gut, suchst Wahrheit. Lehrer-Energie. '
          'Schatten: Kühle Distanz, Über-Rationalisierung. Stärken: Klare Sprache, Vermittlung, Ehrlichkeit.',
    ),
    (
      name: 'Indigo',
      emoji: '💜',
      color: Color(0xFF5E35B1),
      trait: 'Intuition & Vision',
      description:
          'Tiefer Blick, starke Träume, intuitive Eingebungen. Visionär. '
          'Schatten: Realitätsverlust, Eskapismus. Stärken: Innere Führung, Weisheit, Vorausschau.',
    ),
    (
      name: 'Violett',
      emoji: '🤍',
      color: Color(0xFF8E24AA),
      trait: 'Spiritualität & Einheit',
      description:
          'Verbunden mit dem Größeren, Hingabe-fähig, transzendent orientiert. '
          'Schatten: Welt-Abgewandheit, Märtyrertum. Stärken: Bewusstsein, Hingabe, Heiligkeit.',
    ),
  ];

  // 12 Fragen mit jeweils 4 Antwort-Optionen.
  // Jede Antwort gibt Punkte auf eine Farbe (Index 0..6).
  static final _questions = [
    (q: 'Bei einer Party bist du eher...', a: ['Tanzfläche-First', 'Im tiefen Gespräch', 'Mit Kreativen am Buffet', 'Außen am Rand mit dem Hund'], p: [0, 4, 1, 5]),
    (q: 'Dein Lieblings-Wochenende?', a: ['Sport, Abenteuer, Action', 'Buch, Tee, Schreiben', 'Konzert, Galerie, Performance', 'Meditation, Retreat, Stille'], p: [0, 4, 1, 6]),
    (q: 'Wie reagierst du auf Stress?', a: ['Mehr Sport, ausagieren', 'Analyse, Plan machen', 'Schöpferisch verarbeiten', 'Rückzug, beten/meditieren'], p: [0, 2, 1, 6]),
    (q: 'Was zieht dich beim Menschen an?', a: ['Energie & Leidenschaft', 'Intellekt & Witz', 'Tiefe & Mysterium', 'Wärme & Fürsorge'], p: [0, 4, 5, 3]),
    (q: 'Welche Farbe trägst du am liebsten?', a: ['Rot/Schwarz', 'Blau/Grau', 'Lila/Schwarz', 'Grün/Erdtöne'], p: [0, 4, 5, 3]),
    (q: 'Was tust du in einer Krise?', a: ['Sofort handeln', 'Analyse & Strategie', 'Bei Freunden Rat holen', 'In mich gehen, fühlen'], p: [0, 2, 3, 5]),
    (q: 'Welcher Beruf reizt dich am meisten?', a: ['Sportler/Soldat/Chirurg', 'Wissenschaftler/Autor', 'Künstler/Designer', 'Heiler/Therapeut'], p: [0, 4, 1, 3]),
    (q: 'Was magst du am wenigsten?', a: ['Stillsitzen', 'Oberflächlichkeit', 'Routine', 'Kalte Logik'], p: [0, 4, 1, 3]),
    (q: 'Wie äußerst du Liebe?', a: ['Körperliche Nähe', 'Tiefe Gespräche', 'Geschenke/Kreatives', 'Praktische Fürsorge'], p: [0, 4, 1, 3]),
    (q: 'Welche Krankheiten plagen dich am ehesten?', a: ['Verspannung/Verletzung', 'Halsweh/Stimmprobleme', 'Hormone/Bauch', 'Augen/Kopf/Migräne'], p: [0, 4, 1, 5]),
    (q: 'Dein größter Lehrer im Leben?', a: ['Der Körper', 'Die Sprache', 'Die Kunst', 'Die Stille'], p: [0, 4, 1, 6]),
    (q: 'Was bedeutet "Erfolg" für dich?', a: ['Körperliche Vitalität', 'Geistige Klarheit', 'Schöpferische Freiheit', 'Innerer Frieden'], p: [0, 2, 1, 6]),
  ];

  final Map<int, int> _answers = {};
  bool _submitted = false;

  List<int> _scores() {
    final scores = List<int>.filled(_colors.length, 0);
    _answers.forEach((qIdx, aIdx) {
      final p = _questions[qIdx].p[aIdx];
      scores[p] += 1;
    });
    return scores;
  }

  int _dominantColorIndex() {
    final scores = _scores();
    var maxIdx = 0;
    var maxVal = scores[0];
    for (var i = 1; i < scores.length; i++) {
      if (scores[i] > maxVal) {
        maxVal = scores[i];
        maxIdx = i;
      }
    }
    return maxIdx;
  }

  void _submit() {
    if (_answers.length < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Bitte alle 12 Fragen beantworten'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFFAD1457),
        title: const Row(children: [
          Text('🌈', style: TextStyle(fontSize: 22)),
          SizedBox(width: 10),
          Text('Aura-Quiz',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        ]),
      ),
      body: _submitted ? _buildResult() : _buildQuiz(),
    );
  }

  Widget _buildQuiz() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFAD1457), Color(0xFF6A1B9A)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('12-Fragen-Quiz',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(
                'Psychologisches Profil deiner dominanten Aura-Farbe. '
                'Basiert auf Farbpsychologie und Chakra-Korrespondenz.',
                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < _questions.length; i++) _buildQuestion(i),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFAD1457),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('AURA BERECHNEN',
                style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestion(int i) {
    final q = _questions[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${i + 1}. ${q.q}',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (var j = 0; j < q.a.length; j++)
            GestureDetector(
              onTap: () => setState(() => _answers[i] = j),
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: _answers[i] == j ? const Color(0xFFAD1457).withValues(alpha: 0.25) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _answers[i] == j ? const Color(0xFFAD1457) : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(children: [
                  Icon(
                    _answers[i] == j ? Icons.radio_button_checked : Icons.radio_button_off,
                    size: 16,
                    color: _answers[i] == j ? const Color(0xFFAD1457) : Colors.white38,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(q.a[j],
                        style: TextStyle(
                          color: _answers[i] == j ? Colors.white : Colors.white70,
                          fontSize: 12.5,
                        )),
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final scores = _scores();
    final dominantIdx = _dominantColorIndex();
    final dominant = _colors[dominantIdx];
    final maxScore = scores.reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: RadialGradient(colors: [dominant.color, dominant.color.withValues(alpha: 0.4)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: dominant.color.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(dominant.emoji, style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 10),
              const Text('DEINE DOMINANTE AURA-FARBE',
                  style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 2.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(dominant.name,
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4)),
              const SizedBox(height: 4),
              Text(dominant.trait,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: dominant.color.withValues(alpha: 0.4)),
          ),
          child: Text(dominant.description,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6)),
        ),
        const SizedBox(height: 18),
        const Text('AURA-VERTEILUNG',
            style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (var i = 0; i < _colors.length; i++)
          _buildScoreBar(_colors[i], scores[i], maxScore),
        const SizedBox(height: 18),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => setState(() {
              _submitted = false;
              _answers.clear();
            }),
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('Quiz nochmal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreBar(
      ({String name, String emoji, Color color, String trait, String description}) c,
      int score, int maxScore) {
    final percent = maxScore == 0 ? 0.0 : score / maxScore;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(
          width: 70,
          child: Text('${c.emoji} ${c.name}',
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation(c.color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 22,
          child: Text('$score',
              textAlign: TextAlign.right,
              style: TextStyle(color: c.color, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }
}
