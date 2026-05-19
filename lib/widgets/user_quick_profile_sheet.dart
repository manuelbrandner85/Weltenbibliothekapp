// Quick-Profile-Bottom-Sheet — kurze Vorschau eines Users.
//
// Wird vom Avatar-Tap in Chat-Bubbles ausgelöst. Zeigt Username,
// Avatar, Rolle und ggf. eine "Erwähnen"-Action. Lädt das Profil
// lazy aus profiles über Supabase (anon-Read).
//
// Keine DM-Funktion — die App hat noch keinen 1:1-Chat. Wenn das
// kommt, fügen wir hier eine "DM senden"-Action ein.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserQuickProfileSheet {
  static Future<void> show(
    BuildContext context, {
    required String username,
    String? avatarUrl,
    String? displayName,
    Color accent = const Color(0xFFC9A84C),
    void Function(String username)? onMention,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _QuickProfileContent(
        username: username,
        initialAvatarUrl: avatarUrl,
        initialDisplayName: displayName,
        accent: accent,
        onMention: onMention,
      ),
    );
  }
}

class _QuickProfileContent extends StatefulWidget {
  final String username;
  final String? initialAvatarUrl;
  final String? initialDisplayName;
  final Color accent;
  final void Function(String username)? onMention;

  const _QuickProfileContent({
    required this.username,
    required this.initialAvatarUrl,
    required this.initialDisplayName,
    required this.accent,
    required this.onMention,
  });

  @override
  State<_QuickProfileContent> createState() => _QuickProfileContentState();
}

class _QuickProfileContentState extends State<_QuickProfileContent> {
  String? _avatarUrl;
  String? _displayName;
  String? _role;
  String? _bio;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _avatarUrl = widget.initialAvatarUrl;
    _displayName = widget.initialDisplayName;
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('avatar_url,display_name,role,bio')
          .ilike('username', widget.username)
          .limit(1)
          .maybeSingle()
          .timeout(const Duration(seconds: 4));
      if (!mounted) return;
      if (res != null) {
        setState(() {
          _avatarUrl = (res['avatar_url'] as String?) ?? _avatarUrl;
          _displayName = (res['display_name'] as String?) ?? _displayName;
          _role = res['role'] as String?;
          _bio = res['bio'] as String?;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _badge(String? role) {
    switch (role?.toLowerCase().replaceAll('-', '_')) {
      case 'root_admin':
        return '👑 Root-Admin';
      case 'admin':
        return '🛡️ Admin';
      case 'moderator':
        return '⚖️ Moderator';
      case 'content_editor':
        return '✏️ Editor';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name =
        (_displayName?.isNotEmpty ?? false) ? _displayName! : widget.username;
    final badge = _badge(_role);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          CircleAvatar(
            radius: 38,
            backgroundColor: widget.accent.withValues(alpha: 0.2),
            backgroundImage: (_avatarUrl?.isNotEmpty ?? false)
                ? NetworkImage(_avatarUrl!)
                : null,
            child: (_avatarUrl?.isEmpty ?? true)
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: widget.accent,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (widget.username != name)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '@${widget.username}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          if (badge.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.accent.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: widget.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 14),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            )
          else if (_bio?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 14, 8, 4),
              child: Text(
                _bio!,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          if (widget.onMention != null) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onMention!(widget.username);
                },
                icon: const Icon(Icons.alternate_email_rounded, size: 18),
                label: const Text('Erwähnen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
