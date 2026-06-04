// Ursprung core tool: "Zeitleiste der Menschheitsursprünge".
// Interactive vertical timeline of creation myths, early cultures and open
// questions. Tap an entry for details and cross-world references.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/ursprung_timeline_service.dart';
import '../../services/haptic_service.dart';

class UrsprungTimelineScreen extends StatefulWidget {
  const UrsprungTimelineScreen({super.key});

  @override
  State<UrsprungTimelineScreen> createState() => _UrsprungTimelineScreenState();
}

class _UrsprungTimelineScreenState extends State<UrsprungTimelineScreen> {
  static const _cyan = Color(0xFF00D4AA);
  static const _bgDeep = Color(0xFF050510);
  static const _surface = Color(0xFF080818);

  // Category accent colors.
  static const Map<String, Color> _categoryColors = {
    'schoepfungsmythos': Color(0xFFFFD700),
    'urkultur': _cyan,
    'offene_frage': Color(0xFFB388FF),
  };

  List<UrsprungTimelineEntry> _all = [];
  String? _activeCategory;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await UrsprungTimelineService.instance.fetch();
    if (!mounted) return;
    setState(() {
      _all = items;
      _loading = false;
    });
  }

  List<UrsprungTimelineEntry> get _filtered {
    if (_activeCategory == null) return _all;
    return _all.where((e) => e.category == _activeCategory).toList();
  }

  Color _colorFor(String category) => _categoryColors[category] ?? _cyan;

  void _openDetail(UrsprungTimelineEntry entry) {
    HapticService.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TimelineDetailSheet(
        entry: entry,
        accent: _colorFor(entry.category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep,
      appBar: AppBar(
        backgroundColor: _bgDeep,
        elevation: 0,
        iconTheme: const IconThemeData(color: _cyan),
        title: Text(
          'ZEITLEISTE',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w300,
            fontSize: 16,
            letterSpacing: 3.0,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildIntro(),
          _buildCategoryChips(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Text(
        'Von kosmischen Anfaengen ueber die ersten Hochkulturen bis zu den '
        'grossen offenen Fragen der Menschheit.',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 12,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    const cats = UrsprungTimelineService.categoryLabels;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _chip(null, 'Alle', _cyan),
          for (final entry in cats.entries)
            _chip(entry.key, entry.value, _colorFor(entry.key)),
        ],
      ),
    );
  }

  Widget _chip(String? value, String label, Color color) {
    final active = _activeCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => setState(() => _activeCategory = value),
        backgroundColor: _surface,
        selectedColor: color.withValues(alpha: 0.25),
        labelStyle: TextStyle(
          color: active ? color : Colors.white.withValues(alpha: 0.7),
          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          fontSize: 12,
        ),
        side: BorderSide(
          color: active
              ? color.withValues(alpha: 0.6)
              : color.withValues(alpha: 0.15),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _cyan));
    }
    final items = _filtered;
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Keine Eintraege gefunden.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: items.length,
      itemBuilder: (_, i) =>
          _buildTimelineNode(items[i], i == items.length - 1),
    );
  }

  Widget _buildTimelineNode(UrsprungTimelineEntry entry, bool isLast) {
    final color = _colorFor(entry.category);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline rail: node dot + connecting line.
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.25),
                  border: Border.all(color: color, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: color.withValues(alpha: 0.25),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Content card.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildNodeCard(entry, color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeCard(UrsprungTimelineEntry entry, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDetail(entry),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_surface, color.withValues(alpha: 0.06)],
            ),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (entry.yearLabel != null)
                    Expanded(
                      child: Text(
                        entry.yearLabel!,
                        style: TextStyle(
                          color: color.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      UrsprungTimelineService.categoryLabels[entry.category] ??
                          entry.category,
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                entry.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (entry.summary != null) ...[
                const SizedBox(height: 4),
                Text(
                  entry.summary!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Mehr erfahren',
                    style: TextStyle(
                      color: color.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: color.withValues(alpha: 0.8), size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Detail bottom sheet: full description + cross-world references.
class _TimelineDetailSheet extends StatelessWidget {
  final UrsprungTimelineEntry entry;
  final Color accent;
  const _TimelineDetailSheet({required this.entry, required this.accent});

  static const _surface = Color(0xFF080818);

  static const Map<String, Color> _worldColors = {
    'materie': Color(0xFF3B82F6),
    'energie': Color(0xFFA855F7),
    'vorhang': Color(0xFFC9A84C),
    'ursprung': Color(0xFF00D4AA),
  };
  static const Map<String, String> _worldLabels = {
    'materie': 'Materie',
    'energie': 'Energie',
    'vorhang': 'Vorhang',
    'ursprung': 'Ursprung',
  };

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (entry.era != null || entry.yearLabel != null)
              Text(
                [entry.era, entry.yearLabel]
                    .where((e) => e != null && e.isNotEmpty)
                    .join('  ·  '),
                style: TextStyle(
                  color: accent.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              entry.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                UrsprungTimelineService.categoryLabels[entry.category] ??
                    entry.category,
                style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (entry.details != null && entry.details!.isNotEmpty) ...[
              Text(
                entry.details!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 22),
            ] else if (entry.summary != null) ...[
              Text(
                entry.summary!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 22),
            ],
            if (entry.crossWorldRefs.isNotEmpty) ...[
              Text(
                'QUERVERWEISE IN DIE WELTEN',
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3.0,
                ),
              ),
              const SizedBox(height: 10),
              for (final ref in entry.crossWorldRefs.entries)
                _crossRef(ref.key, ref.value),
            ],
          ],
        ),
      ),
    );
  }

  Widget _crossRef(String worldKey, String text) {
    final color = _worldColors[worldKey] ?? const Color(0xFF00D4AA);
    final label = _worldLabels[worldKey] ?? worldKey;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
