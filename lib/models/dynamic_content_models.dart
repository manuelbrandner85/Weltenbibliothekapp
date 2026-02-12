/// 🎯 DYNAMIC CONTENT MANAGEMENT SYSTEM - CORE MODELS
/// Vollständige Datenmodelle für OTA-Updates ohne APK-Neuinstallation
library;

import 'package:flutter/material.dart';

// ============================================================================
// 1. CONTENT TYPES - Alle editierbaren Inhaltstypen
// ============================================================================

/// Content Type Enum
enum ContentType {
  tab,           // Tabs (Wissen, Materie, Energie)
  tool,          // Spirit-Tools, Research-Tools
  marker,        // Karten-Marker mit Bildern/Videos
  media,         // Bilder, Videos, Audio
  text,          // Texte, Überschriften
  button,        // Buttons, CTAs
  popup,         // Popups, Dialoge
  feature,       // Feature Flags
  interaction,   // Click-Aktionen, Workflows
}

/// Publish Status
enum PublishStatus {
  draft,         // Entwurf, nur Admin sichtbar
  sandbox,       // In Sandbox-Vorschau
  scheduled,     // Geplant für späteren Release
  live,          // Live für alle Nutzer
  archived,      // Archiviert
}

/// Change Type für Audit Log
enum ChangeType {
  create,
  update,
  delete,
  publish,
  unpublish,
  rollback,
}

// ============================================================================
// 2. DYNAMIC TAB MODEL
// ============================================================================

/// Dynamic Tab Configuration
/// Ein Tab kann komplett über Backend konfiguriert werden
class DynamicTab {
  final String id;
  final String title;
  final String worldId;         // 'energie', 'materie', 'spirit'
  final IconData icon;
  final Color color;
  final int order;              // Display-Reihenfolge
  final bool isVisible;
  final PublishStatus status;
  final List<DynamicSection> sections;  // Sections innerhalb des Tabs
  final Map<String, dynamic> metadata;  // Zusätzliche Daten
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;       // Admin User ID
  final String? scheduledFor;   // ISO 8601 Timestamp

  const DynamicTab({
    required this.id,
    required this.title,
    required this.worldId,
    required this.icon,
    required this.color,
    this.order = 0,
    this.isVisible = true,
    this.status = PublishStatus.draft,
    this.sections = const [],
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.scheduledFor,
  });

  factory DynamicTab.fromJson(Map<String, dynamic> json) {
    return DynamicTab(
      id: json['id'] as String,
      title: json['title'] as String,
      worldId: json['world_id'] as String,
      icon: _iconFromString(json['icon'] as String? ?? 'bookmark'),
      color: Color(json['color'] as int? ?? 0xFF9B51E0),
      order: json['order'] as int? ?? 0,
      isVisible: json['is_visible'] as bool? ?? true,
      status: PublishStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PublishStatus.draft,
      ),
      sections: (json['sections'] as List<dynamic>?)
          ?.map((s) => DynamicSection.fromJson(s as Map<String, dynamic>))
          .toList() ?? [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String,
      scheduledFor: json['scheduled_for'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'world_id': worldId,
      'icon': _iconToString(icon),
      'color': color.value,  // Using .value is OK for serialization
      'order': order,
      'is_visible': isVisible,
      'status': status.name,
      'sections': sections.map((s) => s.toJson()).toList(),
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
      'scheduled_for': scheduledFor,
    };
  }

  DynamicTab copyWith({
    String? title,
    IconData? icon,
    Color? color,
    int? order,
    bool? isVisible,
    PublishStatus? status,
    List<DynamicSection>? sections,
    Map<String, dynamic>? metadata,
    String? scheduledFor,
  }) {
    return DynamicTab(
      id: id,
      title: title ?? this.title,
      worldId: worldId,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      order: order ?? this.order,
      isVisible: isVisible ?? this.isVisible,
      status: status ?? this.status,
      sections: sections ?? this.sections,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      createdBy: createdBy,
      scheduledFor: scheduledFor ?? this.scheduledFor,
    );
  }
}

// ============================================================================
// 3. DYNAMIC SECTION MODEL
// ============================================================================

/// Section innerhalb eines Tabs
class DynamicSection {
  final String id;
  final String title;
  final String? subtitle;
  final int order;
  final bool isVisible;
  final String layoutType;      // 'list', 'grid', 'carousel', 'custom'
  final List<DynamicContent> contents;
  final Map<String, dynamic> config;  // Layout-spezifische Config

  const DynamicSection({
    required this.id,
    required this.title,
    this.subtitle,
    this.order = 0,
    this.isVisible = true,
    this.layoutType = 'list',
    this.contents = const [],
    this.config = const {},
  });

  factory DynamicSection.fromJson(Map<String, dynamic> json) {
    return DynamicSection(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      order: json['order'] as int? ?? 0,
      isVisible: json['is_visible'] as bool? ?? true,
      layoutType: json['layout_type'] as String? ?? 'list',
      contents: (json['contents'] as List<dynamic>?)
          ?.map((c) => DynamicContent.fromJson(c as Map<String, dynamic>))
          .toList() ?? [],
      config: json['config'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'order': order,
      'is_visible': isVisible,
      'layout_type': layoutType,
      'contents': contents.map((c) => c.toJson()).toList(),
      'config': config,
    };
  }
}

// ============================================================================
// 4. DYNAMIC CONTENT MODEL
// ============================================================================

/// Generic Content Item - kann Text, Tool, Marker, Media etc. sein
class DynamicContent {
  final String id;
  final ContentType type;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? videoUrl;
  final int order;
  final bool isVisible;
  final Map<String, dynamic> data;      // Type-spezifische Daten
  final List<DynamicAction> actions;    // Click-Aktionen
  final Map<String, dynamic> metadata;

  const DynamicContent({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.imageUrl,
    this.videoUrl,
    this.order = 0,
    this.isVisible = true,
    this.data = const {},
    this.actions = const [],
    this.metadata = const {},
  });

  factory DynamicContent.fromJson(Map<String, dynamic> json) {
    return DynamicContent(
      id: json['id'] as String,
      type: ContentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ContentType.text,
      ),
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      videoUrl: json['video_url'] as String?,
      order: json['order'] as int? ?? 0,
      isVisible: json['is_visible'] as bool? ?? true,
      data: json['data'] as Map<String, dynamic>? ?? {},
      actions: (json['actions'] as List<dynamic>?)
          ?.map((a) => DynamicAction.fromJson(a as Map<String, dynamic>))
          .toList() ?? [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'order': order,
      'is_visible': isVisible,
      'data': data,
      'actions': actions.map((a) => a.toJson()).toList(),
      'metadata': metadata,
    };
  }
}

// ============================================================================
// 5. DYNAMIC ACTION MODEL
// ============================================================================

/// Interaktive Aktionen (Button Click, Marker Tap, etc.)
class DynamicAction {
  final String id;
  final String type;            // 'open_popup', 'play_video', 'navigate', 'start_chat'
  final String label;
  final IconData? icon;
  final Map<String, dynamic> parameters;

  const DynamicAction({
    required this.id,
    required this.type,
    required this.label,
    this.icon,
    this.parameters = const {},
  });

  factory DynamicAction.fromJson(Map<String, dynamic> json) {
    return DynamicAction(
      id: json['id'] as String,
      type: json['type'] as String,
      label: json['label'] as String,
      icon: json['icon'] != null ? _iconFromString(json['icon'] as String) : null,
      parameters: json['parameters'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'label': label,
      'icon': icon != null ? _iconToString(icon!) : null,
      'parameters': parameters,
    };
  }
}

// ============================================================================
// 6. MAP MARKER MODEL
// ============================================================================

/// Dynamic Karten-Marker mit Bildern/Videos
class DynamicMarker {
  final String id;
  final String title;
  final String? description;
  final double latitude;
  final double longitude;
  final String category;        // 'ufo', 'power_network', 'historical'
  final String? imageUrl;
  final String? videoUrl;
  final List<String> galleryUrls;  // Mehrere Bilder
  final bool isVisible;
  final PublishStatus status;
  final List<DynamicAction> actions;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  const DynamicMarker({
    required this.id,
    required this.title,
    this.description,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.imageUrl,
    this.videoUrl,
    this.galleryUrls = const [],
    this.isVisible = true,
    this.status = PublishStatus.draft,
    this.actions = const [],
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory DynamicMarker.fromJson(Map<String, dynamic> json) {
    return DynamicMarker(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      category: json['category'] as String,
      imageUrl: json['image_url'] as String?,
      videoUrl: json['video_url'] as String?,
      galleryUrls: (json['gallery_urls'] as List<dynamic>?)
          ?.map((u) => u as String)
          .toList() ?? [],
      isVisible: json['is_visible'] as bool? ?? true,
      status: PublishStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PublishStatus.draft,
      ),
      actions: (json['actions'] as List<dynamic>?)
          ?.map((a) => DynamicAction.fromJson(a as Map<String, dynamic>))
          .toList() ?? [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'gallery_urls': galleryUrls,
      'is_visible': isVisible,
      'status': status.name,
      'actions': actions.map((a) => a.toJson()).toList(),
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
    };
  }
}

// ============================================================================
// 7. FEATURE FLAG MODEL
// ============================================================================

/// Feature Flags für A/B Testing und gradual Rollouts
class FeatureFlag {
  final String id;
  final String name;
  final String description;
  final bool isEnabled;
  final double rolloutPercentage;  // 0.0 - 1.0
  final List<String> enabledForUsers;  // Spezifische User IDs
  final List<String> enabledForRoles;  // Rollen: 'admin', 'beta_tester'
  final DateTime? expiresAt;
  final Map<String, dynamic> config;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  const FeatureFlag({
    required this.id,
    required this.name,
    required this.description,
    this.isEnabled = false,
    this.rolloutPercentage = 0.0,
    this.enabledForUsers = const [],
    this.enabledForRoles = const [],
    this.expiresAt,
    this.config = const {},
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory FeatureFlag.fromJson(Map<String, dynamic> json) {
    return FeatureFlag(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      isEnabled: json['is_enabled'] as bool? ?? false,
      rolloutPercentage: (json['rollout_percentage'] as num?)?.toDouble() ?? 0.0,
      enabledForUsers: (json['enabled_for_users'] as List<dynamic>?)
          ?.map((u) => u as String)
          .toList() ?? [],
      enabledForRoles: (json['enabled_for_roles'] as List<dynamic>?)
          ?.map((r) => r as String)
          .toList() ?? [],
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      config: json['config'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_enabled': isEnabled,
      'rollout_percentage': rolloutPercentage,
      'enabled_for_users': enabledForUsers,
      'enabled_for_roles': enabledForRoles,
      'expires_at': expiresAt?.toIso8601String(),
      'config': config,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  /// Check if feature is enabled for specific user
  bool isEnabledFor(String userId, String userRole) {
    if (!isEnabled) return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    
    // Check role
    if (enabledForRoles.contains(userRole)) return true;
    
    // Check specific user
    if (enabledForUsers.contains(userId)) return true;
    
    // Check rollout percentage
    if (rolloutPercentage >= 1.0) return true;
    if (rolloutPercentage <= 0.0) return false;
    
    // Consistent hash-based rollout
    final hash = userId.hashCode.abs() % 100;
    return (hash / 100.0) < rolloutPercentage;
  }
}

// ============================================================================
// 8. CHANGE LOG MODEL
// ============================================================================

/// Audit Log für alle Änderungen
class ChangeLog {
  final String id;
  final ChangeType type;
  final String entityType;      // 'tab', 'tool', 'marker', etc.
  final String entityId;
  final String adminId;
  final String adminUsername;
  final Map<String, dynamic> before;  // Daten vor Änderung
  final Map<String, dynamic> after;   // Daten nach Änderung
  final String? reason;          // Optional: Grund für Änderung
  final DateTime timestamp;

  const ChangeLog({
    required this.id,
    required this.type,
    required this.entityType,
    required this.entityId,
    required this.adminId,
    required this.adminUsername,
    required this.before,
    required this.after,
    this.reason,
    required this.timestamp,
  });

  factory ChangeLog.fromJson(Map<String, dynamic> json) {
    return ChangeLog(
      id: json['id'] as String,
      type: ChangeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChangeType.update,
      ),
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      adminId: json['admin_id'] as String,
      adminUsername: json['admin_username'] as String,
      before: json['before'] as Map<String, dynamic>? ?? {},
      after: json['after'] as Map<String, dynamic>? ?? {},
      reason: json['reason'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'entity_type': entityType,
      'entity_id': entityId,
      'admin_id': adminId,
      'admin_username': adminUsername,
      'before': before,
      'after': after,
      'reason': reason,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

// ============================================================================
// 9. VERSION SNAPSHOT MODEL
// ============================================================================

/// Complete App State Snapshot für Rollback
class VersionSnapshot {
  final String id;
  final String version;
  final String description;
  final Map<String, dynamic> appState;  // Kompletter App-State
  final String createdBy;
  final DateTime createdAt;
  final List<String> tags;      // 'production', 'beta', 'backup'

  const VersionSnapshot({
    required this.id,
    required this.version,
    required this.description,
    required this.appState,
    required this.createdBy,
    required this.createdAt,
    this.tags = const [],
  });

  factory VersionSnapshot.fromJson(Map<String, dynamic> json) {
    return VersionSnapshot(
      id: json['id'] as String,
      version: json['version'] as String,
      description: json['description'] as String,
      appState: json['app_state'] as Map<String, dynamic>,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      tags: (json['tags'] as List<dynamic>?)
          ?.map((t) => t as String)
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'version': version,
      'description': description,
      'app_state': appState,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'tags': tags,
    };
  }
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/// Icon String Conversion
IconData _iconFromString(String iconName) {
  final iconMap = <String, IconData>{
    'bookmark': Icons.bookmark,
    'explore': Icons.explore,
    'psychology': Icons.psychology,
    'map': Icons.map,
    'search': Icons.search,
    'settings': Icons.settings,
    'star': Icons.star,
    'favorite': Icons.favorite,
    'home': Icons.home,
    'person': Icons.person,
    'chat': Icons.chat,
    'notifications': Icons.notifications,
    'info': Icons.info,
    'help': Icons.help,
    // Add more icons as needed
  };
  return iconMap[iconName] ?? Icons.bookmark;
}

String _iconToString(IconData icon) {
  final iconMap = <int, String>{
    Icons.bookmark.codePoint: 'bookmark',
    Icons.explore.codePoint: 'explore',
    Icons.psychology.codePoint: 'psychology',
    Icons.map.codePoint: 'map',
    Icons.search.codePoint: 'search',
    Icons.settings.codePoint: 'settings',
    Icons.star.codePoint: 'star',
    Icons.favorite.codePoint: 'favorite',
    Icons.home.codePoint: 'home',
    Icons.person.codePoint: 'person',
    Icons.chat.codePoint: 'chat',
    Icons.notifications.codePoint: 'notifications',
    Icons.info.codePoint: 'info',
    Icons.help.codePoint: 'help',
  };
  return iconMap[icon.codePoint] ?? 'bookmark';
}
