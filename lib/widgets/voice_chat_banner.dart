/// 🎙️ Voice Chat Banner Widget
/// Shows voice chat availability banner
library;

import 'package:flutter/material.dart';
import '../services/pinned_rooms_service.dart'; // 📌 Pinned Rooms
import '../screens/shared/telegram_voice_screen.dart';
import '../services/simple_voice_controller.dart'; // ✅ CRITICAL FIX
import 'dart:math' as math;

class VoiceChatBanner extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String userId;
  final String username;
  final Color color;

  const VoiceChatBanner({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.userId,
    required this.username,
    required this.color,
  });

  @override
  State<VoiceChatBanner> createState() => _VoiceChatBannerState();
}

class _VoiceChatBannerState extends State<VoiceChatBanner> with SingleTickerProviderStateMixin {
  final PinnedRoomsService _pinnedRooms = PinnedRoomsService();
  bool _isPinned = false;
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _loadPinStatus();
    
    // 🌊 Wave Animation Setup
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.linear),
    );
  }

  Future<void> _loadPinStatus() async {
    await _pinnedRooms.loadPinnedRooms();
    setState(() {
      _isPinned = _pinnedRooms.isPinned(widget.roomId);
    });
  }

  Future<void> _togglePin() async {
    await _pinnedRooms.togglePin(widget.roomId);
    setState(() {
      _isPinned = _pinnedRooms.isPinned(widget.roomId);
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isPinned
                ? '📌 Voice-Room gepinnt'
                : '📌 Voice-Room entpinnt',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // 🎯 CRITICAL FIX: Join voice room BEFORE opening screen!
        print('🎤 [VoiceChatBanner] Banner tapped - joining voice room...');
        
        final voiceController = SimpleVoiceController();
        
        try {
          // STEP 1: Init microphone
          if (voiceController.localStream == null) {
            print('🎤 [VoiceChatBanner] Initializing microphone...');
            final micSuccess = await voiceController.initMicrophone();
            if (!micSuccess) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Mikrofon-Zugriff verweigert'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }
            print('✅ [VoiceChatBanner] Microphone initialized');
          }
          
          // STEP 2: Join room
          print('🚀 [VoiceChatBanner] Joining room: ${widget.roomName}');
          final success = await voiceController.joinVoiceRoom(
            widget.roomId,
            widget.roomName,
            widget.userId,
            widget.username,
          );
          
          if (success && context.mounted) {
            print('✅ [VoiceChatBanner] Join successful, opening voice screen');
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const TelegramVoiceScreen(),
              ),
            );
          } else if (context.mounted) {
            print('❌ [VoiceChatBanner] Join failed');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fehler beim Beitritt zum Voice-Chat'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          print('❌ [VoiceChatBanner] Error: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Stack(
        children: [
          // 🌊 Animated Wave Background
          AnimatedBuilder(
            animation: _waveAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: _WavePainter(
                  color: widget.color,
                  animationValue: _waveAnimation.value,
                ),
                size: Size.infinite,
              );
            },
          ),
          
          // Content
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // 🔧 FIX 5: Kompakter
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.color.withValues(alpha: 0.15),
                  widget.color.withValues(alpha: 0.05),
                ],
              ),
            ),
        child: Row( // 🔧 FIX 5: Row statt Column (horizontal kompakt)
          children: [
            Icon(Icons.groups, color: widget.color, size: 20), // 🔧 Kleiner
            const SizedBox(width: 8),
            Expanded( // 🔧 FIX 5: Text kann wrappen wenn nötig
              child: Text(
                'Voice-Chat', // 🔧 FIX 5: VIEL KÜRZER! "Gruppen-Voice-Chat verfügbar" → "Voice-Chat"
                style: TextStyle(
                  color: widget.color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Pin Icon
            IconButton(
              icon: Icon(
                _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: widget.color.withValues(alpha: _isPinned ? 1.0 : 0.5),
                  size: 18, // 🔧 Kleiner
                ),
                tooltip: _isPinned ? 'Entpinnen' : 'Pinnen',
                onPressed: _togglePin,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            const SizedBox(width: 4), // 🔧 Spacing
            // 🔧 FIX 5: Join Button (Icon-only für Kompaktheit)
            Container(
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.phone,
                color: widget.color,
                size: 18,
              ),
            ),
          ],
        ),
          ),
        ],
      ),
    );
  }
}

/// 🌊 Wave Painter for Animated Background
class _WavePainter extends CustomPainter {
  final Color color;
  final double animationValue;

  _WavePainter({required this.color, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = 8.0;
    final waveLength = size.width / 2;

    path.moveTo(0, size.height);
    path.lineTo(0, size.height / 2);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        size.height / 2 +
            math.sin((i / waveLength + animationValue) * 2 * math.pi) *
                waveHeight,
      );
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) =>
      animationValue != oldDelegate.animationValue;
}
