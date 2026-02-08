import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../../models/community_post.dart';
import '../../services/community_service.dart'; // ✅ Cloudflare API
import '../../widgets/create_post_dialog_v2.dart'; // ✅ Post-Dialog
import '../../widgets/post_actions_row.dart'; // ✅ POST ACTIONS
import 'materie_live_chat_screen.dart'; // 💬 LIVE-CHAT INTEGRATION
import '../../services/chat_notification_service.dart'; // 🔔 NOTIFICATION SERVICE

/// Moderner Materie-Community-Tab - Spiritueller Feed-Style
class MaterieCommunityTabModern extends StatefulWidget {
  const MaterieCommunityTabModern({super.key});

  @override
  State<MaterieCommunityTabModern> createState() => _MaterieCommunityTabModernState();
}

class _MaterieCommunityTabModernState extends State<MaterieCommunityTabModern> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _selectedView = 'trending'; // 'trending', 'sacred', 'experiences'
  
  // 💬 TAB CONTROLLER für Posts vs Chat
  late TabController _tabController;
  final ChatNotificationService _notificationService = ChatNotificationService();
  final CommunityService _communityService = CommunityService();
  
  // ✅ Echte Posts von Cloudflare API
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
      debugPrint('🟣 ENERGIE Community Tab Modern mit Chat initialisiert');
    }
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final posts = await _communityService.fetchPosts(
        worldType: WorldType.materie,
      );
      if (kDebugMode) {
        debugPrint('🟣 ENERGIE: Geladene Posts: ${posts.length}');
      }
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🟣 ENERGIE: Fehler beim Laden: $e');
      }
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Fehler: $e')),
        );
      }
    }
  }
  
  Future<void> _showCreatePostDialogV2() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CreatePostDialogV2(
        worldType: WorldType.materie,
      ),
    );
    if (result == true) {
      _loadData(); // ✅ Reload posts after success
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                const Color(0xFF4A148C).withValues(alpha: 0.2),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF9C27B0),
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
              
              // TAB 2: Live Chat (NEU!)
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
                  colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9C27B0).withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: _showCreatePostDialogV2, // ✅ FIXED: Use correct method name
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
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
            const Color(0xFF4A148C).withValues(alpha: 0.05),
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
          
          // Trending Materie-Tags
          if (_selectedView == 'trending')
            SliverToBoxAdapter(
              child: _buildTrendingSection(),
            ),
          
          // Community-Posts
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : _posts.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.forum_outlined, size: 64, color: Colors.white.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'Noch keine Posts vorhanden',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sei der Erste und erstelle einen Post!',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                          ),
                        ],
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
          Row(
            children: [
              const Text(
                '🌟',
                style: TextStyle(fontSize: 36),
              ),
              const SizedBox(width: 12),
              const Text(
                'Spirituelle Community',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Teile deine Erfahrungen und Erkenntnisse',
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
                _buildViewTab('sacred', '🕉️ Heilig', Colors.purple),
                const SizedBox(width: 12),
                _buildViewTab('experiences', '✨ Erfahrungen', Colors.pink),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '✨',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              const Text(
                'Spirituelle Themen',
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
              _buildTrendingTag('Kraftorte', 234, Colors.green),
              _buildTrendingTag('Meditation', 189, Colors.purple),
              _buildTrendingTag('Chakren', 167, Colors.pink),
              _buildTrendingTag('Kristalle', 143, Colors.cyan),
              _buildTrendingTag('Vollmond', 128, Colors.yellow),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingTag(String tag, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
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
              color: color.withValues(alpha: 0.9),
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
            Colors.purple.withValues(alpha: 0.08),
            Colors.pink.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.1),
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
                // Avatar mit mystischem Glow
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.purple.withValues(alpha: 0.6),
                        Colors.pink.withValues(alpha: 0.3),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.purple.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      post.authorAvatar ?? '🌟',
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
                      Row(
                        children: [
                          Text(
                            post.authorUsername,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple.withValues(alpha: 0.4),
                                  Colors.pink.withValues(alpha: 0.4),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '⚡ Materie',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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
                
                // More-Button (3-Punkte-Menü)
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  onPressed: () => _showPostMenu(context, post),
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
          
          // Media Display (Image or Video)
          if (post.mediaUrl != null && post.mediaUrl!.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.purple.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  post.mediaUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      color: Colors.purple.withValues(alpha: 0.1),
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.purple,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.withValues(alpha: 0.3),
                            Colors.pink.withValues(alpha: 0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 48,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bild konnte nicht geladen werden',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 16),
          
          // Post Actions (Like, Comment, Share, Materie, Save)
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.purple.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: PostActionsRow(
              post: post,
              accentColor: Colors.purple,
              onPostUpdated: _loadData,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostTag(String tag) {
    // Farbe basierend auf Tag
    Color tagColor = Colors.purple;
    if (tag.contains('Kraftorte') || tag.contains('Erdmaterie')) {
      tagColor = Colors.green;
    } else if (tag.contains('Chakren') || tag.contains('Materie')) {
      tagColor = Colors.pink;
    } else if (tag.contains('Meditation') || tag.contains('Yoga')) {
      tagColor = Colors.blue;
    } else if (tag.contains('Kristalle') || tag.contains('Heilsteine')) {
      tagColor = Colors.cyan;
    } else if (tag.contains('Vollmond') || tag.contains('Ritual')) {
      tagColor = Colors.yellow;
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

  // 3-Punkte-Menü für Posts
  void _showPostMenu(BuildContext context, CommunityPost post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.report_outlined, color: Colors.orange),
                title: const Text('Melden', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ Post gemeldet'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.block_outlined, color: Colors.red),
                title: const Text('Autor blockieren', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🚫 ${post.authorUsername} blockiert'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.link_outlined, color: Colors.blue),
                title: const Text('Link kopieren', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔗 Link kopiert'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // TODO: Review unused method: _buildEngagementStat
  // Widget _buildEngagementStat(IconData icon, int count, Color color) {
    // return Row(
      // children: [
        // Icon(
          // icon,
          // size: 18,
          // color: color.withValues(alpha: 0.7),
        // ),
        // const SizedBox(width: 4),
        // Text(
          // _formatNumber(count),
          // style: TextStyle(
            // color: Colors.white.withValues(alpha: 0.7),
            // fontSize: 13,
            // fontWeight: FontWeight.w500,
          // ),
        // ),
      // ],
    // );
  // }

  // TODO: Review unused method: _buildActionButton
  // Widget _buildActionButton(IconData icon, String label, Color color) {
    // return InkWell(
      // onTap: () {
        // TODO: Implementiere Community-Actions (Like, Comment, Share)
        // ScaffoldMessenger.of(context).showSnackBar(
          // SnackBar(
            // content: Text('$label Funktion coming soon'),
            // duration: const Duration(seconds: 2),
          // ),
        // );
      // },
      // child: Padding(
        // padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        // child: Row(
          // children: [
            // Icon(
              // icon,
              // size: 20,
              // color: Colors.white.withValues(alpha: 0.7),
            // ),
            // const SizedBox(width: 6),
            // Text(
              // label,
              // style: TextStyle(
                // color: Colors.white.withValues(alpha: 0.7),
                // fontSize: 13,
                // fontWeight: FontWeight.w500,
              // ),
            // ),
          // ],
        // ),
      // ),
    // );
  // }

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

  // TODO: Review unused method: _formatNumber
  // String _formatNumber(int number) {
    // if (number >= 1000) {
      // return '${(number / 1000).toStringAsFixed(1)}k';
    // }
    // return number.toString();
  // }
}
