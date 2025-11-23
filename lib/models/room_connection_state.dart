import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// ═══════════════════════════════════════════════════════════════
/// ROOM CONNECTION STATE - Weltenbibliothek WebRTC
/// ═══════════════════════════════════════════════════════════════
/// Models für Multi-Room WebRTC State Management
/// Basierend auf Best Practices aus Recherche (2024/2025)
/// ═══════════════════════════════════════════════════════════════

/// Connection Quality basierend auf Netzwerk-Metriken
enum ConnectionQuality {
  excellent, // < 100ms RTT, < 1% packet loss
  good, // < 200ms RTT, < 3% packet loss
  poor, // < 500ms RTT, < 10% packet loss
  critical, // > 500ms RTT or > 10% packet loss
  unknown, // Noch keine Daten verfügbar
}

/// WebRTC Role (Host vs Viewer)
enum WebRTCRole {
  host, // Stream-Host (startet Stream)
  viewer, // Zuschauer (joined Stream)
}

/// Ice Connection State (simplified)
enum IceConnectionState { disconnected, connecting, connected, failed, closed }

/// ═══════════════════════════════════════════════════════════════
/// ROOM CONNECTION - Isolierte Connection-Daten pro Raum
/// ═══════════════════════════════════════════════════════════════

class RoomConnection {
  /// Eindeutige Room-ID (vom Backend)
  final String roomId;

  /// Chat-Room-ID (welcher Chat-Raum)
  final String chatRoomId;

  /// WebSocket für Signaling
  final WebSocketChannel signalingChannel;

  /// Peer Connections (peerId -> RTCPeerConnection)
  final Map<String, RTCPeerConnection> peerConnections;

  /// Remote Media Streams (peerId -> MediaStream)
  final Map<String, MediaStream> remoteStreams;

  /// Video Renderer für Remote Streams (peerId -> Renderer)
  final Map<String, RTCVideoRenderer> remoteRenderers;

  /// Buffered ICE Candidates (peerId -> List<Candidate>)
  final Map<String, List<RTCIceCandidate>> pendingCandidates;

  /// Participant Info (peerId -> PeerInfo)
  final Map<String, PeerInfo> participants;

  /// Rolle in diesem Raum
  final WebRTCRole role;

  /// Zeitpunkt des Beitritts
  final DateTime joinedAt;

  /// Aktuelle Connection Quality
  ConnectionQuality quality;

  /// Ice Connection State
  IceConnectionState iceState;

  /// Ist dieser Raum aktiv?
  bool isActive;

  RoomConnection({
    required this.roomId,
    required this.chatRoomId,
    required this.signalingChannel,
    required this.role,
    DateTime? joinedAt,
    this.quality = ConnectionQuality.unknown,
    this.iceState = IceConnectionState.disconnected,
    this.isActive = true,
  }) : peerConnections = {},
       remoteStreams = {},
       remoteRenderers = {},
       pendingCandidates = {},
       participants = {},
       joinedAt = joinedAt ?? DateTime.now();

  /// Anzahl der verbundenen Peers
  int get peerCount => peerConnections.length;

  /// Anzahl der Teilnehmer mit Video
  int get videoParticipants =>
      participants.values.where((p) => p.hasVideo).length;

  /// Ist mindestens ein Peer verbunden?
  bool get hasConnectedPeers => peerConnections.isNotEmpty;

  /// Quality als Text
  String get qualityText {
    switch (quality) {
      case ConnectionQuality.excellent:
        return 'Ausgezeichnet';
      case ConnectionQuality.good:
        return 'Gut';
      case ConnectionQuality.poor:
        return 'Schwach';
      case ConnectionQuality.critical:
        return 'Kritisch';
      case ConnectionQuality.unknown:
        return 'Unbekannt';
    }
  }

  /// Cleanup aller Ressourcen
  Future<void> dispose() async {
    // Close all peer connections
    for (final pc in peerConnections.values) {
      pc.close();
    }
    peerConnections.clear();

    // Dispose all renderers
    for (final renderer in remoteRenderers.values) {
      await renderer.dispose();
    }
    remoteRenderers.clear();

    // Close WebSocket
    await signalingChannel.sink.close();

    // Clear collections
    remoteStreams.clear();
    pendingCandidates.clear();
    participants.clear();

    isActive = false;
  }
}

/// ═══════════════════════════════════════════════════════════════
/// PEER INFO - Informationen über einzelne Peers
/// ═══════════════════════════════════════════════════════════════

class PeerInfo {
  /// Eindeutige Peer-ID
  final String peerId;

  /// Username
  final String username;

  /// User-ID (optional)
  final String? userId;

  /// Hat Video aktiviert?
  bool hasVideo;

  /// Hat Audio aktiviert?
  bool hasAudio;

  /// Connection Quality zu diesem Peer
  ConnectionQuality connectionQuality;

  /// Zeitpunkt des Joins
  final DateTime joinedAt;

  /// Letztes Update
  DateTime lastUpdate;

  PeerInfo({
    required this.peerId,
    required this.username,
    this.userId,
    this.hasVideo = false,
    this.hasAudio = true,
    this.connectionQuality = ConnectionQuality.unknown,
    DateTime? joinedAt,
    DateTime? lastUpdate,
  }) : joinedAt = joinedAt ?? DateTime.now(),
       lastUpdate = lastUpdate ?? DateTime.now();

  /// Update peer info
  void update({
    bool? hasVideo,
    bool? hasAudio,
    ConnectionQuality? connectionQuality,
  }) {
    if (hasVideo != null) this.hasVideo = hasVideo;
    if (hasAudio != null) this.hasAudio = hasAudio;
    if (connectionQuality != null) this.connectionQuality = connectionQuality;
    lastUpdate = DateTime.now();
  }

  /// Duration seit Join
  Duration get duration => DateTime.now().difference(joinedAt);

  /// JSON Serialization
  Map<String, dynamic> toJson() => {
    'peerId': peerId,
    'username': username,
    'userId': userId,
    'hasVideo': hasVideo,
    'hasAudio': hasAudio,
    'connectionQuality': connectionQuality.toString(),
    'joinedAt': joinedAt.toIso8601String(),
  };
}

/// ═══════════════════════════════════════════════════════════════
/// ROOM STATS - Statistiken pro Raum
/// ═══════════════════════════════════════════════════════════════

class RoomStats {
  /// Room ID
  final String roomId;

  /// Anzahl Teilnehmer
  final int participantCount;

  /// Upload Bandwidth (Mbps)
  final double uploadBandwidthMbps;

  /// Download Bandwidth (Mbps)
  final double downloadBandwidthMbps;

  /// Average Round-Trip-Time (ms)
  final int averageRttMs;

  /// Packet Loss (%)
  final double packetLossPercent;

  /// Average Packet Loss (alias for BandwidthMonitor compatibility)
  double get averagePacketLoss => packetLossPercent;

  /// Gesamte Connection Quality
  final ConnectionQuality quality;

  /// Average Quality (alias for BandwidthMonitor compatibility)
  ConnectionQuality get averageQuality => quality;

  /// Connection stats per peer (for BandwidthMonitor compatibility)
  final Map<String, ConnectionStats> connectionStats;

  /// Letztes Update
  final DateTime lastUpdated;

  /// Dauer der Session
  final Duration sessionDuration;

  RoomStats({
    required this.roomId,
    required this.participantCount,
    required this.uploadBandwidthMbps,
    required this.downloadBandwidthMbps,
    required this.averageRttMs,
    required this.packetLossPercent,
    required this.quality,
    Map<String, ConnectionStats>? connectionStats,
    DateTime? lastUpdated,
    Duration? sessionDuration,
  }) : connectionStats = connectionStats ?? {},
       lastUpdated = lastUpdated ?? DateTime.now(),
       sessionDuration = sessionDuration ?? Duration.zero;

  /// Ist die Verbindung gut genug?
  bool get isHealthy =>
      quality == ConnectionQuality.excellent ||
      quality == ConnectionQuality.good;

  /// Sollte eine Warnung angezeigt werden?
  bool get shouldWarn =>
      quality == ConnectionQuality.poor ||
      quality == ConnectionQuality.critical;

  /// Gesamte Bandwidth (Mbps)
  double get totalBandwidthMbps => uploadBandwidthMbps + downloadBandwidthMbps;

  /// Quality als Color Code (für UI)
  String get qualityColorHex {
    switch (quality) {
      case ConnectionQuality.excellent:
        return '#4CAF50'; // Green
      case ConnectionQuality.good:
        return '#8BC34A'; // Light Green
      case ConnectionQuality.poor:
        return '#FF9800'; // Orange
      case ConnectionQuality.critical:
        return '#F44336'; // Red
      case ConnectionQuality.unknown:
        return '#9E9E9E'; // Grey
    }
  }

  /// JSON Serialization
  Map<String, dynamic> toJson() => {
    'roomId': roomId,
    'participantCount': participantCount,
    'uploadBandwidthMbps': uploadBandwidthMbps,
    'downloadBandwidthMbps': downloadBandwidthMbps,
    'averageRttMs': averageRttMs,
    'packetLossPercent': packetLossPercent,
    'quality': quality.toString(),
    'lastUpdated': lastUpdated.toIso8601String(),
    'sessionDuration': sessionDuration.inSeconds,
  };

  @override
  String toString() =>
      'RoomStats($roomId: ${participantCount}p, ${quality.toString()}, '
      '↑${uploadBandwidthMbps.toStringAsFixed(1)}Mbps '
      '↓${downloadBandwidthMbps.toStringAsFixed(1)}Mbps, '
      'RTT:${averageRttMs}ms, Loss:${packetLossPercent.toStringAsFixed(1)}%)';
}

/// ═══════════════════════════════════════════════════════════════
/// CONNECTION STATS - Detaillierte Stats pro Peer Connection
/// ═══════════════════════════════════════════════════════════════

class ConnectionStats {
  /// Peer ID
  final String peerId;

  /// Round-Trip-Time (ms)
  final int rttMs;

  /// Packet Loss (%)
  final double packetLoss;

  /// Jitter (ms)
  final int jitterMs;

  /// Packets Lost
  final int packetsLost;

  /// Packets Received
  final int packetsReceived;

  /// Bytes sent (total)
  final int bytesSent;

  /// Bytes received (total)
  final int bytesReceived;

  /// Timestamp
  final DateTime timestamp;

  ConnectionStats({
    required this.peerId,
    required this.rttMs,
    required this.packetLoss,
    required this.jitterMs,
    this.packetsLost = 0,
    this.packetsReceived = 0,
    required this.bytesSent,
    required this.bytesReceived,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Calculate connection quality
  ConnectionQuality get quality {
    if (rttMs < 100 && packetLoss < 1.0) {
      return ConnectionQuality.excellent;
    } else if (rttMs < 200 && packetLoss < 3.0) {
      return ConnectionQuality.good;
    } else if (rttMs < 500 && packetLoss < 10.0) {
      return ConnectionQuality.poor;
    } else {
      return ConnectionQuality.critical;
    }
  }

  /// Bandwidth (rough estimate based on bytes)
  double get estimatedBandwidthMbps {
    // Very rough estimate: bytes per second to Mbps
    // This should be calculated with time delta in real implementation
    return (bytesReceived / 1024 / 1024 * 8); // Convert to Mbps
  }

  @override
  String toString() =>
      'ConnectionStats($peerId: RTT ${rttMs}ms, Loss ${packetLoss.toStringAsFixed(1)}%, '
      'Jitter ${jitterMs}ms, Quality: ${quality.toString()})';
}

/// ═══════════════════════════════════════════════════════════════
/// ROOM INFO - High-level Room Information
/// ═══════════════════════════════════════════════════════════════

class RoomInfo {
  /// Live Room ID
  final String roomId;

  /// Chat Room ID
  final String chatRoomId;

  /// Room Title (optional)
  final String? title;

  /// Host Username (optional)
  final String? hostUsername;

  /// Anzahl Teilnehmer
  final int participantCount;

  /// User's Role in diesem Raum
  final WebRTCRole role;

  /// Connection Quality
  final ConnectionQuality quality;

  /// ICE Connection State
  final IceConnectionState iceState;

  /// Is Active?
  final bool isActive;

  /// Joined At
  final DateTime joinedAt;

  RoomInfo({
    required this.roomId,
    required this.chatRoomId,
    this.title,
    this.hostUsername,
    required this.participantCount,
    required this.role,
    required this.quality,
    required this.iceState,
    required this.isActive,
    required this.joinedAt,
  });

  /// Duration in room
  Duration get duration => DateTime.now().difference(joinedAt);

  /// Is this user the host?
  bool get isHost => role == WebRTCRole.host;

  /// Is this user a viewer?
  bool get isViewer => role == WebRTCRole.viewer;

  @override
  String toString() =>
      'RoomInfo($roomId: $title, ${role.toString()}, '
      '${participantCount}p, ${quality.toString()})';
}
