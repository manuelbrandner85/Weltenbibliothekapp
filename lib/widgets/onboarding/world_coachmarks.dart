import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// First-run coachmarks overlay for the world screens.
///
/// Shows a simple, dismissible translucent card with short German hints about
/// the bottom navigation. Persisted via SharedPreferences so it only ever
/// appears once globally (avoids nagging the user in every world).
class WorldCoachmarks {
  WorldCoachmarks._();

  /// Global flag key — single flag so the intro shows only once across worlds.
  static const String _seenKey = 'coachmarks_seen';

  /// Shows the coachmarks overlay once, if it has not been seen before.
  ///
  /// Non-blocking and crash-safe: any SharedPreferences failure is swallowed
  /// and the overlay is simply skipped.
  static Future<void> maybeShow(
    BuildContext context, {
    required String world,
    required Color accent,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(_seenKey) ?? false;
      if (seen) return;

      // Mark as seen immediately to avoid races / double-show.
      await prefs.setBool(_seenKey, true);

      if (!context.mounted) return;

      await showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.72),
        barrierDismissible: true,
        builder: (ctx) => _CoachmarksDialog(accent: accent),
      );
    } catch (_) {
      // Never crash the app over onboarding — silently ignore.
    }
  }
}

/// A single hint row (icon + title + description).
class _CoachHint {
  final IconData icon;
  final String title;
  final String description;
  const _CoachHint({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _CoachmarksDialog extends StatelessWidget {
  final Color accent;
  const _CoachmarksDialog({required this.accent});

  static const List<_CoachHint> _hints = [
    _CoachHint(
      icon: Icons.home,
      title: 'Home',
      description: 'Dein Einstieg in die Welt.',
    ),
    _CoachHint(
      icon: Icons.people,
      title: 'Community',
      description: 'Live-Chat & Sprachraeume mit anderen.',
    ),
    _CoachHint(
      icon: Icons.map,
      title: 'Karte',
      description: 'Die interaktive Welt-Karte.',
    ),
    _CoachHint(
      icon: Icons.menu_book,
      title: 'Wissen',
      description: 'Kurse & Module zum Vertiefen.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0C0C14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: accent.withValues(alpha: 0.35)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.explore_outlined, color: accent, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Willkommen!',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Hier findest du dich unten in der Navigation zurecht:',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ..._hints.map((h) => _buildHintRow(h)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Verstanden',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHintRow(_CoachHint hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(hint.icon, color: accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hint.title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint.description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white60,
                    height: 1.3,
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
