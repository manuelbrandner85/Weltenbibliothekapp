import 'package:flutter/material.dart';
import '../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../../models/community_post.dart';
import '../../services/community_service.dart'; // 🌐 ECHTE API
import '../../widgets/create_post_dialog_v2.dart'; // ✅ POST-DIALOG
import '../../widgets/loading_skeletons.dart'; // 💀 LOADING SKELETONS
import '../../widgets/article_like_button.dart'; // 👍 NEW: Like Button
import '../../widgets/article_comments_widget.dart'; // 💬 NEW: Comments Widget
import 'materie_live_chat_screen.dart'; // 💬 LIVE-CHAT INTEGRATION
import '../../services/chat_notification_service.dart'; // 🔔 NOTIFICATION SERVICE

/// Modernes Community-Tab für MATERIE-Welt - Social-Media-Style
class MaterieCommunityTabModern extends StatefulWidget {
  const MaterieCommunityTabModern({super.key});

  @override
  State<MaterieCommunityTabModern> createState() => _MaterieCommunityTabModernState();
}

class _MaterieCommunityTabModernState extends State<MaterieCommunityTabModern> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String? _errorMessage; // ✅ FIX #7: Error state
  String _selectedView = 'all'; // ✅ FIX #8: View state variable
  
  // 💬 TAB CONTROLLER für Posts vs Chat
  late TabController _tabController;
  final ChatNotificationService _notificationService = ChatNotificationService();
  final CommunityService _communityService = CommunityService(); // 🌐 ECHTE API
  
  // 🌐 ECHTE Community-Posts von Cloudflare API
  List<CommunityPost> _posts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // ✅ Listener für Tab-Wechsel (FAB nur in Posts-Tab zeigen)
    _tabController.addListener(() {
      setState(() {}); // Rebuild für FAB Visibility
    });
    
    if (kDebugMode) {
      debugPrint('🔵 MATERIE Community Tab Modern mit Chat initialisiert');
    }
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 🌐 Lade echte Community-Posts von Cloudflare API
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final posts = await _communityService.fetchPosts(worldType: WorldType.materie);
      
      if (kDebugMode) {
        debugPrint('🔵 MATERIE Community (AKTIV): ${posts.length} posts loaded');
      }
      
      setState(() {
        _posts = posts;
        _errorMessage = null; // ✅ FIX #7: Clear error
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔵 MATERIE Community (AKTIV): Error loading posts: $e');
      }
      
      setState(() {
        _isLoading = false;
        _errorMessage = 'Fehler beim Laden der Posts. Bitte erneut versuchen.'; // ✅ FIX #7
      });
    }
  }
  
  /// ✅ Zeige Post-Erstellungs-Dialog
  Future<void> _showCreatePostDialogV2() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const CreatePostDialogV2(worldType: WorldType.materie),
    );
    
    if (result == true) {
      _loadData(); // Reload nach erfolgreicher Erstellung
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
        // 💬 TAB BAR: Posts vs Live Chat
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0D47A1).withValues(alpha: 0.2),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF2196F3),
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            tabs: [
              const Tab(
                icon: Icon(Icons.article),
                text: 'Posts',
              ),
              Tab(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.chat_bubble),
                    // 🔔 UNREAD BADGE
                    Positioned(
                      right: -6,
                      top: -6,
                      child: ListenableBuilder(
                        listenable: _notificationService,
                        builder: (context, _) {
                          final count = _notificationService.getTotalUnreadCount();
                          if (count == 0) return const SizedBox.shrink();
                          
                          return Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Center(
                              child: Text(
                                count > 9 ? '9+' : count.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                text: 'Live Chat',
              ),
            ],
          ),
        ),
        
        // 💬 TAB VIEW: Posts oder Chat
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // TAB 1: Community Posts (Original)
              _buildPostsView(),
              
              // TAB 2: Live Chat (ACTIVATED!)
              const MaterieLiveChatScreen(),
            ],
          ),
        ),
      ],
      ),
      // ✅ Post-Button NUR im Posts-Tab anzeigen (nicht im Chat)
      floatingActionButton: _tabController.index == 0
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: _showCreatePostDialogV2,
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: const Icon(Icons.edit, color: Colors.white, size: 24),
                label: const Text(
                  'Post erstellen',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          : null, // Kein Button im Chat-Tab
    );
  }
  
  // Original Posts View
  Widget _buildPostsView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0D47A1).withValues(alpha: 0.05),
            Colors.black,
          ],
        ),
      ),
      child: CustomScrollView(
        slivers: [
          // Header mit View-Tabs
          SliverToBoxAdapter(
            child: _buildHeader(),
          ),
          
          // Trending-Sektion
          if (_selectedView == 'trending')
            SliverToBoxAdapter(
              child: _buildTrendingSection(),
            ),
          
          // Community-Posts
          _isLoading
              ? SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => LoadingSkeletons.postCard(),
                      childCount: 3, // Show 3 skeleton posts
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildPostCard(_posts[index]),
                      childCount: _posts.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titel
          const Text(
            'Community',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Teile deine Recherchen und Erkenntnisse',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),
          
          // View-Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildViewTab('trending', '🔥 Trending', Colors.orange),
                const SizedBox(width: 12),
                _buildViewTab('following', '👥 Following', Colors.blue),
                const SizedBox(width: 12),
                _buildViewTab('community', '💬 Alle Posts', Colors.purple),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewTab(String view, String label, Color color) {
    final isSelected = _selectedView == view;
    return GestureDetector(
      onTap: () => setState(() => _selectedView = view),
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

  Widget _buildTrendingSection() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withValues(alpha: 0.15),
            Colors.deepOrange.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '🔥',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              const Text(
                'Trending Topics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTrendingTag('Geopolitik', 347),
              _buildTrendingTag('WikiLeaks', 234),
              _buildTrendingTag('CERN', 189),
              _buildTrendingTag('Transparenz', 156),
              _buildTrendingTag('Kaninchenbau', 142),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingTag(String tag, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$tag',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              color: Colors.orange.withValues(alpha: 0.8, red: 1.0, green: 0.6, blue: 0.2),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header mit Avatar und Username
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade700,
                        Colors.purple.shade700,
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      post.authorAvatar ?? '👤',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Username und Zeit
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorUsername,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatTimestamp(post.createdAt),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // More-Button
                IconButton(
                  icon: Icon(
                    Icons.more_horiz,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  onPressed: () {
                    // TODO: Implementiere Post-Optionen (Teilen, Melden, etc.)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Post-Optionen coming soon'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              post.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Tags
          if (post.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: post.tags.map((tag) => _buildPostTag(tag)).toList(),
              ),
            ),
          const SizedBox(height: 16),
          
          // Image-Placeholder (wenn hasImage true)
          if (post.hasImage == true)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withValues(alpha: 0.3),
                    Colors.purple.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.image,
                  size: 48,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
          const SizedBox(height: 16),
          
          // 🆕 NEW: Interactive Engagement Widgets
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ArticleLikeButton(
                  articleId: post.id,
                  initialLikes: post.likes,
                  initiallyLiked: false, // TODO: Check if user already liked
                ),
                const SizedBox(width: 20),
                ArticleCommentsWidget(
                  articleId: post.id,
                  initialCommentCount: post.comments,
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    // TODO: Implement share
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('🚀 Share-Funktion coming soon')),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.share_outlined,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.shares ?? 0}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPostTag(String tag) {
    // Farbe basierend auf Tag
    Color tagColor = Colors.blue;
    if (tag.contains('Geopolitik')) {
      tagColor = Colors.green;
    } else if (tag.contains('Geschichte') || tag.contains('Dokumente')) {
      tagColor = Colors.orange;
    } else if (tag.contains('Machtstrukturen') || tag.contains('Recherche')) {
      tagColor = Colors.purple;
    } else if (tag.contains('Transparenz') || tag.contains('WikiLeaks')) {
      tagColor = Colors.yellow;
    } else if (tag.contains('CERN') || tag.contains('Physik')) {
      tagColor = Colors.cyan;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tagColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tagColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        '#$tag',
        style: TextStyle(
          color: tagColor.withValues(alpha: 0.9),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEngagementStat(IconData icon, int count, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: color.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        Text(
          _formatNumber(count),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return InkWell(
      onTap: () {
        // TODO: Implementiere Community-Actions (Like, Comment, Share)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label Funktion coming soon'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return 'vor ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'vor ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'vor ${difference.inDays}d';
    } else {
      return 'vor ${(difference.inDays / 7).floor()}w';
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}
