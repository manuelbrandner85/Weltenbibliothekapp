/// WELTENBIBLIOTHEK v5.9 – USER-PROFIL-SYSTEM
/// 
/// Personalisierte Recherche-Einstellungen:
/// - Bevorzugte Tiefe (oberflächlich, mittel, tief)
/// - Bevorzugte Quellen (Web, Archive, Dokumente, Medien)
/// - Bevorzugte Sichtweise (neutral, offiziell, systemkritisch)
/// - Interaktions-Gewichtungen (für Empfehlungsalgorithmus)
library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// User-Profil-Modell
class UserProfile {
  final String preferredDepth;                    // "oberflächlich", "mittel", "tief"
  final List<String> preferredSources;            // ["web", "archive", "documents", "media"]
  final String preferredView;                     // "neutral", "offiziell", "systemkritisch"
  final Map<String, double> interactionWeights;   // {"media": 1.2, "documents": 1.5, ...}
  
  const UserProfile({
    this.preferredDepth = 'mittel',
    this.preferredSources = const ['web', 'documents'],
    this.preferredView = 'neutral',
    this.interactionWeights = const {},
  });
  
  /// Standard-Profil
  factory UserProfile.defaultProfile() {
    return const UserProfile(
      preferredDepth: 'mittel',
      preferredSources: ['web', 'documents'],
      preferredView: 'neutral',
      interactionWeights: {},
    );
  }
  
  /// Tiefe Recherche-Profil (für Power-User)
  factory UserProfile.deepResearchProfile() {
    return const UserProfile(
      preferredDepth: 'tief',
      preferredSources: ['archive', 'documents'],
      preferredView: 'systemkritisch',
      interactionWeights: {
        'media': 1.2,
        'documents': 1.5,
        'analysis': 1.3,
      },
    );
  }
  
  /// Schnelle Übersicht-Profil
  factory UserProfile.quickOverviewProfile() {
    return const UserProfile(
      preferredDepth: 'oberflächlich',
      preferredSources: ['web'],
      preferredView: 'neutral',
      interactionWeights: {
        'web': 1.5,
        'timeline': 1.2,
      },
    );
  }
  
  /// Aus JSON erstellen
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      preferredDepth: json['preferredDepth'] as String? ?? 'mittel',
      preferredSources: (json['preferredSources'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? ['web', 'documents'],
      preferredView: json['preferredView'] as String? ?? 'neutral',
      interactionWeights: (json['interactionWeights'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ?? {},
    );
  }
  
  /// Zu JSON konvertieren
  Map<String, dynamic> toJson() {
    return {
      'preferredDepth': preferredDepth,
      'preferredSources': preferredSources,
      'preferredView': preferredView,
      'interactionWeights': interactionWeights,
    };
  }
  
  /// Kopie mit Änderungen erstellen
  UserProfile copyWith({
    String? preferredDepth,
    List<String>? preferredSources,
    String? preferredView,
    Map<String, double>? interactionWeights,
  }) {
    return UserProfile(
      preferredDepth: preferredDepth ?? this.preferredDepth,
      preferredSources: preferredSources ?? this.preferredSources,
      preferredView: preferredView ?? this.preferredView,
      interactionWeights: interactionWeights ?? this.interactionWeights,
    );
  }
  
  /// Tiefe als numerischer Wert (1-5)
  int get depthLevel {
    switch (preferredDepth) {
      case 'oberflächlich':
        return 2;
      case 'mittel':
        return 3;
      case 'tief':
        return 5;
      default:
        return 3;
    }
  }
  
  /// Prüft ob eine Quelle bevorzugt wird
  bool isSourcePreferred(String source) {
    return preferredSources.contains(source.toLowerCase());
  }
  
  /// Gibt Gewichtung für eine Quellen-Kategorie zurück
  double getSourceWeight(String source) {
    return interactionWeights[source.toLowerCase()] ?? 1.0;
  }
  
  /// Speichert Profil in SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(toJson()));
  }
  
  /// Lädt Profil aus SharedPreferences
  static Future<UserProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('user_profile');
    
    if (jsonString == null) {
      return UserProfile.defaultProfile();
    }
    
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserProfile.fromJson(json);
    } catch (e) {
      // Bei Fehler: Standard-Profil zurückgeben
      return UserProfile.defaultProfile();
    }
  }
  
  /// Löscht gespeichertes Profil
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_profile');
  }
}

/// Tiefenstufen
enum ResearchDepth {
  oberflaechlich('Oberflächlich', 2, 'Schnelle Übersicht'),
  mittel('Mittel', 3, 'Standard-Recherche'),
  tief('Tief', 5, 'Ausführliche Analyse');
  
  final String label;
  final int level;
  final String description;
  
  const ResearchDepth(this.label, this.level, this.description);
  
  static ResearchDepth fromString(String value) {
    switch (value.toLowerCase()) {
      case 'oberflächlich':
        return ResearchDepth.oberflaechlich;
      case 'tief':
        return ResearchDepth.tief;
      default:
        return ResearchDepth.mittel;
    }
  }
}

/// Quellen-Typen
enum SourceType {
  web('Web', 'Allgemeine Webseiten'),
  archive('Archive', 'Archivierte Dokumente'),
  documents('Dokumente', 'Offizielle Dokumente'),
  media('Medien', 'Video/Audio-Quellen'),
  timeline('Timeline', 'Chronologische Events');
  
  final String label;
  final String description;
  
  const SourceType(this.label, this.description);
  
  static SourceType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'archive':
        return SourceType.archive;
      case 'documents':
        return SourceType.documents;
      case 'media':
        return SourceType.media;
      case 'timeline':
        return SourceType.timeline;
      default:
        return SourceType.web;
    }
  }
}

/// Sichtweisen
enum ViewPreference {
  neutral('Neutral', 'Ausgewogene Darstellung'),
  offiziell('Offiziell', 'Mainstream/Offizielle Perspektive'),
  systemkritisch('Systemkritisch', 'Kritische/Alternative Perspektive');
  
  final String label;
  final String description;
  
  const ViewPreference(this.label, this.description);
  
  static ViewPreference fromString(String value) {
    switch (value.toLowerCase()) {
      case 'offiziell':
        return ViewPreference.offiziell;
      case 'systemkritisch':
        return ViewPreference.systemkritisch;
      default:
        return ViewPreference.neutral;
    }
  }
}

/// Profil-Manager (Singleton)
class UserProfileManager {
  static final UserProfileManager _instance = UserProfileManager._internal();
  factory UserProfileManager() => _instance;
  UserProfileManager._internal();
  
  UserProfile? _currentProfile;
  
  /// Aktuelles Profil laden
  Future<UserProfile> getCurrentProfile() async {
    _currentProfile ??= await UserProfile.load();
    return _currentProfile!;
  }
  
  /// Profil aktualisieren
  Future<void> updateProfile(UserProfile profile) async {
    _currentProfile = profile;
    await profile.save();
  }
  
  /// Profil zurücksetzen
  Future<void> resetToDefault() async {
    _currentProfile = UserProfile.defaultProfile();
    await _currentProfile!.save();
  }
  
  /// Interaktions-Gewichtung aktualisieren
  Future<void> updateInteractionWeight(String source, double weight) async {
    final current = await getCurrentProfile();
    final newWeights = Map<String, double>.from(current.interactionWeights);
    newWeights[source] = weight;
    
    final updated = current.copyWith(interactionWeights: newWeights);
    await updateProfile(updated);
  }
  
  /// Bevorzugte Quelle hinzufügen
  Future<void> addPreferredSource(String source) async {
    final current = await getCurrentProfile();
    if (!current.preferredSources.contains(source)) {
      final newSources = List<String>.from(current.preferredSources)..add(source);
      final updated = current.copyWith(preferredSources: newSources);
      await updateProfile(updated);
    }
  }
  
  /// Bevorzugte Quelle entfernen
  Future<void> removePreferredSource(String source) async {
    final current = await getCurrentProfile();
    if (current.preferredSources.contains(source)) {
      final newSources = List<String>.from(current.preferredSources)..remove(source);
      final updated = current.copyWith(preferredSources: newSources);
      await updateProfile(updated);
    }
  }
}
