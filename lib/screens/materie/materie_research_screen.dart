import 'package:flutter/material.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'dart:async';
import '../../services/backend_recherche_service.dart';
import '../../services/favorites_service.dart';  // 🆕 Favorites Service
import '../../services/search_history_service.dart';  // 🆕 Search History Service
import '../../models/favorite.dart';  // 🆕 Favorite Model
import '../../widgets/follow_up_questions_widget.dart';
import '../../widgets/enhanced_multimedia_section.dart';
import '../../widgets/enhanced_source_card.dart';
import '../../widgets/research_filters_widget.dart' hide SourceType;
import '../../widgets/share_research_widget.dart';
import '../../widgets/related_topics_widget.dart';  // RelatedTopic, RelatedTopicsWidget
import '../../widgets/research_timeline_widget.dart';  // TimelineEvent, ResearchTimelineWidget
import '../../widgets/native_share_helper.dart';  // 🆕 Native Share Helper
import 'compare_mode_screen.dart';

/// MATERIE RESEARCH SCREEN - Production Internet Research
/// 
/// Features:
/// - Backend-basierte Recherche (CORS-kompatibel)
/// - Auto-Start bei Vorschlag-Klick
/// - Alternative Quellen Priorisierung
/// - Production-Ready Error Handling
class MaterieResearchScreen extends StatefulWidget {
  const MaterieResearchScreen({super.key});

  @override
  State<MaterieResearchScreen> createState() => _MaterieResearchScreenState();
}

class _MaterieResearchScreenState extends State<MaterieResearchScreen> {
  // Services
  final BackendRechercheService _searchService = BackendRechercheService();
  
  // Controllers
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  // State
  InternetSearchResult? _currentResult;
  List<String> _querySuggestions = [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  bool _isFavorite = false;
  
  // Debounce Timer
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    
    // Query change listener
    _queryController.addListener(_onQueryChanged);
    
    // Focus listener
    _searchFocusNode.addListener(() {
      setState(() {
        _showSuggestions = _searchFocusNode.hasFocus && _querySuggestions.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounceTimer?.cancel();
    
    final query = _queryController.text;
    
    if (query.length < 3) {
      setState(() {
        _querySuggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _loadQuerySuggestions(query);
    });
  }

  Future<void> _loadQuerySuggestions(String query) async {
    try {
      final suggestions = await _searchService.getQuerySuggestions(query);
      setState(() {
        _querySuggestions = suggestions;
        _showSuggestions = suggestions.isNotEmpty && _searchFocusNode.hasFocus;
      });
    } catch (e) {
      debugPrint('Suggestions error: $e');
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _isSearching = true;
      _showSuggestions = false;
      _currentResult = null;
    });
    
    _searchFocusNode.unfocus();
    
    try {
      final result = await _searchService.searchInternet(query);
      
      setState(() {
        _currentResult = result;
        _isSearching = false;
      });
      
      // Check if this research is already favorited
      _checkIfFavorite();
      
      // 🆕 Save to search history
      try {
        await SearchHistoryService.addSearch(
          query: query,
          resultCount: result.sources.length,
          summary: result.summary.length > 200 
              ? '${result.summary.substring(0, 200)}...'
              : result.summary,
          tags: result.relatedTopics?.map((t) => t['category'] as String? ?? '').where((s) => s.isNotEmpty).toList(),
        );
      } catch (e) {
        debugPrint('Error saving search history: $e');
      }
      
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      
      if (mounted) {
        // Production-Ready Error Messages
        String errorTitle = '❌ Recherche fehlgeschlagen';
        String errorMessage = 'Ein unerwarteter Fehler ist aufgetreten.';
        
        if (e is NetworkException) {
          errorTitle = '🌐 Verbindungsfehler';
          errorMessage = e.toString();
        } else if (e is ServiceUnavailableException) {
          errorTitle = '⚠️ Service vorübergehend nicht verfügbar';
          errorMessage = e.toString();
        } else if (e is RateLimitException) {
          errorTitle = '⏱️ Zu viele Anfragen';
          errorMessage = e.toString();
        } else if (e is TimeoutException) {
          errorTitle = '⏰ Zeitüberschreitung';
          errorMessage = e.toString();
        } else {
          errorMessage = e.toString();
        }
        
        // Show professional error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  errorTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  errorMessage,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'ERNEUT VERSUCHEN',
              textColor: Colors.white,
              onPressed: () {
                _performSearch(query);
              },
            ),
          ),
        );
      }
    }
  }

  void _handleFollowUpQuestion(String question) {
    _queryController.text = question;
    _performSearch(question);
  }

  // ════════════════════════════════════════════════════════════
  // FAVORITES MANAGEMENT
  // ════════════════════════════════════════════════════════════
  
  Future<void> _toggleFavorite() async {
    if (_currentResult == null) return;

    try {
      if (_isFavorite) {
        // Remove from favorites
        final favorites = FavoritesService.getAllFavorites();
        final existing = favorites.where((f) => 
          f.type == FavoriteType.research && f.title == _currentResult!.query
        ).toList();
        
        for (var fav in existing) {
          await FavoritesService.deleteFavorite(fav.id);
        }
        
        setState(() => _isFavorite = false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Aus Favoriten entfernt'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Add to favorites
        final favorite = Favorite(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: FavoriteType.research,
          title: _currentResult!.query,
          description: _currentResult!.summary.length > 100 
              ? '${_currentResult!.summary.substring(0, 100)}...'
              : _currentResult!.summary,
          createdAt: DateTime.now(),
          metadata: {
            'query': _currentResult!.query,
            'summary': _currentResult!.summary,
            'sources': _currentResult!.sources.length,
            'timestamp': _currentResult!.timestamp.toIso8601String(),
          },
        );
        
        await FavoritesService.addFavorite(favorite);
        setState(() => _isFavorite = true);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Zu Favoriten hinzugefügt'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkIfFavorite() async {
    if (_currentResult == null) return;
    
    try {
      final favorites = FavoritesService.getAllFavorites();
      final exists = favorites.any((f) => 
        f.type == FavoriteType.research && f.title == _currentResult!.query
      );
      
      setState(() => _isFavorite = exists);
    } catch (e) {
      debugPrint('Error checking favorite: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Row(
          children: const [
            Icon(Icons.travel_explore, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('🔍 MATERIE RECHERCHE'),
          ],
        ),
        actions: [
          // Favorite Button
          if (_currentResult != null)
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : null,
              ),
              tooltip: _isFavorite ? 'Aus Favoriten entfernen' : 'Zu Favoriten hinzufügen',
              onPressed: () => _toggleFavorite(),
            ),
          // Share Button
          if (_currentResult != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (context) => ShareResearchWidget(
                    query: _currentResult!.query,
                    summary: _currentResult!.summary,
                    sources: _currentResult!.sources.map((s) => s.toJson()).toList(),
                    multimedia: _currentResult!.multimedia,
                  ),
                );
              },
            ),
          // History Button
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Recherche-Historie',
            onPressed: () async {
              final query = await Navigator.pushNamed(context, '/search_history');
              if (query != null && query is String && query.isNotEmpty) {
                _queryController.text = query;
                _performSearch(query);
              }
            },
          ),
          // Compare Mode Button
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: 'Vergleichsmodus',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CompareModeScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchSection(),
          Expanded(
            child: _isSearching
                ? _buildLoadingState()
                : _currentResult != null
                    ? _buildResultsView()
                    : _buildEmptyState(),
          ),
        ],
      ),
      // 🆕 Quick Share FAB
      floatingActionButton: _currentResult != null
          ? QuickShareFAB(
              query: _currentResult!.query,
              summary: _currentResult!.summary,
              sources: _currentResult!.sources.map((s) => s.url).toList(),
            )
          : null,
    );
  }

  Widget _buildSearchSection() {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Main Search Input
          TextField(
            controller: _queryController,
            focusNode: _searchFocusNode,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: 'Alternative Quellen recherchieren...',
              hintStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.red,
                size: 24,
              ),
              suffixIcon: _queryController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      onPressed: () {
                        _queryController.clear();
                        setState(() {
                          _currentResult = null;
                          _querySuggestions = [];
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF2A2A2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onSubmitted: _performSearch,
          ),
          
          // Suggestions
          if (_showSuggestions) ...[
            const SizedBox(height: 8),
            QuerySuggestionsWidget(
              suggestions: _querySuggestions,
              onSuggestionTap: (suggestion) {
                setState(() {
                  _showSuggestions = false;
                  _querySuggestions = [];
                  _queryController.text = suggestion;
                });
                // WICHTIG: Recherche automatisch starten
                _performSearch(suggestion);
              },
            ),
          ],
          
          // Filter Widget
          const SizedBox(height: 8),
          ResearchFiltersWidget(
            initialFilters: ResearchFilters.defaultFilters(),
            onFiltersChanged: (filters) {
              // TODO: Apply filters to results
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Colors.red,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            '🔍 Durchsuche das Internet...',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Alternative Quellen, Unabhängige Medien & mehr',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    final result = _currentResult!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Query Info
          Text(
            'Recherche: "${result.query}"',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Recherche-Bericht (OHNE KI-Hinweise!)
          Card(
            color: const Color(0xFF1A1A1A),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.article,
                        color: Colors.red,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '📄 Recherche-Bericht',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.summary,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Related Topics Widget (NEW)
          if (result.relatedTopics != null && result.relatedTopics!.isNotEmpty) ...[
            RelatedTopicsWidget(
              currentQuery: result.query,
              relatedTopics: result.relatedTopics!
                  .map((t) => RelatedTopic(
                        query: t['topic'] as String? ?? '',
                        title: t['description'] as String? ?? t['topic'] as String? ?? '',
                        category: t['category'] as String? ?? 'general',
                        relevanceScore: (t['relevance'] as num?)?.toInt() ?? 3,
                      ))
                  .toList(),
              onTopicTap: (topic) {
                _queryController.text = topic;
                _performSearch(topic);
              },
            ),
            const SizedBox(height: 16),
          ],
          
          // Timeline Widget (NEW)
          if (result.timeline != null && result.timeline!.isNotEmpty) ...[
            ResearchTimelineWidget(
              title: 'Timeline: ${result.query}',
              events: result.timeline!
                  .map((t) {
                    try {
                      return TimelineEvent.fromJson(t);
                    } catch (e) {
                      // Fallback with safe values
                      return TimelineEvent(
                        date: DateTime.tryParse(t['date'] as String? ?? '') ?? DateTime.now(),
                        title: t['title'] as String? ?? '',
                        description: t['description'] as String? ?? '',
                        importance: (t['importance'] as num?)?.toInt() ?? 1,
                        category: t['category'] as String?,
                        sources: [],
                      );
                    }
                  })
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          
          // Enhanced Multimedia Section (v7.2)
          EnhancedMultimediaSection(
            multimedia: result.multimedia,
            query: result.query,
          ),
          
          const SizedBox(height: 16),
          
          // Sources Section
          Row(
            children: [
              const Icon(
                Icons.source,
                color: Colors.red,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Quellen (${result.sources.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Source Stats
          _buildSourceTypeStats(result.sources),
          
          const SizedBox(height: 16),
          
          // Enhanced Sources (Klickbar!)
          ...result.sources.map((source) => EnhancedSourceCard(source: source.toJson())),
          
          const SizedBox(height: 16),
          
          // Follow-Up
          FollowUpQuestionsWidget(
            questions: result.followUpQuestions,
            onQuestionTap: _handleFollowUpQuestion,
          ),
        ],
      ),
    );
  }

  Widget _buildSourceTypeStats(List<SearchSource> sources) {
    final mainstream = sources.where((s) => s.sourceType == SourceType.mainstream).length;
    final alternative = sources.where((s) => s.sourceType == SourceType.alternative).length;
    final independent = sources.where((s) => s.sourceType == SourceType.independent).length;
    
    return Row(
      children: [
        _buildStatChip('Mainstream', mainstream, SourceType.mainstream.color),
        const SizedBox(width: 8),
        _buildStatChip('Alternative', alternative, SourceType.alternative.color),
        const SizedBox(width: 8),
        _buildStatChip('Unabhängig', independent, SourceType.independent.color),
      ],
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.travel_explore,
            size: 96,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          const Text(
            'Internet-Recherche',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Durchsuche das Internet nach alternativen Quellen, '
              'unabhängigen Medien und kritischen Perspektiven',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Quick Search Examples
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildQuickSearchChip('COVID-19 alternative Quellen'),
              _buildQuickSearchChip('9/11 Verschwörungstheorien'),
              _buildQuickSearchChip('Great Reset WEF'),
              _buildQuickSearchChip('Klimawandel Kritik'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSearchChip(String query) {
    return InkWell(
      onTap: () {
        setState(() {
          _queryController.text = query;
        });
        // WICHTIG: Recherche automatisch starten
        _performSearch(query);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          query,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
