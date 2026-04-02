import 'package:flutter/material.dart';

/// 🎬 Modern Animation Library
/// Smooth, professional animations für die Weltenbibliothek
class ModernAnimations {
  // ═══════════════════════════════════════════════════════════
  // DURATION CONSTANTS
  // ═══════════════════════════════════════════════════════════
  
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
  
  // ═══════════════════════════════════════════════════════════
  // CURVES - SMOOTH & NATURAL
  // ═══════════════════════════════════════════════════════════
  
  static const Curve smoothCurve = Curves.easeInOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve snapCurve = Curves.easeOutExpo;
  static const Curve slowStartCurve = Curves.slowMiddle;
  
  // ═══════════════════════════════════════════════════════════
  // FADE ANIMATIONS
  // ═══════════════════════════════════════════════════════════
  
  /// Smooth fade in animation
  static Widget fadeIn({
    required Widget child,
    Duration duration = normal,
    Curve curve = smoothCurve,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }
  
  /// Fade in with slide from bottom
  static Widget fadeInSlide({
    required Widget child,
    Duration duration = normal,
    double offsetY = 20.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: smoothCurve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, offsetY * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
  
  // ═══════════════════════════════════════════════════════════
  // SCALE ANIMATIONS
  // ═══════════════════════════════════════════════════════════
  
  /// Scale up animation
  static Widget scaleIn({
    required Widget child,
    Duration duration = normal,
    double begin = 0.8,
    double end = 1.0,
    Curve curve = smoothCurve,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }
  
  /// Bounce scale animation
  static Widget bounceScale({
    required Widget child,
    Duration duration = slow,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: bounceCurve,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }
  
  // ═══════════════════════════════════════════════════════════
  // SLIDE ANIMATIONS
  // ═══════════════════════════════════════════════════════════
  
  /// Slide from right
  static Widget slideFromRight({
    required Widget child,
    Duration duration = normal,
    double offset = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: offset, end: 0.0),
      duration: duration,
      curve: smoothCurve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(MediaQuery.of(context).size.width * value, 0),
          child: child,
        );
      },
      child: child,
    );
  }
  
  /// Slide from left
  static Widget slideFromLeft({
    required Widget child,
    Duration duration = normal,
    double offset = -1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: offset, end: 0.0),
      duration: duration,
      curve: smoothCurve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(MediaQuery.of(context).size.width * value, 0),
          child: child,
        );
      },
      child: child,
    );
  }
  
  // ═══════════════════════════════════════════════════════════
  // ROTATION ANIMATIONS
  // ═══════════════════════════════════════════════════════════
  
  /// Rotate animation
  static Widget rotate({
    required Widget child,
    Duration duration = slow,
    double turns = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: turns),
      duration: duration,
      curve: smoothCurve,
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 2 * 3.14159,
          child: child,
        );
      },
      child: child,
    );
  }
  
  // ═══════════════════════════════════════════════════════════
  // SHIMMER ANIMATION
  // ═══════════════════════════════════════════════════════════
  
  /// Shimmer loading effect
  static Widget shimmer({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -1.0, end: 2.0),
      duration: duration,
      curve: Curves.linear,
      builder: (context, value, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Colors.white10,
                Colors.white30,
                Colors.white10,
              ],
              stops: [
                value - 0.3,
                value,
                value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: child,
      onEnd: () {
        // Loop animation
      },
    );
  }
  
  // ═══════════════════════════════════════════════════════════
  // PULSE ANIMATION
  // ═══════════════════════════════════════════════════════════
  
  /// Pulsing glow effect
  static Widget pulse({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: minScale, end: maxScale),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
      onEnd: () {
        // Reverse animation
      },
    );
  }
  
  // ═══════════════════════════════════════════════════════════
  // PAGE TRANSITIONS
  // ═══════════════════════════════════════════════════════════
  
  /// Fade page transition
  static PageRouteBuilder<T> fadeTransition<T>({
    required Widget page,
    Duration duration = normal,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
  
  /// Slide page transition
  static PageRouteBuilder<T> slideTransition<T>({
    required Widget page,
    Duration duration = normal,
    SlideDirection direction = SlideDirection.right,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        Offset begin;
        switch (direction) {
          case SlideDirection.right:
            begin = const Offset(1.0, 0.0);
            break;
          case SlideDirection.left:
            begin = const Offset(-1.0, 0.0);
            break;
          case SlideDirection.up:
            begin = const Offset(0.0, -1.0);
            break;
          case SlideDirection.down:
            begin = const Offset(0.0, 1.0);
            break;
        }
        
        return SlideTransition(
          position: Tween<Offset>(
            begin: begin,
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: smoothCurve,
          )),
          child: child,
        );
      },
    );
  }
  
  /// Scale + Fade page transition
  static PageRouteBuilder<T> scaleFadeTransition<T>({
    required Widget page,
    Duration duration = normal,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: smoothCurve),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }
  
  // ═══════════════════════════════════════════════════════════
  // STAGGERED LIST ANIMATION
  // ═══════════════════════════════════════════════════════════
  
  /// Animate list items with stagger
  static Widget staggeredListItem({
    required Widget child,
    required int index,
    int maxStagger = 10,
  }) {
    final delay = Duration(milliseconds: 50 * (index % maxStagger));
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: normal + delay,
      curve: smoothCurve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
  
  // ═══════════════════════════════════════════════════════════
  // HERO ANIMATION HELPER
  // ═══════════════════════════════════════════════════════════
  
  /// Create Hero animation
  static Widget hero({
    required String tag,
    required Widget child,
  }) {
    return Hero(
      tag: tag,
      child: child,
    );
  }
}

/// Slide direction enum
enum SlideDirection {
  left,
  right,
  up,
  down,
}
