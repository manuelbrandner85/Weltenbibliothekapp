// Additional-Sources (R3): erweiterte Quellenliste mit In-App-Browser,
// Lesezeichen-System (SharedPreferences) und optionaler Auto-Translation
// via Google Translate Wrapper.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class _Source {
  final String title;
  final String description;
  final String url;
  final IconData icon;
  final Color color;
  final String category;
  const _Source({
    required this.title,
    required this.description,
    required this.url,
    required this.icon,
    required this.color,
    required this.category,
  });
}

const _accent = Color(0xFFE53935);
const _bg = Color(0xFF0A0A0A);
const _surface = Color(0xFF1A0000);

const _sources = <_Source>[
  // Whistleblowing & Investigations
  _Source(
    title: 'WikiLeaks',
    description: 'Whistleblowing-Plattform mit geheimen Dokumenten',
    url: 'https://wikileaks.org',
    icon: Icons.shield_outlined,
    color: Colors.green,
    category: 'Whistleblowing',
  ),
  _Source(
    title: 'ProPublica',
    description: 'Investigativer Journalismus',
    url: 'https://www.propublica.org',
    icon: Icons.article,
    color: Colors.cyan,
    category: 'Whistleblowing',
  ),
  _Source(
    title: 'ICIJ (Panama Papers)',
    description: 'International Consortium of Investigative Journalists',
    url: 'https://www.icij.org',
    icon: Icons.public,
    color: Colors.teal,
    category: 'Whistleblowing',
  ),
  _Source(
    title: 'The Black Vault',
    description: 'FOIA Dokumente & Government Secrets',
    url: 'https://www.theblackvault.com',
    icon: Icons.lock_open,
    color: Colors.grey,
    category: 'Whistleblowing',
  ),

  // Government Archives - US
  _Source(
    title: 'CIA FOIA Reading Room',
    description: 'Freigegebene CIA-Dokumente',
    url: 'https://www.cia.gov/readingroom/',
    icon: Icons.folder_open,
    color: Colors.orange,
    category: 'US Government',
  ),
  _Source(
    title: 'FBI Vault',
    description: 'FBI Freedom of Information Act Dokumente',
    url: 'https://vault.fbi.gov',
    icon: Icons.account_balance,
    color: Colors.red,
    category: 'US Government',
  ),
  _Source(
    title: 'National Security Archive',
    description: 'Declassified US Government Documents',
    url: 'https://nsarchive.gwu.edu',
    icon: Icons.security,
    color: Colors.purple,
    category: 'US Government',
  ),
  _Source(
    title: 'CourtListener',
    description: 'US Gerichtsentscheidungen, Dockets, RECAP',
    url: 'https://www.courtlistener.com',
    icon: Icons.gavel,
    color: Colors.brown,
    category: 'US Government',
  ),
  _Source(
    title: 'PACER',
    description: 'Public Access to US Court Electronic Records',
    url: 'https://pacer.uscourts.gov',
    icon: Icons.balance,
    color: Colors.deepOrange,
    category: 'US Government',
  ),
  _Source(
    title: 'Government Attic',
    description: 'FOIA-Antworten - Original-Dokumente Archiv',
    url: 'https://www.governmentattic.org',
    icon: Icons.inventory_2_outlined,
    color: Colors.amber,
    category: 'US Government',
  ),

  // Government Archives - International
  _Source(
    title: 'UK National Archives',
    description: 'Britisches Staatsarchiv - declassified records',
    url: 'https://www.nationalarchives.gov.uk',
    icon: Icons.account_balance_outlined,
    color: Colors.indigo,
    category: 'International',
  ),
  _Source(
    title: 'EU Parliament',
    description: 'Europaeisches Parlament - Dokumente & Anfragen',
    url: 'https://www.europarl.europa.eu',
    icon: Icons.flag,
    color: Colors.blue,
    category: 'International',
  ),
  _Source(
    title: 'Bundestag - Dokumente',
    description: 'Drucksachen, Anfragen, Protokolle',
    url: 'https://dip.bundestag.de',
    icon: Icons.account_balance,
    color: Colors.black87,
    category: 'International',
  ),
  _Source(
    title: 'Council of Europe',
    description: 'Europarat - Vertraege, Resolutionen',
    url: 'https://www.coe.int',
    icon: Icons.gavel_outlined,
    color: Colors.deepPurple,
    category: 'International',
  ),

  // Libraries / Open Knowledge
  _Source(
    title: 'Internet Archive',
    description: 'Digitale Bibliothek mit historischen Dokumenten',
    url: 'https://archive.org',
    icon: Icons.library_books,
    color: Colors.blue,
    category: 'Bibliotheken',
  ),
  _Source(
    title: 'arXiv',
    description: 'Preprint-Server fuer Physik, Math, CS',
    url: 'https://arxiv.org',
    icon: Icons.science,
    color: Colors.lightBlue,
    category: 'Bibliotheken',
  ),
  _Source(
    title: 'PubMed',
    description: 'Biomedizinische Literatur-Datenbank',
    url: 'https://pubmed.ncbi.nlm.nih.gov',
    icon: Icons.biotech,
    color: Colors.lightGreen,
    category: 'Bibliotheken',
  ),

  // German Archives & Transparency
  _Source(
    title: 'FragDenStaat',
    description: 'IFG-Anfragen an deutsche Behoerden stellen und einsehen',
    url: 'https://fragdenstaat.de',
    icon: Icons.question_answer_outlined,
    color: Colors.teal,
    category: 'DE Archiv',
  ),
  _Source(
    title: 'Bundesarchiv',
    description: 'Nationales Gedaechtnis Deutschlands – Akten, Fotos, Filme',
    url: 'https://www.bundesarchiv.de',
    icon: Icons.account_balance_outlined,
    color: Colors.grey,
    category: 'DE Archiv',
  ),
  _Source(
    title: 'Netzpolitik.org',
    description: 'Investigativer Journalismus zu Digitalpolitik & Ueberwachung',
    url: 'https://netzpolitik.org',
    icon: Icons.computer_outlined,
    color: Colors.cyan,
    category: 'DE Archiv',
  ),
  _Source(
    title: 'LobbyControl',
    description: 'Transparenz ueber Lobbyismus und Interessengruppen in DE',
    url: 'https://www.lobbycontrol.de',
    icon: Icons.group_outlined,
    color: Colors.orange,
    category: 'DE Archiv',
  ),
  _Source(
    title: 'Abgeordnetenwatch',
    description: 'Anfragen an Parlamentsabgeordnete, Abstimmungsverhalten',
    url: 'https://www.abgeordnetenwatch.de',
    icon: Icons.how_to_vote_outlined,
    color: Colors.indigo,
    category: 'DE Archiv',
  ),

  // Open Science & Academic
  _Source(
    title: 'CORE.ac.uk',
    description: '200M+ Open-Access Forschungsartikel weltweit',
    url: 'https://core.ac.uk',
    icon: Icons.science_outlined,
    color: Colors.deepPurple,
    category: 'Offene Wissenschaft',
  ),
  _Source(
    title: 'Semantic Scholar',
    description: 'KI-gestuetzte Suche in 200M+ wissenschaftlichen Papieren',
    url: 'https://www.semanticscholar.org',
    icon: Icons.psychology_outlined,
    color: Colors.blue,
    category: 'Offene Wissenschaft',
  ),
  _Source(
    title: 'Zenodo',
    description:
        'Offenes CERN-Repository fuer Forschungsdaten und Publikationen',
    url: 'https://zenodo.org',
    icon: Icons.cloud_download_outlined,
    color: Colors.lightBlue,
    category: 'Offene Wissenschaft',
  ),
  _Source(
    title: 'SSRN',
    description: 'Preprints in Wirtschaft, Recht, Sozialwissenschaften',
    url: 'https://www.ssrn.com',
    icon: Icons.article_outlined,
    color: Colors.amber,
    category: 'Offene Wissenschaft',
  ),
  _Source(
    title: 'OpenAlex',
    description: '250M+ vernetzte Werke, Autoren, Institutionen',
    url: 'https://openalex.org',
    icon: Icons.hub_outlined,
    color: Colors.green,
    category: 'Offene Wissenschaft',
  ),

  // Fact-Checkers
  _Source(
    title: 'Correctiv',
    description: 'Investigativer Journalismus und Faktenchecks auf Deutsch',
    url: 'https://correctiv.org',
    icon: Icons.fact_check_outlined,
    color: Colors.red,
    category: 'Faktencheck',
  ),
  _Source(
    title: 'ARD Faktenfinder',
    description: 'Faktencheck-Redaktion der ARD',
    url: 'https://www.tagesschau.de/faktenfinder/',
    icon: Icons.verified_outlined,
    color: Colors.blue,
    category: 'Faktencheck',
  ),
  _Source(
    title: 'Mimikama',
    description: 'Aufklaerung ueber Fake News und Online-Betrug',
    url: 'https://www.mimikama.org',
    icon: Icons.warning_amber_outlined,
    color: Colors.orange,
    category: 'Faktencheck',
  ),
  _Source(
    title: 'Snopes',
    description: 'Englischsprachige Faktencheck-Referenz seit 1994',
    url: 'https://www.snopes.com',
    icon: Icons.search_outlined,
    color: Colors.teal,
    category: 'Faktencheck',
  ),

  // Corporate & Financial Transparency
  _Source(
    title: 'OpenCorporates',
    description: 'Groeßte offene Datenbank zu Unternehmen weltweit',
    url: 'https://opencorporates.com',
    icon: Icons.business_outlined,
    color: Colors.deepOrange,
    category: 'Wirtschaft',
  ),
  _Source(
    title: 'SEC EDGAR',
    description: 'US-Boersenaufsicht: Pflichtberichte boersennotierter Firmen',
    url: 'https://www.sec.gov/cgi-bin/browse-edgar',
    icon: Icons.bar_chart_outlined,
    color: Colors.brown,
    category: 'Wirtschaft',
  ),
  _Source(
    title: 'ICIJ OffshoreLeaks',
    description: 'Datenbank zu Offshore-Netzwerken (Panama/Pandora Papers)',
    url: 'https://offshoreleaks.icij.org',
    icon: Icons.leak_add_outlined,
    color: Colors.red,
    category: 'Wirtschaft',
  ),
  _Source(
    title: 'OpenSpending',
    description: 'Regierungs-Ausgaben und Budgets weltweit transparent',
    url: 'https://openspending.org',
    icon: Icons.account_balance_wallet_outlined,
    color: Colors.green,
    category: 'Wirtschaft',
  ),
];

class AdditionalSourcesScreen extends StatefulWidget {
  const AdditionalSourcesScreen({super.key});

  @override
  State<AdditionalSourcesScreen> createState() =>
      _AdditionalSourcesScreenState();
}

class _AdditionalSourcesScreenState extends State<AdditionalSourcesScreen> {
  static const _bookmarksKey = 'research_bookmarks_v1';

  Set<String> _bookmarks = {};
  String _filterCategory = 'all';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_bookmarksKey) ?? [];
      if (!mounted) return;
      setState(() => _bookmarks = list.toSet());
    } catch (e) {
      if (kDebugMode)
        debugPrint('additional_sources_screen: silent catch -> $e');
    }
  }

  Future<void> _toggleBookmark(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final next = Set<String>.from(_bookmarks);
      if (next.contains(url)) {
        next.remove(url);
      } else {
        next.add(url);
      }
      await prefs.setStringList(_bookmarksKey, next.toList());
      if (!mounted) return;
      setState(() => _bookmarks = next);
    } catch (e) {
      if (kDebugMode)
        debugPrint('additional_sources_screen: silent catch -> $e');
    }
  }

  List<_Source> get _filtered {
    final q = _search.trim().toLowerCase();
    return _sources.where((s) {
      if (_filterCategory == 'bookmarks' && !_bookmarks.contains(s.url)) {
        return false;
      }
      if (_filterCategory != 'all' &&
          _filterCategory != 'bookmarks' &&
          s.category != _filterCategory) {
        return false;
      }
      if (q.isNotEmpty &&
          !s.title.toLowerCase().contains(q) &&
          !s.description.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
  }

  List<String> get _categories {
    final set = <String>{};
    for (final s in _sources) {
      set.add(s.category);
    }
    return set.toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Keine Quellen.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _SourceCard(
                      source: filtered[i],
                      bookmarked: _bookmarks.contains(filtered[i].url),
                      onTap: () => _openSource(filtered[i]),
                      onBookmark: () => _toggleBookmark(filtered[i].url),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Quellen durchsuchen ...',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 13,
          ),
          prefixIcon: const Icon(Icons.search, color: _accent, size: 20),
          filled: true,
          fillColor: _surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 0,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _accent.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _accent),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final cats = [
      const MapEntry('all', 'Alle'),
      const MapEntry('bookmarks', 'Lesezeichen'),
      ..._categories.map((c) => MapEntry(c, c)),
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final e = cats[i];
          final sel = _filterCategory == e.key;
          return ChoiceChip(
            label: Text(e.value),
            selected: sel,
            onSelected: (_) => setState(() => _filterCategory = e.key),
            labelStyle: TextStyle(
              color: sel ? Colors.white : Colors.white70,
              fontSize: 11,
              fontWeight: sel ? FontWeight.bold : FontWeight.normal,
            ),
            backgroundColor: _surface,
            selectedColor: _accent,
            side: BorderSide(
              color: sel ? _accent : _accent.withValues(alpha: 0.3),
            ),
          );
        },
      ),
    );
  }

  void _openSource(_Source source) {
    if (kIsWeb) {
      // Auf Web direkt extern oeffnen (WebView-Plugin verhaelt sich anders).
      _launchExternal(source.url);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _SourceWebViewScreen(source: source)),
    );
  }

  Future<void> _launchExternal(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _SourceCard extends StatelessWidget {
  final _Source source;
  final bool bookmarked;
  final VoidCallback onTap;
  final VoidCallback onBookmark;

  const _SourceCard({
    required this.source,
    required this.bookmarked,
    required this.onTap,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: source.color.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: source.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(source.icon, color: source.color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              source.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: source.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              source.category,
                              style: TextStyle(
                                color: source.color,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        source.description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    bookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: bookmarked ? _accent : Colors.white54,
                  ),
                  onPressed: onBookmark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SourceWebViewScreen extends StatefulWidget {
  final _Source source;
  const _SourceWebViewScreen({required this.source});

  @override
  State<_SourceWebViewScreen> createState() => _SourceWebViewScreenState();
}

class _SourceWebViewScreenState extends State<_SourceWebViewScreen> {
  late final WebViewController _controller;
  bool _translateEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onNavigationRequest: (req) {
            if (_translateEnabled &&
                req.url.startsWith('http') &&
                !req.url.contains('translate.google.com')) {
              final translated =
                  'https://translate.google.com/translate?sl=auto&tl=de&u=${Uri.encodeComponent(req.url)}';
              _controller.loadRequest(Uri.parse(translated));
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.source.url));
  }

  void _toggleTranslate() {
    setState(() => _translateEnabled = !_translateEnabled);
    final current = _translateEnabled
        ? 'https://translate.google.com/translate?sl=auto&tl=de&u=${Uri.encodeComponent(widget.source.url)}'
        : widget.source.url;
    _controller.loadRequest(Uri.parse(current));
  }

  Future<void> _openExternal() async {
    final uri = Uri.parse(widget.source.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        title: Text(
          widget.source.title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        iconTheme: const IconThemeData(color: _accent),
        actions: [
          IconButton(
            icon: Icon(
              _translateEnabled ? Icons.translate : Icons.g_translate_outlined,
              color: _translateEnabled ? _accent : Colors.white70,
            ),
            tooltip: _translateEnabled
                ? 'Uebersetzung aus'
                : 'Auf Deutsch uebersetzen',
            onPressed: _toggleTranslate,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => _controller.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser, color: Colors.white70),
            onPressed: _openExternal,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_loading)
            const LinearProgressIndicator(
              color: _accent,
              backgroundColor: _surface,
              minHeight: 2,
            ),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}
