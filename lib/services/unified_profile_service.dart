// UnifiedProfileService: ONE profile fuer alle Welten.
//
// Bisher hat jede Welt entweder EnergieProfile oder MaterieProfile direkt
// gelesen, was zu Inkonsistenzen fuehren konnte (Avatar in Materie anders
// als in Energie, Vorname nur in Energie etc.).
//
// Ab v95 ist EnergieProfile der Master und MaterieProfile ein Derivat.
// Jede Welt nutzt UnifiedProfileService -- spirituelle Berechnungen
// (Numerologie, Astrologie) ziehen direkt firstName/lastName/birthDate;
// soziale Anzeigen (Avatar, Username, Bio) sind ueberall identisch.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/energie_profile.dart';
import '../models/materie_profile.dart';
import 'storage_service.dart';

class UnifiedProfileService {
  UnifiedProfileService._();
  static final UnifiedProfileService instance = UnifiedProfileService._();

  final _controller = StreamController<EnergieProfile?>.broadcast();
  EnergieProfile? _cached;
  bool _initialized = false;

  /// Live-Stream auf Profil-Aenderungen.
  /// Screens koennen via StreamBuilder reaktiv reagieren.
  Stream<EnergieProfile?> get stream => _controller.stream;

  /// Synchroner Lesezugriff (cached). Liefert null bis erstes load().
  EnergieProfile? get current => _cached;

  bool get hasProfile => _cached != null && _cached!.isValid;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await reload();
  }

  /// Neulesen aus dem Storage und Stream benachrichtigen.
  Future<EnergieProfile?> reload() async {
    final storage = StorageService();
    EnergieProfile? energie = await storage.loadEnergieProfile();

    // Fallback: wenn EnergieProfile fehlt aber MaterieProfile existiert,
    // bauen wir ein minimales EnergieProfile aus den Materie-Daten.
    if (energie == null || !energie.isValid) {
      final mat = await storage.loadMaterieProfile();
      if (mat != null && mat.username.isNotEmpty) {
        energie = EnergieProfile(
          username: mat.username,
          firstName: mat.name?.split(' ').first ?? '',
          lastName: mat.name != null && (mat.name?.split(' ').length ?? 0) > 1
              ? (mat.name?.split(' ').sublist(1).join(' ') ?? '')
              : '',
          birthDate: DateTime(1990, 1, 1),
          birthPlace: '',
          avatarUrl: mat.avatarUrl,
          avatarEmoji: mat.avatarEmoji,
          bio: mat.bio,
          userId: mat.userId,
          role: mat.role,
        );
      }
    }

    _cached = energie;
    if (kDebugMode) {
      debugPrint('🪪 UnifiedProfile reloaded: '
          'username=${energie?.username}, '
          'firstName=${energie?.firstName}, '
          'role=${energie?.role}');
    }
    _controller.add(_cached);
    return _cached;
  }

  /// Speichert das Profil ueberall:
  /// - EnergieProfile (Master) in den Energie-Bucket
  /// - MaterieProfile (derived) in den Materie-Bucket
  /// - Vorhang/Ursprung lesen direkt aus EnergieProfile -- keine eigenen
  ///   Buckets noetig.
  Future<void> save(EnergieProfile profile) async {
    final storage = StorageService();
    await storage.saveEnergieProfile(profile);

    // Derivat fuer Materie-Welt -- gleiche soziale Felder, kein
    // Geburtsdatum/Spirit-Kram.
    final mat = MaterieProfile(
      username: profile.username,
      name: profile.fullName.trim().isEmpty ? null : profile.fullName,
      avatarUrl: profile.avatarUrl,
      avatarEmoji: profile.avatarEmoji,
      bio: profile.bio,
      userId: profile.userId,
      role: profile.role,
    );
    await storage.saveMaterieProfile(mat);

    _cached = profile;
    _controller.add(_cached);
  }

  // ── Convenience-Getter fuer alle Welten ────────────────────────────────

  /// Anrede-Vorname mit Fallback-Kette: firstName -> username -> 'Explorer'.
  String get firstName {
    final fn = _cached?.firstName.trim() ?? '';
    if (fn.isNotEmpty) return fn;
    final un = _cached?.username.trim() ?? '';
    if (un.isNotEmpty) return un;
    return 'Explorer';
  }

  /// Voller Name mit Fallback auf Username.
  String get displayName {
    final p = _cached;
    if (p == null) return 'Explorer';
    final full = p.fullName.trim();
    if (full.isNotEmpty) return full;
    return p.username;
  }

  String? get avatarEmoji => _cached?.avatarEmoji;
  String? get avatarUrl => _cached?.avatarUrl;
  String? get bio => _cached?.bio;
  String? get username => _cached?.username;
  String? get userId => _cached?.userId;
  String? get role => _cached?.role;
  DateTime? get birthDate => _cached?.birthDate;
  String? get birthPlace => _cached?.birthPlace;
  double? get birthLatitude => _cached?.birthLatitude;
  double? get birthLongitude => _cached?.birthLongitude;
  String? get gender => _cached?.gender;

  bool get isAdmin => _cached?.isAdmin() ?? false;
  bool get isRootAdmin => _cached?.isRootAdmin() ?? false;

  /// Geburtsname (falls abweichend) -- relevant fuer Numerologie-Vergleich.
  String? get birthFirstName => _cached?.birthFirstName;
  String? get birthMiddleNames => _cached?.birthMiddleNames;
  String? get birthLastName => _cached?.birthLastName;

  void dispose() {
    _controller.close();
  }
}
