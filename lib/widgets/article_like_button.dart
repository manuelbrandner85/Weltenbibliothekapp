import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/cloudflare_api_service.dart';
import '../services/haptic_feedback_service.dart';
import '../services/community_interaction_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Like Button Widget mit Animation
class ArticleLikeButton extends StatefulWidget {
  final String articleId;
  final int initialLikes;
  final bool initiallyLiked;
  
  const ArticleLikeButton({
    super.key,
    required this.articleId,
    this.initialLikes = 0,
    this.initiallyLiked = false,
  });

  @override
  State<ArticleLikeButton> createState() => _ArticleLikeButtonState();
}

class _ArticleLikeButtonState extends State<ArticleLikeButton> with SingleTickerProviderStateMixin {
  final CloudflareApiService _api = CloudflareApiService(); // ignore: unused_field
  final CommunityInteractionService _interactionService = CommunityInteractionService();
  
  late bool _isLiked;
  late int _likeCount;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late String _realUserId;
  
  @override
  void initState() {
    super.initState();
    _isLiked = widget.initiallyLiked;
    _likeCount = widget.initialLikes;
    _realUserId = Supabase.instance.client.auth.currentUser?.id ?? 'user_anonymous';
    
    // Animation setup
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    // Lade echten Like-Status aus Supabase
    _loadLikeStatus();
  }
  
  Future<void> _loadLikeStatus() async {
    final liked = await _interactionService.fetchIsLiked(
      postId: widget.articleId,
      userId: _realUserId,
    );
    if (mounted) setState(() => _isLiked = liked);
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _toggleLike() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      if (_isLiked) {
        await HapticFeedbackService().medium();
      } else {
        await HapticFeedbackService().success();
        _animationController.forward().then((_) => _animationController.reverse());
      }
      
      // Toggle via Supabase (mit Optimistic UI)
      final newState = await _interactionService.toggleLikeSupabase(
        postId: widget.articleId,
        userId: _realUserId,
      );
        
      if (mounted) {
        setState(() {
          _isLiked = newState;
          _likeCount += newState ? 1 : -1;
          if (_likeCount < 0) _likeCount = 0;
        });
      }
    } catch (e) {
      // 📳 Haptic Feedback - Error
      await HapticFeedbackService().error();
      
      if (kDebugMode) {
        debugPrint('❌ Error toggling like: $e');
      }
      
      // Show error snackbar if context available
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _toggleLike,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked ? Colors.red : Colors.white.withValues(alpha: 0.7),
                size: 20,
              ),
            ),
            if (_likeCount > 0) ...[
              const SizedBox(width: 6),
              Text(
                _formatCount(_likeCount),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (_isLoading) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}
