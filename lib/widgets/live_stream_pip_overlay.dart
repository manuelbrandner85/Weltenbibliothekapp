import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/webrtc_broadcast_service.dart';
import '../services/image_asset_service.dart';
import '../services/auth_service.dart';

/// ═══════════════════════════════════════════════════════════════
/// LIVE STREAM PiP OVERLAY - Picture-in-Picture
/// ═══════════════════════════════════════════════════════════════
/// Draggable floating window showing live stream while navigating the app
/// ═══════════════════════════════════════════════════════════════

class LiveStreamPiPOverlay extends StatefulWidget {
  final WebRTCBroadcastService webrtcService;
  final String roomTitle;
  final VoidCallback onClose;
  final VoidCallback onExpand;

  const LiveStreamPiPOverlay({
    super.key,
    required this.webrtcService,
    required this.roomTitle,
    required this.onClose,
    required this.onExpand,
  });

  @override
  State<LiveStreamPiPOverlay> createState() => _LiveStreamPiPOverlayState();
}

class _LiveStreamPiPOverlayState extends State<LiveStreamPiPOverlay> {
  Offset _position = const Offset(20, 100); // Initial position
  final double _width = 160;
  final double _height = 240;
  final AuthService _authService = AuthService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    // Listen to WebRTC changes to update video
    widget.webrtcService.addListener(_onWebRTCUpdate);
  }

  @override
  void dispose() {
    widget.webrtcService.removeListener(_onWebRTCUpdate);
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (mounted && user != null) {
        setState(() {
          _currentUserId =
              user['id']?.toString() ?? user['username'] as String?;
        });
      }
    } catch (e) {
      // Silent fail
    }
  }

  void _onWebRTCUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildVideoStream() {
    // For Host: Show own camera (localRenderer)
    if (widget.webrtcService.isHost) {
      // Check if camera is enabled and renderer available
      if (widget.webrtcService.isCameraEnabled &&
          widget.webrtcService.localRenderer != null) {
        return SizedBox.expand(
          child: RTCVideoView(
            widget.webrtcService.localRenderer!,
            mirror: true,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
        );
      } else {
        // Camera OFF - Show Energy Symbol as background
        if (_currentUserId != null) {
          final energyImagePath = ImageAssetService.getEnergySymbolForUser(
            _currentUserId!,
          );

          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(energyImagePath),
                fit: BoxFit.cover,
                opacity: 0.9,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
              child: const Center(
                child: Icon(Icons.videocam_off, color: Colors.white, size: 40),
              ),
            ),
          );
        } else {
          // Fallback if user ID not loaded yet
          return Container(
            color: const Color(0xFF1E293B),
            child: const Center(
              child: Icon(Icons.videocam_off, color: Colors.white70, size: 40),
            ),
          );
        }
      }
    } else {
      // For Viewer: Show host stream (first remote renderer)
      final remoteRenderers = widget.webrtcService.remoteRenderers;
      if (remoteRenderers.isNotEmpty) {
        return SizedBox.expand(
          child: RTCVideoView(
            remoteRenderers.values.first,
            mirror: false,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
        );
      } else {
        // No remote stream - Show waiting placeholder
        return Container(
          color: const Color(0xFF1E293B),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  color: Color(0xFF8B5CF6),
                  strokeWidth: 2,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Verbinde...',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            // Update position while dragging
            _position = Offset(
              (_position.dx + details.delta.dx).clamp(
                0,
                screenSize.width - _width,
              ),
              (_position.dy + details.delta.dy).clamp(
                0,
                screenSize.height - _height,
              ),
            );
          });
        },
        onTap: widget.onExpand, // Tap to expand to fullscreen
        child: Container(
          width: _width,
          height: _height,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                // Video Stream
                _buildVideoStream(),

                // Gradient Overlay (top)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // LIVE Badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Close Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),

                // Stream Info & Expand Hint (bottom)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Chat Room Name
                        Text(
                          widget.roomTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        // Expand Icon
                        const Icon(
                          Icons.expand,
                          color: Colors.white70,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),

                // Camera/Mic Status Indicators (bottom-left)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Camera Status
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: widget.webrtcService.isCameraEnabled
                              ? Colors.green.withValues(alpha: 0.8)
                              : Colors.red.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.webrtcService.isCameraEnabled
                              ? Icons.videocam
                              : Icons.videocam_off,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Mic Status
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: widget.webrtcService.isMicEnabled
                              ? Colors.green.withValues(alpha: 0.8)
                              : Colors.red.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.webrtcService.isMicEnabled
                              ? Icons.mic
                              : Icons.mic_off,
                          color: Colors.white,
                          size: 12,
                        ),
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
}
