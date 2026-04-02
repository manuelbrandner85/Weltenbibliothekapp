import 'package:flutter/material.dart';

/// 🎬 SLIDE FADE TRANSITION - Smooth Slide + Fade Animation
class SlideFadeTransition extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Offset beginOffset;
  final Curve curve;
  final bool animate;
  
  const SlideFadeTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.beginOffset = const Offset(0, 0.3),
    this.curve = Curves.easeOutCubic,
    this.animate = true,
  });
  
  @override
  Widget build(BuildContext context) {
    if (!animate) return child;
    
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(
            beginOffset.dx * (1 - value),
            beginOffset.dy * (1 - value),
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
}

/// 🌊 SCALE FADE TRANSITION - Scale + Fade Animation
class ScaleFadeTransition extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final double beginScale;
  final Curve curve;
  final bool animate;
  
  const ScaleFadeTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.beginScale = 0.8,
    this.curve = Curves.easeOutCubic,
    this.animate = true,
  });
  
  @override
  Widget build(BuildContext context) {
    if (!animate) return child;
    
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
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
}

/// 💫 STAGGERED ANIMATION LIST - Liste mit Stagger-Effekt
class StaggeredAnimationList extends StatelessWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final Duration itemDuration;
  final Axis direction;
  
  const StaggeredAnimationList({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.itemDuration = const Duration(milliseconds: 300),
    this.direction = Axis.vertical,
  });
  
  @override
  Widget build(BuildContext context) {
    return direction == Axis.vertical
        ? Column(
            children: children.asMap().entries.map((entry) {
              return SlideFadeTransition(
                duration: itemDuration,
                beginOffset: Offset(0, 0.2),
                child: AnimatedBuilder(
                  animation: AlwaysStoppedAnimation(entry.key * staggerDelay.inMilliseconds / 1000),
                  builder: (context, child) {
                    return FutureBuilder(
                      future: Future.delayed(Duration(milliseconds: entry.key * staggerDelay.inMilliseconds)),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          return entry.value;
                        }
                        return Opacity(
                          opacity: 0,
                          child: entry.value,
                        );
                      },
                    );
                  },
                ),
              );
            }).toList(),
          )
        : Row(
            children: children.asMap().entries.map((entry) {
              return SlideFadeTransition(
                duration: itemDuration,
                beginOffset: Offset(0.2, 0),
                child: AnimatedBuilder(
                  animation: AlwaysStoppedAnimation(entry.key * staggerDelay.inMilliseconds / 1000),
                  builder: (context, child) {
                    return FutureBuilder(
                      future: Future.delayed(Duration(milliseconds: entry.key * staggerDelay.inMilliseconds)),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          return entry.value;
                        }
                        return Opacity(
                          opacity: 0,
                          child: entry.value,
                        );
                      },
                    );
                  },
                ),
              );
            }).toList(),
          );
  }
}

/// ✨ BOUNCE SCALE BUTTON - Button mit Bounce-Effekt
class BounceScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;
  
  const BounceScaleButton({
    super.key,
    required this.child,
    this.onTap,
    this.duration = const Duration(milliseconds: 150),
  });
  
  @override
  State<BounceScaleButton> createState() => _BounceScaleButtonState();
}

class _BounceScaleButtonState extends State<BounceScaleButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.9), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.05), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
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
      onTap: () {
        _controller.forward(from: 0);
        widget.onTap?.call();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// 🎪 EXPANDABLE SECTION - Expandierbarer Bereich mit Animation
class ExpandableSection extends StatefulWidget {
  final Widget header;
  final Widget child;
  final bool initiallyExpanded;
  final Duration duration;
  
  const ExpandableSection({
    super.key,
    required this.header,
    required this.child,
    this.initiallyExpanded = false,
    this.duration = const Duration(milliseconds: 300),
  });
  
  @override
  State<ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<ExpandableSection> with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _iconAnimation;
  
  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    
    _iconAnimation = Tween<double>(begin: 0, end: 0.5).animate(_animation);
    
    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: _toggle,
          child: Row(
            children: [
              Expanded(child: widget.header),
              RotationTransition(
                turns: _iconAnimation,
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        SizeTransition(
          sizeFactor: _animation,
          child: widget.child,
        ),
      ],
    );
  }
}
