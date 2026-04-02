/// ADMIN ACTION MODEL
/// Protokolliert alle Admin-Aktionen für Transparenz und Nachverfolgung
library;

enum AdminActionType {
  kick,           // User aus Voice Chat entfernen
  mute,           // User stummschalten (Voice)
  unmute,         // Stummschaltung aufheben
  ban,            // Permanenter Ban
  unban,          // Ban aufheben
  timeout,        // Temporärer Ban
  warning,        // Verwarnung aussprechen
  deleteMessage,  // Nachricht löschen
  slowMode,       // Slow Mode aktivieren/deaktivieren
}

enum BanDuration {
  fiveMinutes,    // 5 Minuten
  thirtyMinutes,  // 30 Minuten
  oneHour,        // 1 Stunde
  oneDay,         // 24 Stunden
  permanent,      // Permanent
}

class AdminAction {
  final String id;
  final String adminId;
  final String adminUsername;
  final String targetUserId;
  final String targetUsername;
  final AdminActionType type;
  final String? reason;
  final DateTime timestamp;
  final String? roomId;
  final BanDuration? duration;
  final DateTime? expiresAt;
  
  AdminAction({
    required this.id,
    required this.adminId,
    required this.adminUsername,
    required this.targetUserId,
    required this.targetUsername,
    required this.type,
    this.reason,
    required this.timestamp,
    this.roomId,
    this.duration,
    this.expiresAt,
  });
  
  // Für Firestore Storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admin_id': adminId,
      'admin_username': adminUsername,
      'target_user_id': targetUserId,
      'target_username': targetUsername,
      'type': type.name,
      'reason': reason,
      'timestamp': timestamp.toIso8601String(),
      'room_id': roomId,
      'duration': duration?.name,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }
  
  factory AdminAction.fromJson(Map<String, dynamic> json) {
    return AdminAction(
      id: json['id'] as String,
      adminId: json['admin_id'] as String,
      adminUsername: json['admin_username'] as String,
      targetUserId: json['target_user_id'] as String,
      targetUsername: json['target_username'] as String,
      type: AdminActionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AdminActionType.kick,
      ),
      reason: json['reason'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      roomId: json['room_id'] as String?,
      duration: json['duration'] != null
          ? BanDuration.values.firstWhere(
              (e) => e.name == json['duration'],
              orElse: () => BanDuration.permanent,
            )
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }
  
  // Human-readable action description
  String get description {
    switch (type) {
      case AdminActionType.kick:
        return 'kicked $targetUsername${reason != null ? " (Grund: $reason)" : ""}';
      case AdminActionType.mute:
        return 'muted $targetUsername${reason != null ? " (Grund: $reason)" : ""}';
      case AdminActionType.unmute:
        return 'unmuted $targetUsername';
      case AdminActionType.ban:
        return 'banned $targetUsername permanently${reason != null ? " (Grund: $reason)" : ""}';
      case AdminActionType.unban:
        return 'unbanned $targetUsername';
      case AdminActionType.timeout:
        return 'gave $targetUsername a ${_durationText()} timeout${reason != null ? " (Grund: $reason)" : ""}';
      case AdminActionType.warning:
        return 'warned $targetUsername${reason != null ? " (Grund: $reason)" : ""}';
      case AdminActionType.deleteMessage:
        return 'deleted message from $targetUsername';
      case AdminActionType.slowMode:
        return 'changed slow mode settings';
    }
  }
  
  String _durationText() {
    if (duration == null) return '';
    switch (duration!) {
      case BanDuration.fiveMinutes:
        return '5 minute';
      case BanDuration.thirtyMinutes:
        return '30 minute';
      case BanDuration.oneHour:
        return '1 hour';
      case BanDuration.oneDay:
        return '24 hour';
      case BanDuration.permanent:
        return 'permanent';
    }
  }
  
  // Emoji icon for action type
  String get icon {
    switch (type) {
      case AdminActionType.kick:
        return '🚫';
      case AdminActionType.mute:
        return '🔇';
      case AdminActionType.unmute:
        return '🔊';
      case AdminActionType.ban:
        return '🔴';
      case AdminActionType.unban:
        return '✅';
      case AdminActionType.timeout:
        return '⏱️';
      case AdminActionType.warning:
        return '⚠️';
      case AdminActionType.deleteMessage:
        return '🗑️';
      case AdminActionType.slowMode:
        return '🐌';
    }
  }
}

/// USER BAN INFO
class UserBanInfo {
  final String userId;
  final String username;
  final String adminId;
  final String adminUsername;
  final String? reason;
  final DateTime bannedAt;
  final DateTime? expiresAt;
  final bool isPermanent;
  
  UserBanInfo({
    required this.userId,
    required this.username,
    required this.adminId,
    required this.adminUsername,
    this.reason,
    required this.bannedAt,
    this.expiresAt,
    required this.isPermanent,
  });
  
  bool get isActive {
    if (isPermanent) return true;
    if (expiresAt == null) return true;
    return DateTime.now().isBefore(expiresAt!);
  }
  
  Duration? get remainingDuration {
    if (isPermanent || expiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return Duration.zero;
    return expiresAt!.difference(now);
  }
  
  String get remainingTimeText {
    final remaining = remainingDuration;
    if (remaining == null) return 'Permanent';
    if (remaining == Duration.zero) return 'Abgelaufen';
    
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    
    if (hours > 0) {
      return '$hours Stunden, $minutes Minuten';
    } else {
      return '$minutes Minuten';
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'admin_id': adminId,
      'admin_username': adminUsername,
      'reason': reason,
      'banned_at': bannedAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'is_permanent': isPermanent,
    };
  }
  
  factory UserBanInfo.fromJson(Map<String, dynamic> json) {
    return UserBanInfo(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      adminId: json['admin_id'] as String,
      adminUsername: json['admin_username'] as String,
      reason: json['reason'] as String?,
      bannedAt: DateTime.parse(json['banned_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      isPermanent: json['is_permanent'] as bool? ?? true,
    );
  }
}

/// USER WARNING INFO
class UserWarning {
  final String id;
  final String userId;
  final String username;
  final String adminId;
  final String adminUsername;
  final String reason;
  final DateTime timestamp;
  final String? roomId;
  
  UserWarning({
    required this.id,
    required this.userId,
    required this.username,
    required this.adminId,
    required this.adminUsername,
    required this.reason,
    required this.timestamp,
    this.roomId,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'admin_id': adminId,
      'admin_username': adminUsername,
      'reason': reason,
      'timestamp': timestamp.toIso8601String(),
      'room_id': roomId,
    };
  }
  
  factory UserWarning.fromJson(Map<String, dynamic> json) {
    return UserWarning(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      username: json['username'] as String,
      adminId: json['admin_id'] as String,
      adminUsername: json['admin_username'] as String,
      reason: json['reason'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      roomId: json['room_id'] as String?,
    );
  }
}
