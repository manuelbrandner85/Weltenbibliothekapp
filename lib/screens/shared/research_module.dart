// Erweiterung 4: shared research module for Vorhang + Ursprung.
//
// Consolidates the duplicated research-tab scaffolding (RestrictionGate,
// header, search, themed cards, detail sheet) into ONE reusable widget. Each
// world supplies a config + data loader and optional world-specific source
// filters. The complex Materie "Kaninchenbau" OSINT engine is intentionally
// NOT touched.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/cinematic/cinematic_post_process.dart';
import '../../widgets/cinematic/cinematic_settings.dart';
import '../../widgets/restriction_gate.dart';

/// One research entry, normalized across worlds. Plain Dart class (no records).
class ResearchItem {
  final String id;
  final String title;
  final String summary;
  final String detail;

  /// Optional filter bucket ("source filter") -- drives the chip row.
  final String? category;
  final IconData? icon;

  /// Optional external source link shown in the detail sheet.
  final String? sourceLabel;
  final String? sourceUrl;

  const ResearchItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.detail,
    this.category,
    this.icon,
    this.sourceLabel,
    this.sourceUrl,
  });
}

/// Result of a [ResearchLoader]: the items plus whether offline fallback data
/// was used (drives the offline banner).
class ResearchLoadResult {
  final List<ResearchItem> items;
  final bool usedFallback;
  const ResearchLoadResult(this.items, {this.usedFallback = false});
}

typedef ResearchLoader = Future<ResearchLoadResult> Function();

/// Reusable, world-themed research screen body.
class ResearchModule extends StatefulWidget {
  final String world;
  final Color accent;
  final Color background;
  final Color surface;

  /// Header eyebrow title (e.g. 'PSYCHOLOGIE-KOMPENDIUM').
  final String title;

  /// Loads the items (Supabase, static data, ...).
  final ResearchLoader loader;

  /// Show a free-text search field.
  final bool enableSearch;

  /// Show world-specific source-filter chips derived from item categories.
  final bool enableCategoryFilter;

  final String searchHint;

  /// Optional footer (e.g. Ursprung mentor + modules links).
  final WidgetBuilder? footerBuilder;

  final String restrictionScope;
  final String restrictionLabel;

  const ResearchModule({
    super.key,
    required this.world,
    required this.accent,
    required this.background,
    required this.surface,
    required this.title,
    required this.loader,
    this.enableSearch = false,
    this.enableCategoryFilter = false,
    this.searchHint = 'Durchsuchen ...',
    this.footerBuilder,
    this.restrictionScope = 'research_tools',
    this.restrictionLabel = 'Recherche-Tools',
  });

  @override
  State<ResearchModule> createState() => _ResearchModuleState();
}

class _ResearchModuleState extends State<ResearchModule> {
  final _searchCtrl = TextEditingController();

  List<ResearchItem> _all = [];
  List<String> _categories = [];
  String? _activeCategory;
  String _query = '';
  bool _loading = true;
  bool _usedFallback = false;

  @override
  void initState() {
    super.initState();
    KbCinemaSettings.instance.load(); // Cinema-Qualitaet (geteilt mit Kaninchenbau)
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await widget.loader();
    if (!mounted) return;
    final cats = <String>{};
    for (final it in res.items) {
      if (it.category != null && it.category!.isNotEmpty) {
        cats.add(it.category!);
      }
    }
    setState(() {
      _all = res.items;
      _usedFallback = res.usedFallback;
      _categories = cats.toList();
      _loading = false;
    });
  }

  List<ResearchItem> get _filtered {
    Iterable<ResearchItem> items = _all;
    if (widget.enableCategoryFilter && _activeCategory != null) {
      items = items.where((it) => it.category == _activeCategory);
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      items = items.where((it) =>
          it.title.toLowerCase().contains(q) ||
          it.summary.toLowerCase().contains(q));
    }
    return items.toList();
  }

  void _openDetail(ResearchItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ResearchDetailSheet(item: item, accent: widget.accent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RestrictionGate(
      scope: widget.restrictionScope,
      toolLabel: widget.restrictionLabel,
      child: Stack(
        children: [
          // Cinema-Postprocessing ueber dem gesamten Recherche-Inhalt.
          CinematicPostProcess(
            child: Container(
              color: widget.background,
              child: RefreshIndicator(
                color: widget.accent,
                backgroundColor: widget.surface,
                onRefresh: _load,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    if (widget.enableSearch)
                      SliverToBoxAdapter(child: _buildSearchBar()),
                    if (widget.enableCategoryFilter && _categories.isNotEmpty)
                      SliverToBoxAdapter(child: _buildCategoryChips()),
                    _buildList(),
                    if (widget.footerBuilder != null)
                      SliverToBoxAdapter(child: widget.footerBuilder!(context)),
                    const SliverToBoxAdapter(child: SizedBox(height: 90)),
                  ],
                ),
              ),
            ),
          ),
          // Qualitaets-Schalter oben rechts.
          Positioned(
            top: 8,
            right: 10,
            child: CinemaQualityChip(
              accent: widget.accent,
              accentBright: widget.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: widget.surface,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              color: widget.accent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_all.length} Eintraege',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
          ),
          if (_usedFallback) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_rounded,
                      color: Colors.orangeAccent, size: 15),
                  SizedBox(width: 6),
                  Text('Offline-Daten -- Live-Themen nicht erreichbar',
                      style:
                          TextStyle(color: Colors.orangeAccent, fontSize: 11)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        cursorColor: widget.accent,
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: widget.searchHint,
          hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
          prefixIcon: Icon(Icons.search, color: widget.accent, size: 20),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close,
                      color: Colors.white.withValues(alpha: 0.6), size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                ),
          filled: true,
          fillColor: widget.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: widget.accent.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: widget.accent),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          _chip(null, 'Alle'),
          for (final c in _categories) _chip(c, c),
        ],
      ),
    );
  }

  Widget _chip(String? value, String label) {
    final active = _activeCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => setState(() => _activeCategory = value),
        backgroundColor: widget.surface,
        selectedColor: widget.accent.withValues(alpha: 0.22),
        labelStyle: TextStyle(
          color: active ? widget.accent : Colors.white.withValues(alpha: 0.7),
          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          fontSize: 12,
        ),
        side: BorderSide(
          color: active
              ? widget.accent.withValues(alpha: 0.6)
              : widget.accent.withValues(alpha: 0.15),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading && _all.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 50),
          child: Center(child: CircularProgressIndicator(color: widget.accent)),
        ),
      );
    }
    final items = _filtered;
    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Text(
            'Keine Eintraege gefunden.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => _ResearchCard(
          item: items[i],
          accent: widget.accent,
          surface: widget.surface,
          onTap: () => _openDetail(items[i]),
        ),
        childCount: items.length,
      ),
    );
  }
}

/// Themed list card for a research item.
class _ResearchCard extends StatelessWidget {
  final ResearchItem item;
  final Color accent;
  final Color surface;
  final VoidCallback onTap;

  const _ResearchCard({
    required this.item,
    required this.accent,
    required this.surface,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(item.icon ?? Icons.article_outlined,
                    color: accent, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                            height: 1.3),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: accent.withValues(alpha: 0.5), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Themed detail bottom sheet with optional source link.
class _ResearchDetailSheet extends StatelessWidget {
  final ResearchItem item;
  final Color accent;
  const _ResearchDetailSheet({required this.item, required this.accent});

  Future<void> _openSource() async {
    final url = item.sourceUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.94,
      builder: (_, sc) => SingleChildScrollView(
        controller: sc,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              item.title,
              style: TextStyle(
                  color: accent, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              item.summary,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            Divider(color: accent.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text(
              item.detail,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 14, height: 1.65),
            ),
            if (item.sourceUrl != null && item.sourceUrl!.isNotEmpty) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(item.sourceLabel ?? 'Quelle oeffnen'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _openSource,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
