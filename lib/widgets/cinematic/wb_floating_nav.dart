import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/wb_cinematic_tokens.dart';

@immutable
class WBFloatingNavItem {
  final IconData icon;
  final String label;

  const WBFloatingNavItem({required this.icon, required this.label});
}

/// Floating glassmorphic Bottom-Nav mit Welt-Akzent.
///
/// • schwebt 16px über safe area, 20px Margin links/rechts
/// • aktiver Tab bekommt 4×4 Welt-Glow-Dot mit Spring-Curve-Animation
/// • Höhe 64
/// • Genau ein BackdropFilter — keine zusätzlichen GPU-Layer
class WBFloatingNav extends StatelessWidget {
  final List<WBFloatingNavItem> items;
  final int activeIndex;
  final ValueChanged<int> onChanged;
  final WBWorld world;

  const WBFloatingNav({
    super.key,
    required this.items,
    required this.activeIndex,
    required this.onChanged,
    this.world = WBWorld.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final wb = context.wb;
    final palette = wb.palette(world);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: WBSpace.xl),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(WBRadius.xl),
          child: BackdropFilter(
            filter:
                ImageFilter.blur(sigmaX: wb.blurMedium, sigmaY: wb.blurMedium),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: wb.glassElevated,
                borderRadius: BorderRadius.circular(WBRadius.xl),
                border: Border.all(color: wb.glassStroke, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF000000).withValues(alpha: 0.55),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: palette.primary.withValues(alpha: 0.12),
                    blurRadius: 32,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: _NavTab(
                        item: items[i],
                        active: i == activeIndex,
                        palette: palette,
                        onTap: () {
                          if (i == activeIndex) return;
                          HapticFeedback.selectionClick();
                          onChanged(i);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final WBFloatingNavItem item;
  final bool active;
  final WBWorldPalette palette;
  final VoidCallback onTap;

  const _NavTab({
    required this.item,
    required this.active,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WBRadius.md),
        splashColor: palette.primary.withValues(alpha: 0.10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: active ? 1.10 : 1.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: Icon(
                item.icon,
                size: 22,
                color: active
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              width: active ? 14 : 4,
              height: 4,
              decoration: BoxDecoration(
                color: active
                    ? palette.primary
                    : Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: palette.primary.withValues(alpha: 0.7),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
