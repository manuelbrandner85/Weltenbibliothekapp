import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../providers/webrtc_provider.dart';

/// 100% TELEGRAM-EXAKTE Voice/Video Chat Implementation
/// Basierend auf detaillierter Analyse von offiziellen Telegram Screenshots & Dokumentation
class TelegramVoiceChatWidget extends StatefulWidget {
  final String roomId;
  final String roomName;

  const TelegramVoiceChatWidget({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  State<TelegramVoiceChatWidget> createState() =>
      _TelegramVoiceChatWidgetState();
}

class _TelegramVoiceChatWidgetState extends State<TelegramVoiceChatWidget> {
  bool _isFullscreen = true; // START ALWAYS IN FULLSCREEN! 🔥
  bool _showParticipantsList = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<WebRTCProvider>(
      builder: (context, webrtcProvider, child) {
        final isStreaming = webrtcProvider.isStreaming(widget.roomId);
        final isPiP = webrtcProvider.pipRoomId == widget.roomId;

        // WICHTIGE LOGIK:
        // Zeige Fullscreen NUR wenn ICH SELBST streame UND NICHT in PiP bin

        // Wenn ICH NICHT streame → nichts anzeigen (Live-Leiste wird separat gerendert)
        if (!isStreaming) {
          return const SizedBox.shrink();
        }

        // Wenn PiP aktiv → nichts hier anzeigen (PiP wird global gerendert)
        if (isPiP) {
          return const SizedBox.shrink();
        }

        // TELEGRAM-STYLE: Fullscreen Call UI deckt GANZEN Bildschirm ab
        // Startet IMMER in Fullscreen (_isFullscreen = true)
        return _isFullscreen
            ? _buildFullscreenCallUI(webrtcProvider)
            : _buildMinimizedBanner(webrtcProvider);
      },
    );
  }

  /// ═══════════════════════════════════════════════════════════════
  /// MINIMIERTER BANNER (wie Telegram - kleines Panel oben)
  /// ═══════════════════════════════════════════════════════════════
  Widget _buildMinimizedBanner(WebRTCProvider webrtcProvider) {
    // REAL Participant Count from WebRTC
    final remoteCount = webrtcProvider.service.remoteRenderers.length;
    final participantCount = 1 + remoteCount; // You + remotes

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: GestureDetector(
          onTap: () {
            setState(() => _isFullscreen = true);
          },
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  child: Icon(
                    webrtcProvider.isCameraEnabled ? Icons.videocam : Icons.mic,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Text
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Voice Chat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$participantCount participant${participantCount != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
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
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════
  /// FULLSCREEN CALL UI (wie Telegram - Grid + Controls)
  /// ═══════════════════════════════════════════════════════════════
  Widget _buildFullscreenCallUI(WebRTCProvider webrtcProvider) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF0F0F1E),
        child: SafeArea(
          child: Stack(
            children: [
              // Main Content
              Column(
                children: [
                  // Header
                  _buildHeader(webrtcProvider),

                  // Video Grid Area
                  Expanded(
                    child: _showParticipantsList
                        ? _buildSplitView(webrtcProvider)
                        : _buildVideoGrid(webrtcProvider),
                  ),

                  // Controls
                  _buildControls(webrtcProvider),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════
  /// HEADER (Titel + Teilnehmerzahl + Menu + Close)
  /// ═══════════════════════════════════════════════════════════════
  Widget _buildHeader(WebRTCProvider webrtcProvider) {
    // REAL Participant Count from WebRTC
    final remoteCount = webrtcProvider.service.remoteRenderers.length;
    final participantCount = 1 + remoteCount; // You + remotes

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.roomName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$participantCount participant${participantCount != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Participants List Toggle
          IconButton(
            icon: Icon(
              _showParticipantsList ? Icons.grid_view : Icons.people,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() => _showParticipantsList = !_showParticipantsList);
            },
            tooltip: _showParticipantsList ? 'Show Grid' : 'Show Participants',
          ),

          // PiP Button (statt Minimize)
          IconButton(
            icon: const Icon(Icons.picture_in_picture_alt, color: Colors.white),
            onPressed: () {
              // Aktiviere PiP statt nur zu minimieren
              webrtcProvider.enablePiP(widget.roomId);
              setState(() => _isFullscreen = false);
            },
            tooltip: 'PiP Modus',
          ),

          // Close Button
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () async {
              await webrtcProvider.stopRoomStream(widget.roomId);
              if (mounted) {
                setState(() => _isFullscreen = false);
              }
            },
            tooltip: 'Leave',
          ),
        ],
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════
  /// VIDEO GRID - MEIN VIDEO GROß (VOLLBILD) + ANDERE KLEIN
  /// ═══════════════════════════════════════════════════════════════
  Widget _buildVideoGrid(WebRTCProvider webrtcProvider) {
    // REAL WebRTC Participants
    final localParticipant = {
      'name': 'You',
      'peerId': 'local',
      'isSpeaking': true,
      'hasVideo': webrtcProvider.isCameraEnabled,
      'renderer': webrtcProvider.service.localRenderer,
      'isLocal': true,
    };

    // Add remote participants from WebRTC
    final remoteParticipants = <Map<String, dynamic>>[];
    final remoteRenderers = webrtcProvider.service.remoteRenderers;
    for (final entry in remoteRenderers.entries) {
      final peerId = entry.key;
      final renderer = entry.value;

      remoteParticipants.add({
        'name': 'Participant ${peerId.substring(0, 4)}',
        'peerId': peerId,
        'isSpeaking': false,
        'hasVideo': true,
        'renderer': renderer,
        'isLocal': false,
      });
    }

    return Stack(
      children: [
        // 🎥 MEIN VIDEO - VOLLBILD HINTERGRUND
        Positioned.fill(
          child: _buildParticipantTile(
            name: localParticipant['name'] as String,
            isSpeaking: localParticipant['isSpeaking'] as bool,
            hasVideo: localParticipant['hasVideo'] as bool,
            renderer: localParticipant['renderer'] as RTCVideoRenderer?,
            isLocal: localParticipant['isLocal'] as bool,
          ),
        ),

        // 🎥 ANDERE TEILNEHMER - KLEINE KACHELN OBEN RECHTS
        if (remoteParticipants.isNotEmpty)
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: remoteParticipants.map((participant) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: 120,
                    height: 160,
                    child: _buildParticipantTile(
                      name: participant['name'] as String,
                      isSpeaking: participant['isSpeaking'] as bool,
                      hasVideo: participant['hasVideo'] as bool,
                      renderer: participant['renderer'] as RTCVideoRenderer?,
                      isLocal: participant['isLocal'] as bool,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  /// Einzelne Teilnehmer-Kachel
  Widget _buildParticipantTile({
    required String name,
    required bool isSpeaking,
    required bool hasVideo,
    RTCVideoRenderer? renderer,
    bool isLocal = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSpeaking ? const Color(0xFF8B5CF6) : Colors.transparent,
          width: 3,
        ),
      ),
      child: Stack(
        children: [
          // REAL Video Renderer
          if (hasVideo && renderer != null && renderer.srcObject != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: RTCVideoView(
                renderer,
                mirror: isLocal, // Mirror local video
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            )
          else if (hasVideo)
            // Video Loading State
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                ),
              ),
            )
          else
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
                  ),
                ),
                child: Center(
                  child: Text(
                    name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          // Name Label
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSpeaking) ...[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  /// ═══════════════════════════════════════════════════════════════
  /// SPLIT VIEW (Video Grid + Teilnehmerliste)
  /// ═══════════════════════════════════════════════════════════════
  Widget _buildSplitView(WebRTCProvider webrtcProvider) {
    // REAL Participant List from WebRTC
    final participantsList = <Map<String, dynamic>>[];

    // Add local user
    participantsList.add({
      'name': 'You',
      'isSpeaking': true,
      'hasMic': webrtcProvider.isMicEnabled,
    });

    // Add remote participants
    final remoteRenderers = webrtcProvider.service.remoteRenderers;
    for (final entry in remoteRenderers.entries) {
      final peerId = entry.key;
      participantsList.add({
        'name': 'Participant ${peerId.substring(0, 4)}',
        'isSpeaking': false,
        'hasMic': true, // Assume remote has mic
      });
    }

    return Row(
      children: [
        // Video Grid (Left)
        Expanded(flex: 2, child: _buildVideoGrid(webrtcProvider)),

        // Participants List (Right)
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              border: Border(
                left: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Participants (${participantsList.length})',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: participantsList.length,
                    itemBuilder: (context, index) {
                      final participant = participantsList[index];
                      return _buildParticipantListItem(
                        participant['name'] as String,
                        participant['isSpeaking'] as bool,
                        participant['hasMic'] as bool,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantListItem(String name, bool isSpeaking, bool hasMic) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
          ),
        ),
        child: Center(
          child: Text(
            name[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSpeaking)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 8),
          Icon(
            hasMic ? Icons.mic : Icons.mic_off,
            color: hasMic ? Colors.white : Colors.white38,
            size: 20,
          ),
        ],
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════
  /// CONTROLS (UNTEN - große runde Buttons wie Telegram)
  /// ═══════════════════════════════════════════════════════════════
  Widget _buildControls(WebRTCProvider webrtcProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Microphone
          _buildControlButton(
            icon: webrtcProvider.isMicEnabled ? Icons.mic : Icons.mic_off,
            label: webrtcProvider.isMicEnabled ? 'Mute' : 'Unmute',
            isActive: webrtcProvider.isMicEnabled,
            onPressed: () async {
              if (webrtcProvider.isMicEnabled) {
                await webrtcProvider.muteMicrophone();
              } else {
                await webrtcProvider.unmuteMicrophone();
              }
            },
          ),

          // Camera
          _buildControlButton(
            icon: webrtcProvider.isCameraEnabled
                ? Icons.videocam
                : Icons.videocam_off,
            label: webrtcProvider.isCameraEnabled
                ? 'Stop Video'
                : 'Start Video',
            isActive: webrtcProvider.isCameraEnabled,
            onPressed: () async {
              if (webrtcProvider.isCameraEnabled) {
                await webrtcProvider.disableCamera();
              } else {
                await webrtcProvider.enableCamera();
              }
            },
          ),

          // Screen Share (placeholder)
          _buildControlButton(
            icon: Icons.screen_share,
            label: 'Share',
            isActive: false,
            onPressed: () {
              // TODO: Implement screen sharing
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Screen sharing coming soon')),
              );
            },
          ),

          // Leave
          _buildControlButton(
            icon: Icons.call_end,
            label: 'Leave',
            isActive: false,
            isDestructive: true,
            onPressed: () async {
              await webrtcProvider.stopRoomStream(widget.roomId);
              if (mounted) {
                setState(() => _isFullscreen = false);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDestructive
                  ? Colors.red
                  : (isActive
                        ? const Color(0xFF8B5CF6)
                        : Colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
