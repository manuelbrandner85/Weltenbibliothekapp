import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/materie/osint_source_banner.dart';

// ─────────────────────────────────────────────────────────────────────────────
// R-X10 — Konflikt-Datenbank
// Bewaffnete Konflikte, Proteste und Unruhen aus der ACLED-Datenbank.
// Laeuft ueber den Worker (ACLED_ACCESS_TOKEN + ACLED_EMAIL als Secrets).
// ─────────────────────────────────────────────────────────────────────────────

const _kBg = Color(0xFF0D0000);
const _kSurface = Color(0xFF1A0808);
const _kAccent = Color(0xFFE53935);
const _kText = Colors.white;
const _kMuted = Color(0xFFB0A0A0);
const _kBorder = Color(0x33E53935);

const _kCountries = [
  'Ukraine', 'Sudan', 'Syria', 'Yemen', 'Ethiopia', 'Myanmar',
  'Israel', 'Palestine', 'Democratic Republic of Congo',
  'Somalia', 'Afghanistan', 'Mali', 'Nigeria', 'Russia',
  'Haiti', 'Libya', 'Venezuela',
];

class ConflictDatabaseScreen extends StatefulWidget {
  const ConflictDatabaseScreen({super.key});

  @override
  State<ConflictDatabaseScreen> createState() => _ConflictDatabaseScreenState();
}

class _ConflictDatabaseScreenState extends State<ConflictDatabaseScreen> {
  String _country = 'Ukraine';
  bool _loading = false;
  bool _keyMissing = false;
  String? _error;
  List<Map<String, dynamic>> _events = [];
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _keyMissing = false;
    });
    try {
      final uri = Uri.parse(
          '${ApiConfig.workerUrl}/api/intel/conflict?country=${Uri.encodeComponent(_country)}&limit=50');
      final resp = await http.get(uri).timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['key_missing'] == true) {
        if (mounted) setState(() => _keyMissing = true);
        return;
      }
      final list = (data['events'] as List?) ?? const [];
      if (!mounted) return;
      setState(() {
        _events = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        _total = data['count'] as int? ?? _events.length;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Abruf fehlgeschlagen. Bitte erneut versuchen.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _typeColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('battle') || t.contains('violence')) return _kAccent;
    if (t.contains('explosion') || t.contains('remote')) return const Color(0xFFFF7043);
    if (t.contains('protest')) return const Color(0xFFFFB300);
    if (t.contains('riot')) return const Color(0xFFFF9800);
    return const Color(0xFF4CAF50);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      appBar: WBGlassAppBar(
        world: WBWorld.materie,
        titleWidget: Row(children: const [
          Icon(Icons.shield_outlined, color: _kAccent, size: 22),
          SizedBox(width: 8),
          Text('Konflikt-Datenbank',
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
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Land / Region',
                style: TextStyle(color: _kMuted, fontSize: 12)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
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
                for (final c in _kCountries)
                  DropdownMenuItem(value: c, child: Text(c)),
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
            source: 'Bewaffnete Konflikte, Proteste und Unruhen aus dem '
                'Armed Conflict Location & Event Data Project (ACLED). '
                'Echtzeitdaten von akademischen Analysten weltweit.',
            accent: _kAccent,
            sources: [OsintSource('ACLED', 'https://acleddata.com')],
          ),
          if (_keyMissing)
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.key_off_rounded, color: Color(0xFFFFB300), size: 18),
                SizedBox(width: 8),
                Text('API-Key nicht konfiguriert',
                    style: TextStyle(
                        color: Color(0xFFFFB300),
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ]),
              const SizedBox(height: 8),
              const Text(
                'Fuer diese Funktion werden kostenlose ACLED-Researcher-Keys '
                'benoetigt. Setze ACLED_ACCESS_TOKEN und ACLED_EMAIL als '
                'Wrangler-Secrets:\n\n'
                'npx wrangler secret put ACLED_ACCESS_TOKEN\n'
                'npx wrangler secret put ACLED_EMAIL\n\n'
                'Kostenlose Registrierung unter acleddata.com.',
                style: TextStyle(color: _kMuted, fontSize: 12, height: 1.5),
              ),
            ]))
          else if (_loading)
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
          else ...[
            if (_total > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 2),
                child: Text('$_total Ereignisse gefunden (letzte 50)',
                    style: const TextStyle(color: _kMuted, fontSize: 12)),
              ),
            ..._events.map(_eventCard),
          ],
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

  Widget _eventCard(Map<String, dynamic> e) {
    final type = (e['event_type'] ?? '').toString();
    final sub = (e['sub_event_type'] ?? '').toString();
    final loc = (e['location'] ?? '').toString();
    final date = (e['event_date'] ?? '').toString();
    final fat = e['fatalities']?.toString() ?? '0';
    final notes = (e['notes'] ?? '').toString();
    final c = _typeColor(type);
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(type.isNotEmpty ? type : 'Unbekannt',
              style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        const Spacer(),
        Text(date,
            style: const TextStyle(color: _kMuted, fontSize: 11)),
      ]),
      if (sub.isNotEmpty) ...[
        const SizedBox(height: 4),
        Text(sub, style: const TextStyle(color: _kMuted, fontSize: 11)),
      ],
      const SizedBox(height: 6),
      Row(children: [
        const Icon(Icons.place_outlined, color: _kMuted, size: 13),
        const SizedBox(width: 4),
        Expanded(
          child: Text(loc,
              style: const TextStyle(color: _kText, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        if (fat != '0') ...[
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF7043), size: 13),
          const SizedBox(width: 3),
          Text('$fat', style: const TextStyle(color: Color(0xFFFF7043), fontSize: 12)),
        ],
      ]),
      if (notes.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(
          notes.length > 200 ? '${notes.substring(0, 200)}...' : notes,
          style: const TextStyle(color: _kMuted, fontSize: 12, height: 1.4),
        ),
      ],
    ]));
  }
}
