import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event_model.dart';
import '../providers/favorites_provider.dart';

/// ═══════════════════════════════════════════════════════════════
/// FAVORITE BUTTON WIDGET - Animated Heart Button
/// ═══════════════════════════════════════════════════════════════
/// Beautiful animated favorite button with mystical gold theme
/// ═══════════════════════════════════════════════════════════════

class FavoriteButton extends StatefulWidget {
  final EventModel event;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const FavoriteButton({
    super.key,
    required this.event,
    this.size = 32.0,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.3,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.3,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap(FavoritesProvider favoritesProvider) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    // Trigger animation
    await _controller.forward(from: 0.0);

    // Toggle favorite
    final success = await favoritesProvider.toggleFavorite(widget.event);

    if (success && mounted) {
      // Show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                favoritesProvider.isFavorite(widget.event.id)
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: const Color(0xFFFFD700),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  favoritesProvider.isFavorite(widget.event.id)
                      ? '⭐ ${widget.event.title} zu Favoriten hinzugefügt'
                      : '${widget.event.title} von Favoriten entfernt',
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1A1A2E),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, child) {
        final isFavorite = favoritesProvider.isFavorite(widget.event.id);

        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(scale: _scaleAnimation.value, child: child);
          },
          child: IconButton(
            onPressed: _isProcessing
                ? null
                : () => _handleTap(favoritesProvider),
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              size: widget.size,
            ),
            color: isFavorite
                ? (widget.activeColor ?? const Color(0xFFFFD700))
                : (widget.inactiveColor ?? Colors.white60),
            splashColor: const Color(0xFFFFD700).withValues(alpha: 0.3),
            highlightColor: const Color(0xFFFFD700).withValues(alpha: 0.2),
          ),
        );
      },
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// COMPACT FAVORITE INDICATOR - For list items
/// ═══════════════════════════════════════════════════════════════

class CompactFavoriteIndicator extends StatelessWidget {
  final String eventId;
  final double size;

  const CompactFavoriteIndicator({
    super.key,
    required this.eventId,
    this.size = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, child) {
        if (!favoritesProvider.isFavorite(eventId)) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFFFD700).withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite, size: size, color: const Color(0xFFFFD700)),
              const SizedBox(width: 4),
              Text(
                'Favorit',
                style: TextStyle(
                  color: const Color(0xFFFFD700),
                  fontSize: size * 0.75,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
