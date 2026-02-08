import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/knowledge_extended_models.dart';
import '../../services/unified_knowledge_service.dart';
import 'knowledge_card_modern.dart';
import 'knowledge_reader_mode.dart';
import 'advanced_search_delegate.dart'; // 🔍 ADVANCED SEARCH

/// ============================================
/// UNIFIED KNOWLEDGE TAB - MEGA UPDATE
/// Moderne UI mit allen Features:
/// - Favoriten, Notizen, Lesefortschritt
/// - Such & Filter
/// - Kategorien
/// - Statistiken
/// - KI-Empfehlungen
/// ============================================

class UnifiedKnowledgeTab extends StatefulWidget {
  final String world; // 'materie' oder 'energie'
  
  const UnifiedKnowledgeTab({super.key, required this.world});

  @override
  State<UnifiedKnowledgeTab> createState() => _UnifiedKnowledgeTabState();
}

class _UnifiedKnowledgeTabState extends State<UnifiedKnowledgeTab> with SingleTickerProviderStateMixin {
  final _knowledgeService = UnifiedKnowledgeService();
  final _searchController = TextEditingController();
  
  List<KnowledgeEntry> _allEntries = [];
  List<KnowledgeEntry> _filteredEntries = [];
  Map<String, int> _stats = {};
  
  bool _isLoading = true;
  String _selectedCategory = 'all';
  // UNUSED FIELD: String _selectedView = 'grid'; // grid, list, favorites, read
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final entries = await _knowledgeService.getAllEntries(world: widget.world);
      final stats = await _knowledgeService.getStatistics(widget.world);
      
      setState(() {
        _allEntries = entries;
        _filteredEntries = entries;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Load error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterEntries() {
    setState(() {
      _filteredEntries = _allEntries.where((entry) {
        // Category filter
        if (_selectedCategory != 'all' && entry.category != _selectedCategory) {
          return false;
        }
        
        // Search filter
        if (_searchController.text.isNotEmpty) {
          final query = _searchController.text.toLowerCase();
          return entry.title.toLowerCase().contains(query) ||
                 entry.description.toLowerCase().contains(query) ||
                 entry.tags.any((tag) => tag.toLowerCase().contains(query));
        }
        
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = widget.world == 'materie' 
        ? const Color(0xFF2196F3) 
        : const Color(0xFF9C27B0);
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.grey[50],
      body: Column(
        children: [
          // HEADER MIT STATISTIKEN
          _buildHeader(primaryColor, isDark),
          
          // TAB BAR
          _buildTabBar(primaryColor),
          
          // CONTENT
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllEntriesTab(),
                _buildFavoritesTab(),
                _buildReadEntriesTab(),
                _buildRecommendationsTab(),
              ],
            ),
          ),
        ],
      ),
      
      // FLOATING ACTION BUTTON: Erweiterte Suche
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showSearch(
            context: context,
            delegate: AdvancedSearchDelegate(world: widget.world),
          );
        },
        backgroundColor: primaryColor,
        tooltip: 'Erweiterte Suche',
        child: const Icon(Icons.search),
      ),
    );
  }

  Widget _buildHeader(Color primaryColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor.withValues(alpha: 0.8), primaryColor],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Titel
            Text(
              widget.world == 'materie' ? '📚 MATERIE WISSEN' : '🧘 ENERGIE WISSEN',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // Statistiken
            if (!_isLoading && _stats.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatCard(
                    icon: Icons.library_books,
                    label: 'Gesamt',
                    value: _stats['total']?.toString() ?? '0',
                  ),
                  _StatCard(
                    icon: Icons.check_circle,
                    label: 'Gelesen',
                    value: _stats['read']?.toString() ?? '0',
                  ),
                  _StatCard(
                    icon: Icons.star,
                    label: 'Favoriten',
                    value: _stats['favorites']?.toString() ?? '0',
                  ),
                  _StatCard(
                    icon: Icons.note,
                    label: 'Notizen',
                    value: _stats['with_notes']?.toString() ?? '0',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(Color primaryColor) {
    return Container(
      color: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF1A1A1A) 
          : Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: primaryColor,
        tabs: const [
          Tab(icon: Icon(Icons.grid_view), text: 'Alle'),
          Tab(icon: Icon(Icons.star), text: 'Favoriten'),
          Tab(icon: Icon(Icons.check), text: 'Gelesen'),
          Tab(icon: Icon(Icons.recommend), text: 'Empfehlungen'),
        ],
      ),
    );
  }

  Widget _buildAllEntriesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          // Category Filter
          _buildCategoryFilter(),
          
          // Entry Grid
          Expanded(
            child: _filteredEntries.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _filteredEntries.length,
                    itemBuilder: (context, index) {
                      return _buildEntryCard(_filteredEntries[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab() {
    return FutureBuilder<List<KnowledgeEntry>>(
      future: _knowledgeService.getFavorites(world: widget.world),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final favorites = snapshot.data!;
        
        if (favorites.isEmpty) {
          return _buildEmptyState(
            icon: Icons.star_border,
            message: 'Keine Favoriten',
            hint: 'Markiere Einträge als Favoriten!',
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            return _buildEntryListTile(favorites[index]);
          },
        );
      },
    );
  }

  Widget _buildReadEntriesTab() {
    return FutureBuilder<List<KnowledgeEntry>>(
      future: _knowledgeService.getReadEntries(world: widget.world),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final readEntries = snapshot.data!;
        
        if (readEntries.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline,
            message: 'Noch nichts gelesen',
            hint: 'Starte mit dem ersten Eintrag!',
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: readEntries.length,
          itemBuilder: (context, index) {
            return _buildEntryListTile(readEntries[index]);
          },
        );
      },
    );
  }

  Widget _buildRecommendationsTab() {
    return FutureBuilder<List<KnowledgeEntry>>(
      future: _knowledgeService.getRecommendations(widget.world, limit: 10),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final recommendations = snapshot.data!;
        
        if (recommendations.isEmpty) {
          return _buildEmptyState(
            icon: Icons.lightbulb_outline,
            message: 'Keine Empfehlungen',
            hint: 'Lies ein paar Einträge, um Empfehlungen zu erhalten!',
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: recommendations.length,
          itemBuilder: (context, index) {
            return _buildEntryListTile(recommendations[index]);
          },
        );
      },
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['all', 'conspiracy', 'ancientWisdom', 'forbiddenKnowledge', 
                        'books', 'meditation', 'astrology', 'energyWork', 'consciousness'];
    
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(category == 'all' ? 'Alle' : category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                  _filterEntries();
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEntryCard(KnowledgeEntry entry) {
    final primaryColor = widget.world == 'materie' 
        ? const Color(0xFF2196F3) 
        : const Color(0xFF9C27B0);
    
    return FutureBuilder<bool>(
      future: _knowledgeService.isFavorite(entry.id),
      builder: (context, snapshot) {
        final isFav = snapshot.data ?? false;
        
        return KnowledgeCardModern(
          entry: entry,
          isFavorite: isFav,
          onTap: () => _openEntryDetail(entry),
          onFavoriteToggle: () async {
            if (isFav) {
              await _knowledgeService.removeFavorite(entry.id);
            } else {
              await _knowledgeService.addFavorite(entry.id);
            }
            setState(() {});
          },
          primaryColor: primaryColor,
        );
      },
    );
  }


  Widget _buildEntryListTile(KnowledgeEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(entry.category),
          child: const Icon(Icons.book, color: Colors.white, size: 20),
        ),
        title: Text(
          entry.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          entry.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: FutureBuilder<bool>(
          future: _knowledgeService.isFavorite(entry.id),
          builder: (context, snapshot) {
            final isFav = snapshot.data ?? false;
            return Icon(
              isFav ? Icons.star : Icons.star_border,
              color: Colors.amber,
            );
          },
        ),
        onTap: () => _openEntryDetail(entry),
      ),
    );
  }

  Widget _buildEmptyState({IconData? icon, String? message, String? hint}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon ?? Icons.search_off,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            message ?? 'Keine Einträge gefunden',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (hint != null) ...[
            const SizedBox(height: 8),
            Text(
              hint,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  void _openEntryDetail(KnowledgeEntry entry) async {
    // Increment view count
    await _knowledgeService.incrementViewCount(entry.id);
    
    // Navigate to NEW Reader Mode
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KnowledgeReaderMode(
          entry: entry,
          world: widget.world,
        ),
      ),
    ).then((_) => _loadData()); // Refresh after returning
  }

  // Unused: _showSearchDialog method (kept for future search feature)
  // void _showSearchDialog() {
    // showDialog(
      // context: context,
      // builder: (context) => AlertDialog(
        // title: const Text('Suche'),
        // content: TextField(
          // controller: _searchController,
          // decoration: const InputDecoration(
            // hintText: 'Suchbegriff eingeben...',
            // prefixIcon: Icon(Icons.search),
          // ),
          // onChanged: (_) => _filterEntries(),
        // ),
        // actions: [
          // TextButton(
            // onPressed: () {
              // setState(() {
                // _searchController.clear();
                // _filterEntries();
              // });
              // Navigator.pop(context);
            // },
            // child: const Text('Löschen'),
          // ),
          // TextButton(
            // onPressed: () => Navigator.pop(context),
            // child: const Text('Schließen'),
          // ),
        // ],
      // ),
    // );
  // }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'conspiracy':
        return const Color(0xFFE53935);
      case 'ancientWisdom':
        return const Color(0xFFFFB300);
      case 'forbiddenKnowledge':
        return const Color(0xFF6A1B9A);
      case 'books':
        return const Color(0xFF43A047);
      case 'meditation':
        return const Color(0xFF7E57C2);
      case 'astrology':
        return const Color(0xFFAB47BC);
      case 'energyWork':
        return const Color(0xFF26A69A);
      case 'consciousness':
        return const Color(0xFF29B6F6);
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}

/// DETAIL SCREEN
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
      if (note != null) {
        _noteController.text = note.content;
      }
    });
    
    // Update progress
    await _knowledgeService.updateProgress(widget.entry.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wissendetails'),
        actions: [
          // Favorite Button
          IconButton(
            icon: Icon(_isFavorite ? Icons.star : Icons.star_border),
            onPressed: () async {
              if (_isFavorite) {
                await _knowledgeService.removeFavorite(widget.entry.id);
              } else {
                await _knowledgeService.addFavorite(widget.entry.id);
              }
              setState(() => _isFavorite = !_isFavorite);
            },
          ),
          
          // Share Button
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Share.share(
                '${widget.entry.title}\n\n${widget.entry.description}\n\nQuelle: Weltenbibliothek',
              );
            },
          ),
          
          // Read Toggle
          IconButton(
            icon: Icon(_isRead ? Icons.check_circle : Icons.check_circle_outline),
            onPressed: () async {
              await _knowledgeService.updateProgress(
                widget.entry.id,
                isRead: !_isRead,
              );
              setState(() => _isRead = !_isRead);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Title
          Text(
            widget.entry.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Metadata
          Wrap(
            spacing: 8,
            children: [
              Chip(
                label: Text(widget.entry.category),
                avatar: const Icon(Icons.category, size: 16),
              ),
              Chip(
                label: Text(widget.entry.type),
                avatar: const Icon(Icons.label, size: 16),
              ),
              Chip(
                label: Text('${widget.entry.readingTimeMinutes} min'),
                avatar: const Icon(Icons.schedule, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Description
          Text(
            widget.entry.description,
            style: const TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),
          const Divider(height: 40),
          
          // Full Content
          Text(
            widget.entry.fullContent,
            style: const TextStyle(fontSize: 15, height: 1.6),
          ),
          const SizedBox(height: 30),
          
          // Tags
          Wrap(
            spacing: 8,
            children: widget.entry.tags.map((tag) {
              return Chip(
                label: Text(tag),
                backgroundColor: Colors.blue.withValues(alpha: 0.1),
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
          
          // Notes Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Deine Notizen',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Notiere deine Gedanken...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_note != null)
                        TextButton.icon(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text('Löschen'),
                          onPressed: () async {
                            await _knowledgeService.deleteNote(widget.entry.id);
                            setState(() {
                              _note = null;
                              _noteController.clear();
                            });
                          },
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Speichern'),
                        onPressed: () async {
                          await _knowledgeService.saveNote(
                            widget.entry.id,
                            _noteController.text,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notiz gespeichert!')),
                          );
                          await _loadData();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}

/// STAT CARD WIDGET
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
