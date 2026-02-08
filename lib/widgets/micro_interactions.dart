import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

/// 💎 HOVER GLOW CARD - Card mit Hover-Glow-Effekt (für Desktop/Web)
class HoverGlowCard extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double glowRadius;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  
  const HoverGlowCard({
    super.key,
    required this.child,
    this.glowColor = Colors.blue,
    this.glowRadius = 20,
    this.padding,
    this.borderRadius,
    this.onTap,
  });
  
  @override
  State<HoverGlowCard> createState() => _HoverGlowCardState();
}

class _HoverGlowCardState extends State<HoverGlowCard> {
  bool _isHovering = false;
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: widget.padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            border: Border.all(
              color: _isHovering
                  ? widget.glowColor.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.1),
              width: _isHovering ? 2 : 1,
            ),
            boxShadow: _isHovering
                ? [
                    BoxShadow(
                      color: widget.glowColor.withValues(alpha: 0.4),
                      blurRadius: widget.glowRadius,
                      spreadRadius: widget.glowRadius / 4,
                    ),
                  ]
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// 🎯 RIPPLE EFFECT BUTTON - Custom Ripple Animation
class RippleEffectButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color rippleColor;
  final Duration duration;
  
  const RippleEffectButton({
    super.key,
    required this.child,
    this.onTap,
    this.rippleColor = Colors.white,
    this.duration = const Duration(milliseconds: 600),
  });
  
  @override
  State<RippleEffectButton> createState() => _RippleEffectButtonState();
}

class _RippleEffectButtonState extends State<RippleEffectButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset? _tapPosition;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _handleTap(TapDownDetails details) {
    setState(() {
      _tapPosition = details.localPosition;
    });
    _controller.forward(from: 0);
    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTap,
      child: CustomPaint(
        painter: _RipplePainter(
          animation: _controller,
          tapPosition: _tapPosition,
          color: widget.rippleColor,
        ),
        child: widget.child,
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final Animation<double> animation;
  final Offset? tapPosition;
  final Color color;
  
  _RipplePainter({
    required this.animation,
    required this.tapPosition,
    required this.color,
  }) : super(repaint: animation);
  
  @override
  void paint(Canvas canvas, Size size) {
    if (tapPosition == null) return;
    
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height);
    final radius = maxRadius * animation.value;
    final opacity = (1 - animation.value).clamp(0.0, 1.0);
    
    final paint = Paint()
      ..color = color.withValues(alpha: opacity * 0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(tapPosition!, radius, paint);
  }
  
  @override
  bool shouldRepaint(_RipplePainter oldDelegate) => true;
}

/// ✨ SHIMMER EFFECT - Animated Shimmer für Loading States
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;
  
  const ShimmerEffect({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFF1A1A1A),
    this.highlightColor = const Color(0xFF2A2A2A),
    this.duration = const Duration(milliseconds: 1500),
  });
  
  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
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
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

/// 🌊 WAVE ANIMATION - Wellenförmige Animation
class WaveAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double waveHeight;
  
  const WaveAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 2000),
    this.waveHeight = 10,
  });
  
  @override
  State<WaveAnimation> createState() => _WaveAnimationState();
}

class _WaveAnimationState extends State<WaveAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
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
        return Transform.translate(
          offset: Offset(
            0,
            math.sin(_controller.value * 2 * math.pi) * widget.waveHeight,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// 💫 PARTICLE EFFECT - Partikel-Animation für Erfolgs-Feedback
class ParticleEffect extends StatefulWidget {
  final bool trigger;
  final Widget child;
  final Color particleColor;
  final int particleCount;
  
  const ParticleEffect({
    super.key,
    required this.trigger,
    required this.child,
    this.particleColor = Colors.yellow,
    this.particleCount = 20,
  });
  
  @override
  State<ParticleEffect> createState() => _ParticleEffectState();
}

class _ParticleEffectState extends State<ParticleEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _initParticles();
  }
  
  void _initParticles() {
    _particles.clear();
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(Particle());
    }
  }
  
  @override
  void didUpdateWidget(ParticleEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _controller.forward(from: 0);
      HapticFeedback.mediumImpact();
    }
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
        if (widget.trigger)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ParticlePainter(
                    particles: _particles,
                    animation: _controller,
                    color: widget.particleColor,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class Particle {
  final double angle = math.Random().nextDouble() * 2 * math.pi;
  final double speed = 50 + math.Random().nextDouble() * 100;
  final double size = 2 + math.Random().nextDouble() * 4;
}

class _ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Animation<double> animation;
  final Color color;
  
  _ParticlePainter({
    required this.particles,
    required this.animation,
    required this.color,
  }) : super(repaint: animation);
  
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    for (final particle in particles) {
      final distance = particle.speed * animation.value;
      final x = centerX + math.cos(particle.angle) * distance;
      final y = centerY + math.sin(particle.angle) * distance;
      final opacity = (1 - animation.value).clamp(0.0, 1.0);
      
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }
  
  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}

/// 🎪 FLIP CARD ANIMATION - Card Flip Effekt
class FlipCardAnimation extends StatefulWidget {
  final Widget front;
  final Widget back;
  final Duration duration;
  
  const FlipCardAnimation({
    super.key,
    required this.front,
    required this.back,
    this.duration = const Duration(milliseconds: 600),
  });
  
  @override
  State<FlipCardAnimation> createState() => _FlipCardAnimationState();
}

class _FlipCardAnimationState extends State<FlipCardAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showFront = true;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void flip() {
    if (_controller.isAnimating) return;
    
    HapticFeedback.selectionClick();
    if (_showFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() => _showFront = !_showFront);
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: flip,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * math.pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);
          
          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: angle < math.pi / 2 ? widget.front : Transform(
              transform: Matrix4.identity()..rotateY(math.pi),
              alignment: Alignment.center,
              child: widget.back,
            ),
          );
        },
      ),
    );
  }
}

/// 🌈 RAINBOW BORDER ANIMATION - Animierte Rainbow Border
class RainbowBorderAnimation extends StatefulWidget {
  final Widget child;
  final double borderWidth;
  final Duration duration;
  final BorderRadius? borderRadius;
  
  const RainbowBorderAnimation({
    super.key,
    required this.child,
    this.borderWidth = 2,
    this.duration = const Duration(seconds: 3),
    this.borderRadius,
  });
  
  @override
  State<RainbowBorderAnimation> createState() => _RainbowBorderAnimationState();
}

class _RainbowBorderAnimationState extends State<RainbowBorderAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
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
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            border: Border.all(
              width: widget.borderWidth,
              color: HSLColor.fromAHSL(
                1.0,
                _controller.value * 360,
                1.0,
                0.5,
              ).toColor(),
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// 🎯 PROGRESS RING - Animierter Progress Ring
class ProgressRingAnimation extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color color;
  final Color backgroundColor;
  
  const ProgressRingAnimation({
    super.key,
    required this.progress,
    this.size = 60,
    this.strokeWidth = 6,
    this.color = Colors.blue,
    this.backgroundColor = Colors.grey,
  });
  
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return CustomPaint(
          size: Size(size, size),
          painter: _ProgressRingPainter(
            progress: value,
            strokeWidth: strokeWidth,
            color: color,
            backgroundColor: backgroundColor,
          ),
        );
      },
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;
  final Color backgroundColor;
  
  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.backgroundColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor.withValues(alpha: 0.3)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, bgPaint);
    
    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }
  
  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
