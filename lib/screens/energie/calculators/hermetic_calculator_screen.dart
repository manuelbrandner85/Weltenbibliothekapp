import 'package:flutter/material.dart';
import 'dart:math' as math;

/// ✨ Hermetischer Rechner – Die 7 Gesetze des Hermes Trismegistos (Kybalion)
/// Cinema-Stil mit Metatron's Cube / Flower of Life Animation
class HermeticCalculatorScreen extends StatefulWidget {
  const HermeticCalculatorScreen({super.key});

  @override
  State<HermeticCalculatorScreen> createState() =>
      _HermeticCalculatorScreenState();
}

class _HermeticCalculatorScreenState extends State<HermeticCalculatorScreen>
    with TickerProviderStateMixin {
  late final AnimationController _geoCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _breathCtrl;
  late final TabController _tabCtrl;

  // Meditation Timer
  bool _meditationRunning = false;
  int _meditationSeconds = 300; // 5 Minuten
  int _meditationElapsed = 0;

  @override
  void initState() {
    super.initState();
    _geoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _geoCtrl.dispose();
    _glowCtrl.dispose();
    _breathCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _toggleMeditation() {
    setState(() => _meditationRunning = !_meditationRunning);
    if (_meditationRunning) _runMeditationTimer();
  }

  void _runMeditationTimer() async {
    while (_meditationRunning &&
        _meditationElapsed < _meditationSeconds &&
        mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_meditationRunning) break;
      setState(() => _meditationElapsed++);
      if (_meditationElapsed >= _meditationSeconds) {
        setState(() {
          _meditationRunning = false;
          _meditationElapsed = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06040F),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: const Color(0xFF06040F),
            expandedHeight: 260,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildAnimatedHeader(),
            ),
            title: const Text(
              'Hermetische Gesetze',
              style: TextStyle(
                color: Color(0xFFFFD54F),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              indicatorColor: const Color(0xFFFFD54F),
              labelColor: const Color(0xFFFFD54F),
              unselectedLabelColor: Colors.white38,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'Die 7 Gesetze'),
                Tab(text: 'Alchemie'),
                Tab(text: 'Meditation'),
                Tab(text: 'Axiome'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildLawsTab(),
            _buildAlchemyTab(),
            _buildMeditationTab(),
            _buildAxiomsTab(),
          ],
        ),
      ),
    );
  }

  // ── Animierter Header mit Metatron's Cube ────────────────────────────────

  Widget _buildAnimatedHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0A2E), Color(0xFF06040F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: AnimatedBuilder(
        animation: Listenable.merge([_geoCtrl, _glowCtrl]),
        builder: (context, child) {
          final rotation = _geoCtrl.value * 2 * math.pi;
          final opacity = 0.5 + _glowCtrl.value * 0.5;
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(double.infinity, 260),
                painter: _SacredGeometryPainter(
                  rotation: rotation,
                  opacity: opacity,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    '∞',
                    style: TextStyle(
                      fontSize: 48,
                      color: const Color(0xFFFFD54F)
                          .withValues(alpha: 0.6 + _glowCtrl.value * 0.4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'KYBALION',
                    style: TextStyle(
                      fontSize: 13,
                      letterSpacing: 6,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Tab 1: Die 7 Gesetze ─────────────────────────────────────────────────

  Widget _buildLawsTab() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _kLaws.length,
      itemBuilder: (context, i) => _LawCard(
        law: _kLaws[i],
        glowCtrl: _glowCtrl,
      ),
    );
  }

  // ── Tab 2: Alchemie & Symbole ────────────────────────────────────────────

  Widget _buildAlchemyTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _kAlchemySymbols.length,
      itemBuilder: (context, i) => _AlchemyCard(symbol: _kAlchemySymbols[i]),
    );
  }

  // ── Tab 3: Hermetische Meditation ────────────────────────────────────────

  Widget _buildMeditationTab() {
    final remaining = _meditationSeconds - _meditationElapsed;
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;
    final progress = _meditationElapsed / _meditationSeconds;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Atemanimation
          AnimatedBuilder(
            animation: _breathCtrl,
            builder: (context, child) {
              final scale = 0.7 + _breathCtrl.value * 0.3;
              return SizedBox(
                height: 200,
                child: Center(
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFFD54F)
                                .withValues(alpha: 0.8 * scale),
                            const Color(0xFFAB47BC)
                                .withValues(alpha: 0.4 * scale),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD54F)
                                .withValues(alpha: 0.3 * _breathCtrl.value),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _breathCtrl.value > 0.5 ? 'Einatmen' : 'Ausatmen',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // Timer Display
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: Color(0xFFFFD54F),
              fontSize: 48,
              fontWeight: FontWeight.w300,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),

          const SizedBox(height: 12),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD54F)),
              minHeight: 4,
            ),
          ),

          const SizedBox(height: 20),

          // Start/Stop Button
          GestureDetector(
            onTap: _toggleMeditation,
            child: Container(
              width: 140,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD54F), Color(0xFFAB47BC)],
                ),
              ),
              child: Center(
                child: Text(
                  _meditationRunning ? 'Stoppen' : 'Starten',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Geführter Meditationstext
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: Color(0xFFFFD54F), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Wie oben, so unten',
                      style: TextStyle(
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Setze dich bequem. Schließe die Augen. Atme dreimal tief ein und aus.\n\n'
                  'Stelle dir vor, wie du in einem dunklen, stillen Kosmos schwebst. '
                  'Sterne umgeben dich — unzählige Lichtpunkte im Unendlichen.\n\n'
                  'Beobachte nun deinen Herzschlag. Spüre, wie er pulsiert — genauso wie '
                  'die Sterne pulsieren. Wie dein Atem sich ausdehnt und zieht, so dehnt '
                  'sich das Universum aus und zieht sich zurück.\n\n'
                  'Du bist nicht getrennt vom Kosmos. Du BIST der Kosmos, der sich selbst '
                  'betrachtet. Jede Zelle in dir ist ein Universum. Das Universum ist '
                  'eine Zelle in einem größeren Sein.\n\n'
                  'Wie oben, so unten. Wie innen, so außen. Wie im Großen, so im Kleinen.\n\n'
                  'Bleibe in dieser Stille. Du bist zuhause.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 14,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Tab 4: Axiome ────────────────────────────────────────────────────────

  Widget _buildAxiomsTab() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _kAxioms.length,
      itemBuilder: (context, i) {
        final axiom = _kAxioms[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFD54F).withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '“',
                    style: TextStyle(
                      fontSize: 60,
                      height: 0.7,
                      color:
                          const Color(0xFFFFD54F).withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      axiom['text']!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '— ${axiom['source']}',
                  style: TextStyle(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Sacred Geometry Painter ───────────────────────────────────────────────────

class _SacredGeometryPainter extends CustomPainter {
  final double rotation;
  final double opacity;

  _SacredGeometryPainter({required this.rotation, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: opacity * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    // Äußerer Kreis
    canvas.drawCircle(Offset.zero, size.width * 0.45, paint);

    // 6 Blüten (Flower of Life)
    final r = size.width * 0.22;
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final cx = r * math.cos(angle);
      final cy = r * math.sin(angle);
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }

    // Metatron's Cube Verbindungslinien
    final innerPaint = Paint()
      ..color = const Color(0xFFAB47BC).withValues(alpha: opacity * 0.25)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final points = List.generate(13, (i) {
      if (i == 0) return Offset.zero;
      final double angle =
          ((i - 1) * math.pi / 3) + (i > 6 ? math.pi / 6 : 0.0);
      final double radius = i <= 6 ? r : r * 1.73;
      return Offset(radius * math.cos(angle), radius * math.sin(angle));
    });

    for (int a = 0; a < points.length; a++) {
      for (int b = a + 1; b < points.length; b++) {
        canvas.drawLine(points[a], points[b], innerPaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_SacredGeometryPainter old) =>
      old.rotation != rotation || old.opacity != opacity;
}

// ── Law Card Widget ───────────────────────────────────────────────────────────

class _LawCard extends StatefulWidget {
  final Map<String, dynamic> law;
  final AnimationController glowCtrl;

  const _LawCard({required this.law, required this.glowCtrl});

  @override
  State<_LawCard> createState() => _LawCardState();
}

class _LawCardState extends State<_LawCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.law['color'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Numeral
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.15),
                      border: Border.all(color: color.withValues(alpha: 0.5)),
                    ),
                    child: Center(
                      child: Text(
                        widget.law['number'] as String,
                        style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.law['name'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.law['latin'] as String,
                          style: TextStyle(
                            color: color.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white38,
                  ),
                ],
              ),
            ),
          ),

          // Zusammenfassung (immer sichtbar)
          Padding(
            padding: const EdgeInsets.fromLTRB(84, 0, 20, 16),
            child: Text(
              widget.law['summary'] as String,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          // Expandierter Bereich
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _expanded
                ? Container(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.06),
                      border: Border(
                        top: BorderSide(color: color.withValues(alpha: 0.2)),
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoSection(
                            'Erklärung',
                            widget.law['explanation'] as String,
                            color),
                        const SizedBox(height: 14),
                        _infoSection(
                            'Praxis',
                            widget.law['practice'] as String,
                            color),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: color.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.format_quote,
                                  color: color.withValues(alpha: 0.7),
                                  size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.law['affirmation'] as String,
                                  style: TextStyle(
                                    color: color.withValues(alpha: 0.9),
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _infoSection(String title, String text, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: color.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

// ── Alchemy Card Widget ───────────────────────────────────────────────────────

class _AlchemyCard extends StatelessWidget {
  final Map<String, dynamic> symbol;

  const _AlchemyCard({required this.symbol});

  @override
  Widget build(BuildContext context) {
    final color = symbol['color'] as Color;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Glyph + Name
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: Text(
                    symbol['glyph'] as String,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  symbol['name'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Element Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              symbol['element'] as String,
              style: TextStyle(color: color, fontSize: 10),
            ),
          ),

          const SizedBox(height: 8),

          // Bedeutung
          Expanded(
            child: Text(
              symbol['meaning'] as String,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
                height: 1.4,
              ),
              overflow: TextOverflow.fade,
            ),
          ),

          // Spirituelle Korrespondenz
          Text(
            symbol['spiritual'] as String,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Daten ─────────────────────────────────────────────────────────────────────

const List<Map<String, dynamic>> _kLaws = [
  {
    'number': 'I',
    'name': 'Das Mentalismus-Gesetz',
    'latin': 'Mens Omnia',
    'color': Color(0xFFFFD54F),
    'summary': 'Das All ist Geist; das Universum ist mental.',
    'explanation':
        'Alles, was existiert, ist eine Manifestation des universellen Geistes. Gedanken sind real und schöpferisch. Die physische Welt ist eine Projektion des Bewusstseins.',
    'practice':
        'Beobachte deine dominierenden Gedanken. Was du konstant denkst, manifestiert sich in deiner Realität. Wähle bewusst.',
    'affirmation':
        'Mein Geist ist schöpferisch. Ich gestalte meine Realität durch meine Gedanken.',
  },
  {
    'number': 'II',
    'name': 'Das Entsprechungs-Gesetz',
    'latin': 'Analogia',
    'color': Color(0xFFAB47BC),
    'summary': 'Wie oben, so unten; wie innen, so außen.',
    'explanation':
        'Was im Kleinen gilt, gilt auch im Großen. Das Mikrokosmos spiegelt den Makrokosmos. Dein innerer Zustand zeigt sich in deiner äußeren Welt.',
    'practice':
        'Betrachte Probleme auf verschiedenen Ebenen: körperlich, emotional, mental, spirituell. Heilung auf einer Ebene heilt alle.',
    'affirmation': 'Was ich in mir heile, heile ich in meiner Welt.',
  },
  {
    'number': 'III',
    'name': 'Das Schwingungsgesetz',
    'latin': 'Vibratio',
    'color': Color(0xFF26C6DA),
    'summary': 'Nichts ruht; alles bewegt sich; alles schwingt.',
    'explanation':
        'Jedes Atom, jeder Gedanke, jede Emotion schwingt mit einer bestimmten Frequenz. Höhere Schwingung entspricht höherem Bewusstsein.',
    'practice':
        'Hebe deine Schwingung durch: Dankbarkeit, Freude, Liebe, Natur, Musik, Meditation.',
    'affirmation': 'Ich erhöhe bewusst meine Frequenz durch Freude und Liebe.',
  },
  {
    'number': 'IV',
    'name': 'Das Polaritätsgesetz',
    'latin': 'Polaritas',
    'color': Color(0xFFEC407A),
    'summary': 'Alles ist dual; alles hat zwei Pole; Gegensätze sind identisch.',
    'explanation':
        'Heiß und kalt, Licht und Dunkel, Liebe und Hass sind nur verschiedene Grade derselben Qualität. Durch mentale Transmutation kannst du Pole verschieben.',
    'practice':
        'Bei negativen Gedanken: Verschiebe bewusst zum positiven Pol. Ärger → Verständnis. Angst → Mut.',
    'affirmation':
        'Ich transmutiere das Negative in seiner eigenen Qualität in Positives.',
  },
  {
    'number': 'V',
    'name': 'Das Rhythmusgesetz',
    'latin': 'Rhythmus',
    'color': Color(0xFF66BB6A),
    'summary': 'Alles fließt aus und ein; alles hat seine Gezeiten.',
    'explanation':
        'Wie das Pendel schwingt, so pendelt alles im Leben. Auf Expansion folgt Kontraktion, auf Freude Herausforderung. Widerstand gegen den Rhythmus erzeugt Leiden.',
    'practice':
        'Erkenne die Zyklen in deinem Leben. Nutze die Ebbe zum Reflektieren, die Flut zum Handeln.',
    'affirmation': 'Ich vertraue den Zyklen des Lebens. Alles hat seine Zeit.',
  },
  {
    'number': 'VI',
    'name': 'Das Kausalitätsgesetz',
    'latin': 'Causa et Effectus',
    'color': Color(0xFFFF7043),
    'summary': 'Jede Ursache hat ihre Wirkung; jede Wirkung ihre Ursache.',
    'explanation':
        'Es gibt keine Zufälle. Jedes Ereignis ist das Ergebnis einer Ursache. Indem du die Ursachen (Gedanken, Emotionen, Handlungen) gestaltest, gestaltest du die Wirkungen.',
    'practice':
        'Frage bei jeder Situation: Was habe ich durch meine Gedanken und Handlungen gesät?',
    'affirmation': 'Ich säe bewusst, was ich ernten möchte.',
  },
  {
    'number': 'VII',
    'name': 'Das Geschlechtergesetz',
    'latin': 'Genus',
    'color': Color(0xFF7E57C2),
    'summary':
        'Geschlecht ist in allem; alles hat sein maskulines und feminines Prinzip.',
    'explanation':
        'Das maskuline Prinzip (Initiierung, Aktivität, Wille) und das feminine Prinzip (Empfang, Kreativität, Intuition) existieren in allem — in der Natur, im Menschen, im Kosmos.',
    'practice':
        'Kultiviere beide Prinzipien in dir. Wann bist du zu sehr im Tun (maskulin)? Wann zu sehr im Warten (feminin)?',
    'affirmation': 'Ich integriere Aktion und Empfangen in harmonischer Balance.',
  },
];

const List<Map<String, dynamic>> _kAlchemySymbols = [
  {
    'glyph': '🔥',
    'name': 'Feuer',
    'element': 'Primärelement · Aktiv',
    'color': Color(0xFFFF5722),
    'meaning':
        'Transformation, Reinigung, Willensstärke. Das aufsteigende Dreieck symbolisiert das Streben nach Oben.',
    'spiritual': 'Wille · Mut · Transformation',
  },
  {
    'glyph': '💧',
    'name': 'Wasser',
    'element': 'Primärelement · Passiv',
    'color': Color(0xFF2196F3),
    'meaning':
        'Gefühle, Unterbewusstsein, Fließen. Das absteigende Dreieck symbolisiert Empfang und Tiefe.',
    'spiritual': 'Intuition · Emotion · Reinigung',
  },
  {
    'glyph': '◼',
    'name': 'Erde',
    'element': 'Primärelement · Fest',
    'color': Color(0xFF795548),
    'meaning':
        'Materie, Stabilität, Manifestation. Absteigendes Dreieck mit Linie symbolisiert Grundierung.',
    'spiritual': 'Körper · Erdung · Manifestation',
  },
  {
    'glyph': '💨',
    'name': 'Luft',
    'element': 'Primärelement · Beweglich',
    'color': Color(0xFF90CAF9),
    'meaning':
        'Geist, Denken, Kommunikation. Aufsteigendes Dreieck mit Linie symbolisiert das Aufsteigende.',
    'spiritual': 'Intellekt · Freiheit · Kommunikation',
  },
  {
    'glyph': 'S',
    'name': 'Schwefel',
    'element': 'Tria Prima · Seele',
    'color': Color(0xFFFFD54F),
    'meaning':
        'Einer der drei alchemistischen Grundprinzipien. Steht für die aktive, feurige Seele.',
    'spiritual': 'Seele · Leidenschaft · Aktivität',
  },
  {
    'glyph': 'Hg',
    'name': 'Quecksilber',
    'element': 'Tria Prima · Geist',
    'color': Color(0xFFB0BEC5),
    'meaning':
        'Flüssiges Metall als Symbol für den flüchtigen Geist. Verbindet Materie und Geist.',
    'spiritual': 'Geist · Beweglichkeit · Transformation',
  },
  {
    'glyph': 'NaCl',
    'name': 'Salz',
    'element': 'Tria Prima · Körper',
    'color': Color(0xFFECEFF1),
    'meaning':
        'Das dritte Grundprinzip. Kristallstruktur symbolisiert Stabilität und körperliche Manifestation.',
    'spiritual': 'Körper · Stabilität · Reinheit',
  },
  {
    'glyph': '☉',
    'name': 'Gold',
    'element': 'Planetenmetall · Sonne',
    'color': Color(0xFFFFD54F),
    'meaning':
        'Perfektion der Materie. Ziel des alchemistischen Werks: Transformation des Unreinen zum Vollkommenen.',
    'spiritual': 'Perfektion · Licht · Bewusstsein',
  },
  {
    'glyph': '☽',
    'name': 'Silber',
    'element': 'Planetenmetall · Mond',
    'color': Color(0xFFCFD8DC),
    'meaning':
        'Reinheit und Reflexion. Das silberne Metall spiegelt das Licht und steht für das weibliche Prinzip.',
    'spiritual': 'Intuition · Weiblichkeit · Reflexion',
  },
  {
    'glyph': '♂',
    'name': 'Eisen',
    'element': 'Planetenmetall · Mars',
    'color': Color(0xFFEF5350),
    'meaning':
        'Kraft, Ausdauer und Tapferkeit. Eisen tempert den Willen und stärkt den Mut im spirituellen Kampf.',
    'spiritual': 'Stärke · Mut · Willenskraft',
  },
  {
    'glyph': '⚗',
    'name': 'Stein der Weisen',
    'element': 'Opus Magnum · Ziel',
    'color': Color(0xFFAB47BC),
    'meaning':
        'Das ultimative alchemistische Ziel. Transmutiert unedlen Stoff in Gold und verleiht Unsterblichkeit.',
    'spiritual': 'Erleuchtung · Vollendung · Unsterblichkeit',
  },
  {
    'glyph': '✶',
    'name': 'Elixier',
    'element': 'Quinta Essentia',
    'color': Color(0xFF26C6DA),
    'meaning':
        'Die Quintessenz aller Elemente. Das Lebenselixier, das den Körper verjüngt und den Geist erhebt.',
    'spiritual': 'Leben · Gesundheit · Transzendenz',
  },
];

const List<Map<String, String>> _kAxioms = [
  {
    'text': 'Das All ist Geist; das Universum ist mental. Alles ist Geist.',
    'source': 'Kybalion, Axiom I',
  },
  {
    'text':
        'Wie oben, so unten; wie unten, so oben. Wie innen, so außen; wie außen, so innen.',
    'source': 'Kybalion, Axiom II',
  },
  {
    'text': 'Nichts ruht; alles bewegt sich; alles vibriert.',
    'source': 'Kybalion, Axiom III',
  },
  {
    'text':
        'Alles ist dual; alles hat Pole; alles hat sein Paar von Gegensätzen; Gleiches und Ungleiches sind dasselbe; Gegensätze sind identisch in der Natur, aber verschieden im Grad.',
    'source': 'Kybalion, Axiom IV',
  },
  {
    'text':
        'Alles fließt aus und ein; alles hat seine Gezeiten; alle Dinge steigen und fallen; das Pendelschwingen manifestiert sich in allem; das Maß des Schwungs nach rechts ist das Maß des Schwungs nach links.',
    'source': 'Kybalion, Axiom V',
  },
  {
    'text':
        'Jede Ursache hat ihre Wirkung; jede Wirkung hat ihre Ursache; alles geschieht gemäß dem Gesetz; Zufall ist nur ein Name für ein unbekanntes Gesetz.',
    'source': 'Kybalion, Axiom VI',
  },
  {
    'text':
        'Geschlecht ist in allem; alles hat sein maskulines und feminines Prinzip; Geschlecht manifestiert sich auf allen Ebenen.',
    'source': 'Kybalion, Axiom VII',
  },
];
