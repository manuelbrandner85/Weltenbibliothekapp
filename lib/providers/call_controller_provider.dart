/// 🎛️ CALL CONTROLLER PROVIDER
/// 
/// Production-ready Riverpod provider for CallController
/// 
/// Features:
/// - Proper dependency injection
/// - Service lifecycle management
/// - Auto-dispose when not in use
/// - Error handling
/// - Configuration from environment
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/call_controller_migrated.dart';
import '../services/webrtc_voice_service.dart';
import '../services/voice_backend_service.dart';
import '../core/logging/app_logger.dart';

/// WebRTC Voice Service Provider (Singleton)
/// Uses existing instance to maintain WebRTC state
final webrtcVoiceServiceProvider = Provider<WebRTCVoiceService>((ref) {
  AppLogger.info('🎛️ Creating WebRTCVoiceService instance');
  
  // Use singleton instance
  final service = WebRTCVoiceService.instance;
  
  // Cleanup on dispose
  ref.onDispose(() {
    AppLogger.info('🧹 Disposing WebRTCVoiceService');
    // WebRTC service is singleton, don't dispose
  });
  
  return service;
});

/// Voice Backend Service Provider
final voiceBackendServiceProvider = Provider<VoiceBackendService>((ref) {
  AppLogger.info('🎛️ Creating VoiceBackendService instance');
  
  final service = VoiceBackendService();
  
  ref.onDispose(() {
    AppLogger.info('🧹 Disposing VoiceBackendService');
  });
  
  return service;
});

/// Call Controller Provider (Auto-dispose)
/// Automatically disposes when no longer used
final callControllerProvider = Provider.autoDispose<CallController>((ref) {
  AppLogger.info('🎛️ Creating CallController instance');
  
  // Get dependencies
  final webrtc = ref.watch(webrtcVoiceServiceProvider);
  final backend = ref.watch(voiceBackendServiceProvider);
  
  // Create controller
  final controller = CallController(
    webrtc: webrtc,
    backend: backend,
  );
  
  // Cleanup on dispose
  ref.onDispose(() {
    AppLogger.info('🧹 Disposing CallController');
    
    // Force cleanup if still in call
    if (controller.inCall) {
      AppLogger.warn('⚠️ CallController disposed while in call, forcing cleanup');
      controller.forceCleanup();
    }
  });
  
  return controller;
});

/// Call State Provider (for UI state management)
/// Watches call state changes
final callStateProvider = StateNotifierProvider.autoDispose<CallStateNotifier, CallState>((ref) {
  return CallStateNotifier(ref);
});

/// Call State Notifier
class CallStateNotifier extends StateNotifier<CallState> {
  final AutoDisposeStateNotifierProviderRef<CallStateNotifier, CallState> ref;
  
  CallStateNotifier(this.ref) : super(CallState.initial());

  /// Join call
  Future<void> join({
    required String roomId,
    required String userId,
    required String username,
    required String world,
    bool pushToTalk = false,
  }) async {
    try {
      // Set joining state
      state = state.copyWith(
        isJoining: true,
        error: null,
      );
      
      AppLogger.info('🎛️ [Provider] Joining call',
        context: {
          'roomId': roomId,
          'userId': userId,
          'username': username,
          'world': world,
        },
      );
      
      // Get controller and join
      final controller = ref.read(callControllerProvider);
      await controller.join(
        roomId: roomId,
        userId: userId,
        username: username,
        world: world,
        pushToTalk: pushToTalk,
      );
      
      // Update state
      state = state.copyWith(
        isJoining: false,
        inCall: true,
        roomId: roomId,
        sessionId: controller.sessionId,
      );
      
      AppLogger.info('✅ [Provider] Call joined successfully');
      
    } catch (e) {
      AppLogger.error('❌ [Provider] Failed to join call',
        error: e,
        context: {'roomId': roomId},
      );
      
      state = state.copyWith(
        isJoining: false,
        inCall: false,
        error: e.toString(),
      );
      
      rethrow;
    }
  }

  /// Leave call
  Future<void> leave() async {
    try {
      AppLogger.info('🎛️ [Provider] Leaving call');
      
      final controller = ref.read(callControllerProvider);
      await controller.leave();
      
      // Reset state
      state = CallState.initial();
      
      AppLogger.info('✅ [Provider] Call left successfully');
      
    } catch (e) {
      AppLogger.error('❌ [Provider] Failed to leave call',
        error: e,
      );
      
      state = state.copyWith(
        error: e.toString(),
      );
      
      // Force cleanup even on error
      state = CallState.initial();
    }
  }

  /// Reconnect call
  Future<void> reconnect({
    required String roomId,
    required String userId,
    required String username,
    required String world,
    bool pushToTalk = false,
  }) async {
    try {
      AppLogger.info('🎛️ [Provider] Reconnecting call');
      
      final controller = ref.read(callControllerProvider);
      await controller.handleReconnect(
        roomId: roomId,
        userId: userId,
        username: username,
        world: world,
        pushToTalk: pushToTalk,
      );
      
      // Update state
      state = state.copyWith(
        inCall: true,
        roomId: roomId,
        sessionId: controller.sessionId,
        error: null,
      );
      
      AppLogger.info('✅ [Provider] Call reconnected successfully');
      
    } catch (e) {
      AppLogger.error('❌ [Provider] Failed to reconnect call',
        error: e,
      );
      
      state = state.copyWith(
        inCall: false,
        error: e.toString(),
      );
      
      rethrow;
    }
  }
}

/// Call State Model
class CallState {
  final bool isJoining;
  final bool inCall;
  final String? roomId;
  final String? sessionId;
  final String? error;

  CallState({
    required this.isJoining,
    required this.inCall,
    this.roomId,
    this.sessionId,
    this.error,
  });

  factory CallState.initial() {
    return CallState(
      isJoining: false,
      inCall: false,
    );
  }

  CallState copyWith({
    bool? isJoining,
    bool? inCall,
    String? roomId,
    String? sessionId,
    String? error,
  }) {
    return CallState(
      isJoining: isJoining ?? this.isJoining,
      inCall: inCall ?? this.inCall,
      roomId: roomId ?? this.roomId,
      sessionId: sessionId ?? this.sessionId,
      error: error,
    );
  }
}

// ============================================================================
// USAGE EXAMPLES
// ============================================================================

/// Example 1: Join call using provider
/// 
/// ```dart
/// class MyCallScreen extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final callState = ref.watch(callStateProvider);
///     
///     return Scaffold(
///       body: Center(
///         child: callState.isJoining
///             ? CircularProgressIndicator()
///             : ElevatedButton(
///                 onPressed: () async {
///                   try {
///                     await ref.read(callStateProvider.notifier).join(
///                       roomId: 'room_123',
///                       userId: 'user_abc',
///                       username: 'John Doe',
///                       world: 'materie',
///                     );
///                   } catch (e) {
///                     ScaffoldMessenger.of(context).showSnackBar(
///                       SnackBar(content: Text('Failed to join: $e')),
///                     );
///                   }
///                 },
///                 child: Text('Join Call'),
///               ),
///       ),
///     );
///   }
/// }
/// ```

/// Example 2: Leave call using provider
/// 
/// ```dart
/// ElevatedButton(
///   onPressed: () async {
///     await ref.read(callStateProvider.notifier).leave();
///   },
///   child: Text('Leave Call'),
/// )
/// ```

/// Example 3: Direct controller access (advanced)
/// 
/// ```dart
/// final controller = ref.read(callControllerProvider);
/// 
/// // Check state
/// if (controller.inCall) {
///   print('Currently in call');
///   print('Session ID: ${controller.sessionId}');
///   print('Room ID: ${controller.currentRoomId}');
/// }
/// 
/// // Force cleanup (emergency)
/// controller.forceCleanup();
/// ```

/// Example 4: Watch call state changes
/// 
/// ```dart
/// class CallStatusWidget extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final callState = ref.watch(callStateProvider);
///     
///     if (callState.isJoining) {
///       return Text('Joining call...');
///     }
///     
///     if (callState.inCall) {
///       return Text('In call: ${callState.roomId}');
///     }
///     
///     if (callState.error != null) {
///       return Text('Error: ${callState.error}');
///     }
///     
///     return Text('Not in call');
///   }
/// }
/// ```
