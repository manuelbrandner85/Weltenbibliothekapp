import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════
/// ROLE BADGE WIDGET
/// ═══════════════════════════════════════════════════════════════
/// Displays role icons next to usernames:
/// 👑 Super-Admin
/// 🛡️ Admin
/// 🔧 Moderator
/// ═══════════════════════════════════════════════════════════════

class RoleBadge extends StatelessWidget {
  final String? role;
  final double size;

  const RoleBadge({super.key, this.role, this.size = 20});

  @override
  Widget build(BuildContext context) {
    if (role == null) return const SizedBox.shrink();

    IconData icon;
    Color color;
    String tooltip;

    switch (role) {
      case 'super_admin':
        icon = Icons.star; // Crown emoji equivalent
        color = const Color(0xFFFFD700); // Gold
        tooltip = '👑 Super-Admin';
        break;
      case 'admin':
        icon = Icons.shield; // Shield
        color = const Color(0xFF4169E1); // Royal Blue
        tooltip = '🛡️ Admin';
        break;
      case 'moderator':
        icon = Icons.build; // Wrench
        color = const Color(0xFF32CD32); // Lime Green
        tooltip = '🔧 Moderator';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Tooltip(
      message: tooltip,
      child: Icon(icon, size: size, color: color),
    );
  }
}

/// Username with role badge
class UsernameWithBadge extends StatelessWidget {
  final String username;
  final String? role;
  final TextStyle? textStyle;
  final double badgeSize;

  const UsernameWithBadge({
    super.key,
    required this.username,
    this.role,
    this.textStyle,
    this.badgeSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(username, style: textStyle),
        if (role != null && role != 'user') ...[
          const SizedBox(width: 6),
          RoleBadge(role: role, size: badgeSize),
        ],
      ],
    );
  }
}
