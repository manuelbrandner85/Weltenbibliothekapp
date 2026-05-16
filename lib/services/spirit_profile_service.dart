import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Universeller Spirit-Profil-Service.
/// Liest und schreibt Geburts- und Namensfelder direkt aus/in die Supabase
/// `profiles`-Tabelle — weltübergreifend, ein Datensatz pro User.
///
/// Wird von Numerologie, Astrologie, Human Design und Avatar-Screen genutzt.
class SpiritProfileService {
  static SpiritProfileService? _instance;
  static SpiritProfileService get instance =>
      _instance ??= SpiritProfileService._();
  SpiritProfileService._();

  static SupabaseClient get _db => Supabase.instance.client;

  // ── Laden ─────────────────────────────────────────────────────────────────

  /// Lädt alle Spirit-Felder des eingeloggten Users aus der profiles-Tabelle.
  /// Gibt null zurück wenn nicht eingeloggt oder kein Datensatz vorhanden.
  Future<SpiritProfileData?> load() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final row = await _db
          .from('profiles')
          .select('full_name, birth_date, birth_time, birth_place, username, avatar_url')
          .eq('id', userId)
          .maybeSingle();

      if (row == null) return null;
      return SpiritProfileData.fromMap(row);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [SpiritProfile] load error: $e');
      return null;
    }
  }

  /// Lädt Spirit-Felder eines beliebigen Users (z.B. für Gilden-Mitgliederliste).
  Future<SpiritProfileData?> loadForUser(String userId) async {
    try {
      final row = await _db
          .from('profiles')
          .select('full_name, birth_date, birth_time, birth_place, username, avatar_url')
          .eq('id', userId)
          .maybeSingle();

      if (row == null) return null;
      return SpiritProfileData.fromMap(row);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [SpiritProfile] loadForUser error: $e');
      return null;
    }
  }

  // ── Speichern ─────────────────────────────────────────────────────────────

  /// Speichert Spirit-Felder für den eingeloggten User.
  /// Schreibt nur die Felder die nicht null sind.
  Future<bool> save({
    String? fullName,
    DateTime? birthDate,
    String? birthTime,
    String? birthPlace,
  }) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return false;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (fullName != null) updates['full_name'] = fullName.trim();
    if (birthDate != null) {
      updates['birth_date'] =
          '${birthDate.year}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}';
    }
    if (birthTime != null) updates['birth_time'] = birthTime;
    if (birthPlace != null) updates['birth_place'] = birthPlace.trim();

    try {
      await _db.from('profiles').update(updates).eq('id', userId);
      if (kDebugMode) debugPrint('✅ [SpiritProfile] saved for $userId');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [SpiritProfile] save error: $e');
      return false;
    }
  }

  /// Löscht Spirit-Felder des eingeloggten Users.
  Future<bool> clear() async {
    return save(fullName: '', birthTime: '', birthPlace: '');
  }

  // ── Berechnungs-Hilfsmethoden ─────────────────────────────────────────────

  /// Lebenszahl (Numerologie) aus Geburtsdatum.
  static int? calculateLifePathNumber(DateTime? birthDate) {
    if (birthDate == null) return null;
    final str = '${birthDate.year}${birthDate.month}${birthDate.day}';
    int sum = str.split('').fold(0, (a, c) => a + (int.tryParse(c) ?? 0));
    while (sum > 9 && sum != 11 && sum != 22 && sum != 33) {
      sum = sum.toString().split('').fold(0, (a, c) => a + (int.tryParse(c) ?? 0));
    }
    return sum;
  }

  /// Sternzeichen aus Geburtsdatum.
  static String? calculateZodiacSign(DateTime? birthDate) {
    if (birthDate == null) return null;
    final m = birthDate.month;
    final d = birthDate.day;
    if ((m == 3 && d >= 21) || (m == 4 && d <= 19)) return 'Widder ♈';
    if ((m == 4 && d >= 20) || (m == 5 && d <= 20)) return 'Stier ♉';
    if ((m == 5 && d >= 21) || (m == 6 && d <= 20)) return 'Zwillinge ♊';
    if ((m == 6 && d >= 21) || (m == 7 && d <= 22)) return 'Krebs ♋';
    if ((m == 7 && d >= 23) || (m == 8 && d <= 22)) return 'Löwe ♌';
    if ((m == 8 && d >= 23) || (m == 9 && d <= 22)) return 'Jungfrau ♍';
    if ((m == 9 && d >= 23) || (m == 10 && d <= 22)) return 'Waage ♎';
    if ((m == 10 && d >= 23) || (m == 11 && d <= 21)) return 'Skorpion ♏';
    if ((m == 11 && d >= 22) || (m == 12 && d <= 21)) return 'Schütze ♐';
    if ((m == 12 && d >= 22) || (m == 1 && d <= 19)) return 'Steinbock ♑';
    if ((m == 1 && d >= 20) || (m == 2 && d <= 18)) return 'Wassermann ♒';
    return 'Fische ♓';
  }
}

// ── Datenmodell ───────────────────────────────────────────────────────────────

class SpiritProfileData {
  final String? fullName;
  final DateTime? birthDate;
  final String? birthTime;
  final String? birthPlace;
  final String? username;
  final String? avatarUrl;

  const SpiritProfileData({
    this.fullName,
    this.birthDate,
    this.birthTime,
    this.birthPlace,
    this.username,
    this.avatarUrl,
  });

  bool get hasBasicData =>
      birthDate != null && (birthPlace != null && birthPlace!.isNotEmpty);

  bool get hasFullData =>
      hasBasicData && birthTime != null && birthTime!.isNotEmpty;

  int? get lifePathNumber =>
      SpiritProfileService.calculateLifePathNumber(birthDate);

  String? get zodiacSign =>
      SpiritProfileService.calculateZodiacSign(birthDate);

  factory SpiritProfileData.fromMap(Map<String, dynamic> map) {
    DateTime? birthDate;
    if (map['birth_date'] != null) {
      try {
        birthDate = DateTime.parse(map['birth_date'].toString());
      } catch (_) {}
    }
    return SpiritProfileData(
      fullName: map['full_name'] as String?,
      birthDate: birthDate,
      birthTime: map['birth_time'] as String?,
      birthPlace: map['birth_place'] as String?,
      username: map['username'] as String?,
      avatarUrl: map['avatar_url'] as String?,
    );
  }

  SpiritProfileData copyWith({
    String? fullName,
    DateTime? birthDate,
    String? birthTime,
    String? birthPlace,
    String? username,
    String? avatarUrl,
  }) {
    return SpiritProfileData(
      fullName: fullName ?? this.fullName,
      birthDate: birthDate ?? this.birthDate,
      birthTime: birthTime ?? this.birthTime,
      birthPlace: birthPlace ?? this.birthPlace,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
