import 'package:flutter/material.dart';
import '../screens/profile_onboarding_screen.dart';

/// Widget für fehlende Profile - zeigt hilfreichen Hinweis
class ProfileRequiredWidget extends StatelessWidget {
  final String worldType; // 'materie' oder 'energie'
  final String message;
  final VoidCallback? onProfileCreated;
  
  const ProfileRequiredWidget({
    super.key,
    required this.worldType,
    this.message = 'Profil erforderlich',
    this.onProfileCreated,
  });

  @override
  Widget build(BuildContext context) {
    final isMaterie = worldType == 'materie';
    final primaryColor = isMaterie ? Colors.blue : Colors.purple;
    
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor.withValues(alpha: 0.1),
              primaryColor.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isMaterie
                      ? [const Color(0xFF2196F3), const Color(0xFF00BCD4)]
                      : [const Color(0xFF9C27B0), const Color(0xFF673AB7)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.person_add_outlined,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Titel
            Text(
              message,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Beschreibung
            Text(
              isMaterie
                  ? 'Erstelle ein Materie-Profil, um diese Funktion zu nutzen.'
                  : 'Erstelle ein Energie-Profil mit deinen Geburtsdaten, um spirituelle Tools zu verwenden.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 28),
            
            // Button
            FilledButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileOnboardingScreen(
                      worldType: worldType,
                    ),
                  ),
                );
                
                if (result == true && onProfileCreated != null) {
                  onProfileCreated!();
                }
              },
              icon: const Icon(Icons.add, size: 22),
              label: const Text(
                'Profil erstellen',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Info-Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Deine Daten bleiben lokal gespeichert',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
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
}
