/// Plattform-Router für lokale @-Mention-Benachrichtigungen.
/// • Mobile: flutter_local_notifications (mention_notification_service_io.dart)
/// • Web: No-Op-Stub (mention_notification_service_web.dart)
library;

export 'mention_notification_service_io.dart'
    if (dart.library.html) 'mention_notification_service_web.dart';
