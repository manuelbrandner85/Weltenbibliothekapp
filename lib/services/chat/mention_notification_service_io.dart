import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Lokale @-Mention-Benachrichtigungen.
///
/// Wenn der aktuelle User in einer eingehenden Chat-Nachricht gemention wird
/// (Realtime-INSERT-Event), feuert dieser Service eine lokale System-Notification.
///
/// Einschränkung: funktioniert nur solange der Supabase-Realtime-Channel aktiv
/// ist (App im Vordergrund oder im Hintergrund mit aktiver Connection). Echte
/// Background-Push (App ganz geschlossen) braucht zusätzlich einen Server-Side
/// Trigger + FCM/APNs — nicht Teil dieses Service.
class MentionNotificationService {
  MentionNotificationService._();
  static final MentionNotificationService instance =
      MentionNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );
      _initialized = true;
    } catch (e) {
      if (kDebugMode) debugPrint('MentionNotif init failed: $e');
    }
  }

  /// Prüft, ob [message] die [username] als @-Mention enthält.
  /// Erkennt @username, @Username, @user_name — case-insensitive, Wortgrenze.
  static bool containsMention(String message, String username) {
    if (username.isEmpty) return false;
    final escaped = RegExp.escape(username);
    final re = RegExp('(^|[^a-zA-Z0-9_])@$escaped(?![a-zA-Z0-9_])',
        caseSensitive: false);
    return re.hasMatch(message);
  }

  Future<void> notifyMention({
    required String fromUsername,
    required String roomLabel,
    required String snippet,
  }) async {
    await init();
    if (!_initialized) return;
    try {
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
        '$fromUsername hat dich erwähnt',
        '$roomLabel · $snippet',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'mentions',
            'Erwähnungen',
            channelDescription: 'Wenn dich jemand im Chat mit @Name erwähnt',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('MentionNotif show failed: $e');
    }
  }
}
