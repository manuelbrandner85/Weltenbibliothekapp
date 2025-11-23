import 'dart:async';
import 'package:flutter/material.dart';
import '../services/live_room_service.dart';
import '../services/auth_service.dart';
import '../screens/live_stream_viewer_screen.dart';

/// 🔴 LIVE-BANNER für aktive Livestreams im Chat-Raum
/// Zeigt dünne farbige Leiste mit Live-Thema an, klickbar zum Beitreten
class TelegramLiveBanner extends StatefulWidget {
  final String roomId;
  final String roomName;

  const TelegramLiveBanner({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  State<TelegramLiveBanner> createState() => _TelegramLiveBannerState();
}

class _TelegramLiveBannerState extends State<TelegramLiveBanner> {
  final LiveRoomService _liveRoomService = LiveRoomService();
  final AuthService _authService = AuthService();

  LiveRoom? _activeLiveRoom;
  String? _currentUsername;
  bool _isLoading = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _checkActiveLiveRoom();
    _loadCurrentUser();

    // Poll alle 3 Sekunden für Live-Raum-Updates
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkActiveLiveRoom();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (mounted && user != null) {
        setState(() {
          _currentUsername = user['username'] as String?;
        });
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _checkActiveLiveRoom() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final liveRooms = await _liveRoomService.getActiveLiveRooms();

      // ═══════════════════════════════════════════════════════════════
      // CRITICAL FIX: Filter by chatRoomId (not roomId/liveRoomId)
      // widget.roomId = Chat Room ID (e.g., "allgemeiner_chat")
      // room.chatRoomId = Chat Room ID stored in live_rooms table
      // ═══════════════════════════════════════════════════════════════
      final activeLiveRoom = liveRooms.cast<LiveRoom?>().firstWhere(
        (room) => room?.chatRoomId == widget.roomId && room?.isLive == true,
        orElse: () => null,
      );

      if (mounted) {
        setState(() {
          _activeLiveRoom = activeLiveRoom;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show banner if no active live room
    if (_activeLiveRoom == null || !_activeLiveRoom!.isLive) {
      return const SizedBox.shrink();
    }

    // Don't show banner if current user is the host
    if (_currentUsername != null &&
        _activeLiveRoom!.hostUsername == _currentUsername) {
      return const SizedBox.shrink();
    }

    return _buildLiveBanner(context);
  }

  Widget _buildLiveBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => _joinLivestream(context),
      child: Container(
        width: double.infinity,
        height: 48, // Dünnere Leiste
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFDC2626), // Rot für LIVE
              Color(0xFFB91C1C),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // LIVE Indicator (pulsing)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),

            // LIVE Text
            const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(width: 12),

            // Stream Title
            Expanded(
              child: Text(
                _activeLiveRoom?.title ?? 'Live: ${widget.roomName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Participant Count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${_activeLiveRoom?.participantCount ?? 0}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Join Arrow
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  /// Livestream beitreten als Viewer
  void _joinLivestream(BuildContext context) async {
    if (_currentUsername == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Bitte zuerst einloggen'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_activeLiveRoom == null) return;

    try {
      // Navigate to viewer screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LiveStreamViewerScreen(
            roomId: _activeLiveRoom!.roomId,
            chatRoomId: widget.roomId,
            roomTitle: widget.roomName,
            hostUsername: _activeLiveRoom!.hostUsername,
          ),
        ),
      ).then((_) {
        // Refresh when returning
        _checkActiveLiveRoom();
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
