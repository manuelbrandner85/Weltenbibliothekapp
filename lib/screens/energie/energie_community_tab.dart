import 'package:flutter/material.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:url_launcher/url_launcher.dart';
import '../../utils/date_helpers.dart';
import '../../models/community_post.dart';
import '../../models/live_feed_entry.dart';
import '../../services/live_feed_service.dart';
import '../../services/favorites_service.dart';
import '../../services/feed_filter_service.dart';
import '../../services/reading_progress_service.dart';
import '../../services/user_service.dart'; // 🆕 User Service für Auth
import '../../services/community_service.dart';
import '../../widgets/feed_filter_panel.dart';
import '../../widgets/create_post_dialog.dart';
import '../../widgets/like_button.dart';  // 🆕 Like Widget
import '../../widgets/comment_button.dart';  // 🆕 Comment Widget
import '../../widgets/share_dialog.dart';  // 🆕 Share Dialog
import '../../services/achievement_service.dart';  // 🏆 Achievement System
import '../../services/daily_challenges_service.dart';  // 🎯 Daily Challenges
import 'dart:async';

/// Community-Tab für ENERGIE-Welt mit integrierten Live-Feeds
class EnergieCommunityTab extends StatefulWidget {
  const EnergieCommunityTab({super.key});

  @override
  State<EnergieCommunityTab> createState() => _EnergieCommunityTabState();
}

class _EnergieCommunityTabState extends State<EnergieCommunityTab> {
  final LiveFeedService _feedService = LiveFeedService();
  final FavoritesService _favoritesService = FavoritesService();
  
  /// Get favorites count (uses static method)
  int get _favoritesCount => FavoritesService.getFavoritesCount();
  final FeedFilterService _filterService = FeedFilterService();
  final ReadingProgressService _readingService = ReadingProgressService();
  final CommunityService _communityService = CommunityService();
  // UNUSED FIELD: final UserService _userService = UserService();
  List<EnergieFeedEntry> _liveFeeds = [];
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
    _loadFeeds();
    _loadCommunityPosts(); // ✅ Load real posts
    // FavoritesService already initialized in ServiceManager
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final feeds = await _feedService.getEnergieFeeds();
      setState(() {
        _liveFeeds = feeds;
        _lastUpdate = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Laden der Feeds: $e';
        _isLoading = false;
      });
    }
  }
  
  /// ✅ Load real community posts from backend
  Future<void> _loadCommunityPosts() async {
    if (kDebugMode) {
      debugPrint('🟣 ENERGIE: Loading community posts...');
    }
    
    try {
      final posts = await _communityService.fetchPosts(worldType: WorldType.energie);
      
      if (kDebugMode) {
        debugPrint('🟣 ENERGIE: ${posts.length} community posts loaded');
      }
      
      setState(() {
        _posts = posts;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🟣 ENERGIE: Error loading posts: $e');
      }
    }
  }
  
  /// Show create post dialog
  Future<void> _showCreatePostDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const CreatePostDialog(worldType: WorldType.energie),
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
              Color(0xFF4A148C),
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
                  accentColor: const Color(0xFF9C27B0),
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
        backgroundColor: const Color(0xFF9C27B0),
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
                  'ENERGIE Community',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Community · Spirit-Feeds · Austausch',
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
              color: const Color(0xFF9C27B0).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF9C27B0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF9C27B0),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9C27B0),
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
                      ? const Color(0xFF9C27B0)
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
                      color: Color(0xFF9C27B0),
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
            icon: const Icon(Icons.add_circle, color: Color(0xFF9C27B0)),
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
          _buildViewButton('feeds', 'Spirit-Feeds', Icons.auto_awesome, badge: _liveFeeds.length),
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
            ? const Color(0xFF9C27B0) 
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
                  color: const Color(0xFFE91E63),
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
                backgroundColor: const Color(0xFF9C27B0),
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
              color: Color(0xFF9C27B0),
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
      debugPrint('🟣 ENERGIE UI: ${_liveFeeds.length} Feeds total, ${filteredFeeds.length} nach Filter');
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 💬 Community Posts Section (ZUERST - wichtiger als Feeds!)
        if (_selectedView == 'all' || _selectedView == 'community') ...[
          if (_selectedView == 'all') _buildSectionHeader('💬 Community Austausch', 'Aktuelle Beiträge'),
          
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
          
          // TODO: Re-implement with new Favorites API
          ..._filterService.applyFilters(_liveFeeds.where((feed) => false).toList()).map((feed) => _buildFeedCard(feed)),
          
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

  Widget _buildFeedCard(EnergieFeedEntry feed) {
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
                      color: const Color(0xFF9C27B0).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF9C27B0)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getTypeIcon(feed.quellenTypLabel),
                          size: 12,
                          color: const Color(0xFF9C27B0),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          feed.quellenTypLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF9C27B0),
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
                        color: const Color(0xFFE91E63),
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
                  
                  // ⭐ FAVORITEN-ICON (TODO: Re-implement with new API)
                  IconButton(
                    icon: const Icon(
                      Icons.favorite_border,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      // TODO: Implement with FavoritesService static API
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Favorites coming soon!')),
                      );
                    },
                    tooltip: 'Zu Favoriten hinzufügen',
                  ),

                  
                  // Symbol-Schwerpunkte Icons
                  if (feed.symbolSchwerpunkte.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      children: feed.symbolSchwerpunkte.take(3).map((symbol) {
                        return Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF9C27B0).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            size: 12,
                            color: Color(0xFF9C27B0),
                          ),
                        );
                      }).toList(),
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
              
              // Symbolische Einordnung
              Text(
                feed.symbolischeEinordnung,
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
                    color: const Color(0xFF9C27B0),
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
                  backgroundColor: const Color(0xFF9C27B0),
                  child: Text(
                    post.authorUsername[0].toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                        DateHelpers.getRealisticTimestamp(post.createdAt),
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
                  backgroundColor: const Color(0xFF9C27B0).withValues(alpha: 0.2),
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
                  userId: UserService.getCurrentUserId(),  // 🔥 REAL USER ID
                  initialLikeCount: post.likes,
                  initialIsLiked: false,  // TODO: Load actual state
                  onLikeChanged: () {
                    setState(() {
                      // UI will auto-update via LikeButton
                    });
                    // 🏆 Achievement Trigger: Like
                    _trackLikeAchievement();
                  },
                ),
                const SizedBox(width: 12),
                
                // Comment Button
                CommentButton(
                  postId: post.id,
                  userId: UserService.getCurrentUserId(),  // 🔥 REAL USER ID
                  username: UserService.getCurrentUsername(),  // 🔥 REAL USERNAME
                  initialCommentCount: post.comments,
                  onCommentAdded: () {
                    setState(() {
                      // UI will auto-update via CommentButton
                    });
                    // 🏆 Achievement Trigger: Comment
                    _trackCommentAchievement();
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

  void _sharePost(CommunityPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareDialog(
        postId: post.id,
        postTitle: post.authorUsername,
        postContent: post.content,
        userId: UserService.getCurrentUserId(),  // 🔥 REAL USER ID
      ),
    );
  }

  void _showFeedDetail(EnergieFeedEntry feed) {
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
                        color: const Color(0xFF9C27B0).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF9C27B0)),
                      ),
                      child: Text(
                        feed.quellenTypLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9C27B0),
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
                    
                    // Quelle & Details
                    _buildDetailRow('Quelle', feed.quelle),
                    _buildDetailRow('Spirit-Thema', feed.spiritThema),
                    
                    if (feed.symbolSchwerpunkte.isNotEmpty)
                      _buildDetailRow('Symbole', feed.symbolSchwerpunkte.join(', ')),
                    
                    if (feed.archetypen.isNotEmpty)
                      _buildDetailRow('Archetypen', feed.archetypen.join(', ')),
                    
                    const SizedBox(height: 24),
                    
                    const Text(
                      'Symbolische Einordnung',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      feed.symbolischeEinordnung,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.6,
                      ),
                    ),
                    
                    if (feed.reflexionsfragen.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Reflexionsfragen',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...feed.reflexionsfragen.map((frage) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '• ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF9C27B0),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  frage,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Quelle öffnen Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Quelle öffnen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9C27B0),
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
            width: 120,
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
      case 'text': return Icons.description;
      case 'essay': return Icons.menu_book;
      case 'übersetzung': return Icons.translate;
      case 'lexikon': return Icons.library_books;
      default: return Icons.auto_awesome;
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
      themes.add(feed.spiritThema);
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
  List<Widget> _buildReadingTimeBadge(EnergieFeedEntry feed) {
    // Berechne Lesezeit aus symbolischer Einordnung + Reflexionsfragen
    final text = '${feed.symbolischeEinordnung} ${feed.reflexionsfragen.join(' ')}';
    final info = _readingService.calculateReadingInfo(feed.feedId, text);
    
    // Hole Fortschritt falls vorhanden
    final progress = _readingService.getProgress(feed.feedId);
    
    return [
      Icon(
        Icons.menu_book,
        size: 14,
        color: progress != null && progress.progressPercent > 0
            ? const Color(0xFF9C27B0)
            : Colors.grey[600],
      ),
      const SizedBox(width: 4),
      Text(
        '${info.estimatedMinutes} Min',
        style: TextStyle(
          fontSize: 12,
          color: progress != null && progress.progressPercent > 0
              ? const Color(0xFF9C27B0)
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
            color: const Color(0xFF9C27B0).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${progress.progressPercent.toInt()}%',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF9C27B0),
            ),
          ),
        ),
      ],
    ];
  }
  
  /// 🏆 Achievement Tracking: Like
  Future<void> _trackLikeAchievement() async {
    try {
      await AchievementService().incrementProgress('first_like');
      await AchievementService().incrementProgress('community_champion');
      
      // 🎯 Daily Challenge Tracking
      await DailyChallengesService().incrementProgress(
        ChallengeCategory.community,
        amount: 1,
      );
    } catch (e) {
      debugPrint('⚠️ Achievement tracking error: $e');
    }
  }
  
  /// 🏆 Achievement Tracking: Comment
  Future<void> _trackCommentAchievement() async {
    try {
      await AchievementService().incrementProgress('first_comment');
      
      // 🎯 Daily Challenge Tracking
      await DailyChallengesService().incrementProgress(
        ChallengeCategory.community,
        amount: 1,
      );
    } catch (e) {
      debugPrint('⚠️ Achievement tracking error: $e');
    }
  }
}
