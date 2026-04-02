import 'package:flutter/material.dart';
import '../utils/app_animations.dart';

/// 🎨 WELTENBIBLIOTHEK - IMPROVED LOADING STATE WIDGET
/// Professional loading indicators with smooth animations

class LoadingStateWidget extends StatelessWidget {
  final String? message;
  final String? subtitle;
  final bool showProgress;
  final double? progress; // 0.0 to 1.0
  final Color? color;
  final double size;
  
  const LoadingStateWidget({
    super.key,
    this.message,
    this.subtitle,
    this.showProgress = false,
    this.progress,
    this.color,
    this.size = 48.0,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loadingColor = color ?? theme.colorScheme.primary;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Loading Indicator
          _buildLoadingIndicator(loadingColor),
          
          if (message != null) ...[
            const SizedBox(height: 24),
            Text(
              message!,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ).fadeIn(),
          ],
          
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ).fadeIn(duration: const Duration(milliseconds: 400)),
          ],
          
          if (showProgress && progress != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: loadingColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(loadingColor),
              ),
            ).fadeIn(duration: const Duration(milliseconds: 500)),
            const SizedBox(height: 8),
            Text(
              '${(progress! * 100).toInt()}%',
              style: theme.textTheme.bodySmall,
            ).fadeIn(duration: const Duration(milliseconds: 500)),
          ],
        ],
      ),
    );
  }
  
  Widget _buildLoadingIndicator(Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (value * 0.2),
          child: Opacity(
            opacity: 0.6 + (value * 0.4),
            child: child,
          ),
        );
      },
      onEnd: () {
        // Animation would repeat in StatefulWidget
      },
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 4.0,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}

/// 🎨 Skeleton Loading Widget for Lists
class SkeletonLoader extends StatelessWidget {
  final int itemCount;
  final double height;
  final EdgeInsets padding;
  
  const SkeletonLoader({
    super.key,
    this.itemCount = 3,
    this.height = 80.0,
    this.padding = const EdgeInsets.all(16.0),
  });
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _SkeletonItem(height: height)
              .fadeSlideIn()
              .then((widget) {
                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 200 + (index * 100)),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: child,
                    );
                  },
                  child: widget,
                );
              }),
        );
      },
    );
  }
}

class _SkeletonItem extends StatelessWidget {
  final double height;
  
  const _SkeletonItem({required this.height});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: _ShimmerEffect(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _ShimmerEffect extends StatefulWidget {
  final Widget child;
  
  const _ShimmerEffect({required this.child});
  
  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
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
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value.clamp(0.0, 1.0),
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
              colors: const [
                Color(0xFFEBEBF4),
                Color(0xFFF4F4F4),
                Color(0xFFEBEBF4),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

extension _WidgetExtension on Widget {
  Widget then(Widget Function(Widget) builder) {
    return builder(this);
  }
}
