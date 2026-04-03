import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Teilnehmer im Video/Voice-Raum
class VoiceVideoParticipant {
  final String userId;
  final String username;
  final String avatar;
  bool isMicOn;
  bool isCameraOn;
  MediaStream? stream;

  VoiceVideoParticipant({
    required this.userId,
    required this.username,
    this.avatar = '👤',
    this.isMicOn = true,
    this.isCameraOn = false,
    this.stream,
  });
}

/// Video + Voice Chat Service via WebRTC + Supabase Realtime Signaling
class VideoVoiceService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  // Lokaler Stream
  MediaStream? localStream;
  RTCVideoRenderer localRenderer = RTCVideoRenderer();

  // Remote Streams: userId → Renderer
  final Map<String, RTCVideoRenderer> remoteRenderers = {};
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, VoiceVideoParticipant> participants = {};

  // Status
  bool isMicOn = true;
  bool isCameraOn = false;
  bool isFrontCamera = true;
  bool isConnected = false;
  bool isInitializing = false;

  String? _userId;

  RealtimeChannel? _signalingChannel;

  static const Map<String, dynamic> _iceConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  // ─────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────

  Future<void> initialize({
    required String roomId,
    required String userId,
    required String username,
    String avatar = '👤',
  }) async {
    if (isInitializing || isConnected) return;
    isInitializing = true;
    _userId = userId;
    notifyListeners();

    try {
      await localRenderer.initialize();

      // Nur Mikrofon beim Start – Kamera optional
      localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });
      localRenderer.srcObject = localStream;

      // Signaling-Kanal via Supabase Realtime
      _signalingChannel = _supabase.channel('video_voice:$roomId');
      _signalingChannel!
          .onBroadcast(
            event: 'join',
            callback: (payload) => _onPeerJoin(payload),
          )
          .onBroadcast(
            event: 'leave',
            callback: (payload) => _onPeerLeave(payload),
          )
          .onBroadcast(
            event: 'offer',
            callback: (payload) => _onOffer(payload),
          )
          .onBroadcast(
            event: 'answer',
            callback: (payload) => _onAnswer(payload),
          )
          .onBroadcast(
            event: 'ice',
            callback: (payload) => _onIceCandidate(payload),
          )
          .onBroadcast(
            event: 'camera_state',
            callback: (payload) => _onCameraState(payload),
          );

      _signalingChannel!.subscribe();

      // Beitritt ankündigen
      await _signalingChannel!.sendBroadcastMessage(
        event: 'join',
        payload: {
          'userId': userId,
          'username': username,
          'avatar': avatar,
          'isMicOn': isMicOn,
          'isCameraOn': isCameraOn,
        },
      );

      isConnected = true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ VideoVoiceService init error: $e');
    } finally {
      isInitializing = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  // KAMERA TOGGLE
  // ─────────────────────────────────────────────

  Future<void> toggleCamera() async {
    try {
      if (!isCameraOn) {
        // Kamera einschalten
        final videoStream = await navigator.mediaDevices.getUserMedia({
          'audio': false,
          'video': {
            'facingMode': isFrontCamera ? 'user' : 'environment',
            'width': {'ideal': 1280},
            'height': {'ideal': 720},
          },
        });

        final videoTrack = videoStream.getVideoTracks().first;
        await localStream?.addTrack(videoTrack);
        localRenderer.srcObject = localStream;

        // Allen bestehenden Peers den Video-Track senden
        for (final entry in _peerConnections.entries) {
          final senders = await entry.value.senders;
          final hasVideo = senders.any((s) => s.track?.kind == 'video');
          if (!hasVideo) {
            await entry.value.addTrack(videoTrack, localStream!);
          }
        }

        isCameraOn = true;
      } else {
        // Kamera ausschalten
        final tracks = localStream?.getVideoTracks() ?? [];
        for (final track in tracks) {
          await track.stop();
          await localStream?.removeTrack(track);
        }
        isCameraOn = false;
      }

      // Anderen Teilnehmern Kamera-Status mitteilen
      await _signalingChannel?.sendBroadcastMessage(
        event: 'camera_state',
        payload: {'userId': _userId, 'isCameraOn': isCameraOn},
      );

      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ toggleCamera error: $e');
    }
  }

  // ─────────────────────────────────────────────
  // MIC TOGGLE
  // ─────────────────────────────────────────────

  void toggleMicrophone() {
    isMicOn = !isMicOn;
    localStream?.getAudioTracks().forEach((t) => t.enabled = isMicOn);
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // KAMERA WECHSELN
  // ─────────────────────────────────────────────

  Future<void> switchCamera() async {
    if (!isCameraOn) return;
    isFrontCamera = !isFrontCamera;
    final videoTracks = localStream?.getVideoTracks() ?? [];
    for (final track in videoTracks) {
      await Helper.switchCamera(track);
    }
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // SIGNALING EVENTS
  // ─────────────────────────────────────────────

  Future<void> _onPeerJoin(Map<String, dynamic> payload) async {
    final peerId = payload['userId'] as String?;
    if (peerId == null || peerId == _userId) return;

    final participant = VoiceVideoParticipant(
      userId: peerId,
      username: payload['username'] as String? ?? 'Anonym',
      avatar: payload['avatar'] as String? ?? '👤',
      isMicOn: payload['isMicOn'] as bool? ?? true,
      isCameraOn: payload['isCameraOn'] as bool? ?? false,
    );
    participants[peerId] = participant;

    // Peer-Connection erstellen und Offer senden
    final pc = await _createPeerConnection(peerId);
    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    await _signalingChannel?.sendBroadcastMessage(
      event: 'offer',
      payload: {
        'from': _userId,
        'to': peerId,
        'sdp': {'type': offer.type, 'sdp': offer.sdp},
      },
    );

    notifyListeners();
  }

  Future<void> _onPeerLeave(Map<String, dynamic> payload) async {
    final peerId = payload['userId'] as String?;
    if (peerId == null) return;

    await _peerConnections[peerId]?.close();
    _peerConnections.remove(peerId);

    await remoteRenderers[peerId]?.dispose();
    remoteRenderers.remove(peerId);

    participants.remove(peerId);
    notifyListeners();
  }

  Future<void> _onOffer(Map<String, dynamic> payload) async {
    final from = payload['from'] as String?;
    final to = payload['to'] as String?;
    if (from == null || to != _userId) return;

    if (!participants.containsKey(from)) {
      participants[from] = VoiceVideoParticipant(
        userId: from,
        username: 'Teilnehmer',
      );
    }

    final pc = await _createPeerConnection(from);
    final sdpData = payload['sdp'] as Map<String, dynamic>;
    await pc.setRemoteDescription(
      RTCSessionDescription(sdpData['sdp'] as String, sdpData['type'] as String),
    );

    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);

    await _signalingChannel?.sendBroadcastMessage(
      event: 'answer',
      payload: {
        'from': _userId,
        'to': from,
        'sdp': {'type': answer.type, 'sdp': answer.sdp},
      },
    );
  }

  Future<void> _onAnswer(Map<String, dynamic> payload) async {
    final from = payload['from'] as String?;
    final to = payload['to'] as String?;
    if (from == null || to != _userId) return;

    final pc = _peerConnections[from];
    if (pc == null) return;

    final sdpData = payload['sdp'] as Map<String, dynamic>;
    await pc.setRemoteDescription(
      RTCSessionDescription(sdpData['sdp'] as String, sdpData['type'] as String),
    );
  }

  Future<void> _onIceCandidate(Map<String, dynamic> payload) async {
    final from = payload['from'] as String?;
    final to = payload['to'] as String?;
    if (from == null || to != _userId) return;

    final pc = _peerConnections[from];
    if (pc == null) return;

    final candidateData = payload['candidate'] as Map<String, dynamic>;
    await pc.addCandidate(RTCIceCandidate(
      candidateData['candidate'] as String,
      candidateData['sdpMid'] as String?,
      candidateData['sdpMLineIndex'] as int?,
    ));
  }

  void _onCameraState(Map<String, dynamic> payload) {
    final peerId = payload['userId'] as String?;
    if (peerId == null || peerId == _userId) return;
    final participant = participants[peerId];
    if (participant != null) {
      participant.isCameraOn = payload['isCameraOn'] as bool? ?? false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  // PEER CONNECTION
  // ─────────────────────────────────────────────

  Future<RTCPeerConnection> _createPeerConnection(String peerId) async {
    if (_peerConnections.containsKey(peerId)) {
      return _peerConnections[peerId]!;
    }

    final pc = await createPeerConnection(_iceConfig);
    _peerConnections[peerId] = pc;

    // Lokale Tracks hinzufügen
    localStream?.getTracks().forEach((track) {
      pc.addTrack(track, localStream!);
    });

    // ICE Candidates
    pc.onIceCandidate = (candidate) {
      if (candidate.candidate == null) return;
      _signalingChannel?.sendBroadcastMessage(
        event: 'ice',
        payload: {
          'from': _userId,
          'to': peerId,
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        },
      );
    };

    // Remote Track empfangen
    pc.onTrack = (event) async {
      if (event.streams.isEmpty) return;
      final stream = event.streams[0];

      if (!remoteRenderers.containsKey(peerId)) {
        final renderer = RTCVideoRenderer();
        await renderer.initialize();
        remoteRenderers[peerId] = renderer;
      }
      remoteRenderers[peerId]!.srcObject = stream;

      if (participants.containsKey(peerId)) {
        participants[peerId]!.stream = stream;
        participants[peerId]!.isCameraOn =
            stream.getVideoTracks().isNotEmpty;
      }
      notifyListeners();
    };

    pc.onConnectionState = (state) {
      if (kDebugMode) debugPrint('🔌 PeerConnection[$peerId]: $state');
    };

    return pc;
  }

  // ─────────────────────────────────────────────
  // DISCONNECT
  // ─────────────────────────────────────────────

  Future<void> disconnect() async {
    if (!isConnected) return;

    await _signalingChannel?.sendBroadcastMessage(
      event: 'leave',
      payload: {'userId': _userId},
    );

    for (final pc in _peerConnections.values) {
      await pc.close();
    }
    _peerConnections.clear();

    for (final renderer in remoteRenderers.values) {
      await renderer.dispose();
    }
    remoteRenderers.clear();
    participants.clear();

    localStream?.getTracks().forEach((t) => t.stop());
    await localStream?.dispose();
    localStream = null;
    await localRenderer.dispose();

    await _signalingChannel?.unsubscribe();
    _signalingChannel = null;

    isConnected = false;
    isCameraOn = false;
    isMicOn = true;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
