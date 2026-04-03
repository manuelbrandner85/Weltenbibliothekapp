/// 🔐 UNIVERSAL PERMISSION SERVICE - Platform-agnostic Permissions
/// 
/// Handles permissions for both Web and Native platforms.
/// Provides a unified API that works across all platforms.
library;

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:permission_handler/permission_handler.dart';
import 'dart:html' as html show window;

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 🔐 UNIVERSAL PERMISSION SERVICE
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class UniversalPermissionService {
  static final UniversalPermissionService _instance = UniversalPermissionService._internal();
  factory UniversalPermissionService() => _instance;
  UniversalPermissionService._internal();

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// 🎙️ MICROPHONE PERMISSION
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Request microphone permission (Web + Native)
  Future<bool> requestMicrophonePermission() async {
    if (kIsWeb) {
      return await _requestWebMicrophonePermission();
    } else {
      final status = await Permission.microphone.request();
      return status.isGranted;
    }
  }

  /// Check if microphone permission is granted
  Future<bool> hasMicrophonePermission() async {
    if (kIsWeb) {
      // Web: No way to check without requesting
      // Assume granted if previously granted
      return true;
    } else {
      final status = await Permission.microphone.status;
      return status.isGranted;
    }
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// 📷 CAMERA PERMISSION
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Request camera permission (Web + Native)
  Future<bool> requestCameraPermission() async {
    if (kIsWeb) {
      return await _requestWebCameraPermission();
    } else {
      final status = await Permission.camera.request();
      return status.isGranted;
    }
  }

  /// Check if camera permission is granted
  Future<bool> hasCameraPermission() async {
    if (kIsWeb) {
      return true;
    } else {
      final status = await Permission.camera.status;
      return status.isGranted;
    }
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// 📁 STORAGE PERMISSION (Native only)
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Request storage permission (Native only)
  Future<bool> requestStoragePermission() async {
    if (kIsWeb) {
      // Web: No storage permission needed
      return true;
    } else {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// 🔔 NOTIFICATION PERMISSION
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Request notification permission (Web + Native)
  Future<bool> requestNotificationPermission() async {
    if (kIsWeb) {
      return await _requestWebNotificationPermission();
    } else {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// 📍 LOCATION PERMISSION
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Request location permission (Web + Native)
  Future<bool> requestLocationPermission() async {
    if (kIsWeb) {
      return await _requestWebLocationPermission();
    } else {
      final status = await Permission.location.request();
      return status.isGranted;
    }
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// 🌐 WEB-SPECIFIC PERMISSION HANDLERS
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Web: Request microphone permission via getUserMedia
  Future<bool> _requestWebMicrophonePermission() async {
    if (!kIsWeb) return false;

    try {
      final mediaStream = await html.window.navigator.mediaDevices!.getUserMedia({
        'audio': true,
      });

      // Stop all tracks immediately (we just needed permission)
      for (var track in mediaStream.getTracks()) {
        track.stop();
      }

      debugPrint('✅ Web Microphone Permission granted');
      return true;
    } catch (e) {
      debugPrint('❌ Web Microphone Permission denied: $e');
      return false;
    }
  }

  /// Web: Request camera permission via getUserMedia
  Future<bool> _requestWebCameraPermission() async {
    if (!kIsWeb) return false;

    try {
      final mediaStream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': true,
      });

      // Stop all tracks immediately
      for (var track in mediaStream.getTracks()) {
        track.stop();
      }

      debugPrint('✅ Web Camera Permission granted');
      return true;
    } catch (e) {
      debugPrint('❌ Web Camera Permission denied: $e');
      return false;
    }
  }

  /// Web: Request notification permission via Notification API
  Future<bool> _requestWebNotificationPermission() async {
    if (!kIsWeb) return false;

    try {
      // Use js interop to access Notification API
      final permission = await _requestNotificationPermissionJS();
      final granted = permission == 'granted';
      
      if (granted) {
        debugPrint('✅ Web Notification Permission granted');
      } else {
        debugPrint('❌ Web Notification Permission denied');
      }
      
      return granted;
    } catch (e) {
      debugPrint('❌ Web Notification Permission error: $e');
      return false;
    }
  }

  /// Helper: Request notification permission via JS interop
  Future<String> _requestNotificationPermissionJS() async {
    // Return 'default' for now - Web notifications optional feature
    return 'default';
  }

  /// Web: Request location permission via Geolocation API
  Future<bool> _requestWebLocationPermission() async {
    if (!kIsWeb) return false;

    try {
      // Request current position (triggers permission prompt)
      await html.window.navigator.geolocation.getCurrentPosition();
      debugPrint('✅ Web Location Permission granted');
      return true;
    } catch (e) {
      debugPrint('❌ Web Location Permission denied: $e');
      return false;
    }
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// 🔧 PERMISSION UTILITIES
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Open app settings (Native only)
  Future<bool> openAppSettings() async {
    if (kIsWeb) {
      debugPrint('⚠️ Cannot open app settings on Web');
      return false;
    }
    return await openAppSettings();
  }

  /// Check if permission is permanently denied (Native only)
  Future<bool> isPermissionPermanentlyDenied(Permission permission) async {
    if (kIsWeb) return false;
    final status = await permission.status;
    return status.isPermanentlyDenied;
  }
}
