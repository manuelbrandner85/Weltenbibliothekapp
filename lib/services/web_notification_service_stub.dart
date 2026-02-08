/// Web Notification Service - STUB for Non-Web Platforms
class WebNotificationService {
  static final WebNotificationService _instance = WebNotificationService._internal();
  factory WebNotificationService() => _instance;
  WebNotificationService._internal();
  
  bool get isSupported => false;
  Future<bool> requestPermission() async => false;
  void showNotification(String title, String body, {String? icon}) {}
}
