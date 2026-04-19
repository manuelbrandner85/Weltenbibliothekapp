import 'package:flutter/material.dart';
import 'animation_system_v2.dart';

/// 🎨 ENHANCED LOADING STATES
/// Professional skeleton loaders and progress indicators

class EnhancedLoading {
  EnhancedLoading._();
  
  // ============================================
  // SKELETON LOADERS
  // ============================================
  
  /// Card Skeleton Loader
  static Widget cardSkeleton({
    double? height,
    double? width,
    BorderRadius? borderRadius,
  }) {
    return _SkeletonBox(
      height: height ?? 200,
      width: width,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
    );
  }
  
  /// List Item Skeleton
  static Widget listItemSkeleton({
    bool showAvatar = true,
    int lines = 2,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          if (showAvatar) ...[
            _SkeletonBox(
              height: 48,
              width: 48,
              borderRadius: BorderRadius.circular(24),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(lines, (index) {
                final isLast = index == lines - 1;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                  child: _SkeletonBox(
                    height: 16,
                    width: isLast ? null : double.infinity,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Text Line Skeleton
  static Widget textLineSkeleton({
    double? width,
    double height = 16,
  }) {
    return _SkeletonBox(
      height: height,
      width: width,
      borderRadius: BorderRadius.circular(4),
    );
  }
  
  /// Image Skeleton
  static Widget imageSkeleton({
    required double width,
    required double height,
    BorderRadius? borderRadius,
  }) {
    return _SkeletonBox(
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
    );
  }
  
  // ============================================
  // PROGRESS INDICATORS
  // ============================================
  
  /// Circular Progress with custom colors
  static Widget circularProgress({
    Color? color,
    double? size,
    double? strokeWidth,
  }) {
    return SizedBox(
      width: size ?? 24,
      height: size ?? 24,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth ?? 3,
        valueColor: color != null
            ? AlwaysStoppedAnimation<Color>(color)
            : null,
      ),
    );
  }
  
  /// Linear Progress with label
  static Widget linearProgress({
    required double value,
    String? label,
    Color? backgroundColor,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: backgroundColor ?? Colors.grey.shade200,
            valueColor: valueColor != null
                ? AlwaysStoppedAnimation<Color>(valueColor)
                : null,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
  
  /// Dots Loading Indicator
  static Widget dotsLoading({
    Color? color,
    double size = 8,
  }) {
    return _DotsLoadingIndicator(
      color: color ?? Colors.blue,
      size: size,
    );
  }
  
  /// Pulse Loading
  static Widget pulseLoading({
    required Widget child,
  }) {
    return _PulseLoading(child: child);
  }
  
  // ============================================
  // LOADING OVERLAYS
  // ============================================
  
  /// Full Screen Loading Overlay
  static Widget fullScreenLoading({
    String? message,
    Color? backgroundColor,
  }) {
    return Container(
      color: backgroundColor ?? Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            circularProgress(color: Colors.white, size: 48),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Loading Card
  static Widget loadingCard({
    String? title,
    String? subtitle,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            circularProgress(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// SKELETON BOX
// ============================================

class _SkeletonBox extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius borderRadius;

  const _SkeletonBox({
    required this.height,
    this.width,
    required this.borderRadius,
  });

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

// ============================================
// DOTS LOADING INDICATOR
// ============================================

class _DotsLoadingIndicator extends StatefulWidget {
  final Color color;
  final double size;

  const _DotsLoadingIndicator({
    required this.color,
    required this.size,
  });

  @override
  State<_DotsLoadingIndicator> createState() => _DotsLoadingIndicatorState();
}

class _DotsLoadingIndicatorState extends State<_DotsLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationSystem.extraLong1,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = (_controller.value - delay).clamp(0.0, 1.0);
            final scale = 0.7 + (0.3 * (1 - (value - 0.5).abs() * 2));
            
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.size * 0.3),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: scale),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

// ============================================
// PULSE LOADING
// ============================================

class _PulseLoading extends StatefulWidget {
  final Widget child;

  const _PulseLoading({required this.child});

  @override
  State<_PulseLoading> createState() => _PulseLoadingState();
}

class _PulseLoadingState extends State<_PulseLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationSystem.extraLong1,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.7, end: 1.0).animate(
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ============================================
// LOADING STATE BUILDER
// ============================================

class LoadingStateBuilder<T> extends StatelessWidget {
  final Future<T>? future;
  final T? data;
  final Widget Function(BuildContext, T) builder;
  final Widget Function(BuildContext)? loadingBuilder;
  final Widget Function(BuildContext, Object)? errorBuilder;
  final Widget Function(BuildContext)? emptyBuilder;

  const LoadingStateBuilder({
    super.key,
    this.future,
    this.data,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (data != null) {
      return builder(context, data as T);
    }

    if (future == null) {
      return emptyBuilder?.call(context) ?? const SizedBox.shrink();
    }

    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return builder(context, snapshot.data as T);
        }
        
        if (snapshot.hasError) {
          return errorBuilder?.call(context, snapshot.error!) ??
              Center(
                child: Text('Error: ${snapshot.error}'),
              );
        }
        
        return loadingBuilder?.call(context) ??
            Center(
              child: EnhancedLoading.circularProgress(),
            );
      },
    );
  }
}
