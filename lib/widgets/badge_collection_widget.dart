import 'package:flutter/material.dart';
import '../models/spirit_extended_models.dart';
import 'achievement_detail_dialog.dart';

/// ============================================
/// BADGE COLLECTION WIDGET
/// Übersicht aller Achievements
/// ============================================

class BadgeCollectionWidget extends StatefulWidget {
  final Color accentColor;

  const BadgeCollectionWidget({
    super.key,
    this.accentColor = const Color(0xFF9C27B0),
  });

  @override
  State<BadgeCollectionWidget> createState() => _BadgeCollectionWidgetState();
}

class _BadgeCollectionWidgetState extends State<BadgeCollectionWidget> {
  AchievementCategory _selectedCategory = AchievementCategory.streak;

  @override
  Widget build(BuildContext context) {
// UNUSED: final achievementService = AchievementService();
    final allAchievements = []; // achievementService.getAllAchievementsWithStatus();
    final filteredAchievements = allAchievements
        .where((a) => a.category == _selectedCategory)
        .toList();

    final unlockedCount = 0; // achievementService.unlockedCount;
    final totalCount = 0; // achievementService.totalCount;
    final progressPercent = 0.0; // achievementService.progressPercent;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A2E),
            const Color(0xFF0F0F1E),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.accentColor,
                        widget.accentColor.withValues(alpha: 0.6),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Titel & Fortschritt
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Achievements',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$unlockedCount / $totalCount freigeschaltet',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                // Progress-Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${progressPercent.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: widget.accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Progress-Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressPercent / 100,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(widget.accentColor),
                minHeight: 6,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Filter-Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AchievementCategory.values.map((category) {
                  final isSelected = category == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_getCategoryName(category)),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = category);
                        }
                      },
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      selectedColor: widget.accentColor.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? widget.accentColor
                            : Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? widget.accentColor
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Achievement-Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: filteredAchievements.length,
              itemBuilder: (context, index) {
                final achievement = filteredAchievements[index];
                return _buildAchievementCard(achievement);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Achievement-Card
  Widget _buildAchievementCard(Achievement achievement) {
    final isUnlocked = achievement.isUnlocked;

    return GestureDetector(
      onTap: () => _showAchievementDetails(achievement),
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked
              ? achievement.color.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnlocked
                ? achievement.color.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isUnlocked
                    ? LinearGradient(
                        colors: [
                          achievement.color,
                          achievement.color.withValues(alpha: 0.6),
                        ],
                      )
                    : null,
                color: isUnlocked ? null : Colors.white.withValues(alpha: 0.05),
              ),
              child: Icon(
                achievement.icon,
                size: 24,
                color: isUnlocked ? Colors.white : Colors.white.withValues(alpha: 0.3),
              ),
            ),

            const SizedBox(height: 8),

            // Titel
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                achievement.title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Lock-Icon (wenn locked)
            if (!isUnlocked)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.lock,
                  size: 12,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Achievement-Details-Dialog
  void _showAchievementDetails(Achievement achievement) {
    // Use the new detailed dialog
    AchievementDetailDialog.show(
      context,
      achievement,
      accentColor: widget.accentColor,
    );
  }

  /// Kategorie-Name
  String _getCategoryName(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.streak:
        return 'Streak';
      case AchievementCategory.checkIn:
        return 'Check-In';
      case AchievementCategory.favorites:
        return 'Favoriten';
      case AchievementCategory.spiritTools:
        return 'Tools';
      case AchievementCategory.points:
        return 'Punkte';
      case AchievementCategory.special:
        return 'Spezial';
    }
  }
}
