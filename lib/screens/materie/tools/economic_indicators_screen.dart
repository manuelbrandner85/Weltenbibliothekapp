import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/materie/osint_source_banner.dart';
import '../../../utils/osint_result_share.dart';

// ─────────────────────────────────────────────────────────────────────────────
// R-X8 — Wirtschafts-Indikatoren
// Inflation, BIP, Arbeitslosigkeit u.a. pro Land aus der Weltbank-Datenbank.
// Kostenlos, ohne API-Key.
// ─────────────────────────────────────────────────────────────────────────────

const _kBg = Color(0xFF0D0000);
const _kSurface = Color(0xFF1A0808);
const _kAccent = Color(0xFF26C6DA);
const _kText = Colors.white;
const _kMuted = Color(0xFFB0A0A0);
const _kBorder = Color(0x3326C6DA);

class _Country {
  const _Country(this.name, this.iso2);
  final String name;
  final String iso2;
}

const _countries = [
  _Country('Deutschland', 'DE'),
  _Country('Oesterreich', 'AT'),
  _Country('Schweiz', 'CH'),
  _Country('USA', 'US'),
  _Country('China', 'CN'),
  _Country('Russland', 'RU'),
  _Country('Frankreich', 'FR'),
  _Country('Italien', 'IT'),
  _Country('Spanien', 'ES'),
  _Country('Vereinigtes Koenigreich', 'GB'),
  _Country('Japan', 'JP'),
  _Country('Indien', 'IN'),
  _Country('Brasilien', 'BR'),
  _Country('Tuerkei', 'TR'),
  _Country('Ukraine', 'UA'),
  _Country('Polen', 'PL'),
  _Country('Niederlande', 'NL'),
  _Country('Kanada', 'CA'),
  _Country('Australien', 'AU'),
  _Country('Suedafrika', 'ZA'),
];

class _Indicator {
  const _Indicator(this.code, this.label, this.unit, {this.fractionDigits = 1});
  final String code;
  final String label;
  final String unit;
  final int fractionDigits;
}

const _indicators = [
  _Indicator('FP.CPI.TOTL.ZG', 'Inflation', '%'),
  _Indicator('NY.GDP.MKTP.CD', 'BIP', 'USD', fractionDigits: 0),
  _Indicator('NY.GDP.PCAP.CD', 'BIP pro Kopf', 'USD', fractionDigits: 0),
  _Indicator('SL.UEM.TOTL.ZS', 'Arbeitslosigkeit', '%'),
  _Indicator('SP.POP.TOTL', 'Bevoelkerung', '', fractionDigits: 0),
  _Indicator('SP.DYN.LE00.IN', 'Lebenserwartung', 'Jahre'),
];

class EconomicIndicatorsScreen extends StatefulWidget {
  const EconomicIndicatorsScreen({super.key});

  @override
  State<EconomicIndicatorsScreen> createState() =>
      _EconomicIndicatorsScreenState();
}

class _EconomicIndicatorsScreenState extends State<EconomicIndicatorsScreen> {
  _Country _country = _countries.first;
  bool _loading = false;
  String? _error;
  // label -> (valueString, year)
  final Map<String, (String, String)> _values = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _values.clear();
    });
    try {
      final fetches = _indicators.map((ind) => _fetchOne(ind)).toList();
      await Future.wait(fetches);
      if (!mounted) return;
      if (_values.isEmpty) {
        setState(() => _error = 'Keine Daten fuer dieses Land verfuegbar.');
      }
    } catch (_) {
      if (mounted)
        setState(
            () => _error = 'Abruf fehlgeschlagen. Bitte erneut versuchen.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchOne(_Indicator ind) async {
    try {
      final uri = Uri.parse(
          'https://api.worldbank.org/v2/country/${_country.iso2}/indicator/${ind.code}?format=json&mrv=8');
      final resp = await http.get(uri).timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) return;
      final decoded = jsonDecode(resp.body);
      if (decoded is! List || decoded.length < 2 || decoded[1] is! List) return;
      for (final row in decoded[1] as List) {
        if (row is! Map) continue;
        final v = row['value'];
        if (v is num) {
          _values[ind.label] =
              (_format(v.toDouble(), ind), (row['date'] ?? '').toString());
          return; // most recent non-null
        }
      }
    } catch (_) {/* skip indicator */}
  }

  String _format(double v, _Indicator ind) {
    String num;
    if (ind.fractionDigits == 0) {
      num = _thousands(v.round());
    } else {
      num = v.toStringAsFixed(ind.fractionDigits);
    }
    return ind.unit.isEmpty ? num : '$num ${ind.unit}';
  }

  String _thousands(int v) {
    final s = v.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return (v < 0 ? '-' : '') + buf.toString();
  }

  Map<String, dynamic>? get _shareResult {
    if (_values.isEmpty) return null;
    final out = <String, dynamic>{'Land': _country.name};
    _values.forEach((k, v) => out[k] = '${v.$1} (${v.$2})');
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      appBar: WBGlassAppBar(
        world: WBWorld.materie,
        titleWidget: Row(children: const [
          Icon(Icons.query_stats_rounded, color: _kAccent, size: 22),
          SizedBox(width: 8),
          Text('Wirtschafts-Indikatoren',
              style: TextStyle(color: _kText, fontWeight: FontWeight.bold)),
        ]),
        actions: [
          OsintResultShare.actionButton(
            context,
            toolName: 'Wirtschaft',
            query: _country.name,
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
            const Text('Land', style: TextStyle(color: _kMuted, fontSize: 12)),
            const SizedBox(height: 8),
            DropdownButtonFormField<_Country>(
              value: _country,
              dropdownColor: _kSurface,
              style: const TextStyle(color: _kText, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: _kBg,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _kBorder)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _kBorder)),
              ),
              items: [
                for (final c in _countries)
                  DropdownMenuItem(value: c, child: Text(c.name)),
              ],
              onChanged: (c) {
                if (c != null) {
                  setState(() => _country = c);
                  _load();
                }
              },
            ),
          ])),
          const OsintSourceBanner(
            source: 'Offizielle Entwicklungs-Indikatoren der Weltbank. Werte '
                'sind die jeweils aktuellsten verfuegbaren Jahresdaten - je '
                'nach Land mit Verzoegerung.',
            accent: _kAccent,
            sources: [OsintSource('World Bank', 'https://data.worldbank.org')],
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
          else
            for (final ind in _indicators)
              if (_values.containsKey(ind.label)) _valueCard(ind),
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

  Widget _valueCard(_Indicator ind) {
    final v = _values[ind.label]!;
    return _card(Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ind.label, style: const TextStyle(color: _kMuted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(v.$1,
              style: const TextStyle(
                  color: _kText, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
      ),
      Text(v.$2, style: const TextStyle(color: _kMuted, fontSize: 12)),
    ]));
  }
}
