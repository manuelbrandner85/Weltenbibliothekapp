import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'animation_system_v2.dart';

/// 🎯 MICRO-INTERACTIONS SYSTEM
/// Subtle feedback effects for user actions
/// Based on Apple & Google design guidelines

class MicroInteractions {
  MicroInteractions._();
  
  // ============================================
  // HAPTIC FEEDBACK
  // ============================================
  
  /// Light impact (button press, toggle)
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }
  
  /// Medium impact (selection, swipe action)
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }
  
  /// Heavy impact (important action, error)
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }
  
  /// Selection tick (scrolling through list)
  static void selectionClick() {
    HapticFeedback.selectionClick();
  }
  
  /// Vibrate (notification, alert)
  static void vibrate() {
    HapticFeedback.vibrate();
  }
  
  // ============================================
  // ANIMATED WIDGETS WITH FEEDBACK
  // ============================================
  
  /// Interactive Button with press animation + haptic
  static Widget button({
    required Widget child,
    required VoidCallback onPressed,
    bool enableHaptic = true,
    Color? backgroundColor,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
  }) {
    return _InteractiveButton(
      onPressed: onPressed,
      enableHaptic: enableHaptic,
      backgroundColor: backgroundColor,
      padding: padding,
      borderRadius: borderRadius,
      child: child,
    );
  }
  
  /// Toggle Switch with animation
  static Widget toggle({
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? activeColor,
    Color? inactiveColor,
  }) {
    return _AnimatedToggle(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor,
      inactiveColor: inactiveColor,
    );
  }
  
  /// Checkbox with smooth animation
  static Widget checkbox({
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? activeColor,
  }) {
    return _AnimatedCheckbox(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor,
    );
  }
  
  /// Like button with heart animation
  static Widget likeButton({
    required bool isLiked,
    required VoidCallback onTap,
    Color? activeColor,
    Color? inactiveColor,
    double size = 24,
  }) {
    return _AnimatedLikeButton(
      isLiked: isLiked,
      onTap: onTap,
      activeColor: activeColor,
      inactiveColor: inactiveColor,
      size: size,
    );
  }
}

// ============================================
// INTERACTIVE BUTTON
// ============================================

class _InteractiveButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final bool enableHaptic;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;

  const _InteractiveButton({
    required this.child,
    required this.onPressed,
    this.enableHaptic = true,
    this.backgroundColor,
    this.padding,
    this.borderRadius,
  });

  @override
  State<_InteractiveButton> createState() => _InteractiveButtonState();
}

class _InteractiveButtonState extends State<_InteractiveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _brightnessAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationSystem.micro,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: AnimationSystem.standard),
    );
    
    _brightnessAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
    if (widget.enableHaptic) {
      MicroInteractions.lightImpact();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 1.0 - _brightnessAnimation.value * 0.1),
                BlendMode.srcATop,
              ),
              child: Container(
                padding: widget.padding ?? const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: widget.backgroundColor ?? Colors.blue,
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                ),
                child: child,
              ),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

// ============================================
// ANIMATED TOGGLE
// ============================================

class _AnimatedToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  final Color? inactiveColor;

  const _AnimatedToggle({
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<_AnimatedToggle> createState() => _AnimatedToggleState();
}

class _AnimatedToggleState extends State<_AnimatedToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationSystem.short2,
      value: widget.value ? 1.0 : 0.0,
    );
    
    _positionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AnimationSystem.emphasized),
    );
    
    _colorAnimation = ColorTween(
      begin: widget.inactiveColor ?? Colors.grey,
      end: widget.activeColor ?? Colors.green,
    ).animate(_controller);
  }

  @override
  void didUpdateWidget(_AnimatedToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        MicroInteractions.lightImpact();
        widget.onChanged(!widget.value);
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: 50,
            height: 30,
            decoration: BoxDecoration(
              color: _colorAnimation.value,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Align(
                alignment: Alignment.lerp(
                  Alignment.centerLeft,
                  Alignment.centerRight,
                  _positionAnimation.value,
                )!,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================
// ANIMATED CHECKBOX
// ============================================

class _AnimatedCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  const _AnimatedCheckbox({
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  @override
  State<_AnimatedCheckbox> createState() => _AnimatedCheckboxState();
}

class _AnimatedCheckboxState extends State<_AnimatedCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationSystem.short2,
      value: widget.value ? 1.0 : 0.0,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AnimationSystem.emphasized),
    );
    
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void didUpdateWidget(_AnimatedCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        MicroInteractions.lightImpact();
        widget.onChanged(!widget.value);
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: widget.value
                  ? (widget.activeColor ?? Colors.blue)
                  : Colors.transparent,
              border: Border.all(
                color: widget.value
                    ? (widget.activeColor ?? Colors.blue)
                    : Colors.grey,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Icon(
                Icons.check,
                size: 16,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================
// ANIMATED LIKE BUTTON
// ============================================

class _AnimatedLikeButton extends StatefulWidget {
  final bool isLiked;
  final VoidCallback onTap;
  final Color? activeColor;
  final Color? inactiveColor;
  final double size;

  const _AnimatedLikeButton({
    required this.isLiked,
    required this.onTap,
    this.activeColor,
    this.inactiveColor,
    this.size = 24,
  });

  @override
  State<_AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<_AnimatedLikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationSystem.short2,
    );
    
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _colorAnimation = ColorTween(
      begin: widget.inactiveColor ?? Colors.grey,
      end: widget.activeColor ?? Colors.red,
    ).animate(_controller);
  }

  @override
  void didUpdateWidget(_AnimatedLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked != oldWidget.isLiked && widget.isLiked) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        MicroInteractions.lightImpact();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isLiked ? _scaleAnimation.value : 1.0,
            child: Icon(
              widget.isLiked ? Icons.favorite : Icons.favorite_border,
              size: widget.size,
              color: widget.isLiked
                  ? _colorAnimation.value
                  : (widget.inactiveColor ?? Colors.grey),
            ),
          );
        },
      ),
    );
  }
}
