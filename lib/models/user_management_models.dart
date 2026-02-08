/// User Management Models
/// 
/// Models für Admin User Management (Phase 2)
library;

/// WorldUser - Repräsentiert einen User im System
class WorldUser {
  final String id;
  final String username;
  final String? world; // 'materie' or 'energie'
  final String? role; // 'user', 'admin', 'root_admin'
  final bool isAdmin;
  final bool isRootAdmin;
  final String? email;
  final String? avatarUrl;
  final String? avatarEmoji;
  final DateTime? createdAt;
  final DateTime? lastActivityAt;
  final bool isSuspended;
  final String? suspensionReason;

  WorldUser({
    required this.id,
    required this.username,
    this.world,
    this.role,
    this.isAdmin = false,
    this.isRootAdmin = false,
    this.email,
    this.avatarUrl,
    this.avatarEmoji,
    this.createdAt,
    this.lastActivityAt,
    this.isSuspended = false,
    this.suspensionReason,
  });

  factory WorldUser.fromJson(Map<String, dynamic> json) {
    return WorldUser(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      world: json['world'] as String?,
      role: json['role'] as String?,
      isAdmin: json['is_admin'] as bool? ?? false,
      isRootAdmin: json['is_root_admin'] as bool? ?? false,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      avatarEmoji: json['avatar_emoji'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      lastActivityAt: json['last_activity_at'] != null
          ? DateTime.tryParse(json['last_activity_at'] as String)
          : null,
      isSuspended: json['is_suspended'] as bool? ?? false,
      suspensionReason: json['suspension_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      if (world != null) 'world': world,
      if (role != null) 'role': role,
      'is_admin': isAdmin,
      'is_root_admin': isRootAdmin,
      if (email != null) 'email': email,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (avatarEmoji != null) 'avatar_emoji': avatarEmoji,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (lastActivityAt != null) 'last_activity_at': lastActivityAt!.toIso8601String(),
      'is_suspended': isSuspended,
      if (suspensionReason != null) 'suspension_reason': suspensionReason,
    };
  }
}

/// UserActivity - Repräsentiert eine User-Aktivität
class UserActivity {
  final int id;
  final String userId;
  final String username;
  final String actionType; // 'login', 'post_create', 'comment_create', etc.
  final String? actionDetails;
  final String? ipAddress;
  final String? userAgent;
  final DateTime createdAt;

  UserActivity({
    required this.id,
    required this.userId,
    required this.username,
    required this.actionType,
    this.actionDetails,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
  });

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    return UserActivity(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      actionType: json['action_type'] as String? ?? '',
      actionDetails: json['action_details'] as String?,
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// UserStatistics - Repräsentiert User-Statistiken
class UserStatistics {
  final String userId;
  final String username;
  final int totalLogins;
  final int totalPosts;
  final int totalComments;
  final int totalChatMessages;
  final int totalFlagsReceived;
  final int totalFlagsSubmitted;
  final int totalLikesReceived;
  final int totalLikesGiven;
  final int totalReactionsReceived;
  final int totalReactionsGiven;
  final DateTime? firstLoginAt;
  final DateTime? lastLoginAt;
  final DateTime? lastActivityAt;
  final int totalActiveDays;
  final int reputationScore;
  final String trustLevel; // 'new', 'basic', 'member', 'regular', 'leader'

  UserStatistics({
    required this.userId,
    required this.username,
    this.totalLogins = 0,
    this.totalPosts = 0,
    this.totalComments = 0,
    this.totalChatMessages = 0,
    this.totalFlagsReceived = 0,
    this.totalFlagsSubmitted = 0,
    this.totalLikesReceived = 0,
    this.totalLikesGiven = 0,
    this.totalReactionsReceived = 0,
    this.totalReactionsGiven = 0,
    this.firstLoginAt,
    this.lastLoginAt,
    this.lastActivityAt,
    this.totalActiveDays = 0,
    this.reputationScore = 0,
    this.trustLevel = 'new',
  });

  factory UserStatistics.fromJson(Map<String, dynamic> json) {
    return UserStatistics(
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      totalLogins: json['total_logins'] as int? ?? 0,
      totalPosts: json['total_posts'] as int? ?? 0,
      totalComments: json['total_comments'] as int? ?? 0,
      totalChatMessages: json['total_chat_messages'] as int? ?? 0,
      totalFlagsReceived: json['total_flags_received'] as int? ?? 0,
      totalFlagsSubmitted: json['total_flags_submitted'] as int? ?? 0,
      totalLikesReceived: json['total_likes_received'] as int? ?? 0,
      totalLikesGiven: json['total_likes_given'] as int? ?? 0,
      totalReactionsReceived: json['total_reactions_received'] as int? ?? 0,
      totalReactionsGiven: json['total_reactions_given'] as int? ?? 0,
      firstLoginAt: json['first_login_at'] != null
          ? DateTime.tryParse(json['first_login_at'] as String)
          : null,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.tryParse(json['last_login_at'] as String)
          : null,
      lastActivityAt: json['last_activity_at'] != null
          ? DateTime.tryParse(json['last_activity_at'] as String)
          : null,
      totalActiveDays: json['total_active_days'] as int? ?? 0,
      reputationScore: json['reputation_score'] as int? ?? 0,
      trustLevel: json['trust_level'] as String? ?? 'new',
    );
  }
}

/// UserNote - Repräsentiert eine Admin-Notiz
class UserNote {
  final int id;
  final String userId;
  final String username;
  final String note;
  final String noteType; // 'general', 'warning', 'praise', 'concern'
  final String createdById;
  final String createdByUsername;
  final String createdByRole;
  final DateTime createdAt;

  UserNote({
    required this.id,
    required this.userId,
    required this.username,
    required this.note,
    required this.noteType,
    required this.createdById,
    required this.createdByUsername,
    required this.createdByRole,
    required this.createdAt,
  });

  factory UserNote.fromJson(Map<String, dynamic> json) {
    return UserNote(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      note: json['note'] as String? ?? '',
      noteType: json['note_type'] as String? ?? 'general',
      createdById: json['created_by_id'] as String? ?? '',
      createdByUsername: json['created_by_username'] as String? ?? '',
      createdByRole: json['created_by_role'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// UserSuspension - Repräsentiert eine User-Sperrung
class UserSuspension {
  final int id;
  final String userId;
  final String username;
  final String suspensionType; // 'temporary' or 'permanent'
  final String reason;
  final String suspendedById;
  final String suspendedByUsername;
  final String suspendedByRole;
  final DateTime suspendedAt;
  final DateTime? expiresAt;
  final bool isActive;
  final DateTime? unsuspendedAt;
  final String? unsuspendedById;
  final String? unsuspendedByUsername;

  UserSuspension({
    required this.id,
    required this.userId,
    required this.username,
    required this.suspensionType,
    required this.reason,
    required this.suspendedById,
    required this.suspendedByUsername,
    required this.suspendedByRole,
    required this.suspendedAt,
    this.expiresAt,
    required this.isActive,
    this.unsuspendedAt,
    this.unsuspendedById,
    this.unsuspendedByUsername,
  });

  factory UserSuspension.fromJson(Map<String, dynamic> json) {
    return UserSuspension(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      suspensionType: json['suspension_type'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      suspendedById: json['suspended_by_id'] as String? ?? '',
      suspendedByUsername: json['suspended_by_username'] as String? ?? '',
      suspendedByRole: json['suspended_by_role'] as String? ?? '',
      suspendedAt: DateTime.tryParse(json['suspended_at'] as String? ?? '') ?? DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? false,
      unsuspendedAt: json['unsuspended_at'] != null
          ? DateTime.tryParse(json['unsuspended_at'] as String)
          : null,
      unsuspendedById: json['unsuspended_by_id'] as String?,
      unsuspendedByUsername: json['unsuspended_by_username'] as String?,
    );
  }
}
