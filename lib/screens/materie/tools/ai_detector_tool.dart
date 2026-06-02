import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/materie/osint_source_banner.dart';

// ─────────────────────────────────────────────────────────────────────────────
// F — KI-Content-Detektor
// ─────────────────────────────────────────────────────────────────────────────

const _kBg = Color(0xFF0D0000);
const _kSurface = Color(0xFF1A0808);
const _kAccent = Color(0xFFE53935);
const _kText = Colors.white;
const _kMuted = Color(0xFFB0A0A0);
const _kBorder = Color(0x33E53935);

class AiDetectorTool extends StatefulWidget {
  const AiDetectorTool({super.key});

  @override
  State<AiDetectorTool> createState() => _AiDetectorToolState();
}

class _AiDetectorToolState extends State<AiDetectorTool> {
  final _textCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _detect() async {
    final text = _textCtrl.text.trim();
    if (text.length < 50) {
      setState(() {
        _error =
            'Bitte mindestens 50 Zeichen eingeben für eine zuverlässige Analyse.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final uri = Uri.parse('${ApiConfig.workerUrl}/api/tools/ai-detect');
      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 30));
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['error'] != null) throw Exception(data['error'].toString());
      setState(() {
        _result = data;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Color _scoreColor(int score) {
    if (score <= 30) return const Color(0xFF4CAF50);
    if (score <= 60) return const Color(0xFFFFB300);
    return _kAccent;
  }

  String _scoreLabel(int score) {
    if (score <= 30) return 'Human-verfasst';
    if (score <= 60) return 'Unklar';
    return 'KI-generiert';
  }

  Widget _card(Widget child) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final score = _result?['score'] as int? ?? 0;
    final indicators = (_result?['indicators'] as List?)?.cast<String>() ?? [];
    final verdict = _result?['verdict'] as String?;
    final scoreColor = _scoreColor(score);

    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      appBar: WBGlassAppBar(
        world: WBWorld.materie,
        titleWidget: Row(children: [
          Icon(Icons.smart_toy_rounded, color: _kAccent, size: 22),
          const SizedBox(width: 8),
          const Text('KI-Content-Detektor',
              style: TextStyle(color: _kText, fontWeight: FontWeight.bold)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('Text eingeben',
                  style: TextStyle(color: _kMuted, fontSize: 12)),
              const Spacer(),
              Text('${_textCtrl.text.length} Zeichen',
                  style: const TextStyle(color: _kMuted, fontSize: 11)),
            ]),
            const SizedBox(height: 8),
            TextField(
              controller: _textCtrl,
              style: const TextStyle(color: _kText, fontSize: 13),
              maxLines: 8,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText:
                    'Füge hier den zu prüfenden Text ein (min. 50 Zeichen)...',
                hintStyle: TextStyle(
                    color: _kMuted.withValues(alpha: 0.6), fontSize: 13),
                filled: true,
                fillColor: _kBg,
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _kBorder)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _kBorder)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _kAccent)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _detect,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.psychology_rounded, size: 18),
                label: const Text('KI-Analyse starten'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ])),
          OsintSourceBanner(
            source: 'Wahrscheinlichkeits-Schaetzung ob Text KI-generiert '
                'ist, ueber den Weltenbibliothek-Worker. Ergebnis ist '
                'statistisch, kein Beweis. ',
            accent: _kAccent,
          ),
          if (_error != null)
            _card(Row(children: [
              const Icon(Icons.error_outline, color: _kAccent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(_error!,
                      style: const TextStyle(color: _kAccent, fontSize: 13))),
            ])),
          if (_result != null) ...[
            // Score Gauge
            _card(Column(children: [
              const Text('KI-Wahrscheinlichkeit',
                  style: TextStyle(color: _kMuted, fontSize: 12)),
              const SizedBox(height: 16),
              SizedBox(
                width: 140,
                height: 140,
                child: CustomPaint(
                  painter: _GaugePainter(score: score / 100, color: scoreColor),
                  child: Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('$score%',
                        style: TextStyle(
                            color: scoreColor,
                            fontSize: 28,
                            fontWeight: FontWeight.bold)),
                    Text(verdict ?? _scoreLabel(score),
                        style: TextStyle(color: scoreColor, fontSize: 12)),
                  ])),
                ),
              ),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _legendItem('0-30%', 'Mensch', const Color(0xFF4CAF50)),
                _legendItem('31-60%', 'Unklar', const Color(0xFFFFB300)),
                _legendItem('61-100%', 'KI', _kAccent),
              ]),
            ])),

            if (indicators.isNotEmpty)
              _card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Erkannte Merkmale',
                        style: TextStyle(color: _kMuted, fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: indicators
                          .map((ind) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: scoreColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: scoreColor.withValues(alpha: 0.3)),
                                ),
                                child: Text(ind,
                                    style: TextStyle(
                                        color: scoreColor, fontSize: 12)),
                              ))
                          .toList(),
                    ),
                  ])),

            _card(
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Hinweis',
                  style: TextStyle(color: _kMuted, fontSize: 11)),
              const SizedBox(height: 4),
              const Text(
                'Diese Analyse nutzt heuristische Methoden und KI-Modelle. '
                'Das Ergebnis ist ein Richtwert und kein Beweis. '
                'Kurze Texte können unzuverlässige Ergebnisse liefern.',
                style: TextStyle(color: _kMuted, fontSize: 12, height: 1.5),
              ),
            ])),
          ],
        ]),
      ),
    );
  }

  Widget _legendItem(String range, String label, Color color) =>
      Column(children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(height: 4),
        Text(range, style: const TextStyle(color: _kMuted, fontSize: 9)),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      ]);
}

class _GaugePainter extends CustomPainter {
  final double score;
  final Color color;
  const _GaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = math.min(cx, cy) - 10;

    // Background arc
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      bgPaint,
    );

    // Score arc
    if (score > 0) {
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        math.pi * 0.75,
        math.pi * 1.5 * score,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) =>
      oldDelegate.score != score || oldDelegate.color != color;
}
