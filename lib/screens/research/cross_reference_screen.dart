// Cross-Reference-Screen (R7).
// Parallel-Suche ueber 10 Quellen mit collapsible Sektionen + Verlauf.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/cross_reference_service.dart';
import '../../services/free_api_service.dart';
import '../../services/research_timeline_service.dart';
import '../../services/streak_tracking_service.dart';
import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_ambient_particles.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/cinematic/wb_vignette.dart';

class CrossReferenceScreen extends StatefulWidget {
  const CrossReferenceScreen({super.key});

  @override
  State<CrossReferenceScreen> createState() => _CrossReferenceScreenState();
}

class _CrossReferenceScreenState extends State<CrossReferenceScreen> {
  static const _kHistoryKey = 'cross_ref_history_v1';
  static const _accent = Color(0xFFE53935);

  final _searchCtrl = TextEditingController();
  CrossReferenceResult? _result;
  bool _loading = false;
  String _filter = 'all';
  List<String> _history = [];
  // Collapsed sections per source.
  final Set<String> _collapsed = {};

  @override
  void initState() {
    super.initState();
    StreakTrackingService().trackToolUsage('cross_reference');
    _loadHistory();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kHistoryKey) ?? const <String>[];
    if (mounted) setState(() => _history = raw);
  }

  Future<void> _saveHistory(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = [..._history];
    list.remove(query);
    list.insert(0, query);
    while (list.length > 20) {
      list.removeLast();
    }
    await prefs.setStringList(_kHistoryKey, list);
    if (mounted) setState(() => _history = list);
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _result = null;
    });
    final res = await CrossReferenceService.instance.searchAll(query);
    if (!mounted) return;
    setState(() {
      _result = res;
      _loading = false;
    });
    await _saveHistory(query);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0606),
      extendBodyBehindAppBar: true,
      appBar: const WBGlassAppBar(title: 'Cross-Referenz', world: WBWorld.materie),
      body: Stack(
        children: [
          const IgnorePointer(child: WBAmbientParticles(world: WBWorld.materie, count: 22)),
          const WBVignette(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
              child: Column(
                children: [
                  _searchField(),
                  if (_history.isNotEmpty && _result == null && !_loading) _historyChips(),
                  if (_result != null) _filtersRow(),
                  const SizedBox(height: 8),
                  Expanded(child: _body()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withValues(alpha: 0.4)),
      ),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: const InputDecoration(
          hintText: 'Suchbegriff (z.B. Snowden, NSA, Watergate)...',
          hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded, color: _accent),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        onSubmitted: _search,
      ),
    );
  }

  Widget _historyChips() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: _history.take(8).map((q) {
          return GestureDetector(
            onTap: () {
              _searchCtrl.text = q;
              _search(q);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history_rounded, color: Colors.white38, size: 13),
                  const SizedBox(width: 5),
                  Text(q, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _filtersRow() {
    final r = _result!;
    final filters = <(String, String, int)>[
      ('all', 'Alle', r.totalCount),
      ('wiki', 'Wiki', r.wikidataEntries.length + r.wikipediaArticles.length),
      (
        'study',
        'Studien',
        r.openAlexWorks.length + r.pubmedStudies.length + r.crossRefWorks.length,
      ),
      ('preprint', 'Preprints', r.arxivPapers.length),
      ('news', 'Nachrichten', r.gdeltArticles.length + r.guardianArticles.length),
      ('archive', 'Archiv', r.timelineEvents.length + r.archiveDocs.length),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final sel = _filter == f.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => setState(() => _filter = f.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel
                        ? _accent.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel ? _accent : Colors.white.withValues(alpha: 0.12),
                      width: sel ? 1.4 : 1,
                    ),
                  ),
                  child: Text(
                    '${f.$2} (${f.$3})',
                    style: TextStyle(
                      color: sel ? Colors.white : Colors.white70,
                      fontSize: 12,
                      fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _accent),
            SizedBox(height: 14),
            Text('Suche in 10 Quellen...', style: TextStyle(color: Colors.white60, fontSize: 13)),
          ],
        ),
      );
    }
    if (_result == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.travel_explore_rounded,
                size: 80,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cross-Referenz-Suche\nueber Wikidata, Wikipedia, Studien,\n'
                'arXiv, Nachrichten, Archiv -- 10 Quellen parallel.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 13.5, height: 1.55),
              ),
            ],
          ),
        ),
      );
    }
    final r = _result!;
    if (r.isEmpty) {
      return const Center(
        child: Text('Keine Treffer.', style: TextStyle(color: Colors.white60)),
      );
    }
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            '${r.totalCount} Treffer in ${r.searchDuration.inMilliseconds} ms aus 10 Quellen',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ),
        if (_includesSection('wiki') && r.wikidataEntries.isNotEmpty)
          _section(
            'Wikidata',
            '🌐',
            r.wikidataEntries.length,
            'wiki',
            () => r.wikidataEntries.map(_wikidataTile).toList(),
          ),
        if (_includesSection('wiki') && r.wikipediaArticles.isNotEmpty)
          _section(
            'Wikipedia',
            '📖',
            r.wikipediaArticles.length,
            'wikipedia',
            () => r.wikipediaArticles.map(_wikipediaTile).toList(),
          ),
        if (_includesSection('study') && r.openAlexWorks.isNotEmpty)
          _section(
            'OpenAlex (Studien)',
            '📚',
            r.openAlexWorks.length,
            'openalex',
            () => r.openAlexWorks.map(_openAlexTile).toList(),
          ),
        if (_includesSection('study') && r.pubmedStudies.isNotEmpty)
          _section(
            'PubMed',
            '🧬',
            r.pubmedStudies.length,
            'pubmed',
            () => r.pubmedStudies.map(_pubmedTile).toList(),
          ),
        if (_includesSection('study') && r.crossRefWorks.isNotEmpty)
          _section(
            'CrossRef',
            '📖',
            r.crossRefWorks.length,
            'crossref',
            () => r.crossRefWorks.map(_crossRefTile).toList(),
          ),
        if (_includesSection('preprint') && r.arxivPapers.isNotEmpty)
          _section(
            'arXiv (Preprints)',
            '🔬',
            r.arxivPapers.length,
            'arxiv',
            () => r.arxivPapers.map(_arxivTile).toList(),
          ),
        if (_includesSection('news') && r.guardianArticles.isNotEmpty)
          _section(
            'The Guardian',
            '📰',
            r.guardianArticles.length,
            'guardian',
            () => r.guardianArticles.map(_guardianTile).toList(),
          ),
        if (_includesSection('news') && r.gdeltArticles.isNotEmpty)
          _section(
            'GDELT (Live)',
            '🌍',
            r.gdeltArticles.length,
            'gdelt',
            () => r.gdeltArticles.map(_gdeltTile).toList(),
          ),
        if (_includesSection('archive') && r.timelineEvents.isNotEmpty)
          _section(
            'Eigenes Archiv',
            '🗄️',
            r.timelineEvents.length,
            'archive',
            () => r.timelineEvents.map(_timelineTile).toList(),
          ),
        if (_includesSection('archive') && r.archiveDocs.isNotEmpty)
          _section(
            'Internet Archive',
            '🏛️',
            r.archiveDocs.length,
            'internet-archive',
            () => r.archiveDocs.map(_archiveDocTile).toList(),
          ),
        const SizedBox(height: 30),
      ],
    );
  }

  bool _includesSection(String type) {
    if (_filter == 'all') return true;
    // 'wiki' filter shows both wikidata and wikipedia sections.
    if (_filter == 'wiki') return type == 'wiki' || type == 'wikipedia';
    // 'archive' filter shows both timeline and internet-archive sections.
    if (_filter == 'archive') {
      return type == 'archive' || type == 'internet-archive';
    }
    // 'study' filter shows openalex, pubmed, crossref.
    if (_filter == 'study') {
      return type == 'openalex' || type == 'pubmed' || type == 'crossref';
    }
    // 'news' filter shows guardian and gdelt.
    if (_filter == 'news') return type == 'guardian' || type == 'gdelt';
    return _filter == type;
  }

  Widget _section(
    String title,
    String emoji,
    int count,
    String key,
    List<Widget> Function() builder,
  ) {
    final collapsed = _collapsed.contains(key);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _accent.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            ListTile(
              dense: true,
              leading: Text(emoji, style: const TextStyle(fontSize: 20)),
              title: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Color(0xFFFF8A80),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(collapsed ? Icons.expand_more : Icons.expand_less, color: Colors.white60),
                ],
              ),
              onTap: () => setState(() {
                if (collapsed) {
                  _collapsed.remove(key);
                } else {
                  _collapsed.add(key);
                }
              }),
            ),
            if (!collapsed)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                child: Column(children: builder()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _baseResultTile({
    required String title,
    required String subtitle,
    required String body,
    String? url,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: url == null ? null : () => _openUrl(url),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _accent.withValues(alpha: 0.9), fontSize: 11),
                ),
              ],
              if (body.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _wikidataTile(WikidataEntry e) =>
      _baseResultTile(title: e.label, subtitle: e.id, body: e.description ?? '', url: e.url);

  Widget _timelineTile(TimelineEventV2 e) => _baseResultTile(
    title: e.title,
    subtitle: '${e.dateDisplay} · ${e.category}',
    body: e.description,
    url: e.sources.isNotEmpty ? e.sources.first : null,
  );

  Widget _openAlexTile(OpenAlexWork w) => _baseResultTile(
    title: w.title,
    subtitle: '${w.year ?? ''} · ${w.authors.take(2).join(", ")}',
    body: w.abstract,
    url: w.openAccessUrl ?? w.id,
  );

  Widget _pubmedTile(PubMedStudy s) => _baseResultTile(
    title: s.title,
    subtitle: '${s.source ?? "PubMed"} · ${s.pubDate ?? ""}',
    body: s.authors.join(', '),
    url: s.pubmedUrl,
  );

  Widget _crossRefTile(CrossRefWork w) => _baseResultTile(
    title: w.title,
    subtitle: '${w.year ?? ''} · ${w.publisher}',
    body: 'Zitiert: ${w.citedBy}x',
    url: 'https://doi.org/${w.doi}',
  );

  Widget _guardianTile(GuardianArticle a) => _baseResultTile(
    title: a.webTitle,
    subtitle: '${a.sectionName ?? ""} · ${a.webPublicationDate ?? ""}',
    body: a.trailText ?? '',
    url: a.webUrl,
  );

  Widget _gdeltTile(GdeltArticle a) => _baseResultTile(
    title: a.title,
    subtitle: '${a.domain} · ${a.seendate}',
    body: '',
    url: a.url,
  );

  Widget _wikipediaTile(WikiSearchEntry e) => _baseResultTile(
    title: e.title,
    subtitle: 'Wikipedia ${e.lang.toUpperCase()}',
    body: e.snippet,
    url: e.url,
  );

  Widget _arxivTile(ArxivEntry e) => _baseResultTile(
    title: e.title,
    subtitle: '${e.published} · ${e.authorsDisplay}',
    body: e.summary,
    url: e.url,
  );

  Widget _archiveDocTile(InternetArchiveDoc d) => _baseResultTile(
    title: d.title.isNotEmpty ? d.title : d.identifier,
    subtitle: '${d.mediatypeLabel}${d.date != null ? " · ${d.date}" : ""}',
    body: d.description ?? '',
    url: d.url,
  );
}
