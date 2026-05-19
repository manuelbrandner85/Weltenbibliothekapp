/// Materie-Welt Benutzerprofil
/// Username (pflicht) + optionaler Name + Avatar + Bio
/// ✅ FAIL-SAFE: Erweitert mit userId und role (nullable, rückwärtskompatibel)
class MaterieProfile {
  final String username;
  final String? name; // Optionaler echter Name / Spitzname
  final String? avatarUrl; // 🆕 Profilbild URL
  final String? bio; // 🆕 Bio/Beschreibung
  final String? avatarEmoji; // 🆕 Emoji-Avatar als Fallback
  
  // ✅ NEU: Admin-System Felder (nullable, rückwärtskompatibel)
  final String? userId;  // User ID vom Backend
  final String? role;    // Rolle: 'user', 'admin', 'root_admin'
  
  MaterieProfile({
    required this.username,
    this.name,
    this.avatarUrl,
    this.bio,
    this.avatarEmoji,
    this.userId,   // ✅ NEU: Optional
    this.role,     // ✅ NEU: Optional
  });
  
  // Display-Name: Name falls vorhanden, sonst Username
  String get displayName => name?.isNotEmpty == true ? name! : username;
  
  // ✅ NEU: Admin-Prüfungen (Fail-Safe mit Null-Checks)
  bool isAdmin() => role == 'admin' || role == 'root_admin';
  bool isRootAdmin() => role == 'root_admin';
  String get effectiveRole => role ?? 'user';  // Default: 'user'
  
  // Für Hive Storage (✅ erweitert mit Admin-Feldern)
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'name': name,
      'avatar_url': avatarUrl,
      'bio': bio,
      'avatar_emoji': avatarEmoji,
      'user_id': userId,     // ✅ NEU
      'role': role,          // ✅ NEU
    };
  }
  
  factory MaterieProfile.fromJson(Map<String, dynamic> json) {
    return MaterieProfile(
      username: json['username'] as String? ?? '',
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      avatarEmoji: json['avatar_emoji'] as String?,
      userId: json['user_id'] as String?,      // ✅ NEU: Safe null handling
      role: json['role'] as String?,           // ✅ NEU: Safe null handling
    );
  }
  
  // Leeres Profil erstellen
  factory MaterieProfile.empty() {
    return MaterieProfile(username: '');
  }

  // Validierung
  bool get isValid => username.isNotEmpty;

  /// v103: copyWith fuer immutable Update-Pattern (analog zu EnergieProfile).
  MaterieProfile copyWith({
    String? username,
    String? name,
    String? avatarUrl,
    String? avatarEmoji,
    String? bio,
    String? userId,
    String? role,
  }) =>
      MaterieProfile(
        username: username ?? this.username,
        name: name ?? this.name,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        avatarEmoji: avatarEmoji ?? this.avatarEmoji,
        bio: bio ?? this.bio,
        userId: userId ?? this.userId,
        role: role ?? this.role,
      );
}
