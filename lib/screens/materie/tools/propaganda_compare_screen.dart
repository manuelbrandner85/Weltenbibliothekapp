import 'package:flutter/material.dart';
import '../../../services/ai_service.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/materie/osint_source_banner.dart';

// ─────────────────────────────────────────────────────────────────────────────
// M-X6 — Propaganda Quellen-Vergleich
// Zwei Texte (Quelle A / Quelle B) zum selben Thema werden parallel durch die
// bestehende Propaganda-Analyse geschickt und Seite an Seite verglichen.
// Nutzt den vorhandenen /ai/propaganda-Endpoint (mit lokalem Fallback) -- kein
// neuer Worker-Endpoint, um die Quota zu schonen.
// ─────────────────────────────────────────────────────────────────────────────

const _kBg = Color(0xFF0D0000);
const _kSurface = Color(0xFF1A0808);
const _kAccent = Color(0xFFE53935);
const _kText = Colors.white;
const _kMuted = Color(0xFFB0A0A0);
const _kBorder = Color(0x33E53935);

class PropagandaCompareScreen extends StatefulWidget {
  const PropagandaCompareScreen({super.key});

  @override
  State<PropagandaCompareScreen> createState() =>
      _PropagandaCompareScreenState();
}

class _PropagandaCompareScreenState extends State<PropagandaCompareScreen> {
  final _aCtrl = TextEditingController();
  final _bCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _a;
  Map<String, dynamic>? _b;

  @override
  void dispose() {
    _aCtrl.dispose();
    _bCtrl.dispose();
    super.dispose();
  }

  Future<void> _compare() async {
    final a = _aCtrl.text.trim();
    final b = _bCtrl.text.trim();
    if (a.length < 40 || b.length < 40) {
      setState(() => _error =
          'Bitte in beide Felder je einen laengeren Textausschnitt (min. '
          '40 Zeichen) einfuegen.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _a = null;
      _b = null;
    });
    try {
      final results = await Future.wait([
        AIService.analyzePropaganda(a),
        AIService.analyzePropaganda(b),
      ]);
      setState(() {
        _a = results[0];
        _b = results[1];
      });
    } catch (e) {
      setState(() => _error = 'Analyse fehlgeschlagen. Bitte erneut versuchen.');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Normalisierung (Worker- und Fallback-Shape unterscheiden sich) ──────────
  double? _score(Map<String, dynamic>? r) {
    final v = r?['propaganda_score'] ?? r?['biasScore'];
    return v is num ? v.toDouble() : null;
  }

  String _level(Map<String, dynamic>? r) {
    final lv = r?['level']?.toString();
    if (lv != null && lv.isNotEmpty) return lv;
    final s = _score(r);
    if (s == null) return '-';
    return s > 70 ? 'HOCH' : (s > 40 ? 'MODERAT' : 'NIEDRIG');
  }

  List<String> _techniques(Map<String, dynamic>? r) {
    final t = r?['techniques'];
    if (t is List) return t.map((e) => e.toString()).toList();
    if (t is Map) {
      return t.entries.map((e) => '${e.key}: ${e.value}').toList();
    }
    return const [];
  }

  Color _levelColor(String level) {
    switch (level.toUpperCase()) {
      case 'HOCH':
        return const Color(0xFFEF5350);
      case 'MODERAT':
        return const Color(0xFFFFB300);
      case 'NIEDRIG':
        return const Color(0xFF66BB6A);
      default:
        return _kMuted;
    }
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

  Widget _input(TextEditingController c, String label) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _kMuted, fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: c,
            style: const TextStyle(color: _kText, fontSize: 13),
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Artikel-Text einfuegen ...',
              hintStyle: TextStyle(color: _kMuted.withValues(alpha: 0.6)),
              filled: true,
              fillColor: _kBg,
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
        ],
      );

  Widget _sourcePanel(String title, Map<String, dynamic>? r) {
    final level = _level(r);
    final score = _score(r);
    final techs = _techniques(r);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _levelColor(level).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: _kText, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _levelColor(level).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(level,
                  style: TextStyle(
                      color: _levelColor(level),
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
            const Spacer(),
            if (score != null)
              Text('${score.round()}/100',
                  style: const TextStyle(color: _kMuted, fontSize: 12)),
          ]),
          if (techs.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('Techniken',
                style: TextStyle(color: _kMuted, fontSize: 11)),
            const SizedBox(height: 4),
            for (final t in techs)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text('- $t',
                    style: const TextStyle(color: _kText, fontSize: 12)),
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = _a != null && _b != null;
    final sa = _score(_a);
    final sb = _score(_b);
    String? diffText;
    if (ready && sa != null && sb != null) {
      final d = (sa - sb).abs().round();
      if (d < 10) {
        diffText = 'Beide Quellen zeigen ein aehnliches Propaganda-Niveau '
            '(Differenz $d Punkte).';
      } else {
        final higher = sa > sb ? 'Quelle A' : 'Quelle B';
        diffText = '$higher weist deutlich mehr Propaganda-Merkmale auf '
            '(Differenz $d Punkte).';
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      appBar: WBGlassAppBar(
        world: WBWorld.materie,
        titleWidget: Row(children: [
          const Icon(Icons.compare_rounded, color: _kAccent, size: 22),
          const SizedBox(width: 8),
          const Text('Propaganda-Vergleich',
              style: TextStyle(color: _kText, fontWeight: FontWeight.bold)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _card(Column(children: [
            _input(_aCtrl, 'Quelle A'),
            const SizedBox(height: 12),
            _input(_bCtrl, 'Quelle B'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _compare,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.compare_arrows_rounded, size: 18),
                label: Text(_loading ? 'Analysiere ...' : 'Quellen vergleichen'),
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
          const OsintSourceBanner(
            source: 'Zwei Texte zum selben Thema werden durch dieselbe '
                'KI-Analyse geschickt und gegenuebergestellt. Ergebnis ist '
                'eine Einschaetzung, kein Urteil.',
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
          if (ready) ...[
            if (diffText != null)
              _card(Row(children: [
                const Icon(Icons.insights_rounded, color: _kAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(diffText,
                        style: const TextStyle(
                            color: _kText, fontSize: 13, height: 1.4))),
              ])),
            _sourcePanel('Quelle A', _a),
            const SizedBox(height: 10),
            _sourcePanel('Quelle B', _b),
          ],
        ]),
      ),
    );
  }
}
