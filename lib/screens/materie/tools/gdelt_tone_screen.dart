import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/materie/osint_source_banner.dart';
import '../../../utils/osint_result_share.dart';

// ─────────────────────────────────────────────────────────────────────────────
// R-X2 — GDELT Medien-Tonalitaet
// Weltweite Nachrichten-Ereignisse zu einem Thema, plus durchschnittliche
// Tonalitaet (positiv/negativ). Quelle: GDELT 2.0 Doc API, kostenlos ohne Key.
// ─────────────────────────────────────────────────────────────────────────────

const _kBg = Color(0xFF0D0000);
const _kSurface = Color(0xFF1A0808);
const _kAccent = Color(0xFFFF7043);
const _kText = Colors.white;
const _kMuted = Color(0xFFB0A0A0);
const _kBorder = Color(0x33FF7043);

class GdeltToneScreen extends StatefulWidget {
  const GdeltToneScreen({super.key});

  @override
  State<GdeltToneScreen> createState() => _GdeltToneScreenState();
}

class _GdeltToneScreenState extends State<GdeltToneScreen> {
  final _queryCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  double? _avgTone;
  List<Map<String, dynamic>> _articles = [];

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _queryCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _articles = [];
      _avgTone = null;
    });
    try {
      final enc = Uri.encodeQueryComponent(q);
      final artUri = Uri.parse(
          'https://api.gdeltproject.org/api/v2/doc/doc?query=$enc&mode=ArtList&format=json&maxrecords=30&sort=DateDesc');
      final toneUri = Uri.parse(
          'https://api.gdeltproject.org/api/v2/doc/doc?query=$enc&mode=ToneChart&format=json');
      final resp = await Future.wait([
        http.get(artUri).timeout(const Duration(seconds: 25)),
        http.get(toneUri).timeout(const Duration(seconds: 25)),
      ]);

      final articles = <Map<String, dynamic>>[];
      if (resp[0].statusCode == 200 && resp[0].body.trim().startsWith('{')) {
        final data = jsonDecode(resp[0].body) as Map<String, dynamic>;
        for (final a in (data['articles'] as List?) ?? const []) {
          if (a is Map) articles.add(Map<String, dynamic>.from(a));
        }
      }

      double? avg;
      if (resp[1].statusCode == 200 && resp[1].body.trim().startsWith('{')) {
        final data = jsonDecode(resp[1].body) as Map<String, dynamic>;
        final bins = (data['tonechart'] as List?) ?? const [];
        double sum = 0, count = 0;
        for (final b in bins) {
          if (b is! Map) continue;
          final bin = (b['bin'] as num?)?.toDouble();
          final c = (b['count'] as num?)?.toDouble();
          if (bin != null && c != null) {
            sum += bin * c;
            count += c;
          }
        }
        if (count > 0) avg = sum / count;
      }

      if (!mounted) return;
      if (articles.isEmpty) {
        setState(() => _error = 'Keine Treffer. Anderes Stichwort versuchen.');
      } else {
        setState(() {
          _articles = articles;
          _avgTone = avg;
        });
      }
    } catch (_) {
      if (mounted)
        setState(
            () => _error = 'Abfrage fehlgeschlagen. Bitte erneut versuchen.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic>? get _shareResult {
    if (_articles.isEmpty) return null;
    return {
      'Thema': _queryCtrl.text.trim(),
      'Durchschnitts-Tonalitaet':
          _avgTone != null ? _avgTone!.toStringAsFixed(2) : 'n/a',
      'Bewertung': _toneLabel(_avgTone),
      'Artikel-Anzahl': _articles.length,
      'Schlagzeilen': _articles
          .take(10)
          .map((a) => '${a['title']} (${a['domain']})')
          .toList(),
    };
  }

  String _toneLabel(double? t) {
    if (t == null) return 'unbekannt';
    if (t <= -5) return 'stark negativ';
    if (t < -1) return 'negativ';
    if (t <= 1) return 'neutral';
    if (t < 5) return 'positiv';
    return 'stark positiv';
  }

  Color _toneColor(double? t) {
    if (t == null) return _kMuted;
    if (t < -1) return _kAccent;
    if (t <= 1) return const Color(0xFFFFC107);
    return const Color(0xFF4CAF50);
  }

  String _fmtDate(String? raw) {
    if (raw == null || raw.length < 8) return '';
    // GDELT seendate: 20240115T120000Z
    final y = raw.substring(0, 4);
    final m = raw.substring(4, 6);
    final d = raw.substring(6, 8);
    return '$d.$m.$y';
  }

  Future<void> _open(String? url) async {
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      appBar: WBGlassAppBar(
        world: WBWorld.materie,
        titleWidget: Row(children: const [
          Icon(Icons.insights_rounded, color: _kAccent, size: 22),
          SizedBox(width: 8),
          Text('Medien-Tonalitaet',
              style: TextStyle(color: _kText, fontWeight: FontWeight.bold)),
        ]),
        actions: [
          OsintResultShare.actionButton(
            context,
            toolName: 'GDELT-Tonalitaet',
            query: _queryCtrl.text,
            result: _shareResult,
            color: _kAccent,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Thema / Stichwort',
                style: TextStyle(color: _kMuted, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _queryCtrl,
              style: const TextStyle(color: _kText),
              decoration: InputDecoration(
                hintText: 'z.B. inflation, ukraine, climate',
                hintStyle: TextStyle(color: _kMuted.withValues(alpha: 0.6)),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: _kMuted, size: 18),
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
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _search,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.analytics_rounded, size: 18),
                label: const Text('Medien analysieren'),
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
            source: 'Weltweite Nachrichten und ihre Tonalitaet aus der GDELT-'
                'Datenbank (ueberwacht Medien in 100+ Sprachen in Echtzeit). '
                'Tonalitaet von negativ bis positiv gemittelt.',
            accent: _kAccent,
            sources: [
              OsintSource('GDELT Project', 'https://www.gdeltproject.org')
            ],
          ),
          if (_error != null)
            _card(Row(children: [
              const Icon(Icons.error_outline, color: _kAccent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(_error!,
                      style: const TextStyle(color: _kAccent, fontSize: 13))),
            ])),
          if (_avgTone != null)
            _card(
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('DURCHSCHNITTS-TONALITAET',
                  style: TextStyle(
                      color: _kMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Row(children: [
                Text(_avgTone!.toStringAsFixed(2),
                    style: TextStyle(
                        color: _toneColor(_avgTone),
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _toneColor(_avgTone).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_toneLabel(_avgTone),
                      style: TextStyle(
                          color: _toneColor(_avgTone),
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 6),
              const Text('Skala: -10 (sehr negativ) bis +10 (sehr positiv)',
                  style: TextStyle(color: _kMuted, fontSize: 11)),
            ])),
          for (final a in _articles) _articleCard(a),
        ]),
      ),
    );
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

  Widget _articleCard(Map<String, dynamic> a) => GestureDetector(
        onTap: () => _open(a['url']?.toString()),
        child: _card(
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text((a['title'] ?? '').toString(),
                style: const TextStyle(
                    color: _kText, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.language_rounded, color: _kMuted, size: 12),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  [
                    a['domain'],
                    a['sourcecountry'],
                    _fmtDate(a['seendate']?.toString())
                  ]
                      .where((e) => e != null && e.toString().isNotEmpty)
                      .join('  -  '),
                  style: const TextStyle(color: _kMuted, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.open_in_new, color: _kMuted, size: 12),
            ]),
          ]),
        ),
      );
}
