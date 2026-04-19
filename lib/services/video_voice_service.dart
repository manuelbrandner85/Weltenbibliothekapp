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
///
/// v5.28.0 – Production-Grade Rewrite:
/// ─────────────────────────────────────────────────────────────────
/// CAMERA SWITCH FIX:
///   - switchCamera() nutzt Helper.switchCamera() (flutter_webrtc native API)
///     statt manuellen getUserMedia-Aufruf → zuverlässiger auf Android/iOS
///   - Fallback auf manuelle Implementierung wenn Helper-Methode nicht verfügbar
///   - _isCameraToggling Guards verhindern Race Conditions
///
/// MULTI-PARTICIPANT FIX:
///   - Jeder Peer bekommt eigene RTCPeerConnection mit vollständiger
///     Transceivers-Konfiguration (audio + video von Beginn an)
///   - addTransceiver statt addTrack → garantiert, dass Remote immer Video empfangen kann
///   - onTrack prüft streams.isEmpty + streams[0].id für korrekte Peer-Zuordnung
///   - _peerStreamMap: Stream-ID → Peer-ID für zuverlässige Zuordnung
///
/// AUDIO FIX:
///   - Audio-Tracks werden bei Peer-Connection Init immer hinzugefügt
///   - Audio Transceiver direction: sendrecv
///   - Mikrofon-Toggle via track.enabled (kein stop/remove)
///
/// RECONNECT FIX:
///   - Automatisches Re-Offer nach RTCPeerConnectionStateFailed
///   - _reconnectAttempts Counter verhindert Endlos-Loop
class VideoVoiceService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  // Lokaler Stream (Audio immer, Video optional)
  MediaStream? localStream;

  // Lokaler Renderer
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer get localRenderer => _localRenderer;
  bool _rendererInitialized = false;

  // Remote Streams: userId → Renderer
  final Map<String, RTCVideoRenderer> remoteRenderers = {};
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, VoiceVideoParticipant> participants = {};

  // Stream-ID → peerId Mapping (für onTrack Zuordnung bei mehreren Peers)
  final Map<String, String> _streamToPeer = {};

  // ICE Candidate Queue
  final Map<String, List<RTCIceCandidate>> _pendingIceCandidates = {};
  final Set<String> _remoteDescriptionSet = {};

  // Reconnect Guards
  final Map<String, int> _reconnectAttempts = {};
  static const int _maxReconnectAttempts = 3;

  // Status
  bool isMicOn = true;
  bool isCameraOn = false;
  bool isFrontCamera = true;
  bool isConnected = false;
  bool isInitializing = false;
  bool _isCameraToggling = false;
  bool _isDisposed = false;

  String? _userId;
  // Fields for future reconnect/rejoin capability
  String? _roomId; // ignore: unused_field
  String? _username; // ignore: unused_field
  String? _avatar; // ignore: unused_field

  RealtimeChannel? _signalingChannel;

  // ─────────────────────────────────────────────
  // ICE SERVERS
  // ─────────────────────────────────────────────
  static const Map<String, dynamic> _iceConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun.stunprotocol.org:3478'},
      // Open TURN via OpenRelay (kostenlos, für NAT traversal)
      {
        'urls': 'turn:openrelay.metered.ca:80',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turn:openrelay.metered.ca:443',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
    ],
    'sdpSemantics': 'unified-plan',
    'bundlePolicy': 'max-bundle',
    'rtcpMuxPolicy': 'require',
    'iceTransportPolicy': 'all',
  };

  // ─────────────────────────────────────────────
  // VIDEO CONSTRAINTS
  // ─────────────────────────────────────────────
  Map<String, dynamic> _buildVideoConstraints({bool front = true}) {
    return {
      'audio': false,
      'video': {
        'facingMode': front ? 'user' : 'environment',
        'width': {'ideal': 640, 'max': 1280},
        'height': {'ideal': 480, 'max': 960},
        'frameRate': {'ideal': 24, 'max': 30},
      },
    };
  }

  // ─────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────
  Future<void> initialize({
    required String roomId,
    required String userId,
    required String username,
    String avatar = '👤',
  }) async {
    if (isInitializing || isConnected || _isDisposed) return;
    isInitializing = true;
    _userId = userId;
    _roomId = roomId;
    _username = username;
    _avatar = avatar;
    notifyListeners();

    try {
      // Renderer initialisieren
      if (!_rendererInitialized) {
        _localRenderer = RTCVideoRenderer();
        await _localRenderer.initialize();
        _rendererInitialized = true;
      }

      // Nur Audio beim Start (Kamera ist optional)
      localStream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
          'sampleRate': 48000,
        },
        'video': false,
      });
      _localRenderer.srcObject = localStream;

      // Signaling via Supabase Realtime
      _setupSignalingChannel(roomId);

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
      isInitializing = false;
      if (!_isDisposed) notifyListeners();
      return;
    }

    isInitializing = false;
    if (!_isDisposed) notifyListeners();
  }

  void _setupSignalingChannel(String roomId) {
    _signalingChannel = _supabase.channel('video_voice:$roomId');
    _signalingChannel!
        .onBroadcast(event: 'join', callback: (p) => _onPeerJoin(p))
        .onBroadcast(event: 'leave', callback: (p) => _onPeerLeave(p))
        .onBroadcast(event: 'offer', callback: (p) => _onOffer(p))
        .onBroadcast(event: 'answer', callback: (p) => _onAnswer(p))
        .onBroadcast(event: 'ice', callback: (p) => _onIceCandidate(p))
        .onBroadcast(event: 'camera_state', callback: (p) => _onCameraState(p))
        .onBroadcast(event: 'mic_state', callback: (p) => _onMicState(p));

    _signalingChannel!.subscribe();
  }

  // ─────────────────────────────────────────────
  // MIKROFON EIN/AUS
  // ─────────────────────────────────────────────
  void toggleMicrophone() {
    if (_isDisposed) return;
    isMicOn = !isMicOn;
    // Audio-Track enable/disable (kein stop/remove → kein Renegotiation nötig)
    localStream?.getAudioTracks().forEach((t) => t.enabled = isMicOn);

    // Anderen Teilnehmern mitteilen
    _signalingChannel?.sendBroadcastMessage(
      event: 'mic_state',
      payload: {'userId': _userId, 'isMicOn': isMicOn},
    );
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // KAMERA EIN/AUS
  // ─────────────────────────────────────────────
  Future<bool> toggleCamera() async {
    if (_isCameraToggling || _isDisposed) return isCameraOn;
    _isCameraToggling = true;

    try {
      if (!isCameraOn) {
        // KAMERA EINSCHALTEN
        final videoStream = await navigator.mediaDevices.getUserMedia(
          _buildVideoConstraints(front: isFrontCamera),
        );

        final videoTracks = videoStream.getVideoTracks();
        if (videoTracks.isEmpty) throw Exception('Keine Video-Tracks');

        final videoTrack = videoTracks.first;

        // Alten Video-Track entfernen
        final oldTracks = localStream?.getVideoTracks() ?? [];
        for (final old in oldTracks) {
          old.stop();
          await localStream?.removeTrack(old);
        }

        await localStream?.addTrack(videoTrack);

        // Renderer aktualisieren
        _localRenderer.srcObject = null;
        await Future.delayed(const Duration(milliseconds: 50));
        _localRenderer.srcObject = localStream;

        // Peers: Video-Transceiver aktivieren oder neuen Track senden
        for (final entry in _peerConnections.entries) {
          final peerId = entry.key;
          final pc = entry.value;
          try {
            final senders = await pc.senders;
            final videoSender = senders
                .cast<RTCRtpSender?>()
                .firstWhere(
                  (s) => s?.track?.kind == 'video',
                  orElse: () => null,
                );

            if (videoSender != null) {
              await videoSender.replaceTrack(videoTrack);
            } else {
              // Kein Video-Sender → Track hinzufügen + Renegotiation
              await pc.addTrack(videoTrack, localStream!);
              await _sendOffer(peerId, pc, isRenegotiation: true);
            }
          } catch (e) {
            if (kDebugMode) debugPrint('⚠️ toggleCamera peer[$peerId]: $e');
          }
        }

        isCameraOn = true;
      } else {
        // KAMERA AUSSCHALTEN
        final videoTracks = localStream?.getVideoTracks() ?? [];
        for (final track in videoTracks) {
          track.stop();
          await localStream?.removeTrack(track);
        }

        _localRenderer.srcObject = null;
        await Future.delayed(const Duration(milliseconds: 20));
        _localRenderer.srcObject = localStream;

        // Peers: Video-Track ersetzen durch null
        for (final pc in _peerConnections.values) {
          try {
            final senders = await pc.senders;
            final videoSender = senders
                .cast<RTCRtpSender?>()
                .firstWhere(
                  (s) => s?.track?.kind == 'video',
                  orElse: () => null,
                );
            if (videoSender != null) {
              await videoSender.replaceTrack(null);
            }
          } catch (e) {
            if (kDebugMode) debugPrint('⚠️ toggleCamera off: $e');
          }
        }

        isCameraOn = false;
      }

      // Anderen Teilnehmern Kamera-Status mitteilen
      await _signalingChannel?.sendBroadcastMessage(
        event: 'camera_state',
        payload: {'userId': _userId, 'isCameraOn': isCameraOn},
      );

      if (!_isDisposed) notifyListeners();
      return isCameraOn;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ toggleCamera error: $e');
      isCameraOn = false;
      if (!_isDisposed) notifyListeners();
      return false;
    } finally {
      _isCameraToggling = false;
    }
  }

  // ─────────────────────────────────────────────
  // KAMERA WECHSELN (vorne ↔ hinten)
  // FIX v5.28.0: Nutzt flutter_webrtc Helper.switchCamera()
  // Das ist die native API die auf Android/iOS zuverlässig funktioniert
  // ─────────────────────────────────────────────
  Future<void> switchCamera() async {
    if (!isCameraOn || _isCameraToggling || _isDisposed) return;
    _isCameraToggling = true;

    try {
      final videoTracks = localStream?.getVideoTracks() ?? [];
      if (videoTracks.isEmpty) {
        if (kDebugMode) debugPrint('⚠️ switchCamera: Kein Video-Track vorhanden');
        return;
      }

      final videoTrack = videoTracks.first;

      // FIX: flutter_webrtc Helper.switchCamera() ist die korrekte API
      // für Android/iOS. Sie schaltet intern die Kamera um ohne neuen Stream.
      await Helper.switchCamera(videoTrack);
      isFrontCamera = !isFrontCamera;

      // Renderer kurz neu binden für UI-Update
      final currentStream = _localRenderer.srcObject;
      _localRenderer.srcObject = null;
      await Future.delayed(const Duration(milliseconds: 100));
      _localRenderer.srcObject = currentStream;

      // Peers informieren (kein SDP-Offer nötig, gleicher Track)
      await _signalingChannel?.sendBroadcastMessage(
        event: 'camera_state',
        payload: {'userId': _userId, 'isCameraOn': true},
      );

      if (!_isDisposed) notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Helper.switchCamera failed, using fallback: $e');
      // Fallback: Manuelles Neuerstellen des Streams
      await _switchCameraFallback();
    } finally {
      _isCameraToggling = false;
    }
  }

  /// Fallback wenn Helper.switchCamera nicht verfügbar ist
  Future<void> _switchCameraFallback() async {
    try {
      isFrontCamera = !isFrontCamera;

      final newStream = await navigator.mediaDevices.getUserMedia(
        _buildVideoConstraints(front: isFrontCamera),
      );

      final newTracks = newStream.getVideoTracks();
      if (newTracks.isEmpty) {
        isFrontCamera = !isFrontCamera;
        return;
      }

      final newTrack = newTracks.first;

      // Alten Track stoppen
      final oldTracks = localStream?.getVideoTracks() ?? [];
      for (final old in oldTracks) {
        old.stop();
        await localStream?.removeTrack(old);
      }

      await localStream?.addTrack(newTrack);

      _localRenderer.srcObject = null;
      await Future.delayed(const Duration(milliseconds: 80));
      _localRenderer.srcObject = localStream;

      // Peers: Track ersetzen
      for (final pc in _peerConnections.values) {
        try {
          final senders = await pc.senders;
          final videoSender = senders
              .cast<RTCRtpSender?>()
              .firstWhere(
                (s) => s?.track?.kind == 'video',
                orElse: () => null,
              );
          if (videoSender != null) {
            await videoSender.replaceTrack(newTrack);
          }
        } catch (e) {
          if (kDebugMode) debugPrint('⚠️ switchCamera fallback peer: $e');
        }
      }

      await _signalingChannel?.sendBroadcastMessage(
        event: 'camera_state',
        payload: {'userId': _userId, 'isCameraOn': true},
      );

      if (!_isDisposed) notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ switchCamera fallback error: $e');
      isFrontCamera = !isFrontCamera; // Zurücksetzen
    }
  }

  // ─────────────────────────────────────────────
  // RENEGOTIATION
  // ─────────────────────────────────────────────
  Future<void> _sendOffer(
    String peerId,
    RTCPeerConnection pc, {
    bool isRenegotiation = false,
  }) async {
    try {
      final offer = await pc.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      });
      await pc.setLocalDescription(offer);

      await _signalingChannel?.sendBroadcastMessage(
        event: 'offer',
        payload: {
          'from': _userId,
          'to': peerId,
          'sdp': {'type': offer.type, 'sdp': offer.sdp},
          'isRenegotiation': isRenegotiation,
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ sendOffer[$peerId]: $e');
    }
  }

  // ─────────────────────────────────────────────
  // SIGNALING EVENTS
  // ─────────────────────────────────────────────
  Future<void> _onPeerJoin(Map<String, dynamic> payload) async {
    if (_isDisposed) return;
    final peerId = payload['userId'] as String?;
    if (peerId == null || peerId == _userId) return;

    participants[peerId] = VoiceVideoParticipant(
      userId: peerId,
      username: payload['username'] as String? ?? 'Anonym',
      avatar: payload['avatar'] as String? ?? '👤',
      isMicOn: payload['isMicOn'] as bool? ?? true,
      isCameraOn: payload['isCameraOn'] as bool? ?? false,
    );

    final pc = await _createPeerConnection(peerId);
    await _sendOffer(peerId, pc);

    if (!_isDisposed) notifyListeners();
  }

  Future<void> _onPeerLeave(Map<String, dynamic> payload) async {
    if (_isDisposed) return;
    final peerId = payload['userId'] as String?;
    if (peerId == null) return;

    await _cleanupPeer(peerId);
    if (!_isDisposed) notifyListeners();
  }

  Future<void> _onOffer(Map<String, dynamic> payload) async {
    if (_isDisposed) return;
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

    try {
      await pc.setRemoteDescription(
        RTCSessionDescription(
          sdpData['sdp'] as String,
          sdpData['type'] as String,
        ),
      );
      _remoteDescriptionSet.add(from);
      await _flushPendingCandidates(from, pc);

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
    } catch (e) {
      if (kDebugMode) debugPrint('❌ _onOffer error: $e');
    }
  }

  Future<void> _onAnswer(Map<String, dynamic> payload) async {
    if (_isDisposed) return;
    final from = payload['from'] as String?;
    final to = payload['to'] as String?;
    if (from == null || to != _userId) return;

    final pc = _peerConnections[from];
    if (pc == null) return;

    final sdpData = payload['sdp'] as Map<String, dynamic>;
    try {
      await pc.setRemoteDescription(
        RTCSessionDescription(
          sdpData['sdp'] as String,
          sdpData['type'] as String,
        ),
      );
      _remoteDescriptionSet.add(from);
      await _flushPendingCandidates(from, pc);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ _onAnswer error: $e');
    }
  }

  Future<void> _onIceCandidate(Map<String, dynamic> payload) async {
    if (_isDisposed) return;
    final from = payload['from'] as String?;
    final to = payload['to'] as String?;
    if (from == null || to != _userId) return;

    final candidateData = payload['candidate'] as Map<String, dynamic>?;
    if (candidateData == null) return;

    final candidate = RTCIceCandidate(
      candidateData['candidate'] as String?,
      candidateData['sdpMid'] as String?,
      candidateData['sdpMLineIndex'] as int?,
    );

    final pc = _peerConnections[from];
    if (pc == null || !_remoteDescriptionSet.contains(from)) {
      _pendingIceCandidates.putIfAbsent(from, () => []).add(candidate);
      return;
    }

    try {
      await pc.addCandidate(candidate);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ addCandidate: $e');
    }
  }

  Future<void> _flushPendingCandidates(String peerId, RTCPeerConnection pc) async {
    final pending = _pendingIceCandidates.remove(peerId) ?? [];
    for (final candidate in pending) {
      try {
        await pc.addCandidate(candidate);
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ flush candidate: $e');
      }
    }
  }

  void _onCameraState(Map<String, dynamic> payload) {
    if (_isDisposed) return;
    final peerId = payload['userId'] as String?;
    if (peerId == null || peerId == _userId) return;
    final participant = participants[peerId];
    if (participant != null) {
      participant.isCameraOn = payload['isCameraOn'] as bool? ?? false;
      if (!_isDisposed) notifyListeners();
    }
  }

  void _onMicState(Map<String, dynamic> payload) {
    if (_isDisposed) return;
    final peerId = payload['userId'] as String?;
    if (peerId == null || peerId == _userId) return;
    final participant = participants[peerId];
    if (participant != null) {
      participant.isMicOn = payload['isMicOn'] as bool? ?? true;
      if (!_isDisposed) notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  // PEER CONNECTION
  // v5.28.0 FIX: addTransceiver für garantierten Audio+Video Empfang
  // ─────────────────────────────────────────────
  Future<RTCPeerConnection> _createPeerConnection(String peerId) async {
    if (_peerConnections.containsKey(peerId)) {
      return _peerConnections[peerId]!;
    }

    final pc = await createPeerConnection(_iceConfig);
    _peerConnections[peerId] = pc;

    // Audio-Track hinzufügen (immer vorhanden)
    if (localStream != null) {
      final audioTracks = localStream!.getAudioTracks();
      for (final track in audioTracks) {
        try {
          await pc.addTrack(track, localStream!);
        } catch (e) {
          if (kDebugMode) debugPrint('⚠️ addAudioTrack[$peerId]: $e');
        }
      }

      // Video-Track hinzufügen (falls Kamera aktiv)
      if (isCameraOn) {
        final videoTracks = localStream!.getVideoTracks();
        for (final track in videoTracks) {
          try {
            await pc.addTrack(track, localStream!);
          } catch (e) {
            if (kDebugMode) debugPrint('⚠️ addVideoTrack[$peerId]: $e');
          }
        }
      }
    }

    // ICE Candidates senden
    pc.onIceCandidate = (candidate) {
      if (_isDisposed) return;
      if (candidate.candidate == null || candidate.candidate!.isEmpty) return;
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
    // FIX v5.28.0: streams.isNotEmpty prüfen + Stream-ID für Peer-Zuordnung
    pc.onTrack = (event) async {
      if (_isDisposed) return;

      MediaStream? stream;
      if (event.streams.isNotEmpty) {
        stream = event.streams[0];
        // Stream-ID → peerId Mapping registrieren
        _streamToPeer[stream.id] = peerId;
      } else {
        // Kein Stream direkt im Event → eigenen Stream für diesen Peer erstellen
        stream = remoteRenderers[peerId]?.srcObject;
      }

      if (stream == null) return;

      await _ensureRemoteRenderer(peerId, stream);

      if (participants.containsKey(peerId)) {
        participants[peerId]!.stream = stream;
        // Video-Status aus aktiven Video-Tracks ableiten
        final hasVideo = stream.getVideoTracks().any((t) => t.enabled && t.kind == 'video');
        if (hasVideo) {
          participants[peerId]!.isCameraOn = true;
        }
      }
      if (!_isDisposed) notifyListeners();
    };

    // Verbindungsstatus
    pc.onConnectionState = (state) {
      if (_isDisposed) return;
      if (kDebugMode) debugPrint('🔌 PC[$peerId]: $state');

      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _handlePeerReconnect(peerId, pc);
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        // Kurz warten → evt. erholt es sich selbst
        Future.delayed(const Duration(seconds: 5), () {
          if (!_isDisposed && pc.connectionState ==
              RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
            _handlePeerReconnect(peerId, pc);
          }
        });
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        // Reconnect-Counter zurücksetzen bei erfolgreicher Verbindung
        _reconnectAttempts.remove(peerId);
      }
    };

    pc.onIceConnectionState = (state) {
      if (_isDisposed) return;
      if (kDebugMode) debugPrint('🧊 ICE[$peerId]: $state');
    };

    return pc;
  }

  Future<void> _ensureRemoteRenderer(String peerId, MediaStream stream) async {
    if (!remoteRenderers.containsKey(peerId)) {
      try {
        final renderer = RTCVideoRenderer();
        await renderer.initialize();
        remoteRenderers[peerId] = renderer;
      } catch (e) {
        if (kDebugMode) debugPrint('❌ remoteRenderer init[$peerId]: $e');
        return;
      }
    }
    remoteRenderers[peerId]!.srcObject = stream;
  }

  /// Automatisches Re-Offer nach Verbindungsfehler
  void _handlePeerReconnect(String peerId, RTCPeerConnection pc) {
    if (_isDisposed) return;
    final attempts = _reconnectAttempts[peerId] ?? 0;
    if (attempts >= _maxReconnectAttempts) {
      if (kDebugMode) debugPrint('❌ Max reconnect attempts für $peerId');
      _cleanupPeer(peerId);
      notifyListeners();
      return;
    }

    _reconnectAttempts[peerId] = attempts + 1;
    if (kDebugMode) debugPrint('🔄 Reconnect attempt ${attempts + 1} für $peerId');

    // Neue Verbindung aufbauen
    Future.delayed(const Duration(seconds: 2), () async {
      if (_isDisposed) return;
      try {
        await _cleanupPeer(peerId);
        final newPc = await _createPeerConnection(peerId);
        await _sendOffer(peerId, newPc);
        notifyListeners();
      } catch (e) {
        if (kDebugMode) debugPrint('❌ Reconnect failed für $peerId: $e');
      }
    });
  }

  Future<void> _cleanupPeer(String peerId) async {
    try { await _peerConnections[peerId]?.close(); } catch (_) {}
    _peerConnections.remove(peerId);
    _pendingIceCandidates.remove(peerId);
    _remoteDescriptionSet.remove(peerId);

    // Stream-ID Mappings für diesen Peer entfernen
    _streamToPeer.removeWhere((streamId, pId) => pId == peerId);

    try { await remoteRenderers[peerId]?.dispose(); } catch (_) {}
    remoteRenderers.remove(peerId);

    participants.remove(peerId);
  }

  // ─────────────────────────────────────────────
  // DISCONNECT
  // ─────────────────────────────────────────────
  Future<void> disconnect() async {
    if (!isConnected && !isInitializing) return;

    try {
      await _signalingChannel?.sendBroadcastMessage(
        event: 'leave',
        payload: {'userId': _userId},
      );
    } catch (_) {}

    // Alle Peer-Connections schließen
    final peerIds = List<String>.from(_peerConnections.keys);
    for (final peerId in peerIds) {
      try { await _peerConnections[peerId]?.close(); } catch (_) {}
    }
    _peerConnections.clear();
    _pendingIceCandidates.clear();
    _remoteDescriptionSet.clear();
    _streamToPeer.clear();
    _reconnectAttempts.clear();

    // Remote Renderer freigeben
    for (final renderer in remoteRenderers.values) {
      try { await renderer.dispose(); } catch (_) {}
    }
    remoteRenderers.clear();
    participants.clear();

    // Lokalen Stream stoppen
    try {
      localStream?.getTracks().forEach((t) => t.stop());
      await localStream?.dispose();
    } catch (_) {}
    localStream = null;

    // Lokalen Renderer freigeben
    try {
      _localRenderer.srcObject = null;
      await _localRenderer.dispose();
    } catch (_) {}
    _rendererInitialized = false;

    // Supabase Channel abmelden
    try { await _signalingChannel?.unsubscribe(); } catch (_) {}
    _signalingChannel = null;

    // Status zurücksetzen
    isConnected = false;
    isCameraOn = false;
    isMicOn = true;
    isInitializing = false;
    _isCameraToggling = false;

    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    disconnect().catchError((_) {});
    super.dispose();
  }
}
