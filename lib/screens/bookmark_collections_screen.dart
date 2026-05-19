// Bookmark-Collections-Manager (L5).
//
// Erlaubt das Erstellen, Anzeigen und Befüllen von Bookmark-Ordnern.
// Bookmarks selbst werden weiterhin im bestehenden BookmarksScreen
// gepflegt — dieser Screen ist die Organisations-Ebene darüber.

import 'package:flutter/material.dart';

import '../services/bookmark_collection_service.dart';
import '../services/storage_service.dart';

class BookmarkCollectionsScreen extends StatefulWidget {
  const BookmarkCollectionsScreen({super.key});

  @override
  State<BookmarkCollectionsScreen> createState() =>
      _BookmarkCollectionsScreenState();
}

class _BookmarkCollectionsScreenState extends State<BookmarkCollectionsScreen> {
  static const _accent = Color(0xFFC9A84C);

  List<BookmarkCollection> _collections = const [];
  bool _loading = true;

  String _userId() {
    final s = StorageService();
    return s.getMaterieProfile()?.userId ??
        s.getEnergieProfile()?.userId ??
        'anon';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await BookmarkCollectionService.instance.listFor(_userId());
    if (mounted) {
      setState(() {
        _collections = list;
        _loading = false;
      });
    }
  }

  Future<void> _create() async {
    final nameCtrl = TextEditingController();
    String? selectedIcon = '📁';
    String selectedColor = 'gold';

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D0D1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text('📁 Neue Sammlung',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Name (z.B. Recherche, Lieblings-Module …)',
                  labelStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Icon',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in const [
                    '📁',
                    '⭐',
                    '💡',
                    '🔍',
                    '📚',
                    '🎯',
                    '🌙',
                    '🔮',
                    '⚖️',
                    '👑'
                  ])
                    GestureDetector(
                      onTap: () => setSheet(() => selectedIcon = e),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: selectedIcon == e
                              ? _accent.withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selectedIcon == e
                                ? _accent
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(e, style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Farbe',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (final cKey in const [
                    'gold',
                    'blue',
                    'purple',
                    'green',
                    'red',
                    'cyan'
                  ])
                    GestureDetector(
                      onTap: () => setSheet(() => selectedColor = cKey),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _colorFor(cKey),
                          border: Border.all(
                            color: selectedColor == cKey
                                ? Colors.white
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  await BookmarkCollectionService.instance.create(
                    userId: _userId(),
                    name: nameCtrl.text.trim(),
                    icon: selectedIcon,
                    color: selectedColor,
                  );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                },
                icon: const Icon(Icons.check),
                label: const Text('Sammlung anlegen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == true) _load();
  }

  Color _colorFor(String key) {
    switch (key) {
      case 'blue':
        return const Color(0xFF42A5F5);
      case 'purple':
        return const Color(0xFFAB47BC);
      case 'green':
        return const Color(0xFF66BB6A);
      case 'red':
        return const Color(0xFFEF5350);
      case 'cyan':
        return const Color(0xFF26C6DA);
      case 'gold':
      default:
        return _accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050310),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Bookmark-Sammlungen',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: _accent),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: _accent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text('Neu'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : _collections.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('📁', style: TextStyle(fontSize: 56)),
                        const SizedBox(height: 14),
                        Text(
                          'Noch keine Sammlungen.\nTippe + um eine anzulegen.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              height: 1.5),
                        ),
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _collections.length,
                  itemBuilder: (_, i) {
                    final c = _collections[i];
                    final color = _colorFor(c.color ?? 'gold');
                    return _CollectionCard(
                      collection: c,
                      color: color,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _CollectionDetailScreen(
                              collection: c, color: color),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final BookmarkCollection collection;
  final Color color;
  final VoidCallback onTap;
  const _CollectionCard({
    required this.collection,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.18),
                color.withValues(alpha: 0.04),
              ],
            ),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(collection.icon ?? '📁',
                  style: const TextStyle(fontSize: 32)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectionDetailScreen extends StatelessWidget {
  final BookmarkCollection collection;
  final Color color;
  const _CollectionDetailScreen({
    required this.collection,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050310),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Text(collection.icon ?? '📁', style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(collection.name, style: const TextStyle(color: Colors.white)),
          ],
        ),
        iconTheme: IconThemeData(color: color),
      ),
      body: FutureBuilder<List<String>>(
        future: BookmarkCollectionService.instance.bookmarksOf(collection.id),
        builder: (_, snap) {
          if (!snap.hasData) {
            return Center(child: CircularProgressIndicator(color: color));
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Diese Sammlung ist noch leer.\nFüge Bookmarks über das ⋮-Menü in der Bookmark-Liste hinzu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55), height: 1.5),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) => ListTile(
              leading: Icon(Icons.bookmark_rounded, color: color),
              title: Text(items[i],
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ),
          );
        },
      ),
    );
  }
}
