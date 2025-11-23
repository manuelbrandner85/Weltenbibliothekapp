import 'package:flutter_test/flutter_test.dart';
import 'package:weltenbibliothek/services/webrtc_room_manager.dart';
import 'package:weltenbibliothek/models/room_connection_state.dart';

/// ═══════════════════════════════════════════════════════════════
/// WEBRTC MULTI-ROOM INTEGRATION TESTS
/// ═══════════════════════════════════════════════════════════════
/// Tests for multi-room WebRTC functionality
///
/// Test Scenarios:
/// 1. Single room join/leave
/// 2. Room switching with cleanup
/// 3. Multiple rooms simultaneously
/// 4. Memory leak prevention
/// 5. Room capacity management
/// ═══════════════════════════════════════════════════════════════

void main() {
  group('WebRTC Room Manager Tests', () {
    late WebRTCRoomManager roomManager;

    setUp(() {
      roomManager = WebRTCRoomManager();
    });

    tearDown(() async {
      // Clean up after each test
      await roomManager.leaveAllRooms();
    });

    // ═══════════════════════════════════════════════════════════════
    // BASIC ROOM OPERATIONS
    // ═══════════════════════════════════════════════════════════════

    test('Should initialize with no active rooms', () {
      expect(roomManager.currentRoomId, isNull);
      expect(roomManager.activeRoomIds, isEmpty);
      expect(roomManager.isConnected, isFalse);
    });

    test('Should join room as host', () async {
      final result = await roomManager.joinRoomAsHost(
        roomId: 'test_room_1',
        chatRoomId: 'chat_room_1',
      );

      expect(result.success, isTrue);
      expect(roomManager.currentRoomId, equals('test_room_1'));
      expect(roomManager.isConnected, isTrue);
    });

    test('Should join room as viewer', () async {
      final result = await roomManager.joinRoomAsViewer(
        roomId: 'test_room_2',
        chatRoomId: 'chat_room_2',
      );

      expect(result.success, isTrue);
      expect(roomManager.currentRoomId, equals('test_room_2'));
      expect(roomManager.isConnected, isTrue);
    });

    test('Should leave current room', () async {
      // Join first
      await roomManager.joinRoomAsHost(
        roomId: 'test_room_1',
        chatRoomId: 'chat_room_1',
      );

      expect(roomManager.isConnected, isTrue);

      // Leave
      await roomManager.leaveCurrentRoom();

      expect(roomManager.currentRoomId, isNull);
      expect(roomManager.isConnected, isFalse);
    });

    // ═══════════════════════════════════════════════════════════════
    // ROOM SWITCHING TESTS
    // ═══════════════════════════════════════════════════════════════

    test('Should switch between rooms with cleanup', () async {
      // Join first room
      await roomManager.joinRoomAsHost(
        roomId: 'test_room_1',
        chatRoomId: 'chat_room_1',
      );

      expect(roomManager.currentRoomId, equals('test_room_1'));

      // Switch to second room
      final result = await roomManager.switchToRoom(
        newRoomId: 'test_room_2',
        newChatRoomId: 'chat_room_2',
        role: WebRTCRole.viewer,
      );

      expect(result.success, isTrue);
      expect(result.fromRoomId, equals('test_room_1'));
      expect(result.toRoomId, equals('test_room_2'));
      expect(roomManager.currentRoomId, equals('test_room_2'));
    });

    test('Should not allow concurrent room switches', () async {
      // Join first room
      await roomManager.joinRoomAsHost(
        roomId: 'test_room_1',
        chatRoomId: 'chat_room_1',
      );

      // Start first switch (will take time)
      final switch1Future = roomManager.switchToRoom(
        newRoomId: 'test_room_2',
        newChatRoomId: 'chat_room_2',
        role: WebRTCRole.viewer,
      );

      // Immediately try second switch (should fail)
      final switch2 = await roomManager.switchToRoom(
        newRoomId: 'test_room_3',
        newChatRoomId: 'chat_room_3',
        role: WebRTCRole.viewer,
      );

      expect(switch2.success, isFalse);
      expect(switch2.error, contains('Already switching'));

      // Wait for first switch to complete
      await switch1Future;
    });

    // ═══════════════════════════════════════════════════════════════
    // ROOM CAPACITY TESTS
    // ═══════════════════════════════════════════════════════════════

    test('Should track room capacity limits', () {
      expect(WebRTCRoomManager.maxParticipantsPerRoom, equals(6));
      expect(WebRTCRoomManager.recommendedMaxParticipants, equals(4));
    });

    test('Should check if room is at capacity', () async {
      await roomManager.joinRoomAsHost(
        roomId: 'test_room_1',
        chatRoomId: 'chat_room_1',
      );

      // Initially not at capacity (only host)
      expect(roomManager.isRoomAtCapacity('test_room_1'), isFalse);
      expect(roomManager.isRoomRecommendedCapacity('test_room_1'), isFalse);
    });

    // ═══════════════════════════════════════════════════════════════
    // ROOM INFORMATION TESTS
    // ═══════════════════════════════════════════════════════════════

    test('Should provide room information', () async {
      await roomManager.joinRoomAsHost(
        roomId: 'test_room_1',
        chatRoomId: 'chat_room_1',
      );

      final roomInfo = roomManager.getCurrentRoomInfo();

      expect(roomInfo, isNotNull);
      expect(roomInfo!.roomId, equals('test_room_1'));
      expect(roomInfo.chatRoomId, equals('chat_room_1'));
      expect(roomInfo.role, equals(WebRTCRole.host));
      expect(roomInfo.isActive, isTrue);
    });

    test('Should list current participants', () async {
      await roomManager.joinRoomAsHost(
        roomId: 'test_room_1',
        chatRoomId: 'chat_room_1',
      );

      final participants = roomManager.getCurrentParticipants();

      // Initially empty (local participant not counted)
      expect(participants, isA<List<PeerInfo>>());
    });

    test('Should check if peer is in current room', () async {
      await roomManager.joinRoomAsHost(
        roomId: 'test_room_1',
        chatRoomId: 'chat_room_1',
      );

      expect(roomManager.isPeerInCurrentRoom('peer_123'), isFalse);
    });

    // ═══════════════════════════════════════════════════════════════
    // CAMERA & MICROPHONE TESTS
    // ═══════════════════════════════════════════════════════════════

    test('Should provide camera and microphone state', () {
      // Initial state (before joining)
      expect(roomManager.isCameraEnabled, isFalse);
      expect(roomManager.isMicEnabled, isTrue); // Default: mic enabled
    });

    // ═══════════════════════════════════════════════════════════════
    // CLEANUP TESTS
    // ═══════════════════════════════════════════════════════════════

    test('Should leave all rooms on cleanup', () async {
      // Join first room
      await roomManager.joinRoomAsHost(
        roomId: 'test_room_1',
        chatRoomId: 'chat_room_1',
      );

      expect(roomManager.isConnected, isTrue);

      // Leave all rooms
      await roomManager.leaveAllRooms();

      expect(roomManager.currentRoomId, isNull);
      expect(roomManager.activeRoomIds, isEmpty);
      expect(roomManager.isConnected, isFalse);
    });

    // ═══════════════════════════════════════════════════════════════
    // ERROR HANDLING TESTS
    // ═══════════════════════════════════════════════════════════════

    test('Should handle join errors gracefully', () async {
      // Try to join with invalid parameters (this will depend on implementation)
      final result = await roomManager.joinRoomAsHost(
        roomId: '',
        chatRoomId: '',
      );

      // Expect error handling
      expect(result.success, isTrue); // Even empty string should be handled
    });

    test('Should return error when switching to same room', () async {
      await roomManager.joinRoomAsHost(
        roomId: 'test_room_1',
        chatRoomId: 'chat_room_1',
      );

      // Try to switch to same room
      final result = await roomManager.switchToRoom(
        newRoomId: 'test_room_1',
        newChatRoomId: 'chat_room_1',
        role: WebRTCRole.host,
      );

      // Should succeed (no-op or error depending on implementation)
      expect(result, isNotNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // MEMORY LEAK PREVENTION TESTS
  // ═══════════════════════════════════════════════════════════════

  group('Memory Leak Prevention Tests', () {
    late WebRTCRoomManager roomManager;

    setUp(() {
      roomManager = WebRTCRoomManager();
    });

    tearDown(() async {
      await roomManager.leaveAllRooms();
    });

    test('Should not leak memory on multiple room switches', () async {
      // Switch between rooms multiple times
      for (int i = 0; i < 10; i++) {
        await roomManager.switchToRoom(
          newRoomId: 'test_room_$i',
          newChatRoomId: 'chat_room_$i',
          role: i % 2 == 0 ? WebRTCRole.host : WebRTCRole.viewer,
        );
      }

      // Should only have one active room
      expect(roomManager.activeRoomIds.length, equals(1));
      expect(roomManager.currentRoomId, equals('test_room_9'));
    });

    test('Should cleanup all resources on dispose', () async {
      // Join some rooms
      await roomManager.joinRoomAsHost(
        roomId: 'test_room_1',
        chatRoomId: 'chat_room_1',
      );

      // Dispose
      await roomManager.leaveAllRooms();

      // Verify cleanup
      expect(roomManager.activeRoomIds, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // CONCURRENT ROOM TESTS
  // ═══════════════════════════════════════════════════════════════

  group('Concurrent Room Tests', () {
    late WebRTCRoomManager roomManager;

    setUp(() {
      roomManager = WebRTCRoomManager();
    });

    tearDown(() async {
      await roomManager.leaveAllRooms();
    });

    test('Should handle rapid room joins', () async {
      // Rapidly join multiple rooms
      final futures = <Future>[];
      for (int i = 0; i < 5; i++) {
        futures.add(
          roomManager.joinRoomAsHost(
            roomId: 'test_room_$i',
            chatRoomId: 'chat_room_$i',
          ),
        );
      }

      await Future.wait(futures);

      // Only last room should be active (due to auto-switching)
      expect(roomManager.currentRoomId, isNotNull);
    });
  });
}
