import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

/// ============================================
/// ANIMATED MICRO-INTERACTIONS
/// Collection of premium animations:
/// - Heart Animation (Like Instagram)
/// - Confetti Effect
/// - Smooth Expand/Collapse
/// - Ripple Effect
/// - Floating Action
/// ============================================

/// 1. HEART FAVORITE ANIMATION
class AnimatedHeartButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onTap;
  final Color color;
  final double size;

  const AnimatedHeartButton({
    super.key,
    required this.isFavorite,
    required this.onTap,
    this.color = Colors.red,
    this.size = 30,
  });

  @override
  State<AnimatedHeartButton> createState() => _AnimatedHeartButtonState();
}

class _AnimatedHeartButtonState extends State<AnimatedHeartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.4)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.4, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    _controller.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value * math.pi,
              child: Icon(
                widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: widget.isFavorite ? widget.color : Colors.grey,
                size: widget.size,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 2. CONFETTI CELEBRATION EFFECT
class ConfettiWidget extends StatefulWidget {
  final bool show;
  final Widget child;

  const ConfettiWidget({
    super.key,
    required this.show,
    required this.child,
  });

  @override
  State<ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<ConfettiWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(() {
        setState(() {});
      });

    if (widget.show) {
      _generateParticles();
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ConfettiWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _generateParticles();
      _controller.forward(from: 0);
    }
  }

  void _generateParticles() {
    _particles.clear();
    for (int i = 0; i < 50; i++) {
      _particles.add(Particle(
        color: _randomColor(),
        size: math.Random().nextDouble() * 8 + 4,
        startX: math.Random().nextDouble(),
        startY: -0.1,
        endX: math.Random().nextDouble(),
        endY: math.Random().nextDouble() * 1.5 + 0.5,
        rotation: math.Random().nextDouble() * math.pi * 4,
      ));
    }
  }

  Color _randomColor() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
    ];
    return colors[math.Random().nextInt(colors.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.show)
          Positioned.fill(
            child: CustomPaint(
              painter: ConfettiPainter(
                particles: _particles,
                progress: _controller.value,
              ),
            ),
          ),
      ],
    );
  }
}

class Particle {
  final Color color;
  final double size;
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double rotation;

  Particle({
    required this.color,
    required this.size,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.rotation,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final x = particle.startX * size.width +
          (particle.endX - particle.startX) * size.width * progress;
      final y = particle.startY * size.height +
          (particle.endY - particle.startY) * size.height * progress;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation * progress);

      final paint = Paint()
        ..color = particle.color.withValues(alpha: 1 - progress)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset.zero, particle.size, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}

/// 3. SMOOTH EXPAND/COLLAPSE ANIMATION
class SmoothExpandableCard extends StatefulWidget {
  final Widget title;
  final Widget content;
  final Color? backgroundColor;
  final bool initiallyExpanded;

  const SmoothExpandableCard({
    super.key,
    required this.title,
    required this.content,
    this.backgroundColor,
    this.initiallyExpanded = false,
  });

  @override
  State<SmoothExpandableCard> createState() => _SmoothExpandableCardState();
}

class _SmoothExpandableCardState extends State<SmoothExpandableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _iconRotation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _iconRotation = Tween<double>(begin: 0, end: 0.5).animate(_controller);

    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _toggleExpand,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: widget.title),
                  RotationTransition(
                    turns: _iconRotation,
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: widget.content,
            ),
          ),
        ],
      ),
    );
  }
}

/// 4. RIPPLE EFFECT BUTTON
class RippleEffectButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color rippleColor;
  final double size;

  const RippleEffectButton({
    super.key,
    required this.child,
    required this.onTap,
    this.rippleColor = Colors.blue,
    this.size = 60,
  });

  @override
  State<RippleEffectButton> createState() => _RippleEffectButtonState();
}

class _RippleEffectButtonState extends State<RippleEffectButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0);
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  width: widget.size * _animation.value,
                  height: widget.size * _animation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.rippleColor.withValues(alpha:
                      0.3 * (1 - _animation.value),
                    ),
                  ),
                );
              },
            ),
            widget.child,
          ],
        ),
      ),
    );
  }
}

/// 5. LOADING SKELETON
class LoadingSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const LoadingSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(-1.0 - _controller.value * 2, 0),
              end: Alignment(1.0 - _controller.value * 2, 0),
              colors: const [
                Color(0xFFEEEEEE),
                Color(0xFFF5F5F5),
                Color(0xFFEEEEEE),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 6. PULSE ANIMATION
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.minScale = 0.95,
    this.maxScale = 1.05,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
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
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}
