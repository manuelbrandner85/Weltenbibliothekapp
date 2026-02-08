/// Energie-Welt Benutzerprofil
/// Vollständige Geburtsdaten für spirituelle Berechnungen
/// ✅ FAIL-SAFE: Erweitert mit userId und role (nullable, rückwärtskompatibel)
class EnergieProfile {
  final String username;       // Benutzername (Pflicht)
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final String birthPlace;
  final String? birthTime; // Optional: HH:mm Format
  final String? avatarUrl; // 🆕 Profilbild URL
  final String? bio; // 🆕 Bio/Beschreibung
  final String? avatarEmoji; // 🆕 Emoji-Avatar als Fallback
  
  // ✅ NEU: Admin-System Felder (nullable, rückwärtskompatibel)
  final String? userId;  // User ID vom Backend
  final String? role;    // Rolle: 'user', 'admin', 'root_admin'
  
  EnergieProfile({
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.birthPlace,
    this.birthTime,
    this.avatarUrl,
    this.bio,
    this.avatarEmoji,
    this.userId,   // ✅ NEU: Optional
    this.role,     // ✅ NEU: Optional
  });
  
  // Display-Name: Vollständiger Name
  String get displayName => fullName;
  
  // Vollständiger Name
  String get fullName => '$firstName $lastName';
  
  // Formatiertes Geburtsdatum
  String get formattedBirthDate {
    return '${birthDate.day.toString().padLeft(2, '0')}.${birthDate.month.toString().padLeft(2, '0')}.${birthDate.year}';
  }
  
  // ✅ NEU: Admin-Prüfungen (Fail-Safe mit Null-Checks)
  bool isAdmin() => role == 'admin' || role == 'root_admin';
  bool isRootAdmin() => role == 'root_admin';
  String get effectiveRole => role ?? 'user';  // Default: 'user'
  
  // Für Hive Storage (✅ erweitert mit Admin-Feldern)
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'birthDate': birthDate.toIso8601String(),
      'birthPlace': birthPlace,
      'birthTime': birthTime,
      'avatar_url': avatarUrl,
      'bio': bio,
      'avatar_emoji': avatarEmoji,
      'user_id': userId,     // ✅ NEU
      'role': role,          // ✅ NEU
    };
  }
  
  factory EnergieProfile.fromJson(Map<String, dynamic> json) {
    return EnergieProfile(
      username: json['username'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      birthDate: json['birthDate'] != null 
          ? DateTime.parse(json['birthDate'] as String)
          : DateTime.now(),
      birthPlace: json['birthPlace'] as String? ?? '',
      birthTime: json['birthTime'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      avatarEmoji: json['avatar_emoji'] as String?,
      userId: json['user_id'] as String?,      // ✅ NEU: Safe null handling
      role: json['role'] as String?,           // ✅ NEU: Safe null handling
    );
  }
  
  // Leeres Profil erstellen
  factory EnergieProfile.empty() {
    return EnergieProfile(
      username: '',
      firstName: '',
      lastName: '',
      birthDate: DateTime.now(),
      birthPlace: '',
    );
  }
  
  // Validierung
  bool get isValid {
    return username.isNotEmpty &&
           firstName.isNotEmpty && 
           lastName.isNotEmpty && 
           birthPlace.isNotEmpty;
  }
}
