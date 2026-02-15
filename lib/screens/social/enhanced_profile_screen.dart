import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../services/cloudflare_api_service.dart';
import '../../core/storage/unified_storage_service.dart';

/// 👤 Enhanced User Profile Screen
/// Features:
/// - User avatar & banner
/// - Bio & stats
/// - Follow/Unfollow system
/// - Activity feed
/// - Content collections
class EnhancedProfileScreen extends StatefulWidget {
  final String userId;
  final bool isOwnProfile;
  
  const EnhancedProfileScreen({
    Key? key,
    required this.userId,
    this.isOwnProfile = false,
  }) : super(key: key);

  @override
  State<EnhancedProfileScreen> createState() => _EnhancedProfileScreenState();
}

class _EnhancedProfileScreenState extends State<EnhancedProfileScreen> with SingleTickerProviderStateMixin {
  final CloudflareApiService _api = CloudflareApiService();
  final UnifiedStorageService _storage = UnifiedStorageService();
  
  late TabController _tabController;
  
  bool _isLoading = true;
  bool _isFollowing = false;
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _collections = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    try {
      // Load user profile
      _profileData = await _api.getUserProfile(widget.userId);
      
      // Load user stats
      _stats = await _api.getUserStats(widget.userId);
      
      // Load activity feed
      _activities = await _api.getUserActivity(widget.userId, limit: 20);
      
      // Load collections
      _collections = await _api.getUserCollections(widget.userId);
      
      // Check follow status
      if (!widget.isOwnProfile) {
        final currentUserId = _storage.getCurrentUserId();
        _isFollowing = await _api.isFollowing(currentUserId, widget.userId);
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading profile: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _toggleFollow() async {
    final currentUserId = _storage.getCurrentUserId();
    
    setState(() => _isFollowing = !_isFollowing);
    
    try {
      if (_isFollowing) {
        await _api.followUser(currentUserId, widget.userId);
        _showSnackBar('✅ Du folgst jetzt diesem Nutzer', Colors.green);
      } else {
        await _api.unfollowUser(currentUserId, widget.userId);
        _showSnackBar('❌ Du folgst diesem Nutzer nicht mehr', Colors.orange);
      }
    } catch (e) {
      setState(() => _isFollowing = !_isFollowing);
      _showSnackBar('❌ Fehler beim Aktualisieren', Colors.red);
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
        appBar: AppBar(title: const Text('Profil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    final username = _profileData?['username'] ?? 'Unbekannt';
    final bio = _profileData?['bio'] ?? '';
    final avatarUrl = _profileData?['avatar_url'];
    final bannerUrl = _profileData?['banner_url'];
    
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Banner image
                    if (bannerUrl != null)
                      Image.network(
                        bannerUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _defaultBanner(),
                      )
                    else
                      _defaultBanner(),
                    
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    
                    // Avatar & basic info
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            child: avatarUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      avatarUrl,
                                      width: 76,
                                      height: 76,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _defaultAvatar(),
                                    ),
                                  )
                                : _defaultAvatar(),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Username & stats
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  username,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _statChip('${_stats?['posts'] ?? 0}', 'Beiträge'),
                                    const SizedBox(width: 12),
                                    _statChip('${_stats?['followers'] ?? 0}', 'Follower'),
                                    const SizedBox(width: 12),
                                    _statChip('${_stats?['following'] ?? 0}', 'Folgt'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // Bio & Follow button
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (bio.isNotEmpty)
                    Text(
                      bio,
                      style: const TextStyle(fontSize: 16),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Follow button (if not own profile)
                  if (!widget.isOwnProfile)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _toggleFollow,
                        icon: Icon(_isFollowing ? Icons.person_remove : Icons.person_add),
                        label: Text(_isFollowing ? 'Nicht mehr folgen' : 'Folgen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFollowing ? Colors.grey : Colors.blue,
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Navigate to edit profile
                          Navigator.pushNamed(context, '/profile_settings');
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Profil bearbeiten'),
                      ),
                    ),
                ],
              ),
            ),
            
            // Tabs
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.grid_on), text: 'Beiträge'),
                Tab(icon: Icon(Icons.timeline), text: 'Aktivität'),
                Tab(icon: Icon(Icons.collections_bookmark), text: 'Sammlungen'),
              ],
            ),
            
            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPostsTab(),
                  _buildActivityTab(),
                  _buildCollectionsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _defaultBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.purple[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
  
  Widget _defaultAvatar() {
    return Icon(Icons.person, size: 40, color: Colors.grey[400]);
  }
  
  Widget _statChip(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPostsTab() {
    // Grid of user's posts
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: _stats?['posts'] ?? 0,
      itemBuilder: (context, index) {
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              // Navigate to post detail
            },
            child: Container(
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.article, size: 40, color: Colors.grey),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildActivityTab() {
    if (_activities.isEmpty) {
      return const Center(
        child: Text('Noch keine Aktivitäten'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        final activity = _activities[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(_getActivityIcon(activity['type'])),
            title: Text(activity['description'] ?? ''),
            subtitle: Text(_formatTimestamp(activity['timestamp'])),
          ),
        );
      },
    );
  }
  
  Widget _buildCollectionsTab() {
    if (_collections.isEmpty) {
      return const Center(
        child: Text('Noch keine Sammlungen'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _collections.length,
      itemBuilder: (context, index) {
        final collection = _collections[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.collections_bookmark),
            title: Text(collection['name'] ?? ''),
            subtitle: Text('${collection['item_count'] ?? 0} Einträge'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to collection detail
            },
          ),
        );
      },
    );
  }
  
  IconData _getActivityIcon(String? type) {
    switch (type) {
      case 'post':
        return Icons.article;
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'follow':
        return Icons.person_add;
      default:
        return Icons.timeline;
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
}
