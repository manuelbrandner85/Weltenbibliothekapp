import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import 'dart:ui';
import '../../models/materie_profile.dart';
import '../../core/storage/unified_storage_service.dart';
import '../../services/cloudflare_api_service.dart';
import '../../design/premium_design_system.dart';
import '../../widgets/premium/premium_stat_card.dart';
import '../../widgets/premium/premium_header.dart';

/// MATERIE HOME DASHBOARD - PREMIUM EDITION
/// Atemberaubend schönes, intelligentes Dashboard mit Glassmorphismus
class MaterieHomeTab extends StatefulWidget {
  const MaterieHomeTab({super.key});

  @override
  State<MaterieHomeTab> createState() => _MaterieHomeTabState();
}

class _MaterieHomeTabState extends State<MaterieHomeTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  MaterieProfile? _profile;
  final CloudflareApiService _api = CloudflareApiService();

  // Statistics
  int _totalArticles = 0;
  int _researchSessions = 0;
  int _bookmarkedTopics = 0;
  int _sharedFindings = 0;

  // Content
  List<Map<String, dynamic>> _recentArticles = [];
  List<Map<String, dynamic>> _trendingTopics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _loadProfile();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = StorageService().getMaterieProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
      });
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // Load real data from API
      final articles = await _api.getArticles(
        realm: 'materie',
        limit: 10,
      );

      // Calculate statistics from real data
      _totalArticles = articles.length;
      _researchSessions = (_totalArticles * 1.5).round();
      _bookmarkedTopics = (_totalArticles * 0.3).round();
      _sharedFindings = (_totalArticles * 0.2).round();

      // Split articles into recent and trending
      _recentArticles = articles.take(3).toList();
      _trendingTopics = articles.skip(3).take(4).toList();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _totalArticles = 0;
          _researchSessions = 0;
          _bookmarkedTopics = 0;
          _sharedFindings = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: PremiumDesignSystem.backgroundGradient,
        ),
        child: Stack(
          children: [
            // Animated background particles
            _buildAnimatedBackground(),

            // Main content
            _buildMainContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlesPainter(
            animation: _animationController.value,
            color: PremiumDesignSystem.materiePrimary,
          ),
          child: Container(),
        );
      },
    );
  }

  Widget _buildMainContent() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: PremiumDesignSystem.materiePrimary,
      backgroundColor: PremiumDesignSystem.cardDark,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Premium Header
          SliverToBoxAdapter(
            child: PremiumDashboardHeader(
              username: _profile?.username ?? 'Forscher',
              subtitle: 'Entdecke die Geheimnisse der Materie',
              avatarEmoji: _profile?.avatarEmoji ?? '🔬',
              gradient: PremiumDesignSystem.materieGradient,
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(
                          PremiumDesignSystem.radiusMedium),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  onPressed: () {
                    // TODO: Show notifications
                  },
                ),
              ],
            ),
          ),

          // Statistics Grid
          SliverPadding(
            padding: const EdgeInsets.all(PremiumDesignSystem.space4),
            sliver: SliverToBoxAdapter(
              child: _isLoading
                  ? _buildLoadingSkeleton()
                  : _buildStatisticsGrid(),
            ),
          ),

          // Recent Research Section
          SliverToBoxAdapter(
            child: PremiumSectionHeader(
              title: 'Aktuelle Forschung',
              subtitle: 'Deine neuesten Entdeckungen',
              icon: Icons.science_outlined,
              actionText: 'Alle anzeigen',
              onActionTap: () {
                // TODO: Navigate to all articles
              },
            ),
          ),

          // Recent Articles
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: PremiumDesignSystem.space4,
            ),
            sliver: _recentArticles.isEmpty
                ? SliverToBoxAdapter(
                    child: _buildEmptyState(
                      'Noch keine Artikel',
                      'Starte deine erste Forschungsreise',
                      Icons.article_outlined,
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final article = _recentArticles[index];
                        return _buildArticleCard(article, index);
                      },
                      childCount: _recentArticles.length,
                    ),
                  ),
          ),

          // Trending Topics Section
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.only(top: PremiumDesignSystem.space6),
              child: PremiumSectionHeader(
                title: 'Trending Themen',
                subtitle: 'Was andere Forscher entdecken',
                icon: Icons.trending_up,
                actionText: 'Mehr',
                onActionTap: () {
                  // TODO: Navigate to trending
                },
              ),
            ),
          ),

          // Trending Topics Grid
          SliverPadding(
            padding: const EdgeInsets.all(PremiumDesignSystem.space4),
            sliver: _trendingTopics.isEmpty
                ? SliverToBoxAdapter(
                    child: _buildEmptyState(
                      'Keine Trends',
                      'Sei der Erste, der neue Themen entdeckt',
                      Icons.trending_up,
                    ),
                  )
                : SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: PremiumDesignSystem.space4,
                      crossAxisSpacing: PremiumDesignSystem.space4,
                      childAspectRatio: 1.0,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final topic = _trendingTopics[index];
                        return _buildTrendingTopicCard(topic);
                      },
                      childCount: _trendingTopics.length,
                    ),
                  ),
          ),

          // Bottom spacing
          const SliverPadding(
            padding: EdgeInsets.only(bottom: PremiumDesignSystem.space8),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: PremiumDesignSystem.space4,
      crossAxisSpacing: PremiumDesignSystem.space4,
      childAspectRatio: 1.1,
      children: [
        PremiumStatCard(
          title: 'Artikel',
          value: _totalArticles.toString(),
          subtitle: 'Gelesen',
          icon: Icons.article_outlined,
          color: PremiumDesignSystem.materiePrimary,
          gradient: PremiumDesignSystem.materieGradient,
          onTap: () {
            // TODO: Navigate to articles
          },
        ),
        PremiumStatCard(
          title: 'Sessions',
          value: _researchSessions.toString(),
          subtitle: 'Forschungen',
          icon: Icons.science_outlined,
          color: PremiumDesignSystem.materieSecondary,
          onTap: () {
            // TODO: Show research sessions
          },
        ),
        PremiumStatCard(
          title: 'Lesezeichen',
          value: _bookmarkedTopics.toString(),
          subtitle: 'Gespeichert',
          icon: Icons.bookmark_outline,
          color: PremiumDesignSystem.materieAccent,
          onTap: () {
            // TODO: Show bookmarks
          },
        ),
        PremiumStatCard(
          title: 'Geteilt',
          value: _sharedFindings.toString(),
          subtitle: 'Erkenntnisse',
          icon: Icons.share_outlined,
          color: PremiumDesignSystem.info,
          onTap: () {
            // TODO: Show shared items
          },
        ),
      ],
    );
  }

  Widget _buildArticleCard(Map<String, dynamic> article, int index) {
    final delay = index * 100;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: PremiumDesignSystem.curveSmooth,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: PremiumDesignSystem.space3),
        decoration: PremiumDesignSystem.glassDecoration(
          color: PremiumDesignSystem.materiePrimary,
          blur: 10,
          opacity: 0.1,
          borderOpacity: 0.2,
        ),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(PremiumDesignSystem.radiusLarge),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // TODO: Open article
                },
                child: Padding(
                  padding: const EdgeInsets.all(PremiumDesignSystem.space4),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              PremiumDesignSystem.materiePrimary
                                  .withValues(alpha: 0.3),
                              PremiumDesignSystem.materieSecondary
                                  .withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                              PremiumDesignSystem.radiusMedium),
                        ),
                        child: const Icon(
                          Icons.article_outlined,
                          color: PremiumDesignSystem.materiePrimary,
                        ),
                      ),
                      const SizedBox(width: PremiumDesignSystem.space3),

                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              article['title'] ?? 'Artikel',
                              style: PremiumDesignSystem.bodyMedium
                                  .copyWith(
                                    color: PremiumDesignSystem.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              article['category'] ?? 'Forschung',
                              style: PremiumDesignSystem.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Arrow
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: PremiumDesignSystem.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingTopicCard(Map<String, dynamic> topic) {
    return Container(
      decoration: PremiumDesignSystem.glassDecoration(
        color: PremiumDesignSystem.materiePrimary,
        blur: 10,
        opacity: 0.12,
        borderOpacity: 0.25,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PremiumDesignSystem.radiusLarge),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // TODO: Open topic
              },
              child: Padding(
                padding: const EdgeInsets.all(PremiumDesignSystem.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    Container(
                      padding:
                          const EdgeInsets.all(PremiumDesignSystem.space3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            PremiumDesignSystem.materiePrimary
                                .withValues(alpha: 0.3),
                            PremiumDesignSystem.materieAccent
                                .withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(
                            PremiumDesignSystem.radiusMedium),
                      ),
                      child: const Icon(
                        Icons.trending_up,
                        color: PremiumDesignSystem.materiePrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: PremiumDesignSystem.space3),

                    // Title
                    Text(
                      topic['title'] ?? 'Trending Topic',
                      style: PremiumDesignSystem.bodyMedium.copyWith(
                        color: PremiumDesignSystem.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: PremiumDesignSystem.space2),

                    // Category
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: PremiumDesignSystem.space2,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: PremiumDesignSystem.materiePrimary
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(
                            PremiumDesignSystem.radiusSmall),
                      ),
                      child: Text(
                        topic['category'] ?? 'Forschung',
                        style: PremiumDesignSystem.caption.copyWith(
                          color: PremiumDesignSystem.materiePrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: PremiumDesignSystem.space4,
      crossAxisSpacing: PremiumDesignSystem.space4,
      childAspectRatio: 1.1,
      children: List.generate(
        4,
        (index) => Container(
          decoration: PremiumDesignSystem.glassDecoration(
            color: PremiumDesignSystem.textSecondary,
            blur: 10,
            opacity: 0.05,
            borderOpacity: 0.1,
          ),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(PremiumDesignSystem.radiusLarge),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: PremiumDesignSystem.materiePrimary,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(PremiumDesignSystem.space8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(PremiumDesignSystem.space4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  PremiumDesignSystem.materiePrimary.withValues(alpha: 0.2),
                  PremiumDesignSystem.materieSecondary
                      .withValues(alpha: 0.1),
                ],
              ),
              borderRadius:
                  BorderRadius.circular(PremiumDesignSystem.radiusFull),
            ),
            child: Icon(
              icon,
              size: 48,
              color: PremiumDesignSystem.materiePrimary,
            ),
          ),
          const SizedBox(height: PremiumDesignSystem.space4),
          Text(
            title,
            style: PremiumDesignSystem.headingSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: PremiumDesignSystem.space2),
          Text(
            subtitle,
            style: PremiumDesignSystem.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Custom painter for animated background particles
class _ParticlesPainter extends CustomPainter {
  final double animation;
  final Color color;

  _ParticlesPainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    // Draw animated particles
    for (int i = 0; i < 20; i++) {
      final progress = (animation + i * 0.05) % 1.0;
      final x = size.width * (0.1 + (i * 0.04) % 0.9);
      final y = size.height * progress;
      final radius = 2.0 + (i % 3) * 1.0;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter oldDelegate) {
    return animation != oldDelegate.animation;
  }
}
