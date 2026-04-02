import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/cloudflare_api_service.dart';

/// Article Comments Widget - Zeigt und verwaltet Kommentare
class ArticleCommentsWidget extends StatefulWidget {
  final String articleId;
  final int initialCommentCount;
  
  const ArticleCommentsWidget({
    super.key,
    required this.articleId,
    this.initialCommentCount = 0,
  });

  @override
  State<ArticleCommentsWidget> createState() => _ArticleCommentsWidgetState();
}

class _ArticleCommentsWidgetState extends State<ArticleCommentsWidget> {
  final CloudflareApiService _api = CloudflareApiService();
  final TextEditingController _commentController = TextEditingController();
  
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _showComments = false;
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
  
  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    
    try {
      final comments = await _api.getArticleComments(widget.articleId);
      
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading comments: $e');
      }
      
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    
    setState(() => _isSubmitting = true);
    
    // TODO: Get from actual user session
    final username = 'User_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    
    try {
      await _api.addComment(
        articleId: widget.articleId,
        userId: userId,
        username: username,
        content: content,
      );
      
      _commentController.clear();
      
      // Reload comments
      await _loadComments();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Kommentar hinzugefügt'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error adding comment: $e');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
  
  void _toggleComments() {
    setState(() {
      _showComments = !_showComments;
      if (_showComments && _comments.isEmpty) {
        _loadComments();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comments Button
        InkWell(
          onTap: _toggleComments,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.comment_outlined,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  _comments.isNotEmpty ? '${_comments.length}' : '${widget.initialCommentCount}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Comments Section (expandable)
        if (_showComments) ...[
          const SizedBox(height: 16),
          
          // Add Comment Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Schreibe einen Kommentar...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _addComment,
                    icon: _isSubmitting 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send, size: 18),
                    label: Text(_isSubmitting ? 'Wird gesendet...' : 'Kommentieren'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Comments List
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_comments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Noch keine Kommentare.\nSei der Erste!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                final comment = _comments[index];
                return _buildCommentTile(comment);
              },
            ),
        ],
      ],
    );
  }
  
  Widget _buildCommentTile(Map<String, dynamic> comment) {
    final username = comment['username'] as String;
    final content = comment['content'] as String;
    final createdAt = DateTime.parse(comment['created_at'] as String);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blueAccent.withValues(alpha: 0.3),
                child: Text(
                  username[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _formatTimestamp(createdAt),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return 'vor ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'vor ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'vor ${difference.inDays}d';
    } else {
      return 'vor ${(difference.inDays / 7).floor()}w';
    }
  }
}
