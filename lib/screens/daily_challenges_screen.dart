// =====================================================================
// DAILY CHALLENGES SCREEN v1.0
// =====================================================================
// UI für tägliche Herausforderungen
// Features:
// - Challenge-Liste mit Fortschrittsanzeige
// - Kategorien-Filter
// - Completion Animations
// - Bonus-XP Anzeige
// =====================================================================

import 'package:flutter/material.dart';
import '../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import '../services/daily_challenges_service.dart';
import '../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0

class DailyChallengesScreen extends StatefulWidget {
  const DailyChallengesScreen({super.key});

  @override
  State<DailyChallengesScreen> createState() => _DailyChallengesScreenState();
}

class _DailyChallengesScreenState extends State<DailyChallengesScreen>
    with SingleTickerProviderStateMixin {
  final _challengesService = DailyChallengesService();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final challenges = _challengesService.todaysChallenges;
    final completedCount = _challengesService.completedToday;
    final totalCount = _challengesService.totalChallenges;
    final completionPercent = _challengesService.completionPercent;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'TÄGLICHE HERAUSFORDERUNGEN',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          // HEADER - PROGRESS OVERVIEW
          SliverToBoxAdapter(
            child: _buildProgressHeader(
              completedCount,
              totalCount,
              completionPercent,
            ),
          ),

          // CHALLENGES LIST
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final challenge = challenges[index];
                  return _buildChallengeCard(challenge, index);
                },
                childCount: challenges.length,
              ),
            ),
          ),

          // FOOTER SPACER
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // PROGRESS HEADER
  // =====================================================================

  Widget _buildProgressHeader(int completed, int total, double percent) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade700,
            Colors.purple.shade900,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 32),
              SizedBox(width: 12),
              Text(
                'HEUTE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Progress Circle
          SizedBox(
            height: 120,
            width: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background Circle
                SizedBox(
                  height: 120,
                  width: 120,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 12,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(
                      Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                // Progress Circle
                SizedBox(
                  height: 120,
                  width: 120,
                  child: CircularProgressIndicator(
                    value: percent / 100,
                    strokeWidth: 12,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation(Colors.amber),
                  ),
                ),
                // Center Text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$completed/$total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${percent.toInt()}%',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Status Text
          Text(
            completed == total
                ? '🎉 Alle Challenges abgeschlossen!'
                : 'Noch ${total - completed} Challenges offen',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // CHALLENGE CARD
  // =====================================================================

  Widget _buildChallengeCard(DailyChallenge challenge, int index) {
    final isCompleted = challenge.isCompleted;
    final progress = challenge.progressPercent;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutBack,
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
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isCompleted
              ? Colors.green.shade900.withValues(alpha: 0.3)
              : const Color(0xFF1D1E33),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? Colors.green.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
            width: 2,
          ),
          boxShadow: [
            if (isCompleted)
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Category Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(challenge.category).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    challenge.category.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),

                const SizedBox(width: 16),

                // Title & Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        challenge.description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Completion Icon
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress / 100,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(
                  _getCategoryColor(challenge.category),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Progress Text & Reward
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Progress Numbers
                Text(
                  '${challenge.currentProgress}/${challenge.targetValue}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                // Bonus XP
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.stars,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${challenge.bonusXp} XP',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // HELPERS
  // =====================================================================

  Color _getCategoryColor(ChallengeCategory category) {
    switch (category) {
      case ChallengeCategory.search:
        return Colors.blue;
      case ChallengeCategory.read:
        return Colors.purple;
      case ChallengeCategory.community:
        return Colors.orange;
      case ChallengeCategory.streak:
        return Colors.red;
    }
  }
}
