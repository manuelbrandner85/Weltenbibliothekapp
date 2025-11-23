import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/webrtc_provider.dart';

/// 100% Telegram-Exakte Voice Chat Implementation
/// Basierend auf echten Screenshots
class RoomVideoWidget extends StatefulWidget {
  final String roomId;

  const RoomVideoWidget({super.key, required this.roomId});

  @override
  State<RoomVideoWidget> createState() => _RoomVideoWidgetState();
}

class _RoomVideoWidgetState extends State<RoomVideoWidget> {
  bool _isExpanded = false; // Minimiert by default!

  @override
  Widget build(BuildContext context) {
    return Consumer<WebRTCProvider>(
      builder: (context, webrtcProvider, child) {
        final isStreamingInThisRoom = webrtcProvider.isStreaming(widget.roomId);
        final isPiPActive = webrtcProvider.pipRoomId == widget.roomId;

        // Wenn kein Stream oder PiP aktiv → nichts anzeigen
        if (!isStreamingInThisRoom || isPiPActive) {
          return const SizedBox.shrink();
        }

        // TELEGRAM-STYLE: Minimierter Banner ODER Expandiertes Panel
        return _isExpanded
            ? _buildExpandedPanel(webrtcProvider)
            : _buildMinimizedBanner(webrtcProvider);
      },
    );
  }

  /// MINIMIERTER ZUSTAND - Kleiner Banner oben (wie Telegram!)
  Widget _buildMinimizedBanner(WebRTCProvider webrtcProvider) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: GestureDetector(
          onTap: () {
            setState(() => _isExpanded = true);
          },
          child: Container(
            height: 48, // Klein! Wie Telegram
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Voice Chat Icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  child: const Icon(
                    Icons.videocam,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),

                // Text: "Voice Chat"
                const Expanded(
                  child: Text(
                    'Livestream',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // LIVE Indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Expand Icon
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// EXPANDIERTER ZUSTAND - Vollbild Overlay (wie Telegram!)
  Widget _buildExpandedPanel(WebRTCProvider webrtcProvider) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {}, // Prevent closing on tap
        child: Container(
          color: Colors.black.withValues(alpha: 0.8),
          child: SafeArea(
            child: Column(
              children: [
                // Header mit Close Button
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Livestream',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          // Minimize Button
                          IconButton(
                            icon: const Icon(
                              Icons.minimize,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() => _isExpanded = false);
                            },
                            tooltip: 'Minimieren',
                          ),
                          // Close Button (beendet Stream)
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () async {
                              await webrtcProvider.stopRoomStream(
                                widget.roomId,
                              );
                            },
                            tooltip: 'Beenden',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Video/Participants Area
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Video Placeholder
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF8B5CF6),
                                  const Color(0xFF6D28D9),
                                ],
                              ),
                            ),
                            child: Icon(
                              webrtcProvider.isCameraEnabled
                                  ? Icons.videocam
                                  : Icons.mic,
                              color: Colors.white,
                              size: 60,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Streaming...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Controls
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildExpandedControl(
                        icon: webrtcProvider.isMicEnabled
                            ? Icons.mic
                            : Icons.mic_off,
                        label: 'Mikro',
                        isActive: webrtcProvider.isMicEnabled,
                        onPressed: () async {
                          if (webrtcProvider.isMicEnabled) {
                            await webrtcProvider.muteMicrophone();
                          } else {
                            await webrtcProvider.unmuteMicrophone();
                          }
                        },
                      ),
                      _buildExpandedControl(
                        icon: webrtcProvider.isCameraEnabled
                            ? Icons.videocam
                            : Icons.videocam_off,
                        label: 'Kamera',
                        isActive: webrtcProvider.isCameraEnabled,
                        onPressed: () async {
                          if (webrtcProvider.isCameraEnabled) {
                            await webrtcProvider.disableCamera();
                          } else {
                            await webrtcProvider.enableCamera();
                          }
                        },
                      ),
                      _buildExpandedControl(
                        icon: Icons.call_end,
                        label: 'Beenden',
                        isActive: false,
                        isDestructive: true,
                        onPressed: () async {
                          await webrtcProvider.stopRoomStream(widget.roomId);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedControl({
    required IconData icon,
    required String label,
    required bool isActive,
    bool isDestructive = false,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDestructive
                  ? Colors.red
                  : (isActive
                        ? const Color(0xFF8B5CF6)
                        : Colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
