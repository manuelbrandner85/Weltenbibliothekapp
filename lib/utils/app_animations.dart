import 'package:flutter/material.dart';

/// 🎨 WELTENBIBLIOTHEK - ANIMATION UTILITIES
/// Zentrale Animation Definitionen für konsistente UX

class AppAnimations {
  AppAnimations._();
  
  // ============================================
  // DURATION CONSTANTS
  // ============================================
  
  /// Standard animation duration for most transitions
  static const Duration standard = Duration(milliseconds: 300);
  
  /// Fast animations for micro-interactions
  static const Duration fast = Duration(milliseconds: 150);
  
  /// Slow animations for emphasis
  static const Duration slow = Duration(milliseconds: 500);
  
  /// Page transition duration
  static const Duration pageTransition = Duration(milliseconds: 350);
  
  /// Fade animation duration
  static const Duration fade = Duration(milliseconds: 250);
  
  /// Slide animation duration
  static const Duration slide = Duration(milliseconds: 300);
  
  /// Scale animation duration
  static const Duration scale = Duration(milliseconds: 200);
  
  // ============================================
  // CURVES
  // ============================================
  
  /// Standard easing curve (Material Design recommended)
  static const Curve standardCurve = Curves.easeInOutCubic;
  
  /// Emphasized easing for important actions
  static const Curve emphasizedCurve = Curves.easeOutBack;
  
  /// Bounce effect for playful interactions
  static const Curve bounceCurve = Curves.elasticOut;
  
  /// Smooth deceleration
  static const Curve decelerationCurve = Curves.decelerate;
  
  /// Smooth acceleration
  static const Curve accelerationCurve = Curves.easeIn;
  
  // ============================================
  // PAGE TRANSITIONS
  // ============================================
  
  /// Smooth fade page transition
  static PageTransitionsBuilder fadeTransition = const FadeUpwardsPageTransitionsBuilder();
  
  /// Custom slide transition
  static Route<T> slideTransition<T>(
    Widget page, {
    RouteSettings? settings,
    Offset begin = const Offset(1.0, 0.0),
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: pageTransition,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: begin,
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: standardCurve,
          )),
          child: child,
        );
      },
    );
  }
  
  /// Fade + Scale transition
  static Route<T> fadeScaleTransition<T>(Widget page, {RouteSettings? settings}) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: pageTransition,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.95,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: standardCurve,
            )),
            child: child,
          ),
        );
      },
    );
  }
  
  // ============================================
  // WIDGET ANIMATIONS
  // ============================================
  
  /// Fade in animation widget
  static Widget fadeIn(
    Widget child, {
    Duration duration = standard,
    Curve curve = standardCurve,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: begin, end: end),
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
  
  /// Slide in animation widget
  static Widget slideIn(
    Widget child, {
    Duration duration = standard,
    Curve curve = standardCurve,
    Offset begin = const Offset(0, 0.3),
    Offset end = Offset.zero,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween<Offset>(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: value,
          child: child,
        );
      },
      child: child,
    );
  }
  
  /// Scale in animation widget
  static Widget scaleIn(
    Widget child, {
    Duration duration = scale,
    Curve curve = emphasizedCurve,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: begin, end: end),
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
  
  /// Combined fade + slide animation
  static Widget fadeSlideIn(
    Widget child, {
    Duration duration = standard,
    Curve curve = standardCurve,
    Offset slideBegin = const Offset(0, 0.1),
    double fadeBegin = 0.0,
  }) {
    return fadeIn(
      slideIn(
        child,
        begin: slideBegin,
        duration: duration,
        curve: curve,
      ),
      begin: fadeBegin,
      duration: duration,
      curve: curve,
    );
  }
  
  // ============================================
  // LOADING ANIMATIONS
  // ============================================
  
  /// Pulsing animation for loading states
  static Widget pulse(Widget child, {Duration duration = slow}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      onEnd: () {
        // Repeat animation (would need StatefulWidget for true infinite loop)
      },
      child: child,
    );
  }
  
  /// Shimmer loading effect
  static Widget shimmer(
    Widget child, {
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: -1.0, end: 2.0),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                (value - 0.3).clamp(0.0, 1.0),
                value.clamp(0.0, 1.0),
                (value + 0.3).clamp(0.0, 1.0),
              ],
              colors: const [
                Colors.grey,
                Colors.white,
                Colors.grey,
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: child,
    );
  }
  
  // ============================================
  // BUTTON ANIMATIONS
  // ============================================
  
  /// Bounce animation for buttons
  static Widget bounceOnTap(
    Widget child, {
    required VoidCallback onTap,
    double scale = 0.95,
  }) {
    return GestureDetector(
      onTapDown: (_) {
        // Scale down on tap
      },
      onTapUp: (_) {
        // Scale back up
      },
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        duration: fast,
        curve: bounceCurve,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: child,
      ),
    );
  }
}

/// 🎨 Extension for easy animation access
extension AnimatedWidgetExtension on Widget {
  /// Add fade in animation
  Widget fadeIn({
    Duration duration = AppAnimations.standard,
    Curve curve = AppAnimations.standardCurve,
  }) {
    return AppAnimations.fadeIn(this, duration: duration, curve: curve);
  }
  
  /// Add slide in animation
  Widget slideIn({
    Duration duration = AppAnimations.standard,
    Offset begin = const Offset(0, 0.3),
  }) {
    return AppAnimations.slideIn(this, duration: duration, begin: begin);
  }
  
  /// Add scale in animation
  Widget scaleIn({
    Duration duration = AppAnimations.scale,
    Curve curve = AppAnimations.emphasizedCurve,
  }) {
    return AppAnimations.scaleIn(this, duration: duration, curve: curve);
  }
  
  /// Add combined fade + slide animation
  Widget fadeSlideIn({
    Duration duration = AppAnimations.standard,
  }) {
    return AppAnimations.fadeSlideIn(this, duration: duration);
  }
}
