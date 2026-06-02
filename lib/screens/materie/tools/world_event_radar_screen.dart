import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/materie/osint_source_banner.dart';

// ─────────────────────────────────────────────────────────────────────────────
// R-X1 — Welt-Ereignis-Radar
// Live-Erdbeben (USGS), UN-Katastrophen-Alerts (GDACS) und Naturereignisse
// (NASA EONET). Alle Quellen kostenlos, ohne API-Key, HTTPS.
// ─────────────────────────────────────────────────────────────────────────────

const _kSurface = Color(0xFF1A0808);
const _kAccent = Color(0xFFE53935);
const _kText = Colors.white;
const _kMuted = Color(0xFFB0A0A0);
const _kBorder = Color(0x33E53935);

/// One normalized world event from any of the three sources.
class _WorldEvent {
  const _WorldEvent({
    required this.title,
    required this.severity,
    required this.severityColor,
    required this.category,
    required this.when,
    this.coords,
  });
  final String title;
  final String severity;
  final Color severityColor;
  final String category;
  final DateTime? when;
  final String? coords;
}

class WorldEventRadarScreen extends StatefulWidget {
  const WorldEventRadarScreen({super.key});

  @override
  State<WorldEventRadarScreen> createState() => _WorldEventRadarScreenState();
}

class _WorldEventRadarScreenState extends State<WorldEventRadarScreen> {
  bool _loading = false;
  String? _error;
  int _tab = 0; // 0 = Erdbeben, 1 = Katastrophen, 2 = Naturereignisse

  List<_WorldEvent> _quakes = [];
  List<_WorldEvent> _disasters = [];
  List<_WorldEvent> _natural = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _loadQuakes(),
        _loadDisasters(),
        _loadNatural(),
      ]);
      if (!mounted) return;
      setState(() {
        _quakes = results[0];
        _disasters = results[1];
        _natural = results[2];
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Abruf fehlgeschlagen. Bitte erneut versuchen.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<_WorldEvent>> _loadQuakes() async {
    try {
      final uri = Uri.parse(
          'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/4.5_day.geojson');
      final resp = await http.get(uri).timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) return [];
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final feats = (data['features'] as List?) ?? const [];
      final out = <_WorldEvent>[];
      for (final f in feats) {
        if (f is! Map) continue;
        final p = (f['properties'] as Map?) ?? const {};
        final g = (f['geometry'] as Map?) ?? const {};
        final mag = (p['mag'] as num?)?.toDouble() ?? 0;
        final coords = (g['coordinates'] as List?) ?? const [];
        final lon = coords.isNotEmpty ? coords[0] : null;
        final lat = coords.length > 1 ? coords[1] : null;
        out.add(_WorldEvent(
          title: (p['place'] ?? 'Unbekannter Ort').toString(),
          severity: 'M${mag.toStringAsFixed(1)}',
          severityColor: mag >= 6
              ? _kAccent
              : mag >= 5
                  ? const Color(0xFFFF9800)
                  : const Color(0xFFFFC107),
          category: 'Erdbeben',
          when: p['time'] != null
              ? DateTime.fromMillisecondsSinceEpoch((p['time'] as num).toInt())
              : null,
          coords: (lat != null && lon != null)
              ? '${(lat as num).toStringAsFixed(2)}, ${(lon as num).toStringAsFixed(2)}'
              : null,
        ));
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  Future<List<_WorldEvent>> _loadDisasters() async {
    try {
      final uri = Uri.parse('https://www.gdacs.org/xml/rss.xml');
      final resp = await http.get(uri).timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) return [];
      final doc = xml.XmlDocument.parse(resp.body);
      final items = doc.findAllElements('item');
      final out = <_WorldEvent>[];
      for (final item in items) {
        final title = _childText(item, 'title');
        if (title.isEmpty) continue;
        final level = _childText(item, 'alertlevel');
        final type = _childText(item, 'eventtype');
        final pub = _childText(item, 'pubDate');
        out.add(_WorldEvent(
          title: title,
          severity: _gdacsLabel(level),
          severityColor: _gdacsColor(level),
          category: _gdacsType(type),
          when: _parseRssDate(pub),
        ));
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  Future<List<_WorldEvent>> _loadNatural() async {
    try {
      final uri = Uri.parse(
          'https://eonet.gsfc.nasa.gov/api/v3/events?status=open&limit=50');
      final resp = await http.get(uri).timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) return [];
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final events = (data['events'] as List?) ?? const [];
      final out = <_WorldEvent>[];
      for (final e in events) {
        if (e is! Map) continue;
        final cats = (e['categories'] as List?) ?? const [];
        final catTitle = cats.isNotEmpty && cats.first is Map
            ? (cats.first['title'] ?? '').toString()
            : 'Ereignis';
        final geom = (e['geometry'] as List?) ?? const [];
        String? coords;
        DateTime? when;
        if (geom.isNotEmpty && geom.last is Map) {
          final last = geom.last as Map;
          final c = (last['coordinates'] as List?) ?? const [];
          if (c.length >= 2 && c[0] is num && c[1] is num) {
            coords =
                '${(c[1] as num).toStringAsFixed(2)}, ${(c[0] as num).toStringAsFixed(2)}';
          }
          when = DateTime.tryParse((last['date'] ?? '').toString());
        }
        out.add(_WorldEvent(
          title: (e['title'] ?? '').toString(),
          severity: catTitle,
          severityColor: const Color(0xFF26C6DA),
          category: catTitle,
          when: when,
          coords: coords,
        ));
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  // Finds first child element by local name (ignores namespace prefix).
  String _childText(xml.XmlElement parent, String localName) {
    for (final child in parent.childElements) {
      if (child.name.local == localName) return child.innerText.trim();
    }
    return '';
  }

  // ── GDACS helpers ──────────────────────────────────────────────────────────
  String _gdacsLabel(String level) {
    switch (level.toLowerCase()) {
      case 'red':
        return 'ROT';
      case 'orange':
        return 'ORANGE';
      default:
        return 'GRUEN';
    }
  }

  Color _gdacsColor(String level) {
    switch (level.toLowerCase()) {
      case 'red':
        return _kAccent;
      case 'orange':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF4CAF50);
    }
  }

  String _gdacsType(String type) {
    switch (type.toUpperCase()) {
      case 'EQ':
        return 'Erdbeben';
      case 'TC':
        return 'Tropensturm';
      case 'FL':
        return 'Flut';
      case 'VO':
        return 'Vulkan';
      case 'DR':
        return 'Duerre';
      case 'WF':
        return 'Waldbrand';
      default:
        return 'Katastrophe';
    }
  }

  DateTime? _parseRssDate(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      // RFC-822 fallback: strip weekday + timezone abbreviation
      return null;
    }
  }

  String _ago(DateTime? when) {
    if (when == null) return '';
    final d = DateTime.now().difference(when);
    if (d.inMinutes < 60) return 'vor ${d.inMinutes} Min';
    if (d.inHours < 24) return 'vor ${d.inHours} Std';
    return 'vor ${d.inDays} T';
  }

  List<_WorldEvent> get _current =>
      _tab == 0 ? _quakes : (_tab == 1 ? _disasters : _natural);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      appBar: WBGlassAppBar(
        world: WBWorld.materie,
        titleWidget: Row(children: const [
          Icon(Icons.public_rounded, color: _kAccent, size: 22),
          SizedBox(width: 8),
          Text('Welt-Ereignis-Radar',
              style: TextStyle(color: _kText, fontWeight: FontWeight.bold)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _kAccent),
            tooltip: 'Aktualisieren',
            onPressed: _loading ? null : _loadAll,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const OsintSourceBanner(
            source: 'Live-Ereignisse aus drei offiziellen Quellen. Erdbeben ab '
                'Magnitude 4.5 (letzte 24h), UN-Katastrophen-Alerts und offene '
                'Naturereignisse.',
            accent: _kAccent,
            sources: [
              OsintSource('USGS', 'https://earthquake.usgs.gov'),
              OsintSource('GDACS', 'https://www.gdacs.org'),
              OsintSource('NASA EONET', 'https://eonet.gsfc.nasa.gov'),
            ],
          ),
          _tabs(),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                  child: CircularProgressIndicator(color: _kAccent)),
            )
          else if (_error != null)
            _card(Row(children: [
              const Icon(Icons.error_outline, color: _kAccent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(_error!,
                      style: const TextStyle(color: _kAccent, fontSize: 13))),
            ]))
          else if (_current.isEmpty)
            _card(const Text('Aktuell keine Ereignisse in dieser Kategorie.',
                style: TextStyle(color: _kMuted, fontSize: 13)))
          else
            ..._current.map(_eventCard),
        ]),
      ),
    );
  }

  Widget _tabs() {
    final labels = ['Erdbeben (${_quakes.length})', 'Katastrophen (${_disasters.length})', 'Natur (${_natural.length})'];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
              child: GestureDetector(
                onTap: () => setState(() => _tab = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _tab == i ? _kAccent.withValues(alpha: 0.18) : _kSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _tab == i ? _kAccent : _kBorder),
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

  Widget _eventCard(_WorldEvent e) => _card(
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: e.severityColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: e.severityColor.withValues(alpha: 0.5)),
              ),
              child: Text(e.severity,
                  style: TextStyle(
                      color: e.severityColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
            const Spacer(),
            if (e.when != null)
              Text(_ago(e.when),
                  style: const TextStyle(color: _kMuted, fontSize: 11)),
          ]),
          const SizedBox(height: 8),
          Text(e.title,
              style: const TextStyle(
                  color: _kText, fontSize: 14, fontWeight: FontWeight.w600)),
          if (e.coords != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.place_outlined, color: _kMuted, size: 13),
              const SizedBox(width: 4),
              Text(e.coords!,
                  style: const TextStyle(color: _kMuted, fontSize: 12)),
            ]),
          ],
        ]),
      );
}
