/// 🎭 VORHANG Service — Direct-Supabase Variante
///
/// Drop-in Ersatz für GET /api/vorhang/modules am Cloudflare Worker.
/// Wird genutzt während der Worker durch Free-Plan-Quota tot ist;
/// langfristig wieder über Worker route-bar (oder dauerhaft direkt, je nach
/// Architektur-Entscheidung).
///
/// Response-Shape ist exakt identisch zum Worker-Endpoint, damit die
/// existierenden Screens (vorhang_home_tab, vorhang_modules_screen) ohne
/// Parser-Änderung weiterlaufen.
library;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VorhangService {
  static const List<String> _branchOrder = [
    'Machtpsychologie',
    'Manipulationserkennung',
    'Verhandlung & Überzeugung',
    'Körpersprache & Nonverbales',
    'Strategisches Denken',
    'Schattenarbeit',
  ];

  /// Fetches all Vorhang modules + (best-effort) user progress.
  /// Returns the same Map shape as the Worker endpoint:
  ///   {
  ///     'success': true,
  ///     'total': int,
  ///     'completed': int,
  ///     'progress_percent': int,
  ///     'branches': { '<branch>': [ {...module..., progress, is_unlocked, is_completed}, ... ] },
  ///   }
  static Future<Map<String, dynamic>> fetchModules({String? userId}) async {
    final supa = Supabase.instance.client;

    // v5.44.2: Slim-Select fuer Liste - kein theory_content/case_study/
    // exercise_description (4-5 KB pro Modul * 30 Module = ~150 KB Payload).
    // Detail-Felder werden bei Tap auf Modul via fetchModule(code) lazy
    // nachgeladen (siehe VorhangLessonScreen._fetchModule).
    // Vorher: 264 KB. Nachher: ~35 KB.
    final modulesRaw = await supa
        .from('vorhang_modules')
        .select(
          'module_code,branch,branch_order,title,subtitle,'
          'is_boss_module,xp_reward,prerequisites',
        )
        .order('branch_order', ascending: true)
        .order('module_code', ascending: true);
    final modules = (modulesRaw as List).cast<Map<String, dynamic>>();

    final progressMap = <String, Map<String, dynamic>>{};
    if (userId != null && userId.isNotEmpty) {
      try {
        final progressRaw = await supa
            .from('user_vorhang_progress')
            .select()
            .eq('user_id', userId);
        for (final entry
            in (progressRaw as List).cast<Map<String, dynamic>>()) {
          final code = entry['module_code'] as String?;
          if (code != null) progressMap[code] = entry;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
              '[VorhangService] progress fetch failed (continuing without): $e');
        }
      }
    }

    final branches = <String, List<Map<String, dynamic>>>{};
    for (final b in _branchOrder) {
      branches[b] = <Map<String, dynamic>>[];
    }
    for (final m in modules) {
      final branch = m['branch'] as String?;
      if (branch == null) continue;
      final enriched = Map<String, dynamic>.from(m);
      enriched['progress'] = progressMap[m['module_code']];
      branches
          .putIfAbsent(branch, () => <Map<String, dynamic>>[])
          .add(enriched);
    }

    final completedCodes = progressMap.values
        .where((p) => p['completed_at'] != null)
        .map((p) => p['module_code'] as String)
        .toSet();

    var completedCount = 0;
    for (final list in branches.values) {
      for (final m in list) {
        final code = m['module_code'] as String;
        final prereqsRaw = m['prerequisites'];
        final prereqs = (prereqsRaw is List)
            ? prereqsRaw.whereType<String>().where((c) => c != code).toList()
            : const <String>[];
        m['is_unlocked'] = prereqs.every(completedCodes.contains);
        m['is_completed'] = progressMap[code]?['completed_at'] != null;
        if (m['is_completed'] == true) completedCount++;
      }
    }

    final total = modules.length;
    return {
      'success': true,
      'total': total,
      'completed': completedCount,
      'progress_percent':
          total == 0 ? 0 : ((completedCount / total) * 100).round(),
      'branches': branches,
    };
  }

  /// Fetches a single module + (best-effort) user progress.
  /// Drop-in for GET /api/vorhang/module/<code>.
  static Future<Map<String, dynamic>> fetchModule(
    String moduleCode, {
    String? userId,
  }) async {
    final supa = Supabase.instance.client;

    final moduleData = await supa
        .from('vorhang_modules')
        .select()
        .eq('module_code', moduleCode)
        .maybeSingle();
    if (moduleData == null) {
      throw Exception('Modul "$moduleCode" nicht gefunden');
    }

    Map<String, dynamic>? progress;
    if (userId != null && userId.isNotEmpty) {
      try {
        progress = await supa
            .from('user_vorhang_progress')
            .select()
            .eq('user_id', userId)
            .eq('module_code', moduleCode)
            .maybeSingle();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[VorhangService] module progress fetch failed: $e');
        }
      }
    }

    return {
      'success': true,
      'module': moduleData,
      'progress': progress,
    };
  }
}
