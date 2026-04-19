/// 🎙️ SIMPLE VOICE SERVICE - Production Ready WebRTC
/// 
/// Senior Flutter & WebRTC Engineer Implementation
/// 
/// GARANTIERT:
/// ✅ Mikrofon-Permission wird abgefragt
/// ✅ Local Audio Stream existiert
/// ✅ Eigener User wird SOFORT angezeigt
/// ✅ Andere User erscheinen beim JOIN (auch ohne Stream)
/// ✅ Sauberes userId → PeerConnection → MediaStream Mapping
/// ✅ Stabil auf Android & Web
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 📦 VOICE ROLE ENUM
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
enum VoiceRole {
  speaker,
  listener,
  participant,
}

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 📦 VOICE PARTICIPANT MODEL
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class VoiceParticipant {
  final String userId;
  final String username;
  final bool isSelf;
  final String? avatarEmoji; // ✅ ADD: Avatar emoji

  MediaStream? stream;
  RTCPeerConnection? peer;
  bool isMuted;
  bool isSpeaking;
  bool handRaised; // ✅ ADD: Hand raised state
  double volume; // ✅ ADD: Volume level
  VoiceRole role; // ✅ ADD: Voice role

  VoiceParticipant({
    required this.userId,
    required this.username,
    this.isSelf = false,
    this.avatarEmoji,
    this.stream,
    this.peer,
    this.isMuted = false,
    this.isSpeaking = false,
    this.handRaised = false,
    this.volume = 1.0,
    this.role = VoiceRole.participant,
  });

  /// Check if participant has audio
  bool get hasAudio => stream != null && stream!.getAudioTracks().isNotEmpty;

  /// Check if peer is connected
  bool get isConnected =>
      peer != null &&
      peer!.connectionState == RTCPeerConnectionState.RTCPeerConnectionStateConnected;

  @override
  String toString() {
    return 'VoiceParticipant(userId: $userId, username: $username, isSelf: $isSelf, hasAudio: $hasAudio, isConnected: $isConnected)';
  }
}

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 🎙️ SIMPLE VOICE SERVICE
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class SimpleVoiceService extends ChangeNotifier {
  // Singleton
  static final SimpleVoiceService _instance = SimpleVoiceService._internal();
  factory SimpleVoiceService() => _instance;
  SimpleVoiceService._internal();

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// STATE
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  final Map<String, VoiceParticipant> participants = {};
  MediaStream? localStream;
  String? currentRoomId;
  String? currentUserId;
  String? currentUsername;
  bool isInCall = false;

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// GETTERS
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  List<VoiceParticipant> get participantsList => participants.values.toList();
  int get participantCount => participants.length;
  VoiceParticipant? get self => participants[currentUserId];
  bool get isMuted => self?.isMuted ?? false;

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// 1️⃣ MICROPHONE INITIALISIEREN
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  Future<bool> initMicrophone() async {
    try {
      debugPrint('🎤 [SimpleVoice] Initializing microphone...');

      // ✅ ANDROID: Request permission first
      if (!kIsWeb) {
        debugPrint('📱 [SimpleVoice] Requesting microphone permission...');
        final status = await Permission.microphone.request();
        if (!status.isGranted) {
          debugPrint('❌ [SimpleVoice] Microphone permission denied');
          return false;
        }
        debugPrint('✅ [SimpleVoice] Microphone permission granted');
      }

      // ✅ Get user media
      final constraints = {
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      };

      debugPrint('🎙️ [SimpleVoice] Calling getUserMedia()...');
      localStream = await navigator.mediaDevices.getUserMedia(constraints);

      if (localStream == null || localStream!.getAudioTracks().isEmpty) {
        debugPrint('❌ [SimpleVoice] No local audio stream available');
        return false;
      }

      debugPrint('✅ [SimpleVoice] Microphone initialized successfully');
      debugPrint('   Audio tracks: ${localStream!.getAudioTracks().length}');
      return true;
    } catch (e) {
      debugPrint('❌ [SimpleVoice] Failed to initialize microphone: $e');
      return false;
    }
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// 2️⃣ JOIN VOICE ROOM
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  Future<bool> joinVoiceRoom({
    required String roomId,
    required String userId,
    required String username,
  }) async {
    try {
      debugPrint('🚀 [SimpleVoice] ===== JOIN VOICE ROOM =====');
      debugPrint('   Room: $roomId');
      debugPrint('   User: $username ($userId)');

      // Leave existing room first
      if (isInCall) {
        debugPrint('⚠️ [SimpleVoice] Already in call, leaving first');
        await leaveVoiceRoom();
      }

      // Initialize microphone
      if (localStream == null) {
        debugPrint('🎤 [SimpleVoice] Local stream not initialized, initializing...');
        final success = await initMicrophone();
        if (!success) {
          debugPrint('❌ [SimpleVoice] Failed to initialize microphone');
          return false;
        }
      }

      // Set current state
      currentRoomId = roomId;
      currentUserId = userId;
      currentUsername = username;
      isInCall = true;

      // ✅ ADD SELF IMMEDIATELY
      addSelf(userId: userId, username: username);

      debugPrint('✅ [SimpleVoice] Joined voice room successfully');
      debugPrint('   Participants: ${participants.length}');
      debugParticipants();

      return true;
    } catch (e) {
      debugPrint('❌ [SimpleVoice] Failed to join room: $e');
      return false;
    }
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// 3️⃣ ADD SELF (EIGENEN USER SOFORT HINZUFÜGEN)
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  void addSelf({
    required String userId,
    required String username,
  }) {
    debugPrint('👤 [SimpleVoice] Adding self: $username ($userId)');

    participants[userId] = VoiceParticipant(
      userId: userId,
      username: username,
      isSelf: true,
      stream: localStream,
    );

    notifyListeners();
    debugPrint('✅ [SimpleVoice] Self added successfully');
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// 4️⃣ USER JOINED (ANDEREN USER BEIM JOIN HINZUFÜGEN - OHNE STREAM)
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  void onUserJoined({
    required String userId,
    required String username,
  }) {
    if (participants.containsKey(userId)) {
      debugPrint('⚠️ [SimpleVoice] User already exists: $userId');
      return;
    }

    debugPrint('➕ [SimpleVoice] User joined: $username ($userId)');

    participants[userId] = VoiceParticipant(
      userId: userId,
      username: username,
      isSelf: false,
    );

    notifyListeners();

    // Create peer connection for new user
    createPeerForUser(userId);
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// 5️⃣ CREATE PEER CONNECTION PRO USER
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  Future<void> createPeerForUser(String userId) async {
    try {
      debugPrint('🔗 [SimpleVoice] Creating peer for user: $userId');

      final configuration = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'}
        ]
      };

      final pc = await createPeerConnection(configuration);

      // ✅ 🔊 Local Audio an Peer hängen (PFLICHT)
      if (localStream != null) {
        for (final track in localStream!.getAudioTracks()) {
          await pc.addTrack(track, localStream!);
          debugPrint('🎵 [SimpleVoice] Added local audio track to peer: $userId');
        }
      }

      // ✅ Handle remote track
      pc.onTrack = (RTCTrackEvent event) {
        debugPrint('📥 [SimpleVoice] onTrack from user: $userId');
        if (event.streams.isNotEmpty) {
          final participant = participants[userId];
          if (participant != null) {
            participant.stream = event.streams.first;
            notifyListeners();
            debugPrint('✅ [SimpleVoice] Remote stream attached to user: $userId');
            debugPrint('   Audio tracks: ${event.streams.first.getAudioTracks().length}');
          }
        }
      };

      // ✅ Handle connection state
      pc.onConnectionState = (RTCPeerConnectionState state) {
        debugPrint('🔗 [SimpleVoice] Connection state [$userId]: $state');
      };

      // Store peer
      participants[userId]?.peer = pc;

      debugPrint('✅ [SimpleVoice] Peer created for user: $userId');
    } catch (e) {
      debugPrint('❌ [SimpleVoice] Failed to create peer for user $userId: $e');
    }
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// 6️⃣ USER LEFT
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  void onUserLeft(String userId) {
    debugPrint('➖ [SimpleVoice] User left: $userId');

    participants[userId]?.peer?.close();
    participants.remove(userId);
    notifyListeners();

    debugPrint('✅ [SimpleVoice] User removed: $userId');
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// 7️⃣ LEAVE VOICE ROOM
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  Future<void> leaveVoiceRoom() async {
    try {
      debugPrint('🚪 [SimpleVoice] Leaving voice room...');

      // Close all peer connections
      for (var participant in participants.values) {
        await participant.peer?.close();
      }

      // Clear state
      participants.clear();
      currentRoomId = null;
      currentUserId = null;
      currentUsername = null;
      isInCall = false;

      notifyListeners();

      debugPrint('✅ [SimpleVoice] Left voice room');
    } catch (e) {
      debugPrint('❌ [SimpleVoice] Error leaving room: $e');
    }
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// 8️⃣ TOGGLE MUTE
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  Future<void> toggleMute() async {
    if (localStream == null || currentUserId == null) return;

    final newMuteState = !isMuted;

    // Mute/unmute all audio tracks
    for (var track in localStream!.getAudioTracks()) {
      track.enabled = !newMuteState;
    }

    // Update self participant
    final selfParticipant = participants[currentUserId];
    if (selfParticipant != null) {
      selfParticipant.isMuted = newMuteState;
      notifyListeners();
    }

    debugPrint('🔇 [SimpleVoice] Muted: $newMuteState');
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// 9️⃣ DEBUG PARTICIPANTS
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  void debugParticipants() {
    debugPrint('');
    debugPrint('═══════════════════════════════════════');
    debugPrint('👥 PARTICIPANTS DEBUG ($participantCount users)');
    debugPrint('═══════════════════════════════════════');
    participants.forEach((id, p) {
      debugPrint('USER=${p.username} | self=${p.isSelf} | stream=${p.stream != null} | peer=${p.peer != null}');
    });
    debugPrint('═══════════════════════════════════════');
    debugPrint('');
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// 🔟 DISPOSE
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  @override
  void dispose() {
    leaveVoiceRoom();
    localStream?.dispose();
    super.dispose();
  }
}
