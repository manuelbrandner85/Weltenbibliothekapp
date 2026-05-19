// RealtimeNotificationService -- Live-Bruecke zwischen ActivityLogService
// (lokale Events) und in-app Banner/Push.
//
// Was bisher fehlte:
// - FCM-Push kommt erst nach Worker-Cron-Run (max +5min Delay).
// - Lokale ActivityEvents waren nicht UI-sichtbar.
//
// Diese Service-Schicht:
// 1. Hoert auf ActivityLogService.stream und zeigt sofort einen kompakten
//    in-app Toast (+XP, Achievement-Unlock, etc.).
// 2. Subscribed auf Supabase Realtime fuer notification_queue, sodass
//    Server-getriggerte Notifications (von anderen Devices, vom Admin,
//    Tagesenergie-Push) live ankommen, ohne auf FCM zu warten.
// 3. Singleton -- in main.dart einmal initialisieren.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'activity_log_service.dart';
import 'supabase_service.dart';
import 'unified_profile_service.dart';

class InAppNotification {
  final String title;
  final String body;
  final IconData icon;
  final Color accent;
  final DateTime timestamp;

  InAppNotification({
    required this.title,
    required this.body,
    required this.icon,
    required this.accent,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class RealtimeNotificationService {
  RealtimeNotificationService._();
  static final RealtimeNotificationService instance =
      RealtimeNotificationService._();

  final _controller = StreamController<InAppNotification>.broadcast();
  StreamSubscription<ActivityEvent>? _activitySub;
  RealtimeChannel? _channel;

  Stream<InAppNotification> get stream => _controller.stream;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // 1) ActivityLog -> in-app Banner
    _activitySub = ActivityLogService.instance.stream.listen(_onActivity);

    // 2) Supabase Realtime fuer notification_queue (server-getriggert).
    await _subscribeQueue();
  }

  void _onActivity(ActivityEvent evt) {
    final xp = evt.metadata['xp'] as int? ?? 0;
    switch (evt.kind) {
      case ActivityKind.toolOpen:
      case ActivityKind.articleRead:
      case ActivityKind.checkIn:
      case ActivityKind.loginDaily:
        // leise -- kein Toast (sonst Spam).
        return;
      case ActivityKind.chatMessage:
        return; // chat send braucht kein eigenes Toast
      case ActivityKind.profileEdit:
        _emit(InAppNotification(
          title: 'Profil aktualisiert',
          body: '+10 XP für aktualisierte Daten.',
          icon: Icons.badge_outlined,
          accent: const Color(0xFF7C4DFF),
        ));
        return;
      case ActivityKind.questionAnswered:
        if (xp > 0) {
          _emit(InAppNotification(
            title: 'Richtige Antwort!',
            body: '+$xp XP für deinen Erfolg.',
            icon: Icons.bolt_rounded,
            accent: const Color(0xFFCE93D8),
          ));
        }
        return;
      case ActivityKind.pdfShared:
        _emit(InAppNotification(
          title: 'Seelenporträt geteilt',
          body: '+10 XP - Wissen ist Multiplikation.',
          icon: Icons.picture_as_pdf_rounded,
          accent: const Color(0xFFC9A84C),
        ));
        return;
      case ActivityKind.achievementUnlock:
        _emit(InAppNotification(
          title: 'Achievement freigeschaltet!',
          body: evt.label,
          icon: Icons.workspace_premium_rounded,
          accent: const Color(0xFFFFD54F),
        ));
        return;
      case ActivityKind.custom:
        return;
    }
  }

  Future<void> _subscribeQueue() async {
    // v96: zwei moegliche Identitaeten -- UUID (Supabase Auth) oder
    // legacy_user_id (InvisibleAuth, beginnt mit 'user_'). UnifiedProfile.userId
    // enthaelt eines von beiden.
    final userId = UnifiedProfileService.instance.userId;
    if (userId == null || userId.isEmpty) {
      if (kDebugMode) {
        debugPrint('🔔 Realtime-Queue: keine Identitaet -- skip subscribe');
      }
      return;
    }

    // Heuristik: InvisibleAuth-IDs starten mit 'user_<ts>_<rand>'.
    // Echte UUIDs haben Bindestriche (8-4-4-4-12).
    final isLegacy = userId.startsWith('user_');
    final filterColumn = isLegacy ? 'legacy_user_id' : 'user_id';

    try {
      final client = supabase;
      final keyValue = userId;
      _channel = client
          .channel(
              'rt-notif-$keyValue-${DateTime.now().millisecondsSinceEpoch}')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notification_queue',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: filterColumn,
              value: keyValue,
            ),
            callback: (payload) {
              final row = payload.newRecord;
              final title = (row['title'] as String?) ?? 'Benachrichtigung';
              final body = (row['body'] as String?) ?? '';
              _emit(InAppNotification(
                title: title,
                body: body,
                icon: Icons.notifications_active_rounded,
                accent: const Color(0xFF4FC3F7),
              ));
            },
          )
          .subscribe();
      if (kDebugMode) {
        debugPrint('🔔 Realtime-Queue subscribed via $filterColumn=$keyValue');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Realtime-Queue subscribe failed: $e');
    }
  }

  void _emit(InAppNotification n) {
    _controller.add(n);
  }

  /// Manuelles Triggern (z.B. fuer Erfolgs-Feedback ausserhalb von
  /// ActivityLog -- "Profil gespeichert", "Verbindung wiederhergestellt").
  void show({
    required String title,
    required String body,
    IconData icon = Icons.info_outline,
    Color accent = const Color(0xFF7C4DFF),
  }) {
    _emit(InAppNotification(
      title: title,
      body: body,
      icon: icon,
      accent: accent,
    ));
  }

  void dispose() {
    _activitySub?.cancel();
    _channel?.unsubscribe();
    _controller.close();
  }
}
