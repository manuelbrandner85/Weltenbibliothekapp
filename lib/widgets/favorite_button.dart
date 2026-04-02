import 'package:flutter/material.dart';
import '../services/favorites_service.dart';
import '../services/haptic_feedback_service.dart'; // 📳 HAPTIC FEEDBACK
import '../models/favorite.dart';
import '../config/enhanced_app_themes.dart';

/// Simplified Favorite Button v8.0
/// Works with static FavoritesService API
class FavoriteButton extends StatefulWidget {
  final String itemId;
  final FavoriteType itemType;
  final String itemTitle;
  final String? itemDescription;
  final String? itemUrl;
  final Map<String, dynamic>? metadata;
  final Color? activeColor;
  final Color? inactiveColor;
  final double size;
  
  const FavoriteButton({
    super.key,
    required this.itemId,
    required this.itemType,
    required this.itemTitle,
    this.itemDescription,
    this.itemUrl,
    this.metadata,
    this.activeColor,
    this.inactiveColor,
    this.size = 24.0,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isFavorite = false;
  
  @override
  void initState() {
    super.initState();
    
    // Animation (use EnhancedAppThemes)
    _controller = AnimationController(
      duration: EnhancedAppThemes.fastAnimation,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    
    // Check if favorite
    _checkFavoriteStatus();
  }

  void _checkFavoriteStatus() {
    final favorites = FavoritesService.getAllFavorites();
    final exists = favorites.any((f) => 
      f.id == widget.itemId || 
      (f.type == widget.itemType && f.title == widget.itemTitle)
    );
    
    if (mounted) {
      setState(() => _isFavorite = exists);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    try {
      if (_isFavorite) {
        // 📳 Haptic Feedback - Remove
        await HapticFeedbackService().medium();
        
        // Remove from favorites
        final favorites = FavoritesService.getAllFavorites();
        final existing = favorites.where((f) => 
          f.id == widget.itemId || 
          (f.type == widget.itemType && f.title == widget.itemTitle)
        ).toList();
        
        for (var fav in existing) {
          await FavoritesService.deleteFavorite(fav.id);
        }
        
        setState(() => _isFavorite = false);
        
      } else {
        // 📳 Haptic Feedback - Add (Success Pattern)
        await HapticFeedbackService().success();
        
        // Add to favorites
        final favorite = Favorite(
          id: widget.itemId,
          type: widget.itemType,
          title: widget.itemTitle,
          description: widget.itemDescription,
          url: widget.itemUrl,
          createdAt: DateTime.now(),
          metadata: widget.metadata,
        );
        
        await FavoritesService.addFavorite(favorite);
        setState(() => _isFavorite = true);
        
        // Trigger animation
        _controller.forward().then((_) => _controller.reverse());
      }
      
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: IconButton(
        icon: Icon(
          _isFavorite ? Icons.favorite : Icons.favorite_border,
          color: _isFavorite 
              ? (widget.activeColor ?? EnhancedAppThemes.energieSecondary)
              : (widget.inactiveColor ?? Colors.grey),
          size: widget.size,
        ),
        onPressed: _toggleFavorite,
        tooltip: _isFavorite ? 'Aus Favoriten entfernen' : 'Zu Favoriten hinzufügen',
      ),
    );
  }
}

/// Mini Favorite Icon (no interaction, just displays status)
class FavoriteIcon extends StatelessWidget {
  final String itemId;
  final FavoriteType itemType;
  final String itemTitle;
  final double size;
  final Color? color;
  
  const FavoriteIcon({
    super.key,
    required this.itemId,
    required this.itemType,
    required this.itemTitle,
    this.size = 16.0,
    this.color,
  });

  bool get _isFavorite {
    final favorites = FavoritesService.getAllFavorites();
    return favorites.any((f) => 
      f.id == itemId || 
      (f.type == itemType && f.title == itemTitle)
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isFavorite) return const SizedBox.shrink();
    
    return Icon(
      Icons.favorite,
      size: size,
      color: color ?? Colors.red,
    );
  }
}
