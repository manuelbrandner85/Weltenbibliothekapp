import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import '../utils/responsive_text_styles.dart';

/// Responsive Card Widget
/// Automatische Anpassung an Bildschirmgröße
class ResponsiveCard extends StatelessWidget {
  final Widget? child;
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? elevation;
  final bool showBorder;
  final Color? borderColor;

  const ResponsiveCard({
    super.key,
    this.child,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.backgroundColor,
    this.elevation,
    this.showBorder = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils.of(context);
    final textStyles = ResponsiveTextStyles.of(context);

    Widget cardContent = Container(
      padding: responsive.cardPadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(responsive.borderRadiusLg),
        border: showBorder
            ? Border.all(
                color: borderColor ?? Colors.white.withValues(alpha: 0.2),
                width: 1,
              )
            : null,
        boxShadow: [
          if (elevation != null && elevation! > 0)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: elevation! * 2,
              offset: Offset(0, elevation!),
            ),
        ],
      ),
      child: child ??
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null || subtitle != null || leading != null || trailing != null)
                Row(
                  children: [
                    if (leading != null) ...[
                      leading!,
                      SizedBox(width: responsive.spacingMd),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title != null)
                            Text(
                              title!,
                              style: textStyles.headlineSmall,
                            ),
                          if (subtitle != null) ...[
                            SizedBox(height: responsive.spacingXs),
                            Text(
                              subtitle!,
                              style: textStyles.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      SizedBox(width: responsive.spacingMd),
                      trailing!,
                    ],
                  ],
                ),
            ],
          ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(responsive.borderRadiusLg),
        child: cardContent,
      );
    }

    return cardContent;
  }
}

/// Responsive List Tile
/// Optimierte Darstellung für Listen
class ResponsiveListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const ResponsiveListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils.of(context);
    final textStyles = ResponsiveTextStyles.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.spacingMd,
          vertical: responsive.spacingSm,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(responsive.borderRadiusSm),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              SizedBox(width: responsive.spacingMd),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: textStyles.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: responsive.spacingXs),
                    Text(
                      subtitle!,
                      style: textStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              SizedBox(width: responsive.spacingMd),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
