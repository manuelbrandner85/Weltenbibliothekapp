import 'package:flutter/material.dart';
import '../screens/shared/profile_editor_screen.dart';

/// Widget fuer fehlende Profile -- leitet zum UNIFIED Profile-Editor.
///
/// v95: Frueher fuehrte der Button zum welt-spezifischen
/// ProfileOnboardingScreen (Materie-Profil/Energie-Profil). Das war
/// verwirrend, weil der User EIN Profil hat, das fuer alle Welten gilt.
/// Jetzt: Klick auf 'Profil erstellen' oeffnet den allgemeinen
/// ProfileEditorScreen (lib/screens/shared/profile_editor_screen.dart).
class ProfileRequiredWidget extends StatelessWidget {
  /// Optionaler Welt-Kontext fuer Akzentfarbe der Karte. Egal welcher
  /// Wert -- der Editor selbst ist welt-uebergreifend.
  final String worldType;
  final String message;
  final VoidCallback? onProfileCreated;

  const ProfileRequiredWidget({
    super.key,
    this.worldType = 'energie',
    this.message = 'Profil erforderlich',
    this.onProfileCreated,
  });

  @override
  Widget build(BuildContext context) {
    final isMaterie = worldType == 'materie';
    final primaryColor = isMaterie ? Colors.blue : Colors.purple;
    // v95: Welt-spezifische Phrasen im message normalisieren -- der
    // Profil-Editor ist welt-uebergreifend.
    final displayMessage = message
        .replaceAll('Energie-Profil', 'Profil')
        .replaceAll('Materie-Profil', 'Profil')
        .replaceAll('Vorhang-Profil', 'Profil')
        .replaceAll('Ursprung-Profil', 'Profil');

    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
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
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isMaterie
                      ? [const Color(0xFF2196F3), const Color(0xFF00BCD4)]
                      : [const Color(0xFF9C27B0), const Color(0xFF673AB7)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.person_add_outlined,
                    size: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              displayMessage,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Lege dein allgemeines Profil mit Geburtsdaten an -- es gilt '
              'fuer alle Welten und Tools (Numerologie, Astrologie, '
              'Spirit-Tools, Kristalle, Mantras).',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileEditorScreen(world: 'energie'),
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
                  horizontal: 32, vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Daten lokal gespeichert',
                      style: TextStyle(
                        fontSize: 12,
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
