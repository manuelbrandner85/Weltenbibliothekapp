/// 🌀 URSPRUNG Service — Direct-Supabase Variante
///
/// Drop-in Ersatz für GET /api/ursprung/modules am Cloudflare Worker.
/// Wird genutzt während der Worker durch Free-Plan-Quota tot ist;
/// langfristig wieder über Worker route-bar (oder dauerhaft direkt, je nach
/// Architektur-Entscheidung).
///
/// Response-Shape ist exakt identisch zum Worker-Endpoint, damit die
/// existierenden Screens (ursprung_home_tab, ursprung_modules_screen) ohne
/// Parser-Änderung weiterlaufen.
library;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'invisible_auth_service.dart';

class UrsprungService {
  // Branch-Codes wie in der ursprung_modules-Tabelle (snake_case),
  // sortiert nach inhaltlicher Progression durch CIA-Gateway-Material.
  static const List<String> _branchOrder = [
    'gateway_foundation',
    'focus_levels',
    'energy_tools',
    'patterning_manifestation',
    'remote_viewing',
  ];

  /// Fetches all Ursprung modules + (best-effort) user progress.
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
    final hasUser = userId != null && userId.isNotEmpty;

    // 2026-06-07 BUGFIX: identisch zu VorhangService -- Worker speichert mit
    // profiles.id ODER legacy_user_id, Client muss gegen beide pruefen damit
    // der Admin-Override greift.
    final candidateIds = <String>{};
    if (hasUser) candidateIds.add(userId!);
    final legacy = InvisibleAuthService().legacyUserId;
    if (legacy != null && legacy.isNotEmpty) candidateIds.add(legacy);
    final supaId = supa.auth.currentUser?.id;
    if (supaId != null && supaId.isNotEmpty) candidateIds.add(supaId);

    // U2: nur Metadaten laden (kein theory_content/case_study/
    // exercise_description/test_questions). Voller Inhalt wird bei Tap auf
    // ein Modul via fetchModule(code) lazy nachgeladen.
    // Batch-fetch: modules + user-specific queries all run in parallel.
    final futs = <Future<List<dynamic>>>[
      supa
          .from('ursprung_modules')
          .select(
            'id,module_code,branch,branch_order,title,subtitle,'
            'is_boss_module,xp_reward,prerequisites',
          )
          .order('branch_order', ascending: true)
          .order('module_code', ascending: true)
          .then<List<dynamic>>((r) => r as List),
    ];
    if (hasUser) {
      futs.add(
        supa
            .from('user_ursprung_progress')
            .select()
            .eq('user_id', userId!)
            .then<List<dynamic>>((r) => r as List)
            .catchError((Object e) {
          if (kDebugMode) {
            debugPrint(
                '[UrsprungService] progress fetch failed (continuing without): $e');
          }
          return <dynamic>[];
        }),
      );
    }
    if (candidateIds.isNotEmpty) {
      futs.add(
        supa
            .from('admin_module_access')
            .select('module_code,is_granted')
            .inFilter('user_id', candidateIds.toList())
            .eq('module_type', 'ursprung')
            .then<List<dynamic>>((r) => r as List)
            .catchError((Object e) {
          if (kDebugMode) {
            debugPrint('[UrsprungService] module-override load failed: $e');
          }
          return <dynamic>[];
        }),
      );
    }

    final results = await Future.wait(futs);
    final modules = results[0].cast<Map<String, dynamic>>();

    final progressMap = <String, Map<String, dynamic>>{};
    final adminOverrides = <String, bool>{};

    var idx = 1;
    if (hasUser) {
      for (final entry in results[idx].cast<Map<String, dynamic>>()) {
        final code = entry['module_code'] as String?;
        if (code != null) progressMap[code] = entry;
      }
      idx++;
    }
    if (candidateIds.isNotEmpty) {
      for (final o in results[idx].cast<Map<String, dynamic>>()) {
        final code = o['module_code'] as String?;
        final granted = o['is_granted'] as bool?;
        if (code != null && granted != null) adminOverrides[code] = granted;
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

        // Admin-Override hat Vorrang vor normaler Prerequisite-Logik
        if (adminOverrides.containsKey(code)) {
          m['is_unlocked'] = adminOverrides[code];
        } else {
          m['is_unlocked'] = prereqs.every(completedCodes.contains);
        }
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
  /// Drop-in for GET /api/ursprung/module/<code>.
  static Future<Map<String, dynamic>> fetchModule(
    String moduleCode, {
    String? userId,
  }) async {
    final supa = Supabase.instance.client;

    final moduleData = await supa
        .from('ursprung_modules')
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
            .from('user_ursprung_progress')
            .select()
            .eq('user_id', userId)
            .eq('module_code', moduleCode)
            .maybeSingle();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[UrsprungService] module progress fetch failed: $e');
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
