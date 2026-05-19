import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/knowledge_extended_models.dart';
import '../../services/unified_knowledge_service.dart';
import 'knowledge_reader_mode.dart';
import '../wissen/cinematic_book_reader_screen.dart'; // v5.44.6 Buecher
import '../../widgets/wissen/bookshelf_3d_view.dart'; // v5.44.7 Bookshelf
import 'advanced_search_delegate.dart';
import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/cinematic/wb_vignette.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CINEMATIC WISSEN-TAB  ·  Weltenbibliothek
// ─────────────────────────────────────────────────────────────────────────────

class UnifiedKnowledgeTab extends StatefulWidget {
  final String world;
  const UnifiedKnowledgeTab({super.key, required this.world});

  @override
  State<UnifiedKnowledgeTab> createState() => _UnifiedKnowledgeTabState();
}

class _UnifiedKnowledgeTabState extends State<UnifiedKnowledgeTab>
    with TickerProviderStateMixin {
  final _svc = UnifiedKnowledgeService();

  List<KnowledgeEntry> _all = [];
  List<KnowledgeEntry> _filtered = [];
  Map<String, int> _stats = {};
  bool _isLoading = true;
  String _cat = 'all';
  int _tab = 0; // 0 Entdecken | 1 Gespeichert | 2 Verlauf | 3 Für dich
  // v5.44.7: View-Mode-Toggle - Liste (default) oder Bookshelf-3D
  bool _bookshelfView = false;

  late AnimationController _ambient;
  late AnimationController _pulse;

  // ── world palette ──────────────────────────────────────────────────────────
  bool get _isMaterie => widget.world == 'materie';
  Color get _primary {
    switch (widget.world) {
      case 'materie': return const Color(0xFF3B82F6);
      case 'energie': return const Color(0xFFA855F7);
      case 'vorhang': return const Color(0xFFC9A84C);
      case 'ursprung': return const Color(0xFF00D4AA);
      default:        return const Color(0xFFA855F7);
    }
  }
  Color get _primarySoft {
    switch (widget.world) {
      case 'materie': return const Color(0xFF60A5FA);
      case 'energie': return const Color(0xFFC084FC);
      case 'vorhang': return const Color(0xFFE0C872);
      case 'ursprung': return const Color(0xFF40E8C0);
      default:        return const Color(0xFFC084FC);
    }
  }
  Color get _deep {
    switch (widget.world) {
      case 'materie': return const Color(0xFF020A1C);
      case 'energie': return const Color(0xFF0A0118);
      case 'vorhang': return const Color(0xFF050300);
      case 'ursprung': return const Color(0xFF020F0C);
      default:        return const Color(0xFF0A0118);
    }
  }

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _load();
  }

  @override
  void dispose() {
    _ambient.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final entries = await _svc.getAllEntries(world: widget.world);
      final stats = await _svc.getStatistics(widget.world);
      if (mounted) {
        setState(() {
          _all = entries;
          _filtered = entries;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    setState(() {
      _filtered = _all.where((e) => _cat == 'all' || e.category == _cat).toList();
    });
  }

  void _openEntry(KnowledgeEntry entry) async {
    await _svc.incrementViewCount(entry.id);
    if (!mounted) return;
    // v5.44.6: Buecher (type='book') bekommen den neuen Cinematic-Reader
    // mit 3D-Cover + Quote-Karten. Artikel/Practices/Research bleiben im
    // alten Markdown-Reader.
    final isBook = entry.type == 'book';
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => isBook
            ? CinematicBookReaderScreen(book: entry)
            : KnowledgeReaderMode(entry: entry, world: widget.world),
      ),
    );
    _load();
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildSkeleton();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabPills(),
          if (_tab == 0) _buildCategoryPills(),
          Expanded(child: _buildContent()),
        ],
      ),
      floatingActionButton: _tab == 0
          ? _SearchFAB(
              primary: _primary,
              onTap: () => showSearch(
                context: context,
                delegate: AdvancedSearchDelegate(world: widget.world),
              ),
            )
          : null,
    );
  }

  // ── CINEMATIC HEADER ───────────────────────────────────────────────────────
  Widget _buildHeader() {
    final total = _stats['total'] ?? _all.length;
    final read = _stats['read'] ?? 0;
    final favs = _stats['favorites'] ?? 0;
    final pct = total > 0 ? read / total : 0.0;

    return SizedBox(
      height: 210,
      child: Stack(
        children: [
          // Animated ambient background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_ambient, _pulse]),
              builder: (_, __) => CustomPaint(
                painter: _AmbientPainter(
                  progress: _ambient.value,
                  pulse: _pulse.value,
                  primary: _primary,
                  isMaterie: _isMaterie,
                ),
              ),
            ),
          ),
          // Deep gradient overlay (bottom fade to bg)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    _deep.withValues(alpha: 0.6),
                    _deep,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Eyebrow
                  Row(children: [
                    Container(
                      width: 3, height: 12,
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [BoxShadow(color: _primary, blurRadius: 8)],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      () {
                        switch (widget.world) {
                          case 'materie': return 'MATERIE · BIBLIOTHEK';
                          case 'energie': return 'ENERGIE · BIBLIOTHEK';
                          case 'vorhang': return 'VORHANG · BIBLIOTHEK';
                          case 'ursprung': return 'URSPRUNG · BIBLIOTHEK';
                          default: return 'BIBLIOTHEK';
                        }
                      }(),
                      style: TextStyle(
                        fontSize: 10, letterSpacing: 3.5,
                        color: _primary, fontWeight: FontWeight.w700,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  // Title
                  Text(
                    'Wissen',
                    style: TextStyle(
                      fontSize: 40, fontWeight: FontWeight.w200,
                      letterSpacing: 3, color: Colors.white, height: 1,
                      shadows: [Shadow(color: _primary.withValues(alpha: 0.4), blurRadius: 30)],
                    ),
                  ),
                  const Spacer(),
                  // Stats row
                  Row(children: [
                    _StatPill(icon: Icons.library_books, label: '$total Einträge', color: _primary),
                    const SizedBox(width: 10),
                    _StatPill(icon: Icons.check_circle, label: '$read gelesen', color: const Color(0xFF34D399)),
                    const SizedBox(width: 10),
                    _StatPill(icon: Icons.bookmark, label: '$favs gespeichert', color: const Color(0xFFFBBF24)),
                  ]),
                  const SizedBox(height: 10),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(_primary),
                      minHeight: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB PILLS ─────────────────────────────────────────────────────────────
  Widget _buildTabPills() {
    final tabs = [
      (Icons.explore, 'Entdecken'),
      (Icons.bookmark, 'Gespeichert'),
      (Icons.history, 'Verlauf'),
      (Icons.auto_awesome, 'Für dich'),
    ];
    return Container(
      color: _deep,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = _tab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _tab = i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: active ? _primary.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: active ? _primary.withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.10),
                    width: active ? 1.4 : 1,
                  ),
                  boxShadow: active
                      ? [BoxShadow(color: _primary.withValues(alpha: 0.28), blurRadius: 12)]
                      : null,
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(tabs[i].$1, size: 15, color: active ? _primary : Colors.white.withValues(alpha: 0.45)),
                  const SizedBox(height: 3),
                  Text(tabs[i].$2, style: TextStyle(
                    fontSize: 9,
                    color: active ? _primary : Colors.white.withValues(alpha: 0.40),
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    letterSpacing: 0.3,
                  )),
                ]),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── CATEGORY PILLS ────────────────────────────────────────────────────────
  Widget _buildCategoryPills() {
    final List<(String, IconData, String)> cats;
    switch (widget.world) {
      case 'materie':
        cats = [
          ('all', Icons.grid_view, 'Alle'),
          ('conspiracy', Icons.visibility_off, 'Verschwörung'),
          ('ancientWisdom', Icons.history_edu, 'Alte Weisheit'),
          ('forbiddenKnowledge', Icons.lock, 'Verboten'),
          ('books', Icons.menu_book, 'Bücher'),
        ];
        break;
      case 'vorhang':
        cats = [
          ('all', Icons.grid_view, 'Alle'),
          ('power', Icons.psychology, 'Macht'),
          ('secret', Icons.lock, 'Geheimwissen'),
          ('strategy', Icons.flag, 'Strategie'),
          ('shadow', Icons.nights_stay, 'Schatten'),
        ];
        break;
      case 'ursprung':
        cats = [
          ('all', Icons.grid_view, 'Alle'),
          ('consciousness', Icons.blur_on, 'Bewusstsein'),
          ('indigenous', Icons.public, 'Naturvölker'),
          ('cosmology', Icons.auto_awesome, 'Kosmologie'),
          ('ancient', Icons.account_balance, 'Urgeschichte'),
        ];
        break;
      default: // energie
        cats = [
          ('all', Icons.grid_view, 'Alle'),
          ('meditation', Icons.self_improvement, 'Meditation'),
          ('astrology', Icons.stars, 'Astrologie'),
          ('crystals', Icons.diamond, 'Kristalle'),
          ('consciousness', Icons.psychology, 'Bewusstsein'),
          ('energyWork', Icons.bolt, 'Energie'),
        ];
    }

    return Container(
      color: _deep,
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (id, icon, label) = cats[i];
          final active = _cat == id;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _cat = id;
                _applyFilter();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: active ? _primary.withValues(alpha: 0.20) : Colors.white.withValues(alpha: 0.06),
                border: Border.all(
                  color: active ? _primary.withValues(alpha: 0.60) : Colors.white.withValues(alpha: 0.14),
                  width: active ? 1.5 : 1,
                ),
                boxShadow: active ? [BoxShadow(color: _primary.withValues(alpha: 0.32), blurRadius: 10)] : null,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 12, color: active ? _primary : Colors.white.withValues(alpha: 0.55)),
                const SizedBox(width: 5),
                Text(label, style: TextStyle(
                  fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  color: active ? _primary : Colors.white.withValues(alpha: 0.65),
                )),
              ]),
            ),
          );
        },
      ),
    );
  }

  // ── CONTENT ROUTER ────────────────────────────────────────────────────────
  Widget _buildContent() {
    return switch (_tab) {
      0 => _buildExplore(),
      1 => _buildSaved(),
      2 => _buildHistory(),
      _ => _buildForYou(),
    };
  }

  // ── TAB 0: ENTDECKEN ──────────────────────────────────────────────────────
  Widget _buildExplore() {
    if (_filtered.isEmpty) return _buildEmptyState();

    // v5.44.7: Bookshelf-Modus zeigt nur Buecher als 3D-Regal
    if (_bookshelfView) {
      final books = _filtered.where((e) => e.type == 'book').toList();
      return Column(children: [
        _buildViewModeBar(),
        Expanded(
          child: Bookshelf3DView(
            books: books,
            world: widget.world,
            onTap: _openEntry,
          ),
        ),
      ]);
    }

    final featured = _all.where((e) => e.rating >= 4.0).take(6).toList();

    return RefreshIndicator(
      onRefresh: _load,
      color: _primary,
      backgroundColor: _deep,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildViewModeBar()),
          // Featured horizontal row
          if (featured.isNotEmpty) ...[
            SliverToBoxAdapter(child: _sectionHeader('EMPFOHLEN', Icons.auto_awesome)),
            SliverToBoxAdapter(child: _buildFeaturedRow(featured)),
            SliverToBoxAdapter(child: _sectionHeader('ALLE EINTRÄGE', Icons.grid_view)),
          ],
          // Grid
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _CinematicCard(
                  entry: _filtered[i],
                  primary: _primary,
                  svc: _svc,
                  onTap: () => _openEntry(_filtered[i]),
                ),
                childCount: _filtered.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
    );
  }

  /// v5.44.7: Toggle-Bar zwischen Liste/Grid und Bookshelf-3D-View.
  /// Bookshelf zeigt nur Eintraege mit type='book'.
  Widget _buildViewModeBar() {
    final bookCount = _filtered.where((e) => e.type == 'book').length;
    if (bookCount < 3) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$bookCount Buecher',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 10),
          _ViewModeChip(
            label: 'Liste',
            icon: Icons.view_module,
            selected: !_bookshelfView,
            primary: _primary,
            onTap: () => setState(() => _bookshelfView = false),
          ),
          const SizedBox(width: 6),
          _ViewModeChip(
            label: 'Regal',
            icon: Icons.menu_book_outlined,
            selected: _bookshelfView,
            primary: _primary,
            onTap: () => setState(() => _bookshelfView = true),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedRow(List<KnowledgeEntry> items) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _FeaturedCard(
          entry: items[i],
          primary: _primary,
          deep: _deep,
          onTap: () => _openEntry(items[i]),
        ),
      ),
    );
  }

  // ── TAB 1: GESPEICHERT ────────────────────────────────────────────────────
  Widget _buildSaved() {
    return FutureBuilder<List<KnowledgeEntry>>(
      future: _svc.getFavorites(world: widget.world),
      builder: (_, snap) {
        if (!snap.hasData) return _buildSpinner();
        final items = snap.data!;
        if (items.isEmpty) {
          return _buildEmptyState(
            icon: Icons.bookmark_border,
            title: 'Noch nichts gespeichert',
            hint: 'Tippe das Lesezeichen-Symbol auf einer Karte.',
          );
        }
        return _buildListView(items);
      },
    );
  }

  // ── TAB 2: VERLAUF ────────────────────────────────────────────────────────
  Widget _buildHistory() {
    return FutureBuilder<List<KnowledgeEntry>>(
      future: _svc.getReadEntries(world: widget.world),
      builder: (_, snap) {
        if (!snap.hasData) return _buildSpinner();
        final items = snap.data!;
        if (items.isEmpty) {
          return _buildEmptyState(
            icon: Icons.history,
            title: 'Noch nichts gelesen',
            hint: 'Öffne einen Eintrag, um ihn im Verlauf zu sehen.',
          );
        }
        return _buildListView(items);
      },
    );
  }

  // ── TAB 3: FÜR DICH ──────────────────────────────────────────────────────
  Widget _buildForYou() {
    return FutureBuilder<List<KnowledgeEntry>>(
      future: _svc.getRecommendations(widget.world, limit: 12),
      builder: (_, snap) {
        if (!snap.hasData) return _buildSpinner();
        final items = snap.data!;
        if (items.isEmpty) {
          return _buildEmptyState(
            icon: Icons.auto_awesome,
            title: 'Noch keine Empfehlungen',
            hint: 'Lies ein paar Einträge — wir lernen dazu.',
          );
        }
        return _buildListView(items);
      },
    );
  }

  Widget _buildListView(List<KnowledgeEntry> items) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _ListCard(
        entry: items[i],
        primary: _primary,
        svc: _svc,
        onTap: () => _openEntry(items[i]),
      ),
    );
  }

  // ── UTILITIES ─────────────────────────────────────────────────────────────
  Widget _sectionHeader(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(children: [
        Container(
          width: 3, height: 14,
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [BoxShadow(color: _primary, blurRadius: 8)],
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(
          fontSize: 10, letterSpacing: 3,
          color: _primarySoft, fontWeight: FontWeight.w700,
        )),
        const Spacer(),
        Icon(icon, size: 14, color: _primary.withValues(alpha: 0.5)),
      ]),
    );
  }

  Widget _buildEmptyState({IconData? icon, String? title, String? hint}) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _primary.withValues(alpha: 0.08),
            border: Border.all(color: _primary.withValues(alpha: 0.25)),
          ),
          child: Icon(icon ?? Icons.search_off, size: 32, color: _primary.withValues(alpha: 0.55)),
        ),
        const SizedBox(height: 16),
        Text(title ?? 'Keine Einträge', style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500)),
        if (hint != null) ...[
          const SizedBox(height: 6),
          Text(hint, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.45)), textAlign: TextAlign.center),
        ],
      ]),
    );
  }

  Widget _buildSpinner() {
    return Center(child: CircularProgressIndicator(color: _primary, strokeWidth: 2));
  }

  Widget _buildSkeleton() {
    return Scaffold(
      backgroundColor: _deep,
      body: Column(children: [
        SizedBox(height: 210, child: Container(color: _primary.withValues(alpha: 0.06))),
        const SizedBox(height: 56),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (_, __) => Container(
              height: 80,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FEATURED CARD (horizontal scroll)
// ─────────────────────────────────────────────────────────────────────────────
class _FeaturedCard extends StatelessWidget {
  final KnowledgeEntry entry;
  final Color primary;
  final Color deep;
  final VoidCallback onTap;

  const _FeaturedCard({required this.entry, required this.primary, required this.deep, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final catColor = _catColor(entry.category);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 210,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [deep, Color.lerp(deep, catColor, 0.22)!],
          ),
          border: Border.all(color: catColor.withValues(alpha: 0.35), width: 1.2),
          boxShadow: [
            BoxShadow(color: catColor.withValues(alpha: 0.22), blurRadius: 22, offset: const Offset(0, 8)),
            BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 12),
          ],
        ),
        child: Stack(children: [
          // Background orb
          Positioned(
            right: -15, bottom: -15,
            child: Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [catColor.withValues(alpha: 0.22), Colors.transparent]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Category chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: catColor.withValues(alpha: 0.45)),
                ),
                child: Text(_catLabel(entry.category), style: TextStyle(
                  fontSize: 8.5, color: catColor, fontWeight: FontWeight.w700, letterSpacing: 0.6,
                )),
              ),
              const SizedBox(height: 9),
              Text(entry.title, maxLines: 3, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, height: 1.3)),
              const Spacer(),
              Row(children: [
                Icon(Icons.timer_outlined, size: 11, color: Colors.white.withValues(alpha: 0.45)),
                const SizedBox(width: 4),
                Text('${entry.readingTimeMinutes} Min', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.45))),
                const Spacer(),
                _StarRow(rating: entry.rating),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CINEMATIC GRID CARD
// ─────────────────────────────────────────────────────────────────────────────
class _CinematicCard extends StatelessWidget {
  final KnowledgeEntry entry;
  final Color primary;
  final UnifiedKnowledgeService svc;
  final VoidCallback onTap;

  const _CinematicCard({required this.entry, required this.primary, required this.svc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final catColor = _catColor(entry.category);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF0B0D1A),
          border: Border(left: BorderSide(color: catColor, width: 3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.42), blurRadius: 14, offset: const Offset(0, 5)),
            BoxShadow(color: catColor.withValues(alpha: 0.07), blurRadius: 20),
          ],
        ),
        child: Stack(children: [
          // Atmospheric orb
          Positioned(
            right: -12, top: -12,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [catColor.withValues(alpha: 0.14), Colors.transparent]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Type badge + bookmark
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: catColor.withValues(alpha: 0.40)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_typeIcon(entry.type), size: 9, color: catColor),
                    const SizedBox(width: 3),
                    Text(_typeLabel(entry.type), style: TextStyle(
                      fontSize: 8, color: catColor, fontWeight: FontWeight.w700, letterSpacing: 0.4,
                    )),
                  ]),
                ),
                const Spacer(),
                FutureBuilder<bool>(
                  future: svc.isFavorite(entry.id),
                  builder: (ctx, snap) {
                    final isFav = snap.data ?? false;
                    return GestureDetector(
                      onTap: () async {
                        HapticFeedback.selectionClick();
                        if (isFav) await svc.removeFavorite(entry.id);
                        else await svc.addFavorite(entry.id);
                        (ctx as Element).markNeedsBuild();
                      },
                      child: Icon(
                        isFav ? Icons.bookmark : Icons.bookmark_border,
                        size: 17,
                        color: isFav ? const Color(0xFFFBBF24) : Colors.white.withValues(alpha: 0.35),
                      ),
                    );
                  },
                ),
              ]),
              const SizedBox(height: 10),
              // Title
              Text(entry.title, maxLines: 4, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white, height: 1.3)),
              const Spacer(),
              // Bottom: time + rating
              Row(children: [
                Icon(Icons.timer_outlined, size: 10, color: Colors.white.withValues(alpha: 0.38)),
                const SizedBox(width: 3),
                Text('${entry.readingTimeMinutes}m', style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.38))),
                const Spacer(),
                _StarRow(rating: entry.rating, size: 9),
              ]),
              const SizedBox(height: 7),
              // Tags
              Wrap(
                spacing: 3, runSpacing: 3,
                children: entry.tags.take(2).map((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
                  ),
                  child: Text('#$t', style: TextStyle(fontSize: 8, color: Colors.white.withValues(alpha: 0.40))),
                )).toList(),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LIST CARD (Gespeichert / Verlauf / Für dich)
// ─────────────────────────────────────────────────────────────────────────────
class _ListCard extends StatelessWidget {
  final KnowledgeEntry entry;
  final Color primary;
  final UnifiedKnowledgeService svc;
  final VoidCallback onTap;

  const _ListCard({required this.entry, required this.primary, required this.svc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final catColor = _catColor(entry.category);
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0E1C),
              borderRadius: BorderRadius.circular(14),
              border: Border(left: BorderSide(color: catColor, width: 3)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 12),
              ],
            ),
            child: Row(children: [
              // Icon circle
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: catColor.withValues(alpha: 0.14),
                  border: Border.all(color: catColor.withValues(alpha: 0.40)),
                ),
                child: Icon(_typeIcon(entry.type), size: 18, color: catColor),
              ),
              const SizedBox(width: 12),
              // Text
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(entry.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white, height: 1.3)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.timer_outlined, size: 10, color: Colors.white.withValues(alpha: 0.38)),
                  const SizedBox(width: 3),
                  Text('${entry.readingTimeMinutes} Min', style: TextStyle(fontSize: 9.5, color: Colors.white.withValues(alpha: 0.45))),
                  const SizedBox(width: 10),
                  Text(_catLabel(entry.category), style: TextStyle(fontSize: 9.5, color: catColor.withValues(alpha: 0.8))),
                ]),
              ])),
              const SizedBox(width: 8),
              // Arrow
              Icon(Icons.chevron_right, size: 18, color: Colors.white.withValues(alpha: 0.25)),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT PILL
// ─────────────────────────────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatPill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAR ROW
// ─────────────────────────────────────────────────────────────────────────────
class _StarRow extends StatelessWidget {
  final double rating;
  final double size;

  const _StarRow({required this.rating, this.size = 10});

  @override
  Widget build(BuildContext context) {
    if (rating <= 0) return const SizedBox.shrink();
    return Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (i) => Icon(
      i < rating.round() ? Icons.star : Icons.star_border,
      size: size,
      color: const Color(0xFFFBBF24).withValues(alpha: 0.75),
    )));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEARCH FAB
// ─────────────────────────────────────────────────────────────────────────────
class _SearchFAB extends StatelessWidget {
  final Color primary;
  final VoidCallback onTap;

  const _SearchFAB({required this.primary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54, height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [primary, Color.lerp(primary, Colors.black, 0.3)!],
          ),
          boxShadow: [
            BoxShadow(color: primary.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 2),
            BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: const Icon(Icons.search, color: Colors.white, size: 22),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AMBIENT BACKGROUND PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _AmbientPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final Color primary;
  final bool isMaterie;

  const _AmbientPainter({required this.progress, required this.pulse, required this.primary, required this.isMaterie});

  @override
  void paint(Canvas canvas, Size size) {
    // Animated nebula clouds
    for (int i = 0; i < 3; i++) {
      final x = size.width * (0.15 + i * 0.35 + math.sin(progress * math.pi * 2 + i * 1.2) * 0.08);
      final y = size.height * (0.35 + math.cos(progress * math.pi * 2 + i * 0.8) * 0.22);
      final r = 120.0 + i * 30.0 + pulse * 20;
      canvas.drawCircle(
        Offset(x, y), r,
        Paint()..shader = RadialGradient(
          colors: [primary.withValues(alpha: 0.22 + pulse * 0.08), Colors.transparent],
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: r)),
      );
    }

    // Grid lines (Materie: tight grid, Energie: wider)
    final step = isMaterie ? 32.0 : 48.0;
    final gridPaint = Paint()..color = primary.withValues(alpha: 0.045)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Energie: zusätzliche Kreisringe als Mandala-Andeutung
    if (!isMaterie) {
      for (int i = 1; i <= 3; i++) {
        canvas.drawCircle(
          Offset(size.width / 2, size.height * 0.3),
          i * 55.0 + pulse * 8,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5
            ..color = primary.withValues(alpha: 0.08),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_AmbientPainter old) => old.progress != progress || old.pulse != pulse;
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER FUNCTIONS
// ─────────────────────────────────────────────────────────────────────────────
Color _catColor(String cat) {
  switch (cat) {
    case 'conspiracy':       return const Color(0xFFFF4757);
    case 'ancientWisdom':    return const Color(0xFFFFB347);
    case 'forbiddenKnowledge': return const Color(0xFFFF6B9D);
    case 'books':            return const Color(0xFF4ECDC4);
    case 'meditation':       return const Color(0xFFA78BFA);
    case 'astrology':        return const Color(0xFF60A5FA);
    case 'crystals':         return const Color(0xFF34D399);
    case 'consciousness':    return const Color(0xFFF472B6);
    case 'energyWork':       return const Color(0xFFFBBF24);
    default:                 return const Color(0xFF94A3B8);
  }
}

String _catLabel(String cat) {
  switch (cat) {
    case 'conspiracy':         return 'Verschwörung';
    case 'ancientWisdom':      return 'Alte Weisheit';
    case 'forbiddenKnowledge': return 'Verboten';
    case 'books':              return 'Bücher';
    case 'meditation':         return 'Meditation';
    case 'astrology':          return 'Astrologie';
    case 'crystals':           return 'Kristalle';
    case 'consciousness':      return 'Bewusstsein';
    case 'energyWork':         return 'Energiearbeit';
    default:                   return cat;
  }
}

IconData _typeIcon(String type) {
  switch (type) {
    case 'book':     return Icons.menu_book;
    case 'article':  return Icons.article;
    case 'video':    return Icons.play_circle;
    case 'practice': return Icons.self_improvement;
    case 'research': return Icons.science;
    default:         return Icons.library_books;
  }
}

String _typeLabel(String type) {
  switch (type) {
    case 'book':     return 'BUCH';
    case 'article':  return 'ARTIKEL';
    case 'video':    return 'VIDEO';
    case 'practice': return 'PRAXIS';
    case 'research': return 'FORSCHUNG';
    default:         return 'WISSEN';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KNOWLEDGE DETAIL SCREEN (unverändert)
// ─────────────────────────────────────────────────────────────────────────────

class KnowledgeDetailScreen extends StatefulWidget {
  final KnowledgeEntry entry;

  const KnowledgeDetailScreen({super.key, required this.entry});

  @override
  State<KnowledgeDetailScreen> createState() => _KnowledgeDetailScreenState();
}

class _KnowledgeDetailScreenState extends State<KnowledgeDetailScreen> {
  final _knowledgeService = UnifiedKnowledgeService();
  final _noteController = TextEditingController();

  bool _isFavorite = false;
  bool _isRead = false;
  KnowledgeNote? _note;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final fav = await _knowledgeService.isFavorite(widget.entry.id);
    final progress = await _knowledgeService.getProgress(widget.entry.id);
    final note = await _knowledgeService.getNote(widget.entry.id);

    setState(() {
      _isFavorite = fav;
      _isRead = progress?.isRead ?? false;
      _note = note;
      if (note != null) _noteController.text = note.content;
    });

    await _knowledgeService.updateProgress(widget.entry.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050310),
      appBar: WBGlassAppBar(
        world: WBWorld.neutral,
        titleWidget: Text(widget.entry.title,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.star : Icons.star_border, color: Colors.amber),
            onPressed: () async {
              if (_isFavorite) {
                await _knowledgeService.removeFavorite(widget.entry.id);
              } else {
                await _knowledgeService.addFavorite(widget.entry.id);
              }
              setState(() => _isFavorite = !_isFavorite);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => Share.share('${widget.entry.title}\n\n${widget.entry.description}'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.entry.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(widget.entry.fullContent,
              style: const TextStyle(fontSize: 15, color: Colors.white70, height: 1.6)),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}

/// v5.44.7: Toggle-Chip fuer den Liste/Bookshelf-Switch im Wissen-Tab.
class _ViewModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  const _ViewModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? primary.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? primary : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14,
                color: selected ? primary : Colors.white.withValues(alpha: 0.6)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: selected ? Colors.white : Colors.white.withValues(alpha: 0.7),
            )),
          ]),
        ),
      ),
    );
  }
}
