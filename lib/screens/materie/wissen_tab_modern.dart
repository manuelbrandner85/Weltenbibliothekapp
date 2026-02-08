import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../../models/favorite.dart'; // For FavoriteType
import '../../models/knowledge_entry.dart';
import '../../models/book.dart';
import '../../services/materie_knowledge_service.dart';
import '../../services/materie_book_service.dart';
import '../../widgets/favorite_button.dart';

/// Moderner Wissen-Tab für MATERIE-Welt - Bibliotheks-Style
class MaterieWissenTabModern extends StatefulWidget {
  const MaterieWissenTabModern({super.key});

  @override
  State<MaterieWissenTabModern> createState() => _MaterieWissenTabModernState();
}

class _MaterieWissenTabModernState extends State<MaterieWissenTabModern> {
  final _knowledgeService = MaterieKnowledgeService();
  final _bookService = MaterieBookService();
  
  List<KnowledgeEntry> _allEntries = [];
  List<KnowledgeEntry> _filteredEntries = [];
  List<Book> _books = [];
  String _searchQuery = '';
  String _selectedCategory = 'all'; // 'all', 'geopolitik', 'geschichte', 'wissenschaft'
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint('🔵 MATERIE Wissen Tab Modern initialisiert');
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Simuliere Laden
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _allEntries = _knowledgeService.getAllEntries();
      _books = _bookService.getAllBooks();
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    var filtered = _allEntries;

    // Suchfilter
    if (_searchQuery.isNotEmpty) {
      filtered = _knowledgeService.search(_searchQuery);
    }

    // Kategorie-Filter
    if (_selectedCategory != 'all') {
      filtered = filtered.where((e) {
        final categoryName = e.category.name.toLowerCase();
        return categoryName.contains(_selectedCategory);
      }).toList();
    }

    setState(() {
      _filteredEntries = filtered;
    });
  }

  int _getCategoryCount(String category) {
    if (category == 'all') return _allEntries.length;
    return _allEntries.where((e) {
      final categoryName = e.category.name.toLowerCase();
      return categoryName.contains(category);
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0D47A1).withValues(alpha: 0.05),
            Colors.black,
          ],
        ),
      ),
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _buildHeader(),
          ),
          
          // Suchleiste
          SliverToBoxAdapter(
            child: _buildSearchBar(),
          ),
          
          // Kategorien-Filter
          SliverToBoxAdapter(
            child: _buildCategoryFilter(),
          ),
          
          // Statistik-Card
          SliverToBoxAdapter(
            child: _buildStatsCard(),
          ),
          
          // Content
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : _filteredEntries.isEmpty
                  ? SliverFillRemaining(
                      child: _buildEmptyState(),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildKnowledgeCard(_filteredEntries[index]),
                          childCount: _filteredEntries.length,
                        ),
                      ),
                    ),
          
          // Bottom-Padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '📚',
                style: TextStyle(fontSize: 40),
              ),
              const SizedBox(width: 12),
              const Text(
                'Wissens-Bibliothek',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Deine gesammelte Recherche und Erkenntnisse',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 24,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Suche in Wissens-Einträgen...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 16,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.clear,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _applyFilters();
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildCategoryChip(
              'all',
              '📖 Alle (${_getCategoryCount('all')})',
              Colors.blue,
            ),
            const SizedBox(width: 12),
            _buildCategoryChip(
              'geopolitik',
              '🌍 Geopolitik (${_getCategoryCount('geopolitik')})',
              Colors.green,
            ),
            const SizedBox(width: 12),
            _buildCategoryChip(
              'geschichte',
              '🏛️ Geschichte (${_getCategoryCount('geschichte')})',
              Colors.orange,
            ),
            const SizedBox(width: 12),
            _buildCategoryChip(
              'wissenschaft',
              '🔬 Wissenschaft (${_getCategoryCount('wissenschaft')})',
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category, String label, Color color) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
          _applyFilters();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.7),
                    color.withValues(alpha: 0.3),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final totalEntries = _allEntries.length;
    final totalBooks = _books.length;
    final totalReadingTime = _allEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.readingTime,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.15),
            Colors.purple.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('📄', '$totalEntries', 'Einträge'),
          _buildStatItem('📚', '$totalBooks', 'Bücher'),
          _buildStatItem('⏱️', '$totalReadingTime Min', 'Lesezeit'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String icon, String value, String label) {
    return Column(
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 32),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildKnowledgeCard(KnowledgeEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (kDebugMode) {
            debugPrint('📄 Wissens-Eintrag geöffnet: ${entry.title}');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header mit Kategorie-Badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(entry.category).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getCategoryColor(entry.category).withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      entry.category.name ?? 'Allgemein',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getCategoryColor(entry.category).withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Favoriten-Button
                  FavoriteIcon(
                    itemId: entry.id,
                    itemTitle: entry.title,
                    itemType: FavoriteType.research,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${entry.readingTime} Min',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Titel
              Text(
                entry.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Beschreibung
              if (entry.description.isNotEmpty)
                Text(
                  entry.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
              
              // Tags
              if (entry.tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: entry.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '📭',
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          const Text(
            'Keine Wissens-Einträge gefunden',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Versuche eine andere Suche oder Kategorie',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(KnowledgeCategory? category) {
    if (category == null) return Colors.grey;
    final categoryName = category.name.toLowerCase();
    
    if (categoryName.contains('geopolitik')) {
      return Colors.green;
    } else if (categoryName.contains('geschichte')) {
      return Colors.orange;
    } else if (categoryName.contains('wissenschaft') || categoryName.contains('forschung')) {
      return Colors.purple;
    } else if (categoryName.contains('transparenz')) {
      return Colors.yellow;
    } else if (categoryName.contains('medien')) {
      return Colors.red;
    }
    
    return Colors.blue;
  }
}
