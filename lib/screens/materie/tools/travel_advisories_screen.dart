import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:xml/xml.dart' as xml;
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/materie/osint_source_banner.dart';

// ─────────────────────────────────────────────────────────────────────────────
// R-X7 — Reisewarnungen & Sicherheits-Advisories
// Offizielle Laender-Sicherheitseinstufungen (Level 1-4) des US-Aussen-
// ministeriums via RSS. Kostenlos, ohne API-Key.
// ─────────────────────────────────────────────────────────────────────────────

const _kBg = Color(0xFF0D0000);
const _kSurface = Color(0xFF1A0808);
const _kAccent = Color(0xFFFFB300);
const _kText = Colors.white;
const _kMuted = Color(0xFFB0A0A0);
const _kBorder = Color(0x33FFB300);

class _Advisory {
  const _Advisory({
    required this.country,
    required this.level,
    required this.summary,
    required this.link,
  });
  final String country;
  final int level; // 1..4, 0 = unknown
  final String summary;
  final String link;
}

class TravelAdvisoriesScreen extends StatefulWidget {
  const TravelAdvisoriesScreen({super.key});

  @override
  State<TravelAdvisoriesScreen> createState() => _TravelAdvisoriesScreenState();
}

class _TravelAdvisoriesScreenState extends State<TravelAdvisoriesScreen> {
  final _filterCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  int _minLevel = 0; // 0 = alle
  List<_Advisory> _all = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse('https://travel.state.gov/_res/rss/TAsTWs.xml');
      final resp = await http.get(uri).timeout(const Duration(seconds: 25));
      if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');
      final doc = xml.XmlDocument.parse(resp.body);
      final out = <_Advisory>[];
      for (final item in doc.findAllElements('item')) {
        final title = item.getElement('title')?.innerText.trim() ?? '';
        if (title.isEmpty) continue;
        final link = item.getElement('link')?.innerText.trim() ?? '';
        final desc = item.getElement('description')?.innerText.trim() ?? '';
        out.add(_Advisory(
          country: _country(title),
          level: _level(title),
          summary: _stripHtml(desc),
          link: link,
        ));
      }
      out.sort((a, b) => b.level.compareTo(a.level));
      if (!mounted) return;
      setState(() => _all = out);
    } catch (_) {
      if (mounted) setState(() => _error = 'Abruf fehlgeschlagen. Bitte erneut versuchen.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _country(String title) {
    final idx = title.indexOf(' - ');
    return idx > 0 ? title.substring(0, idx).trim() : title;
  }

  int _level(String title) {
    final m = RegExp(r'Level\s*(\d)').firstMatch(title);
    return m != null ? int.tryParse(m.group(1) ?? '0') ?? 0 : 0;
  }

  String _stripHtml(String s) =>
      s.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll(RegExp(r'\s+'), ' ').trim();

  Color _levelColor(int l) {
    switch (l) {
      case 4:
        return const Color(0xFFE53935);
      case 3:
        return const Color(0xFFFF7043);
      case 2:
        return _kAccent;
      case 1:
        return const Color(0xFF4CAF50);
      default:
        return _kMuted;
    }
  }

  String _levelLabel(int l) {
    switch (l) {
      case 4:
        return 'NICHT REISEN';
      case 3:
        return 'REISE UEBERDENKEN';
      case 2:
        return 'ERHOEHTE VORSICHT';
      case 1:
        return 'NORMALE VORSICHT';
      default:
        return 'INFO';
    }
  }

  List<_Advisory> get _filtered {
    final q = _filterCtrl.text.trim().toLowerCase();
    return _all.where((a) {
      if (_minLevel > 0 && a.level < _minLevel) return false;
      if (q.isNotEmpty && !a.country.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  Future<void> _open(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      appBar: WBGlassAppBar(
        world: WBWorld.materie,
        titleWidget: Row(children: const [
          Icon(Icons.travel_explore_rounded, color: _kAccent, size: 22),
          SizedBox(width: 8),
          Text('Reisewarnungen',
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
            TextField(
              controller: _filterCtrl,
              style: const TextStyle(color: _kText),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Land filtern...',
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
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                for (final l in [0, 2, 3, 4])
                  GestureDetector(
                    onTap: () => setState(() => _minLevel = l),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _minLevel == l
                            ? _kAccent.withValues(alpha: 0.2)
                            : _kBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _minLevel == l ? _kAccent : _kBorder),
                      ),
                      child: Text(l == 0 ? 'Alle' : 'ab Level $l',
                          style: TextStyle(
                              color: _minLevel == l ? _kText : _kMuted,
                              fontSize: 12)),
                    ),
                  ),
              ],
            ),
          ])),
          const OsintSourceBanner(
            source: 'Offizielle Reise-Sicherheitseinstufungen des US-Aussen'
                'ministeriums (Level 1 = normal bis Level 4 = nicht reisen). '
                'Spiegelt auch politische Perspektive der Quelle.',
            accent: _kAccent,
            sources: [
              OsintSource('US State Department', 'https://travel.state.gov')
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
          else if (list.isEmpty)
            _card(const Text('Keine passenden Eintraege.',
                style: TextStyle(color: _kMuted, fontSize: 13)))
          else
            ...list.map(_advisoryCard),
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

  Widget _advisoryCard(_Advisory a) {
    final c = _levelColor(a.level);
    return GestureDetector(
      onTap: () => _open(a.link),
      child: _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.withValues(alpha: 0.5)),
            ),
            child: Text(a.level > 0 ? '${a.level}' : '?',
                style: TextStyle(
                    color: c, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.country,
                  style: const TextStyle(
                      color: _kText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(_levelLabel(a.level),
                  style: TextStyle(
                      color: c, fontSize: 11, fontWeight: FontWeight.bold)),
            ]),
          ),
          const Icon(Icons.open_in_new, color: _kMuted, size: 14),
        ]),
        if (a.summary.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            a.summary.length > 160
                ? '${a.summary.substring(0, 160)}...'
                : a.summary,
            style: const TextStyle(color: _kMuted, fontSize: 12, height: 1.4),
          ),
        ],
      ])),
    );
  }
}
