// 🌕 MOND-PUSH-SERVICE
//
// Plant lokale Benachrichtigungen für anstehende Vollmond-, Neumond- und
// Tagesritual-Termine. Nutzt flutter_local_notifications + timezone.
// Berechnung der Mondphasen via moon_calculator.dart (vorhandener Service).

import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'moon_calculator.dart';

class MoonPushService {
  MoonPushService._();
  static final instance = MoonPushService._();

  static const _enabledKey = 'moon_push_enabled';
  static const _channelId = 'moon_calendar';
  static const _baseId = 200000; // Range für Mond-Notifications

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    if (enabled) {
      await scheduleUpcoming();
    } else {
      await cancelAll();
    }
  }

  Future<void> _ensureInit() async {
    if (_initialized || kIsWeb) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(settings);
    // Android-Permission ab 13 anfragen
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
    } catch (_) {}
    _initialized = true;
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _ensureInit();
    // Range löschen: 100 IDs reserviert für Mond-Events
    for (var i = 0; i < 100; i++) {
      await _plugin.cancel(_baseId + i);
    }
  }

  /// Plant alle Vollmond + Neumond-Termine der nächsten 60 Tage.
  /// Notification 1 Tag vorher um 20:00 Local.
  Future<int> scheduleUpcoming() async {
    if (kIsWeb) return 0;
    await _ensureInit();
    await cancelAll();

    final now = DateTime.now().toUtc();
    final events = <_LunarEvent>[];

    // Iteriere die nächsten 60 Tage, finde Phase-Wechsel.
    String? lastPhase;
    for (var d = 0; d < 60; d++) {
      final t = now.add(Duration(days: d));
      final snap = calculateMoonSnapshot(t);
      if (lastPhase != null && lastPhase != snap.phaseKey) {
        if (snap.phaseKey == 'full_moon' || snap.phaseKey == 'new_moon') {
          events.add(_LunarEvent(
            date: t,
            phaseKey: snap.phaseKey,
            label: snap.phaseLabel,
            zodiac: snap.moonSignName,
          ));
        }
      }
      lastPhase = snap.phaseKey;
    }

    var scheduled = 0;
    for (var i = 0; i < events.length && i < 20; i++) {
      final e = events[i];
      // 1 Tag vorher, 20:00 lokal
      final reminder = DateTime(e.date.year, e.date.month, e.date.day - 1, 20);
      if (reminder.isBefore(DateTime.now())) continue;
      try {
        final tzReminder = tz.TZDateTime.from(reminder, tz.local);
        await _plugin.zonedSchedule(
          _baseId + i,
          _titleFor(e),
          _bodyFor(e),
          tzReminder,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              'Mondkalender',
              channelDescription: 'Erinnerungen für Vollmond / Neumond / Mondphasen',
              importance: Importance.high,
              priority: Priority.defaultPriority,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        scheduled++;
      } catch (e2) {
        if (kDebugMode) debugPrint('⚠️ Moon notification skipped: $e2');
      }
    }
    return scheduled;
  }

  String _titleFor(_LunarEvent e) {
    if (e.phaseKey == 'full_moon') {
      return '🌕 Vollmond morgen in ${e.zodiac}';
    }
    return '🌑 Neumond morgen in ${e.zodiac}';
  }

  String _bodyFor(_LunarEvent e) {
    if (e.phaseKey == 'full_moon') {
      return 'Loslassen, integrieren, würdigen. Heute Abend ideal für Vollmond-Ritual.';
    }
    return 'Neue Saat setzen, Intentionen formulieren. Heute Abend ideal für Neumond-Ritual.';
  }
}

class _LunarEvent {
  final DateTime date;
  final String phaseKey;
  final String label;
  final String zodiac;
  const _LunarEvent({
    required this.date,
    required this.phaseKey,
    required this.label,
    required this.zodiac,
  });
}
