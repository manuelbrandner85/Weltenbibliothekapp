// Cinematic page-transition for Vorhang module navigation.
//
// Incoming screen: fade-in + 4% upward slide, 350 ms easeOutCubic.
// Return: fade-out + subtle slide-down, 280 ms.
// Respects OS reduce-motion (MediaQuery.disableAnimations -> instant swap).

import 'package:flutter/material.dart';

/// Drop-in replacement for [MaterialPageRoute] in the Vorhang section.
///
/// Usage:
///   Navigator.of(context).push(VorhangPageRoute(
///     builder: (_) => VorhangLessonScreen(moduleCode: code),
///   ));
class VorhangPageRoute<T> extends PageRouteBuilder<T> {
  VorhangPageRoute({required WidgetBuilder builder})
    : super(
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionsBuilder: _buildTransition,
      );

  static Widget _buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.of(context).disableAnimations) return child;

    const begin = Offset(0.0, 0.04);
    const end = Offset.zero;
    const curve = Curves.easeOutCubic;

    final slide = Tween<Offset>(
      begin: begin,
      end: end,
    ).chain(CurveTween(curve: curve)).animate(animation);

    final fade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).chain(CurveTween(curve: curve)).animate(animation);

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}
