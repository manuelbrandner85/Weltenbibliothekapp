import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/materie/osint_source_banner.dart';

// ─────────────────────────────────────────────────────────────────────────────
// R-X11 — Waldbrand-Satelliten-Daten
// Thermische Hotspots (VIIRS SNPP) aus der NASA FIRMS-Datenbank.
// Laeuft ueber den Worker (NASA_FIRMS_API_KEY als Secret).
// ─────────────────────────────────────────────────────────────────────────────

const _kSurface = Color(0xFF1A0808);
const _kAccent = Color(0xFFFF6F00);
const _kText = Colors.white;
const _kMuted = Color(0xFFB0A0A0);
const _kBorder = Color(0x33FF6F00);

class WildfireScreen extends StatefulWidget {
  const WildfireScreen({super.key});

  @override
  State<WildfireScreen> createState() => _WildfireScreenState();
}

class _WildfireScreenState extends State<WildfireScreen> {
  bool _loading = false;
  bool _keyMissing = false;
  String? _error;
  int _days = 1;
  List<Map<String, dynamic>> _fires = [];
  int _totalRows = 0;

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
          '${ApiConfig.workerUrl}/api/intel/wildfires?days=$_days&region=world');
      final resp = await http.get(uri).timeout(const Duration(seconds: 25));
      if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['key_missing'] == true) {
        if (mounted) setState(() => _keyMissing = true);
        return;
      }
      final list = (data['fires'] as List?) ?? const [];
      if (!mounted) return;
      setState(() {
        _fires = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        _totalRows = data['totalRows'] as int? ?? _fires.length;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Abruf fehlgeschlagen. Bitte erneut versuchen.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _frpColor(double? frp) {
    if (frp == null) return _kMuted;
    if (frp > 1000) return const Color(0xFFE53935);
    if (frp > 200) return _kAccent;
    if (frp > 50) return const Color(0xFFFFC107);
    return const Color(0xFF4CAF50);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      appBar: WBGlassAppBar(
        world: WBWorld.materie,
        titleWidget: Row(children: const [
          Icon(Icons.local_fire_department_rounded, color: _kAccent, size: 22),
          SizedBox(width: 8),
          Text('Waldbrand-Radar',
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
          _card(Row(children: [
            const Text('Zeitraum:',
                style: TextStyle(color: _kMuted, fontSize: 12)),
            const SizedBox(width: 12),
            for (final d in [1, 2, 7])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _days = d);
                    _load();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: _days == d ? _kAccent.withValues(alpha: 0.2) : const Color(0xFF0D0000),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _days == d ? _kAccent : _kBorder),
                    ),
                    child: Text(d == 1 ? '24h' : d == 2 ? '48h' : '7 Tage',
                        style: TextStyle(
                            color: _days == d ? _kText : _kMuted,
                            fontSize: 12,
                            fontWeight: _days == d ? FontWeight.bold : FontWeight.normal)),
                  ),
                ),
              ),
          ])),
          const OsintSourceBanner(
            source: 'Thermische Hotspots (VIIRS SNPP Near Real-Time) aus der '
                'NASA FIRMS-Datenbank. Zeigt aktive Brandherde weltweit - '
                'inkl. Industrie-Hitze (nicht nur Waldbraende). '
                'FRP = Fire Radiative Power in MW.',
            accent: _kAccent,
            sources: [
              OsintSource('NASA FIRMS', 'https://firms.modaps.eosdis.nasa.gov')
            ],
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
                'Kostenloser NASA-Account erforderlich. Key anfordern auf '
                'firms.modaps.eosdis.nasa.gov, dann als Wrangler-Secret setzen:\n\n'
                'npx wrangler secret put NASA_FIRMS_API_KEY',
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
            if (_totalRows > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 2),
                child: Text(
                    'Top 300 von $_totalRows Hotspots (nach FRP sortiert)',
                    style: const TextStyle(color: _kMuted, fontSize: 12)),
              ),
            ..._fires.map(_fireCard),
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

  Widget _fireCard(Map<String, dynamic> f) {
    final lat = f['latitude'] ?? f['lat'] ?? '';
    final lon = f['longitude'] ?? f['lon'] ?? '';
    final frpRaw = double.tryParse((f['frp'] ?? '').toString());
    final date = (f['acq_date'] ?? '').toString();
    final time = (f['acq_time'] ?? '').toString();
    final country = (f['country_id'] ?? '').toString();
    final conf = (f['confidence'] ?? '').toString();
    final c = _frpColor(frpRaw);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Row(children: [
        Container(
          width: 44,
          alignment: Alignment.center,
          child: Column(children: [
            Icon(Icons.local_fire_department_rounded, color: c, size: 20),
            if (frpRaw != null)
              Text('${frpRaw.round()} MW',
                  style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              lat.isNotEmpty && lon.isNotEmpty ? '$lat, $lon' : 'Koordinaten unbekannt',
              style: const TextStyle(
                  color: _kText, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              [country, if (date.isNotEmpty) '$date ${time.padLeft(4, '0').substring(0, 2)}:${time.padLeft(4, '0').substring(2)}', if (conf.isNotEmpty) 'Konfidenz: $conf%']
                  .where((e) => e.isNotEmpty)
                  .join('  -  '),
              style: const TextStyle(color: _kMuted, fontSize: 11),
            ),
          ]),
        ),
      ]),
    );
  }
}
