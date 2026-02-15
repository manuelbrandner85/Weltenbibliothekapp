import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../services/cloudflare_api_service.dart';
import '../../core/storage/unified_storage_service.dart';

/// 🎯 Personalization & Recommendations Screen
/// Features:
/// - AI-powered content recommendations
/// - Reading progress tracking
/// - Bookmarks & favorites
/// - Custom reading lists
/// - Interest-based suggestions
class PersonalizationScreen extends StatefulWidget {
  const PersonalizationScreen({Key? key}) : super(key: key);

  @override
  State<PersonalizationScreen> createState() => _PersonalizationScreenState();
}

class _PersonalizationScreenState extends State<PersonalizationScreen> with SingleTickerProviderStateMixin {
  final CloudflareApiService _api = CloudflareApiService();
  final UnifiedStorageService _storage = UnifiedStorageService();
  
  late TabController _tabController;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _recommendations = [];
  List<Map<String, dynamic>> _bookmarks = [];
  List<Map<String, dynamic>> _readingHistory = [];
  Map<String, dynamic> _readingStats = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPersonalization();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadPersonalization() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = _storage.getCurrentUserId();
      
      // Load recommendations
      _recommendations = await _api.getRecommendations(userId, limit: 20);
      
      // Load bookmarks
      _bookmarks = await _storage.getBookmarks();
      
      // Load reading history
      _readingHistory = await _storage.getReadingHistory();
      
      // Calculate reading stats
      _readingStats = _calculateReadingStats();
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading personalization: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Map<String, dynamic> _calculateReadingStats() {
    final totalArticles = _readingHistory.length;
    final totalMinutes = _readingHistory.fold<int>(
      0,
      (sum, article) => sum + (article['reading_time'] ?? 0) as int,
    );
    
    final categories = <String, int>{};
    for (var article in _readingHistory) {
      final category = article['category'] ?? 'general';
      categories[category] = (categories[category] ?? 0) + 1;
    }
    
    final favoriteCategory = categories.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    return {
      'total_articles': totalArticles,
      'total_minutes': totalMinutes,
      'total_hours': (totalMinutes / 60).toStringAsFixed(1),
      'favorite_category': favoriteCategory,
      'categories': categories,
    };
  }
  
  Future<void> _toggleBookmark(Map<String, dynamic> article) async {
    final isBookmarked = _bookmarks.any((b) => b['id'] == article['id']);
    
    try {
      if (isBookmarked) {
        await _storage.removeBookmark(article['id']);
        setState(() {
          _bookmarks.removeWhere((b) => b['id'] == article['id']);
        });
        _showSnackBar('❌ Lesezeichen entfernt', Colors.orange);
      } else {
        await _storage.addBookmark(article);
        setState(() {
          _bookmarks.add(article);
        });
        _showSnackBar('✅ Lesezeichen hinzugefügt', Colors.green);
      }
    } catch (e) {
      _showSnackBar('❌ Fehler beim Aktualisieren', Colors.red);
    }
  }
  
  Future<void> _createReadingList() async {
    final nameController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('📚 Neue Leseliste'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Listenname',
              hintText: 'z.B. Favoriten, Später lesen',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, nameController.text),
              child: const Text('Erstellen'),
            ),
          ],
        );
      },
    );
    
    if (result != null && result.isNotEmpty) {
      await _storage.createReadingList(result);
      _showSnackBar('✅ Leseliste erstellt', Colors.green);
    }
  }
  
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('🎯 Für Dich')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎯 Für Dich'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.recommend), text: 'Empfohlen'),
            Tab(icon: Icon(Icons.bookmark), text: 'Lesezeichen'),
            Tab(icon: Icon(Icons.history), text: 'Verlauf'),
            Tab(icon: Icon(Icons.insights), text: 'Statistiken'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRecommendationsTab(),
          _buildBookmarksTab(),
          _buildHistoryTab(),
          _buildStatsTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: _createReadingList,
              icon: const Icon(Icons.add),
              label: const Text('Neue Liste'),
            )
          : null,
    );
  }
  
  Widget _buildRecommendationsTab() {
    if (_recommendations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Noch keine Empfehlungen verfügbar'),
            const SizedBox(height: 8),
            const Text(
              'Lies mehr Artikel, um personalisierte Empfehlungen zu erhalten',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _recommendations.length,
      itemBuilder: (context, index) {
        final article = _recommendations[index];
        final relevanceScore = article['relevance_score'] ?? 0.0;
        final isBookmarked = _bookmarks.any((b) => b['id'] == article['id']);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getCategoryColor(article['category']),
              child: Text(
                '${(relevanceScore * 100).toInt()}%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              article['title'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(article['category'] ?? 'general'),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${article['reading_time'] ?? 5} Min. Lesezeit',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            isThreeLine: true,
            trailing: IconButton(
              icon: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: isBookmarked ? Colors.blue : null,
              ),
              onPressed: () => _toggleBookmark(article),
            ),
            onTap: () {
              // Navigate to article
              _trackReading(article);
            },
          ),
        );
      },
    );
  }
  
  Widget _buildBookmarksTab() {
    if (_bookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Noch keine Lesezeichen'),
            const SizedBox(height: 8),
            const Text(
              'Markiere Artikel, um sie später zu lesen',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _bookmarks.length,
      itemBuilder: (context, index) {
        final article = _bookmarks[index];
        
        return Dismissible(
          key: Key(article['id']),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) {
            _toggleBookmark(article);
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                Icons.article,
                color: _getCategoryColor(article['category']),
              ),
              title: Text(article['title'] ?? ''),
              subtitle: Text(
                'Gespeichert: ${_formatTimestamp(article['saved_at'])}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to article
                _trackReading(article);
              },
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildHistoryTab() {
    if (_readingHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Noch kein Leseverlauf'),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _readingHistory.length,
      itemBuilder: (context, index) {
        final article = _readingHistory[index];
        final progress = article['progress'] ?? 0.0;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: _getCategoryColor(article['category']),
                  child: Icon(
                    progress >= 1.0 ? Icons.check : Icons.article,
                    color: Colors.white,
                  ),
                ),
                if (progress > 0 && progress < 1.0)
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.transparent,
                      strokeWidth: 2,
                    ),
                  ),
              ],
            ),
            title: Text(article['title'] ?? ''),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gelesen: ${_formatTimestamp(article['read_at'])}'),
                if (progress < 1.0)
                  Text(
                    '${(progress * 100).toInt()}% gelesen',
                    style: TextStyle(color: Colors.orange[700]),
                  ),
              ],
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Continue reading
              _trackReading(article);
            },
          ),
        );
      },
    );
  }
  
  Widget _buildStatsTab() {
    final totalArticles = _readingStats['total_articles'] ?? 0;
    final totalHours = _readingStats['total_hours'] ?? '0.0';
    final favoriteCategory = _readingStats['favorite_category'] ?? 'general';
    final categories = _readingStats['categories'] as Map<String, int>? ?? {};
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overview cards
        Row(
          children: [
            Expanded(
              child: Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.article, size: 40, color: Colors.blue[700]),
                      const SizedBox(height: 8),
                      Text(
                        '$totalArticles',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      const Text('Artikel gelesen'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.schedule, size: 40, color: Colors.green[700]),
                      const SizedBox(height: 8),
                      Text(
                        totalHours,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      const Text('Stunden gelesen'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Favorite category
        Card(
          child: ListTile(
            leading: Icon(Icons.favorite, color: Colors.red[700]),
            title: const Text('Lieblingskategorie'),
            subtitle: Text(favoriteCategory),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Category breakdown
        const Text(
          '📊 Kategorien-Verteilung',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        ...categories.entries.map((entry) {
          final percentage = (entry.value / totalArticles * 100).toStringAsFixed(1);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getCategoryColor(entry.key),
                child: Text(
                  '${entry.value}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(entry.key),
              trailing: Text(
                '$percentage%',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
  
  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'research':
        return Colors.blue;
      case 'meditation':
        return Colors.purple;
      case 'astral':
        return Colors.indigo;
      case 'conspiracy':
        return Colors.red;
      case 'history':
        return Colors.brown;
      case 'science':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    
    try {
      final dt = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final diff = now.difference(dt);
      
      if (diff.inMinutes < 1) return 'Gerade eben';
      if (diff.inMinutes < 60) return 'vor ${diff.inMinutes}m';
      if (diff.inHours < 24) return 'vor ${diff.inHours}h';
      if (diff.inDays < 7) return 'vor ${diff.inDays}d';
      
      return '${dt.day}.${dt.month}.${dt.year}';
    } catch (e) {
      return '';
    }
  }
  
  Future<void> _trackReading(Map<String, dynamic> article) async {
    try {
      await _storage.addToReadingHistory(article);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error tracking reading: $e');
      }
    }
  }
}
