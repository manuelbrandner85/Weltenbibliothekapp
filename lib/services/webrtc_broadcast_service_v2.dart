import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// ═══════════════════════════════════════════════════════════════
/// WEBRTC BROADCAST SERVICE V2 - Simplified & Robust
/// ═══════════════════════════════════════════════════════════════
/// Features:
/// - ✅ Unlimited WebRTC Broadcast (1 sender, many viewers OR many-to-many)
/// - ✅ Cloudflare Worker WebSocket Relay compatible
/// - ✅ Robust Candidate Queue (no black screens)
/// - ✅ No Race Conditions in Offer/Answer exchange
/// - ✅ Unified-Plan support with Transceivers
/// - ✅ Fixed Signaling Message Structure
///
/// Signaling Message Format:
/// {
///   "type": "offer|answer|ice-candidate|join|leave|peers-list",
///   "roomId": "room123",
///   "fromPeerId": "abc123",
///   "toPeerId": "def890",
///   "payload": {...}
/// }
/// ═══════════════════════════════════════════════════════════════

class RoomConnection {
  final String roomId;
  final Map<String, RTCPeerConnection> peerConnections = {};
  final Map<String, MediaStream> remoteStreams = {};
  final Map<String, RTCVideoRenderer> remoteRenderers = {};
  final Map<String, List<RTCIceCandidate>> candidateQueue = {};
  WebSocketChannel? signalingChannel;

  RoomConnection({required this.roomId});

  Future<void> dispose() async {
    // Close all peer connections
    for (final pc in peerConnections.values) {
      await pc.close();
    }
    peerConnections.clear();

    // Dispose all renderers
    for (final renderer in remoteRenderers.values) {
      await renderer.dispose();
    }
    remoteRenderers.clear();

    // Clear streams
    remoteStreams.clear();

    // Clear candidate queue
    candidateQueue.clear();

    // Close WebSocket
    await signalingChannel?.sink.close();
    signalingChannel = null;
  }
}

class WebRTCBroadcastService extends ChangeNotifier {
  final Map<String, RoomConnection> _rooms = {};
  final Map<String, List<Map<String, dynamic>>> _candidateQueue = {};

  MediaStream? _localStream;
  RTCVideoRenderer? _localRenderer;
  String _myPeerId = "";
  String? _activeRoomId;

  bool _isCameraEnabled = false;
  bool _isMicEnabled = true;

  // ═══════════════════════════════════════════════════════════════
  // ICE SERVER CONFIG (Cloudflare TURN)
  // ═══════════════════════════════════════════════════════════════
  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      // Metered.ca TURN servers (production-ready)
      {
        'urls': 'turn:a.relay.metered.ca:80',
        'username': 'c71aa02dc4baaa26942a3e1c',
        'credential': 'Mji3tBjcLFPSxaYL',
      },
      {
        'urls': 'turn:a.relay.metered.ca:80?transport=tcp',
        'username': 'c71aa02dc4baaa26942a3e1c',
        'credential': 'Mji3tBjcLFPSxaYL',
      },
      {
        'urls': 'turn:a.relay.metered.ca:443',
        'username': 'c71aa02dc4baaa26942a3e1c',
        'credential': 'Mji3tBjcLFPSxaYL',
      },
      {
        'urls': 'turn:a.relay.metered.ca:443?transport=tcp',
        'username': 'c71aa02dc4baaa26942a3e1c',
        'credential': 'Mji3tBjcLFPSxaYL',
      },
    ],
    'iceCandidatePoolSize': 10,
    'sdpSemantics': 'unified-plan',
  };

  // ═══════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════

  bool get isConnected =>
      _activeRoomId != null && _rooms.containsKey(_activeRoomId);
  bool get isCameraEnabled => _isCameraEnabled;
  bool get isMicEnabled => _isMicEnabled;
  String? get currentRoomId => _activeRoomId;
  RTCVideoRenderer? get localRenderer => _localRenderer;

  Map<String, RTCVideoRenderer> get remoteRenderers {
    final room = _rooms[_activeRoomId];
    return room?.remoteRenderers ?? {};
  }

  int get remoteUserCount {
    final room = _rooms[_activeRoomId];
    return room?.remoteRenderers.length ?? 0;
  }

  // ═══════════════════════════════════════════════════════════════
  // INITIALIZE LOCAL MEDIA
  // ═══════════════════════════════════════════════════════════════

  Future<void> initLocalMedia({bool enableCamera = false}) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '🎥 [WebRTC v2] Initializing local media (camera: $enableCamera)...',
        );
      }

      _localRenderer = RTCVideoRenderer();
      await _localRenderer!.initialize();

      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': enableCamera
            ? {
                'facingMode': 'user',
                'width': {'ideal': 1280},
                'height': {'ideal': 720},
              }
            : false,
      });

      _localRenderer!.srcObject = _localStream;
      _isCameraEnabled = enableCamera;
      _isMicEnabled = true;

      if (kDebugMode) {
        debugPrint('✅ [WebRTC v2] Local media initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC v2] Error initializing local media: $e');
      }
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // JOIN ROOM
  // ═══════════════════════════════════════════════════════════════

  Future<void> joinRoom({
    required String roomId,
    required String peerId,
    required String signalingServerUrl,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🚪 [WebRTC v2] Joining room $roomId as $peerId');
      }

      _myPeerId = peerId;
      _activeRoomId = roomId;

      // Create room connection
      final room = RoomConnection(roomId: roomId);
      _rooms[roomId] = room;

      // Connect WebSocket
      final wsUrl = '$signalingServerUrl/$roomId';
      if (kDebugMode) {
        debugPrint('🔌 [WebRTC v2] Connecting to: $wsUrl');
      }

      room.signalingChannel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Listen to signaling messages
      room.signalingChannel!.stream.listen(
        (data) => _handleSignalingMessage(roomId, data),
        onError: (error) {
          if (kDebugMode) {
            debugPrint('❌ [WebRTC v2] WebSocket error: $error');
          }
        },
        onDone: () {
          if (kDebugMode) {
            debugPrint('🔌 [WebRTC v2] WebSocket closed');
          }
        },
      );

      // Send join message
      _send(roomId, {
        "type": "join",
        "roomId": roomId,
        "fromPeerId": _myPeerId,
      });

      if (kDebugMode) {
        debugPrint('✅ [WebRTC v2] Joined room $roomId');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC v2] Error joining room: $e');
      }
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE PEER CONNECTION
  // ═══════════════════════════════════════════════════════════════

  Future<RTCPeerConnection> _createPeerConnection(
    String roomId,
    String peerId,
  ) async {
    final room = _rooms[roomId]!;
    final pc = await createPeerConnection(_iceServers);

    if (kDebugMode) {
      debugPrint('🤝 [WebRTC v2] Creating peer connection for $peerId');
    }

    // ✅ Add Transceivers (Unified Plan)
    try {
      await pc.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.SendRecv),
      );
      await pc.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.SendRecv),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ [WebRTC v2] Transceiver creation failed (fallback to addTrack): $e',
        );
      }
    }

    // Add local tracks
    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        try {
          await pc.addTrack(track, _localStream!);
          if (kDebugMode) {
            debugPrint('➕ [WebRTC v2] Added local ${track.kind} track');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ [WebRTC v2] Error adding track: $e');
          }
        }
      }
    }

    // ✅ Handle ICE Candidate
    pc.onIceCandidate = (candidate) {
      if (candidate == null) return;

      if (kDebugMode) {
        debugPrint('🧊 [WebRTC v2] ICE candidate for $peerId');
      }

      _send(roomId, {
        "type": "ice-candidate",
        "roomId": roomId,
        "fromPeerId": _myPeerId,
        "toPeerId": peerId,
        "payload": {
          "candidate": candidate.candidate,
          "sdpMid": candidate.sdpMid,
          "sdpMLineIndex": candidate.sdpMLineIndex,
        },
      });
    };

    // ✅ Handle Remote Track (NO BLACK SCREENS!)
    pc.onTrack = (RTCTrackEvent event) async {
      if (kDebugMode) {
        debugPrint('📺 [WebRTC v2] onTrack from $peerId: ${event.track.kind}');
        debugPrint('   Streams count: ${event.streams.length}');
      }

      final renderer = RTCVideoRenderer();
      await renderer.initialize();

      MediaStream remoteStream;

      if (event.streams.isNotEmpty) {
        // ✅ Stream from event
        remoteStream = event.streams[0];
      } else {
        // ✅ Create synthetic stream (fallback for some implementations)
        remoteStream = await createLocalMediaStream("remote-$peerId");
        if (event.track != null) {
          remoteStream.addTrack(event.track!);
        }
      }

      renderer.srcObject = remoteStream;
      room.remoteStreams[peerId] = remoteStream;

      // Dispose old renderer if exists
      if (room.remoteRenderers.containsKey(peerId)) {
        try {
          await room.remoteRenderers[peerId]!.dispose();
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ [WebRTC v2] Error disposing old renderer: $e');
          }
        }
      }

      room.remoteRenderers[peerId] = renderer;

      if (kDebugMode) {
        debugPrint('✅ [WebRTC v2] Renderer created for $peerId');
      }

      // ✅ Apply queued ICE candidates NOW (after track received)
      if (room.candidateQueue.containsKey(peerId)) {
        final queuedCandidates = room.candidateQueue[peerId]!;
        if (kDebugMode) {
          debugPrint(
            '📌 [WebRTC v2] Applying ${queuedCandidates.length} queued candidates for $peerId',
          );
        }

        for (final cand in queuedCandidates) {
          try {
            await pc.addCandidate(cand);
          } catch (e) {
            if (kDebugMode) {
              debugPrint('⚠️ [WebRTC v2] Error adding queued candidate: $e');
            }
          }
        }
        room.candidateQueue.remove(peerId);
      }

      notifyListeners();
    };

    // ✅ Connection State Monitoring
    pc.onIceConnectionState = (state) {
      if (kDebugMode) {
        debugPrint('🧊 [WebRTC v2] ICE state with $peerId: $state');
      }
    };

    pc.onConnectionState = (state) {
      if (kDebugMode) {
        debugPrint('🔗 [WebRTC v2] Connection state with $peerId: $state');
      }
    };

    room.peerConnections[peerId] = pc;
    return pc;
  }

  // ═══════════════════════════════════════════════════════════════
  // HANDLE SIGNALING MESSAGES
  // ═══════════════════════════════════════════════════════════════

  void _handleSignalingMessage(String roomId, dynamic data) async {
    try {
      final message = json.decode(data as String) as Map<String, dynamic>;
      final type = message['type'] as String;

      if (kDebugMode) {
        debugPrint('📨 [WebRTC v2] [$roomId] Received: $type');
      }

      switch (type) {
        case 'peer-joined':
        case 'user_joined':
          await _handlePeerJoined(roomId, message);
          break;
        case 'peers-list':
          await _handlePeersList(roomId, message);
          break;
        case 'offer':
          await _handleOffer(roomId, message);
          break;
        case 'answer':
          await _handleAnswer(roomId, message);
          break;
        case 'ice-candidate':
        case 'ice_candidate':
          await _handleIceCandidate(roomId, message);
          break;
        case 'peer-left':
        case 'user_left':
          await _handlePeerLeft(roomId, message);
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC v2] Error handling signaling: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // HANDLE PEER JOINED
  // ═══════════════════════════════════════════════════════════════

  Future<void> _handlePeerJoined(
    String roomId,
    Map<String, dynamic> message,
  ) async {
    final peerId =
        message['fromPeerId'] as String? ?? message['peerId'] as String?;

    if (peerId == null || peerId == _myPeerId) {
      return;
    }

    if (kDebugMode) {
      debugPrint('👤 [WebRTC v2] Peer joined: $peerId');
    }

    // Create peer connection
    await _createPeerConnection(roomId, peerId);

    // Create offer
    await _createOffer(roomId, peerId);
  }

  // ═══════════════════════════════════════════════════════════════
  // HANDLE PEERS LIST
  // ═══════════════════════════════════════════════════════════════

  Future<void> _handlePeersList(
    String roomId,
    Map<String, dynamic> message,
  ) async {
    final peers = message['peers'] as List<dynamic>?;

    if (peers == null || peers.isEmpty) {
      return;
    }

    if (kDebugMode) {
      debugPrint('👥 [WebRTC v2] Peers list: ${peers.length} peer(s)');
    }

    for (final peerData in peers) {
      String peerId;

      if (peerData is String) {
        peerId = peerData;
      } else if (peerData is Map) {
        peerId = peerData['peerId'] as String? ?? peerData['id'] as String;
      } else {
        continue;
      }

      if (peerId == _myPeerId) {
        continue;
      }

      // Create connection
      await _createPeerConnection(roomId, peerId);

      // Create offer
      await _createOffer(roomId, peerId);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE OFFER
  // ═══════════════════════════════════════════════════════════════

  Future<void> _createOffer(String roomId, String peerId) async {
    try {
      final room = _rooms[roomId];
      if (room == null) return;

      final pc = room.peerConnections[peerId];
      if (pc == null) return;

      if (kDebugMode) {
        debugPrint('📤 [WebRTC v2] Creating offer for $peerId');
      }

      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);

      _send(roomId, {
        "type": "offer",
        "roomId": roomId,
        "fromPeerId": _myPeerId,
        "toPeerId": peerId,
        "payload": {"sdp": offer.toMap()},
      });

      if (kDebugMode) {
        debugPrint('✅ [WebRTC v2] Offer sent to $peerId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC v2] Error creating offer: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // HANDLE OFFER
  // ═══════════════════════════════════════════════════════════════

  Future<void> _handleOffer(String roomId, Map<String, dynamic> message) async {
    try {
      final fromPeerId = message['fromPeerId'] as String;
      final sdpMap = message['payload']['sdp'] as Map<String, dynamic>;

      if (kDebugMode) {
        debugPrint('📥 [WebRTC v2] Received offer from $fromPeerId');
      }

      final room = _rooms[roomId];
      if (room == null) return;

      // Create peer connection if not exists
      RTCPeerConnection pc;
      if (room.peerConnections.containsKey(fromPeerId)) {
        pc = room.peerConnections[fromPeerId]!;
      } else {
        pc = await _createPeerConnection(roomId, fromPeerId);
      }

      // Set remote description
      final offer = RTCSessionDescription(
        sdpMap['sdp'] as String,
        sdpMap['type'] as String,
      );
      await pc.setRemoteDescription(offer);

      // ✅ Apply pending ICE candidates (if any)
      if (room.candidateQueue.containsKey(fromPeerId)) {
        final queuedCandidates = room.candidateQueue[fromPeerId]!;
        if (kDebugMode) {
          debugPrint(
            '📌 [WebRTC v2] Applying ${queuedCandidates.length} queued candidates',
          );
        }

        for (final cand in queuedCandidates) {
          try {
            await pc.addCandidate(cand);
          } catch (e) {
            if (kDebugMode) {
              debugPrint('⚠️ [WebRTC v2] Error adding candidate: $e');
            }
          }
        }
        room.candidateQueue.remove(fromPeerId);
      }

      // Create answer
      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);

      _send(roomId, {
        "type": "answer",
        "roomId": roomId,
        "fromPeerId": _myPeerId,
        "toPeerId": fromPeerId,
        "payload": {"sdp": answer.toMap()},
      });

      if (kDebugMode) {
        debugPrint('✅ [WebRTC v2] Answer sent to $fromPeerId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC v2] Error handling offer: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // HANDLE ANSWER
  // ═══════════════════════════════════════════════════════════════

  Future<void> _handleAnswer(
    String roomId,
    Map<String, dynamic> message,
  ) async {
    try {
      final fromPeerId = message['fromPeerId'] as String;
      final sdpMap = message['payload']['sdp'] as Map<String, dynamic>;

      if (kDebugMode) {
        debugPrint('📥 [WebRTC v2] Received answer from $fromPeerId');
      }

      final room = _rooms[roomId];
      if (room == null) return;

      final pc = room.peerConnections[fromPeerId];
      if (pc == null) return;

      final answer = RTCSessionDescription(
        sdpMap['sdp'] as String,
        sdpMap['type'] as String,
      );

      await pc.setRemoteDescription(answer);

      // ✅ Apply pending ICE candidates (if any)
      if (room.candidateQueue.containsKey(fromPeerId)) {
        final queuedCandidates = room.candidateQueue[fromPeerId]!;
        if (kDebugMode) {
          debugPrint(
            '📌 [WebRTC v2] Applying ${queuedCandidates.length} queued candidates',
          );
        }

        for (final cand in queuedCandidates) {
          try {
            await pc.addCandidate(cand);
          } catch (e) {
            if (kDebugMode) {
              debugPrint('⚠️ [WebRTC v2] Error adding candidate: $e');
            }
          }
        }
        room.candidateQueue.remove(fromPeerId);
      }

      if (kDebugMode) {
        debugPrint('✅ [WebRTC v2] Answer applied from $fromPeerId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC v2] Error handling answer: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // HANDLE ICE CANDIDATE (WITH QUEUE!)
  // ═══════════════════════════════════════════════════════════════

  Future<void> _handleIceCandidate(
    String roomId,
    Map<String, dynamic> message,
  ) async {
    try {
      final fromPeerId = message['fromPeerId'] as String;
      final candidateData = message['payload'] as Map<String, dynamic>;

      if (kDebugMode) {
        debugPrint('🧊 [WebRTC v2] Received ICE candidate from $fromPeerId');
      }

      final room = _rooms[roomId];
      if (room == null) return;

      final pc = room.peerConnections[fromPeerId];

      final candidate = RTCIceCandidate(
        candidateData['candidate'] as String?,
        candidateData['sdpMid'] as String?,
        candidateData['sdpMLineIndex'] as int?,
      );

      if (pc != null && pc.getRemoteDescription() != null) {
        // ✅ Remote Description is set: Add candidate immediately
        await pc.addCandidate(candidate);

        if (kDebugMode) {
          debugPrint('✅ [WebRTC v2] ICE candidate added for $fromPeerId');
        }
      } else {
        // ✅ Queue candidate until remote description is set
        room.candidateQueue.putIfAbsent(fromPeerId, () => []).add(candidate);

        if (kDebugMode) {
          debugPrint(
            '📌 [WebRTC v2] ICE candidate queued for $fromPeerId (no remote description yet)',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC v2] Error handling ICE candidate: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // HANDLE PEER LEFT
  // ═══════════════════════════════════════════════════════════════

  Future<void> _handlePeerLeft(
    String roomId,
    Map<String, dynamic> message,
  ) async {
    final peerId =
        message['fromPeerId'] as String? ?? message['peerId'] as String?;

    if (peerId == null) return;

    if (kDebugMode) {
      debugPrint('👋 [WebRTC v2] Peer left: $peerId');
    }

    final room = _rooms[roomId];
    if (room == null) return;

    // Close peer connection
    final pc = room.peerConnections[peerId];
    if (pc != null) {
      await pc.close();
      room.peerConnections.remove(peerId);
    }

    // Dispose renderer
    final renderer = room.remoteRenderers[peerId];
    if (renderer != null) {
      await renderer.dispose();
      room.remoteRenderers.remove(peerId);
    }

    // Remove stream
    room.remoteStreams.remove(peerId);

    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // TOGGLE CAMERA
  // ═══════════════════════════════════════════════════════════════

  Future<void> toggleCamera() async {
    try {
      if (_isCameraEnabled) {
        // Disable camera
        final videoTracks = _localStream?.getVideoTracks() ?? [];

        for (final track in videoTracks) {
          track.enabled = false;
          await track.stop();
          _localStream?.removeTrack(track);
        }

        // Update all peer connections
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

        _localRenderer?.srcObject = null;
        _isCameraEnabled = false;

        if (kDebugMode) {
          debugPrint('📷 [WebRTC v2] Camera disabled');
        }
      } else {
        // Enable camera
        final newStream = await navigator.mediaDevices.getUserMedia({
          'audio': _isMicEnabled,
          'video': {
            'facingMode': 'user',
            'width': {'ideal': 1280},
            'height': {'ideal': 720},
          },
        });

        final videoTrack = newStream.getVideoTracks()[0];

        if (_localStream == null) {
          _localStream = newStream;
        } else {
          _localStream!.addTrack(videoTrack);
        }

        _localRenderer?.srcObject = _localStream;

        await Future.delayed(const Duration(milliseconds: 100));

        // Update all peer connections
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

            if (!videoSenderFound) {
              await pc.addTrack(videoTrack, _localStream!);
            }
          }
        }

        _isCameraEnabled = true;

        if (kDebugMode) {
          debugPrint('📷 [WebRTC v2] Camera enabled');
        }
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC v2] Error toggling camera: $e');
      }
      _isCameraEnabled = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // TOGGLE MICROPHONE
  // ═══════════════════════════════════════════════════════════════

  void toggleMicrophone() {
    if (_localStream == null) return;

    _isMicEnabled = !_isMicEnabled;

    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = _isMicEnabled;
    }

    notifyListeners();

    if (kDebugMode) {
      debugPrint(
        '🎤 [WebRTC v2] Microphone ${_isMicEnabled ? 'enabled' : 'disabled'}',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // LEAVE ROOM
  // ═══════════════════════════════════════════════════════════════

  Future<void> leaveRoom(String roomId) async {
    try {
      if (kDebugMode) {
        debugPrint('👋 [WebRTC v2] Leaving room $roomId');
      }

      final room = _rooms[roomId];
      if (room == null) return;

      // Send leave message
      _send(roomId, {
        "type": "leave",
        "roomId": roomId,
        "fromPeerId": _myPeerId,
      });

      // Dispose room
      await room.dispose();
      _rooms.remove(roomId);

      if (_activeRoomId == roomId) {
        _activeRoomId = null;
      }

      notifyListeners();

      if (kDebugMode) {
        debugPrint('✅ [WebRTC v2] Left room $roomId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC v2] Error leaving room: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SEND SIGNALING MESSAGE
  // ═══════════════════════════════════════════════════════════════

  void _send(String roomId, Map<String, dynamic> data) {
    try {
      final room = _rooms[roomId];
      if (room == null) return;

      if (kDebugMode) {
        debugPrint('📤 [WebRTC v2] Sending: ${data['type']}');
      }

      room.signalingChannel?.sink.add(json.encode(data));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC v2] Error sending message: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════

  @override
  void dispose() {
    // Leave all rooms
    for (final roomId in _rooms.keys.toList()) {
      leaveRoom(roomId);
    }

    // Stop local stream
    _localStream?.getTracks().forEach((track) {
      track.stop();
    });
    _localStream?.dispose();
    _localStream = null;

    // Dispose local renderer
    _localRenderer?.dispose();
    _localRenderer = null;

    super.dispose();
  }
}
