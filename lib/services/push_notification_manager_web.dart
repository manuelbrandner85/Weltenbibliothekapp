// Web-Stub für PushNotificationManager.
// Push-Benachrichtigungen (FCM, flutter_local_notifications) sind auf Web
// nicht verfügbar. Alle Methoden sind No-Ops.

import 'package:firebase_messaging/firebase_messaging.dart'
    show RemoteMessage;

typedef DeepLinkHandler = void Function(Map<String, dynamic> data);

// ignore: avoid_returning_null_for_void
Future<void> fcmBackgroundHandler(RemoteMessage message) async {}

class PushNotificationManager {
  PushNotificationManager._();
  static final PushNotificationManager instance = PushNotificationManager._();

  Future<void> init({DeepLinkHandler? onDeepLink}) async {}

  Future<void> unsubscribeCurrent() async {}

  Future<void> forceResubscribe() async {}

  Future<void> dispose() async {}
}
