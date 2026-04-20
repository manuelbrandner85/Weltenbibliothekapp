import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// 🎬 Professioneller Video-Übergang zwischen Welten
///
/// Ersetzt die alte Animation mit cinematic Portal-Effekt Videos
/// - MATERIE → ENERGIE: Blau zu Lila Transformation
/// - ENERGIE → MATERIE: Lila zu Blau Transformation
class WorldTransitionVideo extends StatefulWidget {
  final Widget targetScreen;
  final bool isMaterieToEnergie; // true = Materie→Energie, false = Energie→Materie

  const WorldTransitionVideo({
    super.key,
    required this.targetScreen,
    required this.isMaterieToEnergie,
  });

  @override
  State<WorldTransitionVideo> createState() => _WorldTransitionVideoState();
}

class _WorldTransitionVideoState extends State<WorldTransitionVideo> {
  VideoPlayerController? _controller;
  bool _isVideoInitialized = false;
  bool _hasNavigated = false;
  bool _hasError = false;
  Timer? _errorRescueTimer;

  @override
  void initState() {
    super.initState();
    _initializeAndPlayVideo();
    // 🛡️ SAFETY NET: Falls das Video überhaupt NICHT anspringt (z.B. auf
    // Geräten ohne passenden H.264-Decoder), lassen wir den User nie länger
    // als 6 Sekunden auf einem "grauen" Ladebildschirm sitzen.
    _errorRescueTimer = Timer(const Duration(seconds: 6), () {
      if (!mounted || _hasNavigated) return;
      if (!_isVideoInitialized) {
        if (kDebugMode) {
          debugPrint('⏱️ Transition-Video Rescue-Timeout → navigiere zum Target');
        }
        _navigateToTarget();
      }
    });
  }

  Future<void> _initializeAndPlayVideo() async {
    final videoPath = widget.isMaterieToEnergie
        ? 'assets/videos/transition_materie_to_energie.mp4'
        : 'assets/videos/transition_energie_to_materie.mp4';

    try {
      final controller = VideoPlayerController.asset(videoPath);
      _controller = controller;

      // ⏱️ Init mit hartem Timeout: einige Android-Geräte hängen beim
      // Decoder-Setup — dann zeigt VideoPlayer einen grauen Frame statt
      // dem Target.
      await controller.initialize().timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          throw TimeoutException('video initialize() > 4s');
        },
      );

      if (!mounted) return;

      setState(() {
        _isVideoInitialized = true;
      });

      await controller.play();
      controller.addListener(_checkVideoProgress);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Transition-Video Fehler: $e');
      }
      if (!mounted) return;
      setState(() => _hasError = true);
      _navigateToTarget();
    }
  }

  void _checkVideoProgress() {
    final c = _controller;
    if (c == null) return;
    if (c.value.isInitialized &&
        c.value.position >= c.value.duration) {
      _navigateToTarget();
    }
  }

  void _navigateToTarget() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            widget.targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  void dispose() {
    _errorRescueTimer?.cancel();
    final c = _controller;
    if (c != null) {
      c.removeListener(_checkVideoProgress);
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fallbackColor = widget.isMaterieToEnergie
        ? const Color(0xFF0D47A1) // Materie Blau
        : const Color(0xFF4A148C); // Energie Lila

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 🎬 FULLSCREEN TRANSITION VIDEO
          if (_isVideoInitialized && _controller != null)
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            )
          else
            Container(color: fallbackColor),

          // ⏭️ SKIP-BUTTON — immer sichtbar, damit der User auch bei nicht
          // startendem Video nie in einem "grauen" Screen festhängt.
          Positioned(
            top: 50,
            right: 20,
            child: SafeArea(
              child: ElevatedButton.icon(
                onPressed: _navigateToTarget,
                icon: const Icon(Icons.skip_next, size: 20),
                label: Text(_hasError ? 'Fortfahren' : 'Überspringen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
