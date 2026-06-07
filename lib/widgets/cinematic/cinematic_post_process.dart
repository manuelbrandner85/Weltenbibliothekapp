/// Kaninchenbau Cinema-Postprocessing — Single-Pass Fragment-Shader.
///
/// Wendet Chromatic Aberration + Approx-Bloom + Vignette + Film-Grain auf den
/// Kind-Inhalt an. Qualitaet via [KbCinemaSettings]. Auf Web (CanvasKit-Shader
/// unzuverlaessig) und solange der Shader nicht geladen ist -> Kind unveraendert.
///
/// "Auto" startet bei Subtil und schaltet sich bei nachhaltigem Frame-Jank
/// fuer die Session ab (Schutz schwacher Geraete, keine Oszillation).
library;

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_shaders/flutter_shaders.dart';

import 'cinematic_settings.dart';

class CinematicPostProcess extends StatefulWidget {
  final Widget child;

  /// Wenn false, wird der Shader gar nicht angewendet (z.B. solange das
  /// Lade-Overlay laeuft -- spart GPU waehrend der schweren Lade-Phase).
  final bool enabled;

  const CinematicPostProcess({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<CinematicPostProcess> createState() => _CinematicPostProcessState();
}

class _CinematicPostProcessState extends State<CinematicPostProcess>
    with SingleTickerProviderStateMixin {
  ui.FragmentShader? _shader;
  late final AnimationController _clock;

  // Auto-Watchdog
  double _emaFrameMs = 8.0;
  bool _autoDisabled = false;
  int _jankFrames = 0;
  bool _timingsHooked = false;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 100),
    )..repeat();
    _loadShader();
  }

  Future<void> _loadShader() async {
    if (kIsWeb) return; // Web: kein Shader (CanvasKit-Fragment-Shader unsicher)
    try {
      final program =
          await ui.FragmentProgram.fromAsset('shaders/cinematic_post.frag');
      if (!mounted) return;
      setState(() => _shader = program.fragmentShader());
    } catch (e) {
      if (kDebugMode) debugPrint('[Cinema] Shader-Load fehlgeschlagen: $e');
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    if (_timingsHooked) {
      SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    }
    _shader?.dispose();
    super.dispose();
  }

  // Frame-Time-Watchdog (nur im Auto-Modus aktiv).
  void _onTimings(List<FrameTiming> timings) {
    if (_autoDisabled || !mounted) return;
    for (final t in timings) {
      final ms = t.totalSpan.inMicroseconds / 1000.0;
      _emaFrameMs = _emaFrameMs * 0.9 + ms * 0.1;
    }
    // > ~22ms (unter ~45fps) nachhaltig -> abschalten.
    if (_emaFrameMs > 22.0) {
      _jankFrames++;
      if (_jankFrames > 40) {
        _autoDisabled = true;
        if (mounted) setState(() {});
      }
    } else {
      _jankFrames = (_jankFrames - 1).clamp(0, 1000);
    }
  }

  void _ensureTimingsHook(bool needed) {
    if (needed && !_timingsHooked) {
      SchedulerBinding.instance.addTimingsCallback(_onTimings);
      _timingsHooked = true;
    } else if (!needed && _timingsHooked) {
      SchedulerBinding.instance.removeTimingsCallback(_onTimings);
      _timingsHooked = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shader = _shader;
    if (kIsWeb || shader == null || !widget.enabled) {
      _ensureTimingsHook(false);
      return widget.child;
    }

    return ValueListenableBuilder<CinematicQuality>(
      valueListenable: KbCinemaSettings.instance.quality,
      builder: (context, quality, _) {
        final isAuto = quality == CinematicQuality.auto;
        _ensureTimingsHook(isAuto);

        double master = quality.baseMaster;
        if (isAuto && _autoDisabled) master = 0.0;

        if (master <= 0.0) return widget.child;

        // Child wird gecacht -> nur der Sampler rebuildet pro Frame, nicht der
        // gesamte Inhalt.
        return AnimatedBuilder(
          animation: _clock,
          child: widget.child,
          builder: (context, child) {
            final time = _clock.value * 100.0;
            return AnimatedSampler(
              (ui.Image image, Size size, Canvas canvas) {
                shader
                  ..setFloat(0, size.width)
                  ..setFloat(1, size.height)
                  ..setFloat(2, time)
                  ..setFloat(3, master) // uIntensity
                  ..setFloat(4, 1.0) // grain
                  ..setFloat(5, 1.0) // aberration
                  ..setFloat(6, 1.0) // bloom
                  ..setFloat(7, 1.0) // vignette
                  ..setFloat(8, 0.6) // sharpen (Unsharp-Mask, Fotorealismus)
                  ..setImageSampler(0, image);
                canvas.drawRect(
                  Offset.zero & size,
                  Paint()..shader = shader,
                );
              },
              child: child!,
            );
          },
        );
      },
    );
  }
}

/// Wiederverwendbarer Cinema-Qualitaets-Schalter (Aus/Subtil/Kino/Auto).
/// Steuert das globale [KbCinemaSettings] -- gilt fuer alle Screens.
class CinemaQualityChip extends StatelessWidget {
  final Color accent;
  final Color accentBright;
  const CinemaQualityChip({
    super.key,
    this.accent = const Color(0xFFE53935),
    this.accentBright = const Color(0xFFFF5277),
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CinematicQuality>(
      valueListenable: KbCinemaSettings.instance.quality,
      builder: (context, q, _) {
        return PopupMenuButton<CinematicQuality>(
          tooltip: 'Cinema-Effekte',
          color: const Color(0xFF14141F),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          initialValue: q,
          onSelected: (val) => KbCinemaSettings.instance.set(val),
          itemBuilder: (_) => [
            for (final opt in CinematicQuality.values)
              PopupMenuItem<CinematicQuality>(
                value: opt,
                height: 38,
                child: Row(children: [
                  Icon(
                    opt == q
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 16,
                    color: opt == q ? accentBright : Colors.white38,
                  ),
                  const SizedBox(width: 10),
                  Text(opt.label,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 13)),
                ]),
              ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                q == CinematicQuality.off
                    ? Icons.movie_filter_outlined
                    : Icons.movie_filter,
                size: 14,
                color: q == CinematicQuality.off ? Colors.white38 : accentBright,
              ),
              const SizedBox(width: 5),
              Text(q.label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ]),
          ),
        );
      },
    );
  }
}
