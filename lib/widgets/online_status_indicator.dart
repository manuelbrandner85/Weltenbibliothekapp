import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════
/// ONLINE STATUS INDICATOR - Weltenbibliothek
/// ═══════════════════════════════════════════════════════════════
/// Kleiner farbiger Punkt für Online-Status
/// Features:
/// - Grüner Punkt: Online (< 2 Minuten)
/// - Grauer Punkt: Offline
/// - Optional: Pulsating Animation für Online
/// - Verschiedene Größen
/// ═══════════════════════════════════════════════════════════════

enum IndicatorSize {
  small(8),
  medium(12),
  large(16);

  final double size;
  const IndicatorSize(this.size);
}

class OnlineStatusIndicator extends StatefulWidget {
  final bool isOnline;
  final IndicatorSize size;
  final bool animate;
  final bool showBorder;

  const OnlineStatusIndicator({
    super.key,
    required this.isOnline,
    this.size = IndicatorSize.medium,
    this.animate = true,
    this.showBorder = true,
  });

  @override
  State<OnlineStatusIndicator> createState() => _OnlineStatusIndicatorState();
}

class _OnlineStatusIndicatorState extends State<OnlineStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isOnline && widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(OnlineStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOnline && widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isOnline || !widget.animate) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isOnline ? Colors.green : Colors.grey;

    if (widget.isOnline && widget.animate) {
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: _buildIndicator(color),
          );
        },
      );
    } else {
      return _buildIndicator(color);
    }
  }

  Widget _buildIndicator(Color color) {
    return Container(
      width: widget.size.size,
      height: widget.size.size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: widget.showBorder
            ? Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 2,
              )
            : null,
      ),
    );
  }
}
