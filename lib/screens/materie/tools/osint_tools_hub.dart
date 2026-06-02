import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:webview_flutter/webview_flutter.dart';

import '../../../services/osint_history_service.dart'; // 🕰️ D1
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import 'eu_parliament_tracker_screen.dart';
import 'power_network_explorer_screen.dart';
import 'study_analyst_screen.dart';
import 'version_watcher_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OSINT Datenbanken Hub — 7 direkte Datenbank-Zugänge via WebView
// ─────────────────────────────────────────────────────────────────────────────

const _kBg = Color(0xFF0D0000);
const _kSurface = Color(0xFF1A0808);
const _kAccent = Color(0xFFE53935);
const _kText = Colors.white;
const _kMuted = Color(0xFFB0A0A0);
const _kBorder = Color(0x33E53935);

class OsintToolsHub extends StatefulWidget {
  const OsintToolsHub({super.key});

  @override
  State<OsintToolsHub> createState() => _OsintToolsHubState();
}

class _OsintToolsHubState extends State<OsintToolsHub> {
  List<(String, String, String)> _starred = []; // (tool, label, query)

  static const _toolMeta = [
    ('domain_osint', '🌐'),
    ('phone_osint', '📞'),
    ('crypto_tracker', '₿'),
    ('image_analysis', '🖼️'),
    ('ai_detector', '🤖'),
    ('geo_analysis', '🗺️'),
    ('data_leak', '⚠️'),
  ];

  @override
  void initState() {
    super.initState();
    _loadStarred();
  }

  Future<void> _loadStarred() async {
    final result = <(String, String, String)>[];
    for (final (toolId, emoji) in _toolMeta) {
      final entries = await OsintHistoryService.instance.list(toolId);
      for (final e in entries.where((e) => e.starred)) {
        result.add((toolId, emoji, e.query));
      }
    }
    if (mounted) setState(() => _starred = result);
  }

  static final _tools = [
    _DbDef(
      icon: Icons.hub_rounded,
      label: 'Power-Network',
      sub: 'OpenSanctions + 6 Leaks parallel',
      color: const Color(0xFFE53935),
      url: '',
      description:
          'Eine Suche → 2 Datenbanken parallel: OpenSanctions (EU/UN/OFAC, PEP) + Aleph OCCRP (Panama/Pandora/FinCEN/LuxLeaks/Suisse Secrets/Offshore Leaks). Mit Risk-Score, Watchlist, Detail-Drill-down.',
      customScreenBuilder: () => const PowerNetworkExplorerScreen(),
    ),
    _DbDef(
      icon: Icons.biotech_rounded,
      label: 'Studien-Analyst',
      sub: 'PubMed + Semantic Scholar + AI',
      color: const Color(0xFF26C6DA),
      url: '',
      description:
          'Eine Suche → PubMed (35M) + Semantic Scholar (200M) parallel. Auto-Erkennung von Studien-Typ (RCT/Meta/Review), Quality-Score, AI-3-Satz-Zusammenfassung, persönliche Bibliothek.',
      customScreenBuilder: () => const StudyAnalystScreen(),
    ),
    _DbDef(
      icon: Icons.history_rounded,
      label: 'Versions-Wächter',
      sub: 'Wayback-Diff + Watchlist',
      color: const Color(0xFFFF7043),
      url: '',
      description:
          'URL eingeben → Wayback-Verlauf, beliebige 2 Snapshots vergleichen (Text-Diff: was wurde gelöscht/hinzugefügt). Watchlist alarmiert bei neuen Versionen.',
      customScreenBuilder: () => const VersionWatcherScreen(),
    ),
    _DbDef(
      icon: Icons.how_to_vote_rounded,
      label: 'EU-Parlament',
      sub: 'Live-Votes + Werte-Match',
      color: const Color(0xFF2196F3),
      url: '',
      description:
          'Letzte Plenar-Abstimmungen mit Result + Stimmen-Verteilung. 👍/👎-Markierung pro Vote baut deine Werte-Karte. MEP-Browser mit Country-Filter.',
      customScreenBuilder: () => const EuParliamentTrackerScreen(),
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
              style: TextStyle(
                  color: _kText, fontWeight: FontWeight.bold, fontSize: 18)),
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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Text(
            '${_tools.length} Recherche-Tools · Power-Network kombiniert 8 Datenbanken in einer Suche.',
            style: const TextStyle(color: _kMuted, fontSize: 13),
          ),
        ),
        if (_starred.isNotEmpty) _buildBookmarkStrip(context),
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

  Widget _buildBookmarkStrip(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
            const SizedBox(width: 6),
            const Text('Lesezeichen',
                style: TextStyle(
                    color: Colors.amber,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4)),
            const Spacer(),
            GestureDetector(
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const _OsintHistoryScreen()),
                );
                await _loadStarred();
              },
              child: const Text('Alle',
                  style: TextStyle(color: _kAccent, fontSize: 11)),
            ),
          ]),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _starred.map((s) {
              final (_, emoji, query) = s;
              return GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: query));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Kopiert: $query'),
                      duration: const Duration(seconds: 1),
                      backgroundColor: _kSurface,
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Text('$emoji $query',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _DbCard extends StatelessWidget {
  final _DbDef db;
  const _DbCard({required this.db});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (db.customScreenBuilder != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => db.customScreenBuilder!()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => _OsintWebViewScreen(db: db)),
          );
        }
      },
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
                      color: _kText,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
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
  const _OsintWebViewScreen({required this.db});

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
        onPageStarted: (url) => setState(() {
          _currentUrl = url;
          _loading = true;
        }),
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
        onWebResourceError: (_) {
          if (mounted) setState(() => _loading = false);
        },
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
  final Widget Function()? customScreenBuilder;
  const _DbDef({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.url,
    required this.description,
    this.customScreenBuilder,
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
        title:
            const Text('OSINT-Verlauf', style: TextStyle(color: Colors.white)),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: ChoiceChip(
                      label: Text(t.$2, style: const TextStyle(fontSize: 12)),
                      selected: _selectedTool == t.$1,
                      selectedColor: _kAccent.withValues(alpha: 0.25),
                      backgroundColor: Colors.white.withValues(alpha: 0.04),
                      labelStyle: TextStyle(
                        color:
                            _selectedTool == t.$1 ? _kAccent : Colors.white70,
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
                                e.starred
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color:
                                    e.starred ? Colors.amber : Colors.white38,
                              ),
                              onPressed: () => _star(e),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded,
                                  color: Colors.white38, size: 18),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: e.query));
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
