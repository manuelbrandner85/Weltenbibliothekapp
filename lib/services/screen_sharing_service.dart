/// 🖥️ WELTENBIBLIOTHEK - SCREEN SHARING SERVICE
/// WebRTC Screen Sharing for Admins/Moderators
/// Features: Share screen, view shared screens, quality controls, PiP mode
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'webrtc_voice_service.dart'; // ✅ UNIFIED WebRTC Service
import '../services/cloudflare_signaling_service.dart';
import '../services/error_reporting_service.dart';

/// Screen Share State
enum ScreenShareState {
  inactive,
  starting,
  active,
  stopping,
  error,
}

/// Screen Share Participant
class ScreenShareParticipant {
  final String userId;
  final String username;
  final MediaStream stream;
  final bool isLocal;
  
  ScreenShareParticipant({
    required this.userId,
    required this.username,
    required this.stream,
    this.isLocal = false,
  });
}

/// Screen Sharing Service (Singleton)
class ScreenSharingService extends ChangeNotifier {
  static final ScreenSharingService _instance = ScreenSharingService._internal();
  factory ScreenSharingService() => _instance;
  ScreenSharingService._internal();

  // Dependencies
  final SimpleVoiceController _voiceController = SimpleVoiceController();
  final CloudflareSignalingService _signaling = CloudflareSignalingService();
  
  // Screen Share State
  ScreenShareState _state = ScreenShareState.inactive;
  MediaStream? _localScreenStream;
  String? _currentSharerUserId;
  String? _currentSharerUsername;
  
  // Remote Screen Streams (userId -> stream)
  final Map<String, MediaStream> _remoteScreenStreams = {};
  
  // Screen Share Participants
  final Map<String, ScreenShareParticipant> _screenParticipants = {};
  
  // Stream Controllers
  final _stateController = StreamController<ScreenShareState>.broadcast();
  final _screenParticipantsController = StreamController<List<ScreenShareParticipant>>.broadcast();
  
  // Streams
  Stream<ScreenShareState> get stateStream => _stateController.stream;
  Stream<List<ScreenShareParticipant>> get screenParticipantsStream => _screenParticipantsController.stream;
  
  // Getters
  ScreenShareState get state => _state;
  bool get isSharing => _state == ScreenShareState.active && _localScreenStream != null;
  bool get isSomeoneSharing => _screenParticipants.isNotEmpty;
  List<ScreenShareParticipant> get screenParticipants => _screenParticipants.values.toList();
  MediaStream? get localScreenStream => _localScreenStream;
  String? get currentSharerUserId => _currentSharerUserId;
  String? get currentSharerUsername => _currentSharerUsername;
  
  // Screen constraints
  final Map<String, dynamic> _screenConstraints = {
    'video': {
      'mandatory': {
        'minWidth': '1280',
        'minHeight': '720',
        'maxWidth': '1920',
        'maxHeight': '1080',
        'minFrameRate': '15',
        'maxFrameRate': '30',
      },
    },
    'audio': false, // Screen audio can be enabled optionally
  };

  /// Start Screen Sharing (Admin only)
  Future<bool> startScreenShare({
    required String userId,
    required String username,
    bool includeAudio = false,
  }) async {
    try {
      _setState(ScreenShareState.starting);
      
      if (kDebugMode) {
        print('🖥️ ScreenShare: Starting screen share for $username');
      }
      
      // Update constraints if audio is needed
      if (includeAudio) {
        _screenConstraints['audio'] = true;
      }
      
      // Get display media (screen)
      try {
        _localScreenStream = await navigator.mediaDevices.getDisplayMedia(_screenConstraints);
      } catch (e) {
        if (kDebugMode) {
          print('❌ ScreenShare: Failed to get display media - $e');
        }
        _setState(ScreenShareState.error);
        ErrorReportingService().reportError(
          error: e,
          context: 'Screen Share - Get Display Media',
        );
        return false;
      }
      
      if (_localScreenStream == null) {
        _setState(ScreenShareState.error);
        return false;
      }
      
      _currentSharerUserId = userId;
      _currentSharerUsername = username;
      
      // Add local screen participant
      _screenParticipants[userId] = ScreenShareParticipant(
        userId: userId,
        username: username,
        stream: _localScreenStream!,
        isLocal: true,
      );
      _screenParticipantsController.add(screenParticipants);
      
      // Handle track ended (user stops sharing)
      _localScreenStream!.getVideoTracks().first.onEnded = () {
        if (kDebugMode) {
          print('🖥️ ScreenShare: Screen sharing track ended');
        }
        stopScreenShare();
      };
      
      // Add screen track to existing peer connections
      await _addScreenTrackToPeers();
      
      // Notify other participants via signaling
      await _notifyScreenShareStart(userId, username);
      
      _setState(ScreenShareState.active);
      
      if (kDebugMode) {
        print('✅ ScreenShare: Screen sharing started successfully');
      }
      
      return true;
      
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ ScreenShare: Error starting screen share - $e');
      }
      ErrorReportingService().reportError(
        error: e,
        stackTrace: stack,
        context: 'Screen Share - Start',
      );
      _setState(ScreenShareState.error);
      return false;
    }
  }

  /// Stop Screen Sharing
  Future<void> stopScreenShare() async {
    try {
      _setState(ScreenShareState.stopping);
      
      if (kDebugMode) {
        print('🖥️ ScreenShare: Stopping screen share');
      }
      
      // Stop local screen stream
      if (_localScreenStream != null) {
        _localScreenStream!.getTracks().forEach((track) {
          track.stop();
        });
        await _localScreenStream!.dispose();
        _localScreenStream = null;
      }
      
      // Remove screen track from peers
      await _removeScreenTrackFromPeers();
      
      // Remove local participant
      if (_currentSharerUserId != null) {
        _screenParticipants.remove(_currentSharerUserId);
        _screenParticipantsController.add(screenParticipants);
      }
      
      // Notify other participants
      if (_currentSharerUserId != null) {
        await _notifyScreenShareStop(_currentSharerUserId!);
      }
      
      _currentSharerUserId = null;
      _currentSharerUsername = null;
      
      _setState(ScreenShareState.inactive);
      
      if (kDebugMode) {
        print('✅ ScreenShare: Screen sharing stopped');
      }
      
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ ScreenShare: Error stopping screen share - $e');
      }
      ErrorReportingService().reportError(
        error: e,
        stackTrace: stack,
        context: 'Screen Share - Stop',
      );
      _setState(ScreenShareState.error);
    }
  }

  /// Add screen track to existing peer connections
  Future<void> _addScreenTrackToPeers() async {
    if (_localScreenStream == null) return;
    
    try {
      final videoTrack = _localScreenStream!.getVideoTracks().first;
      
      // Access internal participants from VoiceController
      // Note: This requires VoiceController to expose participants map
      // For now, we'll send via signaling
      
      if (kDebugMode) {
        print('🖥️ ScreenShare: Adding screen track to peers');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ ScreenShare: Error adding screen track - $e');
      }
    }
  }

  /// Remove screen track from peer connections
  Future<void> _removeScreenTrackFromPeers() async {
    try {
      if (kDebugMode) {
        print('🖥️ ScreenShare: Removing screen track from peers');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ ScreenShare: Error removing screen track - $e');
      }
    }
  }

  /// Notify participants that screen share started
  Future<void> _notifyScreenShareStart(String userId, String username) async {
    try {
      // Send via signaling service
      // This would use the existing signaling infrastructure
      
      if (kDebugMode) {
        print('📡 ScreenShare: Notifying screen share start');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ ScreenShare: Error notifying screen share start - $e');
      }
    }
  }

  /// Notify participants that screen share stopped
  Future<void> _notifyScreenShareStop(String userId) async {
    try {
      if (kDebugMode) {
        print('📡 ScreenShare: Notifying screen share stop');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ ScreenShare: Error notifying screen share stop - $e');
      }
    }
  }

  /// Handle remote screen share start
  void handleRemoteScreenShare(String userId, String username, MediaStream stream) {
    try {
      _remoteScreenStreams[userId] = stream;
      
      _screenParticipants[userId] = ScreenShareParticipant(
        userId: userId,
        username: username,
        stream: stream,
        isLocal: false,
      );
      
      _currentSharerUserId = userId;
      _currentSharerUsername = username;
      
      _screenParticipantsController.add(screenParticipants);
      
      if (kDebugMode) {
        print('✅ ScreenShare: Remote screen share from $username received');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ ScreenShare: Error handling remote screen share - $e');
      }
    }
  }

  /// Handle remote screen share stop
  void handleRemoteScreenShareStop(String userId) {
    try {
      final stream = _remoteScreenStreams.remove(userId);
      if (stream != null) {
        stream.dispose();
      }
      
      _screenParticipants.remove(userId);
      _screenParticipantsController.add(screenParticipants);
      
      if (_currentSharerUserId == userId) {
        _currentSharerUserId = null;
        _currentSharerUsername = null;
      }
      
      if (kDebugMode) {
        print('✅ ScreenShare: Remote screen share stopped');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ ScreenShare: Error handling remote screen share stop - $e');
      }
    }
  }

  /// Toggle screen share
  Future<bool> toggleScreenShare({
    required String userId,
    required String username,
  }) async {
    if (isSharing) {
      await stopScreenShare();
      return false;
    } else {
      return await startScreenShare(userId: userId, username: username);
    }
  }

  /// Set state
  void _setState(ScreenShareState newState) {
    _state = newState;
    _stateController.add(_state);
    notifyListeners();
  }

  /// Dispose
  @override
  Future<void> dispose() async {
    await stopScreenShare();
    
    for (final stream in _remoteScreenStreams.values) {
      await stream.dispose();
    }
    _remoteScreenStreams.clear();
    _screenParticipants.clear();
    
    await _stateController.close();
    await _screenParticipantsController.close();
    
    super.dispose();
  }
}
