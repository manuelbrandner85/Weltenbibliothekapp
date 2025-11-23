import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import '../services/webrtc_broadcast_service.dart';
import '../services/live_room_service.dart';
import '../services/auth_service.dart';
import '../providers/live_stream_pip_provider.dart';
import '../widgets/chat_background_carousel.dart';
import '../services/energy_symbol_service.dart';
import '../widgets/connection_quality_indicator.dart';
import '../services/connection_quality_notifier.dart';
import 'dart:async';

/// ═══════════════════════════════════════════════════════════════
/// LIVE STREAM VIEWER SCREEN - Weltenbibliothek
/// ═══════════════════════════════════════════════════════════════
/// Viewer-Ansicht für Live-Streaming
/// - Kamera startet STANDARDMÄSSIG AUS
/// - Kann eigene Kamera OPTIONAL anmachen
/// - Sieht Host-Stream in Vollbild
/// - Sieht andere Viewer (falls deren Kamera an ist)
/// ═══════════════════════════════════════════════════════════════

class LiveStreamViewerScreen extends StatefulWidget {
  final String roomId;
  final String chatRoomId;
  final String roomTitle;
  final String hostUsername;

  const LiveStreamViewerScreen({
    super.key,
    required this.roomId,
    required this.chatRoomId,
    required this.roomTitle,
    required this.hostUsername,
  });

  @override
  State<LiveStreamViewerScreen> createState() => _LiveStreamViewerScreenState();
}

class _LiveStreamViewerScreenState extends State<LiveStreamViewerScreen> {
  final WebRTCBroadcastService _webrtcService = WebRTCBroadcastService();
  final LiveRoomService _liveRoomService = LiveRoomService();
  final AuthService _authService = AuthService();
  ConnectionQualityNotifier? _qualityNotifier;
  Timer? _notificationCheckTimer;

  bool _isLoading = true;
  String? _error;
  String? _mainStreamPeerId; // Host oder aktuell fokussierter Stream
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _joinStream();

    // Listen to WebRTC state changes
    _webrtcService.addListener(_onWebRTCStateChanged);
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (mounted && user != null) {
      setState(() {
        _currentUserId = user['id']?.toString() ?? user['username'] as String?;
      });
    }
  }

  @override
  void dispose() {
    _notificationCheckTimer?.cancel();
    _qualityNotifier?.dispose();
    _webrtcService.removeListener(_onWebRTCStateChanged);
    _webrtcService.leaveRoom(widget.roomId);
    super.dispose();
  }

  /// Bestimmt den Chat-Typ basierend auf roomTitle oder chatRoomId
  /// LOGIK:
  /// - "Allgemeiner Chat" → Weltenbibliothek-Hintergründe
  /// - "Musik"-Chats → Musik-Hintergründe
  /// - Selbst erstellte Kanäle → Verschwörungstheorien-Hintergründe
  String _getChatType() {
    final title = widget.roomTitle.toLowerCase();
    final chatId = widget.chatRoomId.toLowerCase();

    // 1. Allgemeiner Chat → Weltenbibliothek
    if (title.contains('allgemein') || chatId.contains('allgemein')) {
      return 'weltenbibliothek';
    }

    // 2. Musik-Chat → Musik
    if (title.contains('musik') || chatId.contains('musik')) {
      return 'musik';
    }

    // 3. Standard-Chats (Weltenbibliothek, bekannte Chats) → Weltenbibliothek
    if (title.contains('weltenbibliothek') ||
        chatId.contains('weltenbibliothek') ||
        chatId.contains('chat_')) {
      return 'weltenbibliothek';
    }

    // 4. ALLE ANDEREN (selbst erstellte Kanäle) → Verschwörungstheorien
    return 'verschwoerung';
  }

  void _onWebRTCStateChanged() {
    if (mounted) {
      setState(() {
        // Auto-select first remote stream as main stream
        if (_mainStreamPeerId == null &&
            _webrtcService.remoteRenderers.isNotEmpty) {
          _mainStreamPeerId = _webrtcService.remoteRenderers.keys.first;
        }
      });
    }
  }

  Future<void> _joinStream() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Join room in backend
      await _liveRoomService.joinLiveRoom(widget.roomId);

      // Join as viewer (Kamera AUTO-OFF)
      await _webrtcService.joinAsViewer(widget.roomId, widget.chatRoomId);

      setState(() {
        _isLoading = false;
      });

      // Initialize quality notifier
      _qualityNotifier = ConnectionQualityNotifier(
        _webrtcService.bandwidthMonitor,
      );

      // Start checking for quality notifications
      _startNotificationCheck();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Dem Live-Stream beigetreten'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Fehler beim Beitreten: $e';
        _isLoading = false;
      });
    }
  }

  void _enablePiP(BuildContext context) {
    final pipProvider = Provider.of<LiveStreamPiPProvider>(
      context,
      listen: false,
    );

    // Store current room info for returning to fullscreen
    pipProvider.enablePiP(
      roomId: widget.roomId,
      chatRoomId: widget.chatRoomId,
      roomTitle: widget.roomTitle,
      hostUsername: widget.hostUsername, // Pass host info for viewer
      webrtcService: _webrtcService,
    );

    // Go back to chat room (keep stream running in PiP)
    Navigator.pop(context);
  }

  Future<void> _leaveStream() async {
    // Leave room in backend
    await _liveRoomService.leaveLiveRoom(widget.roomId);

    // Leave WebRTC room
    await _webrtcService.leaveRoom(widget.roomId);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF8B5CF6)),
              const SizedBox(height: 24),
              const Text(
                'Verbinde mit Live-Stream...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(widget.roomTitle),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _joinStream,
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: ChatBackgroundCarousel(
        chatType: _getChatType(), // Dynamischer Chat-Typ basierend auf Room
        child: Stack(
          children: [
            // Main Stream View (Host oder fokussierter Viewer)
            _buildMainStreamView(),

            // Top Bar
            _buildTopBar(),

            // Bottom Controls
            _buildBottomControls(),

            // Other Participants Grid
            _buildParticipantsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainStreamView() {
    if (_mainStreamPeerId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Warte auf Stream von ${widget.hostUsername}...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final renderer = _webrtcService.remoteRenderers[_mainStreamPeerId];

    if (renderer == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
      );
    }

    return SizedBox.expand(
      child: RTCVideoView(
        renderer,
        mirror: false,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Room Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.roomTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.people,
                            size: 12,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_webrtcService.remoteUserCount + 1}', // +1 für uns selbst
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Connection Quality Badge
                          _buildConnectionQualityBadge(),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // PiP Button
                IconButton(
                  icon: const Icon(
                    Icons.picture_in_picture_alt,
                    color: Colors.white,
                  ),
                  onPressed: () => _enablePiP(context),
                  tooltip: 'Zu PiP wechseln',
                ),
                // Close Button
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _leaveStream,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Microphone Toggle
                _buildControlButton(
                  icon: _webrtcService.isMicEnabled ? Icons.mic : Icons.mic_off,
                  label: 'Mikrofon',
                  isActive: _webrtcService.isMicEnabled,
                  onPressed: () {
                    _webrtcService.toggleMicrophone();
                  },
                ),

                // Camera Toggle (OPTIONAL für Viewer)
                _buildControlButton(
                  icon: _webrtcService.isCameraEnabled
                      ? Icons.videocam
                      : Icons.videocam_off,
                  label: 'Kamera',
                  isActive: _webrtcService.isCameraEnabled,
                  onPressed: () {
                    _webrtcService.toggleCamera();
                  },
                ),

                // Switch Camera (nur wenn Kamera an)
                if (_webrtcService.isCameraEnabled)
                  _buildControlButton(
                    icon: Icons.cameraswitch,
                    label: 'Drehen',
                    isActive: true,
                    onPressed: () {
                      _webrtcService.switchCamera();
                    },
                  ),

                // Leave Stream
                _buildControlButton(
                  icon: Icons.call_end,
                  label: 'Verlassen',
                  isActive: false,
                  color: Colors.red,
                  onPressed: _leaveStream,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    Color? color,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? (color ?? const Color(0xFF8B5CF6))
                : Colors.white.withValues(alpha: 0.2),
            boxShadow: [
              BoxShadow(
                color: (color ?? const Color(0xFF8B5CF6)).withValues(
                  alpha: 0.3,
                ),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon),
            color: Colors.white,
            iconSize: 28,
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _buildConnectionQualityBadge() {
    // Show viewer's own connection quality to host
    if (_mainStreamPeerId == null) {
      return const SizedBox.shrink();
    }

    final stats = _webrtcService.getConnectionStats(
      widget.roomId,
      _mainStreamPeerId!,
    );

    if (stats == null || !_webrtcService.isMonitoringActive) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _showMyConnectionStats(),
      child: ConnectionQualityIndicator(
        quality: stats.quality,
        roomStats: null,
        showDetails: false,
      ),
    );
  }

  void _startNotificationCheck() {
    _notificationCheckTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _checkQualityNotifications(),
    );
  }

  void _checkQualityNotifications() {
    if (_qualityNotifier == null || !mounted) return;

    // Show warnings
    final warnings = _qualityNotifier!.consumeWarnings();
    for (final warning in warnings) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(warning.icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      warning.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      warning.message,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: warning.backgroundColor,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // Show improvements
    final improvements = _qualityNotifier!.consumeImprovements();
    for (final improvement in improvements) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  improvement.message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showMyConnectionStats() {
    if (_mainStreamPeerId == null) return;

    final stats = _webrtcService.getConnectionStats(
      widget.roomId,
      _mainStreamPeerId!,
    );
    final roomStats = _webrtcService.getRoomStats(widget.roomId);

    if (stats == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Deine Verbindungsqualität',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ConnectionQualityIndicator(
                  quality: stats.quality,
                  roomStats: null,
                  showDetails: false,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    stats.quality.toString().split('.').last.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 12),
            _buildStatRow('RTT', '${stats.rttMs} ms'),
            _buildStatRow(
              'Packet Loss',
              '${stats.packetLoss.toStringAsFixed(2)}%',
            ),
            _buildStatRow('Jitter', '${stats.jitterMs} ms'),
            _buildStatRow(
              'Bandwidth',
              '${stats.estimatedBandwidthMbps.toStringAsFixed(2)} Mbps',
            ),
            if (roomStats != null) ...[
              const SizedBox(height: 12),
              const Divider(color: Colors.white24),
              const SizedBox(height: 12),
              Text(
                'Room Stats',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildStatRow('Participants', '${roomStats.participantCount}'),
              _buildStatRow('Avg RTT', '${roomStats.averageRttMs} ms'),
              _buildStatRow(
                'Total Bandwidth',
                '${roomStats.totalBandwidthMbps.toStringAsFixed(2)} Mbps',
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Schließen',
              style: TextStyle(color: Color(0xFF8B5CF6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsGrid() {
    final remoteRenderers = _webrtcService.remoteRenderers;
    final localRenderer = _webrtcService.localRenderer;

    // Nur andere Teilnehmer zeigen (nicht den main stream)
    final otherParticipants = remoteRenderers.entries
        .where((entry) => entry.key != _mainStreamPeerId)
        .toList();

    // Eigene Kamera hinzufügen (falls aktiviert)
    final showLocalCamera =
        _webrtcService.isCameraEnabled && localRenderer != null;

    if (otherParticipants.isEmpty && !showLocalCamera) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 100,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Eigene Kamera (falls an) ODER Energy-Symbol (falls aus)
          if (showLocalCamera)
            _buildThumbnail(
              renderer: localRenderer,
              label: 'Du',
              isMirror: true,
            )
          else if (_currentUserId != null)
            // Energy-Symbol als Thumbnail wenn Kamera AUS
            _buildEnergySymbolThumbnail(userId: _currentUserId!, label: 'Du'),

          // Andere Teilnehmer
          ...otherParticipants.map((entry) {
            final peerId = entry.key;

            // Get participant info for username display
            String displayName = peerId;
            final room = _webrtcService.getRoom(widget.chatRoomId);
            final participant = room?.participants[peerId];
            if (participant != null && participant.username.isNotEmpty) {
              displayName = participant.username;
            }

            return _buildThumbnail(
              renderer: entry.value,
              label: displayName,
              isMirror: false,
              onTap: () {
                // Zum Hauptstream wechseln
                setState(() {
                  _mainStreamPeerId = peerId;
                });
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEnergySymbolThumbnail({
    required String userId,
    required String label,
  }) {
    return Container(
      width: 100,
      height: 150,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFD700), // Gold für Energy-Symbol
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EnergySymbolAvatar(userId: userId, size: 60, showName: false),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail({
    required RTCVideoRenderer renderer,
    required String label,
    required bool isMirror,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 150,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF8B5CF6), width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            RTCVideoView(
              renderer,
              mirror: isMirror,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
            Positioned(
              bottom: 4,
              left: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
