// Adaptive cinematic backdrop.
//
// Shows a seamless, muted, looping ambient video on capable devices, and a
// static still image everywhere else -- never a blank screen, never jank.
//
// A still is ALWAYS painted first as the base layer, so even if the video
// fails to load (missing asset, decode error) or the device is weak, the user
// sees the fallback image immediately. The video, when allowed and ready,
// cross-fades in on top.
//
// Falls back to the still when ANY of these hold:
//   - no video asset given
//   - OS "reduce motion" is enabled (MediaQuery.disableAnimations)
//   - user set CinematicQuality.off
//   - device is low-tier (WbDeviceCapability)
//   - the video errors on init OR the frame watchdog detects sustained jank
//
// Pure Dart -- no new dependencies. Wire actual asset paths in once the
// Higgsfield assets are generated (see docs/motion/PHASE1_ASSETS.md).

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:video_player/video_player.dart';

import '../../core/device/wb_quality.dart';
import 'cinematic_settings.dart';

class WbAdaptiveBackdrop extends StatefulWidget {
  /// Asset path to a muted, seamless loop (e.g. assets/videos/portal_ambient_loop.mp4).
  /// If null, the still is shown.
  final String? videoAsset;

  /// Asset path to the static fallback still (required -- guarantees no blank).
  final String fallbackImage;

  /// Optional content rendered on top of the backdrop.
  final Widget? child;

  /// How the backdrop fills its box.
  final BoxFit fit;

  /// Optional scrim painted over the backdrop (below [child]) to keep text
  /// legible. Use a translucent color or a gradient via [overlayGradient].
  final Color? overlayColor;

  /// Optional gradient scrim (takes precedence over [overlayColor]).
  final Gradient? overlayGradient;

  /// Solid color shown if even the fallback image fails to load.
  final Color voidColor;

  const WbAdaptiveBackdrop({
    super.key,
    required this.fallbackImage,
    this.videoAsset,
    this.child,
    this.fit = BoxFit.cover,
    this.overlayColor,
    this.overlayGradient,
    this.voidColor = const Color(0xFF000004),
  });

  @override
  State<WbAdaptiveBackdrop> createState() => _WbAdaptiveBackdropState();
}

class _WbAdaptiveBackdropState extends State<WbAdaptiveBackdrop>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _videoReady = false;
  bool _videoDisabled = false; // hard-off after error / jank / policy
  bool _resolved = false;

  // Frame watchdog: only ever degrades (never re-enables) to avoid flicker.
  int _jankFrames = 0;
  int _sampledFrames = 0;
  bool _watching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    KbCinemaSettings.instance.quality.addListener(_onQualityChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery (reduce-motion) is available here.
    if (!_resolved) {
      _resolved = true;
      _maybeStartVideo();
    }
  }

  @override
  void didUpdateWidget(covariant WbAdaptiveBackdrop old) {
    super.didUpdateWidget(old);
    if (old.videoAsset != widget.videoAsset) {
      _teardownVideo();
      _videoDisabled = false;
      _maybeStartVideo();
    }
  }

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  bool get _shouldUseVideo {
    if (widget.videoAsset == null) return false;
    if (_videoDisabled) return false;
    if (_reduceMotion) return false;
    // Central adaptive decision (device tier x user CinematicQuality).
    if (!WbQuality.ambientVideo) return false;
    return true;
  }

  void _onQualityChanged() {
    if (!mounted) return;
    if (KbCinemaSettings.instance.quality.value == CinematicQuality.off) {
      _teardownVideo();
      setState(() {});
    } else if (_controller == null && !_videoDisabled) {
      _maybeStartVideo();
    }
  }

  Future<void> _maybeStartVideo() async {
    if (!_shouldUseVideo || _controller != null) return;
    final path = widget.videoAsset!;
    final c = VideoPlayerController.asset(path);
    _controller = c;
    try {
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        _controller = null;
        return;
      }
      await c.setVolume(0);
      await c.setLooping(true);
      await c.play();
      _startWatchdog();
      setState(() => _videoReady = true);
    } catch (_) {
      // Missing asset / decode error -> permanent still fallback.
      await c.dispose();
      if (_controller == c) _controller = null;
      if (mounted) setState(() => _videoDisabled = true);
    }
  }

  void _teardownVideo() {
    _stopWatchdog();
    _videoReady = false;
    final c = _controller;
    _controller = null;
    c?.dispose();
  }

  // ── Frame watchdog ────────────────────────────────────────────────────────
  void _startWatchdog() {
    if (_watching) return;
    _watching = true;
    _jankFrames = 0;
    _sampledFrames = 0;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  void _stopWatchdog() {
    if (!_watching) return;
    _watching = false;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
  }

  void _onTimings(List<FrameTiming> timings) {
    if (!_watching) return;
    for (final t in timings) {
      _sampledFrames++;
      final totalMs = t.totalSpan.inMicroseconds / 1000.0;
      if (totalMs > 32.0) _jankFrames++; // worse than ~30 FPS
    }
    // Evaluate over a window; degrade only on sustained jank.
    if (_sampledFrames >= 120) {
      final jankRatio = _jankFrames / _sampledFrames;
      if (jankRatio > 0.6) {
        // Sustained jank -> drop to still permanently for this view.
        _videoDisabled = true;
        _teardownVideo();
        if (mounted) setState(() {});
      }
      _jankFrames = 0;
      _sampledFrames = 0;
    }
  }

  // ── Lifecycle: pause video off-screen to save battery ─────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (state == AppLifecycleState.resumed) {
      if (_shouldUseVideo) c.play();
    } else {
      c.pause();
    }
  }

  @override
  void dispose() {
    KbCinemaSettings.instance.quality.removeListener(_onQualityChanged);
    WidgetsBinding.instance.removeObserver(this);
    _teardownVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final showVideo = _videoReady && c != null && c.value.isInitialized;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Base layer: ALWAYS the still (or void color if even that fails).
        Image.asset(
          widget.fallbackImage,
          fit: widget.fit,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => ColoredBox(color: widget.voidColor),
        ),

        // Video cross-fades in on top when ready.
        AnimatedOpacity(
          opacity: showVideo ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOut,
          child: showVideo
              ? FittedBox(
                  fit: widget.fit,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: c.value.size.width,
                    height: c.value.size.height,
                    child: VideoPlayer(c),
                  ),
                )
              : const SizedBox.expand(),
        ),

        // Optional scrim for text legibility.
        if (widget.overlayGradient != null)
          DecoratedBox(
            decoration: BoxDecoration(gradient: widget.overlayGradient),
          )
        else if (widget.overlayColor != null)
          ColoredBox(color: widget.overlayColor!),

        if (widget.child != null) widget.child!,
      ],
    );
  }
}
