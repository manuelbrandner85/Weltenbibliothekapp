import 'package:flutter/material.dart';
import '../models/user_model.dart';

/// ═══════════════════════════════════════════════════════════════
/// USER AVATAR WIDGET - Weltenbibliothek
/// ═══════════════════════════════════════════════════════════════
/// Wiederverwendbares Profilbild-Widget
/// Features:
/// - Zeigt Avatar-URL oder Fallback (erster Buchstabe)
/// - Verschiedene Größen (small, medium, large)
/// - Optional: Online-Status-Indicator
/// - Optional: Rolle-Badge (Admin, Moderator)
/// - Tappable für Navigation zu Profil
/// ═══════════════════════════════════════════════════════════════

enum AvatarSize {
  small(32),
  medium(48),
  large(80),
  xlarge(120);

  final double size;
  const AvatarSize(this.size);
}

class UserAvatar extends StatelessWidget {
  final User? user;
  final String? avatarUrl;
  final String? fallbackInitial;
  final AvatarSize size;
  final bool showOnlineStatus;
  final bool showRoleBadge;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.user,
    this.avatarUrl,
    this.fallbackInitial,
    this.size = AvatarSize.medium,
    this.showOnlineStatus = false,
    this.showRoleBadge = false,
    this.onTap,
  });

  /// Convenience constructor mit User-Objekt
  factory UserAvatar.fromUser(
    User user, {
    AvatarSize size = AvatarSize.medium,
    bool showOnlineStatus = false,
    bool showRoleBadge = false,
    VoidCallback? onTap,
  }) {
    return UserAvatar(
      user: user,
      avatarUrl: user.avatarUrl,
      fallbackInitial: user.avatarInitial,
      size: size,
      showOnlineStatus: showOnlineStatus,
      showRoleBadge: showRoleBadge,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveAvatarUrl = avatarUrl ?? user?.avatarUrl;
    final effectiveInitial = fallbackInitial ?? user?.avatarInitial ?? '?';
    final isOnline = user?.isOnline ?? false;
    final role = user?.role;

    Widget avatarContent;

    if (effectiveAvatarUrl != null && effectiveAvatarUrl.isNotEmpty) {
      // Bild-Avatar
      avatarContent = CircleAvatar(
        radius: size.size / 2,
        backgroundImage: NetworkImage(effectiveAvatarUrl),
        backgroundColor: Colors.grey[300],
        onBackgroundImageError: (exception, stackTrace) {
          // Fallback auf Initialen bei Ladefehler
        },
      );
    } else {
      // Fallback: Initialen-Avatar
      avatarContent = CircleAvatar(
        radius: size.size / 2,
        backgroundColor: const Color(0xFF8B5CF6),
        child: Text(
          effectiveInitial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size.size / 2.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Wrap in GestureDetector wenn onTap gesetzt
    if (onTap != null) {
      avatarContent = GestureDetector(onTap: onTap, child: avatarContent);
    }

    // Stack für Badges/Indicators
    return SizedBox(
      width: size.size,
      height: size.size,
      child: Stack(
        children: [
          avatarContent,

          // Online-Status-Indicator
          if (showOnlineStatus)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size.size / 5,
                height: size.size / 5,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
              ),
            ),

          // Rolle-Badge (Admin/Moderator)
          if (showRoleBadge && role != null && role != 'user')
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: EdgeInsets.all(size.size / 20),
                decoration: BoxDecoration(
                  color: Color(user!.roleColor),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  _getRoleIcon(role),
                  size: size.size / 4,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'super_admin':
        return Icons.admin_panel_settings;
      case 'admin':
        return Icons.shield;
      case 'moderator':
        return Icons.gavel;
      default:
        return Icons.person;
    }
  }
}
