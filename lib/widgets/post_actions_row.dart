import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, debugPrint;
import 'package:share_plus/share_plus.dart';
import '../models/community_post.dart';
import '../services/community_service.dart';
import '../services/cloudflare_api_service.dart';
import '../widgets/comments_dialog.dart';
import '../utils/responsive_utils.dart';
import '../utils/responsive_text_styles.dart';

/// Post action buttons (Like, Comment, Share)
class PostActionsRow extends StatefulWidget {
  final CommunityPost post;
  final Color accentColor;
  final VoidCallback onPostUpdated;
  
  const PostActionsRow({
    super.key,
    required this.post,
    required this.accentColor,
    required this.onPostUpdated,
  });
  
  @override
  State<PostActionsRow> createState() => _PostActionsRowState();
}

class _PostActionsRowState extends State<PostActionsRow> {
  final CommunityService _communityService = CommunityService();
  final CloudflareApiService _cloudflareApi = CloudflareApiService();
  int _localLikes = 0;
  int _localComments = 0;
  int _localShares = 0;
  bool _isSaved = false;
  bool _isLiked = false;
  bool _energySent = false;
  
  @override
  void initState() {
    super.initState();
    _localLikes = widget.post.likes;
    _localComments = widget.post.comments;
    _localShares = widget.post.shares ?? 0;
  }
  
  Future<void> _likePost() async {
    // TODO: Get from actual user session
    final username = 'User_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    
    try {
      if (_isLiked) {
        // Unlike
        await _cloudflareApi.unlikeArticle(
          articleId: widget.post.id,
          userId: userId,
        );
        
        setState(() {
          _isLiked = false;
          _localLikes = _localLikes > 0 ? _localLikes - 1 : 0;
        });
      } else {
        // Like
        await _cloudflareApi.likeArticle(
          articleId: widget.post.id,
          userId: userId,
          username: username,
        );
        
        setState(() {
          _isLiked = true;
          _localLikes++;
        });
      }
      
      widget.onPostUpdated();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('👍 Post geliked!'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Fehler: $e')),
        );
      }
    }
  }
  
  void _showComments() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CommentsDialog(
        post: widget.post,
      ),
    );
    
    // Reload post data after dialog closes
    if (result == true || result == null) {
      widget.onPostUpdated();
    }
  }
  
  void _sharePost() async {
    try {
      final shareText = '${widget.post.content}\n\n'
          'Von: ${widget.post.authorUsername} ${widget.post.authorAvatar}\n'
          '${widget.post.mediaUrl != null ? "\n📸 Mit Bild: ${widget.post.mediaUrl}" : ""}\n\n'
          '🌟 Weltenbibliothek - Wissens- und Bewusstseins-Plattform';
      
      // Web-Plattform: Kopiere in Zwischenablage statt Share-Dialog
      if (kIsWeb) {
        // Für Web: Zeige Text im Dialog zum manuellen Kopieren
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Post teilen'),
              content: SelectableText(shareText),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Schließen'),
                ),
              ],
            ),
          );
          
          setState(() {
            _localShares++;
          });
        }
      } else {
        // Mobile: Native Share
        await Share.share(
          shareText,
          subject: 'Weltenbibliothek Post von ${widget.post.authorUsername}',
        );
        
        setState(() {
          _localShares++;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Post geteilt!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Fehler beim Teilen: $e')),
        );
      }
    }
  }
  
  void _savePost() {
    setState(() {
      _isSaved = !_isSaved;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSaved ? '💾 Post gespeichert!' : '🗑️ Speicherung entfernt'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
  
  void _sendEnergy() {
    setState(() {
      _energySent = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✨ Energie gesendet!'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.purple,
      ),
    );
    
    // Nach 2 Sekunden Animation zurücksetzen
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _energySent = false;
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // ✅ RESPONSIVE UTILITIES
    final responsive = context.responsive;
    final textStyles = context.textStyles;
    
    return Row(
      children: [
        // Like Button
        IconButton(
          icon: Icon(Icons.thumb_up_outlined, size: responsive.iconSizeMd),
          color: Colors.grey,
          onPressed: _likePost,
        ),
        Text(
          '$_localLikes',
          style: textStyles.labelSmall.copyWith(color: Colors.grey),
        ),
        SizedBox(width: responsive.spacingMd),
        
        // Comment Button
        IconButton(
          icon: Icon(Icons.comment_outlined, size: responsive.iconSizeMd),
          color: Colors.grey,
          onPressed: _showComments,
        ),
        Text(
          '$_localComments',
          style: textStyles.labelSmall.copyWith(color: Colors.grey),
        ),
        SizedBox(width: responsive.spacingMd),
        
        // Share Button
        IconButton(
          icon: Icon(Icons.share_outlined, size: responsive.iconSizeMd),
          color: Colors.grey,
          onPressed: _sharePost,
        ),
        Text(
          '$_localShares',
          style: textStyles.labelSmall.copyWith(color: Colors.grey),
        ),
        
        const Spacer(),
        
        // Energie senden Button (nur für Energie-Welt)
        if (widget.post.worldType == WorldType.energie)
          IconButton(
            icon: Icon(
              _energySent ? Icons.auto_awesome : Icons.auto_awesome_outlined,
              size: responsive.iconSizeMd,
              color: _energySent ? Colors.purple : Colors.grey,
            ),
            onPressed: _sendEnergy,
            tooltip: 'Energie senden',
          ),
        
        // Save Button
        IconButton(
          icon: Icon(
            _isSaved ? Icons.bookmark : Icons.bookmark_border,
            size: responsive.iconSizeMd,
            color: _isSaved ? widget.accentColor : Colors.grey,
          ),
          onPressed: _savePost,
          tooltip: 'Speichern',
        ),
      ],
    );
  }
}
