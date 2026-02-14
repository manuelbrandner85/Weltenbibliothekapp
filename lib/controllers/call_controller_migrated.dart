import 'package:flutter/foundation.dart';
import '../core/logging/app_logger.dart';
import '../core/exceptions/exception_guard.dart';
import '../core/exceptions/specialized_exceptions.dart';
import '../services/webrtc_voice_service.dart';
import '../services/voice_backend_service.dart';

/// 🎙️ CALL CONTROLLER
/// Manages WebRTC call lifecycle with backend session management
/// 
/// Features:
/// - Backend-First Flow (session → WebRTC)
/// - Proper exception handling
/// - State management (joining, inCall)
/// - Reconnection logic
/// - Error recovery
class CallController {
  final WebRTCVoiceService webrtc;
  final VoiceBackendService backend;

  String? _sessionId;
  String? _currentRoomId;
  bool _joining = false;

  CallController({
    required this.webrtc,
    required this.backend,
  });

  /// Check if currently in a call
  bool get inCall => _sessionId != null;

  /// Check if currently joining
  bool get isJoining => _joining;

  /// Get current session ID
  String? get sessionId => _sessionId;

  /// Get current room ID
  String? get currentRoomId => _currentRoomId;

  /// Join a voice call room
  /// 
  /// Throws:
  /// - [RoomFullException] if room is at capacity
  /// - [AuthException] if authentication fails
  /// - [NetworkException] if network issues
  /// - [VoiceException] for WebRTC-specific errors
  Future<void> join({
    required String roomId,
    required String userId,
    required String username,
    required String world,
    bool pushToTalk = false,
  }) async {
    // Prevent double-join
    if (_joining || inCall) {
      AppLogger.warn('⚠️ Already joining or in call',
        context: {'joining': _joining, 'inCall': inCall},
      );
      return;
    }

    _joining = true;

    try {
      await guard(
        () async {
          AppLogger.info('🎙️ Joining room',
            context: {'roomId': roomId, 'userId': userId},
          );

          // Phase 1: Backend Session Creation
          final sessionData = await backend.joinVoiceRoom(
            roomId: roomId,
            userId: userId,
            username: username,
            world: world,
          );

          _sessionId = sessionData.sessionId;
          _currentRoomId = roomId;

          AppLogger.info('✅ Backend session created',
            context: {'sessionId': _sessionId, 'roomId': roomId},
          );

          // Phase 2: WebRTC Connection
          final success = await webrtc.joinRoom(
            roomId: roomId,
            userId: userId,
            username: username,
            world: world,
            pushToTalk: pushToTalk,
          );

          if (!success) {
            throw VoiceException(
              'WebRTC join failed',
              roomId: roomId,
              userId: userId,
            );
          }

          AppLogger.info('✅ Call connected successfully',
            context: {'roomId': roomId, 'sessionId': _sessionId},
          );
        },
        operationName: 'CallController.join',
        context: {
          'roomId': roomId,
          'userId': userId,
          'username': username,
          'world': world,
          'pushToTalk': pushToTalk,
        },
        onError: (error, stackTrace) async {
          // Cleanup on error
          AppLogger.error('❌ Join failed, cleaning up',
            error: error,
            context: {
              'roomId': roomId,
              'sessionId': _sessionId,
            },
          );

          // Clear local state
          _sessionId = null;
          _currentRoomId = null;

          // Try to cleanup backend session if it was created
          if (_sessionId != null) {
            try {
              await backend.leaveVoiceRoom(_sessionId!);
            } catch (e) {
              AppLogger.warn('⚠️ Backend cleanup failed',
                context: {'sessionId': _sessionId, 'error': e.toString()},
              );
            }
          }

          // Rethrow original error for UI handling
          throw error;
        },
      );
    } finally {
      _joining = false;
    }
  }

  /// Leave current call
  /// 
  /// Throws:
  /// - [VoiceException] if WebRTC leave fails
  /// - [BackendException] if backend leave fails
  Future<void> leave() async {
    if (!inCall) {
      AppLogger.info('ℹ️ Not in call, nothing to leave');
      return;
    }

    await guard(
      () async {
        AppLogger.info('👋 Leaving call',
          context: {'sessionId': _sessionId, 'roomId': _currentRoomId},
        );

        // Phase 1: Leave WebRTC
        try {
          await webrtc.leaveRoom();
          AppLogger.info('✅ WebRTC left');
        } catch (e) {
          AppLogger.warn('⚠️ WebRTC leave error',
            context: {'error': e.toString()},
          );
          // Continue to backend cleanup even if WebRTC fails
        }

        // Phase 2: Leave Backend Session
        if (_sessionId != null) {
          try {
            await backend.leaveVoiceRoom(_sessionId!);
            AppLogger.info('✅ Backend session closed',
              context: {'sessionId': _sessionId},
            );
          } catch (e) {
            AppLogger.warn('⚠️ Backend leave error',
              context: {'sessionId': _sessionId, 'error': e.toString()},
            );
          }
        }

        // Clear state
        final oldSessionId = _sessionId;
        _sessionId = null;
        _currentRoomId = null;

        AppLogger.info('✅ Call ended',
          context: {'sessionId': oldSessionId},
        );
      },
      operationName: 'CallController.leave',
      context: {
        'sessionId': _sessionId,
        'roomId': _currentRoomId,
      },
      onError: (error, stackTrace) async {
        // Always clear state, even on error
        _sessionId = null;
        _currentRoomId = null;

        AppLogger.warn('⚠️ Leave completed with errors',
          context: {'error': error.toString()},
        );
      },
    );
  }

  /// Handle reconnection (leave + join)
  /// 
  /// Throws:
  /// - Same as [join] method
  Future<void> handleReconnect({
    required String roomId,
    required String userId,
    required String username,
    required String world,
    bool pushToTalk = false,
  }) async {
    await guard(
      () async {
        AppLogger.info('🔄 Reconnect triggered',
          context: {'roomId': roomId, 'wasInCall': inCall},
        );

        // Phase 1: Leave current call (if any)
        if (inCall) {
          await leave();

          // Give some time for cleanup
          await Future.delayed(const Duration(milliseconds: 500));
        }

        // Phase 2: Join new call
        await join(
          roomId: roomId,
          userId: userId,
          username: username,
          world: world,
          pushToTalk: pushToTalk,
        );

        AppLogger.info('✅ Reconnection successful',
          context: {'roomId': roomId, 'sessionId': _sessionId},
        );
      },
      operationName: 'CallController.handleReconnect',
      context: {
        'roomId': roomId,
        'userId': userId,
        'wasInCall': inCall,
      },
    );
  }

  /// Force cleanup (emergency state reset)
  void forceCleanup() {
    AppLogger.warn('🚨 Force cleanup triggered');
    _sessionId = null;
    _currentRoomId = null;
    _joining = false;
  }
}
