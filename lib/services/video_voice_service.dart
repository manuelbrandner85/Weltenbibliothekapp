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
/// BUGFIXES v5.24.0:
/// - Kamerawechsel (switchCamera) vollständig repariert: neuen Track erstellen
///   statt Helper.switchCamera (zu instabil auf Android/iOS)
/// - toggleCamera: Track wird korrekt ersetzt statt nur geaddet/gestoppt
/// - Peer-Renegotiation nach Kameraaktion (neues Offer senden)
/// - localRenderer wird nach jedem Track-Wechsel neu gesetzt
/// - Fehlerbehandlung: _isCameraToggling Flag verhindert parallele Aufrufe
/// - disconnect() korrekt: Guards gegen Double-Dispose
/// - isInitializing Guard verhindert Mehrfach-Init
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
  bool _isCameraToggling = false; // Guard gegen parallele Kamera-Aktionen
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
      await localRenderer.initialize();

      // Nur Mikrofon beim Start – Kamera optional
      localStream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
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
  // KAMERA TOGGLE (komplett überarbeitet)
  // ─────────────────────────────────────────────

  Future<bool> toggleCamera() async {
    // Guard: keine parallelen Kamera-Aktionen
    if (_isCameraToggling || _isDisposed) return isCameraOn;
    _isCameraToggling = true;

    try {
      if (!isCameraOn) {
        // ── KAMERA EINSCHALTEN ─────────────────────────────────────
        final videoStream = await navigator.mediaDevices.getUserMedia({
          'audio': false,
          'video': {
            'facingMode': isFrontCamera ? 'user' : 'environment',
            'width': {'ideal': 1280, 'max': 1920},
            'height': {'ideal': 720, 'max': 1080},
            'frameRate': {'ideal': 30, 'max': 60},
          },
        });

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

        // Renderer aktualisieren
        localRenderer.srcObject = null;
        localRenderer.srcObject = localStream;

        // Allen Peers den neuen Video-Track senden (Renegotiation)
        for (final entry in _peerConnections.entries) {
          final peerId = entry.key;
          final pc = entry.value;
          try {
            final senders = await pc.senders;
            final videoSender = senders.cast<RTCRtpSender?>()
                .firstWhere((s) => s?.track?.kind == 'video', orElse: () => null);

            if (videoSender != null) {
              // Vorhandenen Sender ersetzen
              await videoSender.replaceTrack(videoTrack);
            } else {
              // Neuen Track hinzufügen
              await pc.addTrack(videoTrack, localStream!);
              // Renegotiation notwendig
              await _sendRenegotiationOffer(peerId, pc);
            }
          } catch (e) {
            if (kDebugMode) debugPrint('⚠️ addTrack[$peerId] error: $e');
          }
        }

        isCameraOn = true;
      } else {
        // ── KAMERA AUSSCHALTEN ────────────────────────────────────
        final videoTracks = localStream?.getVideoTracks() ?? [];
        for (final track in videoTracks) {
          track.enabled = false;
          track.stop();
          await localStream?.removeTrack(track);
        }

        // Renderer ohne Video-Track aktualisieren
        localRenderer.srcObject = null;
        localRenderer.srcObject = localStream;

        // Peers informieren: Video-Sender auf null setzen
        for (final entry in _peerConnections.entries) {
          final pc = entry.value;
          try {
            final senders = await pc.senders;
            final videoSender = senders.cast<RTCRtpSender?>()
                .firstWhere((s) => s?.track?.kind == 'video', orElse: () => null);
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
      // Kamera-Status zurücksetzen bei Fehler
      isCameraOn = false;
      if (!_isDisposed) notifyListeners();
      return false;
    } finally {
      _isCameraToggling = false;
    }
  }

  // ─────────────────────────────────────────────
  // MIC TOGGLE
  // ─────────────────────────────────────────────

  void toggleMicrophone() {
    if (_isDisposed) return;
    isMicOn = !isMicOn;
    localStream?.getAudioTracks().forEach((t) => t.enabled = isMicOn);
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // KAMERA WECHSELN (vollständig überarbeitet)
  // ─────────────────────────────────────────────

  Future<void> switchCamera() async {
    if (!isCameraOn || _isCameraToggling || _isDisposed) return;
    _isCameraToggling = true;

    try {
      isFrontCamera = !isFrontCamera;

      // Neuen Stream mit der gewünschten Kamera anfordern
      final newStream = await navigator.mediaDevices.getUserMedia({
        'audio': false,
        'video': {
          'facingMode': isFrontCamera ? 'user' : 'environment',
          'width': {'ideal': 1280, 'max': 1920},
          'height': {'ideal': 720, 'max': 1080},
          'frameRate': {'ideal': 30},
        },
      });

      final newVideoTracks = newStream.getVideoTracks();
      if (newVideoTracks.isEmpty) {
        // Rückgängig machen bei Fehler
        isFrontCamera = !isFrontCamera;
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

      // Renderer neu binden (erzwingt UI-Refresh)
      localRenderer.srcObject = null;
      await Future.delayed(const Duration(milliseconds: 50));
      localRenderer.srcObject = localStream;

      // Peers aktualisieren: Track ersetzen (kein Renegotiation nötig)
      for (final pc in _peerConnections.values) {
        try {
          final senders = await pc.senders;
          final videoSender = senders.cast<RTCRtpSender?>()
              .firstWhere((s) => s?.track?.kind == 'video', orElse: () => null);
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
      // Kamerafacing zurücksetzen bei Fehler
      isFrontCamera = !isFrontCamera;
    } finally {
      _isCameraToggling = false;
    }
  }

  // ─────────────────────────────────────────────
  // RENEGOTIATION HELPER
  // ─────────────────────────────────────────────

  Future<void> _sendRenegotiationOffer(String peerId, RTCPeerConnection pc) async {
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

    // Peer-Connection erstellen und Offer senden
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

    // Wenn Renegotiation: bestehende Connection verwenden
    final isRenegotiation = payload['isRenegotiation'] as bool? ?? false;

    try {
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
        RTCSessionDescription(sdpData['sdp'] as String, sdpData['type'] as String),
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

    // ICE Candidates
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
      // Bei Fehler: Peer entfernen
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _handlePeerDisconnect(peerId);
      }
    };

    // ICE-Verbindungsstatus
    pc.onIceConnectionState = (state) {
      if (_isDisposed) return;
      if (kDebugMode) debugPrint('🧊 ICE[$peerId]: $state');
    };

    return pc;
  }

  void _handlePeerDisconnect(String peerId) {
    if (_isDisposed) return;
    // Nach kurzer Wartezeit Peer entfernen (falls keine Reconnection)
    Future.delayed(const Duration(seconds: 5), () {
      if (_isDisposed) return;
      final pc = _peerConnections[peerId];
      if (pc?.connectionState == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          pc?.connectionState == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
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
  // ─────────────────────────────────────────────

  Future<void> disconnect() async {
    if (!isConnected && !isInitializing) return;

    try {
      await _signalingChannel?.sendBroadcastMessage(
        event: 'leave',
        payload: {'userId': _userId},
      );
    } catch (_) {}

    for (final pc in _peerConnections.values) {
      try { await pc.close(); } catch (_) {}
    }
    _peerConnections.clear();

    for (final renderer in remoteRenderers.values) {
      try { await renderer.dispose(); } catch (_) {}
    }
    remoteRenderers.clear();
    participants.clear();

    try {
      localStream?.getTracks().forEach((t) => t.stop());
      await localStream?.dispose();
    } catch (_) {}
    localStream = null;

    try {
      localRenderer.srcObject = null;
      await localRenderer.dispose();
    } catch (_) {}

    try {
      await _signalingChannel?.unsubscribe();
    } catch (_) {}
    _signalingChannel = null;

    isConnected = false;
    isCameraOn = false;
    isMicOn = true;
    isInitializing = false;

    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    disconnect();
    super.dispose();
  }
}
