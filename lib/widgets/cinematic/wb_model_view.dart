// Gated 3D model viewer (glTF/.glb via model_viewer_plus).
//
// Renders an interactive 3D model (rotate / zoom / optional AR) using a
// WebGL <model-viewer> inside a WebView. OTA-friendly (pure Dart + the existing
// webview_flutter), no native export, negligible APK impact vs a game engine.
//
// Gate: shows the model when reduce-motion is OFF and the device is not low-tier
// (WebGL is still heavier than a static image); otherwise shows [fallback].
// On an explicit 3D screen pass forceEnable:true to bypass the tier gate
// (reduce-motion is still respected).

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../core/device/wb_device_capability.dart';

class WbModelView extends StatelessWidget {
  /// Asset path (e.g. 'assets/models/wb_orb.glb') or https URL to a .glb/.gltf.
  final String src;

  /// Shown on weak devices / reduce-motion (and as a graceful default).
  final Widget fallback;

  final String alt;
  final bool autoRotate;
  final bool cameraControls;
  final bool ar;
  final Color backgroundColor;

  /// Bypass the device-tier gate (e.g. a screen the user explicitly opened for
  /// 3D). Reduce-motion is still respected.
  final bool forceEnable;

  const WbModelView({
    super.key,
    required this.src,
    required this.fallback,
    this.alt = '3D-Modell',
    this.autoRotate = true,
    this.cameraControls = true,
    this.ar = false,
    this.backgroundColor = const Color(0xFF000004),
    this.forceEnable = false,
  });

  /// Whether the 3D viewer may render in the current context.
  static bool allowed(BuildContext context, {bool force = false}) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return false;
    if (force) return true;
    // WebGL viewer -> skip on low-tier devices, fall back to the still.
    return WbDeviceCapability.tier != WbDeviceTier.low;
  }

  @override
  Widget build(BuildContext context) {
    if (!allowed(context, force: forceEnable)) return fallback;
    return ModelViewer(
      src: src,
      alt: alt,
      ar: ar,
      autoRotate: autoRotate,
      cameraControls: cameraControls,
      backgroundColor: backgroundColor,
      // Without lighting a glTF renders black on a dark background -> use the
      // built-in neutral image-based lighting and a slightly higher exposure.
      environmentImage: 'neutral',
      exposure: 1.2,
    );
  }
}
