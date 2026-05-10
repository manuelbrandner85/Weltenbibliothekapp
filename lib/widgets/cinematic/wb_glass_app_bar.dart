import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/wb_cinematic_tokens.dart';

/// Glassmorphic Welt-AppBar mit subtiler Welt-Akzent-Linie unten.
///
/// Höhe = kToolbarHeight (56) + Statusbar.
/// Implementiert `PreferredSizeWidget`, kann direkt in `Scaffold(appBar:)`.
class WBGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget> actions;
  final Widget? leading;
  final WBWorld world;
  final bool centerTitle;
  final bool showAccentLine;

  const WBGlassAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions = const [],
    this.leading,
    this.world = WBWorld.neutral,
    this.centerTitle = false,
    this.showAccentLine = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final wb = context.wb;
    final palette = wb.palette(world);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: wb.blurMedium, sigmaY: wb.blurMedium),
        child: Container(
          decoration: BoxDecoration(
            color: wb.glassElevated,
            border: showAccentLine
                ? Border(
                    bottom: BorderSide(
                      color: Colors.transparent,
                      width: 0,
                    ),
                  )
                : null,
          ),
          child: Stack(
            children: [
              SafeArea(
                bottom: false,
                child: SizedBox(
                  height: kToolbarHeight,
                  child: Row(
                    children: [
                      if (leading != null)
                        leading!
                      else if (Navigator.of(context).canPop())
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded,
                              color: Colors.white),
                          onPressed: () => Navigator.of(context).maybePop(),
                        )
                      else
                        const SizedBox(width: WBSpace.lg),
                      Expanded(
                        child: Align(
                          alignment: centerTitle
                              ? Alignment.center
                              : Alignment.centerLeft,
                          child: titleWidget ??
                              (title == null
                                  ? const SizedBox.shrink()
                                  : Text(
                                      title!,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w400,
                                        fontSize: 16,
                                        letterSpacing: 0.4,
                                        color: Colors.white,
                                      ),
                                    )),
                        ),
                      ),
                      ...actions,
                      const SizedBox(width: WBSpace.sm),
                    ],
                  ),
                ),
              ),
              if (showAccentLine)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 1,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            palette.primary.withValues(alpha: 0.0),
                            palette.primary.withValues(alpha: 0.6),
                            palette.primary.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
