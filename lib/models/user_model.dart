/// ═══════════════════════════════════════════════════════════════
/// USER MODEL - Weltenbibliothek
/// ═══════════════════════════════════════════════════════════════
/// Typsicheres User-Datenmodell für die gesamte App
/// Ersetzt Map<String, dynamic> Zugriffe
/// ═══════════════════════════════════════════════════════════════

class User {
  final int id;
  final String username;
  final String? email;
  final String? displayName;
  final String? bio;
  final String? avatarUrl;
  final String role; // 'user', 'moderator', 'admin', 'super_admin'
  final bool isOnline;
  final DateTime? lastSeenAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> permissions;
  final bool isBanned;
  final bool isMuted;

  User({
    required this.id,
    required this.username,
    this.email,
    this.displayName,
    this.bio,
    this.avatarUrl,
    required this.role,
    this.isOnline = false,
    this.lastSeenAt,
    required this.createdAt,
    this.updatedAt,
    this.permissions = const [],
    this.isBanned = false,
    this.isMuted = false,
  });

  /// Display-Name mit Fallback auf Username
  String get effectiveDisplayName => displayName ?? username;

  /// Erster Buchstabe für Avatar-Fallback
  String get avatarInitial =>
      username.isNotEmpty ? username[0].toUpperCase() : '?';

  /// Menschenlesbarer Online-Status-Text
  String get onlineStatusText {
    if (isOnline) return 'Online';
    if (lastSeenAt == null) return 'Offline';

    final diff = DateTime.now().difference(lastSeenAt!);
    if (diff.inMinutes < 1) {
      return 'Gerade online';
    } else if (diff.inMinutes < 60) {
      return 'Vor ${diff.inMinutes} Min. online';
    } else if (diff.inHours < 24) {
      return 'Vor ${diff.inHours} Std. online';
    } else if (diff.inDays == 1) {
      return 'Gestern online';
    } else if (diff.inDays < 7) {
      return 'Vor ${diff.inDays} Tagen online';
    } else {
      return 'Lange nicht online';
    }
  }

  /// Überprüft, ob User Admin-Rechte hat
  bool get isAdmin => role == 'admin' || role == 'super_admin';

  /// Überprüft, ob User Super-Admin ist
  bool get isSuperAdmin => role == 'super_admin';

  /// Überprüft, ob User Moderator oder höher ist
  bool get isModerator => role == 'moderator' || isAdmin;

  /// Rolle als schönen Text formatiert
  String get roleDisplayName {
    switch (role) {
      case 'super_admin':
        return 'Super-Admin';
      case 'admin':
        return 'Admin';
      case 'moderator':
        return 'Moderator';
      case 'user':
      default:
        return 'Benutzer';
    }
  }

  /// Farbe für Rolle-Badge
  int get roleColor {
    switch (role) {
      case 'super_admin':
        return 0xFFFF0000; // Rot
      case 'admin':
        return 0xFFFFA500; // Orange
      case 'moderator':
        return 0xFF00BFFF; // Hellblau
      case 'user':
      default:
        return 0xFF808080; // Grau
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // JSON SERIALIZATION
  // ═══════════════════════════════════════════════════════════════

  /// Erstellt User-Objekt aus JSON (Backend-Response)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String?,
      displayName: json['display_name'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'user',
      isOnline: json['is_online'] as bool? ?? false,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['last_seen_at'] as int) * 1000,
            )
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      permissions: json['permissions'] != null
          ? List<String>.from(json['permissions'] as List)
          : [],
      isBanned: json['is_banned'] as bool? ?? false,
      isMuted: json['is_muted'] as bool? ?? false,
    );
  }

  /// Konvertiert User-Objekt zu JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'display_name': displayName,
      'bio': bio,
      'avatar_url': avatarUrl,
      'role': role,
      'is_online': isOnline,
      'last_seen_at': lastSeenAt != null
          ? lastSeenAt!.millisecondsSinceEpoch ~/ 1000
          : null,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'permissions': permissions,
      'is_banned': isBanned,
      'is_muted': isMuted,
    };
  }

  // ═══════════════════════════════════════════════════════════════
  // COPY WITH (für Updates)
  // ═══════════════════════════════════════════════════════════════

  /// Erstellt Kopie mit geänderten Feldern
  User copyWith({
    String? displayName,
    String? bio,
    String? avatarUrl,
    bool? isOnline,
    DateTime? lastSeenAt,
    String? email,
    String? role,
    List<String>? permissions,
    bool? isBanned,
    bool? isMuted,
  }) {
    return User(
      id: id,
      username: username,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isOnline: isOnline ?? this.isOnline,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      permissions: permissions ?? this.permissions,
      isBanned: isBanned ?? this.isBanned,
      isMuted: isMuted ?? this.isMuted,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // EQUALITY & HASH
  // ═══════════════════════════════════════════════════════════════

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User{id: $id, username: $username, role: $role, isOnline: $isOnline}';
  }
}
