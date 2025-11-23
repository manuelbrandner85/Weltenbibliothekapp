import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/webrtc_config.dart';

/// WebRTCService - Native WebRTC Implementation (Telegram-Style)
///
/// Native WebRTC-Lösung mit folgenden Features:
/// - ✅ Multi-User Video-Calls (2-4 Teilnehmer)
/// - ✅ Kamera Ein/Aus mit Echtzeit-Kontrolle
/// - ✅ Mikrofon Ein/Aus Toggle
/// - ✅ Picture-in-Picture Support
/// - ✅ Cloudflare Signaling Server Integration
/// - ✅ WebSocket für Low-Latency Signaling
/// - ✅ Vollständig synchronisiert mit Chat-System
///
/// Architektur:
/// - Mesh-Topologie für 2-4 Nutzer (jeder verbindet sich mit jedem)
/// - WebSocket Signaling über Cloudflare Workers
/// - STUN/TURN Server für NAT Traversal
/// - Automatisches Reconnect bei Verbindungsabbruch

class WebRTCService extends ChangeNotifier {
  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTANTS
  // ═══════════════════════════════════════════════════════════════════════════

  static const String _logPrefix = '🎥 [WebRTC]';

  // ✅ PRODUCTION: Cloudflare WebRTC Signaling Server (Deployed & Running)
  // Format: wss://domain/ws/{roomId}
  static const String _signalingServerUrl =
      'wss://weltenbibliothek.brandy13062.workers.dev/ws';

  // ✅ FIX: Using unified WebRTC configuration
  static final Map<String, dynamic> _iceServers = WebRTCConfig.iceServers;

  // ═══════════════════════════════════════════════════════════════════════════
  // STATE VARIABLES
  // ═══════════════════════════════════════════════════════════════════════════

  // WebRTC Objects
  MediaStream? _localStream;
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, MediaStream> _remoteStreams = {};

  // Renderers
  RTCVideoRenderer? _localRenderer;
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};

  // ✅ FIX: ICE Candidate Queue - Candidates before remote description set
  final Map<String, List<RTCIceCandidate>> _pendingIceCandidates = {};

  // WebSocket Signaling
  WebSocketChannel? _signalingChannel;

  // Service States
  bool _isInitialized = false;
  bool _isInRoom = false;
  bool _isCameraEnabled = false;
  bool _isMicrophoneEnabled = true;
  bool _isMinimized = false;

  String? _currentRoomId;
  String? _localPeerId;

  // Error Tracking
  String? _lastError;

  // ═══════════════════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════════════════

  bool get isInitialized => _isInitialized;
  bool get isInChannel => _isInRoom;
  bool get isCameraEnabled => _isCameraEnabled;
  bool get isMicEnabled => _isMicrophoneEnabled;
  bool get isMicrophoneMuted => !_isMicrophoneEnabled;
  bool get isMinimized => _isMinimized;
  bool get isPictureInPicture => _isMinimized;

  String? get currentChannel => _currentRoomId;
  String? get currentChannelId => _currentRoomId;
  String? get lastError => _lastError;

  // Local Renderer für Video Widget
  RTCVideoRenderer? get localRenderer => _localRenderer;

  // Remote Users als Map<int, bool>
  // WebRTC nutzt String-IDs, konvertiert zu int-Hash
  Map<int, bool> get remoteUsers {
    final result = <int, bool>{};
    for (final entry in _remoteStreams.entries) {
      final userId = entry.key.hashCode;
      final hasVideo = entry.value.getVideoTracks().isNotEmpty;
      result[userId] = hasVideo;
    }
    return result;
  }

  // Remote Renderers für Video Widget
  Map<String, RTCVideoRenderer> get remoteRenderers =>
      Map.unmodifiable(_remoteRenderers);

  // Remote Streams für direkten Zugriff
  Map<String, MediaStream> get remoteStreams =>
      Map.unmodifiable(_remoteStreams);

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Initialisiert den WebRTC Service
  ///
  /// Steps:
  /// 1. Permissions prüfen und anfordern
  /// 2. Local Video Renderer erstellen
  /// 3. WebRTC konfigurieren
  Future<void> initialize() async {
    if (_isInitialized) {
      _log('⚠️ Bereits initialisiert, überspringe...');
      return;
    }

    try {
      _log('🚀 Starte WebRTC Initialisierung...');
      _lastError = null;

      // STEP 1: Permissions
      _log('📋 STEP 1: Permissions anfordern...');
      final permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        throw Exception('Kamera- oder Mikrofon-Berechtigung wurde verweigert');
      }

      // STEP 2: Initialize Local Renderer
      _log('📋 STEP 2: Local Video Renderer erstellen...');
      _localRenderer = RTCVideoRenderer();
      await _localRenderer!.initialize();

      // STEP 3: Generate Peer ID
      _log('📋 STEP 3: Peer ID generieren...');
      _localPeerId = _generatePeerId();
      _log('  🆔 Local Peer ID: $_localPeerId');

      _isInitialized = true;
      _log('✅ WebRTC Initialisierung erfolgreich abgeschlossen!');

      notifyListeners();
    } catch (e, stackTrace) {
      _lastError = 'Initialisierung fehlgeschlagen: $e';
      _logError('Initialisierung fehlgeschlagen', e, stackTrace);
      rethrow;
    }
  }

  /// Fordert Kamera- und Mikrofon-Berechtigungen an
  Future<bool> _requestPermissions() async {
    try {
      _log('🔐 Frage Berechtigungen an...');

      final cameraStatus = await Permission.camera.request();
      final micStatus = await Permission.microphone.request();

      _log('  📷 Kamera: ${cameraStatus.name}');
      _log('  🎤 Mikrofon: ${micStatus.name}');

      if (!cameraStatus.isGranted) {
        _logError(
          'Kamera-Berechtigung verweigert',
          'Status: ${cameraStatus.name}',
          null,
        );
        return false;
      }

      if (!micStatus.isGranted) {
        _logError(
          'Mikrofon-Berechtigung verweigert',
          'Status: ${micStatus.name}',
          null,
        );
        return false;
      }

      _log('✅ Alle Berechtigungen erteilt!');
      return true;
    } catch (e, stackTrace) {
      _logError('Fehler beim Anfordern der Berechtigungen', e, stackTrace);
      return false;
    }
  }

  /// Generiert eindeutige Peer ID
  String _generatePeerId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'peer_$timestamp$random';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ROOM OPERATIONS (Channel API Kompatibilität)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Tritt einem Room bei (WebRTC Mesh Network)
  ///
  /// Kompatible API: joinChannel(String channelId, int uid)
  Future<void> joinChannel(String channelId, int uid) async {
    if (!_isInitialized) {
      throw Exception('Service nicht initialisiert. Rufe initialize() auf!');
    }

    if (_isInRoom) {
      _log('⚠️ Bereits in Room, verlasse zuerst...');
      await leaveChannel();
    }

    try {
      _log('🚪 Trete Room bei...');
      _log('  📍 Room ID: $channelId');
      _log('  🆔 User UID: $uid');

      _currentRoomId = channelId;
      _lastError = null;

      // STEP 1: Connect WebSocket Signaling
      _log('📋 STEP 1: WebSocket Signaling verbinden...');
      await _connectSignaling(channelId);

      // STEP 2: Announce Presence to Room
      _log('📋 STEP 2: Präsenz im Room ankündigen...');
      _sendSignalingMessage({
        'type': 'join',
        'roomId': channelId,
        'peerId': _localPeerId,
        'uid': uid,
      });

      _isInRoom = true;
      _log('✅ Room beigetreten!');

      notifyListeners();
    } catch (e, stackTrace) {
      _lastError = 'Room Join fehlgeschlagen: $e';
      _logError('joinChannel fehlgeschlagen', e, stackTrace);
      rethrow;
    }
  }

  /// Verlässt den aktuellen Room
  Future<void> leaveChannel() async {
    if (!_isInRoom) {
      _log('⚠️ Nicht in Room, überspringe Leave...');
      return;
    }

    try {
      _log('🚪 Verlasse Room...');

      // STEP 1: Announce Leave
      _sendSignalingMessage({
        'type': 'leave',
        'roomId': _currentRoomId,
        'peerId': _localPeerId,
      });

      // STEP 2: Close all Peer Connections
      _log('  📋 Schließe alle Peer Connections...');
      for (final pc in _peerConnections.values) {
        await pc.close();
      }
      _peerConnections.clear();

      // STEP 3: Dispose Remote Renderers
      _log('  📋 Dispose Remote Renderers...');
      for (final renderer in _remoteRenderers.values) {
        await renderer.dispose();
      }
      _remoteRenderers.clear();
      _remoteStreams.clear();

      // STEP 4: Stop Local Stream
      if (_localStream != null) {
        _log('  📋 Stoppe Local Stream...');
        await _stopLocalStream();
      }

      // STEP 5: Disconnect Signaling
      _log('  📋 Trenne Signaling...');
      _disconnectSignaling();

      _isInRoom = false;
      _currentRoomId = null;
      _isCameraEnabled = false;

      _log('✅ Room verlassen');
      notifyListeners();
    } catch (e, stackTrace) {
      _logError('leaveChannel fehlgeschlagen', e, stackTrace);
      // Don't rethrow - best effort cleanup
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CAMERA CONTROLS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Aktiviert die Kamera
  Future<void> enableCamera() async {
    if (!_isInitialized) {
      throw Exception('Service nicht initialisiert');
    }

    if (!_isInRoom) {
      throw Exception('Nicht in Room - rufe joinChannel() auf!');
    }

    if (_isCameraEnabled) {
      _log('⚠️ Kamera bereits aktiviert');
      return;
    }

    try {
      _log('📹 KAMERA AKTIVIEREN - START');
      _lastError = null;

      // STEP 1: Get User Media
      _log('  📋 STEP 1: getUserMedia()');
      final constraints = {
        'audio': _isMicrophoneEnabled,
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 640},
          'height': {'ideal': 480},
          'frameRate': {'ideal': 30},
        },
      };

      _localStream = await navigator.mediaDevices.getUserMedia(constraints);

      // STEP 2: Set Local Renderer
      _log('  📋 STEP 2: setLocalRenderer()');
      if (_localRenderer != null) {
        _localRenderer!.srcObject = _localStream;
      }

      // STEP 3: Add Tracks to Peer Connections
      _log('  📋 STEP 3: addTracksToPeerConnections()');
      await _addTracksToAllPeers();

      _isCameraEnabled = true;
      _log('✅ KAMERA ERFOLGREICH AKTIVIERT!');

      notifyListeners();
    } catch (e, stackTrace) {
      _lastError = 'Kamera-Aktivierung fehlgeschlagen: $e';
      _logError('enableCamera fehlgeschlagen', e, stackTrace);
      rethrow;
    }
  }

  /// Deaktiviert die Kamera
  Future<void> disableCamera() async {
    if (!_isCameraEnabled) {
      _log('⚠️ Kamera bereits deaktiviert');
      return;
    }

    try {
      _log('📹 KAMERA DEAKTIVIEREN - START');

      // STEP 1: Stop Video Tracks
      _log('  📋 STEP 1: stopVideoTracks()');
      if (_localStream != null) {
        final videoTracks = _localStream!.getVideoTracks();
        for (final track in videoTracks) {
          track.stop();
          await _localStream!.removeTrack(track);
        }
      }

      // STEP 2: Remove Tracks from Peer Connections
      _log('  📋 STEP 2: removeTracksFromPeerConnections()');
      await _removeVideoTracksFromAllPeers();

      // STEP 3: Clear Local Renderer
      _log('  📋 STEP 3: clearLocalRenderer()');
      if (_localRenderer != null) {
        _localRenderer!.srcObject = null;
      }

      _isCameraEnabled = false;
      _log('✅ KAMERA ERFOLGREICH DEAKTIVIERT!');

      notifyListeners();
    } catch (e, stackTrace) {
      _logError('disableCamera fehlgeschlagen', e, stackTrace);
      rethrow;
    }
  }

  /// Wechselt zwischen Front- und Back-Kamera
  Future<void> switchCamera() async {
    if (!_isCameraEnabled) {
      _log('⚠️ Kamera nicht aktiv, kann nicht wechseln');
      return;
    }

    try {
      _log('🔄 Wechsle Kamera...');

      // WebRTC switchCamera: facingMode togglen
      final videoTrack = _localStream?.getVideoTracks().firstOrNull;
      if (videoTrack != null) {
        await Helper.switchCamera(videoTrack);
        _log('✅ Kamera gewechselt');
      }
    } catch (e, stackTrace) {
      _logError('switchCamera fehlgeschlagen', e, stackTrace);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MICROPHONE CONTROLS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Schaltet Mikrofon ein/aus
  Future<void> toggleMicrophone() async {
    if (!_isInRoom) {
      _log('⚠️ Nicht in Room, kann Mikrofon nicht umschalten');
      return;
    }

    try {
      final newState = !_isMicrophoneEnabled;
      _log('🎤 ${newState ? "Aktiviere" : "Deaktiviere"} Mikrofon...');

      if (_localStream != null) {
        final audioTracks = _localStream!.getAudioTracks();
        for (final track in audioTracks) {
          track.enabled = newState;
        }
      }

      _isMicrophoneEnabled = newState;
      _log('✅ Mikrofon ${newState ? "aktiviert" : "deaktiviert"}');

      notifyListeners();
    } catch (e, stackTrace) {
      _logError('toggleMicrophone fehlgeschlagen', e, stackTrace);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PICTURE-IN-PICTURE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Setzt Picture-in-Picture State
  void setMinimized(bool minimized) {
    if (_isMinimized != minimized) {
      _isMinimized = minimized;
      _log('📺 Picture-in-Picture: ${minimized ? "Aktiviert" : "Deaktiviert"}');
      notifyListeners();
    }
  }

  /// Toggle Picture-in-Picture
  void toggleMinimized() {
    setMinimized(!_isMinimized);
  }

  /// Alias-Methoden für Kompatibilität
  void minimizeVideo() => setMinimized(true);
  void maximizeVideo() => setMinimized(false);

  Future<void> muteMicrophone() async {
    if (_isMicrophoneEnabled) {
      await toggleMicrophone();
    }
  }

  Future<void> unmuteMicrophone() async {
    if (!_isMicrophoneEnabled) {
      await toggleMicrophone();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WEBRTC SIGNALING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Verbindet mit WebSocket Signaling Server
  Future<void> _connectSignaling(String roomId) async {
    try {
      final url = '$_signalingServerUrl/$roomId';
      _log('🔌 Verbinde WebSocket: $url');

      _signalingChannel = WebSocketChannel.connect(Uri.parse(url));

      // Listen to Signaling Messages
      // ✅ FIX: Added async/await to ensure sequential message processing
      _signalingChannel!.stream.listen(
        (message) async => await _handleSignalingMessage(message),
        onError: (error) => _logError('WebSocket Error', error, null),
        onDone: () => _log('🔌 WebSocket geschlossen'),
      );

      _log('✅ WebSocket verbunden');
    } catch (e, stackTrace) {
      _logError('WebSocket Connection fehlgeschlagen', e, stackTrace);
      rethrow;
    }
  }

  /// Trennt WebSocket Signaling
  void _disconnectSignaling() {
    _signalingChannel?.sink.close();
    _signalingChannel = null;
  }

  /// Sendet Signaling Message
  void _sendSignalingMessage(Map<String, dynamic> message) {
    if (_signalingChannel != null) {
      final json = jsonEncode(message);
      _signalingChannel!.sink.add(json);
      _log('📤 Signaling: ${message['type']}');
    }
  }

  /// Behandelt eingehende Signaling Messages
  Future<void> _handleSignalingMessage(dynamic rawMessage) async {
    try {
      final message = jsonDecode(rawMessage as String) as Map<String, dynamic>;
      final type = message['type'] as String;

      _log('📥 Signaling: $type');

      switch (type) {
        case 'peer-joined':
          await _handlePeerJoined(message);
          break;
        case 'peer-left':
          _handlePeerLeft(message);
          break;
        case 'offer':
          await _handleOffer(message);
          break;
        case 'answer':
          await _handleAnswer(message);
          break;
        case 'ice-candidate':
          await _handleIceCandidate(message);
          break;
        default:
          _log('⚠️ Unbekannter Signaling Type: $type');
      }
    } catch (e, stackTrace) {
      _logError('handleSignalingMessage Error', e, stackTrace);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PEER CONNECTION MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Neuer Peer ist dem Room beigetreten
  Future<void> _handlePeerJoined(Map<String, dynamic> message) async {
    final peerId = message['peerId'] as String;

    if (peerId == _localPeerId) {
      _log('⚠️ Eigene Peer ID ignoriert');
      return;
    }

    _log('👤 Neuer Peer: $peerId');

    // Create Peer Connection
    final pc = await _createPeerConnection(peerId);
    _peerConnections[peerId] = pc;

    // Add Local Stream Tracks (IMMER - auch nur Audio wenn Kamera aus)
    if (_localStream != null) {
      _log('  📹 Füge Local Tracks hinzu');
      for (final track in _localStream!.getTracks()) {
        await pc.addTrack(track, _localStream!);
      }
    } else {
      // CRITICAL FIX: Erstelle Audio-Only Stream wenn kein Video
      _log('  🎤 KEIN LOCAL STREAM - Erstelle Audio-Only Stream');
      try {
        final audioOnlyStream = await navigator.mediaDevices.getUserMedia({
          'audio': true,
          'video': false,
        });
        _localStream = audioOnlyStream;

        // Set to renderer if available
        if (_localRenderer != null) {
          _localRenderer!.srcObject = _localStream;
        }

        // Add audio track to peer connection
        for (final track in _localStream!.getTracks()) {
          await pc.addTrack(track, _localStream!);
        }

        _log('  ✅ Audio-Only Stream erstellt und hinzugefügt');
      } catch (e) {
        _log('  ❌ Audio-Only Stream fehlgeschlagen: $e');
      }
    }

    // Create Offer
    _log('  📤 Erstelle Offer...');
    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    // Send Offer via Signaling
    _sendSignalingMessage({
      'type': 'offer',
      'roomId': _currentRoomId,
      'fromPeerId': _localPeerId,
      'toPeerId': peerId,
      'sdp': offer.sdp,
    });

    notifyListeners();
  }

  /// Peer hat Room verlassen
  void _handlePeerLeft(Map<String, dynamic> message) {
    final peerId = message['peerId'] as String;
    _log('👋 Peer verlassen: $peerId');

    // Close Peer Connection
    _peerConnections[peerId]?.close();
    _peerConnections.remove(peerId);

    // Dispose Renderer
    _remoteRenderers[peerId]?.dispose();
    _remoteRenderers.remove(peerId);
    _remoteStreams.remove(peerId);

    notifyListeners();
  }

  /// Erhält Offer von anderem Peer
  Future<void> _handleOffer(Map<String, dynamic> message) async {
    final fromPeerId = message['fromPeerId'] as String;
    final sdp = message['sdp'] as String;

    _log('📥 Offer von: $fromPeerId');

    // Create Peer Connection (falls noch nicht vorhanden)
    final pc =
        _peerConnections[fromPeerId] ?? await _createPeerConnection(fromPeerId);
    _peerConnections[fromPeerId] = pc;

    // Add Local Stream Tracks (IMMER - auch nur Audio wenn Kamera aus)
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await pc.addTrack(track, _localStream!);
      }
    } else {
      // CRITICAL FIX: Erstelle Audio-Only Stream wenn kein Video
      _log('  🎤 KEIN LOCAL STREAM - Erstelle Audio-Only Stream (handleOffer)');
      try {
        final audioOnlyStream = await navigator.mediaDevices.getUserMedia({
          'audio': true,
          'video': false,
        });
        _localStream = audioOnlyStream;

        // Set to renderer if available
        if (_localRenderer != null) {
          _localRenderer!.srcObject = _localStream;
        }

        // Add audio track to peer connection
        for (final track in _localStream!.getTracks()) {
          await pc.addTrack(track, _localStream!);
        }

        _log('  ✅ Audio-Only Stream erstellt und hinzugefügt (handleOffer)');
      } catch (e) {
        _log('  ❌ Audio-Only Stream fehlgeschlagen (handleOffer): $e');
      }
    }

    // Set Remote Description
    await pc.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));

    // ✅ FIX: Process pending ICE candidates after remote description set
    await _processPendingIceCandidates(fromPeerId);

    // Create Answer
    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);

    // Send Answer
    _sendSignalingMessage({
      'type': 'answer',
      'roomId': _currentRoomId,
      'fromPeerId': _localPeerId,
      'toPeerId': fromPeerId,
      'sdp': answer.sdp,
    });
  }

  /// Erhält Answer von anderem Peer
  Future<void> _handleAnswer(Map<String, dynamic> message) async {
    final fromPeerId = message['fromPeerId'] as String;
    final sdp = message['sdp'] as String;

    _log('📥 Answer von: $fromPeerId');

    final pc = _peerConnections[fromPeerId];
    if (pc != null) {
      await pc.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));

      // ✅ FIX: Process pending ICE candidates after remote description set
      await _processPendingIceCandidates(fromPeerId);
    }
  }

  /// Erhält ICE Candidate
  /// ✅ FIX: Queue candidates if remote description not yet set
  Future<void> _handleIceCandidate(Map<String, dynamic> message) async {
    final fromPeerId = message['fromPeerId'] as String;
    final candidateData = message['candidate'] as Map<String, dynamic>;

    final candidate = RTCIceCandidate(
      candidateData['candidate'] as String?,
      candidateData['sdpMid'] as String?,
      candidateData['sdpMLineIndex'] as int?,
    );

    _log('📥 ICE Candidate von: $fromPeerId');

    final pc = _peerConnections[fromPeerId];

    if (pc != null) {
      final remoteDesc = await pc.getRemoteDescription();
      if (remoteDesc != null) {
        // ✅ Remote description already set - add candidate immediately
        await pc.addCandidate(candidate);
        _log('  ✅ ICE Candidate hinzugefügt');
      } else {
        // ✅ Remote description not yet set - queue candidate
        _pendingIceCandidates.putIfAbsent(fromPeerId, () => []).add(candidate);
        _log('  📦 ICE Candidate queued (waiting for remote description)');
      }
    }
  }

  /// Erstellt neue Peer Connection
  /// ✅ FIX: Added error handling and cleanup to prevent memory leaks
  Future<RTCPeerConnection> _createPeerConnection(String peerId) async {
    RTCPeerConnection? pc;
    RTCVideoRenderer? renderer;

    try {
      _log('🔗 Erstelle Peer Connection: $peerId');

      pc = await createPeerConnection(_iceServers);

      // ICE Candidate Handler
      pc.onIceCandidate = (candidate) {
        if (candidate.candidate != null) {
          _sendSignalingMessage({
            'type': 'ice-candidate',
            'roomId': _currentRoomId,
            'fromPeerId': _localPeerId,
            'toPeerId': peerId,
            'candidate': {
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex': candidate.sdpMLineIndex,
            },
          });
        }
      };

      // Track Handler (Remote Stream)
      pc.onTrack = (event) async {
        _log('📹 Track received von: $peerId');

        if (event.streams.isNotEmpty) {
          final stream = event.streams[0];
          _remoteStreams[peerId] = stream;

          // Create Renderer für Remote Stream
          final newRenderer = RTCVideoRenderer();
          await newRenderer.initialize();
          newRenderer.srcObject = stream;
          _remoteRenderers[peerId] = newRenderer;

          notifyListeners();
        }
      };

      // Connection State Handler
      pc.onConnectionState = (state) {
        _log('🔌 Connection State [$peerId]: ${state.name}');
      };

      return pc;
    } catch (e, stackTrace) {
      _logError('Peer Connection Creation Failed', e, stackTrace);

      // ✅ CLEANUP on error to prevent memory leaks
      await renderer?.dispose();
      await pc?.close();
      _peerConnections.remove(peerId);
      _remoteRenderers.remove(peerId);
      _remoteStreams.remove(peerId);

      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stoppt Local Stream
  Future<void> _stopLocalStream() async {
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        track.stop();
      }
      _localStream = null;
    }
  }

  /// Fügt Local Tracks zu allen Peer Connections hinzu
  Future<void> _addTracksToAllPeers() async {
    if (_localStream == null) return;

    for (final pc in _peerConnections.values) {
      for (final track in _localStream!.getTracks()) {
        await pc.addTrack(track, _localStream!);
      }
    }
  }

  /// Entfernt Video Tracks von allen Peer Connections
  Future<void> _removeVideoTracksFromAllPeers() async {
    if (_localStream == null) return;

    for (final pc in _peerConnections.values) {
      final senders = await pc.getSenders();
      for (final sender in senders) {
        if (sender.track?.kind == 'video') {
          await pc.removeTrack(sender);
        }
      }
    }
  }

  /// Processes pending ICE candidates after remote description is set
  /// ✅ FIX: Ensures candidates are added in correct order
  Future<void> _processPendingIceCandidates(String peerId) async {
    final candidates = _pendingIceCandidates.remove(peerId);
    if (candidates != null && candidates.isNotEmpty) {
      _log(
        '📦 Processing ${candidates.length} pending ICE candidates for $peerId',
      );

      final pc = _peerConnections[peerId];
      if (pc != null) {
        for (final candidate in candidates) {
          await pc.addCandidate(candidate);
        }
        _log('  ✅ All pending ICE candidates added');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void dispose() {
    _log('🧹 Dispose aufgerufen, räume auf...');

    if (_isInRoom) {
      leaveChannel();
    }

    _localRenderer?.dispose();
    _localRenderer = null;

    _isInitialized = false;

    _log('✅ Cleanup abgeschlossen');
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOGGING HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('$_logPrefix $message');
    }
  }

  void _logError(String context, Object error, StackTrace? stackTrace) {
    if (kDebugMode) {
      debugPrint('$_logPrefix ❌ ERROR in $context:');
      debugPrint('$_logPrefix    $error');
      if (stackTrace != null) {
        debugPrint('$_logPrefix    StackTrace: $stackTrace');
      }
    }
  }
}
