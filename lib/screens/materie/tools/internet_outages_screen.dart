import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/materie/osint_source_banner.dart';

// ─────────────────────────────────────────────────────────────────────────────
// R-X13 — Internet-Ausfaelle & Zensur
// Netz-Ausfaelle und Traffic-Anomalien pro Land/ASN via Cloudflare Radar.
// Laeuft ueber den Worker (CLOUDFLARE_RADAR_API_TOKEN als Secret).
// ─────────────────────────────────────────────────────────────────────────────

const _kSurface = Color(0xFF1A0808);
const _kAccent = Color(0xFF42A5F5);
const _kText = Colors.white;
const _kMuted = Color(0xFFB0A0A0);
const _kBorder = Color(0x3342A5F5);

class InternetOutagesScreen extends StatefulWidget {
  const InternetOutagesScreen({super.key});

  @override
  State<InternetOutagesScreen> createState() => _InternetOutagesScreenState();
}

class _InternetOutagesScreenState extends State<InternetOutagesScreen> {
  bool _loading = false;
  bool _keyMissing = false;
  String? _error;
  List<Map<String, dynamic>> _outages = [];

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
          '${ApiConfig.workerUrl}/api/intel/outages?limit=40');
      final resp = await http.get(uri).timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['key_missing'] == true) {
        if (mounted) setState(() => _keyMissing = true);
        return;
      }
      final list = (data['outages'] as List?) ?? const [];
      if (!mounted) return;
      setState(() => _outages =
          list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList());
    } catch (_) {
      if (mounted) setState(() => _error = 'Abruf fehlgeschlagen. Bitte erneut versuchen.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _scopeColor(String scope) {
    switch (scope.toLowerCase()) {
      case 'country':
        return const Color(0xFFE53935);
      case 'region':
        return const Color(0xFFFF9800);
      default:
        return _kAccent;
    }
  }

  String _scopeLabel(String scope) {
    switch (scope.toLowerCase()) {
      case 'country':
        return 'Land';
      case 'region':
        return 'Region';
      case 'asn':
        return 'Provider/ASN';
      default:
        return scope;
    }
  }

  String _fmtDate(String raw) {
    if (raw.length < 10) return raw;
    return raw.substring(0, 10);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      appBar: WBGlassAppBar(
        world: WBWorld.materie,
        titleWidget: Row(children: const [
          Icon(Icons.wifi_off_rounded, color: _kAccent, size: 22),
          SizedBox(width: 8),
          Text('Internet-Ausfaelle',
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
            source: 'Dokumentierte Internet-Ausfaelle und Traffic-Anomalien '
                'nach Land, Region oder Netz-Provider. Indikator fuer staatliche '
                'Internetsperren, grosse Infrastruktur-Stoerungen oder Angriffe.',
            accent: _kAccent,
            sources: [
              OsintSource('Cloudflare Radar', 'https://radar.cloudflare.com')
            ],
          ),
          if (_keyMissing)
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.key_off_rounded, color: Color(0xFFFFB300), size: 18),
                SizedBox(width: 8),
                Text('API-Token nicht konfiguriert',
                    style: TextStyle(
                        color: Color(0xFFFFB300),
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ]),
              const SizedBox(height: 8),
              const Text(
                'Cloudflare Radar API Token im Cloudflare-Dashboard erstellen '
                '(kostenloser CF-Account genuegt), dann als Wrangler-Secret setzen:\n\n'
                'npx wrangler secret put CLOUDFLARE_RADAR_API_TOKEN\n\n'
                'Berechtigungen: Radar Read.',
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
          else if (_outages.isEmpty)
            _card(const Text(
                'Keine aktuellen Ausfaelle gemeldet.',
                style: TextStyle(color: _kMuted, fontSize: 13)))
          else
            ..._outages.map(_outageCard),
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

  Widget _outageCard(Map<String, dynamic> o) {
    final scope = (o['scope'] ?? '').toString();
    final country = (o['country'] ?? '').toString();
    final loc = (o['location'] ?? '').toString();
    final asnName = (o['asnName'] ?? '').toString();
    final desc = (o['description'] ?? '').toString();
    final start = _fmtDate((o['startDate'] ?? '').toString());
    final end = _fmtDate((o['endDate'] ?? '').toString());
    final c = _scopeColor(scope);
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(_scopeLabel(scope),
              style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        if (country.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(country, style: const TextStyle(color: _kMuted, fontSize: 11)),
        ],
        const Spacer(),
        Text(
          [start, if (end.isNotEmpty && end != start) '- $end']
              .where((e) => e.isNotEmpty)
              .join(' '),
          style: const TextStyle(color: _kMuted, fontSize: 11),
        ),
      ]),
      const SizedBox(height: 8),
      Text(
        loc.isNotEmpty ? loc : (asnName.isNotEmpty ? asnName : 'Unbekannter Bereich'),
        style: const TextStyle(
            color: _kText, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      if (asnName.isNotEmpty && asnName != loc) ...[
        const SizedBox(height: 2),
        Text('Provider: $asnName',
            style: const TextStyle(color: _kMuted, fontSize: 12)),
      ],
      if (desc.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(
          desc.length > 180 ? '${desc.substring(0, 180)}...' : desc,
          style: const TextStyle(color: _kMuted, fontSize: 12, height: 1.4),
        ),
      ],
    ]));
  }
}
