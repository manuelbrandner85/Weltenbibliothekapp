/// Inline Edit Widgets - Live-Editing für alle UI-Komponenten
/// 
/// Ermöglicht Content Editors, ALLE UI-Elemente direkt im UI zu bearbeiten
library;

import 'package:flutter/material.dart';
import '../models/dynamic_ui_models.dart';

/// ============================================================================
/// INLINE EDIT WRAPPER - Macht jedes Widget editierbar
/// ============================================================================

class InlineEditWrapper extends StatefulWidget {
  final Widget child;
  final String entityType; // 'text', 'button', 'media', 'tab', 'tool', 'marker', 'screen'
  final String entityId;
  final dynamic entityData; // Die Daten des Elements
  final Function(dynamic updatedData)? onUpdate;
  final bool enabled; // Nur für Content Editors

  const InlineEditWrapper({
    super.key,
    required this.child,
    required this.entityType,
    required this.entityId,
    required this.entityData,
    this.onUpdate,
    this.enabled = false,
  });

  @override
  State<InlineEditWrapper> createState() => _InlineEditWrapperState();
}

class _InlineEditWrapperState extends State<InlineEditWrapper> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Normale Nutzer sehen nur das Original-Widget
    if (!widget.enabled) {
      return widget.child;
    }

    // Content Editors sehen Edit-Overlay
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Stack(
        children: [
          // Original Widget
          widget.child,
          
          // Edit Overlay (nur bei Hover sichtbar)
          if (_isHovered)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  color: Colors.blue.withValues(alpha: 0.1),
                ),
                child: Stack(
                  children: [
                    // Edit Button
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _showEditDialog(context),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    
                    // Entity Info Label
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${widget.entityType} • ${widget.entityId}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    switch (widget.entityType) {
      case 'text':
        _showTextEditDialog(context);
        break;
      case 'button':
        _showButtonEditDialog(context);
        break;
      case 'media':
        _showMediaEditDialog(context);
        break;
      case 'tab':
        _showTabEditDialog(context);
        break;
      case 'tool':
        _showToolEditDialog(context);
        break;
      case 'marker':
        _showMarkerEditDialog(context);
        break;
      case 'screen':
        _showScreenEditDialog(context);
        break;
      default:
        _showGenericEditDialog(context);
    }
  }

  /// TEXT EDIT DIALOG
  void _showTextEditDialog(BuildContext context) {
    final text = widget.entityData as DynamicText;
    final contentController = TextEditingController(text: text.content);
    final styleIdController = TextEditingController(text: text.styleId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✏️ Text bearbeiten'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Text-Inhalt',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: styleIdController,
                decoration: const InputDecoration(
                  labelText: 'Style-ID',
                  border: OutlineInputBorder(),
                  hintText: 'z.B. heading1, body, caption',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedText = DynamicText(
                id: text.id,
                content: contentController.text.trim(),
                styleId: styleIdController.text.trim(),
                semanticLabel: text.semanticLabel,
                translations: text.translations,
              );
              
              widget.onUpdate?.call(updatedText);
              Navigator.pop(context);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  /// BUTTON EDIT DIALOG
  void _showButtonEditDialog(BuildContext context) {
    final button = widget.entityData as DynamicButton;
    final labelController = TextEditingController(text: button.label.content);
    final iconController = TextEditingController(text: button.icon ?? '');
    final bgColorController = TextEditingController(text: button.backgroundColor);
    final fgColorController = TextEditingController(text: button.foregroundColor);
    final actionTypeController = TextEditingController(text: button.action.type);
    final actionTargetController = TextEditingController(text: button.action.target);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔘 Button bearbeiten'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  labelText: 'Button-Text',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: iconController,
                decoration: const InputDecoration(
                  labelText: 'Icon (Emoji)',
                  border: OutlineInputBorder(),
                  hintText: 'z.B. 🔥',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: bgColorController,
                      decoration: const InputDecoration(
                        labelText: 'BG-Farbe',
                        border: OutlineInputBorder(),
                        hintText: '#9B51E0',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: fgColorController,
                      decoration: const InputDecoration(
                        labelText: 'Text-Farbe',
                        border: OutlineInputBorder(),
                        hintText: '#FFFFFF',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: actionTypeController,
                decoration: const InputDecoration(
                  labelText: 'Aktion',
                  border: OutlineInputBorder(),
                  hintText: 'navigate, video, popup, quiz',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: actionTargetController,
                decoration: const InputDecoration(
                  labelText: 'Ziel',
                  border: OutlineInputBorder(),
                  hintText: 'Screen-ID, URL, etc.',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedButton = DynamicButton(
                id: button.id,
                label: DynamicText(
                  id: button.label.id,
                  content: labelController.text.trim(),
                  styleId: button.label.styleId,
                ),
                icon: iconController.text.trim().isEmpty ? null : iconController.text.trim(),
                backgroundColor: bgColorController.text.trim(),
                foregroundColor: fgColorController.text.trim(),
                action: ButtonAction(
                  type: actionTypeController.text.trim(),
                  target: actionTargetController.text.trim(),
                  parameters: button.action.parameters,
                ),
                width: button.width,
                height: button.height,
                borderRadius: button.borderRadius,
                borderColor: button.borderColor,
                borderWidth: button.borderWidth,
                enabled: button.enabled,
              );
              
              widget.onUpdate?.call(updatedButton);
              Navigator.pop(context);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  /// MEDIA EDIT DIALOG
  void _showMediaEditDialog(BuildContext context) {
    final media = widget.entityData as DynamicMedia;
    final urlController = TextEditingController(text: media.url);
    final captionController = TextEditingController(text: media.caption ?? '');
    final typeController = TextEditingController(text: media.type);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🖼️ Media bearbeiten'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: typeController,
                decoration: const InputDecoration(
                  labelText: 'Typ',
                  border: OutlineInputBorder(),
                  hintText: 'image, video, audio',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'URL',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: captionController,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedMedia = DynamicMedia(
                id: media.id,
                type: typeController.text.trim(),
                url: urlController.text.trim(),
                thumbnail: media.thumbnail,
                caption: captionController.text.trim().isEmpty 
                    ? null 
                    : captionController.text.trim(),
                width: media.width,
                height: media.height,
                fit: media.fit,
                autoPlay: media.autoPlay,
                loop: media.loop,
                metadata: media.metadata,
              );
              
              widget.onUpdate?.call(updatedMedia);
              Navigator.pop(context);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  /// TAB EDIT DIALOG
  void _showTabEditDialog(BuildContext context) {
    final tab = widget.entityData as DynamicTab;
    final labelController = TextEditingController(text: tab.label.content);
    final iconController = TextEditingController(text: tab.icon ?? '');
    final screenIdController = TextEditingController(text: tab.screenId);
    final orderController = TextEditingController(text: tab.order.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📑 Tab bearbeiten'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  labelText: 'Tab-Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: iconController,
                decoration: const InputDecoration(
                  labelText: 'Icon (Emoji)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: screenIdController,
                decoration: const InputDecoration(
                  labelText: 'Screen-ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: orderController,
                decoration: const InputDecoration(
                  labelText: 'Reihenfolge',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedTab = DynamicTab(
                id: tab.id,
                label: DynamicText(
                  id: tab.label.id,
                  content: labelController.text.trim(),
                  styleId: tab.label.styleId,
                ),
                icon: iconController.text.trim().isEmpty ? null : iconController.text.trim(),
                screenId: screenIdController.text.trim(),
                order: int.tryParse(orderController.text.trim()) ?? tab.order,
                enabled: tab.enabled,
                metadata: tab.metadata,
              );
              
              widget.onUpdate?.call(updatedTab);
              Navigator.pop(context);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  /// TOOL EDIT DIALOG
  void _showToolEditDialog(BuildContext context) {
    final tool = widget.entityData as DynamicTool;
    final titleController = TextEditingController(text: tool.title.content);
    final descController = TextEditingController(text: tool.description?.content ?? '');
    final iconController = TextEditingController(text: tool.icon ?? '');
    final typeController = TextEditingController(text: tool.toolType);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🛠️ Tool bearbeiten'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Tool-Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: iconController,
                decoration: const InputDecoration(
                  labelText: 'Icon (Emoji)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: typeController,
                decoration: const InputDecoration(
                  labelText: 'Tool-Typ',
                  border: OutlineInputBorder(),
                  hintText: 'meditation_timer, chakra_scan, quiz',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedTool = DynamicTool(
                id: tool.id,
                world: tool.world,
                room: tool.room,
                title: DynamicText(
                  id: tool.title.id,
                  content: titleController.text.trim(),
                  styleId: tool.title.styleId,
                ),
                description: descController.text.trim().isEmpty
                    ? null
                    : DynamicText(
                        id: tool.description?.id ?? '${tool.id}_desc',
                        content: descController.text.trim(),
                        styleId: tool.description?.styleId ?? 'body',
                      ),
                icon: iconController.text.trim().isEmpty ? null : iconController.text.trim(),
                toolType: typeController.text.trim(),
                config: tool.config,
                order: tool.order,
                enabled: tool.enabled,
              );
              
              widget.onUpdate?.call(updatedTool);
              Navigator.pop(context);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  /// MARKER EDIT DIALOG
  void _showMarkerEditDialog(BuildContext context) {
    final marker = widget.entityData as DynamicMarker;
    final titleController = TextEditingController(text: marker.title.content);
    final descController = TextEditingController(text: marker.description?.content ?? '');
    final latController = TextEditingController(text: marker.latitude.toString());
    final lngController = TextEditingController(text: marker.longitude.toString());
    final colorController = TextEditingController(text: marker.markerColor);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📍 Marker bearbeiten'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Marker-Titel',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: latController,
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: lngController,
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: colorController,
                decoration: const InputDecoration(
                  labelText: 'Marker-Farbe',
                  border: OutlineInputBorder(),
                  hintText: '#FF5733',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedMarker = DynamicMarker(
                id: marker.id,
                category: marker.category,
                latitude: double.tryParse(latController.text.trim()) ?? marker.latitude,
                longitude: double.tryParse(lngController.text.trim()) ?? marker.longitude,
                title: DynamicText(
                  id: marker.title.id,
                  content: titleController.text.trim(),
                  styleId: marker.title.styleId,
                ),
                description: descController.text.trim().isEmpty
                    ? null
                    : DynamicText(
                        id: marker.description?.id ?? '${marker.id}_desc',
                        content: descController.text.trim(),
                        styleId: marker.description?.styleId ?? 'body',
                      ),
                icon: marker.icon,
                markerColor: colorController.text.trim(),
                media: marker.media,
                actions: marker.actions,
                metadata: marker.metadata,
              );
              
              widget.onUpdate?.call(updatedMarker);
              Navigator.pop(context);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  /// SCREEN EDIT DIALOG
  void _showScreenEditDialog(BuildContext context) {
    final screen = widget.entityData as DynamicScreen;
    final titleController = TextEditingController(text: screen.title.content);
    final bgColorController = TextEditingController(text: screen.backgroundColor);
    final layoutController = TextEditingController(text: screen.layout);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📱 Screen bearbeiten'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Screen-Titel',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bgColorController,
                decoration: const InputDecoration(
                  labelText: 'Hintergrund-Farbe',
                  border: OutlineInputBorder(),
                  hintText: '#0A0A0F',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: layoutController,
                decoration: const InputDecoration(
                  labelText: 'Layout-Typ',
                  border: OutlineInputBorder(),
                  hintText: 'list, grid, custom, map, chat',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedScreen = DynamicScreen(
                id: screen.id,
                world: screen.world,
                title: DynamicText(
                  id: screen.title.id,
                  content: titleController.text.trim(),
                  styleId: screen.title.styleId,
                ),
                backgroundColor: bgColorController.text.trim(),
                layout: layoutController.text.trim(),
                widgets: screen.widgets,
                layoutConfig: screen.layoutConfig,
                enabled: screen.enabled,
                metadata: screen.metadata,
              );
              
              widget.onUpdate?.call(updatedScreen);
              Navigator.pop(context);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  /// GENERIC EDIT DIALOG (Fallback)
  void _showGenericEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('✏️ ${widget.entityType} bearbeiten'),
        content: Text('Editor für ${widget.entityType} noch nicht implementiert.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// EDITABLE DYNAMIC TEXT WIDGET
/// ============================================================================

class EditableDynamicText extends StatelessWidget {
  final DynamicText text;
  final DynamicTextStyle? style;
  final bool isEditMode;
  final Function(DynamicText)? onUpdate;

  const EditableDynamicText({
    super.key,
    required this.text,
    this.style,
    this.isEditMode = false,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      text.content,
      style: style?.toTextStyle(),
      textAlign: _parseTextAlign(style?.textAlign),
      maxLines: style?.maxLines,
      overflow: _parseOverflow(style?.overflow),
    );

    if (!isEditMode) {
      return textWidget;
    }

    return InlineEditWrapper(
      entityType: 'text',
      entityId: text.id,
      entityData: text,
      onUpdate: (updatedData) {
        onUpdate?.call(updatedData as DynamicText);
      },
      enabled: isEditMode,
      child: textWidget,
    );
  }

  TextAlign? _parseTextAlign(String? align) {
    switch (align?.toLowerCase()) {
      case 'left': return TextAlign.left;
      case 'right': return TextAlign.right;
      case 'center': return TextAlign.center;
      case 'justify': return TextAlign.justify;
      default: return null;
    }
  }

  TextOverflow? _parseOverflow(String? overflow) {
    switch (overflow?.toLowerCase()) {
      case 'clip': return TextOverflow.clip;
      case 'ellipsis': return TextOverflow.ellipsis;
      case 'fade': return TextOverflow.fade;
      case 'visible': return TextOverflow.visible;
      default: return null;
    }
  }
}

/// ============================================================================
/// EDITABLE DYNAMIC BUTTON WIDGET
/// ============================================================================

class EditableDynamicButton extends StatelessWidget {
  final DynamicButton button;
  final bool isEditMode;
  final Function(DynamicButton)? onUpdate;
  final VoidCallback? onPressed;

  const EditableDynamicButton({
    super.key,
    required this.button,
    this.isEditMode = false,
    this.onUpdate,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final buttonWidget = ElevatedButton(
      onPressed: button.enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: _parseColor(button.backgroundColor),
        foregroundColor: _parseColor(button.foregroundColor),
        minimumSize: Size(button.width ?? 120, button.height ?? 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(button.borderRadius),
          side: button.borderColor != null
              ? BorderSide(
                  color: _parseColor(button.borderColor!),
                  width: button.borderWidth,
                )
              : BorderSide.none,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (button.icon != null) ...[
            Text(button.icon!, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
          ],
          Text(button.label.content),
        ],
      ),
    );

    if (!isEditMode) {
      return buttonWidget;
    }

    return InlineEditWrapper(
      entityType: 'button',
      entityId: button.id,
      entityData: button,
      onUpdate: (updatedData) {
        onUpdate?.call(updatedData as DynamicButton);
      },
      enabled: isEditMode,
      child: buttonWidget,
    );
  }

  Color _parseColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    } else if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
    return Colors.white;
  }
}
