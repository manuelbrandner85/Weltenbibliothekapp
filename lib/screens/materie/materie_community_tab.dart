import 'package:flutter/material.dart';
import '../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:url_launcher/url_launcher.dart';
import '../../models/community_post.dart';
import '../../models/live_feed_entry.dart';
import '../../services/live_feed_service.dart';
import '../../services/favorites_service.dart';
import '../../services/feed_filter_service.dart';
import '../../services/reading_progress_service.dart';
import '../../services/community_service.dart';
import '../../services/user_service.dart';
import '../../widgets/feed_filter_panel.dart';
import '../../widgets/create_post_dialog.dart';
import '../../widgets/like_button.dart';  // 🆕 Like Widget
import '../../widgets/comment_button.dart';  // 🆕 Comment Widget
import '../../widgets/share_dialog.dart';  // 🆕 Share Dialog
import 'dart:async';

/// Community-Tab für MATERIE-Welt mit integrierten Live-Feeds
class MaterieCommunityTab extends StatefulWidget {
  const MaterieCommunityTab({super.key});

  @override
  State<MaterieCommunityTab> createState() => _MaterieCommunityTabState();
}

class _MaterieCommunityTabState extends State<MaterieCommunityTab> {
  final LiveFeedService _feedService = LiveFeedService();
  final FavoritesService _favoritesService = FavoritesService();
  
  /// Get favorites count (uses static method)
  int get _favoritesCount => FavoritesService.getFavoritesCount();
  final FeedFilterService _filterService = FeedFilterService();
  final ReadingProgressService _readingService = ReadingProgressService();
  final CommunityService _communityService = CommunityService();
  final UserService _userService = UserService();
  List<MaterieFeedEntry> _liveFeeds = [];
  List<CommunityPost> _posts = []; // ✅ REAL POSTS from backend
  Timer? _updateTimer;
  DateTime _lastUpdate = DateTime.now();
  bool _showFilterPanel = false;
  
  // 🔧 PROFESSIONELLES ERROR-HANDLING
  bool _isLoading = false;
  String? _errorMessage;
  
  // Filter-State
  String _selectedView = 'all'; // 'all', 'community', 'feeds', 'favorites'

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint('🔵 MATERIE Community Tab initialisiert');
    }
    _loadFeeds();
    _loadCommunityPosts(); // ✅ Load real posts
    
    _filterService.init();
    _readingService.init();
    _startAutoUpdate();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadFeeds() async {
    if (kDebugMode) {
      debugPrint('🔵 MATERIE: Starte Feed-Loading...');
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final feeds = await _feedService.getMaterieFeeds();
      
      if (kDebugMode) {
        debugPrint('🔵 MATERIE: ${feeds.length} Feeds empfangen');
      }
      
      setState(() {
        _liveFeeds = feeds;
        _lastUpdate = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔵 MATERIE ERROR: $e');
      }
      
      setState(() {
        _errorMessage = 'Fehler beim Laden der Feeds: $e';
        _isLoading = false;
      });
    }
  }
  
  /// ✅ Load real community posts from backend
  Future<void> _loadCommunityPosts() async {
    if (kDebugMode) {
      debugPrint('🔵 MATERIE: Loading community posts...');
    }
    
    try {
      final posts = await _communityService.fetchPosts(worldType: WorldType.materie);
      
      if (kDebugMode) {
        debugPrint('🔵 MATERIE: ${posts.length} community posts loaded');
      }
      
      setState(() {
        _posts = posts;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔵 MATERIE: Error loading posts: $e');
      }
    }
  }
  
  /// Show create post dialog
  Future<void> _showCreatePostDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const CreatePostDialog(worldType: WorldType.materie),
    );
    
    if (result == true) {
      // Reload posts after successful creation
      _loadCommunityPosts();
    }
  }

  void _startAutoUpdate() {
    _updateTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _loadFeeds();
    });
  }
  
  /// Like a post
  Future<void> _likePost(CommunityPost post) async {
    try {
      await _communityService.likePost(post.id);
      
      // Update local state
      setState(() {
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          _posts[index] = CommunityPost(
            id: post.id,
            authorUsername: post.authorUsername,
            authorAvatar: post.authorAvatar,
            content: post.content,
            tags: post.tags,
            createdAt: post.createdAt,
            likes: post.likes + 1,
            comments: post.comments,
            shares: post.shares,
            hasImage: post.hasImage,
            worldType: post.worldType,
          );
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('👍 Post geliked!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Fehler: $e')),
      );
    }
  }
  
  /// Show comments dialog
  Future<void> _showCommentsDialog(CommunityPost post) async {
    final commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.comment, color: Color(0xFF2196F3)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Kommentare',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              
              // Comments list
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _communityService.getComments(post.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      return Center(child: Text('Fehler: ${snapshot.error}'));
                    }
                    
                    final comments = snapshot.data ?? [];
                    
                    if (comments.isEmpty) {
                      return const Center(
                        child: Text('Noch keine Kommentare. Sei der Erste!'),
                      );
                    }
                    
                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(comment['username'][0].toUpperCase()),
                          ),
                          title: Text(comment['username']),
                          subtitle: Text(comment['comment']),
                        );
                      },
                    );
                  },
                ),
              ),
              
              const Divider(),
              
              // Add comment
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: const InputDecoration(
                        hintText: 'Kommentar schreiben...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF2196F3)),
                    onPressed: () async {
                      final comment = commentController.text.trim();
                      if (comment.isEmpty) return;
                      
                      try {
                        final user = await _userService.getCurrentUser();
                        await _communityService.commentOnPost(
                          post.id,
                          user.username,
                          comment,
                        );
                        
                        commentController.clear();
                        Navigator.of(context).pop();
                        _loadCommunityPosts(); // Reload to update comment count
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('💬 Kommentar hinzugefügt!')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('❌ Fehler: $e')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Share post
  void _sharePost(CommunityPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareDialog(
        postId: post.id,
        postTitle: post.authorUsername,
        postContent: post.content,
        userId: 'user_manuel',  // TODO: Get from UserService
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D47A1),
              Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildViewSelector(),
            if (_showFilterPanel) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: FeedFilterPanel(
                  filterService: _filterService,
                  availableThemes: _getAvailableThemes(),
                  availableSources: _getAvailableSources(),
                  accentColor: const Color(0xFF2196F3),
                ),
              ),
            ],
            Expanded(
              child: _buildContentList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePostDialog,
        icon: const Icon(Icons.add),
        label: const Text('Neuer Post'),
        backgroundColor: const Color(0xFF2196F3),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MATERIE Community',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Community · Live-Feeds · Diskussionen',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          // Live-Indikator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4CAF50)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Filter-Button
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  _showFilterPanel ? Icons.filter_list_off : Icons.filter_list,
                  color: _showFilterPanel || _filterService.hasActiveFilters
                      ? const Color(0xFF2196F3)
                      : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _showFilterPanel = !_showFilterPanel;
                  });
                },
              ),
              if (_filterService.hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2196F3),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_filterService.activeFilterCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(width: 4),
          
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFF2196F3)),
            onPressed: _showCreatePostDialog, // ✅ Aktiviert - Neuer Post Dialog
          ),
        ],
      ),
    );
  }

  Widget _buildViewSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 50,
      child: Row(
        children: [
          _buildViewButton('all', 'Alle', Icons.view_list),
          const SizedBox(width: 8),
          _buildViewButton('feeds', 'Live-Feeds', Icons.rss_feed, badge: _liveFeeds.length),
          const SizedBox(width: 8),
          _buildViewButton('favorites', 'Favoriten', Icons.favorite, badge: _favoritesCount),
          const SizedBox(width: 8),
          _buildViewButton('community', 'Community', Icons.people),
          
          const Spacer(),
          
          // Update-Info
          Text(
            'Update: ${_formatUpdateTime()}',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton(String view, String label, IconData icon, {int? badge}) {
    final isSelected = _selectedView == view;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedView = view;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
            ? const Color(0xFF2196F3) 
            : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContentList() {
    // 🔧 ERROR STATE
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadFeeds,
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    
    // 🔄 LOADING STATE
    if (_isLoading && _liveFeeds.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF2196F3),
            ),
            SizedBox(height: 16),
            Text(
              'Lade echte RSS-Feeds...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    
    // ✅ CONTENT LOADED
    // Wende Filter an
    final filteredFeeds = _filterService.applyFilters(_liveFeeds);
    
    // 🔍 DEBUG: Zeige Feed-Status
    if (kDebugMode) {
      debugPrint('🔵 MATERIE UI: ${_liveFeeds.length} Feeds total, ${filteredFeeds.length} nach Filter');
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 💬 Community Posts Section (ZUERST - wichtiger als Feeds!)
        if (_selectedView == 'all' || _selectedView == 'community') ...[
          if (_selectedView == 'all') _buildSectionHeader('💬 Community Diskussionen', 'Aktuelle Beiträge'),
          
          ..._posts.map((post) => _buildPostCard(post)),
          
          if (_selectedView == 'all') const SizedBox(height: 24),
        ],
        
        // 📡 Live-Feeds Section (nach Community)
        if (_selectedView == 'all' || _selectedView == 'feeds') ...[
          if (_selectedView == 'all') _buildSectionHeader(
            '📡 Live-Feeds', 
            _filterService.hasActiveFilters
                ? '${filteredFeeds.length} von ${_liveFeeds.length} Feeds'
                : 'Aktualisiert alle 10 Min'
          ),
          
          // 🔍 WICHTIG: Zeige Status wenn keine Feeds
          if (_liveFeeds.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(Icons.rss_feed, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Keine Feeds verfügbar',
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Feeds werden geladen oder sind nicht verfügbar.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...filteredFeeds.map((feed) => _buildFeedCard(feed)),
          
          if (_selectedView == 'all') const SizedBox(height: 24),
        ],
        
                
        // ⭐ Favoriten Section
        if (_selectedView == 'favorites') ...[
          _buildSectionHeader('⭐ Gespeicherte Feeds', '$_favoritesCount Favoriten'),
          
          // Empty favorites placeholder - using actual feed data instead
          // ..._filterService.applyFilters([]).map((feed) => _buildFeedCard(feed)),
          
          if (_favoritesCount == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.favorite_border, size: 64, color: Colors.grey[600]),
                    const SizedBox(height: 16),
                    Text(
                      'Keine Favoriten',
                      style: TextStyle(fontSize: 18, color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tippe auf ❤️ um Feeds zu speichern',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedCard(MaterieFeedEntry feed) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1E1E1E),
      child: InkWell(
        onTap: () => _showFeedDetail(feed),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header mit Typ und Update-Badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF2196F3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getTypeIcon(feed.quellenTypLabel),
                          size: 12,
                          color: const Color(0xFF2196F3),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          feed.quellenTypLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Update-Badge
                  if (feed.updateType == UpdateType.neu)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'NEU',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  
                  const Spacer(),                  
                  const Spacer(),
                  
                  // ⭐ FAVORITEN-ICON (NEU!)
                  IconButton(
                    icon: Icon(
                      false
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: false
                          ? const Color(0xFFE91E63)
                          : Colors.grey,
                    ),
                    onPressed: () async {
                      // TODO: Implement favorites
                      setState(() {}); // UI aktualisieren
                    },
                    tooltip: false
                        ? 'Aus Favoriten entfernen'
                        : 'Zu Favoriten hinzufügen',
                  ),

                  
                  // Tiefe-Level
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < feed.tiefeLevel ? Icons.circle : Icons.circle_outlined,
                        size: 8,
                        color: const Color(0xFF2196F3),
                      );
                    }),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Titel
              Text(
                feed.titel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Zusammenfassung
              Text(
                feed.zusammenfassung,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Footer
              Row(
                children: [
                  Icon(
                    Icons.link,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      feed.quelle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Lesezeit-Badge
                  ..._buildReadingTimeBadge(feed),
                  
                  const SizedBox(width: 12),
                  
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(feed.fetchTimestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  // 🔗 Link-Button
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.open_in_new),
                    iconSize: 18,
                    color: const Color(0xFF2196F3),
                    tooltip: 'Quelle öffnen',
                    onPressed: () async {
                      final url = Uri.parse(feed.sourceUrl);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author & Time
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF2196F3),
                  child: Text(
                    post.authorAvatar ?? post.authorUsername[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorUsername,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _formatDate(post.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Content
            Text(
              post.content,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            
            // Tags
            Wrap(
              spacing: 8,
              children: post.tags.map((tag) {
                return Chip(
                  label: Text(
                    tag,
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: const Color(0xFF2196F3).withValues(alpha: 0.2),
                  padding: EdgeInsets.zero,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            
            // Actions - 🆕 NEUE INTERACTIVE WIDGETS
            Row(
              children: [
                // Like Button
                LikeButton(
                  postId: post.id,
                  userId: 'user_manuel',  // TODO: Get from UserService
                  initialLikeCount: post.likes,
                  initialIsLiked: false,  // TODO: Load actual state
                  onLikeChanged: () {
                    setState(() {
                      // UI will auto-update via LikeButton
                    });
                  },
                ),
                const SizedBox(width: 12),
                
                // Comment Button
                CommentButton(
                  postId: post.id,
                  userId: 'user_manuel',  // TODO: Get from UserService
                  username: 'Manuel',  // TODO: Get from UserService
                  initialCommentCount: post.comments,
                  onCommentAdded: () {
                    setState(() {
                      // UI will auto-update via CommentButton
                    });
                  },
                ),
                
                const Spacer(),
                
                // Share Button (existing)
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  color: Colors.grey,
                  onPressed: () => _sharePost(post),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedDetail(MaterieFeedEntry feed) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Typ-Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF2196F3)),
                      ),
                      child: Text(
                        feed.quellenTypLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Titel
                    Text(
                      feed.titel,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Quelle & Link
                    _buildDetailRow('Quelle', feed.quelle),
                    _buildDetailRow('Thema', feed.thema),
                    _buildDetailRow('Tiefe-Level', '${feed.tiefeLevel}/5'),
                    
                    const SizedBox(height: 24),
                    
                    const Text(
                      'Zusammenfassung',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      feed.zusammenfassung,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.6,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    const Text(
                      'Zentrale Fragestellung',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      feed.zentraleFragestellung,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.6,
                      ),
                    ),
                    
                    if (feed.historischerKontext.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Historischer Kontext',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        feed.historischerKontext,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          height: 1.6,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Quelle öffnen Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Quelle öffnen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                        onPressed: () async {
                          // 🔗 Öffne Quelle im Browser
                          final url = Uri.parse(feed.sourceUrl);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Quelle konnte nicht geöffnet werden'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'blog': return Icons.article;
      case 'archiv': return Icons.folder_special;
      case 'pdf': return Icons.picture_as_pdf;
      case 'essay': return Icons.menu_book;
      default: return Icons.description;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return 'vor ${difference.inDays} Tag${difference.inDays == 1 ? '' : 'en'}';
    } else if (difference.inHours > 0) {
      return 'vor ${difference.inHours} Stunde${difference.inHours == 1 ? '' : 'n'}';
    } else {
      return 'vor ${difference.inMinutes} Minute${difference.inMinutes == 1 ? '' : 'n'}';
    }
  }

  String _formatUpdateTime() {
    final now = DateTime.now();
    final diff = now.difference(_lastUpdate);
    
    if (diff.inMinutes < 1) {
      return 'gerade eben';
    } else if (diff.inMinutes < 60) {
      return 'vor ${diff.inMinutes} Min';
    } else {
      return 'vor ${diff.inHours} Std';
    }
  }

  /// Extrahiere alle verfügbaren Themen aus den Feeds
  List<String> _getAvailableThemes() {
    final themes = <String>{};
    for (final feed in _liveFeeds) {
      themes.add(feed.thema);
    }
    return themes.toList()..sort();
  }

  /// Extrahiere alle verfügbaren Quellen aus den Feeds
  List<String> _getAvailableSources() {
    final sources = <String>{};
    for (final feed in _liveFeeds) {
      sources.add(feed.quelle);
    }
    return sources.toList()..sort();
  }

  /// Erstelle Lesezeit-Badge mit Fortschrittsanzeige
  List<Widget> _buildReadingTimeBadge(MaterieFeedEntry feed) {
    // Berechne Lesezeit aus Zusammenfassung + historischer Kontext
    final text = '${feed.zusammenfassung} ${feed.historischerKontext} ${feed.zentraleFragestellung}';
    final info = _readingService.calculateReadingInfo(feed.feedId, text);
    
    // Hole Fortschritt falls vorhanden
    final progress = _readingService.getProgress(feed.feedId);
    
    return [
      Icon(
        Icons.menu_book,
        size: 14,
        color: progress != null && progress.progressPercent > 0
            ? const Color(0xFF2196F3)
            : Colors.grey[600],
      ),
      const SizedBox(width: 4),
      Text(
        '${info.estimatedMinutes} Min',
        style: TextStyle(
          fontSize: 12,
          color: progress != null && progress.progressPercent > 0
              ? const Color(0xFF2196F3)
              : Colors.grey[600],
          fontWeight: progress != null && progress.progressPercent > 0
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      if (progress != null && progress.progressPercent > 0) ...[
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${progress.progressPercent.toInt()}%',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2196F3),
            ),
          ),
        ),
      ],
    ];
  }
}
