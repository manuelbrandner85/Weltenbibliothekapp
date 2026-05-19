// SharedInvestigationService — Kaninchenbau-Investigations teilen (C2).
//
// share()  → erstellt einen share_token (UUID-short), payload kopiert.
// fetch()  → lädt Investigation per share_token (read-only Public).
// contribute() → fügt User zu contributors[] hinzu, merged Daten.
//
// MVP — Konflikt-Auflösung & Real-time-Sync sind Follow-up.

import 'dart:math';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

class SharedInvestigationService {
  SharedInvestigationService._();
  static final instance = SharedInvestigationService._();

  SupabaseClient get _s => Supabase.instance.client;

  static const _alphabet = 'abcdefghjkmnpqrstuvwxyz23456789';

  String _genToken({int length = 8}) {
    final r = Random.secure();
    return List.generate(
      length,
      (_) => _alphabet[r.nextInt(_alphabet.length)],
    ).join();
  }

  /// Erstellt einen Share-Eintrag und gibt den Token zurück.
  Future<String?> share({
    required String ownerUserId,
    String? ownerUsername,
    required String title,
    required String topic,
    required Map<String, dynamic> payload,
    bool isPublic = true,
  }) async {
    try {
      // Drei Versuche bei Token-Kollision (unique constraint).
      for (var attempt = 0; attempt < 3; attempt++) {
        final token = _genToken();
        try {
          await _s.from('shared_investigations').insert({
            'share_token': token,
            'owner_user_id': ownerUserId,
            'owner_username': ownerUsername,
            'title': title,
            'topic': topic,
            'payload': payload,
            'is_public': isPublic,
          });
          return token;
        } on PostgrestException catch (e) {
          if (e.code == '23505') continue; // unique violation
          rethrow;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Share investigation: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetch(String token) async {
    try {
      final res = await _s
          .from('shared_investigations')
          .select()
          .eq('share_token', token)
          .eq('is_public', true)
          .maybeSingle();
      if (res == null) return null;
      // View-Count atomic-ish erhöhen (best-effort, racy ist hier okay).
      _s
          .from('shared_investigations')
          .update({
            'view_count': ((res as Map)['view_count'] as int? ?? 0) + 1,
          })
          .eq('share_token', token)
          .then((_) {})
          .onError((_, __) => null);
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Fetch shared investigation: $e');
      return null;
    }
  }
}
