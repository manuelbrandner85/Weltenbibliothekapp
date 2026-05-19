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

  // ✨ v93: Spirit-Tools Extras (alle nullable - werden vom User optional gepflegt)
  final double? birthLatitude;          // -90 .. 90 (Aszendent-Berechnung)
  final double? birthLongitude;         // -180 .. 180
  final double? timezoneOffsetHours;    // z.B. 1.0=MEZ, 2.0=MESZ, 5.5=IST
  final bool birthTimeUnknown;          // Wenn true: Tools nehmen 12:00 an
  final String? gender;                 // male|female|diverse|prefer_not_say

  // ✨ v94: Geburtsname-Felder (Heirat/Adoption -- fuer Numerologie-Vergleich)
  final String? birthFirstName;         // Vorname bei Geburt, falls abweichend
  final String? birthMiddleNames;       // Alle Zweitnamen bei Geburt
  final String? birthLastName;          // Nachname bei Geburt (vor Heirat)

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
    this.birthLatitude,
    this.birthLongitude,
    this.timezoneOffsetHours,
    this.birthTimeUnknown = false,
    this.gender,
    this.birthFirstName,
    this.birthMiddleNames,
    this.birthLastName,
  });

  /// True wenn ein Geburtsname-Feld gesetzt ist und sich vom aktuellen Namen
  /// unterscheidet -- triggert die Vergleichs-Karte im Numerologie-Screen.
  bool get hasDifferentBirthName {
    final bf = birthFirstName?.trim() ?? '';
    final bl = birthLastName?.trim() ?? '';
    if (bf.isEmpty && bl.isEmpty) return false;
    return (bf.isNotEmpty && bf != firstName) ||
        (bl.isNotEmpty && bl != lastName);
  }
  
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
      // v93 Spirit-Extras
      'birth_latitude': birthLatitude,
      'birth_longitude': birthLongitude,
      'timezone_offset_hours': timezoneOffsetHours,
      'birth_time_unknown': birthTimeUnknown,
      'gender': gender,
      // v94 Geburtsname
      'birth_first_name': birthFirstName,
      'birth_middle_names': birthMiddleNames,
      'birth_last_name': birthLastName,
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
      // v93 Spirit-Extras
      birthLatitude: (json['birth_latitude'] as num?)?.toDouble(),
      birthLongitude: (json['birth_longitude'] as num?)?.toDouble(),
      timezoneOffsetHours: (json['timezone_offset_hours'] as num?)?.toDouble(),
      birthTimeUnknown: json['birth_time_unknown'] == true,
      gender: json['gender'] as String?,
      birthFirstName: json['birth_first_name'] as String?,
      birthMiddleNames: json['birth_middle_names'] as String?,
      birthLastName: json['birth_last_name'] as String?,
    );
  }

  /// copyWith fuer immutable Update-Pattern (nach Save vom Backend).
  EnergieProfile copyWith({
    String? username,
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    String? birthPlace,
    String? birthTime,
    String? avatarUrl,
    String? bio,
    String? avatarEmoji,
    String? userId,
    String? role,
    double? birthLatitude,
    double? birthLongitude,
    double? timezoneOffsetHours,
    bool? birthTimeUnknown,
    String? gender,
    String? birthFirstName,
    String? birthMiddleNames,
    String? birthLastName,
  }) => EnergieProfile(
        username: username ?? this.username,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        birthDate: birthDate ?? this.birthDate,
        birthPlace: birthPlace ?? this.birthPlace,
        birthTime: birthTime ?? this.birthTime,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        bio: bio ?? this.bio,
        avatarEmoji: avatarEmoji ?? this.avatarEmoji,
        userId: userId ?? this.userId,
        role: role ?? this.role,
        birthLatitude: birthLatitude ?? this.birthLatitude,
        birthLongitude: birthLongitude ?? this.birthLongitude,
        timezoneOffsetHours: timezoneOffsetHours ?? this.timezoneOffsetHours,
        birthTimeUnknown: birthTimeUnknown ?? this.birthTimeUnknown,
        gender: gender ?? this.gender,
        birthFirstName: birthFirstName ?? this.birthFirstName,
        birthMiddleNames: birthMiddleNames ?? this.birthMiddleNames,
        birthLastName: birthLastName ?? this.birthLastName,
      );
  
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
