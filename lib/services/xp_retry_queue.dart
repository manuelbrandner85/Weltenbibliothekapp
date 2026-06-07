/// 2026-06-07: Persistent retry queue for failed XP increments.
///
/// Why: GamificationService.addXp() can throw on transient network errors
/// or backend hiccups. Previously these failures were silently swallowed --
/// the user saw "+50 XP" SnackBar but XP was never persisted. This queue
/// stores failed attempts in SharedPreferences and flushes them on the
/// next app launch / resume.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'gamification_service.dart';

class XpRetryQueue {
  static const _prefsKey = 'pending_xp_queue_v1';
  static const _maxEntries = 50;

  /// Append a failed XP write to the queue. Best-effort -- a queue write
  /// failure must never crash the caller (we're already in an error path).
  static Future<void> enqueue({
    required String world,
    required int xp,
    required String reason,
  }) async {
    if (xp <= 0) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_prefsKey) ?? <String>[];
      raw.add(jsonEncode({
        'world': world,
        'xp': xp,
        'reason': reason,
        'ts': DateTime.now().toUtc().toIso8601String(),
      }));
      // Trim oldest entries if user accumulated too many offline.
      while (raw.length > _maxEntries) {
        raw.removeAt(0);
      }
      await prefs.setStringList(_prefsKey, raw);
      if (kDebugMode) {
        debugPrint('[XpRetryQueue] enqueued $xp xp ($world, $reason); queue size=${raw.length}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[XpRetryQueue] enqueue failed: $e');
    }
  }

  /// Try to apply every pending XP increment. Entries that succeed are
  /// removed; entries that still fail stay in the queue for the next call.
  /// Should be invoked from app start (main.dart) and on app resume.
  static Future<void> flush() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_prefsKey) ?? const <String>[];
      if (raw.isEmpty) return;
      final remaining = <String>[];
      final svc = GamificationService();
      for (final entry in raw) {
        try {
          final m = jsonDecode(entry) as Map<String, dynamic>;
          await svc.addXp(
            (m['world'] as String?) ?? 'meta',
            (m['xp'] as num?)?.toInt() ?? 0,
            reason: (m['reason'] as String?) ?? 'retry',
            syncServer: false,
          );
          if (kDebugMode) {
            debugPrint('[XpRetryQueue] flushed entry: $entry');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[XpRetryQueue] entry still failing, keeping: $e');
          }
          remaining.add(entry);
        }
      }
      await prefs.setStringList(_prefsKey, remaining);
    } catch (e) {
      if (kDebugMode) debugPrint('[XpRetryQueue] flush failed: $e');
    }
  }
}
