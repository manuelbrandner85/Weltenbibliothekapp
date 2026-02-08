import 'package:flutter/material.dart';
import '../models/community_post.dart';
import '../services/community_service.dart';
import '../services/user_service.dart';

/// 💬 ECHTES Kommentar-Dialog mit Backend-Integration
class CommentsDialog extends StatefulWidget {
  final CommunityPost post;
  
  const CommentsDialog({super.key, required this.post});
  
  @override
  State<CommentsDialog> createState() => _CommentsDialogState();
}

class _CommentsDialogState extends State<CommentsDialog> {
  final CommunityService _communityService = CommunityService();
  final UserService _userService = UserService();
  final TextEditingController _commentController = TextEditingController();
  
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isPosting = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadComments();
  }
  
  /// Lade Kommentare vom Backend
  Future<void> _loadComments() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final comments = await _communityService.getComments(widget.post.id);
      
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Fehler beim Laden: $e';
        _isLoading = false;
      });
    }
  }
  
  /// Poste neuen Kommentar
  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    try {
      setState(() => _isPosting = true);
      
      final user = await _userService.getCurrentUser();
      final commentText = _commentController.text.trim();
      
      // Backend call (ECHTE API!)
      await _communityService.commentOnPost(
        widget.post.id,
        user.username,
        commentText,
        avatar: user.avatar,
      );
      
      // Reload comments
      await _loadComments();
      
      // Clear input
      _commentController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Kommentar gepostet!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isPosting = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '💬 Kommentare',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 20),
            
            // Comments List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error, color: Colors.red, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadComments,
                                child: const Text('Erneut versuchen'),
                              ),
                            ],
                          ),
                        )
                      : _comments.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.comment_outlined, size: 64, color: Colors.white24),
                                  SizedBox(height: 16),
                                  Text(
                                    'Noch keine Kommentare',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Sei der Erste, der kommentiert!',
                                    style: TextStyle(color: Colors.white38, fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _comments.length,
                              itemBuilder: (context, index) {
                                final comment = _comments[index];
                                return _buildCommentItem(comment);
                              },
                            ),
            ),
            
            const Divider(color: Colors.white12, height: 20),
            
            // Comment Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    enabled: !_isPosting,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Schreibe einen Kommentar...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: 3,
                    minLines: 1,
                    onSubmitted: (_) => _postComment(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9B51E0), Color(0xFF6A5ACD)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isPosting ? null : _postComment,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: _isPosting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build einzelner Kommentar
  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final username = comment['username'] ?? 'Unbekannt';
    final avatar = comment['avatar'] ?? '👤';
    final text = comment['text'] ?? '';
    final createdAt = comment['createdAt'] ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              // Avatar
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9B51E0), Color(0xFF6A5ACD)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    avatar,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Username
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _formatTimeAgo(createdAt),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Comment text
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Formatiere Zeitstempel
  String _formatTimeAgo(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) return 'Gerade eben';
      if (difference.inMinutes < 60) return 'vor ${difference.inMinutes}m';
      if (difference.inHours < 24) return 'vor ${difference.inHours}h';
      if (difference.inDays < 7) return 'vor ${difference.inDays}d';
      return 'vor ${(difference.inDays / 7).floor()}w';
    } catch (e) {
      return dateTimeStr;
    }
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
