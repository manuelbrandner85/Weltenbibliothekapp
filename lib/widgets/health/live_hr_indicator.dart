import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/biometric_service.dart';

/// Visual state of the [LiveHrIndicator].
enum _HrState { loading, ok, noData, error }

/// Live heart-rate indicator that polls [BiometricService.getRestingHeartRate]
/// at a fixed [pollInterval] and pulses a heart icon in rhythm with the
/// detected BPM. Designed to sit above the timer in Gateway/Breathmaster.
class LiveHrIndicator extends StatefulWidget {
  final BiometricService service;
  final Duration pollInterval;
  final Color accentColor;
  final bool autoStart;

  const LiveHrIndicator({
    super.key,
    required this.service,
    this.pollInterval = const Duration(seconds: 10),
    this.accentColor = const Color(0xFFE53935),
    this.autoStart = true,
  });

  @override
  State<LiveHrIndicator> createState() => LiveHrIndicatorState();
}

class LiveHrIndicatorState extends State<LiveHrIndicator>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  Timer? _pollTimer;
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;

  _HrState _state = _HrState.loading;
  int? _bpm;
  DateTime? _lastSuccessAt;
  String? _detectedSource;
  int _beatCounter = 0;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;
  bool _polling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
    _animCtrl.addStatusListener(_onAnimStatus);

    // Detect source non-blocking (works even when diagnose() does not exist).
    _detectSource();

    if (widget.autoStart) {
      start();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animCtrl.removeStatusListener(_onAnimStatus);
    _animCtrl.dispose();
    _pollTimer?.cancel();
    _pollTimer = null;
    super.dispose();
  }

  // --- Public API ---------------------------------------------------------

  /// Start (or restart) polling the biometric service.
  void start() {
    _pollTimer?.cancel();
    // Fire one immediate poll, then schedule periodic.
    _poll();
    _pollTimer = Timer.periodic(widget.pollInterval, (_) => _poll());
  }

  /// Stop polling. Animation halts as well.
  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (_animCtrl.isAnimating) {
      _animCtrl.stop();
    }
  }

  // --- Internals ----------------------------------------------------------

  Future<void> _detectSource() async {
    String? source;
    try {
      final dynamic svc = widget.service;
      final dynamic diagnosis = await svc.diagnose();
      if (diagnosis != null) {
        final dynamic sources = diagnosis.detectedDataSources;
        if (sources is List && sources.isNotEmpty) {
          source = sources.first.toString();
        }
      }
    } catch (_) {
      // diagnose() not available or threw — fall back below.
    }
    source ??= 'Health Connect';
    if (mounted) {
      setState(() {
        _detectedSource = source;
      });
    }
  }

  Future<void> _poll() async {
    if (_polling) return;
    _polling = true;
    try {
      final value = await widget.service.getRestingHeartRate(
        since: const Duration(minutes: 2),
      );
      if (!mounted) return;

      if (value != null && value > 0) {
        final bpm = value.round();
        _bpm = bpm;
        _lastSuccessAt = DateTime.now();
        _state = _HrState.ok;
        _updateAnimDuration(bpm);
        setState(() {});
      } else {
        // No fresh reading — keep last value if very recent (< 60s).
        final last = _lastSuccessAt;
        final keep = last != null &&
            DateTime.now().difference(last) < const Duration(seconds: 60) &&
            _bpm != null;
        if (!keep) {
          _state = _HrState.noData;
          _bpm = null;
          if (_animCtrl.isAnimating) {
            _animCtrl.stop();
          }
          setState(() {});
        }
      }
    } catch (e, st) {
      debugPrint('LiveHrIndicator poll failed: $e\n$st');
      if (!mounted) return;
      _state = _HrState.error;
      if (_animCtrl.isAnimating) {
        _animCtrl.stop();
      }
      setState(() {});
    } finally {
      _polling = false;
    }
  }

  void _updateAnimDuration(int bpm) {
    if (bpm <= 0) return;
    final ms = (60000 / bpm).clamp(300, 2000).round();
    _animCtrl.duration = Duration(milliseconds: ms);
    if (!_animCtrl.isAnimating) {
      _animCtrl.repeat(reverse: true);
    }
  }

  void _onAnimStatus(AnimationStatus status) {
    // One beat = forward + reverse. Fire haptic on each completed beat
    // (i.e. on every "dismissed" event). Throttle to every 3rd beat.
    if (status == AnimationStatus.dismissed) {
      _beatCounter++;
      if (_beatCounter % 3 == 0 &&
          _lifecycle == AppLifecycleState.resumed &&
          _state == _HrState.ok) {
        // Best-effort; ignore platform errors (e.g. desktop/web).
        HapticFeedback.lightImpact().catchError((_) {});
      }
    }
  }

  // --- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildHeart(),
          const SizedBox(height: 2),
          _buildBpmLine(),
          if (_detectedSource != null && _detectedSource!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                _detectedSource!,
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white60,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeart() {
    final Color iconColor;
    switch (_state) {
      case _HrState.ok:
        iconColor = widget.accentColor;
        break;
      case _HrState.error:
        iconColor = const Color(0xFFE53935);
        break;
      case _HrState.loading:
      case _HrState.noData:
        iconColor = Colors.white38;
        break;
    }

    final iconWidget = Icon(
      _state == _HrState.ok ? Icons.favorite : Icons.favorite_border,
      size: 32,
      color: iconColor,
      shadows: _state == _HrState.ok
          ? [
              Shadow(
                color: widget.accentColor.withValues(alpha: 0.7),
                blurRadius: 12,
              ),
            ]
          : null,
    );

    if (_state == _HrState.ok) {
      return AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: child,
          );
        },
        child: iconWidget,
      );
    }
    return iconWidget;
  }

  Widget _buildBpmLine() {
    switch (_state) {
      case _HrState.loading:
        return const Text(
          'Messe...',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        );
      case _HrState.ok:
        return RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${_bpm ?? '--'}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.0,
                  shadows: [
                    Shadow(
                      color: widget.accentColor.withValues(alpha: 0.8),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const TextSpan(
                text: ' BPM',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        );
      case _HrState.noData:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              '--',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white54,
                height: 1.0,
              ),
            ),
            SizedBox(height: 1),
            Text(
              'Keine Daten - Watch synchronisieren?',
              style: TextStyle(fontSize: 9, color: Colors.white54),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      case _HrState.error:
        return const Text(
          'WARN',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFFE53935),
          ),
        );
    }
  }
}
