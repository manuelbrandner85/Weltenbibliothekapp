// GlobalBookmarksScreen -- welten-uebergreifender Lesezeichen- & Verlauf-Screen.
//
// FEATURE: Buendelt gespeicherte (Favoriten) und kuerzlich gelesene Inhalte
// aller 4 Welten an einem Ort. Bisher waren Favoriten nur pro Welt im
// jeweiligen Wissens-Tab sichtbar. Tap auf einen Eintrag oeffnet den Reader.
//
// Route: '/global_bookmarks'

import 'package:flutter/material.dart';

import '../../config/wb_design.dart';
import '../../models/knowledge_extended_models.dart';
import '../../services/unified_knowledge_service.dart';
import 'knowledge_reader_mode.dart';
import '../wissen/cinematic_book_reader_screen.dart';

class GlobalBookmarksScreen extends StatefulWidget {
  const GlobalBookmarksScreen({super.key});

  @override
  State<GlobalBookmarksScreen> createState() => _GlobalBookmarksScreenState();
}

class _GlobalBookmarksScreenState extends State<GlobalBookmarksScreen>
    with SingleTickerProviderStateMixin {
  final _svc = UnifiedKnowledgeService();
  late final TabController _tabs;

  List<KnowledgeEntry> _favorites = const [];
  List<KnowledgeEntry> _history = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      // world == null -> across all 4 worlds.
      final favs = await _svc.getFavorites();
      final hist = await _svc.getReadEntries();
      if (!mounted) return;
      setState(() {
        _favorites = favs;
        _history = hist;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEntry(KnowledgeEntry entry) async {
    await _svc.incrementViewCount(entry.id);
    if (!mounted) return;
    final isBook = entry.type == 'book';
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => isBook
            ? CinematicBookReaderScreen(book: entry)
            : KnowledgeReaderMode(entry: entry, world: entry.world),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06060C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Meine Bibliothek'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Gespeichert'),
            Tab(text: 'Zuletzt gelesen'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _buildList(
                  _favorites,
                  emptyIcon: Icons.bookmark_border_rounded,
                  emptyText: 'Noch keine gespeicherten Inhalte.\n'
                      'Tippe im Wissens-Tab auf das Lesezeichen-Symbol.',
                ),
                _buildList(
                  _history,
                  emptyIcon: Icons.history_rounded,
                  emptyText: 'Noch nichts gelesen.\n'
                      'Geoeffnete Inhalte erscheinen hier.',
                ),
              ],
            ),
    );
  }

  Widget _buildList(
    List<KnowledgeEntry> items, {
    required IconData emptyIcon,
    required String emptyText,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(emptyIcon, size: 48, color: Colors.white24),
              const SizedBox(height: 16),
              Text(
                emptyText,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _EntryCard(
        entry: items[i],
        onTap: () => _openEntry(items[i]),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final KnowledgeEntry entry;
  final VoidCallback onTap;

  const _EntryCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = WbDesign.accent(entry.world);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: WbDesign.surface(entry.world),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            // World accent rail + type icon.
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_typeIcon(entry.type), color: accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _miniBadge(_worldLabel(entry.world), accent),
                      const SizedBox(width: 6),
                      if (entry.readingTimeMinutes > 0)
                        Text(
                          '${entry.readingTimeMinutes} Min',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Widget _miniBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'book':
        return Icons.menu_book_rounded;
      case 'video':
        return Icons.play_circle_outline_rounded;
      case 'practice':
        return Icons.self_improvement_rounded;
      case 'research':
        return Icons.science_outlined;
      default:
        return Icons.article_outlined;
    }
  }

  String _worldLabel(String world) {
    switch (world) {
      case 'materie':
        return 'Materie';
      case 'energie':
        return 'Energie';
      case 'vorhang':
        return 'Vorhang';
      case 'ursprung':
        return 'Ursprung';
      default:
        return world;
    }
  }
}
