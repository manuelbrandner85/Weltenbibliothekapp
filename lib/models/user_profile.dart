/// Unified User Identity (v101).
///
/// EIN Profil pro User -- gilt fuer alle Welten gleichermassen. Materie-
/// und Energie-Profile bleiben fuer welt-spezifische Extras bestehen
/// (Spirit-Daten in Energie, etc.), aber die IDENTITY-Felder (Username,
/// Display-Name, Avatar) sind ueber alle Welten synchron.
///
/// Wird vom StorageService verwaltet: jeder save{Materie/Energie}Profile
/// schreibt automatisch die Identity-Felder auch in das andere Profil
/// -- Single Source of Truth ist der zuletzt geaenderte Wert.
class UserProfile {
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String? avatarEmoji;
  final String? bio;
  final String? userId;
  final String? role;

  const UserProfile({
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.avatarEmoji,
    this.bio,
    this.userId,
    this.role,
  });

  String get effectiveDisplayName =>
      (displayName != null && displayName!.isNotEmpty) ? displayName! : username;

  bool get isAdmin => role == 'admin' || role == 'root_admin' || role == 'root-admin';
  bool get isRootAdmin => role == 'root_admin' || role == 'root-admin';
  bool get isModerator => role == 'moderator';

  Map<String, dynamic> toJson() => {
        'username': username,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'avatar_emoji': avatarEmoji,
        'bio': bio,
        'user_id': userId,
        'role': role,
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        username: j['username'] as String? ?? '',
        displayName: j['display_name'] as String?,
        avatarUrl: j['avatar_url'] as String?,
        avatarEmoji: j['avatar_emoji'] as String?,
        bio: j['bio'] as String?,
        userId: j['user_id'] as String?,
        role: j['role'] as String?,
      );

  UserProfile copyWith({
    String? username,
    String? displayName,
    String? avatarUrl,
    String? avatarEmoji,
    String? bio,
    String? userId,
    String? role,
  }) =>
      UserProfile(
        username: username ?? this.username,
        displayName: displayName ?? this.displayName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        avatarEmoji: avatarEmoji ?? this.avatarEmoji,
        bio: bio ?? this.bio,
        userId: userId ?? this.userId,
        role: role ?? this.role,
      );
}
