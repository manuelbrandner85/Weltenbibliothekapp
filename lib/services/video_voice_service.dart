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
/// BUGFIXES v5.26.0:
/// - localRenderer: Nach disconnect() wird Renderer disposed + _rendererInitialized=false
///   → beim nächsten initialize() wird er neu erstellt (kein "already disposed" Crash)
/// - Kamera-Constraints: 640×480 (4:3) statt 1280×720 (16:9)
///   → verhindert falschen Zoom/Crop-Effekt auf Mobile (Face zu nah/abgeschnitten)
/// - _buildVideoConstraints(): zentrale Hilfsmethode für konsistente Constraints
/// - disconnect(): setzt _isDisposed NICHT – Service bleibt wiederverwendbar
/// - disconnect(): _isCameraToggling zurücksetzen (verhindert Deadlock nach Reconnect)
/// - BUGFIXES v5.24.0 beibehalten: Guard _isCameraToggling, switchCamera mit neuem Track,
///   Renegotiation, Renderer-Reset, Double-Dispose-Schutz, Init-Guard
class VideoVoiceService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  // Lokaler Stream
  MediaStream? localStream;

  // BUG-FIX v5.26.0: _localRenderer als privates Feld,
  // wird nach dispose() über _rendererInitialized=false als "neu zu erstellen" markiert
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer get localRenderer => _localRenderer;

  bool _rendererInitialized = false;

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
  bool _isCameraToggling = false;
  bool _isDisposed = false;

  String? _userId;

  RealtimeChannel? _signalingChannel;

  static const Map<String, dynamic> _iceConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun.stunprotocol.org:3478'},
    ],
    'sdpSemantics': 'unified-plan',
    'bundlePolicy': 'max-bundle',
    'rtcpMuxPolicy': 'require',
  };

  // ─────────────────────────────────────────────
  // KAMERA CONSTRAINTS (zentrale Hilfsmethode)
  // BUG-FIX v5.26.0:
  // Vorher: 1280×720 (16:9) → mobiles Bild wird intern auf 4:3-Sensor gecroppt
  //         → Gesicht erscheint zu nah/abgeschnitten im Preview
  // Jetzt:  640×480 (4:3) = natives Format der meisten Smartphone-Kameras
  //         → kein Crop, korrektes Seitenverhältnis, natürlicher Zoom
  // ─────────────────────────────────────────────

  Map<String, dynamic> _buildVideoConstraints({bool front = true}) {
    return {
      'audio': false,
      'video': {
        'facingMode': front ? 'user' : 'environment',
        'width': {'ideal': 640, 'max': 1280},
        'height': {'ideal': 480, 'max': 960},
        'frameRate': {'ideal': 30, 'max': 30},
        'aspectRatio': {'ideal': 1.3333},
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
    notifyListeners();

    try {
      // BUG-FIX v5.26.0: Renderer neu erstellen wenn nach disconnect() disposed
      if (!_rendererInitialized) {
        _localRenderer = RTCVideoRenderer();
        await _localRenderer.initialize();
        _rendererInitialized = true;
      }

      // Nur Mikrofon beim Start – Kamera ist optional
      localStream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      });
      _localRenderer.srcObject = localStream;

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
          )
          .onBroadcast(
            event: 'renegotiate',
            callback: (payload) => _onRenegotiateRequest(payload),
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
      if (!_isDisposed) notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  // KAMERA EIN/AUS
  // BUG-FIX v5.26.0: _buildVideoConstraints() für korrektes Aspect Ratio
  // ─────────────────────────────────────────────

  Future<bool> toggleCamera() async {
    if (_isCameraToggling || _isDisposed) return isCameraOn;
    _isCameraToggling = true;

    try {
      if (!isCameraOn) {
        // ── KAMERA EINSCHALTEN ──────────────────────────────────
        // BUG-FIX v5.26.0: Korrekte Constraints → kein Zoom/Crop
        final videoStream = await navigator.mediaDevices.getUserMedia(
          _buildVideoConstraints(front: isFrontCamera),
        );

        final videoTracks = videoStream.getVideoTracks();
        if (videoTracks.isEmpty) {
          throw Exception('Keine Video-Tracks verfügbar');
        }

        final videoTrack = videoTracks.first;

        // Alten Video-Track entfernen (falls noch vorhanden)
        final oldTracks = localStream?.getVideoTracks() ?? [];
        for (final old in oldTracks) {
          old.stop();
          await localStream?.removeTrack(old);
        }

        // Neuen Track hinzufügen
        await localStream?.addTrack(videoTrack);

        // Renderer aktualisieren – srcObject reset erzwingt UI-Refresh
        _localRenderer.srcObject = null;
        await Future.delayed(const Duration(milliseconds: 30));
        _localRenderer.srcObject = localStream;

        // Allen Peers den neuen Video-Track senden (Renegotiation)
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
              await pc.addTrack(videoTrack, localStream!);
              await _sendRenegotiationOffer(peerId, pc);
            }
          } catch (e) {
            if (kDebugMode) debugPrint('⚠️ addTrack[$peerId] error: $e');
          }
        }

        isCameraOn = true;
      } else {
        // ── KAMERA AUSSCHALTEN ───────────────────────────────────
        final videoTracks = localStream?.getVideoTracks() ?? [];
        for (final track in videoTracks) {
          track.enabled = false;
          track.stop();
          await localStream?.removeTrack(track);
        }

        _localRenderer.srcObject = null;
        _localRenderer.srcObject = localStream;

        for (final entry in _peerConnections.entries) {
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
              await videoSender.replaceTrack(null);
            }
          } catch (e) {
            if (kDebugMode) debugPrint('⚠️ removeTrack error: $e');
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
  // MIKROFON EIN/AUS
  // ─────────────────────────────────────────────

  void toggleMicrophone() {
    if (_isDisposed) return;
    isMicOn = !isMicOn;
    localStream?.getAudioTracks().forEach((t) => t.enabled = isMicOn);
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // KAMERA WECHSELN (vorne ↔ hinten)
  // BUG-FIX v5.26.0: _buildVideoConstraints() für korrektes Aspect Ratio
  // ─────────────────────────────────────────────

  Future<void> switchCamera() async {
    if (!isCameraOn || _isCameraToggling || _isDisposed) return;
    _isCameraToggling = true;

    try {
      isFrontCamera = !isFrontCamera;

      // BUG-FIX v5.26.0: Neuen Stream mit korrekter Constraint-Methode (4:3)
      final newStream = await navigator.mediaDevices.getUserMedia(
        _buildVideoConstraints(front: isFrontCamera),
      );

      final newVideoTracks = newStream.getVideoTracks();
      if (newVideoTracks.isEmpty) {
        isFrontCamera = !isFrontCamera; // Rückgängig bei Fehler
        return;
      }

      final newTrack = newVideoTracks.first;

      // Alten Video-Track stoppen & entfernen
      final oldTracks = localStream?.getVideoTracks() ?? [];
      for (final old in oldTracks) {
        old.stop();
        await localStream?.removeTrack(old);
      }

      // Neuen Track in bestehenden Stream einfügen
      await localStream?.addTrack(newTrack);

      // Renderer neu binden → erzwingt UI-Refresh
      _localRenderer.srcObject = null;
      await Future.delayed(const Duration(milliseconds: 50));
      _localRenderer.srcObject = localStream;

      // Peers: Track ersetzen (kein neues SDP-Offer nötig)
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
          if (kDebugMode) debugPrint('⚠️ switchCamera replaceTrack error: $e');
        }
      }

      if (!_isDisposed) notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ switchCamera error: $e');
      isFrontCamera = !isFrontCamera; // Kamerafacing zurücksetzen
    } finally {
      _isCameraToggling = false;
    }
  }

  // ─────────────────────────────────────────────
  // RENEGOTIATION HELPER
  // ─────────────────────────────────────────────

  Future<void> _sendRenegotiationOffer(
      String peerId, RTCPeerConnection pc) async {
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
          'isRenegotiation': true,
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ renegotiation error: $e');
    }
  }

  // ─────────────────────────────────────────────
  // SIGNALING EVENTS
  // ─────────────────────────────────────────────

  Future<void> _onPeerJoin(Map<String, dynamic> payload) async {
    if (_isDisposed) return;
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

    final pc = await _createPeerConnection(peerId);
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
      },
    );

    if (!_isDisposed) notifyListeners();
  }

  Future<void> _onPeerLeave(Map<String, dynamic> payload) async {
    if (_isDisposed) return;
    final peerId = payload['userId'] as String?;
    if (peerId == null) return;

    try {
      await _peerConnections[peerId]?.close();
    } catch (_) {}
    _peerConnections.remove(peerId);

    try {
      await remoteRenderers[peerId]?.dispose();
    } catch (_) {}
    remoteRenderers.remove(peerId);

    participants.remove(peerId);
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
    final isRenegotiation = payload['isRenegotiation'] as bool? ?? false;

    try {
      await pc.setRemoteDescription(
        RTCSessionDescription(
          sdpData['sdp'] as String,
          sdpData['type'] as String,
        ),
      );

      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);

      await _signalingChannel?.sendBroadcastMessage(
        event: 'answer',
        payload: {
          'from': _userId,
          'to': from,
          'sdp': {'type': answer.type, 'sdp': answer.sdp},
          'isRenegotiation': isRenegotiation,
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
    } catch (e) {
      if (kDebugMode) debugPrint('❌ _onAnswer error: $e');
    }
  }

  Future<void> _onIceCandidate(Map<String, dynamic> payload) async {
    if (_isDisposed) return;
    final from = payload['from'] as String?;
    final to = payload['to'] as String?;
    if (from == null || to != _userId) return;

    final pc = _peerConnections[from];
    if (pc == null) return;

    final candidateData = payload['candidate'] as Map<String, dynamic>?;
    if (candidateData == null) return;

    try {
      await pc.addCandidate(RTCIceCandidate(
        candidateData['candidate'] as String?,
        candidateData['sdpMid'] as String?,
        candidateData['sdpMLineIndex'] as int?,
      ));
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ addCandidate error: $e');
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

  Future<void> _onRenegotiateRequest(Map<String, dynamic> payload) async {
    if (_isDisposed) return;
    final from = payload['from'] as String?;
    if (from == null || from == _userId) return;
    // Wird durch _onOffer automatisch behandelt
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
    if (localStream != null) {
      for (final track in localStream!.getTracks()) {
        try {
          await pc.addTrack(track, localStream!);
        } catch (e) {
          if (kDebugMode) debugPrint('⚠️ addTrack error: $e');
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
    pc.onTrack = (event) async {
      if (_isDisposed) return;
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
            stream.getVideoTracks().any((t) => t.enabled);
      }
      if (!_isDisposed) notifyListeners();
    };

    // Verbindungsstatus
    pc.onConnectionState = (state) {
      if (_isDisposed) return;
      if (kDebugMode) debugPrint('🔌 PeerConnection[$peerId]: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _handlePeerDisconnect(peerId);
      }
    };

    pc.onIceConnectionState = (state) {
      if (_isDisposed) return;
      if (kDebugMode) debugPrint('🧊 ICE[$peerId]: $state');
    };

    return pc;
  }

  void _handlePeerDisconnect(String peerId) {
    if (_isDisposed) return;
    Future.delayed(const Duration(seconds: 5), () {
      if (_isDisposed) return;
      final pc = _peerConnections[peerId];
      if (pc?.connectionState ==
              RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          pc?.connectionState ==
              RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        participants.remove(peerId);
        _peerConnections.remove(peerId);
        remoteRenderers[peerId]?.dispose();
        remoteRenderers.remove(peerId);
        if (!_isDisposed) notifyListeners();
      }
    });
  }

  // ─────────────────────────────────────────────
  // DISCONNECT
  // BUG-FIX v5.26.0:
  // - _isDisposed wird NICHT gesetzt → Service bleibt nach disconnect() wiederverwendbar
  // - _rendererInitialized = false → nächstes initialize() erstellt frischen Renderer
  // - _isCameraToggling zurücksetzen → kein Deadlock nach Reconnect
  // ─────────────────────────────────────────────

  Future<void> disconnect() async {
    if (!isConnected && !isInitializing) return;

    // Leave-Broadcast senden
    try {
      await _signalingChannel?.sendBroadcastMessage(
        event: 'leave',
        payload: {'userId': _userId},
      );
    } catch (_) {}

    // Alle Peer-Connections schließen
    for (final pc in _peerConnections.values) {
      try {
        await pc.close();
      } catch (_) {}
    }
    _peerConnections.clear();

    // Remote Renderer freigeben
    for (final renderer in remoteRenderers.values) {
      try {
        await renderer.dispose();
      } catch (_) {}
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
      // BUG-FIX v5.26.0: als "neu zu erstellen" markieren
      _rendererInitialized = false;
    } catch (_) {
      _rendererInitialized = false;
    }

    // Supabase Channel abmelden
    try {
      await _signalingChannel?.unsubscribe();
    } catch (_) {}
    _signalingChannel = null;

    // Status zurücksetzen
    isConnected = false;
    isCameraOn = false;
    isMicOn = true;
    isInitializing = false;
    // BUG-FIX v5.26.0: Guard zurücksetzen → kein Deadlock nach Reconnect
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
