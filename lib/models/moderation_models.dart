/// Flagged Content Model
/// Repräsentiert gemeldeten Inhalt (Post oder Kommentar)
class FlaggedContent {
  final dynamic id; // int oder String (Worker gibt String-IDs zurück)
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
      // id kann int oder String sein (Worker-Kompatibilität)
      id: json['id'] ?? json['flag_id'] ?? 0,
      world: (json['world'] as String?) ?? 'materie',
      contentType: (json['content_type'] as String?) ?? 'chat_message',
      contentId: (json['content_id'] ?? '').toString(),
      contentAuthorId: json['content_author_id'] as String?,
      contentAuthorUsername: (json['content_author_username'] ?? json['author_username']) as String?,
      flaggedById: (json['flagged_by_id'] ?? json['reported_by'] ?? 'system') as String,
      flaggedByUsername: (json['flagged_by_username'] ?? json['reported_by'] ?? 'system') as String,
      flaggedByRole: (json['flagged_by_role'] ?? 'user') as String,
      reason: (json['reason'] ?? '') as String,
      status: (json['status'] ?? 'pending') as String,
      resolvedById: json['resolved_by_id'] as String?,
      resolvedByUsername: json['resolved_by_username'] as String?,
      resolutionAction: json['resolution_action'] as String?,
      resolutionNotes: json['resolution_notes'] as String?,
      resolvedAt: json['resolved_at'] != null 
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
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
  final dynamic id; // int oder String
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
      id: json['id'] ?? 0,
      world: (json['world'] as String?) ?? 'materie',
      userId: (json['user_id'] ?? '') as String,
      username: (json['username'] ?? '') as String,
      muteType: (json['mute_type'] ?? '24h') as String,
      mutedById: (json['muted_by_id'] ?? 'system') as String,
      mutedByUsername: (json['muted_by_username'] ?? 'system') as String,
      mutedByRole: (json['muted_by_role'] ?? 'admin') as String,
      reason: json['reason'] as String?,
      isActive: json['is_active'] is bool
          ? json['is_active'] as bool
          : (json['is_active'] is int ? (json['is_active'] as int) == 1 : true),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'] as String) ?? DateTime.now())
          : DateTime.now(),
      unmutedAt: json['unmuted_at'] != null
          ? DateTime.tryParse(json['unmuted_at'] as String)
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
  final dynamic id; // int oder String
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
      id: json['id'] ?? json['log_id'] ?? 0,
      world: (json['world'] ?? 'materie') as String,
      actionType: (json['action_type'] ?? json['action'] ?? 'unknown') as String,
      moderatorId: (json['moderator_id'] ?? json['admin_username'] ?? 'system') as String,
      moderatorUsername: (json['moderator_username'] ?? json['admin_username'] ?? 'system') as String,
      moderatorRole: (json['moderator_role'] ?? 'admin') as String,
      targetType: (json['target_type'] ?? 'user') as String,
      targetId: (json['target_id'] ?? json['target_username'] ?? '') as String,
      targetUsername: (json['target_username']) as String?,
      reason: json['reason'] as String?,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'] as String) ?? DateTime.now())
          : DateTime.now(),
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
