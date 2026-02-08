import 'package:flutter/material.dart';
import '../../models/knowledge_extended_models.dart';
import '../../services/unified_knowledge_service.dart';
// ⚡ PERFORMANCE HELPER
import 'knowledge_reader_mode.dart';

/// 🔍 ERWEITERTE SUCHE MIT FILTER & SORTIERUNG
/// 
/// Features:
/// - Volltext-Suche (Titel, Beschreibung, Tags, Content)
/// - Multi-Category Filter
/// - Sortierung (Neu, Alt, Beliebt, A-Z, Lesezeit)
/// - Suchhistorie (letzte 5 Suchen)
/// - Quick-Filter Pills
class AdvancedSearchDelegate extends SearchDelegate<KnowledgeEntry?> {
  final String world;
  final UnifiedKnowledgeService _knowledgeService = UnifiedKnowledgeService();
  
  // Filter & Sort State
  final Set<String> _selectedCategories = {};
  String _sortBy = 'relevance'; // relevance, newest, oldest, popular, az, readtime
  
  AdvancedSearchDelegate({required this.world}) : super(
    searchFieldLabel: 'Suche in $world...',
    searchFieldStyle: const TextStyle(fontSize: 16),
  );

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final worldColor = world == 'materie' 
        ? const Color(0xFF1E88E5) 
        : const Color(0xFF7E57C2);

    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? Colors.black : Colors.white,
        iconTheme: IconThemeData(color: worldColor),
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      // Clear button
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
          tooltip: 'Löschen',
        ),
      
      // Filter button
      IconButton(
        icon: Badge(
          label: Text('${_selectedCategories.length}'),
          isLabelVisible: _selectedCategories.isNotEmpty,
          child: const Icon(Icons.filter_list),
        ),
        onPressed: () => _showFilterDialog(context),
        tooltip: 'Filter',
      ),
      
      // Sort button
      PopupMenuButton<String>(
        icon: const Icon(Icons.sort),
        tooltip: 'Sortieren',
        onSelected: (value) {
          _sortBy = value;
          showResults(context);
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'relevance', child: Text('🎯 Relevanz')),
          const PopupMenuItem(value: 'newest', child: Text('🆕 Neueste')),
          const PopupMenuItem(value: 'oldest', child: Text('📅 Älteste')),
          const PopupMenuItem(value: 'popular', child: Text('🔥 Beliebt')),
          const PopupMenuItem(value: 'az', child: Text('🔤 A-Z')),
          const PopupMenuItem(value: 'readtime', child: Text('⏱️ Lesezeit')),
        ],
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
      tooltip: 'Zurück',
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _loadSearchHistory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final history = snapshot.data!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Category Filters
            if (_selectedCategories.isEmpty)
              _buildQuickFilters(context),
            
            // Search History
            if (query.isEmpty && history.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Letzte Suchen',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...history.map((term) => ListTile(
                leading: const Icon(Icons.history),
                title: Text(term),
                trailing: IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 20),
                  onPressed: () {
                    query = term;
                    showResults(context);
                  },
                ),
                onTap: () {
                  query = term;
                  showResults(context);
                },
              )),
            ],
            
            // Popular Searches
            if (query.isEmpty && history.isEmpty)
              _buildPopularSearches(context),
          ],
        );
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty && _selectedCategories.isEmpty) {
      return _buildEmptyState(context, 'Gib einen Suchbegriff ein oder wähle einen Filter.');
    }

    // Save to history
    if (query.isNotEmpty) {
      _saveSearchHistory(query);
    }

    return FutureBuilder<List<KnowledgeEntry>>(
      future: _performSearch(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildEmptyState(context, 'Fehler: ${snapshot.error}');
        }

        final results = snapshot.data ?? [];
        
        if (results.isEmpty) {
          return _buildEmptyState(
            context,
            query.isNotEmpty 
                ? 'Keine Ergebnisse für "$query"'
                : 'Keine Einträge in den gewählten Kategorien',
          );
        }

        return Column(
          children: [
            // Result count & active filters
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]
                  : Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${results.length} Ergebnisse',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_selectedCategories.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedCategories.map((cat) {
                        return Chip(
                          label: Text(
                            _getCategoryLabel(cat),
                            style: const TextStyle(fontSize: 12),
                          ),
                          onDeleted: () {
                            _selectedCategories.remove(cat);
                            showResults(context);
                          },
                          deleteIcon: const Icon(Icons.close, size: 16),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            
            // Results list
            Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  return _buildResultTile(context, results[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<KnowledgeEntry>> _performSearch() async {
    await _knowledgeService.init();
    
    // Get all entries for this world
    List<KnowledgeEntry> entries = await _knowledgeService.getAllEntries(world: world);
    
    // Filter by categories
    if (_selectedCategories.isNotEmpty) {
      entries = entries.where((e) => 
        _selectedCategories.contains(e.category)
      ).toList();
    }
    
    // Search in text
    if (query.isNotEmpty) {
      final searchLower = query.toLowerCase();
      entries = entries.where((e) {
        final titleMatch = e.title.toLowerCase().contains(searchLower);
        final descMatch = e.description.toLowerCase().contains(searchLower);
        final tagsMatch = e.tags.any((tag) => tag.toLowerCase().contains(searchLower));
        final contentMatch = e.fullContent.toLowerCase().contains(searchLower);
        
        return titleMatch || descMatch || tagsMatch || contentMatch;
      }).toList();
    }
    
    // Sort
    switch (_sortBy) {
      case 'newest':
        entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'popular':
        // TODO: Sort by view count when available
        break;
      case 'az':
        entries.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'readtime':
        entries.sort((a, b) => a.readingTimeMinutes.compareTo(b.readingTimeMinutes));
        break;
      case 'relevance':
      default:
        // Keep search relevance order
        break;
    }
    
    return entries;
  }

  Widget _buildResultTile(BuildContext context, KnowledgeEntry entry) {
    // TODO: Use worldColor or remove
    /*
    final worldColor = world == 'materie' 
        ? const Color(0xFF1E88E5) 
        : const Color(0xFF7E57C2);
    */

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getCategoryColor(entry.category ?? '').withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getCategoryIcon(entry.category ?? ''),
          color: _getCategoryColor(entry.category ?? ''),
          size: 20,
        ),
      ),
      title: Text(
        entry.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            entry.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${entry.readingTimeMinutes} min',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getCategoryColor(entry.category ?? '').withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getCategoryLabel(entry.category ?? ''),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getCategoryColor(entry.category ?? ''),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => KnowledgeReaderMode(
              entry: entry,
              world: world,
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickFilters(BuildContext context) {
    final categories = world == 'materie'
        ? ['conspiracy', 'research', 'forbiddenKnowledge', 'ancientWisdom']
        : ['meditation', 'astrology', 'energyWork', 'consciousness'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick-Filter',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((cat) {
              return FilterChip(
                label: Text(_getCategoryLabel(cat)),
                selected: _selectedCategories.contains(cat),
                onSelected: (selected) {
                  if (selected) {
                    _selectedCategories.add(cat);
                  } else {
                    _selectedCategories.remove(cat);
                  }
                  showResults(context);
                },
                backgroundColor: _getCategoryColor(cat).withValues(alpha: 0.1),
                selectedColor: _getCategoryColor(cat).withValues(alpha: 0.3),
                checkmarkColor: _getCategoryColor(cat),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularSearches(BuildContext context) {
    final popular = world == 'materie'
        ? ['MK-Ultra', '9/11', 'JFK', 'Fluorid', 'CIA']
        : ['Meditation', 'Chakra', 'Astrologie', 'Kundalini', 'Reiki'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Beliebte Suchen',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: popular.map((term) {
              return ActionChip(
                label: Text(term),
                onPressed: () {
                  query = term;
                  showResults(context);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFilterDialog(BuildContext context) async {
    final categories = world == 'materie'
        ? ['conspiracy', 'research', 'forbiddenKnowledge', 'ancientWisdom']
        : ['meditation', 'astrology', 'energyWork', 'consciousness'];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Kategorien filtern'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: categories.map((cat) {
                  return CheckboxListTile(
                    title: Text(_getCategoryLabel(cat)),
                    value: _selectedCategories.contains(cat),
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedCategories.add(cat);
                        } else {
                          _selectedCategories.remove(cat);
                        }
                      });
                    },
                    activeColor: _getCategoryColor(cat),
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _selectedCategories.clear();
                    Navigator.pop(context);
                    showResults(context);
                  },
                  child: const Text('Zurücksetzen'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    showResults(context);
                  },
                  child: const Text('Anwenden'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<String>> _loadSearchHistory() async {
    // TODO: Load from persistent storage
    return [];
  }

  Future<void> _saveSearchHistory(String term) async {
    // TODO: Save to persistent storage
  }

  String _getCategoryLabel(String category) {
    const labels = {
      'conspiracy': 'Verschwörungen',
      'research': 'Forschung',
      'forbiddenKnowledge': 'Verbotenes Wissen',
      'ancientWisdom': 'Alte Weisheit',
      'meditation': 'Meditation',
      'astrology': 'Astrologie',
      'energyWork': 'Energie-Arbeit',
      'consciousness': 'Bewusstsein',
    };
    return labels[category] ?? category;
  }

  Color _getCategoryColor(String category) {
    const colors = {
      'conspiracy': Color(0xFFE53935),
      'research': Color(0xFF1E88E5),
      'forbiddenKnowledge': Color(0xFF6A1B9A),
      'ancientWisdom': Color(0xFFFFB300),
      'meditation': Color(0xFF7E57C2),
      'astrology': Color(0xFFAB47BC),
      'energyWork': Color(0xFF26A69A),
      'consciousness': Color(0xFF29B6F6),
    };
    return colors[category] ?? Colors.grey;
  }

  IconData _getCategoryIcon(String category) {
    const icons = {
      'conspiracy': Icons.visibility_off,
      'research': Icons.science,
      'forbiddenKnowledge': Icons.lock,
      'ancientWisdom': Icons.auto_stories,
      'meditation': Icons.self_improvement,
      'astrology': Icons.star,
      'energyWork': Icons.energy_savings_leaf,
      'consciousness': Icons.psychology,
    };
    return icons[category] ?? Icons.article;
  }
}
