/// Plattform-Router für Push-Benachrichtigungen.
/// • Mobile (Android/iOS): FCM + flutter_local_notifications (push_notification_manager_io.dart)
/// • Web: No-Op-Stub — keine Push-Notifications auf Web (push_notification_manager_web.dart)
library;

export 'push_notification_manager_io.dart'
    if (dart.library.html) 'push_notification_manager_web.dart';
