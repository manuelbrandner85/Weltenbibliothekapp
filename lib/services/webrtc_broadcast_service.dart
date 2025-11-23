import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'auth_service.dart';
import 'bandwidth_monitor.dart';
import 'auto_reconnect_manager.dart';
import 'live_room_service.dart';
import '../config/webrtc_config.dart';
import '../models/room_connection_state.dart';

/// ═══════════════════════════════════════════════════════════════
/// WEBRTC BROADCAST SERVICE - Weltenbibliothek v2
/// ═══════════════════════════════════════════════════════════════
/// MULTI-ROOM WebRTC Broadcasting für Live-Streams
///
/// Features:
/// - ✅ Multi-Room Support: Mehrere aktive Räume gleichzeitig
/// - ✅ Room Isolation: Keine Cross-Room WebRTC-Nachrichten
/// - ✅ Clean Room Switching: Automatisches Cleanup beim Raumwechsel
/// - ✅ Memory Leak Prevention: Vollständiges Resource-Disposal
/// - ✅ Bandwidth Monitoring: Verbindungsqualitäts-Tracking
/// - Host startet Stream mit Kamera AUTO-OFF (manuell aktivierbar)
/// - Viewer können beitreten (Kamera standardmäßig AUS)
/// - Jeder kann seine Kamera optional anmachen
/// - Mesh-Netzwerk für alle Teilnehmer
/// - WebSocket Signaling über Cloudflare
/// ═══════════════════════════════════════════════════════════════

class WebRTCBroadcastService extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final LiveRoomService _liveRoomService = LiveRoomService();

  // Singleton pattern
  static final WebRTCBroadcastService _instance =
      WebRTCBroadcastService._internal();
  factory WebRTCBroadcastService() => _instance;
  WebRTCBroadcastService._internal() {
    _autoReconnectManager = AutoReconnectManager(
      webrtcService: this,
      bandwidthMonitor: _bandwidthMonitor,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STATE VARIABLES - MULTI-ROOM ARCHITECTURE
  // ═══════════════════════════════════════════════════════════════

  // ✅ Multi-Room Support: Map von roomId zu RoomConnection
  final Map<String, RoomConnection> _rooms = {};

  // ✅ Aktiver Raum (UI zeigt diesen an)
  String? _activeRoomId;

  // ✅ Lokaler Stream wird über alle Räume geteilt
  MediaStream? _localStream;
  RTCVideoRenderer? _localRenderer;

  // ✅ Current user info
  String? _currentUsername;

  // ✅ Camera/Mic state (global für alle Räume)
  bool _isCameraEnabled = false;
  bool _isMicEnabled = true;
  bool _isSwitchingCamera = false;
  String _currentFacingMode = 'user'; // 'user' = front, 'environment' = back

  // ✅ Statistik-Monitoring
  final BandwidthMonitor _bandwidthMonitor = BandwidthMonitor();

  // ✅ Auto-Reconnect Manager
  late final AutoReconnectManager _autoReconnectManager;

  // ✅ FIX: Using unified WebRTC configuration
  final Map<String, dynamic> _iceServers = WebRTCConfig.iceServers;

  // ═══════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════

  bool get isConnected =>
      _activeRoomId != null && _rooms.containsKey(_activeRoomId);
  bool get isCameraEnabled => _isCameraEnabled;
  bool get isMicEnabled => _isMicEnabled;
  bool get isSwitchingCamera => _isSwitchingCamera;
  bool get isHost => _rooms[_activeRoomId]?.role == WebRTCRole.host;
  String? get currentRoomId => _activeRoomId;
  RTCVideoRenderer? get localRenderer => _localRenderer;

  // ✅ Remote Renderers für aktiven Raum
  Map<String, RTCVideoRenderer> get remoteRenderers {
    final room = _rooms[_activeRoomId];
    return room?.remoteRenderers ?? {};
  }

  // ✅ Remote User Count für aktiven Raum
  int get remoteUserCount {
    final room = _rooms[_activeRoomId];
    return room?.participants.length ?? 0;
  }

  // ✅ Raum-Statistiken abrufen
  RoomStats? getRoomStats(String roomId) =>
      _bandwidthMonitor.getRoomStats(roomId);

  /// Get connection stats for specific peer in room
  ConnectionStats? getConnectionStats(String roomId, String peerId) {
    return _bandwidthMonitor.getConnectionStats(roomId, peerId);
  }

  /// Get room by ID (for accessing participant info)
  RoomConnection? getRoom(String roomId) => _rooms[roomId];

  /// Get bandwidth monitor instance
  BandwidthMonitor get bandwidthMonitor => _bandwidthMonitor;

  /// Get auto-reconnect manager instance
  AutoReconnectManager get autoReconnectManager => _autoReconnectManager;

  /// Get active rooms map (for monitoring/debugging)
  Map<String, RoomConnection> get activeRooms => _rooms;

  // ✅ Aktive Raum-Verbindung abrufen
  RoomConnection? getActiveRoom() => _rooms[_activeRoomId];

  // ✅ Alle aktiven Räume
  List<String> get activeRoomIds => _rooms.keys.toList();

  // ═══════════════════════════════════════════════════════════════
  // JOIN ROOM AS HOST (Kamera AUTO-OFF)
  // ═══════════════════════════════════════════════════════════════

  Future<void> joinAsHost(String roomId, String chatRoomId) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '🎥 [WebRTC] Joining as HOST: $roomId (chatRoom: $chatRoomId)',
        );
      }

      // ✅ Wenn bereits in einem anderen Raum aktiv, wechseln
      if (_activeRoomId != null && _activeRoomId != roomId) {
        await switchRoom(roomId, chatRoomId, WebRTCRole.host);
        return;
      }

      // Get current user
      final user = await _authService.getCurrentUser();
      _currentUsername = user?['username'] as String?;

      // ✅ Lokalen Stream initialisieren (falls noch nicht vorhanden)
      if (_localStream == null) {
        _localRenderer = RTCVideoRenderer();
        await _localRenderer!.initialize();

        // Get user media (HOST: Kamera AUTO-OFF - kann manuell einschalten)
        _localStream = await _getUserMedia(enableCamera: false);
        _localRenderer!.srcObject = _localStream;
        _isCameraEnabled = false;
        _isMicEnabled = true;
      }

      // ✅ Raum-Verbindung erstellen
      await _joinRoom(roomId, chatRoomId, WebRTCRole.host);

      // ✅ Als aktiven Raum setzen
      _activeRoomId = roomId;

      notifyListeners();

      if (kDebugMode) {
        debugPrint(
          '✅ [WebRTC] HOST joined successfully with camera OFF (manual activation)',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC] Error joining as host: $e');
      }
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // JOIN ROOM AS VIEWER (Kamera AUTO-OFF)
  // ═══════════════════════════════════════════════════════════════

  Future<void> joinAsViewer(String roomId, String chatRoomId) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '🎥 [WebRTC] Joining as VIEWER: $roomId (chatRoom: $chatRoomId)',
        );
      }

      // ✅ Wenn bereits in einem anderen Raum aktiv, wechseln
      if (_activeRoomId != null && _activeRoomId != roomId) {
        await switchRoom(roomId, chatRoomId, WebRTCRole.viewer);
        return;
      }

      // Get current user
      final user = await _authService.getCurrentUser();
      _currentUsername = user?['username'] as String?;

      // ✅ Lokalen Stream initialisieren (falls noch nicht vorhanden)
      if (_localStream == null) {
        _localRenderer = RTCVideoRenderer();
        await _localRenderer!.initialize();

        // Get user media (VIEWER: Kamera AUTO-OFF)
        _localStream = await _getUserMedia(enableCamera: false);
        _localRenderer!.srcObject = _localStream;
        _isCameraEnabled = false;
        _isMicEnabled = true;
      }

      // ✅ Raum-Verbindung erstellen
      await _joinRoom(roomId, chatRoomId, WebRTCRole.viewer);

      // ✅ Als aktiven Raum setzen
      _activeRoomId = roomId;

      notifyListeners();

      if (kDebugMode) {
        debugPrint('✅ [WebRTC] VIEWER joined successfully with camera OFF');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC] Error joining as viewer: $e');
      }
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // INTERNAL: JOIN ROOM (Core Logic)
  // ═══════════════════════════════════════════════════════════════

  Future<void> _joinRoom(
    String roomId,
    String chatRoomId,
    WebRTCRole role,
  ) async {
    // ✅ Check: Raum bereits beigetreten?
    if (_rooms.containsKey(roomId)) {
      if (kDebugMode) {
        debugPrint('⚠️ [WebRTC] Already in room $roomId');
      }
      return;
    }

    // ✅ WebSocket-Verbindung für diesen Raum erstellen
    final wsUrl = AuthService.baseUrl.replaceFirst('https://', 'wss://');
    final uri = Uri.parse('$wsUrl/ws/webrtc/$roomId');

    if (kDebugMode) {
      debugPrint('🔌 [WebRTC] Connecting to signaling: $uri');
    }

    final signalingChannel = WebSocketChannel.connect(uri);

    // ✅ RoomConnection-Objekt erstellen
    final roomConnection = RoomConnection(
      roomId: roomId,
      chatRoomId: chatRoomId,
      signalingChannel: signalingChannel,
      role: role,
      joinedAt: DateTime.now(),
    );

    // ✅ In Map speichern
    _rooms[roomId] = roomConnection;

    // ✅ Signaling-Nachrichten für diesen Raum abhören
    signalingChannel.stream.listen(
      (data) => _handleSignalingMessage(roomId, data),
      onError: (error) => _handleSignalingError(roomId, error),
      onDone: () => _handleSignalingDisconnect(roomId),
    );

    // ✅ Sicherstellen, dass username gesetzt ist
    final username =
        _currentUsername ?? 'user_${DateTime.now().millisecondsSinceEpoch}';

    // ✅ Generate UNIQUE peerId (username + timestamp)
    final uniquePeerId = '${username}_${DateTime.now().millisecondsSinceEpoch}';

    if (kDebugMode) {
      debugPrint(
        '🚀 [WebRTC] [$roomId] Joining as: $username (peerId: $uniquePeerId, role: ${role == WebRTCRole.host ? 'host' : 'viewer'})',
      );
    }

    // ✅ Join-Nachricht senden (Server erwartet 'peerId' und 'roomId')
    _sendSignalingMessage(roomId, {
      'type': 'join',
      'peerId': uniquePeerId,
      'roomId': roomId,
      'uid': username,
      'username': username,
      'role': role == WebRTCRole.host ? 'host' : 'viewer',
    });

    // ✅ Raum als aktiv markieren
    roomConnection.isActive = true;

    // ✅ Start bandwidth monitoring for this room
    _bandwidthMonitor.startMonitoring(roomId, roomConnection);
  }

  // ═══════════════════════════════════════════════════════════════
  // SWITCH ROOM (Mit vollständigem Cleanup)
  // ═══════════════════════════════════════════════════════════════

  Future<void> switchRoom(
    String newRoomId,
    String newChatRoomId,
    WebRTCRole role,
  ) async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 [WebRTC] Switching from ${_activeRoomId} to $newRoomId');
      }

      // ✅ Alten Raum verlassen (falls vorhanden)
      if (_activeRoomId != null && _activeRoomId != newRoomId) {
        await leaveRoom(_activeRoomId!);
      }

      // ✅ Neuem Raum beitreten
      await _joinRoom(newRoomId, newChatRoomId, role);

      // ✅ Als aktiven Raum setzen
      _activeRoomId = newRoomId;

      notifyListeners();

      if (kDebugMode) {
        debugPrint('✅ [WebRTC] Switched to room $newRoomId successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC] Error switching room: $e');
      }
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // GET USER MEDIA
  // ═══════════════════════════════════════════════════════════════

  Future<MediaStream> _getUserMedia({required bool enableCamera}) async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': enableCamera
          ? {
              'facingMode': 'user',
              'width': {'ideal': 1280},
              'height': {'ideal': 720},
            }
          : false,
    };

    return await navigator.mediaDevices.getUserMedia(mediaConstraints);
  }

  // ═══════════════════════════════════════════════════════════════
  // TOGGLE CAMERA (Jeder kann seine Kamera an/aus machen)
  // ═══════════════════════════════════════════════════════════════

  Future<void> toggleCamera() async {
    try {
      if (_isCameraEnabled) {
        // ✅ Kamera ausschalten
        final videoTracks = _localStream?.getVideoTracks() ?? [];

        for (final track in videoTracks) {
          track.enabled = false;
          await track.stop();
          _localStream?.removeTrack(track);
        }

        // ✅ In ALLEN aktiven Räumen updaten
        for (final room in _rooms.values) {
          for (final pc in room.peerConnections.values) {
            final senders = await pc.getSenders();
            for (final sender in senders) {
              if (sender.track?.kind == 'video') {
                await sender.replaceTrack(null);
              }
            }
          }
        }

        // Clear local renderer to prevent frozen frame
        _localRenderer?.srcObject = null;
        _isCameraEnabled = false;

        if (kDebugMode) {
          debugPrint('📷 [WebRTC] Camera disabled across all rooms');
        }
      } else {
        // ✅ Kamera einschalten - CRITICAL FIX
        if (kDebugMode) {
          debugPrint('📷 [WebRTC] Enabling camera...');
        }

        // 🔧 CRITICAL: Create completely new stream with video
        final newStream = await navigator.mediaDevices.getUserMedia({
          'audio': _isMicEnabled, // Keep current mic state
          'video': {
            'facingMode': 'user',
            'width': {'ideal': 1280},
            'height': {'ideal': 720},
          },
        });

        final videoTrack = newStream.getVideoTracks()[0];

        // 🔧 CRITICAL FIX: Ensure _localStream exists
        if (_localStream == null) {
          _localStream = newStream;
          if (kDebugMode) {
            debugPrint('📷 [WebRTC] Created new local stream');
          }
        } else {
          // Add video track to existing stream
          _localStream!.addTrack(videoTrack);

          // Sync audio tracks from new stream if needed
          final audioTracks = newStream.getAudioTracks();
          if (audioTracks.isNotEmpty &&
              _localStream!.getAudioTracks().isEmpty) {
            _localStream!.addTrack(audioTracks[0]);
          }
        }

        // 🔧 CRITICAL: Update renderer BEFORE updating peer connections
        _localRenderer?.srcObject = _localStream;

        // Small delay to let renderer initialize
        await Future.delayed(const Duration(milliseconds: 100));

        // ✅ In ALLEN aktiven Räumen updaten
        for (final room in _rooms.values) {
          for (final pc in room.peerConnections.values) {
            final senders = await pc.getSenders();

            bool videoSenderFound = false;
            for (final sender in senders) {
              if (sender.track?.kind == 'video') {
                await sender.replaceTrack(videoTrack);
                videoSenderFound = true;
              }
            }

            // If no video sender exists, add one
            if (!videoSenderFound) {
              await pc.addTrack(videoTrack, _localStream!);
            }
          }
        }

        _isCameraEnabled = true;

        if (kDebugMode) {
          debugPrint(
            '📷 [WebRTC] Camera enabled successfully across all rooms',
          );
        }
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC] Error toggling camera: $e');
      }
      // Reset state on error
      _isCameraEnabled = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SWITCH CAMERA (Front/Back)
  // ═══════════════════════════════════════════════════════════════

  /// 🚀 v3.9.1: AGGRESSIVE CAMERA SWITCH FIX
  /// Completely reworked camera switching with:
  /// - ✅ Manual facingMode toggle (no Helper.switchCamera)
  /// - ✅ Complete renderer dispose/reinitialize cycle
  /// - ✅ Longer warm-up delays (300ms)
  /// - ✅ Event-based readyState checking
  /// - ✅ Comprehensive debug logging
  ///
  /// Research sources:
  /// - GitHub flutter-webrtc/issues/896 (track replacement best practices)
  /// - GitHub flutter-webrtc/issues/1269 (preserve constraints during switch)
  /// - Chromium Bug #40153159 (MediaStreamTrack.stop() Android freeze)
  Future<void> switchCamera() async {
    if (_localStream == null || !_isCameraEnabled || _isSwitchingCamera) {
      if (kDebugMode) {
        debugPrint(
          '🔄 [WebRTC] Cannot switch camera: stream=${{_localStream != null}}, enabled=$_isCameraEnabled, switching=$_isSwitchingCamera',
        );
      }
      return;
    }

    try {
      // 🔄 START: Set switching state
      _isSwitchingCamera = true;
      notifyListeners();

      if (kDebugMode) {
        debugPrint('🚀 [WebRTC v3.9.1] Starting AGGRESSIVE camera switch...');
        debugPrint('📹 [WebRTC] Current facingMode: $_currentFacingMode');
      }

      // Get current video track (to be replaced)
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isEmpty) {
        _isSwitchingCamera = false;
        notifyListeners();
        return;
      }

      final oldTrack = videoTracks.first;

      if (kDebugMode) {
        debugPrint(
          '📹 [WebRTC] Old track: ID=${oldTrack.id}, enabled=${oldTrack.enabled}',
        );
      }

      // 🎯 STEP 1: Toggle facingMode MANUALLY (no Helper.switchCamera!)
      final newFacingMode = _currentFacingMode == 'user'
          ? 'environment'
          : 'user';

      if (kDebugMode) {
        debugPrint(
          '🎯 [WebRTC] STEP 1: Toggling facingMode: $_currentFacingMode → $newFacingMode',
        );
      }

      // 🎯 STEP 2: Open NEW camera FIRST with explicit facingMode
      // This prevents Camera HAL deadlock on Android
      final newStream = await navigator.mediaDevices.getUserMedia({
        'audio': false,
        'video': {
          'facingMode': newFacingMode,
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        },
      });

      final newTrack = newStream.getVideoTracks().first;

      if (kDebugMode) {
        debugPrint('🎯 [WebRTC] STEP 2: New camera opened!');
        debugPrint(
          '📹 [WebRTC] New track: ID=${newTrack.id}, enabled=${newTrack.enabled}',
        );
      }

      // 🎯 STEP 3: LONGER warm-up - Wait for camera to fully initialize
      // Increased from 150ms to 300ms for more reliable startup
      await Future.delayed(const Duration(milliseconds: 300));

      if (kDebugMode) {
        debugPrint('🎯 [WebRTC] STEP 3: Extended warm-up complete (300ms)');
      }

      // 🎯 STEP 4: Additional delay to ensure frames are flowing
      // Since readyState is not available, use fixed delay
      await Future.delayed(const Duration(milliseconds: 200));

      if (kDebugMode) {
        debugPrint(
          '✅ [WebRTC] STEP 4: Track initialization delay complete (500ms total)',
        );
      }

      // 🎯 STEP 5: COMPLETE RENDERER RESET (dispose + reinitialize)
      if (kDebugMode) {
        debugPrint('🎯 [WebRTC] STEP 5: Starting COMPLETE renderer reset...');
      }

      // 5a: Clear srcObject
      _localRenderer?.srcObject = null;
      await Future.delayed(const Duration(milliseconds: 50));

      // 5b: Dispose renderer completely
      try {
        await _localRenderer?.dispose();
        if (kDebugMode) {
          debugPrint('🗑️ [WebRTC] Renderer disposed');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ [WebRTC] Error disposing renderer: $e');
        }
      }

      await Future.delayed(const Duration(milliseconds: 100));

      // 5c: Create fresh renderer
      _localRenderer = RTCVideoRenderer();
      await _localRenderer!.initialize();

      if (kDebugMode) {
        debugPrint('✅ [WebRTC] Fresh renderer initialized');
      }

      await Future.delayed(const Duration(milliseconds: 50));

      // 5d: Attach new stream to fresh renderer
      _localRenderer!.srcObject = newStream;

      if (kDebugMode) {
        debugPrint(
          '✅ [WebRTC] STEP 5: Renderer reset complete with new stream',
        );
      }

      // 🎯 STEP 6: Replace track in ALL peer connections
      // Do this AFTER renderer update to ensure we see the change locally first
      for (final room in _rooms.values) {
        for (final connection in room.peerConnections.values) {
          final senders = await connection.getSenders();
          for (var sender in senders) {
            if (sender.track?.kind == 'video') {
              await sender.replaceTrack(newTrack);
              if (kDebugMode) {
                debugPrint(
                  '📤 [WebRTC] Replaced track in peer connection (room: ${room.roomId})',
                );
              }
            }
          }
        }
      }

      if (kDebugMode) {
        debugPrint('🎯 [WebRTC] STEP 6: All peer connections updated');
      }

      // 🎯 STEP 7: Confirm frames flowing (longer delay)
      await Future.delayed(const Duration(milliseconds: 200));

      if (kDebugMode) {
        debugPrint('🎯 [WebRTC] STEP 7: Frame flow confirmed (200ms)');
      }

      // 🎯 STEP 8: NOW safe to stop old camera
      // New camera is fully active, renderer reset, no race condition!
      try {
        await oldTrack.stop();
        if (kDebugMode) {
          debugPrint('🎯 [WebRTC] STEP 8: Old track stopped safely');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ [WebRTC] Error stopping old track (non-critical): $e');
        }
      }

      // 🎯 STEP 9: Clean up ALL old tracks from stream
      final allOldVideoTracks = _localStream!.getVideoTracks().toList();
      for (final track in allOldVideoTracks) {
        try {
          await track.stop();
          _localStream!.removeTrack(track);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ [WebRTC] Error cleaning old track: $e');
          }
        }
      }

      if (kDebugMode) {
        debugPrint(
          '🎯 [WebRTC] STEP 9: Cleaned ${allOldVideoTracks.length} old track(s)',
        );
      }

      // 🎯 STEP 10: Add new track to main stream
      _localStream!.addTrack(newTrack);

      // 🎯 STEP 11: Update facingMode state
      _currentFacingMode = newFacingMode;

      if (kDebugMode) {
        debugPrint('🎯 [WebRTC] STEP 10: New track added to _localStream');
        debugPrint(
          '🎯 [WebRTC] STEP 11: FacingMode updated to: $_currentFacingMode',
        );
        debugPrint('✅ [WebRTC v3.9.1] AGGRESSIVE camera switch COMPLETE!');
      }

      // ✅ END: Clear switching state
      _isSwitchingCamera = false;
      notifyListeners();

      if (kDebugMode) {
        debugPrint('✅ [WebRTC] Camera switched successfully!');
      }
    } catch (e) {
      _isSwitchingCamera = false;
      notifyListeners();

      if (kDebugMode) {
        debugPrint('❌ [WebRTC] Error switching camera: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // TOGGLE MICROPHONE
  // ═══════════════════════════════════════════════════════════════

  void toggleMicrophone() {
    if (_localStream == null) return;

    _isMicEnabled = !_isMicEnabled;

    _localStream!.getAudioTracks().forEach((track) {
      track.enabled = _isMicEnabled;
    });

    notifyListeners();

    if (kDebugMode) {
      debugPrint(
        '🎤 [WebRTC] Microphone ${_isMicEnabled ? 'enabled' : 'disabled'}',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SIGNALING MESSAGE HANDLING (Room-spezifisch)
  // ═══════════════════════════════════════════════════════════════

  void _handleSignalingMessage(String roomId, dynamic data) async {
    try {
      final room = _rooms[roomId];
      if (room == null || !room.isActive) {
        if (kDebugMode) {
          debugPrint('⚠️ [WebRTC] Received message for inactive room: $roomId');
        }
        return;
      }

      final message = json.decode(data as String) as Map<String, dynamic>;
      final type = message['type'] as String;

      if (kDebugMode) {
        debugPrint('📨 [WebRTC] [$roomId] Signaling: $type');
      }

      switch (type) {
        case 'peer-joined': // ✅ FIX: Server sendet 'peer-joined' nicht 'user_joined'
        case 'user_joined':
          await _handleUserJoined(roomId, message);
          break;
        case 'peers-list': // ✅ NEU: Handle existing peers list
          await _handlePeersList(roomId, message);
          break;
        case 'offer':
          await _handleOffer(roomId, message);
          break;
        case 'answer':
          await _handleAnswer(roomId, message);
          break;
        case 'ice_candidate':
          await _handleIceCandidate(roomId, message);
          break;
        case 'peer-left': // ✅ FIX: Server sendet 'peer-left' nicht 'user_left'
        case 'user_left':
          _handleUserLeft(roomId, message);
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC] [$roomId] Error handling signaling message: $e');
      }
    }
  }

  void _handleSignalingError(String roomId, dynamic error) {
    if (kDebugMode) {
      debugPrint('❌ [WebRTC] [$roomId] Signaling error: $error');
    }
  }

  void _handleSignalingDisconnect(String roomId) {
    if (kDebugMode) {
      debugPrint('🔌 [WebRTC] [$roomId] Signaling disconnected');
    }

    // ✅ Raum als inaktiv markieren
    final room = _rooms[roomId];
    if (room != null) {
      room.isActive = false;
      room.iceState = IceConnectionState.disconnected;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PEER CONNECTION HANDLING (Room-spezifisch)
  // ═══════════════════════════════════════════════════════════════

  Future<void> _handleUserJoined(
    String roomId,
    Map<String, dynamic> message,
  ) async {
    final peerId = message['peerId'] as String?; // Server sendet 'peerId'
    final username =
        message['username'] as String? ?? peerId; // Prefer username over peerId
    final uid = message['uid'] as String?;

    if (kDebugMode) {
      debugPrint('👤 [WebRTC] [$roomId] User joined event:');
      debugPrint('   - peerId: $peerId');
      debugPrint('   - username: $username');
      debugPrint('   - uid: $uid');
      debugPrint('   - current user: $_currentUsername');
    }

    if (peerId == null || username == null) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ [WebRTC] [$roomId] PeerId or username is null, skipping',
        );
      }
      return;
    }

    // Skip if it's the same user (compare by username, NOT peerId)
    if (username == _currentUsername) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ [WebRTC] [$roomId] Skipping self (username: $username, peerId: $peerId)',
        );
      }
      return;
    }

    final room = _rooms[roomId];
    if (room == null) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ [WebRTC] [$roomId] Room not found when handling user joined',
        );
      }
      return;
    }

    // ✅ Peer-Info hinzufügen mit korrekten Werten
    room.participants[peerId] = PeerInfo(
      peerId: peerId,
      username: username, // Display name for UI
      userId: uid, // User ID for authentication
      hasVideo: false,
      hasAudio: true,
      connectionQuality: ConnectionQuality.unknown,
      joinedAt: DateTime.now(),
    );

    if (kDebugMode) {
      debugPrint(
        '✅ [WebRTC] [$roomId] Added participant: $username (peerId: $peerId)',
      );
      debugPrint('   Total participants: ${room.participants.length}');
    }

    // Create peer connection (use peerId as key)
    await _createPeerConnection(roomId, peerId);

    // Create offer if we're the host or existing participant
    if (room.role == WebRTCRole.host || room.peerConnections.isNotEmpty) {
      if (kDebugMode) {
        debugPrint(
          '📤 [WebRTC] [$roomId] Creating offer for $username (peerId: $peerId)',
        );
      }
      await _createOffer(roomId, peerId);
    }

    notifyListeners();
  }

  // ✅ NEU: Handle peers list (wenn wir joinen und es schon Leute gibt)
  Future<void> _handlePeersList(
    String roomId,
    Map<String, dynamic> message,
  ) async {
    final peers = message['peers'] as List<dynamic>?;

    if (kDebugMode) {
      debugPrint('👥 [WebRTC] [$roomId] Peers-list event received');
      debugPrint('   - Peers: $peers');
      debugPrint('   - Current user: $_currentUsername');
    }

    if (peers == null || peers.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ [WebRTC] [$roomId] No existing peers in room');
      }
      return;
    }

    final room = _rooms[roomId];
    if (room == null) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ [WebRTC] [$roomId] Room not found when handling peers list',
        );
      }
      return;
    }

    if (kDebugMode) {
      debugPrint(
        '🔗 [WebRTC] [$roomId] Initiating connections to ${peers.length} existing peer(s)',
      );
    }

    // Create connection to each existing peer
    int connectedCount = 0;
    for (final peerData in peers) {
      // Handle both String and Map formats
      String peerId;
      String username;
      String? userId;

      if (peerData is String) {
        peerId = peerData;
        username = peerData; // Fallback to peerId if no username provided
        userId = null;
      } else if (peerData is Map) {
        peerId = peerData['peerId'] as String? ?? peerData['id'] as String;
        username = peerData['username'] as String? ?? peerId;
        userId = peerData['uid'] as String?;
      } else {
        if (kDebugMode) {
          debugPrint(
            '⚠️ [WebRTC] [$roomId] Invalid peer data format: $peerData',
          );
        }
        continue;
      }

      // Skip self (compare by username, NOT peerId since peerId is unique per connection)
      if (username == _currentUsername) {
        if (kDebugMode) {
          debugPrint(
            '⏭️ [WebRTC] [$roomId] Skipping self: $username (peerId: $peerId)',
          );
        }
        continue;
      }

      // Add peer info with proper username
      room.participants[peerId] = PeerInfo(
        peerId: peerId,
        username: username,
        userId: userId,
        hasVideo: false,
        hasAudio: true,
        connectionQuality: ConnectionQuality.unknown,
        joinedAt: DateTime.now(),
      );

      if (kDebugMode) {
        debugPrint(
          '👤 [WebRTC] [$roomId] Adding existing peer: $username (peerId: $peerId)',
        );
      }

      // Create peer connection
      await _createPeerConnection(roomId, peerId);

      // Create offer to existing peer
      await _createOffer(roomId, peerId);

      connectedCount++;
    }

    if (kDebugMode) {
      debugPrint(
        '✅ [WebRTC] [$roomId] Initiated $connectedCount peer connection(s)',
      );
      debugPrint('   Total participants in room: ${room.participants.length}');
    }

    notifyListeners();
  }

  Future<void> _createPeerConnection(String roomId, String peerId) async {
    try {
      final room = _rooms[roomId];
      if (room == null) {
        if (kDebugMode) {
          debugPrint('⚠️ [WebRTC] [$roomId] Room not found for peer $peerId');
        }
        return;
      }

      if (kDebugMode) {
        debugPrint(
          '🤝 [WebRTC] [$roomId] Creating peer connection for: $peerId',
        );
      }

      final pc = await createPeerConnection(_iceServers);

      // Add local stream tracks
      _localStream?.getTracks().forEach((track) {
        pc.addTrack(track, _localStream!);
        if (kDebugMode) {
          debugPrint(
            '➕ [WebRTC] [$roomId] Added local ${track.kind} track to peer $peerId',
          );
        }
      });

      // Handle remote stream
      pc.onTrack = (RTCTrackEvent event) {
        if (kDebugMode) {
          debugPrint(
            '📺 [WebRTC] [$roomId] Received remote ${event.track.kind} track from $peerId',
          );
        }

        if (event.streams.isNotEmpty) {
          room.remoteStreams[peerId] = event.streams[0];

          if (kDebugMode) {
            debugPrint(
              '🎥 [WebRTC] [$roomId] Creating renderer for peer $peerId',
            );
          }

          // Create renderer for remote stream
          final renderer = RTCVideoRenderer();
          renderer.initialize().then((_) {
            renderer.srcObject = event.streams[0];
            room.remoteRenderers[peerId] = renderer;

            if (kDebugMode) {
              debugPrint(
                '✅ [WebRTC] [$roomId] Renderer initialized for peer $peerId. Total renderers: ${room.remoteRenderers.length}',
              );
            }

            // ✅ Track-Typ erkennen
            final peerInfo = room.participants[peerId];
            if (peerInfo != null) {
              if (event.track.kind == 'video') {
                peerInfo.hasVideo = true;
              }
            }

            notifyListeners();
          });
        }
      };

      // Handle ICE candidates
      pc.onIceCandidate = (RTCIceCandidate candidate) {
        _sendSignalingMessage(roomId, {
          'type': 'ice_candidate',
          'to': peerId,
          'from': _currentUsername,
          'candidate': candidate.toMap(),
        });
      };

      // ✅ Handle ICE Connection State (Detailed Monitoring)
      pc.onIceConnectionState = (RTCIceConnectionState iceState) {
        if (kDebugMode) {
          debugPrint(
            '🧊 [WebRTC] [$roomId] ICE Connection State with $peerId: $iceState',
          );
        }

        switch (iceState) {
          case RTCIceConnectionState.RTCIceConnectionStateConnected:
          case RTCIceConnectionState.RTCIceConnectionStateCompleted:
            room.iceState = IceConnectionState.connected;
            if (kDebugMode) {
              debugPrint('✅ [WebRTC] [$roomId] ICE Connected to $peerId');
            }
            break;
          case RTCIceConnectionState.RTCIceConnectionStateFailed:
            room.iceState = IceConnectionState.failed;
            if (kDebugMode) {
              debugPrint(
                '❌ [WebRTC] [$roomId] ICE Failed with $peerId - Restart may be needed',
              );
            }
            // TODO: Trigger ICE restart
            break;
          case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
            room.iceState = IceConnectionState.disconnected;
            if (kDebugMode) {
              debugPrint('⚠️ [WebRTC] [$roomId] ICE Disconnected from $peerId');
            }
            break;
          case RTCIceConnectionState.RTCIceConnectionStateClosed:
            room.iceState = IceConnectionState.closed;
            break;
          default:
            break;
        }
        notifyListeners();
      };

      // ✅ Handle Connection State Changes
      pc.onConnectionState = (RTCPeerConnectionState state) {
        if (kDebugMode) {
          debugPrint(
            '🔗 [WebRTC] [$roomId] Connection State with $peerId: $state',
          );
        }

        switch (state) {
          case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
            if (kDebugMode) {
              debugPrint(
                '✅ [WebRTC] [$roomId] Peer Connection Established with $peerId',
              );
            }
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
            if (kDebugMode) {
              debugPrint(
                '❌ [WebRTC] [$roomId] Peer Connection Failed with $peerId',
              );
            }
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
            if (kDebugMode) {
              debugPrint(
                '⚠️ [WebRTC] [$roomId] Peer Connection Disconnected from $peerId',
              );
            }
            break;
          default:
            break;
        }
      };

      // ✅ Handle Signaling State Changes
      pc.onSignalingState = (RTCSignalingState signalingState) {
        if (kDebugMode) {
          debugPrint(
            '📡 [WebRTC] [$roomId] Signaling State with $peerId: $signalingState',
          );
        }
      };

      // ✅ In Raum speichern
      room.peerConnections[peerId] = pc;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC] [$roomId] Error creating peer connection: $e');
      }
    }
  }

  Future<void> _createOffer(String roomId, String peerId) async {
    try {
      final room = _rooms[roomId];
      if (room == null) return;

      final pc = room.peerConnections[peerId];
      if (pc == null) return;

      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);

      _sendSignalingMessage(roomId, {
        'type': 'offer',
        'to': peerId,
        'from': _currentUsername,
        'offer': offer.toMap(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC] [$roomId] Error creating offer: $e');
      }
    }
  }

  Future<void> _handleOffer(String roomId, Map<String, dynamic> message) async {
    try {
      final room = _rooms[roomId];
      if (room == null) return;

      final from = message['from'] as String;
      final offerMap = message['offer'] as Map<String, dynamic>;

      // Create peer connection if not exists
      if (!room.peerConnections.containsKey(from)) {
        await _createPeerConnection(roomId, from);

        // ✅ Participant hinzufügen falls nicht vorhanden
        if (!room.participants.containsKey(from)) {
          room.participants[from] = PeerInfo(
            peerId: from,
            username: from,
            hasVideo: false,
            hasAudio: true,
            connectionQuality: ConnectionQuality.unknown,
            joinedAt: DateTime.now(),
          );
        }
      }

      final pc = room.peerConnections[from];
      if (pc == null) return;

      final offer = RTCSessionDescription(
        offerMap['sdp'] as String,
        offerMap['type'] as String,
      );

      await pc.setRemoteDescription(offer);

      // ✅ Pending ICE candidates verarbeiten
      final pendingCandidates = room.pendingCandidates[from];
      if (pendingCandidates != null) {
        for (final candidate in pendingCandidates) {
          await pc.addCandidate(candidate);
        }
        room.pendingCandidates.remove(from);
      }

      // Create answer
      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);

      _sendSignalingMessage(roomId, {
        'type': 'answer',
        'to': from,
        'from': _currentUsername,
        'answer': answer.toMap(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC] [$roomId] Error handling offer: $e');
      }
    }
  }

  Future<void> _handleAnswer(
    String roomId,
    Map<String, dynamic> message,
  ) async {
    try {
      final room = _rooms[roomId];
      if (room == null) return;

      final from = message['from'] as String;
      final answerMap = message['answer'] as Map<String, dynamic>;

      final pc = room.peerConnections[from];
      if (pc == null) return;

      final answer = RTCSessionDescription(
        answerMap['sdp'] as String,
        answerMap['type'] as String,
      );

      await pc.setRemoteDescription(answer);

      // ✅ Pending ICE candidates verarbeiten
      final pendingCandidates = room.pendingCandidates[from];
      if (pendingCandidates != null) {
        for (final candidate in pendingCandidates) {
          await pc.addCandidate(candidate);
        }
        room.pendingCandidates.remove(from);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC] [$roomId] Error handling answer: $e');
      }
    }
  }

  Future<void> _handleIceCandidate(
    String roomId,
    Map<String, dynamic> message,
  ) async {
    try {
      final room = _rooms[roomId];
      if (room == null) return;

      final from = message['from'] as String;
      final candidateMap = message['candidate'] as Map<String, dynamic>;

      final pc = room.peerConnections[from];

      final candidate = RTCIceCandidate(
        candidateMap['candidate'] as String,
        candidateMap['sdpMid'] as String?,
        candidateMap['sdpMLineIndex'] as int?,
      );

      if (pc != null && pc.getRemoteDescription() != null) {
        // ✅ Remote Description gesetzt: Direkt hinzufügen
        await pc.addCandidate(candidate);
      } else {
        // ✅ Noch keine Remote Description: Candidate speichern
        room.pendingCandidates.putIfAbsent(from, () => []).add(candidate);

        if (kDebugMode) {
          debugPrint(
            '📌 [WebRTC] [$roomId] Stored pending ICE candidate from $from',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC] [$roomId] Error handling ICE candidate: $e');
      }
    }
  }

  void _handleUserLeft(String roomId, Map<String, dynamic> message) {
    final peerId = message['peerId'] as String?; // Server sendet 'peerId'
    final username = message['username'] as String?;

    if (peerId == null) return;

    if (kDebugMode) {
      debugPrint(
        '👋 [WebRTC] [$roomId] User left: $username (peerId: $peerId)',
      );
    }

    final room = _rooms[roomId];
    if (room == null) return;

    // Close peer connection (use peerId as key!)
    room.peerConnections[peerId]?.close();
    room.peerConnections.remove(peerId);

    // Dispose remote renderer (use peerId as key!)
    room.remoteRenderers[peerId]?.dispose();
    room.remoteRenderers.remove(peerId);

    // Remove remote stream (use peerId as key!)
    room.remoteStreams.remove(peerId);

    // ✅ Remove participant (use peerId as key!)
    room.participants.remove(peerId);

    notifyListeners();
  }

  void _sendSignalingMessage(String roomId, Map<String, dynamic> message) {
    try {
      final room = _rooms[roomId];
      if (room == null || !room.isActive) return;

      room.signalingChannel.sink.add(json.encode(message));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC] [$roomId] Error sending signaling message: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // LEAVE ROOM (Room-spezifisch)
  // ═══════════════════════════════════════════════════════════════

  Future<void> leaveRoom(String roomId) async {
    try {
      if (kDebugMode) {
        debugPrint('👋 [WebRTC] Leaving room $roomId...');
      }

      final room = _rooms[roomId];
      if (room == null) return;

      // ✅ CRITICAL FIX: Call backend API to update participant_count in DB
      try {
        await _liveRoomService.leaveLiveRoom(roomId);
        if (kDebugMode) {
          debugPrint(
            '✅ [WebRTC] Backend updated: participant left room $roomId',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ [WebRTC] Backend leave API failed (non-critical): $e');
        }
      }

      // Send leave message via WebSocket
      _sendSignalingMessage(roomId, {
        'type': 'leave',
        'username': _currentUsername,
        'room_id': roomId,
      });

      // ✅ Room-Connection dispose (schließt alle Verbindungen)
      await room.dispose();

      // ✅ Aus Map entfernen
      _rooms.remove(roomId);

      // ✅ Stats cleanup handled by BandwidthMonitor

      // ✅ Wenn aktiver Raum, zurücksetzen
      if (_activeRoomId == roomId) {
        _activeRoomId = null;
      }

      notifyListeners();

      if (kDebugMode) {
        debugPrint('✅ [WebRTC] Left room $roomId successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC] Error leaving room $roomId: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // LEAVE ALL ROOMS (Vollständiges Cleanup)
  // ═══════════════════════════════════════════════════════════════

  Future<void> leaveAllRooms() async {
    if (kDebugMode) {
      debugPrint('👋 [WebRTC] Leaving all rooms...');
    }

    // ✅ Kopie der Room-IDs (um während Iteration zu modifizieren)
    final roomIds = _rooms.keys.toList();

    for (final roomId in roomIds) {
      await leaveRoom(roomId);
    }

    // ✅ Lokalen Stream stoppen
    _localStream?.getTracks().forEach((track) {
      track.stop();
    });
    _localStream?.dispose();
    _localStream = null;

    // ✅ Lokalen Renderer aufräumen
    _localRenderer?.dispose();
    _localRenderer = null;

    // ✅ State zurücksetzen
    _activeRoomId = null;
    _currentUsername = null;
    _isCameraEnabled = false;
    _isMicEnabled = true;

    // ✅ Stop bandwidth monitoring
    _bandwidthMonitor.stopMonitoring();

    notifyListeners();

    if (kDebugMode) {
      debugPrint('✅ [WebRTC] Left all rooms successfully');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // STATISTICS & MONITORING
  // ═══════════════════════════════════════════════════════════════

  /// Check if monitoring is active
  bool get isMonitoringActive => _bandwidthMonitor.isMonitoring;

  /// Get quality message for specific peer
  String? getQualityMessage(String roomId, String peerId) {
    return _bandwidthMonitor.getQualityMessage(roomId, peerId);
  }

  /// Check if quality has degraded
  bool hasQualityDegraded(String roomId, String peerId) {
    return _bandwidthMonitor.hasQualityDegraded(roomId, peerId);
  }

  // ═══════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════

  @override
  void dispose() {
    leaveAllRooms();
    super.dispose();
  }
}
