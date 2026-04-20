import 'package:flutter/services.dart';

/// Programmatically restarts the app via native AlarmManager (Android only).
/// Falls back gracefully on old APKs that don't have the Kotlin handler.
class RestartService {
  static const _channel = MethodChannel('weltenbibliothek/restart');

  /// Requests a native app restart.
  /// Returns true if the native handler accepted the call (process will die shortly).
  /// Returns false if the handler is not available (old APK) — caller should fall back.
  static Future<bool> restartApp() async {
    try {
      await _channel.invokeMethod<void>('restartApp');
      return true;
    } catch (_) {
      return false;
    }
  }
}
