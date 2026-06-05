// Quick-Profile-Bottom-Sheet — kurze Vorschau eines Users.
//
// Wird vom Avatar-/Namens-Tap in Chat-Bubbles ausgelöst. Zeigt Username,
// Avatar mit XP-Ring, Level, Welt + Rolle, Online-Status, Bio und Actions
// (Erwähnen + In aktiven Live-Call einladen). Lädt das Profil lazy aus
// `profiles` über Supabase (anon-Read).
//
// Konsolidiert die frühere separate UserProfileSheet — es gibt jetzt nur
// noch dieses eine Sheet für alle Chat-Profil-Previews.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/livekit_call_provider.dart';
import '../services/livestream_invite_service.dart';
import '../services/user_service.dart';
import 'xp_avatar_ring.dart';

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
  String? _userId;
  String? _avatarUrl;
  String? _displayName;
  String? _role;
  String? _bio;
  String? _world;
  int _xp = 0;
  bool _isOnline = false;
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
          .select('id,avatar_url,display_name,role,bio,xp,world,last_seen_at')
          .ilike('username', widget.username)
          .limit(1)
          .maybeSingle()
          .timeout(const Duration(seconds: 4));
      if (!mounted) return;
      if (res != null) {
        final lastSeen = res['last_seen_at'] as String?;
        bool online = false;
        if (lastSeen != null) {
          final dt = DateTime.tryParse(lastSeen);
          if (dt != null) {
            online =
                DateTime.now().toUtc().difference(dt.toUtc()).inMinutes < 15;
          }
        }
        setState(() {
          _userId = res['id']?.toString();
          _avatarUrl = (res['avatar_url'] as String?) ?? _avatarUrl;
          _displayName = (res['display_name'] as String?) ?? _displayName;
          _role = res['role'] as String?;
          _bio = res['bio'] as String?;
          _world = (res['world'] as String?);
          _xp = (res['xp'] as num?)?.toInt() ?? 0;
          _isOnline = online;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Level via the same formula as PlayerProgress: level = sqrt(xp/100).
  int get _level => math.max(1, math.sqrt(_xp / 100).floor());
  double get _progress {
    final forLevel = _level * _level * 100;
    final forNext = (_level + 1) * (_level + 1) * 100;
    final range = forNext - forLevel;
    if (range <= 0) return 1.0;
    return ((_xp - forLevel) / range).clamp(0.0, 1.0);
  }

  String _roleBadge(String? role) {
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

  String _worldLabel(String world) {
    switch (world) {
      case 'materie':
        return 'Materie';
      case 'energie':
        return 'Energie';
      case 'vorhang':
        return 'Vorhang';
      case 'ursprung':
        return 'Ursprung';
      default:
        return world;
    }
  }

  Future<void> _inviteToCall({
    required String roomName,
    required String world,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final uid = _userId;
    if (uid == null || uid.isEmpty) return;
    final fromName = UserService.getCurrentUsername();
    final ok = await LivestreamInviteService.instance.invite(
      roomName: roomName,
      world: world,
      fromName: fromName.isNotEmpty ? fromName : 'Jemand',
      userIds: [uid],
    );
    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok
            ? '${widget.username} wurde eingeladen'
            : 'Einladung fehlgeschlagen'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name =
        (_displayName?.isNotEmpty ?? false) ? _displayName! : widget.username;
    final badge = _roleBadge(_role);

    // Active LiveKit call (if any) -> enables "invite to call".
    final call = ProviderScope.containerOf(context, listen: false)
        .read(livekitCallServiceProvider);
    final hasActiveCall = call.isConnected &&
        call.roomName != null &&
        call.roomName!.isNotEmpty &&
        (_userId?.isNotEmpty ?? false);

    final avatarChild = (_avatarUrl?.isNotEmpty ?? false)
        ? Image.network(_avatarUrl!, fit: BoxFit.cover)
        : Container(
            color: widget.accent.withValues(alpha: 0.2),
            alignment: Alignment.center,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: widget.accent,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          );

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
          // Avatar with XP ring (only when xp is known).
          if (_xp > 0)
            XpAvatarRing(
              progress: _progress,
              level: _level,
              accent: widget.accent,
              size: 88,
              strokeWidth: 4,
              child: avatarChild,
            )
          else
            ClipOval(
              child: SizedBox(width: 76, height: 76, child: avatarChild),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_isOnline) ...[
                const SizedBox(width: 8),
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
          if (widget.username != name)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '@${widget.username}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          const SizedBox(height: 10),
          // Badges: level, world, role.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (_xp > 0) _chip('Level $_level', widget.accent),
              if (_world != null && _world!.isNotEmpty)
                _chip(_worldLabel(_world!), widget.accent),
              if (badge.isNotEmpty) _chip(badge, widget.accent),
            ],
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
          // ── Actions ──────────────────────────────────────────
          if (hasActiveCall) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _inviteToCall(
                  roomName: call.roomName!,
                  world: call.world ?? 'materie',
                ),
                icon: const Icon(Icons.video_call_rounded, size: 20),
                label: const Text('In meinen Live-Call einladen'),
                style: FilledButton.styleFrom(
                  backgroundColor: widget.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
          if (widget.onMention != null) ...[
            SizedBox(height: hasActiveCall ? 10 : 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onMention!(widget.username);
                },
                icon: const Icon(Icons.alternate_email_rounded, size: 18),
                label: const Text('Erwähnen'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: widget.accent,
                  side: BorderSide(color: widget.accent.withValues(alpha: 0.5)),
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

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
