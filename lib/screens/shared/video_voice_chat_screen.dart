import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../services/video_voice_service.dart';

/// Telegram-Style Video + Voice Chat Screen
///
/// BUGFIXES v5.27.0:
/// - Listener jetzt korrekt VOR notifyListeners in initialize() registriert
/// - _cameraLoading Zustand robuster: wird auch bei Service-Fehler zurückgesetzt
/// - localRenderer nur anzeigen wenn _rendererInitialized UND isCameraOn
/// - Kamera-Switch UI: verhindert doppeltes Tippen via _cameraLoading
/// - Verbesserte Verbindungsanzeige: 3 Zustände (Verbinde/Live/Fehler)
/// - VideoGrid: Scroll-Problem bei 1 Remote-Participant behoben (GridView → Expanded-Column)
///
/// BUGFIXES v5.26.0 beibehalten:
/// - Local preview: 140×190, objectFit=Contain → kein Face-Cropping
/// - _buildVideoTiles: nur remote Video-Teilnehmer im Grid
/// - Leerer Zustand: zeigt eigenen Avatar-Kreis
/// - accentColor für Kamera-Rand
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
  bool _cameraLoading = false;

  // Lokale Kamera-Vorschau Offset (draggable)
  Offset _localPreviewOffset = const Offset(16, 16);

  @override
  void initState() {
    super.initState();
    _service = VideoVoiceService();
    // BUG-FIX v5.27.0: Listener VOR initialize() registrieren damit
    // keine Events verloren gehen (der Listener wird bei initialize() bereits benötigt)
    _service.addListener(_onServiceChange);

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
    // BUG-FIX v5.27.0: Kamera-Preview nur wenn Renderer wirklich initialisiert ist
    final showLocalPreview = _service.isCameraOn &&
        _isInitialized &&
        !_cameraLoading &&
        _service.localStream != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildVideoGrid()),
                _buildBottomControls(),
              ],
            ),

            // Lokale Kamera-Vorschau (draggable)
            if (showLocalPreview) _buildDraggableLocalPreview(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TOP BAR
  // ─────────────────────────────────────────────

  Widget _buildTopBar() {
    final count = _service.participants.length + 1;

    // BUG-FIX v5.27.0: 3 Verbindungszustände
    final Color statusColor;
    final String statusText;
    if (_service.isInitializing) {
      statusColor = Colors.orange;
      statusText = 'Verbinde...';
    } else if (_service.isConnected) {
      statusColor = Colors.green;
      statusText = 'Live';
    } else {
      statusColor = Colors.red;
      statusText = 'Getrennt';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
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
                '$count Teilnehmer${_service.isInitializing ? ' · Beitreten...' : ''}',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
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
  // BUG-FIX v5.27.0: GridView shrinkWrap durch Expanded-Logik ersetzt
  // um Overflow bei einzelnem remote Teilnehmer zu verhindern
  // ─────────────────────────────────────────────

  Widget _buildVideoGrid() {
    final videoParticipants = _service.participants.values
        .where((p) => p.isCameraOn)
        .toList();
    final audioParticipants = _service.participants.values
        .where((p) => !p.isCameraOn)
        .toList();

    final hasLocalVideo = _service.isCameraOn && _isInitialized && !_cameraLoading;
    final totalVideoCount = videoParticipants.length + (hasLocalVideo ? 1 : 0);

    // Kein Teilnehmer außer uns selbst
    if (_service.participants.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          // Video-Tiles (remote participants mit Kamera)
          if (videoParticipants.isNotEmpty)
            Expanded(
              flex: audioParticipants.isEmpty ? 1 : 3,
              child: _buildVideoTiles(videoParticipants),
            ),

          // Audio-only Teilnehmer
          if (audioParticipants.isNotEmpty)
            SizedBox(
              height: totalVideoCount == 0 ? null : 140,
              child: totalVideoCount == 0
                  ? _buildVoiceOnlyGrid(audioParticipants)
                  : _buildVoiceOnlyRow(audioParticipants),
            ),

          // Nur Audio-Teilnehmer vorhanden (kein remote Video)
          if (videoParticipants.isEmpty && audioParticipants.isNotEmpty)
            Expanded(
              flex: 2,
              child: _buildVoiceOnlyGrid(audioParticipants),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoTiles(List<VoiceVideoParticipant> videoParticipants) {
    final count = videoParticipants.length;
    final columns = count <= 1 ? 1 : 2;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: 3 / 4,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: count,
      physics: const BouncingScrollPhysics(),
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
          if (renderer != null)
            RTCVideoView(
              renderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
            )
          else
            _buildAvatarFallback(participant),

          // Gradient + Username
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
                  Flexible(
                    child: Text(
                      participant.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
        child: Container(
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
          style: const TextStyle(color: Colors.white70, fontSize: 12),
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
          const SizedBox(height: 12),
          Text(
            'Raum: ${widget.roomId.toUpperCase()}',
            style: const TextStyle(color: Colors.white24, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // LOKALE KAMERA-VORSCHAU (Draggable)
  // BUGFIX v5.26.0: 140×190, Contain, accentColor-Rand
  // BUGFIX v5.27.0: Nur anzeigen wenn localStream != null
  // ─────────────────────────────────────────────

  Widget _buildDraggableLocalPreview() {
    final screenSize = MediaQuery.of(context).size;
    return Positioned(
      right: _localPreviewOffset.dx,
      bottom: _localPreviewOffset.dy + 100,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _localPreviewOffset = Offset(
              (_localPreviewOffset.dx - details.delta.dx)
                  .clamp(0, screenSize.width - 150),
              (_localPreviewOffset.dy - details.delta.dy)
                  .clamp(0, screenSize.height - 220),
            );
          });
        },
        child: Container(
          width: 140,
          height: 190,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.accentColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              RTCVideoView(
                _service.localRenderer,
                mirror: _service.isFrontCamera,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
              ),
              // Username-Label
              Positioned(
                bottom: 4,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BOTTOM CONTROLS (Glassmorphism)
  // BUG-FIX v5.27.0: Kamera-Button verhindert Doppeltippen während Ladevorgang
  // ─────────────────────────────────────────────

  Widget _buildBottomControls() {
    final cameraEnabled = !_cameraLoading;
    final switchEnabled = _service.isCameraOn && !_cameraLoading;

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
            onTap: cameraEnabled ? _handleToggleCamera : null,
          ),

          // Kamera wechseln
          _buildControlButton(
            icon: Icons.flip_camera_ios,
            label: 'Wechseln',
            color: switchEnabled ? Colors.white : Colors.white24,
            bgColor: switchEnabled
                ? widget.accentColor.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            onTap: switchEnabled ? _handleSwitchCamera : null,
          ),

          // Auflegen
          _buildControlButton(
            icon: Icons.call_end,
            label: 'Auflegen',
            color: Colors.white,
            bgColor: Colors.red,
            onTap: _handleHangUp,
          ),
        ],
      ),
    );
  }

  Future<void> _handleToggleCamera() async {
    if (_cameraLoading) return;
    if (mounted) setState(() => _cameraLoading = true);
    try {
      await _service.toggleCamera();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kamera-Fehler: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cameraLoading = false);
    }
  }

  Future<void> _handleSwitchCamera() async {
    if (_cameraLoading) return;
    if (mounted) setState(() => _cameraLoading = true);
    try {
      await _service.switchCamera();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kamera wechseln fehlgeschlagen: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cameraLoading = false);
    }
  }

  Future<void> _handleHangUp() async {
    await _service.disconnect();
    if (mounted) Navigator.of(context).pop();
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
