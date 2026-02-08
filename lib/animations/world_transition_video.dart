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
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initializeAndPlayVideo();
  }

  Future<void> _initializeAndPlayVideo() async {
    try {
      // Wähle Video basierend auf Übergangsrichtung
      final videoPath = widget.isMaterieToEnergie
          ? 'assets/videos/transition_materie_to_energie.mp4'
          : 'assets/videos/transition_energie_to_materie.mp4';

      _controller = VideoPlayerController.asset(videoPath);
      
      await _controller.initialize();
      
      if (!mounted) return;
      
      setState(() {
        _isVideoInitialized = true;
      });

      // Starte Video automatisch
      await _controller.play();

      // Listener für Video-Ende
      _controller.addListener(_checkVideoProgress);
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Transition-Video Fehler: $e');
      }
      // Bei Fehler direkt zur Zielseite navigieren
      _navigateToTarget();
    }
  }

  void _checkVideoProgress() {
    if (_controller.value.isInitialized && 
        _controller.value.position >= _controller.value.duration) {
      // Video zu Ende → zur Zielseite navigieren
      _navigateToTarget();
    }
  }

  void _navigateToTarget() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    // Ersetze aktuelle Route mit Zielseite (kein Back-Button)
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => widget.targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Sanfter Fade-In am Ende
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_checkVideoProgress);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 🎬 FULLSCREEN TRANSITION VIDEO
          if (_isVideoInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            )
          else
            // Loading Fallback (sollte nur sehr kurz sichtbar sein)
            Container(
              color: widget.isMaterieToEnergie
                  ? const Color(0xFF0D47A1) // Materie Blau
                  : const Color(0xFF4A148C), // Energie Lila
            ),
          
          // ⏭️ SKIP-BUTTON (oben rechts)
          if (_isVideoInitialized)
            Positioned(
              top: 50,
              right: 20,
              child: SafeArea(
                child: ElevatedButton.icon(
                  onPressed: _navigateToTarget,
                  icon: const Icon(Icons.skip_next, size: 20),
                  label: const Text('Überspringen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
