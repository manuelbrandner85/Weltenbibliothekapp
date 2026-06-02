import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/materie/osint_source_banner.dart';

// ─────────────────────────────────────────────────────────────────────────────
// R-X3 — Prognose-Maerkte
// Was wettet die Crowd auf geopolitische Ereignisse? Live-Wahrscheinlichkeiten
// und Handelsvolumen aus Polymarket. Kostenlos, ohne API-Key.
// ─────────────────────────────────────────────────────────────────────────────

const _kBg = Color(0xFF0D0000);
const _kSurface = Color(0xFF1A0808);
const _kAccent = Color(0xFF7E57C2);
const _kText = Colors.white;
const _kMuted = Color(0xFFB0A0A0);
const _kBorder = Color(0x337E57C2);

class _Market {
  const _Market({
    required this.question,
    required this.topOutcome,
    required this.topProb,
    required this.volume,
    required this.slug,
  });
  final String question;
  final String topOutcome;
  final double topProb; // 0..1
  final double volume;
  final String slug;
}

class PredictionMarketsScreen extends StatefulWidget {
  const PredictionMarketsScreen({super.key});

  @override
  State<PredictionMarketsScreen> createState() =>
      _PredictionMarketsScreenState();
}

class _PredictionMarketsScreenState extends State<PredictionMarketsScreen> {
  bool _loading = false;
  String? _error;
  List<_Market> _markets = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse(
          'https://gamma-api.polymarket.com/markets?closed=false&active=true&order=volume&ascending=false&limit=40');
      final resp = await http.get(uri).timeout(const Duration(seconds: 25));
      if (resp.statusCode != 200) {
        throw Exception('HTTP ${resp.statusCode}');
      }
      final decoded = jsonDecode(resp.body);
      final list = decoded is List ? decoded : const [];
      final out = <_Market>[];
      for (final m in list) {
        if (m is! Map) continue;
        final outcomes = _decodeStringList(m['outcomes']);
        final prices = _decodeStringList(m['outcomePrices']);
        if (outcomes.isEmpty || prices.isEmpty) continue;
        // Find highest-probability outcome
        var bestIdx = 0;
        var bestProb = 0.0;
        for (var i = 0; i < prices.length && i < outcomes.length; i++) {
          final p = double.tryParse(prices[i]) ?? 0;
          if (p > bestProb) {
            bestProb = p;
            bestIdx = i;
          }
        }
        out.add(_Market(
          question: (m['question'] ?? '').toString(),
          topOutcome: outcomes[bestIdx],
          topProb: bestProb,
          volume: double.tryParse((m['volume'] ?? '0').toString()) ?? 0,
          slug: (m['slug'] ?? '').toString(),
        ));
      }
      if (!mounted) return;
      setState(() => _markets = out);
    } catch (_) {
      if (mounted) setState(() => _error = 'Abruf fehlgeschlagen. Bitte erneut versuchen.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> _decodeStringList(dynamic raw) {
    if (raw == null) return const [];
    try {
      if (raw is String) {
        final d = jsonDecode(raw);
        if (d is List) return d.map((e) => e.toString()).toList();
      } else if (raw is List) {
        return raw.map((e) => e.toString()).toList();
      }
    } catch (_) {/* ignore */}
    return const [];
  }

  String _fmtVolume(double v) {
    if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '\$${(v / 1e3).toStringAsFixed(1)}K';
    return '\$${v.toStringAsFixed(0)}';
  }

  Future<void> _open(String slug) async {
    if (slug.isEmpty) return;
    final uri = Uri.parse('https://polymarket.com/event/$slug');
    if (await canLaunchUrl(uri)) {
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
          Icon(Icons.trending_up_rounded, color: _kAccent, size: 22),
          SizedBox(width: 8),
          Text('Prognose-Maerkte',
              style: TextStyle(color: _kText, fontWeight: FontWeight.bold)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _kAccent),
            tooltip: 'Aktualisieren',
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const OsintSourceBanner(
            source: 'Aktive Wett-Maerkte nach Handelsvolumen sortiert. Die '
                'Wahrscheinlichkeit ergibt sich aus dem Marktpreis - sie ist '
                'eine Crowd-Schaetzung, keine Gewissheit.',
            accent: _kAccent,
            sources: [OsintSource('Polymarket', 'https://polymarket.com')],
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator(color: _kAccent)),
            )
          else if (_error != null)
            _card(Row(children: [
              const Icon(Icons.error_outline, color: _kAccent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(_error!,
                      style: const TextStyle(color: _kAccent, fontSize: 13))),
            ]))
          else if (_markets.isEmpty)
            _card(const Text('Keine aktiven Maerkte gefunden.',
                style: TextStyle(color: _kMuted, fontSize: 13)))
          else
            ..._markets.map(_marketCard),
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

  Widget _marketCard(_Market m) {
    final pct = (m.topProb * 100).clamp(0, 100).toStringAsFixed(0);
    final probColor = m.topProb >= 0.66
        ? const Color(0xFF4CAF50)
        : m.topProb >= 0.4
            ? const Color(0xFFFFC107)
            : _kAccent;
    return GestureDetector(
      onTap: () => _open(m.slug),
      child: _card(
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m.question,
              style: const TextStyle(
                  color: _kText, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(children: [
            Text('$pct%',
                style: TextStyle(
                    color: probColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(m.topOutcome,
                  style: const TextStyle(color: _kMuted, fontSize: 13),
                  overflow: TextOverflow.ellipsis),
            ),
            const Icon(Icons.bar_chart_rounded, color: _kMuted, size: 14),
            const SizedBox(width: 4),
            Text(_fmtVolume(m.volume),
                style: const TextStyle(color: _kMuted, fontSize: 12)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: m.topProb.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: _kBg,
              valueColor: AlwaysStoppedAnimation(probColor),
            ),
          ),
        ]),
      ),
    );
  }
}
