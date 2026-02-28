/// Achievements Gallery Screen - Badge-System
/// Weltenbibliothek v61
library;

import 'package:flutter/material.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import '../../services/storage_service.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final _storageService = StorageService();
  
  List<AchievementData> _achievements = [];
  int _unlockedCount = 0;
  
  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }
  
  Future<void> _loadAchievements() async {
    final allAchievements = _storageService.getAllAppAchievements();
    
    setState(() {
      _achievements = _getAchievementsList(allAchievements);
      _unlockedCount = _achievements.where((a) => a.isUnlocked).length;
    });
  }
  
  List<AchievementData> _getAchievementsList(List achievements) {
    // Definiere alle 12 Achievements
    return [
      AchievementData(
        id: 'first_steps',
        emoji: '🌱',
        title: 'Erste Schritte',
        description: 'Erste Meditation abgeschlossen',
        isUnlocked: achievements.any((a) => a.id == 'first_steps' && a.isUnlocked),
      ),
      AchievementData(
        id: 'meditation_10',
        emoji: '🧘',
        title: 'Anfänger',
        description: '10 Meditationen abgeschlossen',
        isUnlocked: achievements.any((a) => a.id == 'meditation_10' && a.isUnlocked),
      ),
      AchievementData(
        id: 'meditation_100',
        emoji: '🧘‍♂️',
        title: 'Meister',
        description: '100 Meditationen abgeschlossen',
        isUnlocked: achievements.any((a) => a.id == 'meditation_100' && a.isUnlocked),
      ),
      AchievementData(
        id: 'mantra_21_days',
        emoji: '🕉️',
        title: 'Mantra-Meister',
        description: '21-Tage-Challenge abgeschlossen',
        isUnlocked: achievements.any((a) => a.id == 'mantra_21_days' && a.isUnlocked),
      ),
      AchievementData(
        id: 'tarot_reader',
        emoji: '🔮',
        title: 'Kartenleger',
        description: '10 Tarot-Ziehungen',
        isUnlocked: achievements.any((a) => a.id == 'tarot_reader' && a.isUnlocked),
      ),
      AchievementData(
        id: 'tarot_master',
        emoji: '🃏',
        title: 'Tarot-Experte',
        description: '50 Tarot-Ziehungen',
        isUnlocked: achievements.any((a) => a.id == 'tarot_master' && a.isUnlocked),
      ),
      AchievementData(
        id: 'crystal_collector',
        emoji: '💎',
        title: 'Kristall-Sammler',
        description: '5 Kristalle in Sammlung',
        isUnlocked: achievements.any((a) => a.id == 'crystal_collector' && a.isUnlocked),
      ),
      AchievementData(
        id: 'crystal_master',
        emoji: '💠',
        title: 'Kristall-Meister',
        description: '10 Kristalle in Sammlung',
        isUnlocked: achievements.any((a) => a.id == 'crystal_master' && a.isUnlocked),
      ),
      AchievementData(
        id: 'week_streak',
        emoji: '🔥',
        title: 'Woche der Praxis',
        description: '7 Tage Streak',
        isUnlocked: achievements.any((a) => a.id == 'week_streak' && a.isUnlocked),
      ),
      AchievementData(
        id: 'month_streak',
        emoji: '🌟',
        title: 'Monat der Hingabe',
        description: '30 Tage Streak',
        isUnlocked: achievements.any((a) => a.id == 'month_streak' && a.isUnlocked),
      ),
      AchievementData(
        id: 'explorer',
        emoji: '🗺️',
        title: 'Entdecker',
        description: 'Alle 15 Spirit-Tools genutzt',
        isUnlocked: achievements.any((a) => a.id == 'explorer' && a.isUnlocked),
      ),
      AchievementData(
        id: 'level_10',
        emoji: '⭐',
        title: 'Level 10',
        description: '1000 XP erreicht',
        isUnlocked: achievements.any((a) => a.id == 'level_10' && a.isUnlocked),
      ),
    ];
  }
  
  @override
  Widget build(BuildContext context) {
    final progress = _achievements.isEmpty ? 0.0 : _unlockedCount / _achievements.length;
    
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text('🏆 Achievements'),
        backgroundColor: Color(0xFFFFD700),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFD700).withValues(alpha: 0.3), Color(0xFF000000)],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _loadAchievements,
          child: ListView(
            padding: EdgeInsets.all(20),
            children: [
              // Progress Card
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFFD700).withValues(alpha: 0.3),
                      Color(0xFFFFA000).withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFFFFD700).withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Dein Fortschritt',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Circular Progress
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 12,
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$_unlockedCount/${_achievements.length}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Achievements Grid
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemCount: _achievements.length,
                itemBuilder: (context, index) {
                  final achievement = _achievements[index];
                  return _buildAchievementCard(achievement);
                },
              ),
              
              SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAchievementCard(AchievementData achievement) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: achievement.isUnlocked
              ? [
                  Color(0xFFFFD700).withValues(alpha: 0.3),
                  Color(0xFFFFA000).withValues(alpha: 0.3),
                ]
              : [
                  Colors.white.withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: achievement.isUnlocked
              ? Color(0xFFFFD700).withValues(alpha: 0.5)
              : Colors.white24,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  achievement.emoji,
                  style: TextStyle(fontSize: 48),
                ),
                SizedBox(height: 12),
                Text(
                  achievement.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: achievement.isUnlocked ? Colors.white : Colors.white54,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: achievement.isUnlocked ? Colors.white70 : Colors.white38,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Lock Overlay
          if (!achievement.isUnlocked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(
                    Icons.lock,
                    color: Colors.white54,
                    size: 32,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AchievementData {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final bool isUnlocked;
  
  AchievementData({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.isUnlocked,
  });
}
