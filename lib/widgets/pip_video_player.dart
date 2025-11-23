import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../providers/webrtc_provider.dart';

/// Telegram-Style PiP Bubble
/// Kleiner, runder Bubble (wie echtes Telegram)
class PiPVideoPlayer extends StatefulWidget {
  final String roomId;
  final VoidCallback onClose;

  const PiPVideoPlayer({
    super.key,
    required this.roomId,
    required this.onClose,
  });

  @override
  State<PiPVideoPlayer> createState() => _PiPVideoPlayerState();
}

class _PiPVideoPlayerState extends State<PiPVideoPlayer> {
  Offset _position = const Offset(20, 100);
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final webrtcProvider = Provider.of<WebRTCProvider>(context);
    final screenSize = MediaQuery.of(context).size;

    // Telegram-Style: Kleiner runder Bubble
    const double bubbleSize = 70;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onTap: () {
          // Antippen = Zurück zum Chat (Panel unten anzeigen)
          widget.onClose();
        },
        onPanUpdate: (details) {
          setState(() {
            _isDragging = true;
            _position = Offset(
              (_position.dx + details.delta.dx).clamp(
                0,
                screenSize.width - bubbleSize,
              ),
              (_position.dy + details.delta.dy).clamp(
                0,
                screenSize.height - bubbleSize - 100,
              ),
            );
          });
        },
        onPanEnd: (_) {
          setState(() => _isDragging = false);
          _snapToEdge(screenSize, bubbleSize, bubbleSize);
        },
        child: AnimatedContainer(
          duration: _isDragging
              ? Duration.zero
              : const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          width: bubbleSize,
          height: bubbleSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: webrtcProvider.isStreaming(widget.roomId)
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      // REAL Local Video Preview
                      if (webrtcProvider.service.localRenderer != null &&
                          webrtcProvider.service.localRenderer!.srcObject !=
                              null)
                        RTCVideoView(
                          webrtcProvider.service.localRenderer!,
                          mirror: true, // Mirror for selfie view
                          objectFit:
                              RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        )
                      else
                        // Loading state
                        Container(
                          color: const Color(0xFF1A1A2E),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      // LIVE Indicator (roter Puls-Punkt)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(
                    color: const Color(0xFF1A1A2E),
                    child: const Icon(
                      Icons.videocam_off,
                      color: Colors.white70,
                      size: 28,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _snapToEdge(Size screenSize, double bubbleSize, double bubbleHeight) {
    final centerX = _position.dx + bubbleSize / 2;
    final isLeftSide = centerX < screenSize.width / 2;

    setState(() {
      _position = Offset(
        isLeftSide ? 20 : screenSize.width - bubbleSize - 20,
        _position.dy.clamp(100, screenSize.height - bubbleHeight - 200),
      );
    });
  }
}
