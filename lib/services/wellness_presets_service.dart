// WellnessPresetsService — Meditation- + Frequency-Presets (H1 + H2).

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

class MeditationPreset {
  final String id;
  final String title;
  final String? description;
  final int durationMin;
  final List<VoicePrompt> prompts;
  final String category;
  const MeditationPreset({
    required this.id,
    required this.title,
    required this.description,
    required this.durationMin,
    required this.prompts,
    required this.category,
  });

  factory MeditationPreset.fromJson(Map<String, dynamic> j) {
    final raw = (j['voice_prompts'] as List?) ?? [];
    return MeditationPreset(
      id: j['id'] as String,
      title: j['title'] as String? ?? '',
      description: j['description'] as String?,
      durationMin: (j['duration_min'] as int?) ?? 5,
      prompts: raw
          .whereType<Map>()
          .map((p) => VoicePrompt(
                atSec: (p['at_sec'] as int?) ?? 0,
                text: p['text'] as String? ?? '',
              ))
          .toList(),
      category: j['category'] as String? ?? 'general',
    );
  }
}

class VoicePrompt {
  final int atSec;
  final String text;
  const VoicePrompt({required this.atSec, required this.text});
}

class FrequencyPreset {
  final String id;
  final String userId;
  final String title;
  final double hz;
  final String? description;
  final String category;
  final bool isSystem;
  const FrequencyPreset({
    required this.id,
    required this.userId,
    required this.title,
    required this.hz,
    required this.description,
    required this.category,
    required this.isSystem,
  });

  factory FrequencyPreset.fromJson(Map<String, dynamic> j) => FrequencyPreset(
        id: j['id'] as String,
        userId: j['user_id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        hz: (j['hz'] as num).toDouble(),
        description: j['description'] as String?,
        category: j['category'] as String? ?? 'custom',
        isSystem: j['is_system'] as bool? ?? false,
      );
}

class WellnessPresetsService {
  WellnessPresetsService._();
  static final instance = WellnessPresetsService._();

  SupabaseClient get _s => Supabase.instance.client;

  // H1
  Future<List<MeditationPreset>> meditations() async {
    try {
      final res = await _s
          .from('meditation_presets')
          .select()
          .order('duration_min', ascending: true);
      return (res as List)
          .map((r) => MeditationPreset.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Meditation presets: $e');
      return const [];
    }
  }

  // H2
  Future<List<FrequencyPreset>> frequencies({String? category}) async {
    try {
      var q = _s.from('frequency_presets').select();
      if (category != null) q = q.eq('category', category);
      final res = await q.order('hz', ascending: true);
      return (res as List)
          .map((r) => FrequencyPreset.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Frequency presets: $e');
      return const [];
    }
  }

  Future<FrequencyPreset?> saveCustom({
    required String userId,
    String? username,
    required String title,
    required double hz,
    String? description,
  }) async {
    try {
      final res = await _s.from('frequency_presets').insert({
        'user_id': userId,
        'username': username,
        'title': title,
        'hz': hz,
        'description': description,
        'category': 'custom',
        'is_system': false,
      }).select().single();
      return FrequencyPreset.fromJson(Map<String, dynamic>.from(res as Map));
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Frequency save: $e');
      return null;
    }
  }
}
