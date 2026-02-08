import 'package:flutter/material.dart';
import '../../models/knowledge_entry.dart';
import '../../models/book.dart';
import '../../services/materie_knowledge_service.dart';
import '../../services/materie_book_service.dart';

/// Wissen-Tab für MATERIE-Welt
class MaterieWissenTab extends StatefulWidget {
  const MaterieWissenTab({super.key});

  @override
  State<MaterieWissenTab> createState() => _MaterieWissenTabState();
}

class _MaterieWissenTabState extends State<MaterieWissenTab> {
  final _knowledgeService = MaterieKnowledgeService();
  final _bookService = MaterieBookService();
  
  List<KnowledgeEntry> _allEntries = [];
  List<KnowledgeEntry> _filteredEntries = [];
  List<Book> _books = [];
  String _searchQuery = '';
  KnowledgeType? _selectedType;
  KnowledgeCategory? _selectedCategory;
  int? _selectedDifficulty;
  String? _selectedAuthor;
  String? _selectedTimeFilter; // 'neu', 'woche', 'monat', 'alle'
  String _sortBy = 'datum'; // 'datum', 'titel', 'laenge', 'schwierigkeit'
  final Set<String> _selectedTags = {};
  bool _showAdvancedFilters = false;
  bool _showStatistics = false;
  final Set<String> _favoriteIds = {}; // Gespeicherte Favoriten

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  void _loadEntries() {
    setState(() {
      _allEntries = _knowledgeService.getAllEntries();
      _books = _bookService.getAllBooks();
      _applyFilters();
    });
  }

  void _applyFilters() {
    var filtered = _allEntries;

    // Suchfilter
    if (_searchQuery.isNotEmpty) {
      filtered = _knowledgeService.search(_searchQuery);
    }

    // Typ-Filter
    if (_selectedType != null) {
      filtered = filtered.where((e) => e.type == _selectedType).toList();
    }

    // Kategorie-Filter
    if (_selectedCategory != null) {
      filtered = filtered.where((e) => e.category == _selectedCategory).toList();
    }

    // Schwierigkeit-Filter
    if (_selectedDifficulty != null) {
      filtered = filtered.where((e) => e.difficulty == _selectedDifficulty).toList();
    }

    // Autor-Filter
    if (_selectedAuthor != null && _selectedAuthor!.isNotEmpty) {
      filtered = filtered.where((e) => e.author == _selectedAuthor).toList();
    }

    // Zeit-Filter
    if (_selectedTimeFilter != null && _selectedTimeFilter != 'alle') {
      final now = DateTime.now();
      filtered = filtered.where((e) {
        if (e.publishedDate == null) return false;
        switch (_selectedTimeFilter) {
          case 'neu':
            return now.difference(e.publishedDate!).inDays <= 7;
          case 'woche':
            return now.difference(e.publishedDate!).inDays <= 30;
          case 'monat':
            return now.difference(e.publishedDate!).inDays <= 90;
          default:
            return true;
        }
      }).toList();
    }

    // Tag-Filter
    if (_selectedTags.isNotEmpty) {
      filtered = filtered.where((e) {
        return _selectedTags.any((tag) => e.tags.contains(tag));
      }).toList();
    }

    // Sortierung
    switch (_sortBy) {
      case 'datum':
        filtered.sort((a, b) {
          final dateA = a.publishedDate ?? DateTime(2000);
          final dateB = b.publishedDate ?? DateTime(2000);
          return dateB.compareTo(dateA); // Neueste zuerst
        });
        break;
      case 'titel':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'laenge':
        filtered.sort((a, b) => a.readingTime.compareTo(b.readingTime));
        break;
      case 'schwierigkeit':
        filtered.sort((a, b) => a.difficulty.compareTo(b.difficulty));
        break;
    }

    setState(() => _filteredEntries = filtered);
  }

  List<String> _getAllTags() {
    final tags = <String>{};
    for (var entry in _allEntries) {
      tags.addAll(entry.tags);
    }
    return tags.toList()..sort();
  }

  List<String> _getAllAuthors() {
    final authors = <String>{};
    for (var entry in _allEntries) {
      if (entry.author != null && entry.author!.isNotEmpty) {
        authors.add(entry.author!);
      }
    }
    return authors.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1565C0),
            Color(0xFF1A1A1A),
          ],
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (_showStatistics) _buildStatisticsDashboard(),
          _buildSearchBar(),
          _buildQuickFilters(),
          if (_showAdvancedFilters) _buildAdvancedFilters(),
          _buildSortAndFilterBar(),
          Expanded(
            child: _filteredEntries.isEmpty
                ? _buildEmptyState()
                : _buildEntriesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_stories, color: Color(0xFF2196F3), size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WISSENSDATENBANK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Bücher · Quellen · Methoden · Lexikon',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Statistik Toggle
          GestureDetector(
            onTap: () {
              setState(() => _showStatistics = !_showStatistics);
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _showStatistics
                    ? const Color(0xFF2196F3)
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(Icons.bar_chart, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsDashboard() {
    final totalEntries = _allEntries.length;
    final totalBooks = _books.length;
    final totalFavorites = _allEntries.where((e) => _favoriteIds.contains(e.id)).length;
    final totalReadingTime = _allEntries.fold(0, (sum, e) => sum + e.readingTime);
    
    // Kategorie-Verteilung
    final categoryDistribution = <KnowledgeCategory, int>{};
    for (var entry in _allEntries) {
      categoryDistribution[entry.category] = (categoryDistribution[entry.category] ?? 0) + 1;
    }
    
    // Schwierigkeit-Verteilung
    final difficultyDistribution = <int, int>{};
    for (var entry in _allEntries) {
      difficultyDistribution[entry.difficulty] = (difficultyDistribution[entry.difficulty] ?? 0) + 1;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'STATISTIK-DASHBOARD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Statistik-Grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Einträge',
                  totalEntries.toString(),
                  Icons.description,
                  Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Bücher',
                  totalBooks.toString(),
                  Icons.auto_stories,
                  Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Favoriten',
                  totalFavorites.toString(),
                  Icons.favorite,
                  Colors.red.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Lesezeit',
                  '${(totalReadingTime / 60).toStringAsFixed(1)}h',
                  Icons.schedule,
                  Colors.orange.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Kategorie-Verteilung
          const Text(
            'TOP KATEGORIEN',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...categoryDistribution.entries.take(3).map((entry) {
            final percentage = (entry.value / totalEntries * 100).toStringAsFixed(0);
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      _getCategoryLabel(entry.key),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Stack(
                      children: [
                        Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: entry.value / totalEntries,
                          child: Container(
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '$percentage% (${entry.value})',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryLabel(KnowledgeCategory category) {
    switch (category) {
      case KnowledgeCategory.geopolitics:
        return 'Geopolitik';
      case KnowledgeCategory.alternativeMedia:
        return 'Alt. Medien';
      case KnowledgeCategory.research:
        return 'Forschung';
      case KnowledgeCategory.conspiracy:
        return 'Verschwörung';
      case KnowledgeCategory.history:
        return 'Geschichte';
      case KnowledgeCategory.science:
        return 'Wissenschaft';
      default:
        return category.toString();
    }
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: (value) {
          setState(() => _searchQuery = value);
          _applyFilters();
        },
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Suche nach Titel, Autor, Tags...',
          hintStyle: const TextStyle(color: Colors.white60),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF2196F3)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white60),
                  onPressed: () {
                    setState(() => _searchQuery = '');
                    _applyFilters();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Suchfeld
          TextField(
            onChanged: (value) {
              setState(() => _searchQuery = value);
              _applyFilters();
            },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Suche...',
              hintStyle: const TextStyle(color: Colors.white60),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF2196F3)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Filter-Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Alle', _selectedType == null, () {
                  setState(() {
                    _selectedType = null;
                    _selectedCategory = null;
                  });
                  _applyFilters();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Bücher', _selectedType == KnowledgeType.book, () {
                  setState(() => _selectedType = KnowledgeType.book);
                  _applyFilters();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Methoden', _selectedType == KnowledgeType.method, () {
                  setState(() => _selectedType = KnowledgeType.method);
                  _applyFilters();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Lexikon', _selectedType == KnowledgeType.lexicon, () {
                  setState(() => _selectedType = KnowledgeType.lexicon);
                  _applyFilters();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Quellen', _selectedType == KnowledgeType.source, () {
                  setState(() => _selectedType = KnowledgeType.source);
                  _applyFilters();
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSortAndFilterBar() {
    final activeFiltersCount = [
      if (_selectedType != null) 1,
      if (_selectedCategory != null) 1,
      if (_selectedDifficulty != null) 1,
      if (_selectedAuthor != null) 1,
      if (_selectedTimeFilter != null && _selectedTimeFilter != 'alle') 1,
      if (_selectedTags.isNotEmpty) _selectedTags.length,
    ].fold(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Sortierung
          Expanded(
            child: GestureDetector(
              onTap: _showSortOptions,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sort, color: Color(0xFF2196F3), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _getSortLabel(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, color: Colors.white60, size: 16),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Erweiterte Filter Toggle
          GestureDetector(
            onTap: () {
              setState(() => _showAdvancedFilters = !_showAdvancedFilters);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _showAdvancedFilters
                    ? const Color(0xFF2196F3)
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tune, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    activeFiltersCount > 0 ? 'Filter ($activeFiltersCount)' : 'Filter',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          
          // Filter Zurücksetzen
          if (activeFiltersCount > 0)
            const SizedBox(width: 8),
          if (activeFiltersCount > 0)
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = null;
                  _selectedCategory = null;
                  _selectedDifficulty = null;
                  _selectedAuthor = null;
                  _selectedTimeFilter = null;
                  _selectedTags.clear();
                });
                _applyFilters();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.clear, color: Colors.red, size: 16),
              ),
            ),
        ],
      ),
    );
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'datum':
        return 'Neueste';
      case 'titel':
        return 'A-Z';
      case 'laenge':
        return 'Länge';
      case 'schwierigkeit':
        return 'Schwierigkeit';
      default:
        return 'Sortierung';
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SORTIEREN NACH',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            _buildSortOption('Neueste zuerst', 'datum', Icons.access_time),
            _buildSortOption('Titel (A-Z)', 'titel', Icons.sort_by_alpha),
            _buildSortOption('Leselänge', 'laenge', Icons.schedule),
            _buildSortOption('Schwierigkeit', 'schwierigkeit', Icons.signal_cellular_alt),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, String value, IconData icon) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() => _sortBy = value);
        _applyFilters();
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2196F3).withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2196F3)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF2196F3) : Colors.white60, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF2196F3) : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check, color: Color(0xFF2196F3), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ERWEITERTE FILTER',
            style: TextStyle(
              color: Color(0xFF2196F3),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          
          // Kategorie-Filter
          _buildFilterSection(
            'Kategorie',
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildAdvancedChip('Alle Kategorien', _selectedCategory == null, () {
                    setState(() => _selectedCategory = null);
                    _applyFilters();
                  }),
                  const SizedBox(width: 8),
                  _buildAdvancedChip('Geopolitik', _selectedCategory == KnowledgeCategory.geopolitics, () {
                    setState(() => _selectedCategory = KnowledgeCategory.geopolitics);
                    _applyFilters();
                  }),
                  const SizedBox(width: 8),
                  _buildAdvancedChip('Alt. Medien', _selectedCategory == KnowledgeCategory.alternativeMedia, () {
                    setState(() => _selectedCategory = KnowledgeCategory.alternativeMedia);
                    _applyFilters();
                  }),
                  const SizedBox(width: 8),
                  _buildAdvancedChip('Forschung', _selectedCategory == KnowledgeCategory.research, () {
                    setState(() => _selectedCategory = KnowledgeCategory.research);
                    _applyFilters();
                  }),
                  const SizedBox(width: 8),
                  _buildAdvancedChip('Geschichte', _selectedCategory == KnowledgeCategory.history, () {
                    setState(() => _selectedCategory = KnowledgeCategory.history);
                    _applyFilters();
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Schwierigkeit-Filter
          _buildFilterSection(
            'Schwierigkeit',
            Row(
              children: [
                _buildAdvancedChip('Alle', _selectedDifficulty == null, () {
                  setState(() => _selectedDifficulty = null);
                  _applyFilters();
                }),
                const SizedBox(width: 8),
                _buildAdvancedChip('Einsteiger (1-2)', _selectedDifficulty == 1, () {
                  setState(() => _selectedDifficulty = 1);
                  _applyFilters();
                }),
                const SizedBox(width: 8),
                _buildAdvancedChip('Mittel (3)', _selectedDifficulty == 3, () {
                  setState(() => _selectedDifficulty = 3);
                  _applyFilters();
                }),
                const SizedBox(width: 8),
                _buildAdvancedChip('Experte (4-5)', _selectedDifficulty == 5, () {
                  setState(() => _selectedDifficulty = 5);
                  _applyFilters();
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Zeit-Filter
          _buildFilterSection(
            'Veröffentlicht',
            Row(
              children: [
                _buildAdvancedChip('Alle', _selectedTimeFilter == null || _selectedTimeFilter == 'alle', () {
                  setState(() => _selectedTimeFilter = 'alle');
                  _applyFilters();
                }),
                const SizedBox(width: 8),
                _buildAdvancedChip('Letzte Woche', _selectedTimeFilter == 'neu', () {
                  setState(() => _selectedTimeFilter = 'neu');
                  _applyFilters();
                }),
                const SizedBox(width: 8),
                _buildAdvancedChip('Letzter Monat', _selectedTimeFilter == 'woche', () {
                  setState(() => _selectedTimeFilter = 'woche');
                  _applyFilters();
                }),
                const SizedBox(width: 8),
                _buildAdvancedChip('Letzte 3 Monate', _selectedTimeFilter == 'monat', () {
                  setState(() => _selectedTimeFilter = 'monat');
                  _applyFilters();
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Autor-Filter
          if (_getAllAuthors().isNotEmpty)
            _buildFilterSection(
              'Autor',
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildAdvancedChip('Alle Autoren', _selectedAuthor == null, () {
                      setState(() => _selectedAuthor = null);
                      _applyFilters();
                    }),
                    const SizedBox(width: 8),
                    ..._getAllAuthors().take(5).map((author) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildAdvancedChip(author, _selectedAuthor == author, () {
                        setState(() => _selectedAuthor = author);
                        _applyFilters();
                      }),
                    )),
                  ],
                ),
              ),
            ),
          
          // Tag-Cloud
          if (_getAllTags().isNotEmpty)
            const SizedBox(height: 12),
          if (_getAllTags().isNotEmpty)
            _buildFilterSection(
              'Tags (${_selectedTags.length} ausgewählt)',
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _getAllTags().take(15).map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedTags.remove(tag);
                        } else {
                          _selectedTags.add(tag);
                        }
                      });
                      _applyFilters();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2196F3)
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2196F3)
                              : Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tag,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          if (isSelected)
                            const SizedBox(width: 4),
                          if (isSelected)
                            const Icon(Icons.close, color: Colors.white, size: 12),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        content,
      ],
    );
  }

  Widget _buildAdvancedChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2196F3)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2196F3)
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2196F3)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2196F3)
                : Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEntriesList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 📚 BÜCHER-BANNER (Neu!)
        if (_books.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_stories, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'VOLLSTÄNDIGE BÜCHER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${_books.length} professionelle Bücher mit je 10+ Kapiteln verfügbar',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ..._books.map((book) => _buildBookPreview(book)),
              ],
            ),
          ),
        ],
        
        // Normale Einträge
        ..._filteredEntries.map((entry) => _buildEntryCard(entry)),
      ],
    );
  }
  
  Widget _buildBookPreview(Book book) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(book.coverImageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.menu_book, color: Colors.white60, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${book.totalChapters} Kapitel',
                          style: const TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.schedule, color: Colors.white60, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          book.formattedReadingTime,
                          style: const TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            book.description,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _showBookReader(book),
            icon: const Icon(Icons.auto_stories, size: 16),
            label: const Text('Jetzt Lesen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2196F3),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showBookReader(Book book) {
    // Zeige Buch-Reader (kompakte Version)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            book.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                    Text(
                      book.author,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${book.totalChapters} Kapitel · ${book.formattedReadingTime}',
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              
              // Kapitel-Liste
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: book.chapters.length,
                  cacheExtent: 200.0, // 🚀 PHASE C: Pre-render optimization
                  addAutomaticKeepAlives: false, // 🚀 PHASE C: Memory optimization
                  addRepaintBoundaries: true, // 🚀 PHASE C: Isolate repaints
                  itemBuilder: (context, index) {
                    final chapter = book.chapters[index];
                    // 🚀 PHASE C: RepaintBoundary + ValueKey for performance
                    return RepaintBoundary(
                      key: ValueKey('chapter_${book.id}_$index'),
                      child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E2E2E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${chapter.chapterNumber}',
                              style: const TextStyle(
                                color: Color(0xFF2196F3),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          chapter.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${chapter.wordCount} Wörter · ${chapter.estimatedMinutes} Min',
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, 
                          color: Color(0xFF2196F3), size: 16),
                        onTap: () => _showChapterReader(book, chapter),
                      ),
                    ), // 🚀 PHASE C: End of RepaintBoundary
                  );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showChapterReader(Book book, BookChapter chapter) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFF1A1A1A),
          appBar: AppBar(
            title: Text('Kapitel ${chapter.chapterNumber}: ${chapter.title}'),
            backgroundColor: const Color(0xFF2196F3),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: const TextStyle(
                    color: Color(0xFF2196F3),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kapitel ${chapter.chapterNumber}',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  chapter.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  chapter.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEntryCard(KnowledgeEntry entry) {
    return GestureDetector(
      onTap: () => _showEntryDetail(entry),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF2196F3).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.typeLabel,
                    style: const TextStyle(
                      color: Color(0xFF2196F3),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.categoryLabel,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                    ),
                  ),
                ),
                Text(
                  '${entry.readingTime} Min',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 8),
                // Favoriten-Button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_favoriteIds.contains(entry.id)) {
                        _favoriteIds.remove(entry.id);
                      } else {
                        _favoriteIds.add(entry.id);
                      }
                    });
                  },
                  child: Icon(
                    _favoriteIds.contains(entry.id) ? Icons.favorite : Icons.favorite_border,
                    color: _favoriteIds.contains(entry.id) ? Colors.red : Colors.white60,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Title
            Text(
              entry.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Description
            Text(
              entry.description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            
            // Tags
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: entry.tags.take(3).map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            'Keine Einträge gefunden',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showEntryDetail(KnowledgeEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              entry.typeLabel,
                              style: const TextStyle(
                                color: Color(0xFF2196F3),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Title
                      Text(
                        entry.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Meta
                      Text(
                        '${entry.categoryLabel} · ${entry.difficultyLabel} · ${entry.readingTime} Min',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                      ),
                      if (entry.author != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'von ${entry.author}',
                          style: const TextStyle(
                            color: Color(0xFF2196F3),
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      
                      // Content
                      Text(
                        entry.fullContent,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Tags
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: entry.tags.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF2196F3).withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: Color(0xFF2196F3),
                              fontSize: 12,
                            ),
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 32),
                      
                      // Verwandte Inhalte
                      ..._buildRelatedContent(entry),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildRelatedContent(KnowledgeEntry currentEntry) {
    // Finde verwandte Einträge basierend auf Tags und Kategorie
    final relatedEntries = _allEntries.where((entry) {
      if (entry.id == currentEntry.id) return false;
      
      // Gleiche Kategorie
      if (entry.category == currentEntry.category) return true;
      
      // Gemeinsame Tags
      final commonTags = entry.tags.where((tag) => currentEntry.tags.contains(tag)).length;
      return commonTags >= 2;
    }).take(3).toList();

    if (relatedEntries.isEmpty) return [];

    return [
      const Divider(color: Colors.white24, thickness: 1),
      const SizedBox(height: 16),
      const Row(
        children: [
          Icon(Icons.link, color: Color(0xFF2196F3), size: 20),
          SizedBox(width: 8),
          Text(
            'VERWANDTE INHALTE',
            style: TextStyle(
              color: Color(0xFF2196F3),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      ...relatedEntries.map((related) => GestureDetector(
        onTap: () {
          Navigator.pop(context);
          Future.delayed(const Duration(milliseconds: 300), () {
            _showEntryDetail(related);
          });
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2E2E2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF2196F3).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTypeIcon(related.type),
                  color: const Color(0xFF2196F3),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      related.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${related.categoryLabel} · ${related.readingTime} Min',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF2196F3),
                size: 16,
              ),
            ],
          ),
        ),
      )),
    ];
  }

  IconData _getTypeIcon(KnowledgeType type) {
    switch (type) {
      case KnowledgeType.book:
        return Icons.auto_stories;
      case KnowledgeType.practice:
        return Icons.self_improvement;
      case KnowledgeType.method:
        return Icons.psychology;
      case KnowledgeType.symbol:
        return Icons.category;
      case KnowledgeType.ritual:
        return Icons.auto_fix_high;
      case KnowledgeType.concept:
        return Icons.lightbulb;
      case KnowledgeType.lexicon:
        return Icons.menu_book;
      case KnowledgeType.source:
        return Icons.source;
    }
  }
}
