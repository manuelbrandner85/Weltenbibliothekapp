// Pure-Flutter 3D model view (flutter_cube, OBJ).
//
// Renders an interactive 3D model directly on the Flutter canvas -- NO WebView
// and NO WebGL, so it works on devices where model-viewer rendered black.
// Drag to rotate, pinch to zoom. Optional slow auto-rotation.
//
// Gate: shows the model when reduce-motion is OFF and the device is not
// low-tier; otherwise [fallback]. forceEnable bypasses the tier gate
// (reduce-motion still respected) for explicit 3D screens.

import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart' as cube;

import '../../core/device/wb_device_capability.dart';

class WbModelView extends StatefulWidget {
  /// Asset path to an .obj model (with a sibling .mtl), e.g.
  /// 'assets/models/wb_orb.obj'.
  final String src;

  /// Shown on weak devices / reduce-motion (and as a graceful default).
  final Widget fallback;

  final String alt;
  final bool autoRotate;

  /// Kept for API compatibility (flutter_cube has built-in drag/zoom).
  final bool cameraControls;
  final bool ar;

  final Color backgroundColor;
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
    return WbDeviceCapability.tier != WbDeviceTier.low;
  }

  @override
  State<WbModelView> createState() => _WbModelViewState();
}

class _WbModelViewState extends State<WbModelView>
    with SingleTickerProviderStateMixin {
  cube.Scene? _scene;
  cube.Object? _object;
  AnimationController? _spin;

  @override
  void initState() {
    super.initState();
    if (widget.autoRotate) {
      _spin = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 18),
      )
        ..addListener(_onTick)
        ..repeat();
    }
  }

  void _onTick() {
    final o = _object;
    final s = _scene;
    if (o == null || s == null) return;
    o.rotation.y = _spin!.value * 360.0;
    o.updateTransform();
    s.update();
  }

  @override
  void dispose() {
    _spin?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!WbModelView.allowed(context, force: widget.forceEnable)) {
      return widget.fallback;
    }
    return ColoredBox(
      color: widget.backgroundColor,
      child: cube.Cube(
        onSceneCreated: (cube.Scene scene) {
          _scene = scene;
          scene.camera.zoom = 10;
          final o = cube.Object(
            fileName: widget.src,
            lighting: true,
            backfaceCulling: false,
          );
          _object = o;
          scene.world.add(o);
        },
      ),
    );
  }
}
