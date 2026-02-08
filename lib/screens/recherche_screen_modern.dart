import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_components.dart';

/// 🔍 MODERNER RECHERCHE-SCREEN
/// 
/// Große Suchleiste, Quick-Filter, Tab-basierte Modi, Card-Ergebnisse

class RechercheScreenModern extends StatefulWidget {
  const RechercheScreenModern({super.key});

  @override
  State<RechercheScreenModern> createState() => _RechercheScreenModernState();
}

class _RechercheScreenModernState extends State<RechercheScreenModern> 
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  
  String _selectedTimeFilter = 'Alle';
  bool _isSearching = false;
  bool _hasResults = false;
  
  // Mock Results
  final List<Map<String, dynamic>> _mockResults = [
    {
      'title': 'Geopolitische Spannungen in Europa 2025',
      'source': 'Alternative Medien',
      'category': 'Geopolitik',
      'categoryColor': AppTheme.geopolitikGreen,
      'date': '15. Jan 2025',
      'readTime': '8 min',
      'trustScore': 4,
      'preview': 'Analyse der aktuellen geopolitischen Lage in Europa mit Fokus auf...',
    },
    {
      'title': 'WikiLeaks: Neue Dokumente enthüllt',
      'source': 'WikiLeaks Official',
      'category': 'Transparenz',
      'categoryColor': AppTheme.transparenzYellow,
      'date': '14. Jan 2025',
      'readTime': '12 min',
      'trustScore': 5,
      'preview': 'Geheime Regierungsdokumente zeigen bisher unbekannte Verbindungen...',
    },
    {
      'title': 'CERN Forschung: Durchbruch in Teilchenphysik',
      'source': 'CERN News',
      'category': 'Forschung',
      'categoryColor': AppTheme.forschungPurple,
      'date': '13. Jan 2025',
      'readTime': '15 min',
      'trustScore': 5,
      'preview': 'Wissenschaftler am CERN haben einen bedeutenden Durchbruch...',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _performSearch() {
    if (_searchController.text.isEmpty) return;
    
    setState(() {
      _isSearching = true;
    });

    // Simulate search
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _hasResults = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.materieGradient,
      ),
      child: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: _hasResults ? _buildResults() : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        gradient: AppTheme.darkSurfaceGradient,
        boxShadow: AppTheme.shadowMedium,
      ),
      child: Column(
        children: [
          const SizedBox(height: AppTheme.space2),
          
          // Large Search Bar
          _buildSearchBar(),
          
          const SizedBox(height: AppTheme.space3),
          
          // Quick Time Filters
          _buildTimeFilters(),
          
          const SizedBox(height: AppTheme.space3),
          
          // Mode Tabs
          _buildModeTabs(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: TextField(
        controller: _searchController,
        style: AppTheme.bodyLarge.copyWith(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Suche nach Wahrheit...',
          hintStyle: AppTheme.bodyLarge.copyWith(
            color: Colors.white.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.materieBlueLight,
            size: 28,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _hasResults = false;
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space4,
            vertical: AppTheme.space4,
          ),
        ),
        onSubmitted: (_) => _performSearch(),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildTimeFilters() {
    final filters = ['Alle', 'Heute', 'Woche', 'Monat'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: AppTheme.space2),
            child: PremiumChip(
              label: filter,
              isSelected: _selectedTimeFilter == filter,
              onTap: () {
                setState(() {
                  _selectedTimeFilter = filter;
                });
              },
              color: AppTheme.materieBlue,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModeTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.materieBlue.withValues(alpha: 0.7),
              AppTheme.materieBlue.withValues(alpha: 0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.coloredShadow(AppTheme.materieBlue),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
        labelStyle: AppTheme.labelMedium.copyWith(fontWeight: FontWeight.w700),
        tabs: const [
          Tab(text: 'Standard'),
          Tab(text: 'Kaninchenbau'),
          Tab(text: 'International'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppTheme.space4),
            Text(
              'Suche nach Wahrheit',
              style: AppTheme.headlineMedium.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppTheme.space2),
            Text(
              'Gib einen Suchbegriff ein um zu starten',
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space6),
            
            // Quick Search Suggestions
            Wrap(
              spacing: AppTheme.space2,
              runSpacing: AppTheme.space2,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('Geopolitik'),
                _buildSuggestionChip('WikiLeaks'),
                _buildSuggestionChip('CERN'),
                _buildSuggestionChip('NSA'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        _searchController.text = text;
        _performSearch();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space4,
          vertical: AppTheme.space2,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: AppTheme.materieBlueLight.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: AppTheme.labelMedium.copyWith(
            color: AppTheme.materieBlueLight,
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    return TabBarView(
      controller: _tabController,
      physics: const BouncingScrollPhysics(),
      children: [
        _buildResultsList(), // Standard
        _buildResultsList(), // Kaninchenbau
        _buildResultsList(), // International
      ],
    );
  }

  Widget _buildResultsList() {
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.materieBlue),
            ),
            const SizedBox(height: AppTheme.space4),
            Text(
              'Suche läuft...',
              style: AppTheme.bodyLarge.copyWith(color: Colors.white),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.space4),
      itemCount: _mockResults.length,
      itemBuilder: (context, index) {
        return _buildResultCard(_mockResults[index]);
      },
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space3),
      child: PremiumCard(
        onTap: () {
          // Open article
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              result['title'],
              style: AppTheme.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppTheme.space2),
            
            // Preview
            Text(
              result['preview'],
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppTheme.space3),
            
            // Metadata Row
            Wrap(
              spacing: AppTheme.space2,
              runSpacing: AppTheme.space1,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Category Tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space2,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: result['categoryColor'].withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: result['categoryColor'].withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    result['category'],
                    style: AppTheme.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                
                // Trust Score
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) {
                    return Icon(
                      i < result['trustScore'] ? Icons.star : Icons.star_border,
                      size: 14,
                      color: AppTheme.transparenzYellow,
                    );
                  }),
                ),
                
                // Date
                Text(
                  result['date'],
                  style: AppTheme.bodySmall,
                ),
                
                // Read Time
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      result['readTime'],
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
