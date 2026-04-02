import 'package:flutter/material.dart';

/// 🎨 GRADIENT ICON - Premium Icons mit Gradient-Effekt
class GradientIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final List<Color> colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  
  const GradientIcon({
    super.key,
    required this.icon,
    this.size = 24,
    required this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });
  
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: colors,
        begin: begin,
        end: end,
      ).createShader(bounds),
      child: Icon(
        icon,
        size: size,
        color: Colors.white,
      ),
    );
  }
}

/// 🎭 ANIMATED GRADIENT ICON - Animierter Gradient-Icon
class AnimatedGradientIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final List<Color> colors;
  final Duration duration;
  
  const AnimatedGradientIcon({
    super.key,
    required this.icon,
    this.size = 24,
    required this.colors,
    this.duration = const Duration(seconds: 3),
  });
  
  @override
  State<AnimatedGradientIcon> createState() => _AnimatedGradientIconState();
}

class _AnimatedGradientIconState extends State<AnimatedGradientIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: widget.colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            transform: GradientRotation(_animation.value * 2 * 3.14159),
          ).createShader(bounds),
          child: Icon(
            widget.icon,
            size: widget.size,
            color: Colors.white,
          ),
        );
      },
    );
  }
}

/// 💫 PULSING ICON - Icon mit Puls-Animation
class PulsingIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;
  final Duration duration;
  
  const PulsingIcon({
    super.key,
    required this.icon,
    this.size = 24,
    required this.color,
    this.duration = const Duration(milliseconds: 1000),
  });
  
  @override
  State<PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<PulsingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Icon(
        widget.icon,
        size: widget.size,
        color: widget.color,
      ),
    );
  }
}

/// 🌟 GLOWING ICON - Icon mit Glow-Effekt
class GlowingIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final double glowRadius;
  
  const GlowingIcon({
    super.key,
    required this.icon,
    this.size = 24,
    required this.color,
    this.glowRadius = 10,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: glowRadius,
            spreadRadius: glowRadius / 2,
          ),
        ],
      ),
      child: Icon(
        icon,
        size: size,
        color: color,
      ),
    );
  }
}

/// 🎯 FEATURE ICON BUTTON - Premium Feature Button mit Gradient
class FeatureIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final List<Color> gradientColors;
  final bool isActive;
  
  const FeatureIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.gradientColors,
    this.isActive = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isActive ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? gradientColors.first.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.2),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
