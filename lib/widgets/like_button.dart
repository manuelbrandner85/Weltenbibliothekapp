import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/community_interaction_service.dart';
import '../config/enhanced_app_themes.dart';

/// Like Button Widget with Animation
/// Shows like status, count, and handles toggle
class LikeButton extends StatefulWidget {
  final String postId;
  final String userId;
  final int initialLikeCount;
  final bool initialIsLiked;
  final VoidCallback? onLikeChanged;

  const LikeButton({
    super.key,
    required this.postId,
    required this.userId,
    this.initialLikeCount = 0,
    this.initialIsLiked = false,
    this.onLikeChanged,
  });

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late bool _isLiked;
  late int _likeCount;
  bool _isProcessing = false;

  final _interactionService = CommunityInteractionService();

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initialIsLiked;
    _likeCount = widget.initialLikeCount;

    // Animation setup (use EnhancedAppThemes duration)
    _animationController = AnimationController(
      duration: EnhancedAppThemes.fastAnimation,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    // Load actual like status
    _loadLikeStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadLikeStatus() async {
    final isLiked = _interactionService.isLiked(
      postId: widget.postId,
      userId: widget.userId,
    );

    final count = await _interactionService.getLikeCount(widget.postId);

    if (mounted) {
      setState(() {
        _isLiked = isLiked;
        _likeCount = count;
      });
    }
  }

  Future<void> _handleLikeTap() async {
    if (_isProcessing) return;
    
    // ✨ Haptic Feedback
    HapticFeedback.lightImpact();

    setState(() {
      _isProcessing = true;
    });

    // Optimistic UI update
    final previousIsLiked = _isLiked;
    final previousCount = _likeCount;

    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    // Animate
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Backend sync
    final success = await _interactionService.toggleLike(
      postId: widget.postId,
      userId: widget.userId,
    );

    if (!success) {
      // Rollback on failure
      if (mounted) {
        setState(() {
          _isLiked = previousIsLiked;
          _likeCount = previousCount;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Like fehlgeschlagen. Bitte erneut versuchen.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      widget.onLikeChanged?.call();
    }

    setState(() {
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _handleLikeTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isLiked
              ? EnhancedAppThemes.energiePrimary.withValues(alpha: 0.15)
              : EnhancedAppThemes.darkSurface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isLiked 
                ? EnhancedAppThemes.energiePrimary 
                : Colors.grey.shade700,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Heart Icon
            ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked 
                    ? EnhancedAppThemes.energiePrimary 
                    : Colors.grey.shade400,
                size: 20,
              ),
            ),
            const SizedBox(width: 6),
            
            // Like Count
            Text(
              _formatLikeCount(_likeCount),
              style: TextStyle(
                color: _isLiked 
                    ? EnhancedAppThemes.energiePrimary 
                    : Colors.grey.shade300,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            // Processing indicator
            if (_isProcessing) ...[
              const SizedBox(width: 6),
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isLiked ? Colors.red : Colors.grey.shade400,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatLikeCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
}
