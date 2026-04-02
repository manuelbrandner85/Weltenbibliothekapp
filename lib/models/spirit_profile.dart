/// Spirit-Welt Benutzerprofil
/// Vollständige Geburtsdaten für spirituelle Berechnungen
class SpiritProfile {
  final String username;       // Benutzername (Pflicht)
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final String birthPlace;
  final String? birthTime; // Optional: HH:mm Format
  final String? avatarUrl; // 🆕 Profilbild URL
  final String? bio; // 🆕 Bio/Beschreibung
  final String? avatarEmoji; // 🆕 Emoji-Avatar als Fallback
  
  SpiritProfile({
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.birthPlace,
    this.birthTime,
    this.avatarUrl,
    this.bio,
    this.avatarEmoji,
  });
  
  // Display-Name: Vollständiger Name
  String get displayName => fullName;
  
  // Vollständiger Name
  String get fullName => '$firstName $lastName';
  
  // Formatiertes Geburtsdatum
  String get formattedBirthDate {
    return '${birthDate.day.toString().padLeft(2, '0')}.${birthDate.month.toString().padLeft(2, '0')}.${birthDate.year}';
  }
  
  // Für Hive Storage
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
    };
  }
  
  factory SpiritProfile.fromJson(Map<String, dynamic> json) {
    return SpiritProfile(
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
    );
  }
  
  // Leeres Profil erstellen
  factory SpiritProfile.empty() {
    return SpiritProfile(
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
