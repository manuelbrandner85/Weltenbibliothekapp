#!/bin/bash
# Android Build Script - Temporarily disables web-only features

echo "🔧 Preparing Android Build..."

# Backup files
cp lib/services/notification_service.dart lib/services/notification_service.dart.web_bak
cp lib/services/export_import_service.dart lib/services/export_import_service.dart.web_bak  
cp lib/utils/recherche_exporter.dart lib/utils/recherche_exporter.dart.web_bak
cp lib/screens/materie/materie_karte_tab_pro.dart lib/screens/materie/materie_karte_tab_pro.dart.web_bak

echo "📦 Creating Android-compatible stubs..."

# Create minimal notification service stub
cat > lib/services/notification_service.dart << 'STUB_END'
/// Notification Service - Android Stub
library;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NotificationType { achievementUnlock, streakReminder, dailyPractice, syncComplete }

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  
  bool get permissionGranted => false;
  bool get notificationsEnabled => false;
  
  Future<void> initialize() async {}
  Future<bool> requestPermission() async => false;
  Future<void> showNotification(String title, String body, {NotificationType? type}) async {}
  Future<void> setNotificationsEnabled(bool enabled) async {}
}
STUB_END

echo "✅ Services stubbed for Android"

# Build APK
echo "🏗️ Building Release APK..."
flutter build apk --release

BUILD_EXIT=$?

echo "🔄 Restoring web-enabled versions..."
# Restore originals
mv lib/services/notification_service.dart.web_bak lib/services/notification_service.dart
mv lib/services/export_import_service.dart.web_bak lib/services/export_import_service.dart
mv lib/utils/recherche_exporter.dart.web_bak lib/utils/recherche_exporter.dart
mv lib/screens/materie/materie_karte_tab_pro.dart.web_bak lib/screens/materie/materie_karte_tab_pro.dart

if [ $BUILD_EXIT -eq 0 ]; then
    echo "✅ APK Build Complete!"
    echo "📱 Location: build/app/outputs/flutter-apk/app-release.apk"
    ls -lh build/app/outputs/flutter-apk/app-release.apk
else
    echo "❌ Build failed with exit code $BUILD_EXIT"
    exit $BUILD_EXIT
fi
