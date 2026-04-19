/// Web Push Notification Service - STUB for Non-Web Platforms
class WebPushNotificationService {
  static final WebPushNotificationService _instance = WebPushNotificationService._internal();
  factory WebPushNotificationService() => _instance;
  WebPushNotificationService._internal();
  
  bool get isSupported => false;
  Future<bool> requestPermission() async => false;
  Future<void> subscribeToTopic(String topic) async {}
  Future<void> unsubscribeFromTopic(String topic) async {}
}
