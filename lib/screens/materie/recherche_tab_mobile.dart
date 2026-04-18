library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/recherche_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MATERIE RECHERCHE TAB – Clean rewrite
// 5 sections: SearchBar · KI-Zusammenfassung · Quellen · Bilder · Historie
// ═══════════════════════════════════════════════════════════════════════════

class MobileOptimierterRechercheTab extends StatefulWidget {
  const MobileOptimierterRechercheTab({super.key});

  @override
  State<MobileOptimierterRechercheTab> createState() =>
      _MobileOptimierterRechercheTabState();
}

class _MobileOptimierterRechercheTabState
    extends State<MobileOptimierterRechercheTab> {
  // ── Services ────────────────────────────────────────────────────────────
  final _service = RechercheService();

  // ── State ───────────────────────────────────────────────────────────────
  final _queryCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  bool _isSearching = false;
  String? _error;
  Map<String, dynamic>? _result;
  List<Map<String, dynamic>> _history = [];
  Timer? _debounce;

  // ── Design ──────────────────────────────────────────────────────────────
  static const _bg    = Color(0xFF04080F);
  static const _card  = Color(0xFF0A1020);
  static const _blue  = Color(0xFF2979FF);
  static const _blueL = Color(0xFF82B1FF);
  static const _cyan  = Color(0xFF00E5FF);

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    _scrollCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── Data ────────────────────────────────────────────────────────────────

  Future<void> _loadHistory() async {
    final h = await _service.getHistory();
    if (mounted) setState(() => _history = h);
  }

  Future<void> _search([String? query]) async {
    final q = (query ?? _queryCtrl.text).trim();
    if (q.isEmpty) return;
    _queryCtrl.text = q;
    FocusScope.of(context).unfocus();

    setState(() {
      _isSearching = true;
      _error = null;
      _result = null;
    });

    try {
      final r = await _service.search(q);
      if (mounted) {
        setState(() {
          _result = r;
          _isSearching = false;
        });
        _loadHistory();
        _scrollCtrl.animateTo(0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _deleteHistory(Map<String, dynamic> entry) async {
    await _service.deleteHistoryEntry(entry['id']);
    _loadHistory();
  }

  void _openUrl(String? url) {
    if (url == null || url.isEmpty) return;
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  // ══════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _result != null
                  ? () => _search(_result!['query'] as String?)
                  : _loadHistory,
              color: _blue,
              backgroundColor: _card,
              child: CustomScrollView(
                controller: _scrollCtrl,
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  if (_isSearching) _buildShimmer(),
                  if (_error != null && !_isSearching) _buildError(),
                  if (_result != null && !_isSearching) ...[
                    _buildSummarySection(),
                    _buildSourcesSection(),
                    _buildImagesSection(),
                  ],
                  if (_result == null && !_isSearching && _error == null)
                    _buildHistorySection(),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ──────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      color: _card,
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _queryCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: '🔍 Recherchiere ein Thema...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white38, size: 20),
                suffixIcon: _queryCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: Colors.white38, size: 18),
                        onPressed: () {
                          _queryCtrl.clear();
                          setState(() {
                            _result = null;
                            _error = null;
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _search(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_blue, Color(0xFF1A237E)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.rocket_launch,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shimmer ─────────────────────────────────────────────────────────────

  Widget _buildShimmer() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            4,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ShimmerBox(height: i == 0 ? 120 : 60),
            ),
          ),
        ),
      ),
    );
  }

  // ── Error ────────────────────────────────────────────────────────────────

  Widget _buildError() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 56),
            const SizedBox(height: 16),
            const Text(
              'Recherche fehlgeschlagen',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _search,
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section: KI-Zusammenfassung ─────────────────────────────────────────

  Widget _buildSummarySection() {
    final summary = _result?['summary'] as String? ?? '';
    if (summary.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _blue.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, color: _blue, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'KI-Zusammenfassung',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
            ]),
            const SizedBox(height: 12),
            Text(
              summary,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 14, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section: Quellen ────────────────────────────────────────────────────

  Widget _buildSourcesSection() {
    final sources = (_result?['sources'] as List?)
        ?.cast<Map<String, dynamic>>() ?? [];
    if (sources.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                '📰 Quellen (${sources.length})',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            );
          }
          return _SourceCard(
            source: sources[i - 1],
            onTap: () => _openUrl(
                sources[i - 1]['url'] as String?),
          );
        },
        childCount: sources.length + 1,
      ),
    );
  }

  // ── Section: Bilder ─────────────────────────────────────────────────────

  Widget _buildImagesSection() {
    final images = (_result?['images'] as List?)
        ?.cast<Map<String, dynamic>>() ?? [];
    if (images.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              '🖼️ Bilder',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: images.length,
              itemBuilder: (ctx, i) {
                final img = images[i];
                final url = img['url'] as String? ?? img['src'] as String? ?? '';
                return GestureDetector(
                  onTap: () => _openUrl(url),
                  child: Container(
                    width: 160,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _card,
                    ),
                    child: url.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Center(
                              child:
                                  Icon(Icons.broken_image, color: Colors.white24),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.image, color: Colors.white24),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Section: Recherche-Historie ─────────────────────────────────────────

  Widget _buildHistorySection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_history.isEmpty) ...[
              const SizedBox(height: 80),
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.search, size: 64, color: Colors.white12),
                    SizedBox(height: 16),
                    Text(
                      'Starte eine Recherche',
                      style: TextStyle(color: Colors.white38, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Gib ein Thema ein und drücke auf den Raketen-Button',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white24, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🕐 Letzte Recherchen',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  TextButton(
                    onPressed: _loadHistory,
                    child: Text('Aktualisieren',
                        style: TextStyle(color: _blueL, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._history.map(
                (entry) => _HistoryTile(
                  entry: entry,
                  onTap: () => _search(entry['query'] as String?),
                  onDelete: () => _deleteHistory(entry),
                  accentColor: _cyan,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _SourceCard extends StatelessWidget {
  final Map<String, dynamic> source;
  final VoidCallback onTap;

  const _SourceCard({required this.source, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = source['title'] as String?
        ?? source['name'] as String?
        ?? 'Ohne Titel';
    final url   = source['url'] as String? ?? '';
    final desc  = source['description'] as String?
        ?? source['snippet'] as String?
        ?? source['kurzinhalt'] as String?
        ?? '';

    String domain = '';
    try {
      if (url.isNotEmpty) domain = Uri.parse(url).host;
    } catch (_) {}

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1020),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                desc,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (domain.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.link, size: 12, color: Color(0xFF82B1FF)),
                const SizedBox(width: 4),
                Text(domain,
                    style: const TextStyle(
                        color: Color(0xFF82B1FF), fontSize: 11)),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final Map<String, dynamic> entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Color accentColor;

  const _HistoryTile({
    required this.entry,
    required this.onTap,
    required this.onDelete,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final query = entry['query'] as String? ?? '';
    final ts    = entry['timestamp'] as String? ?? '';
    String timeStr = '';
    try {
      final dt = DateTime.parse(ts).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) timeStr = 'vor ${diff.inMinutes}m';
      else if (diff.inHours < 24) timeStr = 'vor ${diff.inHours}h';
      else timeStr = 'vor ${diff.inDays}d';
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1020),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.history, color: accentColor, size: 20),
        title: Text(
          query,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: timeStr.isNotEmpty
            ? Text(timeStr,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 11))
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 16, color: Colors.white38),
          onPressed: onDelete,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double height;
  const _ShimmerBox({required this.height});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.04),
              Colors.white.withValues(alpha: 0.10 * _anim.value),
              Colors.white.withValues(alpha: 0.04),
            ],
          ),
        ),
      ),
    );
  }
}
