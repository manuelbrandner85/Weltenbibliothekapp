import 'package:flutter/material.dart';
import 'tool_overlay_dialog.dart';
import '../utils/responsive_utils.dart';
import '../utils/responsive_text_styles.dart';

/// Floating Tool Button - Schwebt über dem Chat
class FloatingToolButton extends StatelessWidget {
  final Widget? toolWidget;
  final String toolName;
  final IconData toolIcon;
  final Color toolColor;

  const FloatingToolButton({
    super.key,
    required this.toolWidget,
    required this.toolName,
    required this.toolIcon,
    required this.toolColor,
  });

  @override
  Widget build(BuildContext context) {
    final utils = ResponsiveUtils.of(context);
    final textStyles = ResponsiveTextStyles.of(context);
    
    if (toolWidget == null) return const SizedBox.shrink();

    return Positioned(
      top: utils.spacingMd,
      right: utils.spacingMd,
      child: Material(
        elevation: utils.elevationLg,
        borderRadius: BorderRadius.circular(utils.borderRadiusLg * 1.75),
        child: InkWell(
          onTap: () {
            ToolOverlayDialog.show(
              context,
              toolWidget: toolWidget!,
              toolName: toolName,
              toolIcon: toolIcon,
              toolColor: toolColor,
            );
          },
          borderRadius: BorderRadius.circular(utils.borderRadiusLg * 1.75),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: utils.spacingMd, 
              vertical: utils.spacingMd * 0.75,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [toolColor, toolColor.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(utils.borderRadiusLg * 1.75),
              boxShadow: [
                BoxShadow(
                  color: toolColor.withValues(alpha: 0.4),
                  blurRadius: utils.spacingMd * 0.75,
                  spreadRadius: utils.spacingXs / 4,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(toolIcon, color: Colors.white, size: utils.iconSizeMd),
                SizedBox(width: utils.spacingXs),
                Text(
                  toolName,
                  style: textStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: utils.spacingXs / 2),
                Icon(Icons.arrow_forward_ios, 
                     color: Colors.white70, 
                     size: utils.iconSizeSm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
