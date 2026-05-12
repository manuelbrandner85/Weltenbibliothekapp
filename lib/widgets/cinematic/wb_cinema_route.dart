import 'package:flutter/material.dart';
import '../../theme/wb_cinematic_tokens.dart';

/// Cinematic page transition — fade + subtle upward slide.
///
/// Usage: `Navigator.push(context, WBCinemaRoute(page: MyScreen()));`
class WBCinemaRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  WBCinemaRoute({required this.page})
      : super(
          transitionDuration: WBMotion.page,
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: WBMotion.enterCurve,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}
