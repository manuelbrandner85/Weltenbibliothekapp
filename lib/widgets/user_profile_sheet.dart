// UserProfileSheet -- tap a username/avatar in chat to see a quick profile
// card: avatar with XP ring, level, world, online status.
//
// FEATURE (C): Previously there was no way to view another member from the
// chat. Now a tap opens this glassmorphic bottom sheet. Other users' XP is
// fetched from the public profile endpoint (local gamification is per-device).
//
// Usage:
//   showUserProfileSheet(context, username: 'Max', accent: gold);

import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'xp_avatar_ring.dart';

/// Public profile data fetched from the worker.
class _PublicProfile {
  final String userId;
  final String username;
  final String? avatarUrl;
  final String? avatarEmoji;
  final int xp;
  final String? world;
  final String? role;
  final bool isOnline;

  const _PublicProfile({
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.avatarEmoji,
    this.xp = 0,
    this.world,
    this.role,
    this.isOnline = false,
  });

  /// Level via the same formula as PlayerProgress: level = sqrt(xp/100).
  int get level => math.max(1, math.sqrt(xp / 100).floor());
  int get _xpForLevel => level * level * 100;
  int get _xpForNext => (level + 1) * (level + 1) * 100;
  double get progressToNext {
    final range = _xpForNext - _xpForLevel;
    if (range <= 0) return 1.0;
    return ((xp - _xpForLevel) / range).clamp(0.0, 1.0);
  }
}

/// Shows the quick profile sheet for [username].
Future<void> showUserProfileSheet(
  BuildContext context, {
  required String username,
  required Color accent,
  String? avatarUrl,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _UserProfileSheet(
      username: username,
      accent: accent,
      fallbackAvatarUrl: avatarUrl,
    ),
  );
}

class _UserProfileSheet extends StatefulWidget {
  final String username;
  final Color accent;
  final String? fallbackAvatarUrl;

  const _UserProfileSheet({
    required this.username,
    required this.accent,
    this.fallbackAvatarUrl,
  });

  @override
  State<_UserProfileSheet> createState() => _UserProfileSheetState();
}

class _UserProfileSheetState extends State<_UserProfileSheet> {
  late final Future<_PublicProfile?> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<_PublicProfile?> _fetch() async {
    try {
      // 1) Resolve username -> userId + online via the search endpoint.
      final searchUri = Uri.parse(
          '${ApiConfig.workerUrl}/api/users/search?q=${Uri.encodeComponent(widget.username)}&limit=20');
      final searchRes =
          await http.get(searchUri).timeout(const Duration(seconds: 8));
      if (searchRes.statusCode != 200) return null;
      final searchData = json.decode(searchRes.body) as Map<String, dynamic>;
      final users = (searchData['users'] as List?) ?? const [];
      Map<String, dynamic>? match;
      for (final u in users) {
        final m = Map<String, dynamic>.from(u as Map);
        if ((m['username'] ?? '').toString().toLowerCase() ==
            widget.username.toLowerCase()) {
          match = m;
          break;
        }
      }
      if (match == null) return null;
      final userId = (match['user_id'] ?? '').toString();
      final isOnline = match['is_online'] == true;
      final avatarUrl =
          (match['avatar_url'])?.toString() ?? widget.fallbackAvatarUrl;

      // 2) Fetch full public profile for xp/world/role.
      int xp = 0;
      String? world;
      String? role;
      String? avatarEmoji;
      if (userId.isNotEmpty) {
        try {
          final profUri = Uri.parse(
              '${ApiConfig.workerUrl}/api/profile/get?userId=${Uri.encodeComponent(userId)}');
          final profRes =
              await http.get(profUri).timeout(const Duration(seconds: 8));
          if (profRes.statusCode == 200) {
            final decoded = json.decode(profRes.body);
            final row = decoded is List && decoded.isNotEmpty
                ? Map<String, dynamic>.from(decoded.first as Map)
                : (decoded is Map
                    ? Map<String, dynamic>.from(decoded)
                    : <String, dynamic>{});
            xp = (row['xp'] as num?)?.toInt() ?? 0;
            world = (row['world'] ?? row['world_preference'])?.toString();
            role = (row['role'])?.toString();
            avatarEmoji = (row['avatar_emoji'])?.toString();
          }
        } catch (_) {/* xp optional */}
      }

      return _PublicProfile(
        userId: userId,
        username: (match['username'] ?? widget.username).toString(),
        avatarUrl: avatarUrl,
        avatarEmoji: avatarEmoji,
        xp: xp,
        world: world,
        role: role,
        isOnline: isOnline,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF121212).withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(color: accent.withValues(alpha: 0.25), width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: FutureBuilder<_PublicProfile?>(
                future: _future,
                builder: (context, snapshot) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: CircularProgressIndicator(color: accent),
                        )
                      else
                        _buildContent(snapshot.data, accent),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(_PublicProfile? p, Color accent) {
    final username = p?.username ?? widget.username;
    final avatarUrl = p?.avatarUrl ?? widget.fallbackAvatarUrl;
    final emoji = p?.avatarEmoji;

    final avatar = (avatarUrl != null && avatarUrl.startsWith('http'))
        ? Image.network(avatarUrl, fit: BoxFit.cover)
        : Container(
            color: accent.withValues(alpha: 0.2),
            alignment: Alignment.center,
            child: Text(
              emoji != null && emoji.isNotEmpty
                  ? emoji
                  : (username.isNotEmpty ? username[0].toUpperCase() : '?'),
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.bold,
                fontSize: 32,
              ),
            ),
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar with XP ring (only when xp is known).
        if (p != null && p.xp > 0)
          XpAvatarRing(
            progress: p.progressToNext,
            level: p.level,
            accent: accent,
            size: 96,
            strokeWidth: 4,
            child: avatar,
          )
        else
          ClipOval(
            child: SizedBox(width: 88, height: 88, child: avatar),
          ),
        const SizedBox(height: 14),
        // Username + online dot.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                username,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (p?.isOnline == true) ...[
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
        const SizedBox(height: 4),
        Text(
          p?.isOnline == true ? 'Gerade online' : 'Mitglied',
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 16),
        // Badges row: level, world, role.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            if (p != null && p.xp > 0) _badge('Level ${p.level}', accent),
            if (p?.world != null && p!.world!.isNotEmpty)
              _badge(_worldLabel(p.world!), accent),
            if (p?.role != null && p!.role!.isNotEmpty && p.role != 'user')
              _badge(_roleLabel(p.role!), const Color(0xFFFFB300)),
          ],
        ),
        if (p == null) ...[
          const SizedBox(height: 8),
          const Text(
            'Profil konnte nicht geladen werden',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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

  String _roleLabel(String role) {
    switch (role) {
      case 'root_admin':
        return 'Root-Admin';
      case 'admin':
        return 'Admin';
      case 'content_editor':
        return 'Redakteur';
      case 'moderator':
        return 'Moderator';
      default:
        return role;
    }
  }
}
