import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/spirit_extended_models.dart';
import 'package:weltenbibliothek/core/storage/unified_storage_service.dart';

/// Streak-Widget für Dashboard
/// Zeigt aktuellen Streak, Kalender und Badges
class StreakWidget extends StatefulWidget {
  final Color accentColor;
  final String worldType; // 'materie' oder 'energie'
  
  const StreakWidget({
    super.key,
    required this.accentColor,
    required this.worldType,
  });

  @override
  State<StreakWidget> createState() => _StreakWidgetState();
}

class _StreakWidgetState extends State<StreakWidget> {
  SpiritProgress? _progress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    final progress = StorageService().getSpiritProgress();
    setState(() {
      _progress = progress;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoading();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.accentColor.withValues(alpha: 0.15),
            Colors.black.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.accentColor.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          
          const Divider(color: Colors.white24, thickness: 1, height: 1),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Streak-Counter (groß)
                  _buildStreakCounter(),
                  
                  const SizedBox(height: 24),
                  
                  // 7-Tage Kalender
                  _buildWeekCalendar(),
                  
                  const SizedBox(height: 24),
                  
                  // Badges
                  _buildBadges(),
                  
                  const SizedBox(height: 16),
                  
                  // Statistiken
                  _buildStats(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.3),
        ),
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(widget.accentColor),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  widget.accentColor.withValues(alpha: 0.6),
                  widget.accentColor.withValues(alpha: 0.2),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '🔥',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dein Streak',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Bleib dran!',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCounter() {
    final currentStreak = _progress?.currentStreak ?? 0;
    final longestStreak = _progress?.longestStreak ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.accentColor.withValues(alpha: 0.3),
            widget.accentColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$currentStreak',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: widget.accentColor,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  currentStreak == 1 ? 'Tag' : 'Tage',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: widget.accentColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🏆',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  'Längster: $longestStreak Tage',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekCalendar() {
    final today = DateTime.now();
    final lastActivityDate = _progress?.lastActivityDate ?? today;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Letzte 7 Tage',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (index) {
            final date = today.subtract(Duration(days: 6 - index));
            final isActive = _isDateActive(date, lastActivityDate);
            final isToday = _isSameDay(date, today);
            
            return _buildDayIndicator(
              date: date,
              isActive: isActive,
              isToday: isToday,
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDayIndicator({
    required DateTime date,
    required bool isActive,
    required bool isToday,
  }) {
    final weekday = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'][date.weekday - 1];
    
    return Column(
      children: [
        Text(
          weekday,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive
                ? widget.accentColor.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: isToday
                ? Border.all(color: Colors.white, width: 2)
                : null,
          ),
          child: Center(
            child: Text(
              isActive ? '✓' : '·',
              style: TextStyle(
                fontSize: isActive ? 20 : 24,
                color: isActive ? Colors.white : Colors.white30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${date.day}',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildBadges() {
    final currentStreak = _progress?.currentStreak ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Abzeichen',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBadge(
              emoji: '🔥',
              label: '7 Tage',
              unlocked: currentStreak >= 7,
            ),
            _buildBadge(
              emoji: '💪',
              label: '30 Tage',
              unlocked: currentStreak >= 30,
            ),
            _buildBadge(
              emoji: '👑',
              label: '100 Tage',
              unlocked: currentStreak >= 100,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge({
    required String emoji,
    required String label,
    required bool unlocked,
  }) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: unlocked
                ? LinearGradient(
                    colors: [
                      widget.accentColor.withValues(alpha: 0.6),
                      widget.accentColor.withValues(alpha: 0.3),
                    ],
                  )
                : null,
            color: unlocked ? null : Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
            border: Border.all(
              color: unlocked
                  ? widget.accentColor.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: Center(
            child: Opacity(
              opacity: unlocked ? 1.0 : 0.3,
              child: Text(
                emoji,
                style: const TextStyle(
                  fontSize: 28,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: unlocked ? Colors.white : Colors.white38,
            fontWeight: unlocked ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    final totalPoints = _progress?.totalPoints ?? 0;
    final currentLevel = _progress?.currentLevel ?? 1;
    final activityCount = _progress?.activityCounts.values.fold(0, (sum, count) => sum + count) ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            icon: '⭐',
            value: '$totalPoints',
            label: 'Punkte',
          ),
          _buildStatItem(
            icon: '📊',
            value: '$currentLevel',
            label: 'Level',
          ),
          _buildStatItem(
            icon: '✓',
            value: '$activityCount',
            label: 'Aktivitäten',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: widget.accentColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  bool _isDateActive(DateTime date, DateTime lastActivity) {
    final currentStreak = _progress?.currentStreak ?? 0;
    if (currentStreak == 0) return false;
    
    final today = DateTime.now();
    final daysSinceLastActivity = today.difference(lastActivity).inDays;
    
    // Wenn heute aktiv war
    if (daysSinceLastActivity == 0) {
      final daysDiff = today.difference(date).inDays;
      return daysDiff < currentStreak;
    }
    
    // Wenn gestern aktiv war (Streak noch gültig)
    if (daysSinceLastActivity == 1) {
      final daysDiff = lastActivity.difference(date).inDays;
      return daysDiff >= 0 && daysDiff < currentStreak;
    }
    
    return false;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
