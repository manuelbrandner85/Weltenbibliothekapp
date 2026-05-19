// QuietHoursService — globale Ruhezeiten für Notifications (M1).
//
// Speichert SharedPrefs UND user_notification_prefs (DB). Client kann
// vor jeder Notification-Anzeige isQuietNow() prüfen und unterdrücken
// wenn aktiv.

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuietHoursPrefs {
  final bool enabled;
  final int startHour; // 0-23
  final int endHour; // 0-23
  const QuietHoursPrefs({
    required this.enabled,
    required this.startHour,
    required this.endHour,
  });

  bool isQuiet(DateTime when) {
    if (!enabled) return false;
    final h = when.hour;
    if (startHour == endHour) return false;
    if (startHour < endHour) {
      return h >= startHour && h < endHour;
    } else {
      // umfasst Mitternacht (z.B. 22 → 7)
      return h >= startHour || h < endHour;
    }
  }
}

class QuietHoursService {
  QuietHoursService._();
  static final instance = QuietHoursService._();

  static const _kEnabled = 'quiet_hours_enabled';
  static const _kStart = 'quiet_hours_start';
  static const _kEnd = 'quiet_hours_end';

  Future<QuietHoursPrefs> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return QuietHoursPrefs(
        enabled: prefs.getBool(_kEnabled) ?? false,
        startHour: prefs.getInt(_kStart) ?? 22,
        endHour: prefs.getInt(_kEnd) ?? 7,
      );
    } catch (_) {
      return const QuietHoursPrefs(enabled: false, startHour: 22, endHour: 7);
    }
  }

  Future<void> save(QuietHoursPrefs p, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kEnabled, p.enabled);
      await prefs.setInt(_kStart, p.startHour);
      await prefs.setInt(_kEnd, p.endHour);
    } catch (_) {}

    if (userId != null && userId.isNotEmpty) {
      try {
        await Supabase.instance.client.from('user_notification_prefs').upsert({
          'user_id': userId,
          'quiet_hours_enabled': p.enabled,
          'quiet_start_hour': p.startHour,
          'quiet_end_hour': p.endHour,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id');
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ QuietHours DB sync: $e');
      }
    }
  }

  Future<bool> isQuietNow() async {
    final p = await load();
    return p.isQuiet(DateTime.now());
  }
}
