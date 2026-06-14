// Gated Unity 3D embed.
//
// Renders a Unity view ONLY on clearly capable devices and otherwise shows a
// lightweight [fallback]. This keeps the app fast and battery-friendly on weak
// devices (project rule: Performance/Akku haben Vorrang) and avoids the heavy
// Unity runtime path where it is not wanted.
//
// Gate (all must hold to show Unity):
//   - not Flutter Web (Unity embed is mobile-only here)
//   - OS "reduce motion" is OFF
//   - device is high-tier per WbQuality.heavyEffects (or [forceEnable])
//
// IMPORTANT: a Unity view only actually works once a Unity project has been
// exported into android/unityLibrary (+ ios/UnityLibrary) and wired into the
// Gradle/Xcode build -- see docs/unity/SETUP.md. Until then this widget simply
// shows the fallback on every device, so the app keeps building and running.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';

import '../../core/device/wb_quality.dart';

class WbUnityView extends StatefulWidget {
  /// Shown on weak devices / web / reduce-motion, and while Unity loads.
  final Widget fallback;

  /// Called once the Unity view is ready -- use it to postMessage into Unity.
  final void Function(UnityWidgetController controller)? onCreated;

  /// Optional message receiver from Unity (gameObject -> Flutter).
  final void Function(dynamic message)? onMessage;

  /// Bypass the device-tier gate (e.g. an explicit "3D" screen the user opened).
  /// Reduce-motion and web are still respected.
  final bool forceEnable;

  const WbUnityView({
    super.key,
    required this.fallback,
    this.onCreated,
    this.onMessage,
    this.forceEnable = false,
  });

  /// Whether a Unity view may render in the current context.
  static bool allowed(BuildContext context, {bool force = false}) {
    if (kIsWeb) return false;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return false;
    if (force) return true;
    return WbQuality.heavyEffects; // only on clearly capable devices
  }

  @override
  State<WbUnityView> createState() => _WbUnityViewState();
}

class _WbUnityViewState extends State<WbUnityView> with WidgetsBindingObserver {
  UnityWidgetController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  // Pause Unity off-screen to save battery; resume on return.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null) return;
    if (state == AppLifecycleState.resumed) {
      c.resume();
    } else {
      c.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!WbUnityView.allowed(context, force: widget.forceEnable)) {
      return widget.fallback;
    }
    return UnityWidget(
      fullscreen: false,
      // Shown until the Unity scene is loaded (and if it fails to load).
      placeholder: widget.fallback,
      onUnityCreated: (c) {
        _controller = c;
        widget.onCreated?.call(c);
      },
      onUnityMessage: (msg) => widget.onMessage?.call(msg),
    );
  }
}
