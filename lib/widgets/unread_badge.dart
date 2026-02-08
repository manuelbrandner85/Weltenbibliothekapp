import 'package:flutter/material.dart';
import '../services/chat_notification_service.dart';
import '../utils/responsive_utils.dart';
import '../utils/responsive_text_styles.dart';

/// Unread Message Badge für Navigation Tabs
class UnreadBadge extends StatelessWidget {
  final String? roomId; // null = alle Räume
  final Color color;
  
  const UnreadBadge({
    super.key,
    this.roomId,
    this.color = const Color(0xFF2196F3),
  });

  @override
  Widget build(BuildContext context) {
    final utils = ResponsiveUtils.of(context);
    final textStyles = ResponsiveTextStyles.of(context);
    
    return ListenableBuilder(
      listenable: ChatNotificationService(),
      builder: (context, child) {
        final service = ChatNotificationService();
        final count = roomId != null 
            ? service.getUnreadCount(roomId!) 
            : service.getTotalUnreadCount();
        
        if (count == 0) return const SizedBox.shrink();
        
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: utils.spacingXs / 2, 
            vertical: utils.spacingXs / 4,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color,
                color.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(utils.borderRadiusMd),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: utils.spacingXs,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(
            count > 99 ? '99+' : count.toString(),
            style: textStyles.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}

/// Unread Badge für Bottom Navigation Bar
class NavBarUnreadBadge extends StatelessWidget {
  final Color color;
  
  const NavBarUnreadBadge({
    super.key,
    this.color = const Color(0xFF2196F3),
  });

  @override
  Widget build(BuildContext context) {
    final utils = ResponsiveUtils.of(context);
    final textStyles = ResponsiveTextStyles.of(context);
    
    return ListenableBuilder(
      listenable: ChatNotificationService(),
      builder: (context, child) {
        final count = ChatNotificationService().getTotalUnreadCount();
        
        if (count == 0) return const SizedBox.shrink();
        
        return Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: EdgeInsets.all(utils.spacingXs / 2),
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.5),
                  blurRadius: utils.spacingXs / 2,
                  spreadRadius: 1,
                ),
              ],
            ),
            constraints: BoxConstraints(
              minWidth: utils.iconSizeSm + 2,
              minHeight: utils.iconSizeSm + 2,
            ),
            child: Center(
              child: Text(
                count > 9 ? '9+' : count.toString(),
                style: textStyles.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}
