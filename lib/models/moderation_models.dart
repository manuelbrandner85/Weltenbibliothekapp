/// Flagged Content Model
/// Repräsentiert gemeldeten Inhalt (Post oder Kommentar)
class FlaggedContent {
  final int id;
  final String world;
  final String contentType; // 'post' oder 'comment'
  final String contentId;
  final String? contentAuthorId;
  final String? contentAuthorUsername;
  final String flaggedById;
  final String flaggedByUsername;
  final String flaggedByRole;
  final String reason;
  final String status; // 'pending', 'resolved', 'dismissed'
  final String? resolvedById;
  final String? resolvedByUsername;
  final String? resolutionAction;
  final String? resolutionNotes;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  
  FlaggedContent({
    required this.id,
    required this.world,
    required this.contentType,
    required this.contentId,
    this.contentAuthorId,
    this.contentAuthorUsername,
    required this.flaggedById,
    required this.flaggedByUsername,
    required this.flaggedByRole,
    required this.reason,
    required this.status,
    this.resolvedById,
    this.resolvedByUsername,
    this.resolutionAction,
    this.resolutionNotes,
    this.resolvedAt,
    required this.createdAt,
  });
  
  factory FlaggedContent.fromJson(Map<String, dynamic> json) {
    return FlaggedContent(
      id: json['id'] as int,
      world: json['world'] as String,
      contentType: json['content_type'] as String,
      contentId: json['content_id'] as String,
      contentAuthorId: json['content_author_id'] as String?,
      contentAuthorUsername: json['content_author_username'] as String?,
      flaggedById: json['flagged_by_id'] as String,
      flaggedByUsername: json['flagged_by_username'] as String,
      flaggedByRole: json['flagged_by_role'] as String,
      reason: json['reason'] as String,
      status: json['status'] as String,
      resolvedById: json['resolved_by_id'] as String?,
      resolvedByUsername: json['resolved_by_username'] as String?,
      resolutionAction: json['resolution_action'] as String?,
      resolutionNotes: json['resolution_notes'] as String?,
      resolvedAt: json['resolved_at'] != null 
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  
  bool get isPending => status == 'pending';
  bool get isResolved => status == 'resolved';
  bool get isDismissed => status == 'dismissed';
  
  String get statusText {
    switch (status) {
      case 'pending':
        return 'Ausstehend';
      case 'resolved':
        return 'Bearbeitet';
      case 'dismissed':
        return 'Verworfen';
      default:
        return status;
    }
  }
}

/// User Mute Model
/// Repräsentiert eine User-Sperre
class UserMute {
  final int id;
  final String world;
  final String userId;
  final String username;
  final String muteType; // '24h' oder 'permanent'
  final String mutedById;
  final String mutedByUsername;
  final String mutedByRole;
  final String? reason;
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime? unmutedAt;
  final String? unmutedById;
  final String? unmutedByUsername;
  
  UserMute({
    required this.id,
    required this.world,
    required this.userId,
    required this.username,
    required this.muteType,
    required this.mutedById,
    required this.mutedByUsername,
    required this.mutedByRole,
    this.reason,
    required this.isActive,
    this.expiresAt,
    required this.createdAt,
    this.unmutedAt,
    this.unmutedById,
    this.unmutedByUsername,
  });
  
  factory UserMute.fromJson(Map<String, dynamic> json) {
    return UserMute(
      id: json['id'] as int,
      world: json['world'] as String,
      userId: json['user_id'] as String,
      username: json['username'] as String,
      muteType: json['mute_type'] as String,
      mutedById: json['muted_by_id'] as String,
      mutedByUsername: json['muted_by_username'] as String,
      mutedByRole: json['muted_by_role'] as String,
      reason: json['reason'] as String?,
      isActive: (json['is_active'] as int) == 1,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      unmutedAt: json['unmuted_at'] != null
          ? DateTime.parse(json['unmuted_at'] as String)
          : null,
      unmutedById: json['unmuted_by_id'] as String?,
      unmutedByUsername: json['unmuted_by_username'] as String?,
    );
  }
  
  bool get isPermanent => muteType == 'permanent';
  bool get is24h => muteType == '24h';
  
  bool get isExpired {
    if (!isActive) return true;
    if (isPermanent) return false;
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
  
  String get muteTypeText {
    return isPermanent ? 'Permanent' : '24 Stunden';
  }
  
  String? get expiresText {
    if (expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    if (remaining.isNegative) return 'Abgelaufen';
    
    if (remaining.inHours > 0) {
      return 'Noch ${remaining.inHours}h ${remaining.inMinutes % 60}m';
    } else {
      return 'Noch ${remaining.inMinutes}m';
    }
  }
}

/// Moderation Log Entry Model
/// Repräsentiert einen Eintrag im Moderation-Log
class ModerationLogEntry {
  final int id;
  final String world;
  final String actionType;
  final String moderatorId;
  final String moderatorUsername;
  final String moderatorRole;
  final String targetType;
  final String targetId;
  final String? targetUsername;
  final String? reason;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  
  ModerationLogEntry({
    required this.id,
    required this.world,
    required this.actionType,
    required this.moderatorId,
    required this.moderatorUsername,
    required this.moderatorRole,
    required this.targetType,
    required this.targetId,
    this.targetUsername,
    this.reason,
    this.metadata,
    required this.createdAt,
  });
  
  factory ModerationLogEntry.fromJson(Map<String, dynamic> json) {
    return ModerationLogEntry(
      id: json['id'] as int,
      world: json['world'] as String,
      actionType: json['action_type'] as String,
      moderatorId: json['moderator_id'] as String,
      moderatorUsername: json['moderator_username'] as String,
      moderatorRole: json['moderator_role'] as String,
      targetType: json['target_type'] as String,
      targetId: json['target_id'] as String,
      targetUsername: json['target_username'] as String?,
      reason: json['reason'] as String?,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  
  String get actionText {
    switch (actionType) {
      case 'delete_post':
        return 'Post gelöscht';
      case 'delete_comment':
        return 'Kommentar gelöscht';
      case 'edit_post':
        return 'Post bearbeitet';
      case 'edit_comment':
        return 'Kommentar bearbeitet';
      case 'mute_user_24h':
        return 'User 24h gesperrt';
      case 'mute_user_permanent':
        return 'User permanent gesperrt';
      case 'unmute_user':
        return 'User entsperrt';
      case 'flag_content':
        return 'Content gemeldet';
      case 'resolve_flag':
        return 'Meldung bearbeitet';
      case 'dismiss_flag':
        return 'Meldung verworfen';
      default:
        return actionType;
    }
  }
  
  bool get isRootAdmin => moderatorRole == 'root_admin';
}
