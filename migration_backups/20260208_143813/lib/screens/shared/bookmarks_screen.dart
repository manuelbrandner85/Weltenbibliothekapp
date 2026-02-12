import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../../services/bookmark_service.dart';
import 'package:intl/intl.dart';

/// 🔖 BOOKMARKS SCREEN
/// 
/// Features:
/// - Alle gespeicherten Bookmarks anzeigen
/// - Kategorien-Filter (All, Recherche, Narratives)
/// - Suche in Bookmarks
/// - Lösch-Funktion
/// - Export/Import
/// - Statistiken

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final BookmarkService _bookmarkService = BookmarkService();
  List<Bookmark> _bookmarks = [];
  List<Bookmark> _filteredBookmarks = [];
  String _searchQuery = '';
  String? _selectedCategory;
  bool _isLoading = true;

  final List<String> _categories = ['All', 'Recherche', 'Narratives', 'Andere'];

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() => _isLoading = true);

    try {
      final bookmarks = await _bookmarkService.getAllBookmarks();
      setState(() {
        _bookmarks = bookmarks;
        _filteredBookmarks = bookmarks;
        _isLoading = false;
      });

      if (kDebugMode) {
        debugPrint('📚 Bookmarks: Loaded ${bookmarks.length} bookmarks');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (kDebugMode) {
        debugPrint('❌ Bookmarks: Error loading - $e');
      }
    }
  }

  void _filterBookmarks() {
    setState(() {
      _filteredBookmarks = _bookmarks.where((bookmark) {
        // Search filter
        final matchesSearch = _searchQuery.isEmpty ||
            bookmark.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (bookmark.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

        // Category filter
        final matchesCategory = _selectedCategory == null ||
            _selectedCategory == 'All' ||
            bookmark.category == _selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();

      // Sort by date (newest first)
      _filteredBookmarks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<void> _deleteBookmark(String id) async {
    try {
      await _bookmarkService.deleteBookmark(id);
      await _loadBookmarks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bookmark gelöscht'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Löschen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportBookmarks() async {
    try {
      final exported = await _bookmarkService.exportBookmarks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${exported.length} Bookmarks exportiert'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Kopieren',
              onPressed: () {
                // TODO: Copy to clipboard
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export fehlgeschlagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
        actions: [
          // Statistics
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => _showStatistics(),
            tooltip: 'Statistiken',
          ),
          // Export
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _exportBookmarks,
            tooltip: 'Export',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Bookmarks durchsuchen...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                          _filterBookmarks();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _filterBookmarks();
              },
            ),
          ),

          // Category Filter Chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category ||
                    (_selectedCategory == null && category == 'All');

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected
                            ? (category == 'All' ? null : category)
                            : null;
                      });
                      _filterBookmarks();
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Bookmarks List
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_filteredBookmarks.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredBookmarks.length,
      itemBuilder: (context, index) {
        return _buildBookmarkCard(_filteredBookmarks[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty || _selectedCategory != null
                ? Icons.search_off
                : Icons.bookmark_border,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedCategory != null
                ? 'Keine passenden Bookmarks gefunden'
                : 'Noch keine Bookmarks',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedCategory != null
                ? 'Versuche eine andere Suche'
                : 'Speichere interessante Recherchen',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarkCard(Bookmark bookmark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to bookmark content
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Öffne: ${bookmark.title}'),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(bookmark.category),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      bookmark.category ?? 'Andere',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Delete Button
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _deleteBookmark(bookmark.id),
                    tooltip: 'Löschen',
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Title
              Text(
                bookmark.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Description
              if (bookmark.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  bookmark.description!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 8),

              // Footer
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd.MM.yyyy HH:mm').format(bookmark.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
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

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'Recherche':
        return Colors.blue;
      case 'Narratives':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _showStatistics() {
    final stats = _bookmarkService.getStatistics();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📊 Bookmark Statistiken'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Gesamt', stats['total'].toString()),
            _buildStatRow('Recherche', stats['byCategory']['Recherche'].toString()),
            _buildStatRow('Narratives', stats['byCategory']['Narratives'].toString()),
            _buildStatRow('Andere', stats['byCategory']['Andere'].toString()),
            const Divider(),
            _buildStatRow('Heute hinzugefügt', stats['addedToday'].toString()),
            _buildStatRow('Diese Woche', stats['addedThisWeek'].toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
