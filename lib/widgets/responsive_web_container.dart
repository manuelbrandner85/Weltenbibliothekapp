/// 🖥️ RESPONSIVE WEB CONTAINER
///
/// Wrappt Bildschirme so dass sie auf PC nicht über die ganze Viewport-Breite
/// stretchen. Mobile-Layouts (≤ 600 px) bleiben unverändert — der Container
/// ist transparent.
///
/// Drei Breakpoints:
///   - mobile  (< 600 px)   → kein Constraint, voller View
///   - tablet  (600-1024)   → max-width 800, zentriert
///   - desktop (> 1024)     → max-width per Variante (compact/wide), zentriert
///
/// Nutzung:
///   ResponsiveWebContainer(
///     child: ListView(...),
///   )
///
///   // Für Onboarding/Forms mit weniger Breite gewünscht:
///   ResponsiveWebContainer(
///     variant: WebContainerVariant.compact,
///     child: Form(...),
///   )
library;

import 'package:flutter/widgets.dart';

enum WebContainerVariant {
  /// Forms, Logins, Onboarding — max 600 px.
  compact,

  /// Standard Content (Dashboard, Listen) — max 1100 px.
  standard,

  /// Maps, Karten, breite Tabs — max 1400 px.
  wide,
}

class ResponsiveWebContainer extends StatelessWidget {
  const ResponsiveWebContainer({
    super.key,
    required this.child,
    this.variant = WebContainerVariant.standard,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final WebContainerVariant variant;
  final Alignment alignment;

  static const double _mobileBreakpoint = 600;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mobile-View → kein Constraint
        if (constraints.maxWidth <= _mobileBreakpoint) return child;

        final double maxWidth = switch (variant) {
          WebContainerVariant.compact => 600,
          WebContainerVariant.standard => 1100,
          WebContainerVariant.wide => 1400,
        };
        return Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        );
      },
    );
  }
}
