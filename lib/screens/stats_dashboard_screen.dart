import 'package:flutter/material.dart';
// OpenClaw v2.0
import '../services/stats_service.dart';
import '../theme/wb_cinematic_tokens.dart';
import '../widgets/cinematic/wb_glass_app_bar.dart';
import '../widgets/cinematic/wb_glass_card.dart';
import '../widgets/cinematic/wb_vignette.dart';

/// Stats Dashboard Screen — Cinema v6.0
class StatsDashboardScreen extends StatelessWidget {
  final StatsService statsService;

  const StatsDashboardScreen({
    super.key,
    required this.statsService,
  });

  @override
  Widget build(BuildContext context) {
    final stats = statsService.stats;
    final achievements = statsService.achievements;
    final wb = context.wb;

    return Scaffold(
      backgroundColor: wb.bgDeep,
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        world: WBWorld.neutral,
        title: 'Statistiken',
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: WBVignette()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(WBSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLevelCard(context),
                  const SizedBox(height: WBSpace.lg),
                  _buildStatsGrid(stats),
                  const SizedBox(height: WBSpace.xxl),
                  Text(
                    'Erfolge',
                    style: WBType.title.copyWith(
                      fontSize: 18,
                      color: context.onBg,
                    ),
                  ),
                  const SizedBox(height: WBSpace.sm),
                  ...achievements
                      .map((a) => _buildAchievementCard(context, a, stats)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(BuildContext context) {
    final level = statsService.level;
    final xp = statsService.xp;
    final nextLevelXp = statsService.nextLevelXp;
    final progress = level >= 5 ? 1.0 : xp / nextLevelXp;
    final palette = context.wb.palette(WBWorld.neutral);

    return WBGlassCard(
      world: WBWorld.neutral,
      child: Column(
        children: [
          Row(
            children: [
              Text(statsService.levelName,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const Spacer(),
              Text('Level $level',
                  style: TextStyle(
                      fontSize: 20,
                      color: palette.primary,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: WBSpace.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(WBRadius.sm),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(palette.primary),
            ),
          ),
          const SizedBox(height: WBSpace.sm),
          Text(
            level >= 5
                ? 'Maximales Level erreicht!'
                : '$xp / $nextLevelXp XP zum nächsten Level',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(UserStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: WBSpace.md,
      crossAxisSpacing: WBSpace.md,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
            icon: Icons.search,
            label: 'Recherchen',
            value: stats.totalSearches.toString(),
            color: const Color(0xFF3B82F6)),
        _buildStatCard(
            icon: Icons.bookmark_outline,
            label: 'Lesezeichen',
            value: stats.bookmarksCount.toString(),
            color: const Color(0xFFFF9800)),
        _buildStatCard(
            icon: Icons.category_outlined,
            label: 'Kategorien',
            value: '${stats.categoriesExplored}/7',
            color: const Color(0xFF4CAF50)),
        _buildStatCard(
            icon: Icons.auto_stories_outlined,
            label: 'Narrative',
            value: stats.narrativesViewed.toString(),
            color: const Color(0xFFA855F7)),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return WBGlassCard(
      world: WBWorld.neutral,
      padding: const EdgeInsets.all(WBSpace.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: WBSpace.sm),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: Colors.white.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(
    BuildContext context,
    Achievement achievement,
    UserStats stats,
  ) {
    int currentCount = 0;
    switch (achievement.category) {
      case 'searches':
        currentCount = stats.totalSearches;
      case 'bookmarks':
        currentCount = stats.bookmarksCount;
      case 'categories':
        currentCount = stats.categoriesExplored;
      case 'narratives':
        currentCount = stats.narrativesViewed;
    }

    final progress = currentCount / achievement.requiredCount;
    final isUnlocked = achievement.isUnlocked;
    final palette = context.wb.palette(WBWorld.neutral);

    return Padding(
      padding: const EdgeInsets.only(bottom: WBSpace.sm),
      child: WBGlassCard(
        world: WBWorld.neutral,
        padding: const EdgeInsets.symmetric(
            horizontal: WBSpace.lg, vertical: WBSpace.md),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isUnlocked
                  ? Colors.amber.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.06),
              child:
                  Text(achievement.icon, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: WBSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(achievement.title,
                      style: TextStyle(
                        fontWeight:
                            isUnlocked ? FontWeight.bold : FontWeight.normal,
                        color: Colors.white,
                        fontSize: 14,
                      )),
                  const SizedBox(height: 2),
                  Text(achievement.description,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12)),
                  if (!isUnlocked) ...[
                    const SizedBox(height: WBSpace.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(WBRadius.sm),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.amber),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('$currentCount / ${achievement.requiredCount}',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.35))),
                  ] else
                    Text('Freigeschaltet!',
                        style: TextStyle(
                            color: palette.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                ],
              ),
            ),
            isUnlocked
                ? const Icon(Icons.check_circle, color: Colors.amber, size: 20)
                : Icon(Icons.lock_outline,
                    color: Colors.white.withValues(alpha: 0.2), size: 20),
          ],
        ),
      ),
    );
  }
}
