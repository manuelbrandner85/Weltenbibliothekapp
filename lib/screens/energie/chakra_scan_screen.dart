import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 💎 Chakra-Assessment — Fragebogen-basierte Energieanalyse
class ChakraScanScreen extends StatefulWidget {
  final String roomId;
  const ChakraScanScreen({super.key, this.roomId = 'chakra'});

  @override
  State<ChakraScanScreen> createState() => _ChakraScanScreenState();
}

class _ChakraScanScreenState extends State<ChakraScanScreen>
    with TickerProviderStateMixin {
  int _step = 0; // 0=intro, 1=questions, 2=result
  int _currentQ = 0;
  final Map<int, int> _answers = {}; // questionIndex → 0..4 (nie..immer)

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _pulse = Tween(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // 7 Chakras × 3 Fragen = 21 Fragen
  static const _chakras = [
    {
      'name': 'Wurzel-Chakra',
      'sanskrit': 'Muladhara',
      'color': Color(0xFFE53935),
      'emoji': '🔴',
      'element': 'Erde',
      'location': 'Steißbein',
      'questions': [
        'Ich fühle mich sicher und geerdet im Alltag.',
        'Meine Grundbedürfnisse (Essen, Wohnen, Sicherheit) fühlen sich erfüllt an.',
        'Ich vertraue darauf, dass ich im Leben gut versorgt bin.',
      ],
      'balanced': 'Du fühlst dich sicher, geerdet und verankert im Leben.',
      'unbalanced': 'Ängste, Unsicherheit oder Überlebensinstinkte könnten dich belasten.',
      'practice': 'Barfuß auf Gras gehen · Rote Lebensmittel · Granat/Rubin meditieren',
    },
    {
      'name': 'Sakral-Chakra',
      'sanskrit': 'Svadhisthana',
      'color': Color(0xFFFF6D00),
      'emoji': '🟠',
      'element': 'Wasser',
      'location': 'Unterbauch',
      'questions': [
        'Ich genieße Freude, Kreativität und sinnliche Erlebnisse.',
        'Ich kann meine Emotionen frei und gesund ausdrücken.',
        'Meine Beziehungen fühlen sich ausgewogen und nährend an.',
      ],
      'balanced': 'Kreativität, Freude und gesunde Beziehungen fließen durch dein Leben.',
      'unbalanced': 'Kreativitätsblockaden, emotionale Taubheit oder Abhängigkeiten möglich.',
      'practice': 'Im Wasser schwimmen · Orange meditieren · Tanzen / kreativ sein',
    },
    {
      'name': 'Solarplexus-Chakra',
      'sanskrit': 'Manipura',
      'color': Color(0xFFFFD600),
      'emoji': '🟡',
      'element': 'Feuer',
      'location': 'Magenbereich',
      'questions': [
        'Ich vertraue meiner eigenen Urteilskraft und Entscheidungsfähigkeit.',
        'Ich habe ein gesundes Selbstbewusstsein ohne Arroganz.',
        'Ich setze klare Grenzen und vertrete meine Meinung.',
      ],
      'balanced': 'Du strahlst innere Stärke, Selbstvertrauen und Entschlossenheit aus.',
      'unbalanced': 'Kontrollbedürfnis, Selbstzweifel oder Willensschwäche könnten präsent sein.',
      'practice': 'Sonnenenergie tanken · Gelb meditieren · Kernkräftigung / Yoga',
    },
    {
      'name': 'Herz-Chakra',
      'sanskrit': 'Anahata',
      'color': Color(0xFF4CAF50),
      'emoji': '💚',
      'element': 'Luft',
      'location': 'Herz-Mitte',
      'questions': [
        'Ich kann bedingungslos lieben — mich selbst und andere.',
        'Ich vergebe leicht und trage keine alten Wunden mit mir.',
        'Ich empfinde Mitgefühl und Empathie für andere Lebewesen.',
      ],
      'balanced': 'Liebe, Mitgefühl und Verbundenheit sind deine natürlichen Zustände.',
      'unbalanced': 'Herzensschmerz, Selbstkritik oder Schwierigkeiten beim Loslassen.',
      'practice': 'Liebende-Güte-Meditation · Grüner Kristall · Tief einatmen',
    },
    {
      'name': 'Hals-Chakra',
      'sanskrit': 'Vishuddha',
      'color': Color(0xFF0288D1),
      'emoji': '🔵',
      'element': 'Äther',
      'location': 'Kehle',
      'questions': [
        'Ich spreche meine Wahrheit klar und authentisch aus.',
        'Ich höre anderen aufmerksam zu ohne zu urteilen.',
        'Ich drücke mich kreativ aus (Schreiben, Musik, Kunst, Sprache).',
      ],
      'balanced': 'Authentische Kommunikation und kreativer Selbstausdruck fließen leicht.',
      'unbalanced': 'Schwierigkeiten beim Sprechen, Schweigen aus Angst, oder Überreden.',
      'practice': 'Singen / Summen · Blaue Howlith meditieren · Journaling',
    },
    {
      'name': 'Stirn-Chakra',
      'sanskrit': 'Ajna',
      'color': Color(0xFF3949AB),
      'emoji': '🔷',
      'element': 'Licht',
      'location': 'Zwischen den Augen',
      'questions': [
        'Ich vertraue meiner Intuition und inneren Führung.',
        'Ich habe klare Visionen und einen Sinn für das große Ganze.',
        'Ich unterscheide zwischen Illusion und tiefer Wahrheit.',
      ],
      'balanced': 'Klare Intuition, Weisheit und spirituelle Einsicht leiten dich.',
      'unbalanced': 'Verwirrung, Überanalyse, Albträume oder fehlende Lebensrichtung.',
      'practice': 'Indigo-Amethyst meditieren · Stille Kontemplation · Träume aufschreiben',
    },
    {
      'name': 'Kronen-Chakra',
      'sanskrit': 'Sahasrara',
      'color': Color(0xFF9C27B0),
      'emoji': '🟣',
      'element': 'Bewusstsein',
      'location': 'Scheitel',
      'questions': [
        'Ich fühle mich mit dem Universum / Höherem Selbst verbunden.',
        'Ich lebe aus einem tiefen Sinn für Zweck und Bedeutung.',
        'Ich bin offen für spirituelles Wachstum und höhere Wahrheiten.',
      ],
      'balanced': 'Göttliche Verbindung, Einheitsbewusstsein und Sinn erfüllen dein Leben.',
      'unbalanced': 'Spirituelle Leere, Materialismus oder ein Gefühl der Sinnlosigkeit.',
      'practice': 'Stille Meditation · Weißes / violettes Licht visualisieren · Natur-Kontemplation',
    },
  ];

  static const _answerLabels = ['Nie', 'Selten', 'Manchmal', 'Oft', 'Immer'];

  List<_ChakraScore> get _scores {
    final scores = <_ChakraScore>[];
    for (int ci = 0; ci < _chakras.length; ci++) {
      final qs = _chakras[ci]['questions'] as List;
      double total = 0;
      int answered = 0;
      for (int qi = 0; qi < qs.length; qi++) {
        final key = ci * 3 + qi;
        if (_answers.containsKey(key)) {
          total += _answers[key]! / 4.0;
          answered++;
        }
      }
      scores.add(_ChakraScore(
        chakra: _chakras[ci] as Map<String, dynamic>,
        score: answered > 0 ? total / answered : 0.5,
        answered: answered,
        total: qs.length,
      ));
    }
    return scores;
  }

  void _answer(int value) {
    HapticFeedback.lightImpact();
    final totalQ = _chakras.length * 3;
    setState(() {
      _answers[_currentQ] = value;
      if (_currentQ < totalQ - 1) {
        _currentQ++;
      } else {
        _step = 2; // results
      }
    });
  }

  void _restart() => setState(() {
    _step = 0;
    _currentQ = 0;
    _answers.clear();
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF7C4DFF);
    const bg = Color(0xFF0D0D1A);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _step == 0
              ? _buildIntro(accent)
              : _step == 1
                  ? _buildQuestion(accent)
                  : _buildResult(accent),
        ),
      ),
    );
  }

  Widget _buildIntro(Color accent) {
    return Column(
      key: const ValueKey('intro'),
      children: [
        AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Chakra-Assessment'),
          elevation: 0,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => Transform.scale(
                    scale: _pulse.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [accent, const Color(0xFF0D0D1A)],
                          stops: const [0.3, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(color: accent.withValues(alpha: 0.4), blurRadius: 40, spreadRadius: 10),
                        ],
                      ),
                      child: const Center(
                        child: Text('☯', style: TextStyle(fontSize: 52)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Chakra-Analyse',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '21 Fragen · 7 Chakren · ~3 Minuten\n\nEntdecke welche Energiezentren aktiv sind\nund welche mehr Aufmerksamkeit brauchen.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 15,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Chakra-Vorschau
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _chakras.map((c) {
                    final color = c['color'] as Color;
                    return Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => setState(() => _step = 1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: const Text(
                    'Assessment starten',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestion(Color accent) {
    final totalQ = _chakras.length * 3;
    final chakraIdx = _currentQ ~/ 3;
    final qIdx = _currentQ % 3;
    final chakra = _chakras[chakraIdx] as Map<String, dynamic>;
    final color = chakra['color'] as Color;
    final qs = chakra['questions'] as List;
    final progress = _currentQ / totalQ;

    return Column(
      key: ValueKey('q_$_currentQ'),
      children: [
        AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            '${chakra['emoji']} ${chakra['name']}',
            style: const TextStyle(fontSize: 16),
          ),
          leading: _currentQ > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded),
                  onPressed: () => setState(() => _currentQ--),
                )
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => setState(() => _step = 0),
                ),
        ),
        // Progress
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Frage ${_currentQ + 1} von $totalQ',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Chakra-Symbol
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.15),
                    border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
                  ),
                  child: Center(
                    child: Text(chakra['emoji'] as String, style: const TextStyle(fontSize: 32)),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  qs[qIdx] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Antwort-Buttons
                ...List.generate(5, (i) {
                  final isSelected = _answers[_currentQ] == i;
                  return GestureDetector(
                    onTap: () => _answer(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? color : Colors.white.withValues(alpha: 0.1),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? color : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? color : Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 13)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _answerLabels[i],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult(Color accent) {
    final sc = _scores;

    return Column(
      key: const ValueKey('result'),
      children: [
        AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Dein Chakra-Profil'),
          actions: [
            TextButton(
              onPressed: _restart,
              child: const Text('Neu', style: TextStyle(color: Color(0xFF7C4DFF))),
            ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Chakra-Rad
              Center(child: _ChakraWheel(scores: sc, pulseCtrl: _pulseCtrl)),
              const SizedBox(height: 24),
              ...sc.map((s) => _ChakraResultCard(score: s)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChakraScore {
  final Map<String, dynamic> chakra;
  final double score; // 0.0–1.0
  final int answered;
  final int total;

  const _ChakraScore({
    required this.chakra,
    required this.score,
    required this.answered,
    required this.total,
  });

  String get label {
    if (score >= 0.75) return 'Aktiv';
    if (score >= 0.45) return 'Ausgewogen';
    return 'Blockiert';
  }

  Color get labelColor {
    if (score >= 0.75) return const Color(0xFF4CAF50);
    if (score >= 0.45) return const Color(0xFFFFB300);
    return const Color(0xFFFF1744);
  }
}

class _ChakraWheel extends StatelessWidget {
  final List<_ChakraScore> scores;
  final AnimationController pulseCtrl;

  const _ChakraWheel({required this.scores, required this.pulseCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseCtrl,
      builder: (_, __) => SizedBox(
        width: 220,
        height: 220,
        child: CustomPaint(
          painter: _WheelPainter(scores: scores, pulse: pulseCtrl.value),
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<_ChakraScore> scores;
  final double pulse;

  const _WheelPainter({required this.scores, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2 - 10;

    for (int i = 0; i < scores.length; i++) {
      final s = scores[i];
      final color = s.chakra['color'] as Color;
      final angle = (i / scores.length) * 2 * math.pi - math.pi / 2;
      final r = maxR * s.score * (0.95 + pulse * 0.05);
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      // Linie
      final paint = Paint()
        ..color = color.withValues(alpha: 0.5)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(center, Offset(x, y), paint);

      // Dot
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 8, dotPaint);
      canvas.drawCircle(
        Offset(x, y), 4,
        Paint()..color = Colors.white..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) => old.pulse != pulse;
}

class _ChakraResultCard extends StatefulWidget {
  final _ChakraScore score;
  const _ChakraResultCard({required this.score});

  @override
  State<_ChakraResultCard> createState() => _ChakraResultCardState();
}

class _ChakraResultCardState extends State<_ChakraResultCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.score;
    final color = s.chakra['color'] as Color;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Text(s.chakra['emoji'] as String, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.chakra['name'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          s.chakra['sanskrit'] as String,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: s.labelColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: s.labelColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      s.label,
                      style: TextStyle(
                        color: s.labelColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: Colors.white38,
                    size: 20,
                  ),
                ],
              ),
            ),
            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: s.score,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.score >= 0.45
                          ? s.chakra['balanced'] as String
                          : s.chakra['unbalanced'] as String,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.spa_outlined, color: color, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s.chakra['practice'] as String,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
