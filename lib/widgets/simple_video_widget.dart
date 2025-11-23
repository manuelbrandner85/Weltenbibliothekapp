import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../providers/webrtc_provider.dart';

/// 🎥 Simple Video Widget - Telegram-Style mit PiP über Chat
///
/// Features:
/// - Startet im Fullscreen (über gesamtem Chat)
/// - PiP-Button zum Minimieren
/// - Draggable PiP-Window frei beweglich über Chat
/// - Chat bleibt funktionsfähig während Video läuft
/// - Multi-User Grid-View (2-4 Teilnehmer)
/// - Jeder User kann unabhängig PiP nutzen
class SimpleVideoWidget extends StatefulWidget {
  const SimpleVideoWidget({super.key});

  @override
  State<SimpleVideoWidget> createState() => _SimpleVideoWidgetState();
}

class _SimpleVideoWidgetState extends State<SimpleVideoWidget> {
  // PiP Position (für Drag & Drop)
  Offset _pipPosition = const Offset(20, 100);

  // PiP Größe (anpassbar)
  static const double _pipWidth = 160.0;
  static const double _pipHeight = 240.0;

  @override
  Widget build(BuildContext context) {
    return Consumer<WebRTCProvider>(
      builder: (context, webrtcProvider, child) {
        // Wenn nicht im Channel: Nichts anzeigen
        if (!webrtcProvider.isInChannel) {
          return const SizedBox.shrink();
        }

        // Picture-in-Picture Modus (minimiert über Chat)
        if (webrtcProvider.isPictureInPicture) {
          return _buildPictureInPictureView(webrtcProvider);
        }

        // Full-Screen Modus (über gesamtem Chat)
        return _buildFullScreenView(webrtcProvider);
      },
    );
  }

  /// 🖼️ Picture-in-Picture View (minimiert, draggable über Chat)
  Widget _buildPictureInPictureView(WebRTCProvider webrtcProvider) {
    return Positioned(
      left: _pipPosition.dx,
      top: _pipPosition.dy,
      child: GestureDetector(
        // Drag & Drop Funktionalität
        onPanUpdate: (details) {
          setState(() {
            _pipPosition += details.delta;

            // Begrenze Position auf Bildschirm
            final size = MediaQuery.of(context).size;
            _pipPosition = Offset(
              _pipPosition.dx.clamp(0, size.width - _pipWidth),
              _pipPosition.dy.clamp(0, size.height - _pipHeight),
            );
          });
        },
        // Doppeltipp: Zurück zu Fullscreen
        onDoubleTap: () {
          webrtcProvider.maximizeVideo();
        },
        child: Container(
          width: _pipWidth,
          height: _pipHeight,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
            border: Border.all(color: const Color(0xFF9B59B6), width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                // Video Content
                if (webrtcProvider.isCameraEnabled)
                  _buildLocalVideoView(webrtcProvider)
                else
                  _buildCameraOffPlaceholder(),

                // Gradient Overlay für bessere Button-Sichtbarkeit
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Fullscreen Button (oben links)
                Positioned(
                  top: 8,
                  left: 8,
                  child: _buildPiPControlButton(
                    icon: Icons.fullscreen,
                    onPressed: () => webrtcProvider.maximizeVideo(),
                    tooltip: 'Vollbild',
                  ),
                ),

                // Close Button (oben rechts)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildPiPControlButton(
                    icon: Icons.close,
                    onPressed: () async => await webrtcProvider.leaveChannel(),
                    tooltip: 'Beenden',
                    color: Colors.red,
                  ),
                ),

                // Camera Status & Participant Count (unten)
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Camera Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: webrtcProvider.isCameraEnabled
                              ? Colors.green.withValues(alpha: 0.9)
                              : Colors.red.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          webrtcProvider.isCameraEnabled
                              ? Icons.videocam
                              : Icons.videocam_off,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),

                      // Participant Count
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.people,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${webrtcProvider.remoteUsers.length + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Drag Indicator (Mitte unten)
                Positioned(
                  bottom: 35,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 📺 Full-Screen View (über gesamtem Chat)
  Widget _buildFullScreenView(WebRTCProvider webrtcProvider) {
    final remotePeerIds = webrtcProvider.service.remoteStreams.keys.toList();

    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // ═══════════════════════════════════════════════════════════════
          // NEUE LOGIK: Wenn alleine → Eigene Kamera Vollbild
          // ═══════════════════════════════════════════════════════════════
          if (remotePeerIds.isEmpty)
            // ALLEINE IM CALL: Eigene Kamera im Vollbild
            if (webrtcProvider.isCameraEnabled)
              Center(
                child: SizedBox.expand(
                  child: _buildLocalVideoView(webrtcProvider),
                ),
              )
            else
              _buildCameraOffPlaceholder()
          else
            // MIT ANDEREN: Remote Users Grid anzeigen
            _buildRemoteUsersGrid(webrtcProvider, remotePeerIds),

          // Local Video Preview (Klein, unten rechts) - NUR wenn mit anderen
          if (remotePeerIds.isNotEmpty && webrtcProvider.isCameraEnabled)
            Positioned(
              bottom: 120,
              right: 16,
              child: Container(
                width: 100,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF9B59B6), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildLocalVideoView(webrtcProvider),
                ),
              ),
            ),

          // Control Buttons (Unten)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: _buildControlButtons(webrtcProvider),
          ),

          // PiP Button (Oben rechts) - NEU!
          Positioned(
            top: 16,
            right: 16,
            child: _buildFullscreenControlButton(
              icon: Icons.picture_in_picture_alt,
              label: 'PiP',
              onPressed: () => webrtcProvider.minimizeVideo(),
              tooltip: 'Picture-in-Picture aktivieren',
            ),
          ),

          // Channel Info (Oben links)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // LIVE Indicator
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.people, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${remotePeerIds.length + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 👥 Remote Users Grid (2x2 Grid für bis zu 4 Benutzer)
  Widget _buildRemoteUsersGrid(
    WebRTCProvider webrtcProvider,
    List<String> remotePeerIds,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: remotePeerIds.length > 1 ? 2 : 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 9 / 16,
      ),
      itemCount: remotePeerIds.length > 4 ? 4 : remotePeerIds.length,
      itemBuilder: (context, index) {
        final peerId = remotePeerIds[index];
        return _buildRemoteVideoView(webrtcProvider, peerId);
      },
    );
  }

  /// 📹 Local Video View (Eigene Kamera) - WebRTC Version
  Widget _buildLocalVideoView(WebRTCProvider webrtcProvider) {
    final localRenderer = webrtcProvider.service.localRenderer;

    if (localRenderer == null) {
      return _buildCameraOffPlaceholder();
    }

    return RTCVideoView(
      localRenderer,
      mirror: true, // Spiegeln für Selfie-Ansicht
      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
    );
  }

  /// 📹 Remote Video View (Anderer Benutzer)
  Widget _buildRemoteVideoView(WebRTCProvider webrtcProvider, String peerId) {
    final remoteRenderer = webrtcProvider.service.remoteRenderers[peerId];

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Remote Video Stream
            if (remoteRenderer != null)
              RTCVideoView(
                remoteRenderer,
                mirror: false,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person,
                      size: 48,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Verbinde...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

            // Peer ID Badge
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  peerId.substring(0, 12),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ❌ Kamera Aus Placeholder
  Widget _buildCameraOffPlaceholder() {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off,
              size: 48,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Kamera aus',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🎛️ Control Buttons (Kamera, Mikrofon, Auflegen, Switch Camera)
  Widget _buildControlButtons(WebRTCProvider webrtcProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Kamera Toggle
          _buildControlButton(
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

          // Mikrofon Toggle
          _buildControlButton(
            icon: webrtcProvider.isMicEnabled ? Icons.mic : Icons.mic_off,
            label: 'Mikrofon',
            isActive: webrtcProvider.isMicEnabled,
            onPressed: () async {
              await webrtcProvider.toggleMicrophone();
            },
          ),

          // Kamera Wechseln (nur wenn Kamera aktiv)
          if (webrtcProvider.isCameraEnabled)
            _buildControlButton(
              icon: Icons.flip_camera_ios,
              label: 'Wechseln',
              isActive: true,
              onPressed: () async {
                await webrtcProvider.switchCamera();
              },
            ),

          // Auflegen Button
          _buildControlButton(
            icon: Icons.call_end,
            label: 'Beenden',
            isActive: true,
            isDestructive: true,
            onPressed: () async {
              await webrtcProvider.leaveChannel();
            },
          ),
        ],
      ),
    );
  }

  /// 🔘 Control Button Widget (Fullscreen)
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    final backgroundColor = isDestructive
        ? Colors.red
        : (isActive ? const Color(0xFF9B59B6) : Colors.grey[800]);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(35),
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// 🔘 PiP Control Button (klein, rund)
  Widget _buildPiPControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    Color? color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: (color ?? Colors.black).withValues(alpha: 0.7),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
        tooltip: tooltip,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }

  /// 🔘 Fullscreen Control Button (groß, mit Label)
  Widget _buildFullscreenControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF9B59B6), width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
