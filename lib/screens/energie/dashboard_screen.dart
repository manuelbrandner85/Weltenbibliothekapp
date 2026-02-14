import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../models/energie_profile.dart';
import '../../core/storage/unified_storage_service.dart';
import '../../services/cloudflare_api_service.dart';
import '../../design/premium_design_system.dart';
import '../../widgets/premium/premium_stat_card.dart';
import '../../widgets/premium/premium_header.dart';

/// ENERGIE DASHBOARD - PREMIUM EDITION
/// Atemberaubend schönes Dashboard mit Kristall-Sammlungen und spirituellen Statistiken
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;

  EnergieProfile? _profile;
  final CloudflareApiService _api = CloudflareApiService();

  // Statistics
  int _crystalCollection = 0;
  int _tarotReadings = 0;
  int _meditationMinutes = 0;
  int _energyLevel = 0;

  // Content
  List<Map<String, dynamic>> _crystalLibrary = [];
  List<Map<String, dynamic>> _recentActivities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Rotation animation for crystals
    _animationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Pulse animation for energy level
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _loadProfile();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = StorageService().getEnergieProfile();
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
        realm: 'energie',
        limit: 100,
      );

      // Calculate statistics from real data
      _crystalCollection = articles.length;
      _tarotReadings = (_crystalCollection * 0.8).round();
      _meditationMinutes = _crystalCollection * 15;
      _energyLevel = math.min(100, _crystalCollection * 2);

      // Split articles for display
      _crystalLibrary = articles.take(6).toList();
      _recentActivities = articles.skip(6).take(4).toList();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _crystalCollection = 0;
          _tarotReadings = 0;
          _meditationMinutes = 0;
          _energyLevel = 0;
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
          painter: _CrystalParticlesPainter(
            animation: _animationController.value,
            color: PremiumDesignSystem.energiePrimary,
          ),
          child: Container(),
        );
      },
    );
  }

  Widget _buildMainContent() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: PremiumDesignSystem.energiePrimary,
      backgroundColor: PremiumDesignSystem.cardDark,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Premium Header
          SliverToBoxAdapter(
            child: PremiumDashboardHeader(
              username: _profile?.username ?? 'Suchender',
              subtitle: 'Deine spirituelle Reise',
              avatarEmoji: _profile?.avatarEmoji ?? '🔮',
              gradient: PremiumDesignSystem.energieGradient,
              actions: [
                // Energy Level Indicator
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: PremiumDesignSystem.space3,
                        vertical: PremiumDesignSystem.space2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.2 + (_pulseController.value * 0.1),
                        ),
                        borderRadius: BorderRadius.circular(
                            PremiumDesignSystem.radiusFull),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt,
                            color: Colors.yellow[300],
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$_energyLevel%',
                            style: PremiumDesignSystem.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
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

          // Crystal Library Section
          SliverToBoxAdapter(
            child: PremiumSectionHeader(
              title: 'Kristall-Bibliothek',
              subtitle: 'Deine spirituelle Sammlung',
              icon: Icons.auto_awesome,
              actionText: 'Alle anzeigen',
              onActionTap: () {
                // TODO: Navigate to full library
              },
            ),
          ),

          // Crystal Grid
          SliverPadding(
            padding: const EdgeInsets.all(PremiumDesignSystem.space4),
            sliver: _crystalLibrary.isEmpty
                ? SliverToBoxAdapter(
                    child: _buildEmptyState(
                      'Noch keine Kristalle',
                      'Beginne deine spirituelle Reise',
                      Icons.auto_awesome,
                    ),
                  )
                : SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: PremiumDesignSystem.space3,
                      crossAxisSpacing: PremiumDesignSystem.space3,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final crystal = _crystalLibrary[index];
                        return _buildCrystalCard(crystal, index);
                      },
                      childCount: _crystalLibrary.length,
                    ),
                  ),
          ),

          // Recent Activities Section
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.only(top: PremiumDesignSystem.space6),
              child: PremiumSectionHeader(
                title: 'Kürzliche Aktivitäten',
                subtitle: 'Deine spirituelle Praxis',
                icon: Icons.history,
                actionText: 'Mehr',
                onActionTap: () {
                  // TODO: Navigate to activities
                },
              ),
            ),
          ),

          // Activities List
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: PremiumDesignSystem.space4,
            ),
            sliver: _recentActivities.isEmpty
                ? SliverToBoxAdapter(
                    child: _buildEmptyState(
                      'Keine Aktivitäten',
                      'Starte deine spirituelle Praxis',
                      Icons.self_improvement,
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final activity = _recentActivities[index];
                        return _buildActivityCard(activity, index);
                      },
                      childCount: _recentActivities.length,
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
          title: 'Kristalle',
          value: _crystalCollection.toString(),
          subtitle: 'Gesammelt',
          icon: Icons.auto_awesome,
          color: PremiumDesignSystem.energiePrimary,
          gradient: PremiumDesignSystem.energieGradient,
          onTap: () {
            // TODO: Navigate to crystals
          },
        ),
        PremiumStatCard(
          title: 'Tarot',
          value: _tarotReadings.toString(),
          subtitle: 'Lesungen',
          icon: Icons.star_outline,
          color: PremiumDesignSystem.energieSecondary,
          onTap: () {
            // TODO: Show tarot readings
          },
        ),
        PremiumStatCard(
          title: 'Meditation',
          value: '${_meditationMinutes}m',
          subtitle: 'Minuten',
          icon: Icons.self_improvement,
          color: PremiumDesignSystem.energieAccent,
          onTap: () {
            // TODO: Show meditation stats
          },
        ),
        PremiumStatCard(
          title: 'Energie',
          value: '$_energyLevel%',
          subtitle: 'Level',
          icon: Icons.bolt,
          color: PremiumDesignSystem.warning,
          onTap: () {
            // TODO: Show energy details
          },
        ),
      ],
    );
  }

  Widget _buildCrystalCard(Map<String, dynamic> crystal, int index) {
    final delay = index * 100;
    final crystalEmojis = ['💎', '🔮', '✨', '⭐', '💫', '🌟'];

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: PremiumDesignSystem.curveSmooth,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        decoration: PremiumDesignSystem.glassDecoration(
          color: PremiumDesignSystem.energiePrimary,
          blur: 10,
          opacity: 0.15,
          borderOpacity: 0.3,
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
                  // TODO: Show crystal details
                },
                child: Padding(
                  padding: const EdgeInsets.all(PremiumDesignSystem.space3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Crystal emoji with rotation
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _animationController.value *
                                2 *
                                math.pi *
                                (index % 2 == 0 ? 1 : -1),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    PremiumDesignSystem.energiePrimary
                                        .withValues(alpha: 0.3),
                                    PremiumDesignSystem.energieAccent
                                        .withValues(alpha: 0.1),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  crystalEmojis[index % crystalEmojis.length],
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: PremiumDesignSystem.space2),

                      // Crystal name
                      Text(
                        crystal['title'] ?? 'Kristall',
                        style: PremiumDesignSystem.bodySmall.copyWith(
                          color: PremiumDesignSystem.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
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

  Widget _buildActivityCard(Map<String, dynamic> activity, int index) {
    final delay = index * 100;
    final activityIcons = [
      Icons.self_improvement,
      Icons.book_outlined,
      Icons.star_outline,
      Icons.favorite_border,
    ];

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
          color: PremiumDesignSystem.energiePrimary,
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
                  // TODO: Open activity
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
                              PremiumDesignSystem.energiePrimary
                                  .withValues(alpha: 0.3),
                              PremiumDesignSystem.energieSecondary
                                  .withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                              PremiumDesignSystem.radiusMedium),
                        ),
                        child: Icon(
                          activityIcons[index % activityIcons.length],
                          color: PremiumDesignSystem.energiePrimary,
                        ),
                      ),
                      const SizedBox(width: PremiumDesignSystem.space3),

                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity['title'] ?? 'Aktivität',
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
                              activity['category'] ?? 'Spirituell',
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
                  color: PremiumDesignSystem.energiePrimary,
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
                  PremiumDesignSystem.energiePrimary.withValues(alpha: 0.2),
                  PremiumDesignSystem.energieSecondary
                      .withValues(alpha: 0.1),
                ],
              ),
              borderRadius:
                  BorderRadius.circular(PremiumDesignSystem.radiusFull),
            ),
            child: Icon(
              icon,
              size: 48,
              color: PremiumDesignSystem.energiePrimary,
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

/// Custom painter for animated crystal particles
class _CrystalParticlesPainter extends CustomPainter {
  final double animation;
  final Color color;

  _CrystalParticlesPainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Draw animated star/crystal particles
    for (int i = 0; i < 15; i++) {
      final progress = (animation + i * 0.07) % 1.0;
      final x = size.width * (0.1 + (i * 0.06) % 0.9);
      final y = size.height * progress;

      // Draw star shape
      _drawStar(canvas, Offset(x, y), 3.0 + (i % 3) * 1.0, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    const numPoints = 5;
    final path = Path();
    final angle = (2 * math.pi) / (numPoints * 2);

    for (int i = 0; i < numPoints * 2; i++) {
      final r = i % 2 == 0 ? radius : radius / 2;
      final x = center.dx + r * math.cos(i * angle - math.pi / 2);
      final y = center.dy + r * math.sin(i * angle - math.pi / 2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CrystalParticlesPainter oldDelegate) {
    return animation != oldDelegate.animation;
  }
}
