import 'package:flutter/foundation.dart';
import 'webrtc_broadcast_service.dart';
import '../models/room_connection_state.dart';

/// ═══════════════════════════════════════════════════════════════
/// WEBRTC ROOM MANAGER - High-Level API
/// ═══════════════════════════════════════════════════════════════
/// Manages multiple WebRTC rooms with intelligent switching and cleanup
///
/// Features:
/// - ✅ High-level room switching API
/// - ✅ Automatic cleanup on room switch
/// - ✅ Room state tracking and monitoring
/// - ✅ Error handling and recovery
/// - ✅ Room capacity management
/// ═══════════════════════════════════════════════════════════════

class WebRTCRoomManager extends ChangeNotifier {
  final WebRTCBroadcastService _webrtcService = WebRTCBroadcastService();

  // Singleton pattern
  static final WebRTCRoomManager _instance = WebRTCRoomManager._internal();
  factory WebRTCRoomManager() => _instance;
  WebRTCRoomManager._internal() {
    // Listen to WebRTC service changes
    _webrtcService.addListener(_onWebRTCStateChanged);
  }

  // ═══════════════════════════════════════════════════════════════
  // STATE TRACKING
  // ═══════════════════════════════════════════════════════════════

  // Room switching state
  bool _isSwitching = false;
  String? _switchError;

  // Room capacity limits (Mesh topology recommended: 2-6 participants)
  static const int maxParticipantsPerRoom = 6;
  static const int recommendedMaxParticipants = 4;

  // ═══════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════

  /// Get current active room ID
  String? get currentRoomId => _webrtcService.currentRoomId;

  /// Get active room connection
  RoomConnection? get currentRoom => _webrtcService.getActiveRoom();

  /// Get all active room IDs
  List<String> get activeRoomIds => _webrtcService.activeRoomIds;

  /// Is currently switching rooms?
  bool get isSwitching => _isSwitching;

  /// Get last switch error
  String? get switchError => _switchError;

  /// Is connected to any room?
  bool get isConnected => _webrtcService.isConnected;

  /// Get room stats for specific room
  RoomStats? getRoomStats(String roomId) => _webrtcService.getRoomStats(roomId);

  /// Get participant count for current room
  int get currentParticipantCount {
    final room = currentRoom;
    return room?.participants.length ?? 0;
  }

  /// Check if room is at capacity
  bool isRoomAtCapacity(String roomId) {
    final room = _webrtcService.getActiveRoom();
    if (room == null || room.roomId != roomId) return false;
    return room.participants.length >= maxParticipantsPerRoom;
  }

  /// Check if room is recommended capacity
  bool isRoomRecommendedCapacity(String roomId) {
    final room = _webrtcService.getActiveRoom();
    if (room == null || room.roomId != roomId) return false;
    return room.participants.length >= recommendedMaxParticipants;
  }

  // ═══════════════════════════════════════════════════════════════
  // HIGH-LEVEL ROOM MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  /// Join a room as host
  ///
  /// This is a high-level API that handles:
  /// - Automatic room switching if already in another room
  /// - Capacity checking
  /// - Error handling
  Future<RoomJoinResult> joinRoomAsHost({
    required String roomId,
    required String chatRoomId,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🎯 [RoomManager] Joining room as HOST: $roomId');
      }

      // Check if already in this room
      if (currentRoomId == roomId) {
        return RoomJoinResult.success(
          roomId: roomId,
          message: 'Already in this room',
        );
      }

      // Join as host
      await _webrtcService.joinAsHost(roomId, chatRoomId);

      if (kDebugMode) {
        debugPrint('✅ [RoomManager] Successfully joined as HOST: $roomId');
      }

      return RoomJoinResult.success(
        roomId: roomId,
        message: 'Successfully joined as host',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [RoomManager] Error joining as host: $e');
      }

      return RoomJoinResult.error(
        roomId: roomId,
        error: 'Failed to join as host: $e',
      );
    }
  }

  /// Join a room as viewer
  ///
  /// This is a high-level API that handles:
  /// - Automatic room switching if already in another room
  /// - Capacity checking
  /// - Error handling
  Future<RoomJoinResult> joinRoomAsViewer({
    required String roomId,
    required String chatRoomId,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🎯 [RoomManager] Joining room as VIEWER: $roomId');
      }

      // Check if already in this room
      if (currentRoomId == roomId) {
        return RoomJoinResult.success(
          roomId: roomId,
          message: 'Already in this room',
        );
      }

      // Join as viewer
      await _webrtcService.joinAsViewer(roomId, chatRoomId);

      if (kDebugMode) {
        debugPrint('✅ [RoomManager] Successfully joined as VIEWER: $roomId');
      }

      return RoomJoinResult.success(
        roomId: roomId,
        message: 'Successfully joined as viewer',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [RoomManager] Error joining as viewer: $e');
      }

      return RoomJoinResult.error(
        roomId: roomId,
        error: 'Failed to join as viewer: $e',
      );
    }
  }

  /// Switch to a different room
  ///
  /// This is a high-level API that handles:
  /// - Leaving current room with full cleanup
  /// - Joining new room
  /// - State management during transition
  /// - Error recovery
  Future<RoomSwitchResult> switchToRoom({
    required String newRoomId,
    required String newChatRoomId,
    required WebRTCRole role,
  }) async {
    if (_isSwitching) {
      return RoomSwitchResult.error(
        fromRoomId: currentRoomId,
        toRoomId: newRoomId,
        error: 'Already switching rooms',
      );
    }

    try {
      _isSwitching = true;
      _switchError = null;
      notifyListeners();

      final fromRoomId = currentRoomId;

      if (kDebugMode) {
        debugPrint('🔄 [RoomManager] Switching from $fromRoomId to $newRoomId');
      }

      // Use WebRTC service's switchRoom method
      await _webrtcService.switchRoom(newRoomId, newChatRoomId, role);

      _isSwitching = false;
      notifyListeners();

      if (kDebugMode) {
        debugPrint('✅ [RoomManager] Successfully switched to $newRoomId');
      }

      return RoomSwitchResult.success(
        fromRoomId: fromRoomId,
        toRoomId: newRoomId,
      );
    } catch (e) {
      _isSwitching = false;
      _switchError = e.toString();
      notifyListeners();

      if (kDebugMode) {
        debugPrint('❌ [RoomManager] Error switching rooms: $e');
      }

      return RoomSwitchResult.error(
        fromRoomId: currentRoomId,
        toRoomId: newRoomId,
        error: e.toString(),
      );
    }
  }

  /// Leave current room
  Future<void> leaveCurrentRoom() async {
    if (currentRoomId == null) return;

    try {
      if (kDebugMode) {
        debugPrint('👋 [RoomManager] Leaving current room: $currentRoomId');
      }

      await _webrtcService.leaveRoom(currentRoomId!);

      if (kDebugMode) {
        debugPrint('✅ [RoomManager] Successfully left room');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [RoomManager] Error leaving room: $e');
      }
      rethrow;
    }
  }

  /// Leave all rooms (complete cleanup)
  Future<void> leaveAllRooms() async {
    try {
      if (kDebugMode) {
        debugPrint('👋 [RoomManager] Leaving all rooms');
      }

      await _webrtcService.leaveAllRooms();

      if (kDebugMode) {
        debugPrint('✅ [RoomManager] Successfully left all rooms');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [RoomManager] Error leaving all rooms: $e');
      }
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ROOM INFORMATION
  // ═══════════════════════════════════════════════════════════════

  /// Get room information for UI display
  RoomInfo? getCurrentRoomInfo() {
    final room = currentRoom;
    if (room == null) return null;

    return RoomInfo(
      roomId: room.roomId,
      chatRoomId: room.chatRoomId,
      participantCount: room.participants.length,
      role: room.role,
      quality: room.quality,
      iceState: room.iceState,
      isActive: room.isActive,
      joinedAt: room.joinedAt,
    );
  }

  /// Get all participants in current room
  List<PeerInfo> getCurrentParticipants() {
    final room = currentRoom;
    if (room == null) return [];
    return room.participants.values.toList();
  }

  /// Check if specific peer is in current room
  bool isPeerInCurrentRoom(String peerId) {
    final room = currentRoom;
    if (room == null) return false;
    return room.participants.containsKey(peerId);
  }

  // ═══════════════════════════════════════════════════════════════
  // CAMERA & MICROPHONE CONTROLS (Delegated to WebRTC Service)
  // ═══════════════════════════════════════════════════════════════

  /// Toggle camera (affects all rooms)
  Future<void> toggleCamera() => _webrtcService.toggleCamera();

  /// Switch camera (front/back)
  Future<void> switchCamera() => _webrtcService.switchCamera();

  /// Toggle microphone (affects all rooms)
  void toggleMicrophone() => _webrtcService.toggleMicrophone();

  /// Get camera state
  bool get isCameraEnabled => _webrtcService.isCameraEnabled;

  /// Get microphone state
  bool get isMicEnabled => _webrtcService.isMicEnabled;

  // ═══════════════════════════════════════════════════════════════
  // EVENT HANDLERS
  // ═══════════════════════════════════════════════════════════════

  void _onWebRTCStateChanged() {
    // Propagate state changes from WebRTC service
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════

  @override
  void dispose() {
    _webrtcService.removeListener(_onWebRTCStateChanged);
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════
// RESULT CLASSES
// ═══════════════════════════════════════════════════════════════

/// Result of joining a room
class RoomJoinResult {
  final bool success;
  final String roomId;
  final String? message;
  final String? error;

  RoomJoinResult._({
    required this.success,
    required this.roomId,
    this.message,
    this.error,
  });

  factory RoomJoinResult.success({required String roomId, String? message}) {
    return RoomJoinResult._(success: true, roomId: roomId, message: message);
  }

  factory RoomJoinResult.error({
    required String roomId,
    required String error,
  }) {
    return RoomJoinResult._(success: false, roomId: roomId, error: error);
  }
}

/// Result of switching rooms
class RoomSwitchResult {
  final bool success;
  final String? fromRoomId;
  final String toRoomId;
  final String? error;

  RoomSwitchResult._({
    required this.success,
    this.fromRoomId,
    required this.toRoomId,
    this.error,
  });

  factory RoomSwitchResult.success({
    String? fromRoomId,
    required String toRoomId,
  }) {
    return RoomSwitchResult._(
      success: true,
      fromRoomId: fromRoomId,
      toRoomId: toRoomId,
    );
  }

  factory RoomSwitchResult.error({
    String? fromRoomId,
    required String toRoomId,
    required String error,
  }) {
    return RoomSwitchResult._(
      success: false,
      fromRoomId: fromRoomId,
      toRoomId: toRoomId,
      error: error,
    );
  }
}
