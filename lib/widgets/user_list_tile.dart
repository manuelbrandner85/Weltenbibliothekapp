import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'user_avatar.dart';
import 'online_status_indicator.dart';

/// ═══════════════════════════════════════════════════════════════
/// USER LIST TILE - Weltenbibliothek
/// ═══════════════════════════════════════════════════════════════
/// Wiederverwendbares Listen-Element für User-Listen
/// Features:
/// - Avatar mit Online-Status
/// - Username + Optional Display-Name
/// - Bio als Subtitle
/// - Rolle-Badge (Admin, Moderator)
/// - Tappable für Navigation zu Profil
/// ═══════════════════════════════════════════════════════════════

class UserListTile extends StatelessWidget {
  final User user;
  final VoidCallback? onTap;
  final bool showOnlineStatus;
  final bool showRoleBadge;
  final bool showBio;
  final Widget? trailing;

  const UserListTile({
    super.key,
    required this.user,
    this.onTap,
    this.showOnlineStatus = true,
    this.showRoleBadge = true,
    this.showBio = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          UserAvatar.fromUser(
            user,
            size: AvatarSize.medium,
            showRoleBadge: showRoleBadge,
          ),
          if (showOnlineStatus)
            Positioned(
              right: 0,
              bottom: 0,
              child: OnlineStatusIndicator(
                isOnline: user.isOnline,
                size: IndicatorSize.small,
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              user.effectiveDisplayName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (user.username != user.effectiveDisplayName) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '@${user.username}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
      subtitle: _buildSubtitle(context),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget? _buildSubtitle(BuildContext context) {
    final List<Widget> subtitleParts = [];

    // Rolle-Badge (wenn kein separates Badge angezeigt wird)
    if (!showRoleBadge && user.role != 'user') {
      subtitleParts.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Color(user.roleColor).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            user.roleDisplayName,
            style: TextStyle(
              color: Color(user.roleColor),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // Online-Status-Text (wenn Indicator nicht angezeigt wird)
    if (!showOnlineStatus && user.isOnline) {
      subtitleParts.add(
        Text(
          'Online',
          style: TextStyle(color: Colors.green[600], fontSize: 12),
        ),
      );
    } else if (!showOnlineStatus && !user.isOnline && user.lastSeenAt != null) {
      subtitleParts.add(
        Text(
          user.onlineStatusText,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      );
    }

    // Bio
    if (showBio && user.bio != null && user.bio!.isNotEmpty) {
      subtitleParts.add(
        Text(
          user.bio!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey[700], fontSize: 13),
        ),
      );
    }

    if (subtitleParts.isEmpty) return null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        ...subtitleParts.expand(
          (widget) => [widget, const SizedBox(height: 2)],
        ),
      ],
    );
  }
}
