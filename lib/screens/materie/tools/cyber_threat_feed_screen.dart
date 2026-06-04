import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/materie/osint_source_banner.dart';

// ─────────────────────────────────────────────────────────────────────────────
// R-X4 — Cyber-Bedrohungs-Feed
// Aktuelle Ransomware-Opfer (ransomware.live) und aktive C2-/Botnet-Server
// (abuse.ch Feodo Tracker). Beide Quellen kostenlos, ohne API-Key.
// ─────────────────────────────────────────────────────────────────────────────

const _kSurface = Color(0xFF1A0808);
const _kAccent = Color(0xFFE53935);
const _kText = Colors.white;
const _kMuted = Color(0xFFB0A0A0);
const _kBorder = Color(0x33E53935);

class CyberThreatFeedScreen extends StatefulWidget {
  const CyberThreatFeedScreen({super.key});

  @override
  State<CyberThreatFeedScreen> createState() => _CyberThreatFeedScreenState();
}

class _CyberThreatFeedScreenState extends State<CyberThreatFeedScreen> {
  bool _loading = false;
  String? _error;
  int _tab = 0; // 0 = Ransomware, 1 = C2-Server

  List<Map<String, dynamic>> _victims = [];
  List<Map<String, dynamic>> _c2 = [];

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
      final results = await Future.wait([
        _loadVictims(),
        _loadC2(),
      ]);
      if (!mounted) return;
      setState(() {
        _victims = results[0];
        _c2 = results[1];
      });
    } catch (_) {
      if (mounted)
        setState(
            () => _error = 'Abruf fehlgeschlagen. Bitte erneut versuchen.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _loadVictims() async {
    try {
      final uri = Uri.parse('https://api.ransomware.live/v2/recentvictims');
      final resp = await http.get(uri).timeout(const Duration(seconds: 25));
      if (resp.statusCode != 200) return [];
      final decoded = jsonDecode(resp.body);
      final list = decoded is List ? decoded : const [];
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .take(40)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadC2() async {
    try {
      final uri =
          Uri.parse('https://feodotracker.abuse.ch/downloads/ipblocklist.json');
      final resp = await http.get(uri).timeout(const Duration(seconds: 25));
      if (resp.statusCode != 200) return [];
      final decoded = jsonDecode(resp.body);
      final list = decoded is List ? decoded : const [];
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .take(50)
          .toList();
    } catch (_) {
      return [];
    }
  }

  String _str(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      appBar: WBGlassAppBar(
        world: WBWorld.materie,
        titleWidget: Row(children: const [
          Icon(Icons.gpp_maybe_rounded, color: _kAccent, size: 22),
          SizedBox(width: 8),
          Text('Cyber-Bedrohungen',
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
          const OsintSourceBanner(
            source: 'Aktuelle Ransomware-Opfer (von den Erpresser-Leak-Seiten '
                'gesammelt) und aktive Command-and-Control-Server bekannter '
                'Botnetze. Reine Beobachtungsdaten, keine Handlungsempfehlung.',
            accent: _kAccent,
            sources: [
              OsintSource('ransomware.live', 'https://www.ransomware.live'),
              OsintSource('abuse.ch Feodo', 'https://feodotracker.abuse.ch'),
            ],
          ),
          _tabs(),
          const SizedBox(height: 12),
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
          else if (_tab == 0)
            ...(_victims.isEmpty
                ? [
                    _card(const Text('Keine aktuellen Eintraege.',
                        style: TextStyle(color: _kMuted, fontSize: 13)))
                  ]
                : _victims.map(_victimCard))
          else
            ...(_c2.isEmpty
                ? [
                    _card(const Text('Keine aktuellen Eintraege.',
                        style: TextStyle(color: _kMuted, fontSize: 13)))
                  ]
                : _c2.map(_c2Card)),
        ]),
      ),
    );
  }

  Widget _tabs() {
    final labels = [
      'Ransomware-Opfer (${_victims.length})',
      'C2-Server (${_c2.length})'
    ];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == 0 ? 8 : 0),
              child: GestureDetector(
                onTap: () => setState(() => _tab = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _tab == i
                        ? _kAccent.withValues(alpha: 0.18)
                        : _kSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _tab == i ? _kAccent : _kBorder),
                  ),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _tab == i ? _kText : _kMuted,
                      fontSize: 11,
                      fontWeight:
                          _tab == i ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
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

  Widget _victimCard(Map<String, dynamic> v) {
    final victim = _str(v, ['victim', 'post_title', 'title']);
    final group = _str(v, ['group', 'group_name']);
    final country = _str(v, ['country']);
    final date = _str(v, ['attackdate', 'discovered', 'published']);
    final activity = _str(v, ['activity', 'sector']);
    return _card(
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: Text(victim.isEmpty ? '(unbenannt)' : victim,
              style: const TextStyle(
                  color: _kText, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        if (group.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _kAccent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(group,
                style: const TextStyle(
                    color: _kAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
      ]),
      const SizedBox(height: 6),
      Text(
        [activity, country, date].where((e) => e.isNotEmpty).join('  -  '),
        style: const TextStyle(color: _kMuted, fontSize: 11),
      ),
    ]));
  }

  Widget _c2Card(Map<String, dynamic> c) {
    final ip = _str(c, ['ip_address', 'ip']);
    final malware = _str(c, ['malware', 'malware_printable']);
    final country = _str(c, ['country']);
    final asName = _str(c, ['as_name']);
    final port = _str(c, ['port']);
    return _card(
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.dns_rounded, color: _kAccent, size: 16),
        const SizedBox(width: 8),
        Text(port.isEmpty ? ip : '$ip:$port',
            style: const TextStyle(
                color: _kText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace')),
        const Spacer(),
        if (malware.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(malware,
                style: const TextStyle(
                    color: Color(0xFFFF9800),
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
      ]),
      const SizedBox(height: 6),
      Text(
        [asName, country].where((e) => e.isNotEmpty).join('  -  '),
        style: const TextStyle(color: _kMuted, fontSize: 11),
      ),
    ]));
  }
}
