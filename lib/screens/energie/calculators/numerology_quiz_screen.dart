// Numerologie-Quiz mit 30 Fragen in 3 Schwierigkeitsleveln.
// 5/10/20 XP pro Frage. Korrekte Antworten via NumerologyEngine berechnet
// (Level 3) -- nie hardgecoded.

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../services/achievement_service.dart';
import '../../../services/spirit_calculations/numerology_engine.dart';
import '../../../services/streak_tracking_service.dart';
import '../../../widgets/cinematic/wb_ambient_particles.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/cinematic/wb_vignette.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import 'shared_calc_bg.dart';

enum _QuizLevel { grundlagen, fortgeschritten, experte }

class _QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const _QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

class NumerologyQuizScreen extends StatefulWidget {
  const NumerologyQuizScreen({super.key});

  @override
  State<NumerologyQuizScreen> createState() => _NumerologyQuizScreenState();
}

class _NumerologyQuizScreenState extends State<NumerologyQuizScreen> {
  _QuizLevel _level = _QuizLevel.grundlagen;
  int _index = 0;
  int _score = 0;
  int _xp = 0;
  int? _selected;
  bool _revealed = false;
  bool _finished = false;

  late List<_QuizQuestion> _questions;

  @override
  void initState() {
    super.initState();
    _questions = _buildQuestions(_level);
    StreakTrackingService().trackToolUsage('numerology_quiz');
  }

  int get _xpPerQuestion => switch (_level) {
        _QuizLevel.grundlagen => 5,
        _QuizLevel.fortgeschritten => 10,
        _QuizLevel.experte => 20,
      };

  String get _levelLabel => switch (_level) {
        _QuizLevel.grundlagen => 'Grundlagen',
        _QuizLevel.fortgeschritten => 'Fortgeschritten',
        _QuizLevel.experte => 'Experte',
      };

  void _pick(int i) {
    if (_revealed) return;
    setState(() {
      _selected = i;
      _revealed = true;
      if (i == _questions[_index].correctIndex) {
        _score++;
        _xp += _xpPerQuestion;
      }
    });
  }

  void _next() {
    if (_index + 1 < _questions.length) {
      setState(() {
        _index++;
        _selected = null;
        _revealed = false;
      });
    } else {
      setState(() => _finished = true);
      _grantAchievements();
    }
  }

  Future<void> _grantAchievements() async {
    final passed = _score >= 7;
    final allRight = _score == _questions.length;
    final svc = AchievementService();
    if (passed) {
      switch (_level) {
        case _QuizLevel.grundlagen:
          await svc.incrementProgress('numerology_quiz_lehrling');
          break;
        case _QuizLevel.fortgeschritten:
          await svc.incrementProgress('numerology_quiz_geselle');
          break;
        case _QuizLevel.experte:
          await svc.incrementProgress('numerology_quiz_meister');
          if (allRight) {
            await svc.incrementProgress('numerology_quiz_guru');
          }
          break;
      }
    }
  }

  void _switchLevel(_QuizLevel l) {
    setState(() {
      _level = l;
      _questions = _buildQuestions(l);
      _index = 0;
      _score = 0;
      _xp = 0;
      _selected = null;
      _revealed = false;
      _finished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06040F),
      extendBodyBehindAppBar: true,
      appBar: const WBGlassAppBar(
        title: 'Numerologie-Quiz',
        world: WBWorld.energie,
      ),
      body: CalcAnimatedBg(
        primaryColor: const Color(0xFF7C4DFF),
        secondaryColor: const Color(0xFFCE93D8),
        child: Stack(
          children: [
            const IgnorePointer(
              child: WBAmbientParticles(world: WBWorld.energie, count: 30),
            ),
            const WBVignette(),
            SafeArea(
              child: _finished ? _buildResults() : _buildQuiz(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuiz() {
    final q = _questions[_index];
    return Column(
      children: [
        _levelSwitcher(),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_index + 1) / _questions.length,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF7C4DFF)),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text('Frage ${_index + 1} / ${_questions.length}',
                  style: const TextStyle(color: Colors.white60, fontSize: 11)),
              const Spacer(),
              Text('$_xp XP gesammelt',
                  style: const TextStyle(
                      color: Color(0xFFCE93D8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            children: [
              _questionCard(q.question),
              const SizedBox(height: 14),
              ...List.generate(q.options.length, (i) {
                final isCorrect = i == q.correctIndex;
                final isSelected = _selected == i;
                Color border = Colors.white.withValues(alpha: 0.08);
                Color bg = Colors.white.withValues(alpha: 0.05);
                if (_revealed) {
                  if (isCorrect) {
                    border = Colors.greenAccent;
                    bg = Colors.green.withValues(alpha: 0.15);
                  } else if (isSelected) {
                    border = Colors.redAccent;
                    bg = Colors.red.withValues(alpha: 0.15);
                  }
                } else if (isSelected) {
                  border = const Color(0xFF7C4DFF);
                  bg = const Color(0xFF7C4DFF).withValues(alpha: 0.18);
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _pick(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: border, width: 1.4),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: border.withValues(alpha: 0.3),
                            ),
                            child: Text(
                              String.fromCharCode(65 + i),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              q.options[i],
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  height: 1.4),
                            ),
                          ),
                          if (_revealed && isCorrect)
                            const Icon(Icons.check_circle,
                                color: Colors.greenAccent, size: 18)
                          else if (_revealed && isSelected)
                            const Icon(Icons.cancel,
                                color: Colors.redAccent, size: 18),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              if (_revealed) ...[
                const SizedBox(height: 10),
                _explanationCard(q.explanation),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C4DFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _index + 1 < _questions.length
                          ? 'Weiter'
                          : 'Ergebnis ansehen',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _levelSwitcher() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: _QuizLevel.values.map((l) {
          final sel = l == _level;
          final label = switch (l) {
            _QuizLevel.grundlagen => 'Grundlagen · 5 XP',
            _QuizLevel.fortgeschritten => 'Fortgeschritten · 10 XP',
            _QuizLevel.experte => 'Experte · 20 XP',
          };
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: () => _switchLevel(l),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: sel
                        ? const Color(0xFF7C4DFF).withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: sel
                          ? const Color(0xFF7C4DFF)
                          : Colors.white.withValues(alpha: 0.1),
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: sel ? Colors.white : Colors.white60,
                      fontSize: 10.5,
                      fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _questionCard(String text) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: const Color(0xFF7C4DFF).withValues(alpha: 0.4)),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ),
      ),
    );
  }

  Widget _explanationCard(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amberAccent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded,
              color: Colors.amberAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12.5, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final total = _questions.length;
    final pct = _score / total;
    final passed = _score >= 7;
    final medal = switch (_level) {
      _QuizLevel.grundlagen => passed ? '🥉 Lehrling' : 'noch nicht bestanden',
      _QuizLevel.fortgeschritten =>
        passed ? '🥈 Geselle' : 'noch nicht bestanden',
      _QuizLevel.experte => passed ? '🥇 Meister' : 'noch nicht bestanden',
    };
    final allRight = _score == total;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 30),
        const Text(
          'Quiz beendet!',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4),
        ),
        const SizedBox(height: 6),
        Text(
          '$_levelLabel · ${(pct * 100).toStringAsFixed(0)} %',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white60, fontSize: 13),
        ),
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF7C4DFF).withValues(alpha: 0.65),
                const Color(0xFF7C4DFF).withValues(alpha: 0.15),
              ]),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C4DFF).withValues(alpha: 0.5),
                  blurRadius: 30,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text('$_score / $total',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900)),
          ),
        ),
        const SizedBox(height: 24),
        _statCard('XP verdient', '+$_xp XP', Icons.bolt_rounded),
        const SizedBox(height: 8),
        _statCard('Auszeichnung', medal, Icons.workspace_premium_rounded),
        if (allRight) ...[
          const SizedBox(height: 8),
          _statCard('Perfekt!', '💎 Zahlen-Guru (Platin)',
              Icons.diamond_rounded),
        ],
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _switchLevel(_level),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C4DFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Nochmal versuchen',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zurueck',
                style: TextStyle(color: Colors.white70)),
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFCE93D8), size: 20),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// QUESTIONS -- Level 3 nutzt echte Engine-Berechnungen.
// ══════════════════════════════════════════════════════════════════════

List<_QuizQuestion> _buildQuestions(_QuizLevel level) {
  switch (level) {
    case _QuizLevel.grundlagen:
      return _grundlagenFragen;
    case _QuizLevel.fortgeschritten:
      return _fortgeschrittenFragen;
    case _QuizLevel.experte:
      return _expertenFragen();
  }
}

const _grundlagenFragen = <_QuizQuestion>[
  _QuizQuestion(
    question: 'Wie berechnet man die Lebenszahl?',
    options: [
      'Alle Buchstaben des Namens addieren',
      'Geburtsdatum auf eine Ziffer reduzieren',
      'Geburtsmonat mal Geburtstag',
      'Quersumme des Geburtsjahres',
    ],
    correctIndex: 1,
    explanation:
        'Die Lebenszahl entsteht durch das Reduzieren des vollstaendigen Geburtsdatums (Tag + Monat + Jahr) auf eine einzelne Ziffer.',
  ),
  _QuizQuestion(
    question: 'Welche Zahlen sind Meisterzahlen?',
    options: ['10, 20, 30', '11, 22, 33', '7, 13, 21', '1, 2, 3'],
    correctIndex: 1,
    explanation:
        'Die Meisterzahlen 11, 22 und 33 werden nicht weiter reduziert -- sie tragen besondere spirituelle Aufgaben.',
  ),
  _QuizQuestion(
    question: 'Was zeigt die Seelenzahl?',
    options: [
      'Dein aeusseres Erscheinungsbild',
      'Deine innersten Wuensche und Sehnsuechte',
      'Dein Beruf',
      'Dein Todesdatum',
    ],
    correctIndex: 1,
    explanation:
        'Die Seelenzahl (Soul Urge) offenbart, was dein Herz wirklich begehrt -- berechnet aus den Vokalen des Namens.',
  ),
  _QuizQuestion(
    question: 'Welche Buchstaben werden fuer die Seelenzahl verwendet?',
    options: [
      'Konsonanten',
      'Nur der erste Buchstabe',
      'Vokale (A, E, I, O, U)',
      'Alle Buchstaben',
    ],
    correctIndex: 2,
    explanation:
        'Vokale tragen die innere, seelische Schwingung -- daher bilden A/E/I/O/U die Grundlage der Seelenzahl.',
  ),
  _QuizQuestion(
    question: 'Was ist das Persoenliche Jahr?',
    options: [
      'Dein Alter',
      'Ein 9-Jahres-Zyklus basierend auf Geburtstag + aktuellem Jahr',
      'Das Jahr deiner Geburt',
      'Immer das aktuelle Kalenderjahr',
    ],
    correctIndex: 1,
    explanation:
        'Persoenliches Jahr = (Geburtstag + Geburtsmonat + aktuelles Jahr), reduziert. Es laeuft in 9-Jahres-Zyklen.',
  ),
  _QuizQuestion(
    question: 'Was zeigt die Ausdruckszahl?',
    options: [
      'Deine Talente, Faehigkeiten und natuerliche Mission',
      'Nur deinen Beruf',
      'Deine Vergangenheit',
      'Das aktuelle Datum',
    ],
    correctIndex: 0,
    explanation:
        'Die Ausdruckszahl (Expression) wird aus allen Buchstaben des Geburtsnamens berechnet und zeigt deine Talente.',
  ),
  _QuizQuestion(
    question: 'Wie lange dauert ein numerologischer Lebenszyklus?',
    options: ['9 Jahre', '7 Jahre', '12 Jahre', '28 Jahre'],
    correctIndex: 0,
    explanation:
        'Der Persoenliche-Jahre-Zyklus laeuft ueber 9 Jahre, danach beginnt ein neuer Zyklus auf hoeherer Spirale.',
  ),
  _QuizQuestion(
    question: 'Welcher Wert hat der Buchstabe A im pythagoraeischen System?',
    options: ['1', '2', '3', '5'],
    correctIndex: 0,
    explanation:
        'Pythagoraeisch beginnt das Alphabet bei 1: A=1, B=2, C=3 ... I=9, J=1, K=2 usw.',
  ),
  _QuizQuestion(
    question: 'Wofuer steht die 9 als Lebenszahl?',
    options: [
      'Beginn und Pionierenergie',
      'Vollendung, Mitgefuehl, Humanitaet',
      'Materieller Erfolg',
      'Stabilitaet und Ordnung',
    ],
    correctIndex: 1,
    explanation:
        'Die 9 markiert das Ende eines Zyklus und steht fuer Loslassen, Mitgefuehl und universellen Dienst.',
  ),
  _QuizQuestion(
    question: 'Welche Zahl steht fuer Pionier-Energie?',
    options: ['1', '4', '6', '8'],
    correctIndex: 0,
    explanation:
        'Die 1 ist der Pionier, der Anfang, die Schoepferkraft -- erster Impuls aus der Quelle.',
  ),
];

const _fortgeschrittenFragen = <_QuizQuestion>[
  _QuizQuestion(
    question: 'Was bedeutet die Lebenszahl 7?',
    options: [
      'Materieller Erfolg',
      'Spirituelle Suche und innere Weisheit',
      'Kreativitaet und Freude',
      'Familiaere Verantwortung',
    ],
    correctIndex: 1,
    explanation:
        '7 ist die Zahl des Mystikers, Forschers und spirituell Suchenden -- Innenwelt, Analyse, Tiefe.',
  ),
  _QuizQuestion(
    question: 'Welches System ist aelter: Pythagoraeisch oder Chaldaeisch?',
    options: [
      'Pythagoraeisch',
      'Beide gleich alt',
      'Chaldaeisch',
      'Keines von beiden',
    ],
    correctIndex: 2,
    explanation:
        'Das chaldaeische System (ca. 4000 v. Chr., Babylonien) ist ca. 3500 Jahre aelter als das pythagoraeische.',
  ),
  _QuizQuestion(
    question: 'Die Karma-Zahlen sind:',
    options: ['11, 22, 33', '13, 14, 16, 19', '1, 4, 7', '3, 6, 9'],
    correctIndex: 1,
    explanation:
        'Die Karma-Zahlen 13, 14, 16, 19 markieren Lektionen aus frueheren Leben, die zu integrieren sind.',
  ),
  _QuizQuestion(
    question: 'Welche Zahl trägt das Chaldäische System KEINEM Buchstaben zu?',
    options: ['7', '9', '5', '3'],
    correctIndex: 1,
    explanation:
        'Im chaldaeischen System ist die 9 heilig und wird keinem Buchstaben zugeordnet.',
  ),
  _QuizQuestion(
    question: 'Was ist eine Bruecken-Zahl?',
    options: [
      'Eine spezielle Zahl, die fehlt',
      'Die Differenz zwischen zwei Kernzahlen mit eigener Deutung',
      'Eine Zahl ueber 100',
      'Die hoechste Lebenszahl',
    ],
    correctIndex: 1,
    explanation:
        'Brueckenzahlen zeigen, welche Energie zwei Kernzahlen verbindet -- sie sind die Differenz, z.B. |Lebenszahl - Ausdruckszahl|.',
  ),
  _QuizQuestion(
    question:
        'Welche Zahl im Inclusion Chart deutet auf eine Karmische Lektion?',
    options: [
      '5x vorkommend',
      '3x vorkommend',
      '0x vorkommend',
      '1x vorkommend',
    ],
    correctIndex: 2,
    explanation:
        'Fehlende Zahlen (0x im Namen) markieren karmische Lektionen, die in diesem Leben gemeistert werden sollen.',
  ),
  _QuizQuestion(
    question: 'Wofuer steht die Meisterzahl 22?',
    options: [
      'Der Erleuchtete',
      'Der Master Builder -- Traeume materialisieren',
      'Der Master Teacher',
      'Der Diplomat',
    ],
    correctIndex: 1,
    explanation:
        'Die 22 ist die Master-Builder-Zahl. Sie verleiht die Kraft, grosse Visionen in materielle Realitaet zu uebersetzen.',
  ),
  _QuizQuestion(
    question:
        'Welche Achse hat im Synastrie-Score die hoechste Gewichtung (40%)?',
    options: [
      'Ausdruckszahl',
      'Lebenszahl',
      'Seelenzahl',
      'Persoenlichkeitszahl',
    ],
    correctIndex: 1,
    explanation:
        'Die Lebenszahl traegt 40% des gewichteten Kompatibilitaets-Scores, Seele 35%, Ausdruck 25%.',
  ),
  _QuizQuestion(
    question: 'Welche Solfeggio-Frequenz wird der Lebenszahl 5 zugeordnet?',
    options: ['174 Hz', '417 Hz', '528 Hz', '963 Hz'],
    correctIndex: 2,
    explanation:
        '528 Hz (Transformation / "Wunder-Frequenz") wird der 5 zugeordnet -- DNS-Reparatur und Wandel.',
  ),
  _QuizQuestion(
    question: 'Welche Sephira entspricht der Lebenszahl 6?',
    options: ['Kether', 'Yesod', 'Tiphareth', 'Geburah'],
    correctIndex: 2,
    explanation:
        'Tiphareth (Schoenheit) ist das Herzzentrum des Lebensbaums und resoniert mit der 6.',
  ),
];

List<_QuizQuestion> _expertenFragen() {
  // Berechne korrekte Antworten programmatisch -- NIE hartkodieren!
  final lp1 = NumerologyEngine.calculateLifePath(DateTime(1985, 11, 29));
  final lp2 = NumerologyEngine.calculateLifePath(DateTime(1990, 7, 4));
  final exp1 =
      NumerologyEngine.calculateExpressionNumber('Anna', 'Schmidt');
  final soul1 = NumerologyEngine.calculateSoulNumber('Maria', 'Mueller');
  final personalYear1 = NumerologyEngine.calculatePersonalYear(
      DateTime(1985, 5, 15), DateTime(2024, 1, 1));
  final addr1 = NumerologyEngine.calculateAddressNumber('Musterstrasse 42');
  final addr2 = NumerologyEngine.calculateAddressNumber('Hauptplatz 123/4');
  final chal1 = NumerologyEngine.calculateChaldeanName('David', 'Cohen');
  final pyth1 = NumerologyEngine.calculateExpressionNumber('David', 'Cohen');
  final compat = NumerologyEngine.calculateTrueCompatibility(4, 5);

  String opt(int n) => n.toString();
  List<String> optsAround(int correct,
      [int low = 1, int high = 11]) {
    final s = <int>{correct};
    int extra = correct - 1;
    while (s.length < 4 && extra >= low) {
      s.add(extra);
      extra--;
    }
    extra = correct + 1;
    while (s.length < 4 && extra <= high) {
      s.add(extra);
      extra++;
    }
    final list = s.toList()..sort();
    return list.map(opt).toList();
  }

  List<String> opts4(int correct) => optsAround(correct);
  int idxOf(int correct, List<String> opts) =>
      opts.indexOf(opt(correct));

  final q1Opts = opts4(lp1);
  final q2Opts = opts4(lp2);
  final q3Opts = opts4(exp1);
  final q4Opts = opts4(soul1);
  final q5Opts = opts4(personalYear1);
  final q6Opts = opts4(addr1);
  final q7Opts = opts4(addr2);
  final q8Opts = opts4(chal1);
  final q9Opts = opts4(pyth1);
  final q10Opts = ['$compat', '${compat - 5}', '${compat + 5}', '50'];

  return [
    _QuizQuestion(
      question: 'Berechne die Lebenszahl fuer den 29.11.1985.',
      options: q1Opts,
      correctIndex: idxOf(lp1, q1Opts),
      explanation:
          'Tag 29 -> 11 (Master). Monat 11 (Master). Jahr 1985 -> 23 -> 5. 11+11+5 = 27 -> 9.',
    ),
    _QuizQuestion(
      question: 'Berechne die Lebenszahl fuer den 04.07.1990.',
      options: q2Opts,
      correctIndex: idxOf(lp2, q2Opts),
      explanation:
          'Tag 4. Monat 7. Jahr 1990 -> 19 -> 10 -> 1. Summe: 4+7+1 = 12 -> 3.',
    ),
    _QuizQuestion(
      question: 'Wie lautet die Ausdruckszahl von "Anna Schmidt"?',
      options: q3Opts,
      correctIndex: idxOf(exp1, q3Opts),
      explanation:
          'Alle Buchstaben pythagoraeisch summiert und reduziert.',
    ),
    _QuizQuestion(
      question: 'Wie lautet die Seelenzahl von "Maria Mueller"?',
      options: q4Opts,
      correctIndex: idxOf(soul1, q4Opts),
      explanation: 'Nur Vokale summieren und reduzieren.',
    ),
    _QuizQuestion(
      question:
          'Persoenliches Jahr fuer Geburtstag 15.05.1985 im Jahr 2024?',
      options: q5Opts,
      correctIndex: idxOf(personalYear1, q5Opts),
      explanation:
          'Tag 1+5 + Monat 5 + Jahr 2024->8 = 6+5+8 = 19 -> 10 -> 1.',
    ),
    _QuizQuestion(
      question: 'Hauszahl von "Musterstrasse 42"?',
      options: q6Opts,
      correctIndex: idxOf(addr1, q6Opts),
      explanation: 'Nur Ziffern: 4+2 = 6.',
    ),
    _QuizQuestion(
      question: 'Hauszahl von "Hauptplatz 123/4"?',
      options: q7Opts,
      correctIndex: idxOf(addr2, q7Opts),
      explanation: 'Nur Ziffern: 1+2+3+4 = 10 -> 1.',
    ),
    _QuizQuestion(
      question: 'Chaldaeische Namenszahl von "David Cohen"?',
      options: q8Opts,
      correctIndex: idxOf(chal1, q8Opts),
      explanation:
          'Chaldaeisch: D=4 A=1 V=6 I=1 D=4 + C=3 O=7 H=5 E=5 N=5. Reduziert.',
    ),
    _QuizQuestion(
      question: 'Pythagoraeische Ausdruckszahl von "David Cohen"?',
      options: q9Opts,
      correctIndex: idxOf(pyth1, q9Opts),
      explanation:
          'Pythagoraeisch unterscheidet sich vom chaldaeischen Wert.',
    ),
    _QuizQuestion(
      question: 'Kompatibilitaets-Score Lebenszahl 4 + Lebenszahl 5?',
      options: q10Opts,
      correctIndex: idxOf(compat, q10Opts),
      explanation:
          'Stabilitaet (4) trifft Freiheit (5) -- klassisch herausforderndste Kombi mit niedrigem Score.',
    ),
  ];
}
