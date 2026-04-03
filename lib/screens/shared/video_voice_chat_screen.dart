import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../services/video_voice_service.dart';

/// Telegram-Style Video + Voice Chat Screen
/// - Video-Grid für Teilnehmer mit Kamera
/// - Voice-only Kreise für Teilnehmer ohne Kamera
/// - Kamera ist optional (standardmäßig aus)
/// - Dark UI (#0D0D1A) mit glassmorphism Controls
class VideoVoiceChatScreen extends StatefulWidget {
  final String roomId;
  final String userId;
  final String username;
  final String avatar;
  final Color accentColor;

  const VideoVoiceChatScreen({
    super.key,
    required this.roomId,
    required this.userId,
    required this.username,
    this.avatar = '👤',
    this.accentColor = const Color(0xFF7C4DFF),
  });

  @override
  State<VideoVoiceChatScreen> createState() => _VideoVoiceChatScreenState();
}

class _VideoVoiceChatScreenState extends State<VideoVoiceChatScreen>
    with SingleTickerProviderStateMixin {
  late VideoVoiceService _service;
  late AnimationController _pulseController;
  bool _isInitialized = false;
  bool _cameraLoading = false; // Loading-Indikator für Kameraoperationen

  // Lokale Kamera-Vorschau Offset (draggable)
  Offset _localPreviewOffset = const Offset(16, 16);

  @override
  void initState() {
    super.initState();
    _service = VideoVoiceService();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _initialize();
  }

  Future<void> _initialize() async {
    await _service.initialize(
      roomId: widget.roomId,
      userId: widget.userId,
      username: widget.username,
      avatar: widget.avatar,
    );
    _service.addListener(_onServiceChange);
    if (mounted) setState(() => _isInitialized = true);
  }

  void _onServiceChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChange);
    _service.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Stack(
          children: [
            // Haupt-Inhalt
            Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildVideoGrid()),
                _buildBottomControls(),
              ],
            ),

            // Lokale Kamera-Vorschau (draggable, unten rechts)
            if (_service.isCameraOn && _isInitialized)
              _buildDraggableLocalPreview(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TOP BAR
  // ─────────────────────────────────────────────

  Widget _buildTopBar() {
    final count = _service.participants.length + 1; // +1 für sich selbst
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Raum-Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.roomId.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '$count Teilnehmer',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
          const Spacer(),
          // Verbindungs-Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _service.isConnected
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _service.isConnected ? Colors.green : Colors.orange,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _service.isConnected ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _service.isConnected ? 'Live' : 'Verbinde...',
                  style: TextStyle(
                    color: _service.isConnected ? Colors.green : Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // VIDEO GRID
  // ─────────────────────────────────────────────

  Widget _buildVideoGrid() {
    final videoParticipants = _service.participants.values
        .where((p) => p.isCameraOn)
        .toList();
    final audioParticipants = _service.participants.values
        .where((p) => !p.isCameraOn)
        .toList();

    // Lokaler Video-Teilnehmer
    final hasLocalVideo = _service.isCameraOn && _isInitialized;
    final totalVideoCount = videoParticipants.length + (hasLocalVideo ? 1 : 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          // Video-Tiles
          if (totalVideoCount > 0)
            Expanded(
              flex: audioParticipants.isEmpty ? 1 : 3,
              child: _buildVideoTiles(videoParticipants, hasLocalVideo),
            ),

          // Audio-only Teilnehmer
          if (audioParticipants.isNotEmpty)
            SizedBox(
              height: totalVideoCount == 0 ? null : 140,
              child: totalVideoCount == 0
                  ? _buildVoiceOnlyGrid(audioParticipants)
                  : _buildVoiceOnlyRow(audioParticipants),
            ),

          // Leerer Zustand
          if (totalVideoCount == 0 && audioParticipants.isEmpty)
            Expanded(child: _buildEmptyState()),
        ],
      ),
    );
  }

  Widget _buildVideoTiles(
    List<VoiceVideoParticipant> videoParticipants,
    bool hasLocalVideo,
  ) {
    final count = videoParticipants.length + (hasLocalVideo ? 1 : 0);
    // Grid-Layout
    int columns = count <= 1 ? 1 : 2;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: 9 / 16,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: videoParticipants.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (ctx, i) {
        final p = videoParticipants[i];
        return _buildVideoTile(
          participant: p,
          renderer: _service.remoteRenderers[p.userId],
        );
      },
    );
  }

  Widget _buildVideoTile({
    required VoiceVideoParticipant participant,
    RTCVideoRenderer? renderer,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video
          if (renderer != null)
            RTCVideoView(
              renderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            )
          else
            _buildAvatarFallback(participant),

          // Gradient unten für Username
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
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
              child: Row(
                children: [
                  Text(
                    participant.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    participant.isMicOn ? Icons.mic : Icons.mic_off,
                    color: participant.isMicOn ? Colors.white : Colors.red,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(VoiceVideoParticipant participant) {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: widget.accentColor.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  participant.avatar,
                  style: const TextStyle(fontSize: 36),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceOnlyGrid(List<VoiceVideoParticipant> participants) {
    return Center(
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: [
          _buildVoiceCircle(
            name: widget.username,
            avatar: widget.avatar,
            isMicOn: _service.isMicOn,
            isSelf: true,
          ),
          ...participants.map((p) => _buildVoiceCircle(
                name: p.username,
                avatar: p.avatar,
                isMicOn: p.isMicOn,
              )),
        ],
      ),
    );
  }

  Widget _buildVoiceOnlyRow(List<VoiceVideoParticipant> participants) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      itemCount: participants.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (ctx, i) {
        final p = participants[i];
        return _buildVoiceCircle(
          name: p.username,
          avatar: p.avatar,
          isMicOn: p.isMicOn,
        );
      },
    );
  }

  Widget _buildVoiceCircle({
    required String name,
    required String avatar,
    required bool isMicOn,
    bool isSelf = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (ctx, child) {
            return Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelf
                    ? widget.accentColor.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.1),
                border: Border.all(
                  color: isMicOn
                      ? widget.accentColor.withValues(
                          alpha: 0.4 + 0.3 * _pulseController.value,
                        )
                      : Colors.grey.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(avatar, style: const TextStyle(fontSize: 32)),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          isSelf ? '$name (Du)' : name,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Icon(
          isMicOn ? Icons.mic : Icons.mic_off,
          color: isMicOn ? Colors.green : Colors.red,
          size: 14,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Eigener Kreis
          _buildVoiceCircle(
            name: widget.username,
            avatar: widget.avatar,
            isMicOn: _service.isMicOn,
            isSelf: true,
          ),
          const SizedBox(height: 32),
          const Text(
            'Warte auf andere Teilnehmer...',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // LOKALE KAMERA-VORSCHAU (Draggable)
  // ─────────────────────────────────────────────

  Widget _buildDraggableLocalPreview() {
    final screenSize = MediaQuery.of(context).size;
    return Positioned(
      right: _localPreviewOffset.dx,
      bottom: _localPreviewOffset.dy + 100, // über Bottom-Bar
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _localPreviewOffset = Offset(
              (_localPreviewOffset.dx - details.delta.dx)
                  .clamp(0, screenSize.width - 130),
              (_localPreviewOffset.dy - details.delta.dy)
                  .clamp(0, screenSize.height - 200),
            );
          });
        },
        child: Container(
          width: 120,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.accentColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 8,
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: RTCVideoView(
            _service.localRenderer,
            mirror: _service.isFrontCamera,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BOTTOM CONTROLS (Glassmorphism)
  // ─────────────────────────────────────────────

  Widget _buildBottomControls() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Mikrofon
          _buildControlButton(
            icon: _service.isMicOn ? Icons.mic : Icons.mic_off,
            label: _service.isMicOn ? 'Mikro' : 'Stumm',
            color: _service.isMicOn ? Colors.white : Colors.red,
            bgColor: _service.isMicOn
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.red.withValues(alpha: 0.2),
            onTap: () => setState(() => _service.toggleMicrophone()),
          ),

          // Kamera
          _buildControlButton(
            icon: _cameraLoading
                ? Icons.hourglass_empty
                : (_service.isCameraOn ? Icons.videocam : Icons.videocam_off),
            label: _cameraLoading
                ? 'Warte...'
                : (_service.isCameraOn ? 'Kamera' : 'Kamera aus'),
            color: _cameraLoading
                ? Colors.orange
                : (_service.isCameraOn ? Colors.blue : Colors.white54),
            bgColor: _service.isCameraOn
                ? Colors.blue.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.1),
            onTap: _cameraLoading ? null : () async {
              if (mounted) setState(() => _cameraLoading = true);
              try {
                await _service.toggleCamera();
              } finally {
                if (mounted) setState(() => _cameraLoading = false);
              }
            },
          ),

          // Kamera wechseln (nur wenn Kamera an)
          _buildControlButton(
            icon: Icons.flip_camera_ios,
            label: 'Wechseln',
            color: (_service.isCameraOn && !_cameraLoading) ? Colors.white : Colors.white24,
            bgColor: Colors.white.withValues(alpha: 0.1),
            onTap: (_service.isCameraOn && !_cameraLoading)
                ? () async {
                    if (mounted) setState(() => _cameraLoading = true);
                    try {
                      await _service.switchCamera();
                    } finally {
                      if (mounted) setState(() => _cameraLoading = false);
                    }
                  }
                : null,
          ),

          // Auflegen
          _buildControlButton(
            icon: Icons.call_end,
            label: 'Auflegen',
            color: Colors.white,
            bgColor: Colors.red,
            onTap: () async {
              await _service.disconnect();
              if (mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
