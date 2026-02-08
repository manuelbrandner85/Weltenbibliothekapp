import 'package:flutter/material.dart';
import '../services/intelligent_search_service.dart';
import 'package:intl/intl.dart';

/// Intelligenter Such-Screen
class IntelligentSearchScreen extends StatefulWidget {
  final String? initialWorld; // Optional: 'materie' oder 'energie'
  
  const IntelligentSearchScreen({super.key, this.initialWorld});

  @override
  State<IntelligentSearchScreen> createState() => _IntelligentSearchScreenState();
}

class _IntelligentSearchScreenState extends State<IntelligentSearchScreen> {
  final IntelligentSearchService _searchService = IntelligentSearchService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<Map<String, dynamic>> _searchResults = [];
  List<String> _searchHistory = [];
  List<String> _suggestions = [];
  bool _isSearching = false;
  bool _showHistory = true;

  // Filter
  String? _selectedWorld;
  String? _selectedCategory;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _selectedWorld = widget.initialWorld;
    _loadSearchHistory();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final history = await _searchService.getSearchHistory();
    setState(() => _searchHistory = history);
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query.length >= 2) {
      setState(() {
        _showHistory = false;
        _suggestions = _searchService.getSuggestions(query, _getMockTitles());
      });
    } else {
      setState(() {
        _showHistory = true;
        _suggestions = [];
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _showHistory = false;
    });

    _searchFocus.unfocus();

    // Mock-Daten (in echter App: API-Call oder lokale Datenbank)
    final allArticles = _getMockArticles();

    final results = await _searchService.search(
      query: query,
      allArticles: allArticles,
      world: _selectedWorld,
      category: _selectedCategory,
      fromDate: _fromDate,
      toDate: _toDate,
    );

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(),
            _buildFilterChips(),
            Expanded(
              child: _showHistory
                  ? _buildSearchHistory()
                  : _suggestions.isNotEmpty
                      ? _buildSuggestions()
                      : _isSearching
                          ? const Center(child: CircularProgressIndicator())
                          : _searchResults.isNotEmpty
                              ? _buildSearchResults()
                              : _buildEmptyState(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _selectedWorld == 'materie' 
                ? Colors.blue.shade900.withValues(alpha: 0.3)
                : Colors.purple.shade900.withValues(alpha: 0.3),
            const Color(0xFF1A1A1A),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Suche...',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey.shade500),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                                _showHistory = true;
                              });
                            },
                          )
                        : null,
                  ),
                  onSubmitted: _performSearch,
                  textInputAction: TextInputAction.search,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.white),
                onPressed: _showFilterDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    if (_selectedWorld == null && _selectedCategory == null && _fromDate == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (_selectedWorld != null)
              _buildFilterChip(
                label: _selectedWorld!.toUpperCase(),
                onDelete: () => setState(() => _selectedWorld = null),
                color: _selectedWorld == 'materie' ? Colors.blue : Colors.purple,
              ),
            if (_selectedCategory != null)
              _buildFilterChip(
                label: _selectedCategory!,
                onDelete: () => setState(() => _selectedCategory = null),
              ),
            if (_fromDate != null || _toDate != null)
              _buildFilterChip(
                label: _getDateRangeLabel(),
                onDelete: () => setState(() {
                  _fromDate = null;
                  _toDate = null;
                }),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onDelete,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (color ?? Colors.grey).withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.close, size: 16, color: color ?? Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty) {
      return _buildTrendingSearches();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'LETZTE SUCHEN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            TextButton(
              onPressed: () async {
                await _searchService.clearSearchHistory();
                _loadSearchHistory();
              },
              child: const Text('LÖSCHEN'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._searchHistory.take(10).map((query) => ListTile(
          leading: const Icon(Icons.history, color: Colors.grey),
          title: Text(query, style: const TextStyle(color: Colors.white)),
          trailing: const Icon(Icons.north_west, color: Colors.grey, size: 16),
          onTap: () {
            _searchController.text = query;
            _performSearch(query);
          },
        )),
        const SizedBox(height: 24),
        _buildTrendingSearches(),
      ],
    );
  }

  Widget _buildTrendingSearches() {
    final trending = _searchService.getTrendingSearches(_selectedWorld ?? 'materie');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '🔥 TRENDING',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: trending.map((term) => ActionChip(
            label: Text(term),
            backgroundColor: const Color(0xFF2A2A2A),
            labelStyle: const TextStyle(color: Colors.white),
            onPressed: () {
              _searchController.text = term;
              _performSearch(term);
            },
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildSuggestions() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return ListTile(
          leading: const Icon(Icons.search, color: Colors.grey),
          title: Text(suggestion, style: const TextStyle(color: Colors.white)),
          trailing: const Icon(Icons.north_west, color: Colors.grey, size: 16),
          onTap: () {
            _searchController.text = suggestion;
            _performSearch(suggestion);
          },
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final article = _searchResults[index];
        return _buildArticleCard(article);
      },
    );
  }

  Widget _buildArticleCard(Map<String, dynamic> article) {
    final world = article['world'] as String;
    final worldColor = world == 'materie' ? Colors.blue : Colors.purple;
    final score = article['searchScore'] as double;
    
    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Navigate to article detail
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: worldColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      world.toUpperCase(),
                      style: TextStyle(
                        color: worldColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Relevanz-Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getScoreColor(score).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 12,
                          color: _getScoreColor(score),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${score.toInt()}%',
                          style: TextStyle(
                            color: _getScoreColor(score),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                article['title'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                article['content'] as String,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.category, color: Colors.grey.shade600, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    article['category'] as String,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
          Icon(Icons.search_off, size: 80, color: Colors.grey.shade700),
          const SizedBox(height: 24),
          Text(
            'Keine Ergebnisse',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Versuche andere Suchbegriffe',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FILTER',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text('Welt:', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Alle'),
                  selected: _selectedWorld == null,
                  onSelected: (selected) {
                    setState(() => _selectedWorld = null);
                    Navigator.pop(context);
                  },
                ),
                ChoiceChip(
                  label: const Text('Materie'),
                  selected: _selectedWorld == 'materie',
                  onSelected: (selected) {
                    setState(() => _selectedWorld = 'materie');
                    Navigator.pop(context);
                  },
                ),
                ChoiceChip(
                  label: const Text('Energie'),
                  selected: _selectedWorld == 'energie',
                  onSelected: (selected) {
                    setState(() => _selectedWorld = 'energie');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.amber;
    return Colors.orange;
  }

  String _getDateRangeLabel() {
    if (_fromDate != null && _toDate != null) {
      return '${DateFormat('dd.MM.yy').format(_fromDate!)} - ${DateFormat('dd.MM.yy').format(_toDate!)}';
    }
    if (_fromDate != null) {
      return 'Ab ${DateFormat('dd.MM.yy').format(_fromDate!)}';
    }
    if (_toDate != null) {
      return 'Bis ${DateFormat('dd.MM.yy').format(_toDate!)}';
    }
    return '';
  }

  // Mock-Daten (in echter App durch API ersetzen)
  List<Map<String, dynamic>> _getMockArticles() {
    return [
      {
        'id': '1',
        'title': 'Die Wahrheit über die Illuminati',
        'content': 'Geheimbünde kontrollieren die Welt. Die Illuminati sind real und ihre Symbolik ist überall...',
        'category': 'Geheimbünde',
        'world': 'materie',
        'publishedDate': '2025-01-15',
        'tags': ['illuminati', 'elite', 'kontrolle'],
        'views': 5000,
        'likes': 250,
      },
      {
        'id': '2',
        'title': 'UFO-Sichtungen nehmen zu',
        'content': 'Immer mehr Menschen berichten von UFO-Sichtungen. Was steckt dahinter...',
        'category': 'UFOs',
        'world': 'materie',
        'publishedDate': '2025-01-14',
        'tags': ['ufo', 'alien', 'sichtung'],
        'views': 3000,
        'likes': 150,
      },
      {
        'id': '3',
        'title': 'Chakra-Meditation für Anfänger',
        'content': 'Lerne die 7 Chakren kennen und wie du sie durch Meditation aktivierst...',
        'category': 'Meditation',
        'world': 'energie',
        'publishedDate': '2025-01-13',
        'tags': ['chakra', 'meditation', 'energie'],
        'views': 2000,
        'likes': 100,
      },
    ];
  }

  List<String> _getMockTitles() {
    return _getMockArticles().map((a) => a['title'] as String).toList();
  }
}
