import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../../widgets/favorite_button.dart';
import '../../models/favorite.dart';  // 🆕 For FavoriteType

/// Moderner Energie-Wissen-Tab - Spirituelle Bibliothek
class EnergieWissenTabModern extends StatefulWidget {
  const EnergieWissenTabModern({super.key});

  @override
  State<EnergieWissenTabModern> createState() => _EnergieWissenTabModernState();
}

class _EnergieWissenTabModernState extends State<EnergieWissenTabModern> {
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'all'; // 'all', 'meditation', 'kristalle', 'chakren', 'weisheit'
  
  // Demo Weisheits-Einträge
  final List<WisdomEntry> _allEntries = [
    WisdomEntry(
      id: '1',
      title: 'Die 7 Chakren verstehen',
      category: 'chakren',
      summary: 'Vollständige Anleitung zu den Energiezentren des Körpers und wie man sie aktiviert.',
      readingTime: 15,
      tags: ['Chakren', 'Energie', 'Meditation'],
      enlightenmentLevel: 4,
    ),
    WisdomEntry(
      id: '2',
      title: 'Meditation für Anfänger',
      category: 'meditation',
      summary: 'Schritt-für-Schritt-Anleitung zum Einstieg in die Meditationspraxis.',
      readingTime: 10,
      tags: ['Meditation', 'Achtsamkeit', 'Anfänger'],
      enlightenmentLevel: 2,
    ),
    WisdomEntry(
      id: '3',
      title: 'Heilsteine und ihre Wirkung',
      category: 'kristalle',
      summary: 'Umfassender Guide über Kristalle, Heilsteine und ihre energetischen Eigenschaften.',
      readingTime: 20,
      tags: ['Kristalle', 'Heilung', 'Energie'],
      enlightenmentLevel: 3,
    ),
    WisdomEntry(
      id: '4',
      title: 'Die Kraft der Achtsamkeit',
      category: 'weisheit',
      summary: 'Wie Achtsamkeitspraxis dein Leben transformieren kann.',
      readingTime: 12,
      tags: ['Achtsamkeit', 'Bewusstsein', 'Transformation'],
      enlightenmentLevel: 5,
    ),
    WisdomEntry(
      id: '5',
      title: 'Kundalini Erweckung',
      category: 'chakren',
      summary: 'Fortgeschrittene Praktiken zur Erweckung der Kundalini-Energie.',
      readingTime: 25,
      tags: ['Kundalini', 'Energie', 'Fortgeschritten'],
      enlightenmentLevel: 5,
    ),
    WisdomEntry(
      id: '6',
      title: 'Astralreisen Grundlagen',
      category: 'weisheit',
      summary: 'Einführung in außerkörperliche Erfahrungen und astrale Projektion.',
      readingTime: 18,
      tags: ['Astralreisen', 'Bewusstsein', 'Spirituell'],
      enlightenmentLevel: 4,
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint('🟣 ENERGIE Wissen Tab Modern initialisiert');
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);
  }

  List<WisdomEntry> get _filteredEntries {
    var filtered = _allEntries;

    // Suchfilter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((e) {
        return e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            e.summary.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            e.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }

    // Kategorie-Filter
    if (_selectedCategory != 'all') {
      filtered = filtered.where((e) => e.category == _selectedCategory).toList();
    }

    return filtered;
  }

  int _getCategoryCount(String category) {
    if (category == 'all') return _allEntries.length;
    return _allEntries.where((e) => e.category == category).length;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF4A148C).withValues(alpha: 0.05),
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
                          (context, index) => _buildWisdomCard(_filteredEntries[index]),
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
                '📖',
                style: TextStyle(fontSize: 40),
              ),
              const SizedBox(width: 12),
              const Text(
                'Weisheits-Bibliothek',
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
            'Deine gesammelte spirituelle Weisheit',
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
            Colors.purple.withValues(alpha: 0.15),
            Colors.purple.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 24,
            color: Colors.purple.withValues(alpha: 0.8, red: 0.7, green: 0.4, blue: 0.9),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Suche in Weisheits-Einträgen...',
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
                color: Colors.purple.withValues(alpha: 0.8, red: 0.7, green: 0.4, blue: 0.9),
              ),
              onPressed: () {
                setState(() => _searchQuery = '');
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
              '✨ Alle (${_getCategoryCount('all')})',
              Colors.purple,
            ),
            const SizedBox(width: 12),
            _buildCategoryChip(
              'meditation',
              '🧘 Meditation (${_getCategoryCount('meditation')})',
              Colors.blue,
            ),
            const SizedBox(width: 12),
            _buildCategoryChip(
              'kristalle',
              '💎 Kristalle (${_getCategoryCount('kristalle')})',
              Colors.cyan,
            ),
            const SizedBox(width: 12),
            _buildCategoryChip(
              'chakren',
              '🔮 Chakren (${_getCategoryCount('chakren')})',
              Colors.pink,
            ),
            const SizedBox(width: 12),
            _buildCategoryChip(
              'weisheit',
              '🌟 Weisheit (${_getCategoryCount('weisheit')})',
              Colors.amber,
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
        setState(() => _selectedCategory = category);
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
    final totalReadingTime = _allEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.readingTime,
    );
    final avgEnlightenment = _allEntries.fold<double>(
      0.0,
      (sum, entry) => sum + entry.enlightenmentLevel,
    ) / _allEntries.length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withValues(alpha: 0.15),
            Colors.pink.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('📚', '$totalEntries', 'Einträge'),
          _buildStatItem('⏱️', '$totalReadingTime Min', 'Lesezeit'),
          _buildStatItem('✨', avgEnlightenment.toStringAsFixed(1), 'Erleuchtung'),
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

  Widget _buildWisdomCard(WisdomEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.withValues(alpha: 0.1),
            Colors.pink.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (kDebugMode) {
            debugPrint('📖 Weisheits-Eintrag geöffnet: ${entry.title}');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header mit Kategorie-Badge und Erleuchtungs-Level
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
                      _getCategoryName(entry.category),
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
                    itemId: 'energie_${entry.title}',
                    itemType: FavoriteType.narrative,
                    itemTitle: entry.title,
                    color: Colors.amber,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  // Erleuchtungs-Level
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < entry.enlightenmentLevel
                            ? Icons.star
                            : Icons.star_border,
                        size: 16,
                        color: Colors.amber.withValues(alpha: 0.8),
                      );
                    }),
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
              Text(
                entry.summary,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // Tags und Lesezeit
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: entry.tags.take(2).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.purple.withValues(alpha: 0.9, red: 0.8, green: 0.5, blue: 0.9),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
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
            '🌌',
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          const Text(
            'Keine Weisheits-Einträge gefunden',
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

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'meditation':
        return Colors.blue;
      case 'kristalle':
        return Colors.cyan;
      case 'chakren':
        return Colors.pink;
      case 'weisheit':
        return Colors.amber;
      default:
        return Colors.purple;
    }
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'meditation':
        return 'Meditation';
      case 'kristalle':
        return 'Kristalle';
      case 'chakren':
        return 'Chakren';
      case 'weisheit':
        return 'Weisheit';
      default:
        return 'Allgemein';
    }
  }
}

// Hilfsklasse für Weisheits-Einträge
class WisdomEntry {
  final String id;
  final String title;
  final String category;
  final String summary;
  final int readingTime;
  final List<String> tags;
  final int enlightenmentLevel; // 1-5 Sterne

  WisdomEntry({
    required this.id,
    required this.title,
    required this.category,
    required this.summary,
    required this.readingTime,
    required this.tags,
    required this.enlightenmentLevel,
  });
}
