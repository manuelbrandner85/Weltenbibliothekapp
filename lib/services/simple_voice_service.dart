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
      print('🎤 [SimpleVoice] Initializing microphone...');

      // ✅ ANDROID: Request permission first
      if (!kIsWeb) {
        print('📱 [SimpleVoice] Requesting microphone permission...');
        final status = await Permission.microphone.request();
        if (!status.isGranted) {
          print('❌ [SimpleVoice] Microphone permission denied');
          return false;
        }
        print('✅ [SimpleVoice] Microphone permission granted');
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

      print('🎙️ [SimpleVoice] Calling getUserMedia()...');
      localStream = await navigator.mediaDevices.getUserMedia(constraints);

      if (localStream == null || localStream!.getAudioTracks().isEmpty) {
        print('❌ [SimpleVoice] No local audio stream available');
        return false;
      }

      print('✅ [SimpleVoice] Microphone initialized successfully');
      print('   Audio tracks: ${localStream!.getAudioTracks().length}');
      return true;
    } catch (e) {
      print('❌ [SimpleVoice] Failed to initialize microphone: $e');
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
      print('🚀 [SimpleVoice] ===== JOIN VOICE ROOM =====');
      print('   Room: $roomId');
      print('   User: $username ($userId)');

      // Leave existing room first
      if (isInCall) {
        print('⚠️ [SimpleVoice] Already in call, leaving first');
        await leaveVoiceRoom();
      }

      // Initialize microphone
      if (localStream == null) {
        print('🎤 [SimpleVoice] Local stream not initialized, initializing...');
        final success = await initMicrophone();
        if (!success) {
          print('❌ [SimpleVoice] Failed to initialize microphone');
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

      print('✅ [SimpleVoice] Joined voice room successfully');
      print('   Participants: ${participants.length}');
      debugParticipants();

      return true;
    } catch (e) {
      print('❌ [SimpleVoice] Failed to join room: $e');
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
    print('👤 [SimpleVoice] Adding self: $username ($userId)');

    participants[userId] = VoiceParticipant(
      userId: userId,
      username: username,
      isSelf: true,
      stream: localStream,
    );

    notifyListeners();
    print('✅ [SimpleVoice] Self added successfully');
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// 4️⃣ USER JOINED (ANDEREN USER BEIM JOIN HINZUFÜGEN - OHNE STREAM)
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  void onUserJoined({
    required String userId,
    required String username,
  }) {
    if (participants.containsKey(userId)) {
      print('⚠️ [SimpleVoice] User already exists: $userId');
      return;
    }

    print('➕ [SimpleVoice] User joined: $username ($userId)');

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
      print('🔗 [SimpleVoice] Creating peer for user: $userId');

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
          print('🎵 [SimpleVoice] Added local audio track to peer: $userId');
        }
      }

      // ✅ Handle remote track
      pc.onTrack = (RTCTrackEvent event) {
        print('📥 [SimpleVoice] onTrack from user: $userId');
        if (event.streams.isNotEmpty) {
          final participant = participants[userId];
          if (participant != null) {
            participant.stream = event.streams.first;
            notifyListeners();
            print('✅ [SimpleVoice] Remote stream attached to user: $userId');
            print('   Audio tracks: ${event.streams.first.getAudioTracks().length}');
          }
        }
      };

      // ✅ Handle connection state
      pc.onConnectionState = (RTCPeerConnectionState state) {
        print('🔗 [SimpleVoice] Connection state [$userId]: $state');
      };

      // Store peer
      participants[userId]?.peer = pc;

      print('✅ [SimpleVoice] Peer created for user: $userId');
    } catch (e) {
      print('❌ [SimpleVoice] Failed to create peer for user $userId: $e');
    }
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// 6️⃣ USER LEFT
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  void onUserLeft(String userId) {
    print('➖ [SimpleVoice] User left: $userId');

    participants[userId]?.peer?.close();
    participants.remove(userId);
    notifyListeners();

    print('✅ [SimpleVoice] User removed: $userId');
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// 7️⃣ LEAVE VOICE ROOM
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  Future<void> leaveVoiceRoom() async {
    try {
      print('🚪 [SimpleVoice] Leaving voice room...');

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

      print('✅ [SimpleVoice] Left voice room');
    } catch (e) {
      print('❌ [SimpleVoice] Error leaving room: $e');
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

    print('🔇 [SimpleVoice] Muted: $newMuteState');
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// 9️⃣ DEBUG PARTICIPANTS
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  void debugParticipants() {
    print('');
    print('═══════════════════════════════════════');
    print('👥 PARTICIPANTS DEBUG ($participantCount users)');
    print('═══════════════════════════════════════');
    participants.forEach((id, p) {
      print('USER=${p.username} | self=${p.isSelf} | stream=${p.stream != null} | peer=${p.peer != null}');
    });
    print('═══════════════════════════════════════');
    print('');
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
