// CommunityActionsBar -- Like + Kommentar-Footer fuer Community-Posts.
//
// FEATURE (V7 / U6): Vorhang- und Ursprung-Community zeigten Posts nur
// als statischen Feed. Jetzt: Like-Button (optimistisches Update) +
// Kommentar-Button der ein Bottom-Sheet mit Kommentaren oeffnet.
// Wiederverwendbar in allen 4 Welten.

import 'package:flutter/material.dart';

import '../models/community_post.dart';
import '../services/community_service.dart';
import '../services/user_service.dart';

class CommunityActionsBar extends StatefulWidget {
  final CommunityPost post;
  final Color accent;

  const CommunityActionsBar({
    super.key,
    required this.post,
    required this.accent,
  });

  @override
  State<CommunityActionsBar> createState() => _CommunityActionsBarState();
}

class _CommunityActionsBarState extends State<CommunityActionsBar> {
  final _service = CommunityService();
  late int _likes = widget.post.likes;
  late int _comments = widget.post.comments;
  bool _liked = false;
  bool _busy = false;

  Future<void> _toggleLike() async {
    if (_busy) return;
    // Optimistisches Update.
    setState(() {
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
      _busy = true;
    });
    try {
      await _service.likePost(widget.post.id);
    } catch (_) {
      // Rollback bei Fehler.
      if (mounted) {
        setState(() {
          _liked = !_liked;
          _likes += _liked ? 1 : -1;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openComments() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF12121E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CommentSheet(
        post: widget.post,
        accent: widget.accent,
        onCommentAdded: () {
          if (mounted) setState(() => _comments++);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          _ActionButton(
            icon: _liked ? Icons.favorite : Icons.favorite_border,
            label: '$_likes',
            color: _liked ? Colors.redAccent : Colors.white54,
            onTap: _toggleLike,
          ),
          const SizedBox(width: 20),
          _ActionButton(
            icon: Icons.mode_comment_outlined,
            label: '$_comments',
            color: Colors.white54,
            onTap: _openComments,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _CommentSheet extends StatefulWidget {
  final CommunityPost post;
  final Color accent;
  final VoidCallback onCommentAdded;

  const _CommentSheet({
    required this.post,
    required this.accent,
    required this.onCommentAdded,
  });

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  final _service = CommunityService();
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final c = await _service.getComments(widget.post.id);
      if (mounted) setState(() {
        _comments = c;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final un = UserService.getCurrentUsername();
    final username = un.isNotEmpty ? un : 'Anonym';
    try {
      await _service.commentOnPost(widget.post.id, username, text);
      _ctrl.clear();
      widget.onCommentAdded();
      await _load();
    } catch (_) {/* best-effort */} finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Text('Kommentare',
                style: TextStyle(
                    color: widget.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _comments.isEmpty
                      ? const Center(
                          child: Text('Noch keine Kommentare.\nSei der Erste!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white38)))
                      : ListView.builder(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.all(16),
                          itemCount: _comments.length,
                          itemBuilder: (_, i) {
                            final c = _comments[i];
                            final user = (c['username'] ??
                                    c['profiles']?['username'] ??
                                    'Anonym')
                                .toString();
                            final body =
                                (c['content'] ?? c['comment'] ?? '').toString();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user,
                                      style: TextStyle(
                                          color: widget.accent,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12)),
                                  const SizedBox(height: 2),
                                  Text(body,
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 13)),
                                ],
                              ),
                            );
                          },
                        ),
            ),
            // Eingabe-Zeile
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Kommentar schreiben...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.send_rounded, color: widget.accent),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
