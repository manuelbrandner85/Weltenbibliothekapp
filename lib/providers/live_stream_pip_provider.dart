import 'package:flutter/material.dart';
import '../services/webrtc_broadcast_service.dart';

/// ═══════════════════════════════════════════════════════════════
/// LIVE STREAM PiP PROVIDER
/// ═══════════════════════════════════════════════════════════════
/// Manages Picture-in-Picture state for live streams
/// Allows users to navigate the app while staying in live stream
/// ═══════════════════════════════════════════════════════════════

class LiveStreamPiPProvider extends ChangeNotifier {
  // PiP State
  bool _isPiPActive = false;
  String? _roomId;
  String? _chatRoomId;
  String? _roomTitle;
  String? _hostUsername;
  WebRTCBroadcastService? _webrtcService;

  // Getters
  bool get isPiPActive => _isPiPActive;
  String? get roomId => _roomId;
  String? get chatRoomId => _chatRoomId;
  String? get roomTitle => _roomTitle;
  String? get hostUsername => _hostUsername;
  WebRTCBroadcastService? get webrtcService => _webrtcService;

  /// Enable PiP mode
  void enablePiP({
    required String roomId,
    required String chatRoomId,
    required String roomTitle,
    required WebRTCBroadcastService webrtcService,
    String? hostUsername,
  }) {
    _isPiPActive = true;
    _roomId = roomId;
    _chatRoomId = chatRoomId;
    _roomTitle = roomTitle;
    _hostUsername = hostUsername;
    _webrtcService = webrtcService;
    notifyListeners();
  }

  /// Disable PiP mode (close overlay)
  void disablePiP() {
    _isPiPActive = false;
    _roomId = null;
    _chatRoomId = null;
    _roomTitle = null;
    _hostUsername = null;
    // Don't dispose webrtcService - it's managed by the screen
    _webrtcService = null;
    notifyListeners();
  }

  /// End stream completely (leave room and close PiP)
  Future<void> endStream() async {
    if (_webrtcService != null && _roomId != null) {
      await _webrtcService!.leaveRoom(_roomId!);
    }
    disablePiP();
  }
}
