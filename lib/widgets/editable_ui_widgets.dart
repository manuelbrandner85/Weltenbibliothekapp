import 'package:flutter/material.dart';

/// 🔲 PHASE 4: Universal Editable Button Widget
/// 
/// Macht JEDEN Button im System editierbar:
/// - Text/Label
/// - Icon
/// - Tooltip
/// - Farbe
/// - Größe
/// - Aktion (Future: Route/Function)
class EditableButton extends StatelessWidget {
  final String buttonId;
  final String label;
  final IconData? icon;
  final String? tooltip;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isEditMode;
  final bool canEdit;
  final Function(String, Map<String, dynamic>)? onEdit;

  const EditableButton({
    super.key,
    required this.buttonId,
    required this.label,
    this.icon,
    this.tooltip,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.isEditMode = false,
    this.canEdit = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final button = icon != null
        ? ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
            ),
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
            ),
            child: Text(label),
          );

    // In Edit Mode: Add edit overlay
    if (isEditMode && canEdit) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Tooltip(
            message: tooltip ?? label,
            child: button,
          ),
          // Edit button overlay
          Positioned(
            top: -8,
            right: -8,
            child: GestureDetector(
              onTap: () {
                if (onEdit != null) {
                  onEdit!(buttonId, {
                    'label': label,
                    'icon': icon?.codePoint,
                    'tooltip': tooltip,
                    'backgroundColor': backgroundColor?.value,
                    'foregroundColor': foregroundColor?.value,
                  });
                }
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF9B51E0),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.edit,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Tooltip(
      message: tooltip ?? label,
      child: button,
    );
  }
}

/// 🔲 PHASE 4: Universal Editable Icon Button
class EditableIconButton extends StatelessWidget {
  final String buttonId;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  final bool isEditMode;
  final bool canEdit;
  final Function(String, Map<String, dynamic>)? onEdit;

  const EditableIconButton({
    super.key,
    required this.buttonId,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.color,
    this.isEditMode = false,
    this.canEdit = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final iconButton = IconButton(
      icon: Icon(icon),
      color: color,
      onPressed: onPressed,
      tooltip: tooltip,
    );

    // In Edit Mode: Add edit overlay
    if (isEditMode && canEdit) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          iconButton,
          // Edit button overlay
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                if (onEdit != null) {
                  onEdit!(buttonId, {
                    'icon': icon.codePoint,
                    'tooltip': tooltip,
                    'color': color?.value,
                  });
                }
              },
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF9B51E0),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.edit,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return iconButton;
  }
}

/// 📝 PHASE 4: Universal Editable Text Widget
class EditableText extends StatelessWidget {
  final String textId;
  final String content;
  final TextStyle? style;
  final bool isEditMode;
  final bool canEdit;
  final Function(String, String)? onEdit;
  final int? maxLines;
  final TextAlign? textAlign;

  const EditableText({
    super.key,
    required this.textId,
    required this.content,
    this.style,
    this.isEditMode = false,
    this.canEdit = false,
    this.onEdit,
    this.maxLines,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      content,
      style: style,
      maxLines: maxLines,
      textAlign: textAlign,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
    );

    // In Edit Mode: Make clickable for editing
    if (isEditMode && canEdit) {
      return Stack(
        children: [
          GestureDetector(
            onTap: () {
              if (onEdit != null) {
                onEdit!(textId, content);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF9B51E0).withValues(alpha: 0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.all(4),
              child: textWidget,
            ),
          ),
          // Edit indicator
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF9B51E0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit,
                size: 8,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    return textWidget;
  }
}
