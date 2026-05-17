// 4-Quadrant World-Switcher-Pill für die AppBar in Welt-Screens.
//
// Erlaubt schnelles Springen zwischen Materie/Energie/Vorhang/Ursprung
// ohne den Umweg übers Portal. Aktuelle Welt = großer farbiger Punkt,
// andere drei = kleiner & gedimmt. Tap auf eine andere Welt =
// pushReplacement auf den entsprechenden Wrapper.

import 'package:flutter/material.dart';

import '../screens/energie_world_wrapper.dart';
import '../screens/materie_world_wrapper.dart';
import '../screens/ursprung/ursprung_world_wrapper.dart';
import '../screens/vorhang/vorhang_world_wrapper.dart';

class WorldSwitcherPill extends StatelessWidget {
  final String currentWorld;

  const WorldSwitcherPill({super.key, required this.currentWorld});

  static const _worlds = [
    ('materie', Color(0xFF3B82F6), Icons.public),
    ('energie', Color(0xFFA855F7), Icons.auto_awesome),
    ('vorhang', Color(0xFFC9A84C), Icons.psychology),
    ('ursprung', Color(0xFF00D4AA), Icons.all_inclusive),
  ];

  void _navigate(BuildContext context, String world) {
    if (world == currentWorld) return;
    Widget screen;
    switch (world) {
      case 'materie':
        screen = const MaterieWorldWrapper();
        break;
      case 'energie':
        screen = const EnergieWorldWrapper();
        break;
      case 'vorhang':
        screen = const VorhangWorldWrapper();
        break;
      case 'ursprung':
        screen = const UrsprungWorldWrapper();
        break;
      default:
        return;
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionDuration: const Duration(milliseconds: 320),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _worlds.map((w) {
          final isCurrent = w.$1 == currentWorld;
          return _WorldDot(
            world: w.$1,
            color: w.$2,
            icon: w.$3,
            isCurrent: isCurrent,
            onTap: () => _navigate(context, w.$1),
          );
        }).toList(),
      ),
    );
  }
}

class _WorldDot extends StatelessWidget {
  final String world;
  final Color color;
  final IconData icon;
  final bool isCurrent;
  final VoidCallback onTap;

  const _WorldDot({
    required this.world,
    required this.color,
    required this.icon,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: world[0].toUpperCase() + world.substring(1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: isCurrent ? 26 : 18,
          height: isCurrent ? 26 : 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCurrent
                ? color.withValues(alpha: 0.85)
                : color.withValues(alpha: 0.18),
            border: Border.all(
              color: isCurrent
                  ? color
                  : color.withValues(alpha: 0.4),
              width: isCurrent ? 1.5 : 1,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.55),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: isCurrent ? 14 : 0,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
