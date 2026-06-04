import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/materie/osint_source_banner.dart';

// ─────────────────────────────────────────────────────────────────────────────
// R-X5 — Live-Flugverfolgung
// Flugzeuge in einer Region live ueber das oeffentliche OpenSky-Network.
// Kostenlos, ohne API-Key (anonyme Abfrage, begrenztes Rate-Limit).
// ─────────────────────────────────────────────────────────────────────────────

const _kBg = Color(0xFF0D0000);
const _kSurface = Color(0xFF1A0808);
const _kAccent = Color(0xFF42A5F5);
const _kText = Colors.white;
const _kMuted = Color(0xFFB0A0A0);
const _kBorder = Color(0x3342A5F5);

class _Region {
  const _Region(this.label, this.laMin, this.loMin, this.laMax, this.loMax);
  final String label;
  final double laMin, loMin, laMax, loMax;
}

const _regions = [
  _Region('Mitteleuropa', 45.0, 5.0, 55.0, 17.0),
  _Region('Naher Osten', 28.0, 33.0, 38.0, 50.0),
  _Region('Osteuropa', 44.0, 22.0, 56.0, 40.0),
  _Region('USA Ost', 33.0, -82.0, 43.0, -70.0),
  _Region('Ostasien', 30.0, 118.0, 42.0, 132.0),
];

class _Flight {
  const _Flight({
    required this.callsign,
    required this.country,
    required this.altitude,
    required this.speed,
    required this.onGround,
    this.lat,
    this.lon,
  });
  final String callsign;
  final String country;
  final double? altitude;
  final double? speed;
  final bool onGround;
  final double? lat;
  final double? lon;
}

class FlightTrackerScreen extends StatefulWidget {
  const FlightTrackerScreen({super.key});

  @override
  State<FlightTrackerScreen> createState() => _FlightTrackerScreenState();
}

class _FlightTrackerScreenState extends State<FlightTrackerScreen> {
  bool _loading = false;
  String? _error;
  int _regionIdx = 0;
  List<_Flight> _flights = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = _regions[_regionIdx];
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse(
          'https://opensky-network.org/api/states/all?lamin=${r.laMin}&lomin=${r.loMin}&lamax=${r.laMax}&lomax=${r.loMax}');
      final resp = await http.get(uri).timeout(const Duration(seconds: 25));
      if (resp.statusCode == 429) {
        throw Exception('rate');
      }
      if (resp.statusCode != 200) {
        throw Exception('HTTP ${resp.statusCode}');
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final states = (data['states'] as List?) ?? const [];
      final out = <_Flight>[];
      for (final s in states) {
        if (s is! List || s.length < 11) continue;
        final callsign = (s[1] ?? '').toString().trim();
        out.add(_Flight(
          callsign: callsign.isEmpty ? '(unbekannt)' : callsign,
          country: (s[2] ?? '').toString(),
          lon: s[5] is num ? (s[5] as num).toDouble() : null,
          lat: s[6] is num ? (s[6] as num).toDouble() : null,
          altitude: s[7] is num ? (s[7] as num).toDouble() : null,
          onGround: s[8] == true,
          speed: s[9] is num ? (s[9] as num).toDouble() : null,
        ));
      }
      out.sort((a, b) => (b.altitude ?? 0).compareTo(a.altitude ?? 0));
      if (!mounted) return;
      setState(() => _flights = out);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().contains('rate')
            ? 'OpenSky-Limit erreicht. Bitte in 1-2 Minuten erneut versuchen.'
            : 'Abruf fehlgeschlagen. Bitte erneut versuchen.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _alt(double? m) => m == null ? '-' : '${(m).round()} m';
  String _spd(double? ms) => ms == null ? '-' : '${(ms * 3.6).round()} km/h';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      appBar: WBGlassAppBar(
        world: WBWorld.materie,
        titleWidget: Row(children: const [
          Icon(Icons.flight_rounded, color: _kAccent, size: 22),
          SizedBox(width: 8),
          Text('Flugverfolgung',
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
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Region',
                style: TextStyle(color: _kMuted, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _regions.length; i++)
                  GestureDetector(
                    onTap: () {
                      setState(() => _regionIdx = i);
                      _load();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: _regionIdx == i
                            ? _kAccent.withValues(alpha: 0.2)
                            : _kBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _regionIdx == i ? _kAccent : _kBorder),
                      ),
                      child: Text(_regions[i].label,
                          style: TextStyle(
                              color: _regionIdx == i ? _kText : _kMuted,
                              fontSize: 12,
                              fontWeight: _regionIdx == i
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                    ),
                  ),
              ],
            ),
          ])),
          const OsintSourceBanner(
            source: 'Live-Positionen von Flugzeugen mit ADS-B-Transponder. '
                'Militaerische oder staatliche Maschinen sind oft nicht oder '
                'nur teilweise sichtbar.',
            accent: _kAccent,
            sources: [
              OsintSource('OpenSky Network', 'https://opensky-network.org')
            ],
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
          else ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 2),
              child: Text('${_flights.length} Flugzeuge erfasst',
                  style: const TextStyle(color: _kMuted, fontSize: 12)),
            ),
            ..._flights.take(60).map(_flightCard),
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

  Widget _flightCard(_Flight f) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
        ),
        child: Row(children: [
          Icon(f.onGround ? Icons.flight_land_rounded : Icons.flight_rounded,
              color: f.onGround ? _kMuted : _kAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(f.callsign,
                  style: const TextStyle(
                      color: _kText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace')),
              const SizedBox(height: 2),
              Text(f.country,
                  style: const TextStyle(color: _kMuted, fontSize: 11)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(_alt(f.altitude),
                style: const TextStyle(color: _kText, fontSize: 12)),
            const SizedBox(height: 2),
            Text(_spd(f.speed),
                style: const TextStyle(color: _kMuted, fontSize: 11)),
          ]),
        ]),
      );
}
