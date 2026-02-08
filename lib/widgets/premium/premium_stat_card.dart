import 'package:flutter/material.dart';
import 'dart:ui';
import '../../design/premium_design_system.dart';

/// PREMIUM STAT CARD
/// Glassmorphic card for displaying statistics with smooth animations
class PremiumStatCard extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const PremiumStatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.gradient,
    this.onTap,
  });

  @override
  State<PremiumStatCard> createState() => _PremiumStatCardState();
}

class _PremiumStatCardState extends State<PremiumStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: PremiumDesignSystem.durationMedium,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: PremiumDesignSystem.curveSmooth,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: PremiumDesignSystem.curveDefault,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            decoration: PremiumDesignSystem.glassDecoration(
              color: widget.color,
              blur: 15,
              opacity: 0.15,
              borderOpacity: 0.3,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(PremiumDesignSystem.radiusLarge),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(PremiumDesignSystem.space4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon with gradient background
                      Container(
                        padding: const EdgeInsets.all(PremiumDesignSystem.space3),
                        decoration: BoxDecoration(
                          gradient: widget.gradient ??
                              LinearGradient(
                                colors: [
                                  widget.color.withValues(alpha: 0.3),
                                  widget.color.withValues(alpha: 0.1),
                                ],
                              ),
                          borderRadius: BorderRadius.circular(
                              PremiumDesignSystem.radiusMedium),
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: PremiumDesignSystem.space3),

                      // Title
                      Text(
                        widget.title,
                        style: PremiumDesignSystem.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: PremiumDesignSystem.space1),

                      // Value with gradient text
                      ShaderMask(
                        shaderCallback: (bounds) => (widget.gradient ??
                                LinearGradient(
                                  colors: [widget.color, widget.color.withValues(alpha: 0.7)],
                                ))
                            .createShader(bounds),
                        child: Text(
                          widget.value,
                          style: PremiumDesignSystem.headingLarge.copyWith(
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Subtitle (optional)
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: PremiumDesignSystem.space1),
                        Text(
                          widget.subtitle!,
                          style: PremiumDesignSystem.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// PREMIUM PROGRESS CARD
/// Card showing progress with animated progress bar
class PremiumProgressCard extends StatefulWidget {
  final String title;
  final double progress; // 0.0 to 1.0
  final String progressText;
  final IconData icon;
  final Color color;
  final Gradient? gradient;

  const PremiumProgressCard({
    super.key,
    required this.title,
    required this.progress,
    required this.progressText,
    required this.icon,
    required this.color,
    this.gradient,
  });

  @override
  State<PremiumProgressCard> createState() => _PremiumProgressCardState();
}

class _PremiumProgressCardState extends State<PremiumProgressCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: PremiumDesignSystem.durationSlow,
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: PremiumDesignSystem.curveSmooth,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PremiumDesignSystem.glassDecoration(
        color: widget.color,
        blur: 15,
        opacity: 0.15,
        borderOpacity: 0.3,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PremiumDesignSystem.radiusLarge),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(PremiumDesignSystem.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(PremiumDesignSystem.space2),
                      decoration: BoxDecoration(
                        gradient: widget.gradient ??
                            LinearGradient(
                              colors: [
                                widget.color.withValues(alpha: 0.3),
                                widget.color.withValues(alpha: 0.1),
                              ],
                            ),
                        borderRadius: BorderRadius.circular(
                            PremiumDesignSystem.radiusSmall),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: PremiumDesignSystem.space3),

                    // Title
                    Expanded(
                      child: Text(
                        widget.title,
                        style: PremiumDesignSystem.bodyMedium.copyWith(
                          color: PremiumDesignSystem.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Progress text
                    Text(
                      widget.progressText,
                      style: PremiumDesignSystem.bodySmall.copyWith(
                        color: widget.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: PremiumDesignSystem.space3),

                // Progress bar
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(
                          PremiumDesignSystem.radiusFull),
                      child: Stack(
                        children: [
                          // Background
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: widget.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(
                                  PremiumDesignSystem.radiusFull),
                            ),
                          ),

                          // Progress
                          FractionallySizedBox(
                            widthFactor: _progressAnimation.value,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                gradient: widget.gradient ??
                                    LinearGradient(
                                      colors: [
                                        widget.color,
                                        widget.color.withValues(alpha: 0.7),
                                      ],
                                    ),
                                borderRadius: BorderRadius.circular(
                                    PremiumDesignSystem.radiusFull),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
