/// 👥 PARTICIPANTS SERVICE
/// 
/// Production-ready service for watching voice room participants
/// 
/// Features:
/// - Stream-based participant watching
/// - Automatic retry on errors
/// - Proper exception handling
/// - Stack-trace preservation
/// - Configurable polling interval
/// - Error recovery with exponential backoff
library;

import 'dart:async';
import '../core/logging/app_logger.dart';
import '../core/exceptions/specialized_exceptions.dart';
import '../core/exceptions/exception_guard.dart';
import '../services/voice_backend_service.dart';
import '../services/webrtc_voice_service.dart' show VoiceParticipant;

/// Participants Service
/// Watches room participants with automatic error handling
class ParticipantsService {
  final VoiceBackendService backend;
  
  /// Default polling interval
  static const Duration defaultInterval = Duration(seconds: 2);
  
  /// Maximum polling interval (for exponential backoff)
  static const Duration maxInterval = Duration(seconds: 30);
  
  /// Minimum polling interval
  static const Duration minInterval = Duration(seconds: 1);

  ParticipantsService(this.backend);

  /// Watch participants in a room
  /// 
  /// Returns a stream of participant lists that updates automatically.
  /// Handles errors gracefully with exponential backoff retry logic.
  /// 
  /// Parameters:
  /// - [roomId]: Voice room ID to watch
  /// - [interval]: Polling interval (default: 2 seconds)
  /// - [maxRetries]: Maximum consecutive error retries before giving up (default: unlimited)
  /// 
  /// Throws:
  /// - [NetworkException] if network is unavailable after max retries
  /// - [BackendException] if backend returns errors after max retries
  /// - [VoiceException] for room-specific errors
  Stream<List<VoiceParticipant>> watchParticipants({
    required String roomId,
    Duration interval = defaultInterval,
    int? maxRetries,
  }) async* {
    AppLogger.info('👥 Starting participant watch',
      context: {
        'roomId': roomId,
        'interval': interval.inSeconds,
        'maxRetries': maxRetries?.toString() ?? 'unlimited',
      },
    );

    int consecutiveErrors = 0;
    Duration currentInterval = interval;
    
    try {
      while (true) {
        try {
          // Fetch participants with error handling
          final participants = await guard(
            () async {
              return await backend.fetchParticipants(roomId);
            },
            operationName: 'ParticipantsService.fetchParticipants',
            context: {'roomId': roomId},
            onError: (error, stackTrace) async {
              consecutiveErrors++;
              
              AppLogger.warn('⚠️ Failed to fetch participants',
                context: {
                  'roomId': roomId,
                  'error': error.toString(),
                  'consecutiveErrors': consecutiveErrors,
                },
              );

              // Check if max retries exceeded
              if (maxRetries != null && consecutiveErrors >= maxRetries) {
                AppLogger.error('❌ Max retries exceeded',
                  error: error,
                  context: {
                    'roomId': roomId,
                    'maxRetries': maxRetries,
                  },
                );
                throw BackendException(
                  'Failed to fetch participants after $maxRetries retries',
                  statusCode: 0,
                  cause: error,
                );
              }

              // Exponential backoff: double the interval on each error
              currentInterval = Duration(
                seconds: (currentInterval.inSeconds * 2).clamp(
                  minInterval.inSeconds,
                  maxInterval.inSeconds,
                ),
              );

              AppLogger.info('🔄 Retrying with backoff',
                context: {
                  'nextInterval': currentInterval.inSeconds,
                  'consecutiveErrors': consecutiveErrors,
                },
              );

              // Return empty list on error (graceful degradation)
              return <VoiceParticipant>[];
            },
          );

          // Success - reset error counter and interval
          if (consecutiveErrors > 0) {
            AppLogger.info('✅ Participant fetch recovered',
              context: {
                'roomId': roomId,
                'participantCount': participants.length,
                'previousErrors': consecutiveErrors,
              },
            );
            consecutiveErrors = 0;
            currentInterval = interval; // Reset to original interval
          }

          // Yield participants to stream
          yield participants;

        } catch (e) {
          // Critical error that should stop the stream
          AppLogger.error('❌ Critical error in participant watch',
            error: e,
            context: {'roomId': roomId},
          );
          rethrow;
        }

        // Wait before next poll
        await Future.delayed(currentInterval);
      }
    } finally {
      AppLogger.info('👋 Stopped participant watch',
        context: {
          'roomId': roomId,
          'totalErrors': consecutiveErrors,
        },
      );
    }
  }

  /// Watch single participant in a room
  /// 
  /// Convenience method to watch a specific participant
  Stream<VoiceParticipant?> watchParticipant({
    required String roomId,
    required String userId,
    Duration interval = defaultInterval,
  }) async* {
    AppLogger.info('👤 Starting single participant watch',
      context: {
        'roomId': roomId,
        'userId': userId,
        'interval': interval.inSeconds,
      },
    );

    await for (final participants in watchParticipants(
      roomId: roomId,
      interval: interval,
    )) {
      try {
        final participant = participants.firstWhere(
          (p) => p.userId == userId,
          orElse: () => throw VoiceException(
            'Participant not found',
            roomId: roomId,
            userId: userId,
          ),
        );
        yield participant;
      } catch (e) {
        // Participant not in room
        yield null;
      }
    }
  }

  /// Get participant count in a room
  /// 
  /// One-shot method to get current participant count
  Future<int> getParticipantCount(String roomId) async {
    return await guard(
      () async {
        final participants = await backend.fetchParticipants(roomId);
        return participants.length;
      },
      operationName: 'ParticipantsService.getParticipantCount',
      context: {'roomId': roomId},
      onError: (error, stackTrace) async {
        AppLogger.error('❌ Failed to get participant count',
          error: error,
          context: {'roomId': roomId},
        );
        return 0; // Return 0 on error
      },
    );
  }

  /// Check if user is in room
  /// 
  /// One-shot method to check if a specific user is in a room
  Future<bool> isUserInRoom({
    required String roomId,
    required String userId,
  }) async {
    return await guard(
      () async {
        final participants = await backend.fetchParticipants(roomId);
        return participants.any((p) => p.userId == userId);
      },
      operationName: 'ParticipantsService.isUserInRoom',
      context: {'roomId': roomId, 'userId': userId},
      onError: (error, stackTrace) async {
        AppLogger.error('❌ Failed to check user presence',
          error: error,
          context: {'roomId': roomId, 'userId': userId},
        );
        return false; // Return false on error
      },
    );
  }
}
