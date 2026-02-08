import 'dart:ui';
import 'package:flutter/material.dart';
import '../../design/premium_design_system.dart';

/// Premium Glassmorphism Card Widget
/// Beautiful frosted-glass effect with blur and transparency
class GlassCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double? blur;
  final double? opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadows;
  
  const GlassCard({
    super.key,
    required this.child,
    this.color,
    this.blur = 10,
    this.opacity = 0.1,
    this.borderRadius,
    this.padding,
    this.margin,
    this.onTap,
    this.shadows,
  });
  
  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? PremiumDesignSystem.cardDark;
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(PremiumDesignSystem.radiusLarge);
    
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur!, sigmaY: blur!),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: effectiveBorderRadius,
              child: Container(
                padding: padding ?? const EdgeInsets.all(PremiumDesignSystem.space4),
                decoration: BoxDecoration(
                  color: effectiveColor.withValues(alpha: opacity!),
                  borderRadius: effectiveBorderRadius,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: shadows ?? PremiumDesignSystem.shadowMedium,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated Glass Card with hover effects
class AnimatedGlassCard extends StatefulWidget {
  final Widget child;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  
  const AnimatedGlassCard({
    super.key,
    required this.child,
    this.color,
    this.borderRadius,
    this.padding,
    this.margin,
    this.onTap,
  });
  
  @override
  State<AnimatedGlassCard> createState() => _AnimatedGlassCardState();
}

class _AnimatedGlassCardState extends State<AnimatedGlassCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: PremiumDesignSystem.durationMedium,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: PremiumDesignSystem.curveSmooth),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.1, end: 0.15).animate(
      CurvedAnimation(parent: _controller, curve: PremiumDesignSystem.curveSmooth),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: GlassCard(
                color: widget.color,
                opacity: _opacityAnimation.value,
                borderRadius: widget.borderRadius,
                padding: widget.padding,
                margin: widget.margin,
                onTap: widget.onTap,
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Gradient Card with Glow Effect
class GradientGlowCard extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  
  const GradientGlowCard({
    super.key,
    required this.child,
    required this.gradient,
    this.borderRadius,
    this.padding,
    this.margin,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(PremiumDesignSystem.radiusLarge);
    
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: effectiveBorderRadius,
        boxShadow: [
          BoxShadow(
            color: (gradient as LinearGradient).colors.first.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveBorderRadius,
          child: Container(
            padding: padding ?? const EdgeInsets.all(PremiumDesignSystem.space4),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: effectiveBorderRadius,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Stat Card with Icon and Value
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;
  
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return AnimatedGlassCard(
      onTap: onTap,
      color: color.withValues(alpha: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon with gradient background
          Container(
            padding: const EdgeInsets.all(PremiumDesignSystem.space2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.3),
                  color.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(PremiumDesignSystem.radiusMedium),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: PremiumDesignSystem.space3),
          
          // Value
          Text(
            value,
            style: PremiumDesignSystem.headingLarge.copyWith(
              color: PremiumDesignSystem.textPrimary,
            ),
          ),
          const SizedBox(height: PremiumDesignSystem.space1),
          
          // Label
          Text(
            label,
            style: PremiumDesignSystem.bodySmall.copyWith(
              color: PremiumDesignSystem.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
