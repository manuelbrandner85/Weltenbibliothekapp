import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/free_api_service.dart';

/// 📚 Forschungs-Archiv — OpenAlex (250M+ Papers, kein API-Key)
class ResearchArchiveScreen extends StatefulWidget {
  final String roomId;
  const ResearchArchiveScreen({super.key, required this.roomId});

  @override
  State<ResearchArchiveScreen> createState() => _ResearchArchiveScreenState();
}

class _ResearchArchiveScreenState extends State<ResearchArchiveScreen> {
  final _api = FreeApiService.instance;
  final _searchCtrl = TextEditingController();

  List<OpenAlexWork> _works = [];
  bool _loading = false;
  String _query = '';
  Timer? _debounce;

  static const _defaultQueries = [
    'alternative medicine healing',
    'consciousness quantum mind',
    'ancient civilizations lost technology',
    'UFO UAP government documents',
    'telepathy parapsychology research',
    'plant medicine phytochemicals',
  ];
  int _queryIndex = 0;

  @override
  void initState() {
    super.initState();
    _search(_defaultQueries[0]);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) return;
    setState(() { _loading = true; _query = q; });
    final results = await _api.fetchOpenAlexWorks(q, limit: 20);
    if (mounted) setState(() { _works = results; _loading = false; });
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () => _search(val));
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE53935);
    const bg = Color(0xFF0D0505);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: const Color(0xFF1A0000),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Forschungs-Archiv',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [const Color(0xFF1A0000), accent.withValues(alpha: 0.15)],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.auto_stories_rounded,
                      size: 48, color: Color(0x33E53935)),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  onSubmitted: _search,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Thema suchen…',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFE53935)),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54),
                            onPressed: () {
                              _searchCtrl.clear();
                              _search(_defaultQueries[_queryIndex]);
                            })
                        : null,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Themen-Chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _defaultQueries.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final active = _query == _defaultQueries[i];
                  return GestureDetector(
                    onTap: () {
                      _searchCtrl.text = _defaultQueries[i];
                      _search(_defaultQueries[i]);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: active
                            ? accent.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active ? accent : Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        _defaultQueries[i].split(' ').take(2).join(' '),
                        style: TextStyle(
                          color: active ? accent : Colors.white70,
                          fontSize: 12,
                          fontWeight: active ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          if (_loading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: accent),
                    const SizedBox(height: 16),
                    Text('Durchsuche 250M+ Studien…',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
                  ],
                ),
              ),
            )
          else if (_works.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.find_in_page_outlined,
                        size: 64, color: Colors.white.withValues(alpha: 0.2)),
                    const SizedBox(height: 16),
                    Text('Keine Ergebnisse für "$_query"',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text(
                        '${_works.length} Open-Access Studien · OpenAlex',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                  return _WorkCard(work: _works[i - 1], accent: accent);
                },
                childCount: _works.length + 1,
              ),
            ),
        ],
      ),
    );
  }
}

class _WorkCard extends StatelessWidget {
  final OpenAlexWork work;
  final Color accent;

  const _WorkCard({required this.work, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            final url = work.openAccessUrl ?? (work.doi != null ? 'https://doi.org/${work.doi}' : null);
            if (url != null) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        work.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        work.year?.toString() ?? '—',
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (work.authors.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    work.authors.join(', '),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 11,
                    ),
                  ),
                ],
                if (work.abstract.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    work.abstract,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (work.citedBy > 0) ...[
                      Icon(Icons.format_quote_rounded,
                          size: 13, color: Colors.white.withValues(alpha: 0.4)),
                      const SizedBox(width: 3),
                      Text(
                        '${work.citedBy} Zitate',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (work.openAccessUrl != null) ...[
                      Icon(Icons.lock_open_rounded,
                          size: 13, color: const Color(0xFF4CAF50).withValues(alpha: 0.8)),
                      const SizedBox(width: 3),
                      Text(
                        'Open Access',
                        style: TextStyle(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const Spacer(),
                    ...work.concepts.take(2).map((c) => Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          color: accent.withValues(alpha: 0.8),
                          fontSize: 10,
                        ),
                      ),
                    )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
