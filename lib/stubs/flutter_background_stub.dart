// Web-Stub für flutter_background (Android only).
// Alle Methoden sind No-Ops — auf Web gibt es keinen Hintergrund-Service.

enum AndroidNotificationImportance { normal, high, max }

class AndroidResource {
  final String name;
  final String defType;
  const AndroidResource({required this.name, this.defType = 'drawable'});
}

class FlutterBackgroundAndroidConfig {
  final String notificationTitle;
  final String notificationText;
  final AndroidNotificationImportance notificationImportance;
  final AndroidResource notificationIcon;
  final bool enableWifiLock;
  final bool showBadge;
  final bool shouldRequestBatteryOptimizationsOff;

  const FlutterBackgroundAndroidConfig({
    this.notificationTitle = 'Notification title',
    this.notificationText = 'Notification text',
    this.notificationImportance = AndroidNotificationImportance.normal,
    this.notificationIcon =
        const AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
    this.enableWifiLock = true,
    this.showBadge = true,
    this.shouldRequestBatteryOptimizationsOff = true,
  });
}

class FlutterBackground {
  static Future<bool> get hasPermissions async => false;

  static Future<bool> initialize({
    FlutterBackgroundAndroidConfig androidConfig =
        const FlutterBackgroundAndroidConfig(),
  }) async =>
      false;

  static Future<bool> enableBackgroundExecution() async => false;

  static Future<bool> disableBackgroundExecution() async => false;
}
