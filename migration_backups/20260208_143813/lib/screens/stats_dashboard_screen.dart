import 'package:flutter/material.dart';
import '../services/stats_service.dart';

/// Stats Dashboard Screen
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Statistiken'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level Card
            _buildLevelCard(context),
            
            const SizedBox(height: 16),
            
            // Stats Grid
            _buildStatsGrid(stats),
            
            const SizedBox(height: 24),
            
            // Achievements
            Text(
              '🏆 Erfolge',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            ...achievements.map((achievement) => _buildAchievementCard(
              context,
              achievement,
              stats,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard(BuildContext context) {
    final level = statsService.level;
    final xp = statsService.xp;
    final nextLevelXp = statsService.nextLevelXp;
    final progress = level >= 5 ? 1.0 : xp / nextLevelXp;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  statsService.levelName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Level $level',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 8),
            Text(
              level >= 5 
                  ? 'Maximales Level erreicht!' 
                  : '$xp / $nextLevelXp XP zum nächsten Level',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(UserStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          icon: '🔍',
          label: 'Recherchen',
          value: stats.totalSearches.toString(),
          color: Colors.blue,
        ),
        _buildStatCard(
          icon: '📑',
          label: 'Lesezeichen',
          value: stats.bookmarksCount.toString(),
          color: Colors.orange,
        ),
        _buildStatCard(
          icon: '🗂️',
          label: 'Kategorien',
          value: '${stats.categoriesExplored}/7',
          color: Colors.green,
        ),
        _buildStatCard(
          icon: '📚',
          label: 'Narrative',
          value: stats.narrativesViewed.toString(),
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
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
        break;
      case 'bookmarks':
        currentCount = stats.bookmarksCount;
        break;
      case 'categories':
        currentCount = stats.categoriesExplored;
        break;
      case 'narratives':
        currentCount = stats.narrativesViewed;
        break;
    }

    final progress = currentCount / achievement.requiredCount;
    final isUnlocked = achievement.isUnlocked;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isUnlocked ? Colors.amber[50] : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isUnlocked ? Colors.amber : Colors.grey[300],
          child: Text(
            achievement.icon,
            style: const TextStyle(fontSize: 24),
          ),
        ),
        title: Text(
          achievement.title,
          style: TextStyle(
            fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(achievement.description),
            const SizedBox(height: 4),
            if (!isUnlocked) ...[
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
              const SizedBox(height: 2),
              Text(
                '$currentCount / ${achievement.requiredCount}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ] else
              Text(
                'Freigeschaltet!',
                style: TextStyle(
                  color: Colors.amber[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: isUnlocked
            ? const Icon(Icons.check_circle, color: Colors.amber)
            : Icon(Icons.lock, color: Colors.grey[400]),
      ),
    );
  }
}
