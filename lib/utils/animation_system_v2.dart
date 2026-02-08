import 'package:flutter/material.dart';

/// 🎨 WELTENBIBLIOTHEK - ENHANCED ANIMATION SYSTEM V2
/// Professional animation timing and easing based on Material Design 3
/// and Apple Human Interface Guidelines

class AnimationSystem {
  AnimationSystem._();
  
  // ============================================
  // DURATION STANDARDS (Material Design 3)
  // ============================================
  
  /// Micro-interactions (50-100ms) - Button press, checkbox toggle
  static const Duration instant = Duration(milliseconds: 50);
  static const Duration micro = Duration(milliseconds: 100);
  
  /// Short animations (150-250ms) - Icons, small elements
  static const Duration short1 = Duration(milliseconds: 150);
  static const Duration short2 = Duration(milliseconds: 200);
  static const Duration short3 = Duration(milliseconds: 250);
  
  /// Medium animations (300-400ms) - Cards, lists, standard transitions
  static const Duration medium1 = Duration(milliseconds: 300);
  static const Duration medium2 = Duration(milliseconds: 350);
  static const Duration medium3 = Duration(milliseconds: 400);
  
  /// Long animations (450-600ms) - Page transitions, complex animations
  static const Duration long1 = Duration(milliseconds: 450);
  static const Duration long2 = Duration(milliseconds: 500);
  static const Duration long3 = Duration(milliseconds: 600);
  
  /// Extra long (700-1000ms) - Emphasis, special effects
  static const Duration extraLong1 = Duration(milliseconds: 700);
  static const Duration extraLong2 = Duration(milliseconds: 900);
  
  // ============================================
  // MATERIAL DESIGN 3 CURVES
  // ============================================
  
  /// Standard easing - Most common, smooth in and out
  static const Curve standard = Curves.easeInOutCubicEmphasized;
  
  /// Standard accelerate - Element enters screen
  static const Curve standardAccelerate = Curves.easeInCubic;
  
  /// Standard decelerate - Element exits screen
  static const Curve standardDecelerate = Curves.easeOutCubic;
  
  /// Emphasized - Important actions, attention-grabbing
  static const Curve emphasized = Curves.easeOutBack;
  
  /// Emphasized decelerate - Smooth landing
  static const Curve emphasizedDecelerate = Curves.easeOutQuint;
  
  /// Emphasized accelerate - Quick start
  static const Curve emphasizedAccelerate = Curves.easeInQuint;
  
  /// Legacy (for compatibility)
  static const Curve legacy = Curves.fastOutSlowIn;
  
  // ============================================
  // CUSTOM CURVES
  // ============================================
  
  /// Smooth cubic bezier (Apple-style)
  static const Curve smooth = Cubic(0.4, 0.0, 0.2, 1.0);
  
  /// Snappy bounce
  static const Curve bounce = Curves.elasticOut;
  
  /// Subtle spring
  static const Curve spring = Cubic(0.34, 1.56, 0.64, 1.0);
  
  // ============================================
  // ANIMATED WIDGETS
  // ============================================
  
  /// Fade In Animation
  static Widget fadeIn({
    required Widget child,
    Duration? duration,
    Curve? curve,
    double? delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration ?? medium1,
      curve: curve ?? standardDecelerate,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: child,
      ),
      child: child,
    );
  }
  
  /// Slide + Fade In
  static Widget slideFadeIn({
    required Widget child,
    Offset begin = const Offset(0, 20),
    Duration? duration,
    Curve? curve,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration ?? medium2,
      curve: curve ?? emphasizedDecelerate,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(
            begin.dx * (1 - value),
            begin.dy * (1 - value),
          ),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
  
  /// Scale + Fade In
  static Widget scaleFadeIn({
    required Widget child,
    double beginScale = 0.9,
    Duration? duration,
    Curve? curve,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration ?? short3,
      curve: curve ?? emphasizedDecelerate,
      builder: (context, value, child) {
        final scale = beginScale + (1.0 - beginScale) * value;
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
  
  /// Shimmer Loading Effect
  static Widget shimmer({
    required Widget child,
    Duration? duration,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration ?? Duration(milliseconds: 1500),
      curve: Curves.linear,
      builder: (context, value, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 - value * 2, 0),
              end: Alignment(1.0 - value * 2, 0),
              colors: [
                baseColor ?? Colors.grey.shade300,
                highlightColor ?? Colors.grey.shade100,
                baseColor ?? Colors.grey.shade300,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: child,
    );
  }
  
  // ============================================
  // MICRO-INTERACTIONS
  // ============================================
  
  /// Button Press Animation
  static Widget buttonPress({
    required Widget child,
    required VoidCallback onPressed,
    double scaleDown = 0.95,
  }) {
    return _PressableWidget(
      scaleDown: scaleDown,
      onPressed: onPressed,
      child: child,
    );
  }
  
  /// Ripple Effect (Material style)
  static Widget ripple({
    required Widget child,
    required VoidCallback onTap,
    Color? color,
    BorderRadius? borderRadius,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: color?.withValues(alpha: 0.3),
        highlightColor: color?.withValues(alpha: 0.1),
        child: child,
      ),
    );
  }
}

// ============================================
// PRESSABLE WIDGET
// ============================================

class _PressableWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final double scaleDown;

  const _PressableWidget({
    required this.child,
    required this.onPressed,
    required this.scaleDown,
  });

  @override
  State<_PressableWidget> createState() => _PressableWidgetState();
}

class _PressableWidgetState extends State<_PressableWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationSystem.micro,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AnimationSystem.standard,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

// ============================================
// PAGE ROUTE BUILDERS
// ============================================

class EnhancedPageRoutes {
  EnhancedPageRoutes._();
  
  /// Slide from Right (iOS style)
  static Route<T> slideRight<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: AnimationSystem.medium2,
      reverseTransitionDuration: AnimationSystem.medium2,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end);
        final offsetAnimation = animation.drive(
          tween.chain(CurveTween(curve: AnimationSystem.emphasized)),
        );
        
        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }
  
  /// Fade + Scale (Material style)
  static Route<T> fadeScale<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: AnimationSystem.medium1,
      reverseTransitionDuration: AnimationSystem.short3,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: AnimationSystem.emphasizedDecelerate,
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }
  
  /// Slide Up (Bottom Sheet style)
  static Route<T> slideUp<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: AnimationSystem.medium2,
      reverseTransitionDuration: AnimationSystem.medium1,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end);
        final offsetAnimation = animation.drive(
          tween.chain(CurveTween(curve: AnimationSystem.emphasizedDecelerate)),
        );
        
        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }
}

// ============================================
// STAGGERED ANIMATION HELPER
// ============================================

class StaggeredAnimation {
  /// Create staggered list animation
  static Widget staggeredList({
    required List<Widget> children,
    Duration? delay,
    Duration? itemDuration,
    Curve? curve,
  }) {
    final delayDuration = delay ?? AnimationSystem.micro;
    final animDuration = itemDuration ?? AnimationSystem.short3;
    
    return Column(
      children: List.generate(children.length, (index) {
        return AnimationSystem.slideFadeIn(
          duration: animDuration,
          curve: curve ?? AnimationSystem.emphasizedDecelerate,
          child: children[index],
        );
      }),
    );
  }
}
