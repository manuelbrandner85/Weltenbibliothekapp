import 'dart:async';
import 'package:flutter/material.dart';

/// Chat-Hintergrund-Carousel Widget
/// ✅ AUTOMATISCHER 5-MINUTEN WECHSEL
/// Zeigt 3 wechselbare Hintergrundbilder pro Chat-Typ
/// Hintergrund wechselt automatisch alle 5 Minuten
class ChatBackgroundCarousel extends StatefulWidget {
  final String chatType; // 'weltenbibliothek', 'musik', 'verschwoerung'
  final Widget child; // Chat-Content

  const ChatBackgroundCarousel({
    super.key,
    required this.chatType,
    required this.child,
  });

  @override
  State<ChatBackgroundCarousel> createState() => _ChatBackgroundCarouselState();
}

class _ChatBackgroundCarouselState extends State<ChatBackgroundCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoChangeTimer;

  /// Hintergrundbilder pro Chat-Typ (24K Gold Design)
  static const Map<String, List<String>> backgroundImages = {
    'weltenbibliothek': [
      'assets/images/chat_backgrounds/weltenbibliothek_1.png',
      'assets/images/chat_backgrounds/weltenbibliothek_2.png',
      'assets/images/chat_backgrounds/weltenbibliothek_3.png',
    ],
    'musik': [
      'assets/images/chat_backgrounds/musik_1.png',
      'assets/images/chat_backgrounds/musik_2.png',
      'assets/images/chat_backgrounds/musik_3.png',
    ],
    'verschwoerung': [
      'assets/images/chat_backgrounds/verschwoerung_1.png',
      'assets/images/chat_backgrounds/verschwoerung_2.png',
      'assets/images/chat_backgrounds/verschwoerung_3.png',
    ],
  };

  List<String> get _images => backgroundImages[widget.chatType] ?? [];

  @override
  void initState() {
    super.initState();
    _startAutoChange();
  }

  @override
  void dispose() {
    _autoChangeTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// ✅ Startet automatischen 5-Minuten Hintergrund-Wechsel
  void _startAutoChange() {
    if (_images.length <= 1) return; // Kein Wechsel bei nur 1 Bild

    _autoChangeTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      _nextBackground();
    });
  }

  /// Wechselt zum nächsten Hintergrund (automatisch oder manuell)
  void _nextBackground() {
    final nextPage = (_currentPage + 1) % _images.length;
    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_images.isEmpty) {
      // Fallback: Kein Hintergrund
      return widget.child;
    }

    return Stack(
      children: [
        // Hintergrund-Carousel
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemCount: _images.length,
          itemBuilder: (context, index) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black,
              child: Image.asset(
                _images[index],
                fit: BoxFit.contain, // ✅ FIXED: Keine Abschnitte mehr
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.black,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white30,
                        size: 64,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),

        // Dunkles Overlay für bessere Lesbarkeit
        Container(color: Colors.black.withValues(alpha: 0.4)),

        // Chat-Content
        widget.child,

        // ✅ AUTOMATISCHER WECHSEL - Keine manuellen Buttons mehr!
        // Hintergrund wechselt automatisch alle 5 Minuten
        // Optional: Dezenter Indikator (nur wenn mehrere Bilder)
        if (_images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Nur Seiteindikatoren (kein manueller Wechsel mehr)
                ...List.generate(_images.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 12 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? const Color(0xFFFFD700) // Gold
                          : Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }
}
