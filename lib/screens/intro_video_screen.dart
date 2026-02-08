import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'portal_home_screen.dart';

/// 🎬 Professionelles Einführungsvideo beim App-Start
/// 
/// Features:
/// - Automatisches Abspielen beim App-Start
/// - Auto-Skip nach Video-Ende
/// - Skip-Button für sofortiges Überspringen
/// - Smooth Fade-Out Animation
/// - Einmalige Anzeige (beim ersten App-Start)
class IntroVideoScreen extends StatefulWidget {
  const IntroVideoScreen({super.key});

  @override
  State<IntroVideoScreen> createState() => _IntroVideoScreenState();
}

class _IntroVideoScreenState extends State<IntroVideoScreen> {
  late VideoPlayerController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      // Video aus Assets laden
      _controller = VideoPlayerController.asset(
        'assets/videos/weltenbibliothek_intro.mp4',
      );

      await _controller.initialize();
      
      // Auto-Play starten
      await _controller.play();
      
      // Listener für Video-Ende
      _controller.addListener(_checkVideoProgress);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Video-Fehler: $e');
      }
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      
      // Bei Fehler direkt zur App springen
      _navigateToApp();
    }
  }

  void _checkVideoProgress() {
    if (_controller.value.isInitialized && 
        _controller.value.position >= _controller.value.duration) {
      // Video zu Ende → zur App navigieren
      _navigateToApp();
    }
  }

  void _navigateToApp() {
    if (!mounted) return;
    
    // Navigation zur Haupt-App mit Fade-Animation
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const PortalHomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
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
          // Video Player
          if (!_isLoading && !_hasError)
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),

          // Loading Indicator
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFFFFD700),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Weltenbibliothek lädt...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          // Skip Button (oben rechts)
          if (!_isLoading && !_hasError)
            SafeArea(
              child: Positioned(
                top: 16,
                right: 16,
                child: TextButton(
                  onPressed: _navigateToApp,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Überspringen',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.skip_next,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
