import 'package:flutter/material.dart';
import 'dart:ui';
import '../../design/premium_design_system.dart';

/// PREMIUM DASHBOARD HEADER
/// Beautiful header with gradient background and user info
class PremiumDashboardHeader extends StatelessWidget {
  final String username;
  final String subtitle;
  final String avatarEmoji;
  final Gradient gradient;
  final List<Widget>? actions;

  const PremiumDashboardHeader({
    super.key,
    required this.username,
    required this.subtitle,
    required this.avatarEmoji,
    required this.gradient,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        boxShadow: PremiumDesignSystem.shadowLarge,
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              PremiumDesignSystem.space4,
              PremiumDesignSystem.space6,
              PremiumDesignSystem.space4,
              PremiumDesignSystem.space4,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(
                              PremiumDesignSystem.radiusLarge),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          boxShadow: PremiumDesignSystem.shadowMedium,
                        ),
                        child: Center(
                          child: Text(
                            avatarEmoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                      const SizedBox(width: PremiumDesignSystem.space4),

                      // User info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Willkommen zurück,',
                              style: PremiumDesignSystem.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              username,
                              style: PremiumDesignSystem.headingMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: PremiumDesignSystem.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Actions
                      if (actions != null) ...actions!,
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// PREMIUM SECTION HEADER
/// Section header with optional action button
class PremiumSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? actionText;
  final VoidCallback? onActionTap;

  const PremiumSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PremiumDesignSystem.space4,
        vertical: PremiumDesignSystem.space2,
      ),
      child: Row(
        children: [
          // Icon (optional)
          if (icon != null) ...[
            Icon(
              icon,
              color: PremiumDesignSystem.textPrimary,
              size: 20,
            ),
            const SizedBox(width: PremiumDesignSystem.space2),
          ],

          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PremiumDesignSystem.headingSmall,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: PremiumDesignSystem.bodySmall,
                  ),
                ],
              ],
            ),
          ),

          // Action button (optional)
          if (actionText != null && onActionTap != null)
            TextButton(
              onPressed: onActionTap,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: PremiumDesignSystem.space3,
                  vertical: PremiumDesignSystem.space2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionText!,
                    style: PremiumDesignSystem.bodySmall.copyWith(
                      color: PremiumDesignSystem.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: PremiumDesignSystem.info,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
