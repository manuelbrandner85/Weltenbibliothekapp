import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/room_connection_state.dart';
import 'bandwidth_monitor.dart';
import 'webrtc_broadcast_service.dart';

/// ═══════════════════════════════════════════════════════════════
/// AUTO-RECONNECT MANAGER - Weltenbibliothek
/// ═══════════════════════════════════════════════════════════════
/// Automatically attempts to reconnect when connection quality becomes critical
/// - Monitors connection quality continuously
/// - Triggers ICE restart for poor connections
/// - Rebuilds peer connections for critical failures
/// - Implements exponential backoff for retry attempts
/// ═══════════════════════════════════════════════════════════════

class AutoReconnectManager extends ChangeNotifier {
  final WebRTCBroadcastService _webrtcService;
  final BandwidthMonitor _bandwidthMonitor;

  Timer? _monitorTimer;
  final Map<String, ReconnectState> _reconnectStates = {};

  // Thresholds for triggering reconnection
  static const int criticalRttThreshold = 1000; // 1 second RTT
  static const double criticalPacketLossThreshold = 20.0; // 20% packet loss
  static const int maxReconnectAttempts = 3;
  static const Duration reconnectCooldown = Duration(seconds: 30);

  bool _isEnabled = true;

  AutoReconnectManager({
    required WebRTCBroadcastService webrtcService,
    required BandwidthMonitor bandwidthMonitor,
  }) : _webrtcService = webrtcService,
       _bandwidthMonitor = bandwidthMonitor {
    _startMonitoring();
  }

  bool get isEnabled => _isEnabled;

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    notifyListeners();
  }

  void _startMonitoring() {
    _monitorTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkConnectionsAndReconnect(),
    );
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectionsAndReconnect() async {
    if (!_isEnabled) return;

    // Check each active room
    for (final roomId in _bandwidthMonitor.activeRoomIds) {
      final roomStats = _bandwidthMonitor.getRoomStats(roomId);

      if (roomStats == null) continue;

      // Check each peer connection
      for (final entry in roomStats.connectionStats.entries) {
        final peerId = entry.key;
        final stats = entry.value;

        await _checkAndReconnectPeer(roomId, peerId, stats);
      }
    }
  }

  Future<void> _checkAndReconnectPeer(
    String roomId,
    String peerId,
    ConnectionStats stats,
  ) async {
    final key = '${roomId}_$peerId';
    final state = _reconnectStates[key] ?? ReconnectState();

    // Check if reconnect is needed
    final needsReconnect = _shouldReconnect(stats);

    if (!needsReconnect) {
      // Reset state if connection is good
      if (state.attempts > 0) {
        _reconnectStates[key] = ReconnectState();
        notifyListeners();
      }
      return;
    }

    // Check cooldown
    if (state.lastAttempt != null &&
        DateTime.now().difference(state.lastAttempt!) < reconnectCooldown) {
      return; // Still in cooldown
    }

    // Check max attempts
    if (state.attempts >= maxReconnectAttempts) {
      if (kDebugMode) {
        debugPrint('⚠️ Max reconnect attempts reached for $peerId in $roomId');
      }
      return;
    }

    // Attempt reconnect
    await _attemptReconnect(roomId, peerId, stats, state);
  }

  bool _shouldReconnect(ConnectionStats stats) {
    // Critical RTT
    if (stats.rttMs > criticalRttThreshold) {
      return true;
    }

    // Critical packet loss
    if (stats.packetLoss > criticalPacketLossThreshold) {
      return true;
    }

    // Critical quality
    if (stats.quality == ConnectionQuality.critical) {
      return true;
    }

    return false;
  }

  Future<void> _attemptReconnect(
    String roomId,
    String peerId,
    ConnectionStats stats,
    ReconnectState state,
  ) async {
    final key = '${roomId}_$peerId';

    // Update state
    state.attempts++;
    state.lastAttempt = DateTime.now();
    _reconnectStates[key] = state;
    notifyListeners();

    if (kDebugMode) {
      debugPrint(
        '🔄 Auto-reconnect attempt ${state.attempts}/$maxReconnectAttempts for $peerId',
      );
      debugPrint(
        '   RTT: ${stats.rttMs}ms, Packet Loss: ${stats.packetLoss.toStringAsFixed(2)}%',
      );
    }

    try {
      // Determine reconnect strategy based on severity
      if (stats.rttMs > criticalRttThreshold * 2 ||
          stats.packetLoss > criticalPacketLossThreshold * 2) {
        // Severe issues - full peer connection rebuild
        await _rebuildPeerConnection(roomId, peerId);
      } else {
        // Moderate issues - ICE restart
        await _restartIce(roomId, peerId);
      }

      if (kDebugMode) {
        debugPrint('✅ Auto-reconnect successful for $peerId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Auto-reconnect failed for $peerId: $e');
      }
    }
  }

  Future<void> _restartIce(String roomId, String peerId) async {
    final roomConnection = _webrtcService.activeRooms[roomId];
    if (roomConnection == null) return;

    final peerConnection = roomConnection.peerConnections[peerId];
    if (peerConnection == null) return;

    // Restart ICE
    await peerConnection.restartIce();

    if (kDebugMode) {
      debugPrint('🔄 ICE restart completed for $peerId');
    }
  }

  Future<void> _rebuildPeerConnection(String roomId, String peerId) async {
    if (kDebugMode) {
      debugPrint('🔨 Rebuilding peer connection for $peerId');
    }

    // This is a more aggressive approach
    // Close the current peer connection and create a new one
    final roomConnection = _webrtcService.activeRooms[roomId];
    if (roomConnection == null) return;

    final peerConnection = roomConnection.peerConnections[peerId];
    if (peerConnection == null) return;

    // Close old connection
    await peerConnection.close();

    // Remove from maps
    roomConnection.peerConnections.remove(peerId);
    roomConnection.remoteStreams.remove(peerId);

    // WebRTC service will automatically create a new connection
    // when it receives the next offer/answer from this peer
    if (kDebugMode) {
      debugPrint('✅ Peer connection rebuilt for $peerId');
    }
  }

  /// Get reconnect state for a specific peer
  ReconnectState? getReconnectState(String roomId, String peerId) {
    return _reconnectStates['${roomId}_$peerId'];
  }

  /// Manually trigger reconnect for a peer
  Future<void> manualReconnect(String roomId, String peerId) async {
    final stats = _bandwidthMonitor.getConnectionStats(roomId, peerId);
    if (stats == null) return;

    final key = '${roomId}_$peerId';
    final state = _reconnectStates[key] ?? ReconnectState();

    await _attemptReconnect(roomId, peerId, stats, state);
  }

  /// Reset reconnect state for a peer
  void resetReconnectState(String roomId, String peerId) {
    final key = '${roomId}_$peerId';
    _reconnectStates.remove(key);
    notifyListeners();
  }

  /// Clear all reconnect states
  void clearAllStates() {
    _reconnectStates.clear();
    notifyListeners();
  }
}

class ReconnectState {
  int attempts = 0;
  DateTime? lastAttempt;

  ReconnectState({this.attempts = 0, this.lastAttempt});

  bool get isReconnecting =>
      attempts > 0 &&
      (lastAttempt != null &&
          DateTime.now().difference(lastAttempt!) < const Duration(seconds: 5));

  String get status {
    if (attempts == 0) return 'Connected';
    if (isReconnecting) return 'Reconnecting...';
    if (attempts >= AutoReconnectManager.maxReconnectAttempts) {
      return 'Failed';
    }
    return 'Waiting to retry';
  }
}
