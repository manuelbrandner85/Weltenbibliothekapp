import 'package:flutter/material.dart';
import '../services/storage_service.dart';

/// 📊 XP & LEVEL WIDGET
/// Zeigt aktuelles Level, XP und Progress-Bar
class LevelWidget extends StatefulWidget {
  final Color? accentColor;
  
  const LevelWidget({
    super.key,
    this.accentColor,
  });

  @override
  State<LevelWidget> createState() => _LevelWidgetState();
}

class _LevelWidgetState extends State<LevelWidget> {
  final _storage = StorageService();
  
  int _currentLevel = 1;
  int _currentXP = 0;
  int _xpForNextLevel = 100;
  double _progress = 0.0;
  
  @override
  void initState() {
    super.initState();
    _loadLevelData();
  }

  Future<void> _loadLevelData() async {
    try {
      final level = await _storage.getCurrentLevel();
      final xp = await _storage.getCurrentXP();
      final xpNext = await _storage.getXPForNextLevel();
      final progress = await _storage.getLevelProgress();
      
      setState(() {
        _currentLevel = level;
        _currentXP = xp;
        _xpForNextLevel = xpNext;
        _progress = progress;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.accentColor ?? Colors.amber;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Level Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$_currentLevel',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Level Info & Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Level',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '$_currentXP / $_xpForNextLevel XP',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  '${(_progress * 100).toInt()}% bis Level ${_currentLevel + 1}',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 🔥 STREAK WIDGET WITH FIRE ANIMATION
/// Zeigt aktuellen Streak mit animiertem Feuer
class StreakWidget extends StatefulWidget {
  final Color? accentColor;
  final VoidCallback? onTap;
  
  const StreakWidget({
    super.key,
    this.accentColor,
    this.onTap,
  });

  @override
  State<StreakWidget> createState() => _StreakWidgetState();
}

class _StreakWidgetState extends State<StreakWidget>
    with SingleTickerProviderStateMixin {
  final _storage = StorageService();
  
  int _currentStreak = 0;
  int _bestStreak = 0;
  bool _canCheckIn = false;
  
  late AnimationController _fireController;
  late Animation<double> _fireAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _fireController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _fireAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _fireController, curve: Curves.easeInOut),
    );
    
    _loadStreakData();
  }

  @override
  void dispose() {
    _fireController.dispose();
    super.dispose();
  }

  Future<void> _loadStreakData() async {
    try {
      final streak = await _storage.getCurrentStreak();
      final best = await _storage.getBestStreak();
      final lastCheckIn = await _storage.getLastCheckInDate();
      
      bool canCheckIn = true;
      if (lastCheckIn != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final lastDate = DateTime(
          lastCheckIn.year,
          lastCheckIn.month,
          lastCheckIn.day,
        );
        canCheckIn = today.difference(lastDate).inDays > 0;
      }
      
      setState(() {
        _currentStreak = streak;
        _bestStreak = best;
        _canCheckIn = canCheckIn;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.accentColor ?? Colors.orange;
    
    return GestureDetector(
      onTap: widget.onTap ?? _showStreakDialog,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.2),
              Colors.red.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            // Animated Fire Icon
            AnimatedBuilder(
              animation: _fireAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _fireAnimation.value,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _currentStreak > 0
                          ? color.withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _currentStreak > 0 ? '🔥' : '⭕',
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(width: 16),
            
            // Streak Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Streak',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      if (_canCheckIn)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Check-In!',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    '$_currentStreak Tage',
                    style: TextStyle(
                      color: color,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 2),
                  
                  Text(
                    'Bester Streak: $_bestStreak Tage',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStreakDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          '🔥 Daily Streak',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Aktueller Streak: $_currentStreak Tage',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bester Streak: $_bestStreak Tage',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            if (_canCheckIn)
              const Text(
                'Nutze die App heute, um deinen Streak zu verlängern!',
                style: TextStyle(color: Colors.greenAccent),
                textAlign: TextAlign.center,
              )
            else
              const Text(
                'Heute bereits eingecheckt! ✅',
                style: TextStyle(color: Colors.amber),
                textAlign: TextAlign.center,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
