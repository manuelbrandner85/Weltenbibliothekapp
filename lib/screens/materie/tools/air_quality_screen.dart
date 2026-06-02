import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/materie/osint_source_banner.dart';
import '../../../utils/osint_result_share.dart';

// ─────────────────────────────────────────────────────────────────────────────
// R-X12 — Luftqualitaet
// Messstationen weltweit mit aktuellen Sensorwerten (PM2.5, NO2, O3 u.a.)
// ueber die OpenAQ v3 API. Laeuft ueber den Worker (OPENAQ_API_KEY als Secret).
// ─────────────────────────────────────────────────────────────────────────────

const _kBg = Color(0xFF0D0000);
const _kSurface = Color(0xFF1A0808);
const _kAccent = Color(0xFF66BB6A);
const _kText = Colors.white;
const _kMuted = Color(0xFFB0A0A0);
const _kBorder = Color(0x3366BB6A);

class AirQualityScreen extends StatefulWidget {
  const AirQualityScreen({super.key});

  @override
  State<AirQualityScreen> createState() => _AirQualityScreenState();
}

class _AirQualityScreenState extends State<AirQualityScreen> {
  final _cityCtrl = TextEditingController();
  bool _loading = false;
  bool _keyMissing = false;
  String? _error;
  List<Map<String, dynamic>> _stations = [];

  @override
  void initState() {
    super.initState();
    _search('Berlin');
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String city) async {
    setState(() {
      _loading = true;
      _error = null;
      _keyMissing = false;
    });
    try {
      final uri = Uri.parse(
          '${ApiConfig.workerUrl}/api/intel/airquality?city=${Uri.encodeComponent(city)}&limit=30');
      final resp = await http.get(uri).timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['key_missing'] == true) {
        if (mounted) setState(() => _keyMissing = true);
        return;
      }
      final list = (data['results'] as List?) ?? const [];
      if (!mounted) return;
      if (list.isEmpty) {
        setState(() => _error = 'Keine Stationen fuer diese Stadt gefunden.');
      } else {
        setState(() => _stations =
            list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList());
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Abruf fehlgeschlagen. Bitte erneut versuchen.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic>? get _shareResult {
    if (_stations.isEmpty) return null;
    return {
      'Stadt': _cityCtrl.text.trim(),
      'Stationen': _stations.map((s) => {
            'Name': s['name'],
            'Land': s['country'],
            'Letzte Messung': s['lastUpdated'],
            'Sensoren': (s['sensors'] as List?)
                    ?.map((x) => '${x['parameter']} (${x['unit']})')
                    .join(', ') ??
                '',
          }).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      appBar: WBGlassAppBar(
        world: WBWorld.materie,
        titleWidget: Row(children: const [
          Icon(Icons.air_rounded, color: _kAccent, size: 22),
          SizedBox(width: 8),
          Text('Luftqualitaet',
              style: TextStyle(color: _kText, fontWeight: FontWeight.bold)),
        ]),
        actions: [
          OsintResultShare.actionButton(
            context,
            toolName: 'Luftqualitaet',
            query: _cityCtrl.text,
            result: _shareResult,
            color: _kAccent,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Stadt',
                style: TextStyle(color: _kMuted, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _cityCtrl,
              style: const TextStyle(color: _kText),
              decoration: InputDecoration(
                hintText: 'z.B. Berlin, Tokyo, Cairo',
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
              onSubmitted: (v) {
                final c = v.trim();
                if (c.isNotEmpty) _search(c);
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading
                    ? null
                    : () {
                        final c = _cityCtrl.text.trim();
                        if (c.isNotEmpty) _search(c);
                      },
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.air_rounded, size: 18),
                label: const Text('Messstationen suchen'),
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
            source: 'Messstationen und Sensorwerte aus der OpenAQ-Plattform '
                '(offene Luft-Messdaten weltweit). PM2.5 und PM10 = '
                'Feinstaubwerte, NO2 = Stickstoffdioxid, O3 = Ozon.',
            accent: _kAccent,
            sources: [OsintSource('OpenAQ', 'https://openaq.org')],
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
                'Kostenloser OpenAQ-Account unter explore.openaq.org, dann:\n\n'
                'npx wrangler secret put OPENAQ_API_KEY',
                style: TextStyle(color: _kMuted, fontSize: 12, height: 1.5),
              ),
            ]))
          else if (_error != null)
            _card(Row(children: [
              const Icon(Icons.error_outline, color: _kAccent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(_error!,
                      style: const TextStyle(color: _kAccent, fontSize: 13))),
            ]))
          else
            ..._stations.map(_stationCard),
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

  Widget _stationCard(Map<String, dynamic> s) {
    final name = (s['name'] ?? '').toString();
    final city = (s['city'] ?? '').toString();
    final country = (s['country'] ?? '').toString();
    final updated = (s['lastUpdated'] ?? '').toString();
    final sensors = (s['sensors'] as List?) ?? const [];
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.sensors_rounded, color: _kAccent, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(name,
              style: const TextStyle(
                  color: _kText, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ]),
      const SizedBox(height: 4),
      Text(
        [city, country].where((e) => e.isNotEmpty).join(', '),
        style: const TextStyle(color: _kMuted, fontSize: 12),
      ),
      if (updated.isNotEmpty) ...[
        const SizedBox(height: 2),
        Text('Letzte Messung: $updated',
            style: const TextStyle(color: _kMuted, fontSize: 11)),
      ],
      if (sensors.isNotEmpty) ...[
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final sensor in sensors)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _kAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kAccent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${sensor['parameter']}${sensor['unit'].toString().isNotEmpty ? ' (${sensor['unit']})' : ''}',
                  style: const TextStyle(color: _kAccent, fontSize: 11),
                ),
              ),
          ],
        ),
      ],
    ]));
  }
}
