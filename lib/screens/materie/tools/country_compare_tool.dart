import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/materie/osint_source_banner.dart';
import '../../../utils/osint_result_share.dart';

// ─────────────────────────────────────────────────────────────────────────────
// M-X7 — Laender-Vergleich (Bevoelkerung, Flaeche, Gini, Sprachen, Waehrung)
// Datenquelle: restcountries.com v3.1 (kostenlos, kein API-Key).
// ─────────────────────────────────────────────────────────────────────────────

const _kBg = Color(0xFF0D0000);
const _kSurface = Color(0xFF1A0808);
const _kAccent = Color(0xFFE53935);
const _kText = Colors.white;
const _kMuted = Color(0xFFB0A0A0);
const _kBorder = Color(0x33E53935);

class CountryCompareTool extends StatefulWidget {
  const CountryCompareTool({super.key});

  @override
  State<CountryCompareTool> createState() => _CountryCompareToolState();
}

class _CountryCompareToolState extends State<CountryCompareTool> {
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

  Future<Map<String, dynamic>> _fetch(String name) async {
    final uri = Uri.parse(
        'https://restcountries.com/v3.1/name/${Uri.encodeComponent(name)}'
        '?fields=name,population,area,capital,region,subregion,flags,'
        'currencies,languages,gini,timezones');
    final resp = await http.get(uri).timeout(const Duration(seconds: 20));
    if (resp.statusCode != 200) {
      throw Exception('Land "$name" nicht gefunden');
    }
    final list = jsonDecode(resp.body) as List;
    if (list.isEmpty) throw Exception('Land "$name" nicht gefunden');
    return (list.first as Map<String, dynamic>);
  }

  Future<void> _compare() async {
    final a = _aCtrl.text.trim();
    final b = _bCtrl.text.trim();
    if (a.isEmpty || b.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _a = null;
      _b = null;
    });
    try {
      final results = await Future.wait([_fetch(a), _fetch(b)]);
      setState(() {
        _a = results[0];
        _b = results[1];
      });
    } catch (e) {
      setState(() => _error = 'Ein Land wurde nicht gefunden. Englischer '
          'Name funktioniert am besten (z.B. "Germany").');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Feld-Extraktoren ──────────────────────────────────────────────────────
  String _commonName(Map<String, dynamic>? c) =>
      (c?['name'] as Map?)?['common']?.toString() ?? '-';

  String _flagEmoji(Map<String, dynamic>? c) =>
      (c?['flags'] as Map?)?['emoji']?.toString() ?? '';

  String _population(Map<String, dynamic>? c) {
    final p = c?['population'];
    return p is num ? _grouped(p.toInt()) : '-';
  }

  String _area(Map<String, dynamic>? c) {
    final a = c?['area'];
    return a is num ? '${_grouped(a.round())} km2' : '-';
  }

  String _density(Map<String, dynamic>? c) {
    final p = c?['population'];
    final a = c?['area'];
    if (p is num && a is num && a > 0) {
      return '${(p / a).toStringAsFixed(1)} /km2';
    }
    return '-';
  }

  String _capital(Map<String, dynamic>? c) {
    final cap = c?['capital'];
    return (cap is List && cap.isNotEmpty) ? cap.join(', ') : '-';
  }

  String _region(Map<String, dynamic>? c) {
    final r = c?['region']?.toString() ?? '';
    final s = c?['subregion']?.toString() ?? '';
    if (r.isEmpty) return '-';
    return s.isEmpty ? r : '$r / $s';
  }

  String _currencies(Map<String, dynamic>? c) {
    final cur = c?['currencies'];
    if (cur is! Map || cur.isEmpty) return '-';
    return cur.entries.map((e) {
      final name = (e.value as Map?)?['name']?.toString() ?? e.key;
      return '$name (${e.key})';
    }).join(', ');
  }

  String _languages(Map<String, dynamic>? c) {
    final lang = c?['languages'];
    if (lang is! Map || lang.isEmpty) return '-';
    return lang.values.map((v) => v.toString()).join(', ');
  }

  String _gini(Map<String, dynamic>? c) {
    final g = c?['gini'];
    if (g is! Map || g.isEmpty) return '-';
    // Neuestes verfuegbares Jahr.
    final years = g.keys.map((k) => k.toString()).toList()..sort();
    final latest = years.last;
    return '${g[latest]} (${latest})';
  }

  String _grouped(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Map<String, dynamic>? get _shareResult {
    if (_a == null || _b == null) return null;
    return {
      _commonName(_a): {
        'Bevoelkerung': _population(_a),
        'Flaeche': _area(_a),
        'Dichte': _density(_a),
        'Hauptstadt': _capital(_a),
        'Region': _region(_a),
        'Gini': _gini(_a),
      },
      _commonName(_b): {
        'Bevoelkerung': _population(_b),
        'Flaeche': _area(_b),
        'Dichte': _density(_b),
        'Hauptstadt': _capital(_b),
        'Region': _region(_b),
        'Gini': _gini(_b),
      },
    };
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

  Widget _input(TextEditingController ctrl, String hint) => TextField(
        controller: ctrl,
        style: const TextStyle(color: _kText),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: _kMuted.withValues(alpha: 0.6)),
          isDense: true,
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
        onSubmitted: (_) => _compare(),
      );

  Widget _compareRow(String label, String va, String vb) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  color: _kMuted,
                  fontSize: 10,
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Text(va,
                    style: const TextStyle(color: _kText, fontSize: 13))),
            const SizedBox(width: 12),
            Expanded(
                child: Text(vb,
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: _kText, fontSize: 13))),
          ]),
          const SizedBox(height: 6),
          Container(height: 1, color: _kBorder),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = _a != null && _b != null;
    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      appBar: WBGlassAppBar(
        world: WBWorld.materie,
        titleWidget: Row(children: [
          const Icon(Icons.public_rounded, color: _kAccent, size: 22),
          const SizedBox(width: 8),
          const Text('Laender-Vergleich',
              style: TextStyle(color: _kText, fontWeight: FontWeight.bold)),
        ]),
        actions: [
          OsintResultShare.actionButton(
            context,
            toolName: 'Laender-Vergleich',
            query: '${_aCtrl.text} vs ${_bCtrl.text}',
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
            const Text('Zwei Laender vergleichen',
                style: TextStyle(color: _kMuted, fontSize: 12)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _input(_aCtrl, 'Germany')),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child:
                    Text('vs', style: TextStyle(color: _kMuted, fontSize: 12)),
              ),
              Expanded(child: _input(_bCtrl, 'France')),
            ]),
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
                label: const Text('Vergleichen'),
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
            source: 'Faktendaten (Bevoelkerung, Flaeche, Gini-Index, Sprachen, '
                'Waehrung) ueber restcountries.com.',
            accent: _kAccent,
            sources: [
              OsintSource('restcountries.com', 'https://restcountries.com')
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
          if (ready)
            _card(
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Row(children: [
                    Text(_flagEmoji(_a), style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(_commonName(_a),
                          style: const TextStyle(
                              color: _kText,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                    ),
                  ]),
                ),
                Expanded(
                  child:
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Expanded(
                      child: Text(_commonName(_b),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              color: _kText,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 6),
                    Text(_flagEmoji(_b), style: const TextStyle(fontSize: 22)),
                  ]),
                ),
              ]),
              const SizedBox(height: 12),
              _compareRow('Bevoelkerung', _population(_a), _population(_b)),
              _compareRow('Flaeche', _area(_a), _area(_b)),
              _compareRow('Dichte', _density(_a), _density(_b)),
              _compareRow('Hauptstadt', _capital(_a), _capital(_b)),
              _compareRow('Region', _region(_a), _region(_b)),
              _compareRow('Gini-Index', _gini(_a), _gini(_b)),
              _compareRow('Waehrung', _currencies(_a), _currencies(_b)),
              _compareRow('Sprachen', _languages(_a), _languages(_b)),
            ])),
        ]),
      ),
    );
  }
}
