import 'dart:math' as math;
import 'package:flutter/material.dart';

/// E-X10 -- Pendel-Orakel (Ja/Nein-Befragung)
///
/// Geführte Pendel-Session: Frage eingeben, Pendel schwingt animiert aus und
/// liefert Ja / Nein / Vielleicht. Die letzten Fragen werden (in-memory)
/// protokolliert. Reines On-Device-Tool, keine Server-Anbindung.
class PendulumOracleScreen extends StatefulWidget {
  const PendulumOracleScreen({super.key});

  @override
  State<PendulumOracleScreen> createState() => _PendulumOracleScreenState();
}

class _PendulumOracleScreenState extends State<PendulumOracleScreen>
    with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFF0B0614);
  static const _surface = Color(0xFF160C24);
  static const _gold = Color(0xFFC9A84C);
  static const _purple = Color(0xFF8E5BD0);

  final _questionCtrl = TextEditingController();
  final _rng = math.Random();

  late final AnimationController _swing;
  bool _running = false;
  // Schwing-Achse in Radiant: 0 = horizontal (Ja), pi/2 = vertikal (Nein),
  // pi/4 = diagonal (Vielleicht). Bestimmt die Pendelrichtung.
  double _axis = math.pi / 2;
  String? _answer;
  final List<_PendulumEntry> _log = [];

  @override
  void initState() {
    super.initState();
    _swing = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _swing.dispose();
    _questionCtrl.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final q = _questionCtrl.text.trim();
    if (_running) return;
    setState(() {
      _running = true;
      _answer = null;
    });
    // Zufalls-Ergebnis bestimmt die Schwing-Achse.
    final roll = _rng.nextInt(100);
    final String result;
    if (roll < 45) {
      result = 'Ja';
      _axis = 0; // horizontal
    } else if (roll < 90) {
      result = 'Nein';
      _axis = math.pi / 2; // vertikal
    } else {
      result = 'Vielleicht';
      _axis = math.pi / 4; // diagonal
    }

    // Mehrere Schwünge, dann ausklingen.
    _swing
      ..reset()
      ..repeat(reverse: true);
    await Future<void>.delayed(const Duration(milliseconds: 3000));
    _swing.stop();
    _swing.animateTo(0.5, duration: const Duration(milliseconds: 500));

    if (!mounted) return;
    setState(() {
      _running = false;
      _answer = result;
      if (q.isNotEmpty) {
        _log.insert(0, _PendulumEntry(question: q, answer: result));
        if (_log.length > 12) _log.removeLast();
      }
    });
  }

  Color _answerColor(String a) {
    switch (a) {
      case 'Ja':
        return const Color(0xFF66BB6A);
      case 'Nein':
        return const Color(0xFFEF5350);
      default:
        return _gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Oszillation: -1..1 abhaengig vom Controller-Wert.
    final phase = _running ? math.sin(_swing.value * math.pi * 2) : 0.0;
    const maxAngle = 0.5; // Radiant Auslenkung
    final swingAngle = phase * maxAngle;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _gold),
        title: const Text('Pendel-Orakel',
            style: TextStyle(color: Colors.white, fontSize: 17)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Formuliere eine Ja/Nein-Frage, atme ruhig und lass das '
                'Pendel antworten.',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _questionCtrl,
                style: const TextStyle(color: Colors.white),
                minLines: 1,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Deine Frage ...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                  filled: true,
                  fillColor: _surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _purple.withValues(alpha: 0.4)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _purple.withValues(alpha: 0.4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _gold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Pendel-Visualisierung
              SizedBox(
                height: 260,
                child: Center(
                  child: Transform.rotate(
                    angle: _axis,
                    child: Transform.rotate(
                      angle: swingAngle,
                      alignment: Alignment.topCenter,
                      child: CustomPaint(
                        size: const Size(60, 230),
                        painter: _PendulumPainter(
                          color: _running ? _gold : _purple,
                          glow: _running,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_answer != null)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _answerColor(_answer!).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _answerColor(_answer!).withValues(alpha: 0.5)),
                  ),
                  child: Center(
                    child: Text(
                      _answer!,
                      style: TextStyle(
                        color: _answerColor(_answer!),
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _running ? null : _ask,
                  icon: _running
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.touch_app_rounded, size: 18),
                  label: Text(_running ? 'Pendel schwingt ...' : 'Pendel befragen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              if (_log.isNotEmpty) ...[
                const SizedBox(height: 28),
                const Text('LETZTE FRAGEN',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                for (final e in _log)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _purple.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(e.question,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                        ),
                        const SizedBox(width: 10),
                        Text(e.answer,
                            style: TextStyle(
                                color: _answerColor(e.answer),
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 12),
              Text(
                'Zur Reflexion und Intuitionsschulung gedacht - keine '
                'Wahrsagung.',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 11,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendulumPainter extends CustomPainter {
  final Color color;
  final bool glow;
  _PendulumPainter({required this.color, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final stringPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 1.5;
    // Faden vom oberen Pivot zum Bob.
    final bobCenter = Offset(cx, size.height - 22);
    canvas.drawLine(Offset(cx, 0), bobCenter, stringPaint);

    // Pivot-Punkt.
    canvas.drawCircle(
        Offset(cx, 0), 4, Paint()..color = color.withValues(alpha: 0.8));

    if (glow) {
      canvas.drawCircle(
        bobCenter,
        26,
        Paint()
          ..color = color.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    // Bob (Pendelgewicht).
    final bobPaint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0.5)],
      ).createShader(Rect.fromCircle(center: bobCenter, radius: 18));
    canvas.drawCircle(bobCenter, 18, bobPaint);
    canvas.drawCircle(
        bobCenter,
        18,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white.withValues(alpha: 0.3));
  }

  @override
  bool shouldRepaint(covariant _PendulumPainter old) =>
      old.color != color || old.glow != glow;
}

class _PendulumEntry {
  final String question;
  final String answer;
  const _PendulumEntry({required this.question, required this.answer});
}
