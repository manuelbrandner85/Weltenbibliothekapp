// RVTargetService — Remote-Viewing Daily-Target-Pool (J2).

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

class RVTarget {
  final String id;
  final DateTime activeDate;
  final String imageUrl;
  final String? hint;
  final List<String> categories;
  const RVTarget({
    required this.id,
    required this.activeDate,
    required this.imageUrl,
    required this.hint,
    required this.categories,
  });

  factory RVTarget.fromJson(Map<String, dynamic> j) => RVTarget(
        id: j['id'] as String,
        activeDate: DateTime.parse(j['active_date'] as String),
        imageUrl: j['image_url'] as String,
        hint: j['hint'] as String?,
        categories: (j['categories'] as List?)?.cast<String>() ?? const [],
      );
}

class RVGuess {
  final String id;
  final String targetId;
  final String userId;
  final String? username;
  final String? guessText;
  final String? guessSketch;
  final int? matchScore;
  final DateTime submittedAt;
  const RVGuess({
    required this.id,
    required this.targetId,
    required this.userId,
    required this.username,
    required this.guessText,
    required this.guessSketch,
    required this.matchScore,
    required this.submittedAt,
  });

  factory RVGuess.fromJson(Map<String, dynamic> j) => RVGuess(
        id: j['id'] as String,
        targetId: j['target_id'] as String,
        userId: j['user_id'] as String? ?? '',
        username: j['username'] as String?,
        guessText: j['guess_text'] as String?,
        guessSketch: j['guess_sketch'] as String?,
        matchScore: j['match_score'] as int?,
        submittedAt: DateTime.parse(j['submitted_at'] as String),
      );
}

class RVTargetService {
  RVTargetService._();
  static final instance = RVTargetService._();

  SupabaseClient get _s => Supabase.instance.client;

  Future<RVTarget?> today() async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final res = await _s
          .from('rv_daily_targets')
          .select()
          .eq('active_date', today)
          .maybeSingle();
      if (res == null) return null;
      return RVTarget.fromJson(Map<String, dynamic>.from(res as Map));
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ RV target: $e');
      return null;
    }
  }

  Future<bool> submitGuess({
    required String targetId,
    required String userId,
    String? username,
    String? guessText,
    String? guessSketch,
  }) async {
    try {
      await _s.from('rv_target_guesses').insert({
        'target_id': targetId,
        'user_id': userId,
        'username': username,
        'guess_text': guessText,
        'guess_sketch': guessSketch,
      });
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ RV submit: $e');
      return false;
    }
  }

  Future<bool> rateGuess(String guessId, int score) async {
    try {
      await _s.from('rv_target_guesses').update({
        'match_score': score.clamp(0, 100),
      }).eq('id', guessId);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ RV rate: $e');
      return false;
    }
  }

  Future<List<RVGuess>> myGuesses(String userId, {int limit = 30}) async {
    try {
      final res = await _s
          .from('rv_target_guesses')
          .select()
          .eq('user_id', userId)
          .order('submitted_at', ascending: false)
          .limit(limit);
      return (res as List)
          .map((r) => RVGuess.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ RV my: $e');
      return const [];
    }
  }
}
