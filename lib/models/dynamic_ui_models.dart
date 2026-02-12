/// Dynamic UI Models - Vollständiges Live-Edit-System
/// 
/// Ermöglicht Content Editors, ALLE UI-Elemente live zu bearbeiten:
/// - Screens, Tabs, Tools, Marker, Medien
/// - Texte, Fonts, Farben, Styles
/// - Buttons, Aktionen, Interaktionen
library;

import 'package:flutter/material.dart';
import 'dart:convert';

/// ============================================================================
/// 1. BASE MODELS - Grundlegende Datenstrukturen
/// ============================================================================

/// Version Control für alle Änderungen
class ContentVersion {
  final String versionId;
  final DateTime timestamp;
  final String editorId;
  final String editorName;
  final String changeDescription;
  final Map<String, dynamic> oldValue;
  final Map<String, dynamic> newValue;
  final String changeType; // 'create', 'update', 'delete', 'reorder'
  final String entityType; // 'screen', 'tab', 'tool', 'marker', 'text', etc.
  final String entityId;

  ContentVersion({
    required this.versionId,
    required this.timestamp,
    required this.editorId,
    required this.editorName,
    required this.changeDescription,
    required this.oldValue,
    required this.newValue,
    required this.changeType,
    required this.entityType,
    required this.entityId,
  });

  factory ContentVersion.fromJson(Map<String, dynamic> json) {
    return ContentVersion(
      versionId: json['version_id'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      editorId: json['editor_id'] ?? '',
      editorName: json['editor_name'] ?? '',
      changeDescription: json['change_description'] ?? '',
      oldValue: json['old_value'] ?? {},
      newValue: json['new_value'] ?? {},
      changeType: json['change_type'] ?? '',
      entityType: json['entity_type'] ?? '',
      entityId: json['entity_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version_id': versionId,
      'timestamp': timestamp.toIso8601String(),
      'editor_id': editorId,
      'editor_name': editorName,
      'change_description': changeDescription,
      'old_value': oldValue,
      'new_value': newValue,
      'change_type': changeType,
      'entity_type': entityType,
      'entity_id': entityId,
    };
  }
}

/// ============================================================================
/// 2. TEXT STYLING - Vollständige Schriftverwaltung
/// ============================================================================

/// Dynamische Text-Styles (Farbe, Größe, Font, etc.)
class DynamicTextStyle {
  final String id;
  final String name; // z.B. "heading1", "body", "caption"
  final double fontSize;
  final String fontFamily;
  final String fontWeight; // 'normal', 'bold', 'w100'-'w900'
  final String fontStyle; // 'normal', 'italic'
  final String color; // Hex-Color: "#FFFFFF"
  final double? letterSpacing;
  final double? wordSpacing;
  final double? height; // Line height multiplier
  final String? decoration; // 'none', 'underline', 'lineThrough', 'overline'
  final String? decorationColor;
  final String? decorationStyle; // 'solid', 'double', 'dotted', 'dashed', 'wavy'
  final String? textAlign; // 'left', 'right', 'center', 'justify'
  final int? maxLines;
  final String? overflow; // 'clip', 'ellipsis', 'fade', 'visible'

  DynamicTextStyle({
    required this.id,
    required this.name,
    required this.fontSize,
    this.fontFamily = 'Roboto',
    this.fontWeight = 'normal',
    this.fontStyle = 'normal',
    required this.color,
    this.letterSpacing,
    this.wordSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.decorationStyle,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  factory DynamicTextStyle.fromJson(Map<String, dynamic> json) {
    return DynamicTextStyle(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      fontSize: (json['font_size'] ?? 16).toDouble(),
      fontFamily: json['font_family'] ?? 'Roboto',
      fontWeight: json['font_weight'] ?? 'normal',
      fontStyle: json['font_style'] ?? 'normal',
      color: json['color'] ?? '#FFFFFF',
      letterSpacing: json['letter_spacing']?.toDouble(),
      wordSpacing: json['word_spacing']?.toDouble(),
      height: json['height']?.toDouble(),
      decoration: json['decoration'],
      decorationColor: json['decoration_color'],
      decorationStyle: json['decoration_style'],
      textAlign: json['text_align'],
      maxLines: json['max_lines'],
      overflow: json['overflow'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'font_size': fontSize,
      'font_family': fontFamily,
      'font_weight': fontWeight,
      'font_style': fontStyle,
      'color': color,
      if (letterSpacing != null) 'letter_spacing': letterSpacing,
      if (wordSpacing != null) 'word_spacing': wordSpacing,
      if (height != null) 'height': height,
      if (decoration != null) 'decoration': decoration,
      if (decorationColor != null) 'decoration_color': decorationColor,
      if (decorationStyle != null) 'decoration_style': decorationStyle,
      if (textAlign != null) 'text_align': textAlign,
      if (maxLines != null) 'max_lines': maxLines,
      if (overflow != null) 'overflow': overflow,
    };
  }

  /// Convert to Flutter TextStyle
  TextStyle toTextStyle() {
    return TextStyle(
      fontSize: fontSize,
      fontFamily: fontFamily,
      fontWeight: _parseFontWeight(fontWeight),
      fontStyle: fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
      color: _parseColor(color),
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      height: height,
      decoration: _parseDecoration(decoration),
      decorationColor: decorationColor != null ? _parseColor(decorationColor!) : null,
      decorationStyle: _parseDecorationStyle(decorationStyle),
    );
  }

  FontWeight _parseFontWeight(String weight) {
    switch (weight.toLowerCase()) {
      case 'bold': return FontWeight.bold;
      case 'w100': return FontWeight.w100;
      case 'w200': return FontWeight.w200;
      case 'w300': return FontWeight.w300;
      case 'w400': return FontWeight.w400;
      case 'w500': return FontWeight.w500;
      case 'w600': return FontWeight.w600;
      case 'w700': return FontWeight.w700;
      case 'w800': return FontWeight.w800;
      case 'w900': return FontWeight.w900;
      default: return FontWeight.normal;
    }
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

  TextDecoration _parseDecoration(String? decoration) {
    switch (decoration?.toLowerCase()) {
      case 'underline': return TextDecoration.underline;
      case 'linethrough': return TextDecoration.lineThrough;
      case 'overline': return TextDecoration.overline;
      default: return TextDecoration.none;
    }
  }

  TextDecorationStyle? _parseDecorationStyle(String? style) {
    switch (style?.toLowerCase()) {
      case 'solid': return TextDecorationStyle.solid;
      case 'double': return TextDecorationStyle.double;
      case 'dotted': return TextDecorationStyle.dotted;
      case 'dashed': return TextDecorationStyle.dashed;
      case 'wavy': return TextDecorationStyle.wavy;
      default: return null;
    }
  }
}

/// ============================================================================
/// 3. DYNAMIC TEXT - Editierbare Texte
/// ============================================================================

/// Dynamischer Text mit Live-Edit
class DynamicText {
  final String id;
  final String content;
  final String styleId; // Referenz zu DynamicTextStyle
  final String? semanticLabel; // Accessibility
  final Map<String, String> translations; // Multi-Language Support

  DynamicText({
    required this.id,
    required this.content,
    required this.styleId,
    this.semanticLabel,
    this.translations = const {},
  });

  factory DynamicText.fromJson(Map<String, dynamic> json) {
    return DynamicText(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      styleId: json['style_id'] ?? 'body',
      semanticLabel: json['semantic_label'],
      translations: Map<String, String>.from(json['translations'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'style_id': styleId,
      if (semanticLabel != null) 'semantic_label': semanticLabel,
      'translations': translations,
    };
  }
}

/// ============================================================================
/// 4. DYNAMIC BUTTON - Editierbare Buttons mit Aktionen
/// ============================================================================

/// Button-Aktion (was passiert beim Klick)
class ButtonAction {
  final String type; // 'navigate', 'video', 'popup', 'quiz', 'chat', 'external_link', 'custom'
  final String target; // Screen-ID, Video-URL, Quiz-ID, etc.
  final Map<String, dynamic> parameters; // Zusätzliche Parameter

  ButtonAction({
    required this.type,
    required this.target,
    this.parameters = const {},
  });

  factory ButtonAction.fromJson(Map<String, dynamic> json) {
    return ButtonAction(
      type: json['type'] ?? 'navigate',
      target: json['target'] ?? '',
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'target': target,
      'parameters': parameters,
    };
  }
}

/// Dynamischer Button
class DynamicButton {
  final String id;
  final DynamicText label;
  final String? icon; // Emoji oder Icon-Name
  final String backgroundColor; // Hex-Color
  final String foregroundColor; // Hex-Color
  final ButtonAction action;
  final double? width;
  final double? height;
  final double borderRadius;
  final String? borderColor;
  final double borderWidth;
  final bool enabled;

  DynamicButton({
    required this.id,
    required this.label,
    this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.action,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.borderColor,
    this.borderWidth = 0,
    this.enabled = true,
  });

  factory DynamicButton.fromJson(Map<String, dynamic> json) {
    return DynamicButton(
      id: json['id'] ?? '',
      label: DynamicText.fromJson(json['label'] ?? {}),
      icon: json['icon'],
      backgroundColor: json['background_color'] ?? '#9B51E0',
      foregroundColor: json['foreground_color'] ?? '#FFFFFF',
      action: ButtonAction.fromJson(json['action'] ?? {}),
      width: json['width']?.toDouble(),
      height: json['height']?.toDouble(),
      borderRadius: (json['border_radius'] ?? 8.0).toDouble(),
      borderColor: json['border_color'],
      borderWidth: (json['border_width'] ?? 0).toDouble(),
      enabled: json['enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label.toJson(),
      if (icon != null) 'icon': icon,
      'background_color': backgroundColor,
      'foreground_color': foregroundColor,
      'action': action.toJson(),
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      'border_radius': borderRadius,
      if (borderColor != null) 'border_color': borderColor,
      'border_width': borderWidth,
      'enabled': enabled,
    };
  }
}

/// ============================================================================
/// 5. DYNAMIC MEDIA - Bilder, Videos, Audio
/// ============================================================================

class DynamicMedia {
  final String id;
  final String type; // 'image', 'video', 'audio', 'embed'
  final String url;
  final String? thumbnail;
  final String? caption;
  final double? width;
  final double? height;
  final String fit; // 'cover', 'contain', 'fill', 'fitWidth', 'fitHeight'
  final bool autoPlay;
  final bool loop;
  final Map<String, dynamic> metadata;

  DynamicMedia({
    required this.id,
    required this.type,
    required this.url,
    this.thumbnail,
    this.caption,
    this.width,
    this.height,
    this.fit = 'cover',
    this.autoPlay = false,
    this.loop = false,
    this.metadata = const {},
  });

  factory DynamicMedia.fromJson(Map<String, dynamic> json) {
    return DynamicMedia(
      id: json['id'] ?? '',
      type: json['type'] ?? 'image',
      url: json['url'] ?? '',
      thumbnail: json['thumbnail'],
      caption: json['caption'],
      width: json['width']?.toDouble(),
      height: json['height']?.toDouble(),
      fit: json['fit'] ?? 'cover',
      autoPlay: json['auto_play'] ?? false,
      loop: json['loop'] ?? false,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'url': url,
      if (thumbnail != null) 'thumbnail': thumbnail,
      if (caption != null) 'caption': caption,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      'fit': fit,
      'auto_play': autoPlay,
      'loop': loop,
      'metadata': metadata,
    };
  }
}

/// ============================================================================
/// 6. DYNAMIC TAB - Editierbare Tabs
/// ============================================================================

class DynamicTab {
  final String id;
  final DynamicText label;
  final String? icon;
  final String screenId; // Welcher Screen wird geladen
  final int order; // Sortierung
  final bool enabled;
  final Map<String, dynamic> metadata;

  DynamicTab({
    required this.id,
    required this.label,
    this.icon,
    required this.screenId,
    required this.order,
    this.enabled = true,
    this.metadata = const {},
  });

  factory DynamicTab.fromJson(Map<String, dynamic> json) {
    return DynamicTab(
      id: json['id'] ?? '',
      label: DynamicText.fromJson(json['label'] ?? {}),
      icon: json['icon'],
      screenId: json['screen_id'] ?? '',
      order: json['order'] ?? 0,
      enabled: json['enabled'] ?? true,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label.toJson(),
      if (icon != null) 'icon': icon,
      'screen_id': screenId,
      'order': order,
      'enabled': enabled,
      'metadata': metadata,
    };
  }
}

/// ============================================================================
/// 7. DYNAMIC MARKER - Map-Marker mit Popups
/// ============================================================================

class DynamicMarker {
  final String id;
  final String category;
  final double latitude;
  final double longitude;
  final DynamicText title;
  final DynamicText? description;
  final String? icon;
  final String markerColor; // Hex-Color
  final List<DynamicMedia> media;
  final List<DynamicButton> actions;
  final Map<String, dynamic> metadata;

  DynamicMarker({
    required this.id,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.title,
    this.description,
    this.icon,
    required this.markerColor,
    this.media = const [],
    this.actions = const [],
    this.metadata = const {},
  });

  factory DynamicMarker.fromJson(Map<String, dynamic> json) {
    return DynamicMarker(
      id: json['id'] ?? '',
      category: json['category'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      title: DynamicText.fromJson(json['title'] ?? {}),
      description: json['description'] != null 
          ? DynamicText.fromJson(json['description'])
          : null,
      icon: json['icon'],
      markerColor: json['marker_color'] ?? '#FF5733',
      media: (json['media'] as List<dynamic>?)
          ?.map((m) => DynamicMedia.fromJson(m))
          .toList() ?? [],
      actions: (json['actions'] as List<dynamic>?)
          ?.map((a) => DynamicButton.fromJson(a))
          .toList() ?? [],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'title': title.toJson(),
      if (description != null) 'description': description!.toJson(),
      if (icon != null) 'icon': icon,
      'marker_color': markerColor,
      'media': media.map((m) => m.toJson()).toList(),
      'actions': actions.map((a) => a.toJson()).toList(),
      'metadata': metadata,
    };
  }
}

/// ============================================================================
/// 8. DYNAMIC TOOL - Interaktive Tools
/// ============================================================================

class DynamicTool {
  final String id;
  final String world; // 'energie', 'materie'
  final String room; // Tab/Room-ID
  final DynamicText title;
  final DynamicText? description;
  final String? icon;
  final String toolType; // 'meditation_timer', 'chakra_scan', 'quiz', 'calculator', 'custom'
  final Map<String, dynamic> config; // Tool-spezifische Konfiguration
  final int order;
  final bool enabled;

  DynamicTool({
    required this.id,
    required this.world,
    required this.room,
    required this.title,
    this.description,
    this.icon,
    required this.toolType,
    this.config = const {},
    required this.order,
    this.enabled = true,
  });

  factory DynamicTool.fromJson(Map<String, dynamic> json) {
    return DynamicTool(
      id: json['id'] ?? '',
      world: json['world'] ?? '',
      room: json['room'] ?? '',
      title: DynamicText.fromJson(json['title'] ?? {}),
      description: json['description'] != null
          ? DynamicText.fromJson(json['description'])
          : null,
      icon: json['icon'],
      toolType: json['tool_type'] ?? 'custom',
      config: Map<String, dynamic>.from(json['config'] ?? {}),
      order: json['order'] ?? 0,
      enabled: json['enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'world': world,
      'room': room,
      'title': title.toJson(),
      if (description != null) 'description': description!.toJson(),
      if (icon != null) 'icon': icon,
      'tool_type': toolType,
      'config': config,
      'order': order,
      'enabled': enabled,
    };
  }
}

/// ============================================================================
/// 9. DYNAMIC SCREEN - Vollständiger Screen mit Layout
/// ============================================================================

class DynamicScreen {
  final String id;
  final String world; // 'energie', 'materie'
  final DynamicText title;
  final String backgroundColor; // Hex-Color
  final String layout; // 'list', 'grid', 'custom', 'map', 'chat'
  final List<dynamic> widgets; // Mix aus DynamicText, DynamicButton, DynamicMedia, etc.
  final Map<String, dynamic> layoutConfig; // Spalten, Spacing, etc.
  final bool enabled;
  final Map<String, dynamic> metadata;

  DynamicScreen({
    required this.id,
    required this.world,
    required this.title,
    required this.backgroundColor,
    required this.layout,
    this.widgets = const [],
    this.layoutConfig = const {},
    this.enabled = true,
    this.metadata = const {},
  });

  factory DynamicScreen.fromJson(Map<String, dynamic> json) {
    return DynamicScreen(
      id: json['id'] ?? '',
      world: json['world'] ?? '',
      title: DynamicText.fromJson(json['title'] ?? {}),
      backgroundColor: json['background_color'] ?? '#0A0A0F',
      layout: json['layout'] ?? 'list',
      widgets: json['widgets'] ?? [],
      layoutConfig: Map<String, dynamic>.from(json['layout_config'] ?? {}),
      enabled: json['enabled'] ?? true,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'world': world,
      'title': title.toJson(),
      'background_color': backgroundColor,
      'layout': layout,
      'widgets': widgets,
      'layout_config': layoutConfig,
      'enabled': enabled,
      'metadata': metadata,
    };
  }
}

/// ============================================================================
/// 10. FEATURE FLAGS - Dynamische Feature-Aktivierung
/// ============================================================================

class FeatureFlag {
  final String id;
  final String name;
  final bool enabled;
  final List<String> enabledForRoles; // Welche Rollen sehen das Feature
  final DateTime? enabledFrom;
  final DateTime? enabledUntil;
  final Map<String, dynamic> config;

  FeatureFlag({
    required this.id,
    required this.name,
    required this.enabled,
    this.enabledForRoles = const [],
    this.enabledFrom,
    this.enabledUntil,
    this.config = const {},
  });

  factory FeatureFlag.fromJson(Map<String, dynamic> json) {
    return FeatureFlag(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      enabled: json['enabled'] ?? false,
      enabledForRoles: List<String>.from(json['enabled_for_roles'] ?? []),
      enabledFrom: json['enabled_from'] != null
          ? DateTime.parse(json['enabled_from'])
          : null,
      enabledUntil: json['enabled_until'] != null
          ? DateTime.parse(json['enabled_until'])
          : null,
      config: Map<String, dynamic>.from(json['config'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'enabled': enabled,
      'enabled_for_roles': enabledForRoles,
      if (enabledFrom != null) 'enabled_from': enabledFrom!.toIso8601String(),
      if (enabledUntil != null) 'enabled_until': enabledUntil!.toIso8601String(),
      'config': config,
    };
  }

  /// Check if feature is currently enabled
  bool isActive({String? userRole}) {
    if (!enabled) return false;
    
    final now = DateTime.now();
    if (enabledFrom != null && now.isBefore(enabledFrom!)) return false;
    if (enabledUntil != null && now.isAfter(enabledUntil!)) return false;
    
    if (userRole != null && enabledForRoles.isNotEmpty) {
      return enabledForRoles.contains(userRole);
    }
    
    return true;
  }
}
