/// Achievements Screen - Badge Gallery
/// Version: 1.0.0
library;

import 'package:flutter/material.dart';
import '../services/achievement_service.dart';
import '../services/haptic_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  final _achievementService = AchievementService();
  late TabController _tabController;
  
  AchievementCategory _selectedCategory = AchievementCategory.researcher;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: AchievementCategory.values.length,
      vsync: this,
    );
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedCategory = AchievementCategory.values[_tabController.index];
        });
        HapticService.lightImpact();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getCategoryName(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.researcher:
        return 'Forscher';
      case AchievementCategory.explorer:
        return 'Entdecker';
      case AchievementCategory.community:
        return 'Community';
      case AchievementCategory.knowledge:
        return 'Wissen';
      case AchievementCategory.streak:
        return 'Streak';
      case AchievementCategory.collector:
        return 'Sammler';
      case AchievementCategory.creator:
        return 'Ersteller';
      case AchievementCategory.master:
        return 'Meister';
    }
  }

  String _getCategoryIcon(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.researcher:
        return '🔬';
      case AchievementCategory.explorer:
        return '🗺️';
      case AchievementCategory.community:
        return '👥';
      case AchievementCategory.knowledge:
        return '📚';
      case AchievementCategory.streak:
        return '🔥';
      case AchievementCategory.collector:
        return '💾';
      case AchievementCategory.creator:
        return '✍️';
      case AchievementCategory.master:
        return '⭐';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userLevel = _achievementService.getUserLevel();
    final unlockedCount = _achievementService.getUnlockedCount();
    final totalCount = _achievementService.getTotalCount();
    final completionPercent = (unlockedCount / totalCount * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        title: const Text(
          '🏆 ACHIEVEMENTS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.amber,
          tabs: AchievementCategory.values.map((category) {
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getCategoryIcon(category),
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getCategoryName(category),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: Column(
        children: [
          // User Stats Header
          _buildStatsHeader(userLevel, unlockedCount, totalCount, completionPercent),
          
          // Achievement Grid
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: AchievementCategory.values.map((category) {
                return _buildAchievementGrid(category);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(
    UserLevel userLevel,
    int unlockedCount,
    int totalCount,
    int completionPercent,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A237E).withValues(alpha: 0.3),
            const Color(0xFF0D47A1).withValues(alpha: 0.2),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          // Level & XP Row
          Row(
            children: [
              // Level Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.amber, Colors.orange],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'LEVEL ${userLevel.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // XP Progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${userLevel.currentXP} / ${userLevel.xpForNextLevel} XP',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Level ${userLevel.level + 1}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: userLevel.progressToNextLevel,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Achievement Completion
          Row(
            children: [
              // Completion Badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.5),
                  ),
                ),
                child: const Icon(
                  Icons.stars,
                  color: Colors.blue,
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              // Completion Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$unlockedCount / $totalCount Achievements',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$completionPercent%',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: unlockedCount / totalCount,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementGrid(AchievementCategory category) {
    final achievements = _achievementService.getAchievementsByCategory(category);
    
    if (achievements.isEmpty) {
      return Center(
        child: Text(
          'Keine Achievements in dieser Kategorie',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 16,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        return _buildAchievementCard(achievements[index]);
      },
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final progress = _achievementService.getProgress(achievement.id);
    final isUnlocked = progress?.isUnlocked ?? false;
    final currentProgress = progress?.currentProgress ?? 0;
    final progressPercent = (currentProgress / achievement.maxProgress).clamp(0.0, 1.0);

    Color rarityColor;
    switch (achievement.rarity) {
      case AchievementRarity.common:
        rarityColor = Colors.grey;
        break;
      case AchievementRarity.uncommon:
        rarityColor = Colors.green;
        break;
      case AchievementRarity.rare:
        rarityColor = Colors.blue;
        break;
      case AchievementRarity.epic:
        rarityColor = Colors.purple;
        break;
      case AchievementRarity.legendary:
        rarityColor = Colors.orange;
        break;
    }

    return GestureDetector(
      onTap: () {
        HapticService.lightImpact();
        _showAchievementDetails(achievement, progress);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isUnlocked
                ? [
                    rarityColor.withValues(alpha: 0.3),
                    rarityColor.withValues(alpha: 0.1),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.05),
                    Colors.white.withValues(alpha: 0.02),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? rarityColor.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Achievement Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked
                    ? rarityColor.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: isUnlocked
                      ? rarityColor.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  achievement.icon,
                  style: TextStyle(
                    fontSize: 40,
                    color: isUnlocked ? null : Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Achievement Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                achievement.name,
                style: TextStyle(
                  color: isUnlocked ? Colors.white : Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 8),

            // Progress or XP
            if (!isUnlocked && achievement.maxProgress > 1) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progressPercent,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(rarityColor),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currentProgress / ${achievement.maxProgress}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isUnlocked) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${achievement.xpReward} XP',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock,
                      color: Colors.white.withValues(alpha: 0.3),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Gesperrt',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAchievementDetails(Achievement achievement, AchievementProgress? progress) {
    final isUnlocked = progress?.isUnlocked ?? false;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A237E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              achievement.icon,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              achievement.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              achievement.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (!isUnlocked && achievement.secretHint != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        achievement.secretHint!,
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isUnlocked && progress?.unlockedAt != null) ...[
              const SizedBox(height: 16),
              Text(
                'Freigeschaltet: ${_formatDate(progress!.unlockedAt!)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('SCHLIESSEN'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
