import 'package:flutter/material.dart';

import '../../screens/shared/stats_dashboard_screen.dart';
import '../../screens/shared/unified_world_map_screen.dart';
import '../../services/haptic_service.dart';

/// Shared "Mehr" bottom sheet for all four world screens.
///
/// Shows: Vier-Welten-Karte, Statistik, Errungenschaften,
/// Lesezeichen, Welt wechseln.
/// Replaces the duplicated _showMoreMenu() in each world screen.
void showWBMoreMenu(
  BuildContext context, {
  required String world,
  required Color accent,
}) {
  HapticService.selectionClick();
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF0C0C14),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            _WBMoreMenuItem(
              icon: Icons.layers_outlined,
              label: 'Vier-Welten-Karte',
              accent: accent,
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UnifiedWorldMapScreen(world: world),
                  ),
                );
              },
            ),
            _WBMoreMenuItem(
              icon: Icons.analytics_outlined,
              label: 'Statistik',
              accent: accent,
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StatsDashboardScreen(world: world),
                  ),
                );
              },
            ),
            _WBMoreMenuItem(
              icon: Icons.emoji_events_outlined,
              label: 'Errungenschaften',
              accent: accent,
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.pushNamed(context, '/achievements');
              },
            ),
            _WBMoreMenuItem(
              icon: Icons.bookmarks_outlined,
              label: 'Lesezeichen',
              accent: accent,
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.pushNamed(context, '/global_bookmarks');
              },
            ),
            _WBMoreMenuItem(
              icon: Icons.swap_horiz,
              label: 'Welt wechseln',
              accent: accent,
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

class _WBMoreMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _WBMoreMenuItem({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: accent),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}
