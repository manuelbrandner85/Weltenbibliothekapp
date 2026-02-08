import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/responsive_helper.dart';
import '../config/enhanced_app_themes.dart';

/// Responsive Button Widget
/// Automatische Anpassung an Bildschirmgröße
class ResponsiveButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final ButtonSize size;
  final bool isFullWidth;
  final bool isOutlined;
  final bool isLoading;

  const ResponsiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.size = ButtonSize.medium,
    this.isFullWidth = false,
    this.isOutlined = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // Button-Höhe basierend auf Größe
    final double height = _getHeight(context);
    
    // Button-Content
    Widget buttonContent = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: context.responsive(mobile: 20, tablet: 24, desktop: 28),
            height: context.responsive(mobile: 20, tablet: 24, desktop: 28),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                textColor ?? Colors.white,
              ),
            ),
          )
        else if (icon != null) ...[
          Icon(
            icon,
            size: _getIconSize(context),
            color: textColor ?? Colors.white,
          ),
          SizedBox(width: context.responsive(mobile: 8, tablet: 10, desktop: 12)),
        ],
        Text(
          label,
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontSize: _getFontSize(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    return SizedBox(
      height: height,
      width: isFullWidth ? double.infinity : null,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : () {
                HapticFeedback.lightImpact();
                onPressed();
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: backgroundColor ?? EnhancedAppThemes.energiePrimary,
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    context.responsive(mobile: 12, tablet: 14, desktop: 16)
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive(mobile: 16, tablet: 20, desktop: 24),
                  vertical: context.responsive(mobile: 8, tablet: 10, desktop: 12),
                ),
              ),
              child: buttonContent,
            )
          : ElevatedButton(
              onPressed: isLoading ? null : () {
                HapticFeedback.lightImpact();
                onPressed();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor ?? EnhancedAppThemes.energiePrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    context.responsive(mobile: 12, tablet: 14, desktop: 16)
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive(mobile: 16, tablet: 20, desktop: 24),
                  vertical: context.responsive(mobile: 8, tablet: 10, desktop: 12),
                ),
                elevation: 4,
              ),
              child: buttonContent,
            ),
    );
  }

  double _getHeight(BuildContext context) {
    switch (size) {
      case ButtonSize.small:
        return context.responsive(mobile: 40, tablet: 44, desktop: 48);
      case ButtonSize.medium:
        return context.responsive(mobile: 48, tablet: 52, desktop: 56);
      case ButtonSize.large:
        return context.responsive(mobile: 56, tablet: 60, desktop: 64);
    }
  }

  double _getIconSize(BuildContext context) {
    switch (size) {
      case ButtonSize.small:
        return context.responsive(mobile: 18, tablet: 20, desktop: 22);
      case ButtonSize.medium:
        return context.responsive(mobile: 22, tablet: 24, desktop: 26);
      case ButtonSize.large:
        return context.responsive(mobile: 26, tablet: 28, desktop: 30);
    }
  }

  double _getFontSize(BuildContext context) {
    switch (size) {
      case ButtonSize.small:
        return context.responsive(mobile: 13, tablet: 14, desktop: 15);
      case ButtonSize.medium:
        return context.responsive(mobile: 15, tablet: 16, desktop: 17);
      case ButtonSize.large:
        return context.responsive(mobile: 17, tablet: 18, desktop: 19);
    }
  }
}

enum ButtonSize { small, medium, large }
