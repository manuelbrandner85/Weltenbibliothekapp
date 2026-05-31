// 🧠 ARCHETYPEN-QUIZ — Carol Pearson's 12 Hauptarchetypen
//
// 12 Multiple-Choice-Szenario-Fragen. Antworten mappen auf einen der
// 12 Pearson-Archetypen. Dominanter Archetyp = höchster Score.

import 'package:flutter/material.dart';

// dart2js-Bug-Workaround: Named/positional Records kompilieren nicht zuverlaessig.
class _Archetype {
  final String name;
  final String emoji;
  final String trait;
  final String shadow;
  final Color color;
  const _Archetype({
    required this.name,
    required this.emoji,
    required this.trait,
    required this.shadow,
    required this.color,
  });
}

class _Answer {
  final String text;
  final int archIdx;
  const _Answer(this.text, this.archIdx);
}

class _Question {
  final String q;
  final List<_Answer> a;
  const _Question({required this.q, required this.a});
}

class ArchetypeQuizScreen extends StatefulWidget {
  const ArchetypeQuizScreen({super.key});

  @override
  State<ArchetypeQuizScreen> createState() => _ArchetypeQuizScreenState();
}

class _ArchetypeQuizScreenState extends State<ArchetypeQuizScreen> {
  static const _bg = Color(0xFF06040F);
  static const _surface = Color(0xFF100B1E);
  static const _accent = Color(0xFF673AB7);

  // 12 Archetypen-Indizes (0..11) korrespondierend zu archetypes_12.dart-Reihenfolge:
  // 0=Unschuldiger 1=Gewöhnlicher 2=Held 3=Fürsorger 4=Suchender 5=Liebender
  // 6=Rebell 7=Schöpfer 8=Herrscher 9=Magier 10=Weise 11=Narr
  static final _archetypes = [
    _Archetype(
      name: 'Unschuldiger',
      emoji: '🤍',
      trait: 'Vertrauen · Sehnsucht nach Paradies',
      shadow: 'Naivität, Realitätsverleugnung',
      color: Color(0xFFE0F2F1),
    ),
    _Archetype(
      name: 'Gewöhnlicher',
      emoji: '🧑‍🤝‍🧑',
      trait: 'Bodenständigkeit · Zugehörigkeit',
      shadow: 'Anpassung um jeden Preis',
      color: Color(0xFF8D6E63),
    ),
    _Archetype(
      name: 'Held',
      emoji: '🦸',
      trait: 'Mut · Wettbewerb · Sieg',
      shadow: 'Arroganz, Burnout',
      color: Color(0xFFE53935),
    ),
    _Archetype(
      name: 'Fürsorger',
      emoji: '💕',
      trait: 'Mitgefühl · Schutz',
      shadow: 'Märtyrertum, Burnout durch Geben',
      color: Color(0xFFE91E63),
    ),
    _Archetype(
      name: 'Suchender',
      emoji: '🔍',
      trait: 'Freiheit · Reise · Authentizität',
      shadow: 'Entwurzelung, Bindungsunfähigkeit',
      color: Color(0xFFFB8C00),
    ),
    _Archetype(
      name: 'Liebender',
      emoji: '❤️',
      trait: 'Hingabe · Schönheit · Sinnlichkeit',
      shadow: 'Eifersucht, Selbst-Verlust',
      color: Color(0xFFC2185B),
    ),
    _Archetype(
      name: 'Rebell',
      emoji: '⚔️',
      trait: 'Befreiung · Disruption',
      shadow: 'Wut als Identität',
      color: Color(0xFF263238),
    ),
    _Archetype(
      name: 'Schöpfer',
      emoji: '🎨',
      trait: 'Vision · Kreation',
      shadow: 'Perfektionismus, blockierte Vision',
      color: Color(0xFF9C27B0),
    ),
    _Archetype(
      name: 'Herrscher',
      emoji: '👑',
      trait: 'Verantwortung · Souveränität',
      shadow: 'Kontrolle, Tyrannei',
      color: Color(0xFFFFB300),
    ),
    _Archetype(
      name: 'Magier',
      emoji: '✨',
      trait: 'Transformation · Vision-zu-Realität',
      shadow: 'Manipulation, Macht-Missbrauch',
      color: Color(0xFF7C4DFF),
    ),
    _Archetype(
      name: 'Weise',
      emoji: '🧙',
      trait: 'Wahrheit · Klarheit',
      shadow: 'Lebens-Vermeidung durch Denken',
      color: Color(0xFF1E88E5),
    ),
    _Archetype(
      name: 'Narr',
      emoji: '🃏',
      trait: 'Freude · Heiligkeit des Augenblicks',
      shadow: 'Eskapismus, Verantwortungslosigkeit',
      color: Color(0xFFFDD835),
    ),
  ];

  static final _questions = [
    _Question(
      q: 'Sonntagabend mit unverplanter Zeit — was tust du?',
      a: [
        _Answer('Spazierengehen, einfach sein', 0),
        _Answer('Mit Freunden treffen', 1),
        _Answer('Sport oder Wettkampf', 2),
        _Answer('Für jemanden kochen', 3),
      ]
    ),
    _Question(
      q: 'Im Job suchst du vor allem...',
      a: [
        _Answer('Sicherheit und Routine', 0),
        _Answer('Sinn und Wirkung', 9),
        _Answer('Aufstieg und Anerkennung', 8),
        _Answer('Kreative Freiheit', 7),
      ]
    ),
    _Question(
      q: 'In Konflikten...',
      a: [
        _Answer('Suche ich Harmonie', 0),
        _Answer('Setze ich klare Grenzen', 2),
        _Answer('Versuche zu vermitteln', 3),
        _Answer('Sage ich was Sache ist, koste es was es wolle', 6),
      ]
    ),
    _Question(
      q: 'Mein Lieblings-Genre in Büchern/Filmen?',
      a: [
        _Answer('Romance, Drama', 5),
        _Answer('Action, Abenteuer', 4),
        _Answer('Mystery, Sci-Fi', 9),
        _Answer('Sachbücher, Philosophie', 10),
      ]
    ),
    _Question(
      q: 'Was ist dir wichtiger?',
      a: [
        _Answer('Aufrichtigkeit', 0),
        _Answer('Erfolg', 2),
        _Answer('Tiefe Verbindungen', 5),
        _Answer('Freiheit', 4),
      ]
    ),
    _Question(
      q: 'Wenn du eine Schwäche zugeben müsstest...',
      a: [
        _Answer('Zu vertrauensselig', 0),
        _Answer('Zu kritisch mit mir', 7),
        _Answer('Zu viel zugleich wollen', 9),
        _Answer('Zu wenig auf mich achten', 3),
      ]
    ),
    _Question(
      q: 'In sozialer Runde bist du eher...',
      a: [
        _Answer('Der Comedian', 11),
        _Answer('Der Tiefgründige', 10),
        _Answer('Der Organisator', 8),
        _Answer('Der Außenseiter', 6),
      ]
    ),
    _Question(
      q: 'Welcher Satz beschreibt dich?',
      a: [
        _Answer('Ich liebe Menschen.', 3),
        _Answer('Ich liebe Schönheit.', 5),
        _Answer('Ich liebe Wahrheit.', 10),
        _Answer('Ich liebe das Spiel.', 11),
      ]
    ),
    _Question(
      q: 'Bei einer Reise willst du am liebsten...',
      a: [
        _Answer('Etwas Authentisches erleben', 4),
        _Answer('Tief in eine Kultur eintauchen', 10),
        _Answer('Adrenalin und Abenteuer', 2),
        _Answer('Etwas Lokales mit Insidern entdecken', 11),
      ]
    ),
    _Question(
      q: 'Was treibt dich an, morgens aufzustehen?',
      a: [
        _Answer('Verantwortung für andere', 3),
        _Answer('Mein nächstes Werk', 7),
        _Answer('Veränderung in der Welt', 6),
        _Answer('Pure Lebensfreude', 11),
      ]
    ),
    _Question(
      q: 'Welche Krise wäre für dich am schlimmsten?',
      a: [
        _Answer('Verlust der Liebe', 5),
        _Answer('Verlust der Macht', 8),
        _Answer('Verlust der Freiheit', 4),
        _Answer('Verlust der Bedeutung', 10),
      ]
    ),
    _Question(
      q: 'Wie willst du in Erinnerung bleiben?',
      a: [
        _Answer('Als jemand, der Großes vollbracht hat', 2),
        _Answer('Als jemand, der die Welt verändert hat', 9),
        _Answer('Als jemand, der wahrhaftig gelebt hat', 4),
        _Answer('Als jemand, der die Welt schöner gemacht hat', 7),
      ]
    ),
  ];

  final Map<int, int> _answers = {};
  bool _submitted = false;

  List<int> _scores() {
    final scores = List<int>.filled(_archetypes.length, 0);
    _answers.forEach((qIdx, aIdx) {
      final archIdx = _questions[qIdx].a[aIdx].archIdx;
      scores[archIdx] += 1;
    });
    return scores;
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
        backgroundColor: _accent,
        title: const Row(children: [
          Text('🧠', style: TextStyle(fontSize: 22)),
          SizedBox(width: 10),
          Text('Archetypen-Quiz',
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
            gradient: LinearGradient(
                colors: [_accent, _accent.withValues(alpha: 0.5)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pearson-12-Archetypen-Test',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(
                '12 Szenario-Fragen → dein dominanter Pearson-Archetyp. '
                'Beantworte spontan, nicht "wie sollte ich sein".',
                style:
                    TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
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
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('AUSWERTEN',
                style:
                    TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2)),
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
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (var j = 0; j < q.a.length; j++)
            GestureDetector(
              onTap: () => setState(() => _answers[i] = j),
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: _answers[i] == j
                      ? _accent.withValues(alpha: 0.25)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _answers[i] == j
                        ? _accent
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(children: [
                  Icon(
                    _answers[i] == j
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 16,
                    color: _answers[i] == j ? _accent : Colors.white38,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(q.a[j].text,
                        style: TextStyle(
                          color:
                              _answers[i] == j ? Colors.white : Colors.white70,
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
    // Top-3 Archetypen
    final indexed = List.generate(scores.length, (i) => MapEntry(i, scores[i]));
    indexed.sort((a, b) => b.value.compareTo(a.value));
    final top3 = indexed.take(3).toList();
    final dominant = _archetypes[top3[0].key];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              dominant.color,
              dominant.color.withValues(alpha: 0.3)
            ]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: dominant.color.withValues(alpha: 0.5), blurRadius: 24)
            ],
          ),
          child: Column(
            children: [
              Text(dominant.emoji, style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 8),
              const Text('DEIN DOMINANTER ARCHETYP',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(dominant.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3)),
              const SizedBox(height: 4),
              Text(dominant.trait,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontStyle: FontStyle.italic)),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Schatten: ${dominant.shadow}',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 11)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text('SEKUNDÄRE EINFLÜSSE',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (final entry in top3.skip(1))
          _buildSecondary(_archetypes[entry.key], entry.value),
        const SizedBox(height: 18),
        const Text('GESAMT-VERTEILUNG',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (var i = 0; i < _archetypes.length; i++)
          _buildScoreBar(_archetypes[i], scores[i], top3[0].value),
        const SizedBox(height: 18),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => setState(() {
              _submitted = false;
              _answers.clear();
            }),
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('Quiz nochmal',
                style: TextStyle(color: Colors.white)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecondary(_Archetype a, int score) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: a.color.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Text(a.emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              Text(a.trait,
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ),
        Text('$score',
            style: TextStyle(
                color: a.color, fontSize: 18, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildScoreBar(_Archetype a, int score, int maxScore) {
    final percent = maxScore == 0 ? 0.0 : score / maxScore;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(
          width: 110,
          child: Text('${a.emoji} ${a.name}',
              style: const TextStyle(color: Colors.white, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation(a.color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 18,
          child: Text('$score',
              textAlign: TextAlign.right,
              style: TextStyle(
                  color: a.color, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }
}
