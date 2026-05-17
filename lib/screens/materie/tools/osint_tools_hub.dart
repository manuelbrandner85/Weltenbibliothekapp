import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:webview_flutter/webview_flutter.dart';

import '../../../services/osint_history_service.dart'; // 🕰️ D1
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/cinematic/wb_vignette.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OSINT Datenbanken Hub — 7 direkte Datenbank-Zugänge via WebView
// ─────────────────────────────────────────────────────────────────────────────

const _kBg      = Color(0xFF0D0000);
const _kSurface = Color(0xFF1A0808);
const _kAccent  = Color(0xFFE53935);
const _kText    = Colors.white;
const _kMuted   = Color(0xFFB0A0A0);
const _kBorder  = Color(0x33E53935);

class OsintToolsHub extends StatelessWidget {
  const OsintToolsHub({super.key});

  static const _tools = [
    _DbDef(
      icon: Icons.account_balance_wallet_rounded,
      label: 'Panama Papers',
      sub: 'ICIJ Offshore Leaks',
      color: Color(0xFFFFB300),
      url: 'https://offshoreleaks.icij.org/',
      description: 'Durchsuche Panama Papers, Pandora Papers und Paradise Papers — Offshore-Netzwerke, Shell-Firmen, versteckte Vermögen.',
    ),
    _DbDef(
      icon: Icons.gavel_rounded,
      label: 'OpenSanctions',
      sub: 'EU/UN/OFAC Sanktionslisten',
      color: Color(0xFFE53935),
      url: 'https://www.opensanctions.org/',
      description: 'Internationale Sanktionslisten: EU, UN, OFAC, Interpol, politisch exponierte Personen (PEP).',
    ),
    _DbDef(
      icon: Icons.folder_zip_rounded,
      label: 'Aleph OCCRP',
      sub: 'FinCEN, LuxLeaks, Suisse Secrets',
      color: Color(0xFF7C4DFF),
      url: 'https://aleph.occrp.org/',
      description: 'OCCRP Aleph: Größte Datenbank für investigativen Journalismus — FinCEN Files, LuxLeaks, Suisse Secrets, Pandora.',
    ),
    _DbDef(
      icon: Icons.science_rounded,
      label: 'PubMed',
      sub: '35 Mio. Studien & Papers',
      color: Color(0xFF00BCD4),
      url: 'https://pubmed.ncbi.nlm.nih.gov/',
      description: 'National Library of Medicine: 35 Millionen biomedizinische Studien, peer-reviewed Forschung, klinische Daten.',
    ),
    _DbDef(
      icon: Icons.auto_stories_rounded,
      label: 'Semantic Scholar',
      sub: '200 Mio. wissenschaftliche Paper',
      color: Color(0xFF4CAF50),
      url: 'https://www.semanticscholar.org/',
      description: 'AI-gestützte Suche in 200 Millionen wissenschaftlichen Veröffentlichungen aller Fachbereiche.',
    ),
    _DbDef(
      icon: Icons.archive_rounded,
      label: 'Internet Archive',
      sub: '50 Mio. Dokumente & Wayback',
      color: Color(0xFFFF7043),
      url: 'https://archive.org/',
      description: 'Wayback Machine + 50 Millionen Bücher, Videos, Audio und Webseiten — das Gedächtnis des Internets.',
    ),
    _DbDef(
      icon: Icons.how_to_vote_rounded,
      label: 'EU-Parlament',
      sub: 'Abstimmungen & Abgeordnete',
      color: Color(0xFF2196F3),
      url: 'https://www.europarl.europa.eu/meps/de/full-list/all',
      description: 'Alle EU-Abgeordneten, Abstimmungsverhalten, Ausschüsse, Lobbyist-Kontakte und Ausgaben.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      appBar: WBGlassAppBar(
        world: WBWorld.materie,
        titleWidget: Row(children: [
          Icon(Icons.manage_search_rounded, color: _kAccent, size: 22),
          const SizedBox(width: 8),
          const Text('OSINT Datenbanken',
              style: TextStyle(color: _kText, fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        actions: [
          // 🕰️ D1: pro-Tool-History
          IconButton(
            icon: Icon(Icons.history_rounded, color: _kAccent),
            tooltip: 'Such-Verlauf',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _OsintHistoryScreen()),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text(
            '7 direkte Datenbank-Zugänge für OSINT-Recherche.',
            style: const TextStyle(color: _kMuted, fontSize: 13),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.05,
            ),
            itemCount: _tools.length,
            itemBuilder: (context, i) => _DbCard(db: _tools[i]),
          ),
        ),
      ]),
    );
  }
}

class _DbCard extends StatelessWidget {
  final _DbDef db;
  const _DbCard({required this.db});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _OsintWebViewScreen(db: db)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: db.color.withValues(alpha: 0.3), width: 1),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [db.color.withValues(alpha: 0.1), _kSurface],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: db.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: db.color.withValues(alpha: 0.3)),
                ),
                child: Icon(db.icon, color: db.color, size: 20),
              ),
              const SizedBox(height: 10),
              Text(db.label,
                  style: const TextStyle(
                      color: _kText, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 3),
              Text(db.sub,
                  style: const TextStyle(color: _kMuted, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2),
              const Spacer(),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Icon(Icons.open_in_browser_rounded,
                    color: db.color.withValues(alpha: 0.6), size: 13),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _OsintWebViewScreen extends StatefulWidget {
  final _DbDef db;
  const _OsintWebViewScreen({required this.db, super.key});

  @override
  State<_OsintWebViewScreen> createState() => _OsintWebViewScreenState();
}

class _OsintWebViewScreenState extends State<_OsintWebViewScreen> {
  late final WebViewController _ctrl;
  bool _loading = true;
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.db.url;
    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) => setState(() { _currentUrl = url; _loading = true; }),
        onPageFinished: (_) { if (mounted) setState(() => _loading = false); },
        onWebResourceError: (_) { if (mounted) setState(() => _loading = false); },
      ))
      ..loadRequest(Uri.parse(widget.db.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: WBGlassAppBar(
        world: WBWorld.materie,
        titleWidget: Row(children: [
          Icon(widget.db.icon, color: widget.db.color, size: 18),
          const SizedBox(width: 8),
          Text(widget.db.label,
              style: const TextStyle(
                  color: _kText, fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () => _ctrl.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
            onPressed: () async {
              if (await _ctrl.canGoBack()) _ctrl.goBack();
            },
          ),
        ],
        bottom: _loading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  backgroundColor: _kBg,
                  color: widget.db.color,
                  minHeight: 3,
                ),
              )
            : PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: _kBorder),
              ),
      ),
      body: WebViewWidget(controller: _ctrl),
    );
  }
}

class _DbDef {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final String url;
  final String description;
  const _DbDef({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.url,
    required this.description,
  });
}

// 🕰️ D1: OSINT-Such-Verlauf pro Tool
class _OsintHistoryScreen extends StatefulWidget {
  const _OsintHistoryScreen();
  @override
  State<_OsintHistoryScreen> createState() => _OsintHistoryScreenState();
}

class _OsintHistoryScreenState extends State<_OsintHistoryScreen> {
  static const _tools = [
    ('domain_osint', '🌐 Domain'),
    ('phone_osint', '📞 Phone'),
    ('crypto_tracker', '₿ Crypto'),
    ('image_analysis', '🖼️ Image'),
    ('ai_detector', '🤖 AI-Detector'),
    ('geo_analysis', '🗺️ Geo'),
    ('data_leak', '⚠️ Leaks'),
  ];

  String _selectedTool = 'domain_osint';
  List<OsintHistoryEntry> _entries = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await OsintHistoryService.instance.list(_selectedTool);
    if (mounted) setState(() => _entries = list);
  }

  Future<void> _star(OsintHistoryEntry e) async {
    await OsintHistoryService.instance.toggleStar(_selectedTool, e.query);
    _load();
  }

  Future<void> _clear() async {
    await OsintHistoryService.instance.clear(_selectedTool);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('OSINT-Verlauf',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: _kAccent),
        actions: [
          if (_entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: _kAccent),
              tooltip: 'Verlauf leeren',
              onPressed: _clear,
            ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final t in _tools)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: ChoiceChip(
                      label: Text(t.$2,
                          style: const TextStyle(fontSize: 12)),
                      selected: _selectedTool == t.$1,
                      selectedColor: _kAccent.withValues(alpha: 0.25),
                      backgroundColor: Colors.white.withValues(alpha: 0.04),
                      labelStyle: TextStyle(
                        color: _selectedTool == t.$1 ? _kAccent : Colors.white70,
                      ),
                      onSelected: (_) {
                        setState(() => _selectedTool = t.$1);
                        _load();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _entries.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Noch keine Suchen für dieses Tool.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55)),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _entries.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (_, i) {
                      final e = _entries[i];
                      return ListTile(
                        leading: Icon(
                          e.starred ? Icons.star : Icons.search,
                          color: e.starred ? Colors.amber : Colors.white60,
                        ),
                        title: Text(e.query,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13)),
                        subtitle: Text(
                          _relTime(e.timestamp),
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                e.starred ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: e.starred ? Colors.amber : Colors.white38,
                              ),
                              onPressed: () => _star(e),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded,
                                  color: Colors.white38, size: 18),
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: e.query));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('📋 Kopiert'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _relTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'jetzt';
    if (d.inMinutes < 60) return 'vor ${d.inMinutes}m';
    if (d.inHours < 24) return 'vor ${d.inHours}h';
    return 'vor ${d.inDays}d';
  }
}
