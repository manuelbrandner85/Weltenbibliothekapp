import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import '../services/webrtc_broadcast_service.dart';
import '../services/live_room_service.dart';
import '../services/auth_service.dart';
import '../providers/live_stream_pip_provider.dart';
import '../widgets/chat_background_carousel.dart';
import '../services/image_asset_service.dart';
import '../widgets/connection_quality_indicator.dart';
import '../models/room_connection_state.dart';
import '../services/connection_quality_notifier.dart';
import 'dart:async';

/// ═══════════════════════════════════════════════════════════════
/// LIVE STREAM HOST SCREEN - Weltenbibliothek
/// ═══════════════════════════════════════════════════════════════
/// Host-Ansicht für Live-Streaming
/// - Kamera startet AUTOMATISCH in Vollbild
/// - Zeigt alle Viewer mit ihren Kameras (falls aktiviert)
/// - Kamera/Mikrofon Kontrollen
/// - Stream beenden
/// ═══════════════════════════════════════════════════════════════

class LiveStreamHostScreen extends StatefulWidget {
  final String roomId;
  final String chatRoomId;
  final String roomTitle;

  const LiveStreamHostScreen({
    super.key,
    required this.roomId,
    required this.chatRoomId,
    required this.roomTitle,
  });

  @override
  State<LiveStreamHostScreen> createState() => _LiveStreamHostScreenState();
}

class _LiveStreamHostScreenState extends State<LiveStreamHostScreen> {
  final WebRTCBroadcastService _webrtcService = WebRTCBroadcastService();
  final LiveRoomService _liveRoomService = LiveRoomService();
  final AuthService _authService = AuthService();
  ConnectionQualityNotifier? _qualityNotifier;
  Timer? _notificationCheckTimer;

  bool _isLoading = true;
  String? _error;
  String? _currentUserId;
  String? _currentUsername;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _startBroadcast();

    // Listen to WebRTC state changes
    _webrtcService.addListener(_onWebRTCStateChanged);
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (mounted && user != null) {
      setState(() {
        _currentUserId = user['id']?.toString() ?? user['username'] as String?;
        _currentUsername = user['username'] as String?;
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

  void _onWebRTCStateChanged() {
    if (mounted) {
      setState(() {});
    }
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

  Future<void> _startBroadcast() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Join as host (Kamera AUTO-OFF mit manueller Aktivierung)
      await _webrtcService.joinAsHost(widget.roomId, widget.chatRoomId);

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
            content: Text('🎥 Live-Stream gestartet!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Fehler beim Starten: $e';
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
      webrtcService: _webrtcService,
      hostUsername: _currentUsername,
    );

    // Wait a frame for the overlay to be built, then navigate back
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  Future<void> _endBroadcast() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Live-Stream beenden?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Möchtest du den Live-Stream wirklich beenden? Alle Zuschauer werden entfernt.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Abbrechen',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Beenden'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // End stream in backend
      await _liveRoomService.endLiveRoom(widget.roomId);

      // Leave WebRTC room
      await _webrtcService.leaveRoom(widget.roomId);

      if (mounted) {
        Navigator.pop(context);
      }
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
                'Starte Live-Stream...',
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
                onPressed: _startBroadcast,
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
            // Main Camera View (Vollbild)
            _buildMainCameraView(),

            // Top Bar
            _buildTopBar(),

            // Bottom Controls
            _buildBottomControls(),

            // Viewer Grid (Klein, oben rechts)
            _buildViewerGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCameraView() {
    final localRenderer = _webrtcService.localRenderer;

    if (localRenderer == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
      );
    }

    // Wenn Kamera AUS ist, zeige Energie-Bild als VOLLBILD-HINTERGRUND
    if (!_webrtcService.isCameraEnabled && _currentUserId != null) {
      final energyImagePath = ImageAssetService.getEnergySymbolForUser(
        _currentUserId!,
      );

      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(energyImagePath),
            fit: BoxFit.cover,
            opacity: 0.8, // Leicht transparent für bessere Lesbarkeit
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.3),
              Colors.black.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Username mit Schatten
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _currentUsername ?? 'Host',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Kamera-Status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white30, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.videocam_off, color: Colors.white, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Kamera ausgeschaltet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox.expand(
      child: RTCVideoView(
        localRenderer,
        mirror: true,
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
                // LIVE Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Viewer Count
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        '${_webrtcService.remoteUserCount + 1}', // +1 for host
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Connection Quality Badge
                _buildConnectionQualityBadge(),
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
                  onPressed: _endBroadcast,
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

                // Camera Toggle
                _buildControlButton(
                  icon: _webrtcService.isCameraEnabled
                      ? Icons.videocam
                      : Icons.videocam_off,
                  label: 'Kamera',
                  isActive: _webrtcService.isCameraEnabled,
                  onPressed: () async {
                    // Show loading indicator while toggling
                    await _webrtcService.toggleCamera();
                  },
                ),

                // Switch Camera (IMMER sichtbar, auch wenn Kamera aus)
                _buildControlButton(
                  icon: _webrtcService.isSwitchingCamera
                      ? Icons.hourglass_empty
                      : Icons.cameraswitch,
                  label: _webrtcService.isSwitchingCamera
                      ? 'Drehe...'
                      : 'Drehen',
                  isActive: _webrtcService.isCameraEnabled,
                  onPressed: _webrtcService.isSwitchingCamera
                      ? () {}
                      : () async {
                          if (!_webrtcService.isCameraEnabled) {
                            // Erst Kamera einschalten, dann drehen
                            await _webrtcService.toggleCamera();
                            await Future.delayed(
                              const Duration(milliseconds: 500),
                            );
                          }
                          await _webrtcService.switchCamera();
                        },
                ),

                // End Stream
                _buildControlButton(
                  icon: Icons.call_end,
                  label: 'Beenden',
                  isActive: false,
                  color: Colors.red,
                  onPressed: _endBroadcast,
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
    final roomStats = _webrtcService.getRoomStats(widget.roomId);

    if (roomStats == null || !_webrtcService.isMonitoringActive) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _showConnectionStatsDialog(),
      child: ConnectionQualityIndicator(
        quality: roomStats.averageQuality,
        roomStats: roomStats,
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

  void _showConnectionStatsDialog() {
    final roomStats = _webrtcService.getRoomStats(widget.roomId);

    if (roomStats == null) return;

    // Get per-peer stats
    final peerStats = <String, ConnectionStats>{};
    final roomConnection = _webrtcService.activeRooms[widget.roomId];

    if (roomConnection != null) {
      for (final peerId in roomConnection.peerConnections.keys) {
        final stats = _webrtcService.getConnectionStats(widget.roomId, peerId);
        if (stats != null) {
          peerStats[peerId] = stats;
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) =>
          ConnectionStatsDialog(roomStats: roomStats, peerStats: peerStats),
    );
  }

  Widget _buildViewerGrid() {
    final remoteRenderers = _webrtcService.remoteRenderers;

    if (remoteRenderers.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get current room to access participant info
    final currentRoomId = _webrtcService.currentRoomId;

    return Positioned(
      top: 100,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: remoteRenderers.entries.map((entry) {
          final peerId = entry.key;
          final renderer = entry.value;

          // Get participant info for username
          String displayName = peerId;
          if (currentRoomId != null) {
            final room = _webrtcService.getRoom(currentRoomId);
            final participant = room?.participants[peerId];
            if (participant != null && participant.username.isNotEmpty) {
              displayName = participant.username;
            }
          }

          return Container(
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
                  mirror: false,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
                // Username Label
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
