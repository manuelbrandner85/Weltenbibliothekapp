// Lightweight, web-safe device capability tier.
//
// Used to decide whether expensive visuals (ambient background videos,
// heavy shaders, particle layers) are worth running on this device.
// Deliberately cheap: no extra plugins, no async, cached after first read.
//
// Heuristic is conservative on purpose -- on weak devices we prefer a static
// still over a janky video. A manual override (CinematicQuality.off) and the
// OS reduce-motion flag are checked separately at the widget level.

import 'package:flutter/foundation.dart';

// CPU core count: real value on native, 0 (unknown) on web.
import 'wb_cpu_io.dart' if (dart.library.html) 'wb_cpu_web.dart';

enum WbDeviceTier { low, mid, high }

class WbDeviceCapability {
  WbDeviceCapability._();

  static WbDeviceTier? _cached;

  /// Cached device tier (computed once).
  static WbDeviceTier get tier => _cached ??= _detect();

  static WbDeviceTier _detect() {
    // Web: GPU/CPU are unknown and highly variable -> stay conservative (mid),
    // which still allows a single ambient loop but blocks "high" extras.
    if (kIsWeb) return WbDeviceTier.mid;

    final cores = wbCpuCores();
    if (cores <= 0) return WbDeviceTier.mid; // unknown -> safe middle
    if (cores <= 4) return WbDeviceTier.low; // entry-level / old devices
    if (cores <= 6) return WbDeviceTier.mid;
    return WbDeviceTier.high;
  }

  /// Whether a moving ambient background video is acceptable here.
  /// Low-tier devices fall back to a static still (battery + jank).
  static bool get allowsAmbientVideo => tier != WbDeviceTier.low;

  /// Whether the heaviest optional effects (extra particle layers, full shader)
  /// should run. Only on clearly capable devices.
  static bool get allowsHeavyEffects => tier == WbDeviceTier.high;

  @visibleForTesting
  static void debugOverrideTier(WbDeviceTier? t) => _cached = t;
}
