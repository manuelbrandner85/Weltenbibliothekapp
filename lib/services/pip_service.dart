/// 📺 B10.3 — Picture-in-Picture Service
///
/// Kapselt den MethodChannel zu Android PiP.
/// Auf Geräten mit Android < 8.0 (API 26) ist PiP nicht verfügbar —
/// alle Methoden sind dann No-Ops.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PipService {
  PipService._();
  static final PipService instance = PipService._();

  static const _channel = MethodChannel('weltenbibliothek/pip');

  bool _supported = false;
  bool _active = false;

  bool get isSupported => _supported;
  bool get isActive => _active;

  final _pipController = StreamController<bool>.broadcast();
  Stream<bool> get onPipModeChanged => _pipController.stream;

  /// Muss einmalig beim App-Start (z.B. in main.dart oder LiveKitScreen initState)
  /// aufgerufen werden, um den MethodCallHandler zu registrieren.
  Future<void> init() async {
    try {
      _supported = await _channel.invokeMethod<bool>('isSupported') ?? false;
    } catch (_) {
      _supported = false;
    }

    // Empfange Events von Android (onUserLeaveHint, onPipModeChanged)
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onUserLeaveHint':
          // Android informiert uns dass User Home gedrückt hat —
          // LiveKitGroupCallScreen entscheidet ob er PiP auslöst.
          _pipController.add(_active); // kein Wechsel, nur Trigger
          break;
        case 'onPipModeChanged':
          final active = (call.arguments as Map)['active'] as bool? ?? false;
          _active = active;
          _pipController.add(active);
          break;
      }
    });
  }

  /// Wechselt in PiP-Modus. Gibt false zurück wenn nicht unterstützt.
  Future<bool> enterPip() async {
    if (!_supported) return false;
    try {
      return await _channel.invokeMethod<bool>('enterPip') ?? false;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ PiP enterPip failed: $e');
      return false;
    }
  }

  void dispose() {
    _pipController.close();
  }
}
