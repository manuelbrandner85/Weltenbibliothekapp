import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/wb_cinematic_tokens.dart';
import '../../core/responsive.dart';

@immutable
class WBFloatingNavItem {
  final IconData icon;
  final String label;

  const WBFloatingNavItem({required this.icon, required this.label});
}

/// Floating glassmorphic Bottom-Nav mit Welt-Akzent.
///
/// • schwebt 16px über safe area, 20px Margin links/rechts
/// • aktiver Tab: Pill-Background + Icon + Label-Text
/// • inaktive Tabs: gedimmter Icon, kein Label (kompakt)
/// • Hoehe 68 — genug fuer Icon + Label
/// • Genau ein BackdropFilter — keine zusaetzlichen GPU-Layer
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
            filter: ImageFilter.blur(
              sigmaX: wb.blurMedium,
              sigmaY: wb.blurMedium,
            ),
            child: Container(
              // Responsive Hoehe: kleine Phones / grosse System-Fonts wuerden
              // Icon + Label sonst clippen. Clamp haelt es kompakt.
              height: context.isSmallPhone ? 64 : context.rw(68),
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: EdgeInsets.symmetric(horizontal: active ? 10 : 6, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? palette.primary.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(WBRadius.lg),
          border: active
              ? Border.all(
                  color: palette.primary.withValues(alpha: 0.25),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: active ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: Icon(
                item.icon,
                size: 20,
                color: active
                    ? palette.highlight
                    : Colors.white.withValues(alpha: 0.45),
              ),
            ),
            // Label always visible: active = bold+accent, inactive = small+dim.
            // Helps users discover what each tab does without tapping.
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label,
                  style: GoogleFonts.inter(
                    fontSize: active ? context.rf(9) : context.rf(8),
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    letterSpacing: active ? 0.5 : 0.3,
                    color: active
                        ? palette.label
                        : Colors.white.withValues(alpha: 0.35),
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
