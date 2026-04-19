/// Achievement Detail Dialog
/// Shows detailed information about an achievement
library;

import 'package:flutter/material.dart';
import '../models/spirit_extended_models.dart';
import '../utils/custom_page_route.dart';

class AchievementDetailDialog extends StatelessWidget {
  final Achievement achievement;
  final Color accentColor;

  const AchievementDetailDialog({
    super.key,
    required this.achievement,
    this.accentColor = const Color(0xFF9C27B0),
  });

  static void show(BuildContext context, Achievement achievement, {Color? accentColor}) {
    Navigator.of(context).push(
      CustomDialogRoute(
        dialog: AchievementDetailDialog(
          achievement: achievement,
          accentColor: accentColor ?? const Color(0xFF9C27B0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A2E),
              const Color(0xFF0F0F1E),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white70),
                padding: const EdgeInsets.all(16),
              ),
            ),

            // Achievement Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.3),
                    accentColor.withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.5),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  achievement.icon,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Achievement Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                achievement.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 12),

            // Achievement Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                achievement.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: achievement.isUnlocked
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: achievement.isUnlocked
                      ? Colors.green.withValues(alpha: 0.5)
                      : Colors.grey.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    achievement.isUnlocked ? Icons.check_circle : Icons.lock,
                    color: achievement.isUnlocked ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    achievement.isUnlocked ? 'FREIGESCHALTET' : 'GESPERRT',
                    style: TextStyle(
                      color: achievement.isUnlocked ? Colors.green : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            if (achievement.isUnlocked && achievement.unlockedAt != null) ...[
              const SizedBox(height: 16),
              Text(
                'Freigeschaltet am: ${_formatDate(achievement.unlockedAt!)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Requirement Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: accentColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Voraussetzungen',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getRequirementText(achievement),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getRequirementText(Achievement achievement) {
    // Extract requirement from achievement ID
    switch (achievement.id) {
      case 'first_steps':
        return 'Eröffne deine Reise durch die Weltenbibliothek';
      case 'collector':
        return 'Sammle 5 Wissensartikel in deinen Favoriten';
      case 'knowledge_seeker':
        return 'Lies 10 Artikel aus der Wissensdatenbank';
      case 'spirit_explorer':
        return 'Nutze alle 16 Spirit-Tools mindestens einmal';
      case 'streak_7':
        return 'Logge dich an 7 aufeinanderfolgenden Tagen ein';
      case 'streak_30':
        return 'Logge dich an 30 aufeinanderfolgenden Tagen ein';
      case 'journal_10':
        return 'Schreibe 10 Journal-Einträge';
      case 'sync_master':
        return 'Erkenne 20 Synchronizitäten in deinem Leben';
      case 'meditation_guru':
        return 'Nutze das Meditation-Tool 50 Mal';
      case 'points_1000':
        return 'Sammle 1000 Erfahrungspunkte';
      case 'points_5000':
        return 'Sammle 5000 Erfahrungspunkte';
      default:
        return 'Erfülle die spezifischen Anforderungen für dieses Achievement';
    }
  }
}
