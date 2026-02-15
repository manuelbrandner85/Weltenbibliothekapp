/// 🌐 CLOUDFLARE SIGNALING SERVICE
/// WebRTC Signaling via Cloudflare KV Storage
/// 
/// Features:
/// - HTTP-based Signaling (no WebSockets needed)
/// - SDP Offer/Answer Exchange
/// - ICE Candidate Exchange
/// - Room Management via Cloudflare KV
/// - Real-time Polling
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CloudflareSignalingService {
  // Singleton
  static final CloudflareSignalingService _instance = CloudflareSignalingService._internal();
  factory CloudflareSignalingService() => _instance;
  CloudflareSignalingService._internal();

  // Cloudflare Worker Configuration
  // ✅ PRODUCTION: Deployed and working!
  static const String _workerBaseUrl = 'https://weltenbibliothek-api-v2.brandy13062.workers.dev';
  static const String _apiToken = 'y-Xiv3kKeiybDm2CV0yLFu7TSd22co6NBw3udn5Y';
  
  // State
  String? _currentRoomId;
  String? _currentUserId;
  String? _currentUsername; // ✅ Track current username
  Timer? _pollingTimer;
  
  // ✅ CLIENT-SIDE PARTICIPANTS TRACKING (Fallback when Worker fails)
  final Map<String, Map<String, dynamic>> _localParticipants = {};
  
  // Stream Controllers
  final _offersController = StreamController<Map<String, dynamic>>.broadcast();
  final _answersController = StreamController<Map<String, dynamic>>.broadcast();
  final _candidatesController = StreamController<Map<String, dynamic>>.broadcast();
  final _participantsController = StreamController<List<Map<String, dynamic>>>.broadcast();

  Stream<Map<String, dynamic>> get offersStream => _offersController.stream;
  Stream<Map<String, dynamic>> get answersStream => _answersController.stream;
  Stream<Map<String, dynamic>> get candidatesStream => _candidatesController.stream;
  Stream<List<Map<String, dynamic>>> get participantsStream => _participantsController.stream;

  /// Initialize Room
  Future<void> initializeRoom(String roomId, String userId, String username) async {
    try {
      if (kDebugMode) {
        debugPrint('🌐 [Cloudflare Signaling] Initializing room: $roomId');
      }

      _currentRoomId = roomId;
      _currentUserId = userId;
      _currentUsername = username;

      // ✅ CLIENT-SIDE: Add self to local participants immediately
      _localParticipants[userId] = {
        'userId': userId,
        'username': username,
        'joinedAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      // ✅ Emit initial participants list with self
      _participantsController.add(_localParticipants.values.toList());
      
      if (kDebugMode) {
        debugPrint('👤 [Cloudflare Signaling] Added self to participants: $username');
      }

      // Register user in room
      await _registerUser(roomId, userId, username);

      // Start polling for signals
      _startPolling();

      if (kDebugMode) {
        debugPrint('✅ [Cloudflare Signaling] Room initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Cloudflare Signaling] Initialization failed: $e');
      }
      rethrow;
    }
  }

  /// Register User in Room
  Future<void> _registerUser(String roomId, String userId, String username) async {
    try {
      if (kDebugMode) {
        debugPrint('📝 [Cloudflare] Registering user: $username ($userId) in room: $roomId');
      }
      
      // Register user via Cloudflare Worker
      final endpoint = '$_workerBaseUrl/voice/register';
      
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiToken',
        },
        body: jsonEncode({
          'roomId': roomId,
          'userId': userId,
          'username': username,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('User-Registration Timeout (15s)');
        },
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('✅ [Cloudflare] User registered successfully');
          debugPrint('   Response: ${response.body}');
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ [Cloudflare Signaling] Registration response: ${response.statusCode}');
          debugPrint('   Body: ${response.body}');
        }
      }
    } on SocketException {
      if (kDebugMode) {
        debugPrint('❌ [Cloudflare] Registration: Keine Internetverbindung');
      }
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Cloudflare] Registration: $e');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [Cloudflare Signaling] Registration failed (non-critical): $e');
      }
      // Non-critical error, continue anyway
    }
  }

  /// Send SDP Offer
  Future<void> sendOffer(String targetUserId, Map<String, dynamic> offer) async {
    try {
      final endpoint = '$_workerBaseUrl/voice/offer';
      
      await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiToken',
        },
        body: jsonEncode({
          'roomId': _currentRoomId,
          'fromUserId': _currentUserId,
          'toUserId': targetUserId,
          'sdp': offer['sdp'],
          'type': offer['type'],
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Send-Offer Timeout (10s)');
        },
      );

      if (kDebugMode) {
        debugPrint('📤 [Cloudflare Signaling] Sent offer to $targetUserId');
      }
    } on SocketException {
      if (kDebugMode) {
        debugPrint('❌ [Cloudflare] Send offer: Keine Internetverbindung');
      }
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Cloudflare] Send offer: $e');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Cloudflare Signaling] Send offer failed: $e');
      }
    }
  }

  /// Send SDP Answer
  Future<void> sendAnswer(String targetUserId, Map<String, dynamic> answer) async {
    try {
      final endpoint = '$_workerBaseUrl/voice/answer';
      
      await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiToken',
        },
        body: jsonEncode({
          'roomId': _currentRoomId,
          'fromUserId': _currentUserId,
          'toUserId': targetUserId,
          'sdp': answer['sdp'],
          'type': answer['type'],
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Send-Answer Timeout (10s)');
        },
      );

      if (kDebugMode) {
        debugPrint('📤 [Cloudflare Signaling] Sent answer to $targetUserId');
      }
    } on SocketException {
      if (kDebugMode) {
        debugPrint('❌ [Cloudflare] Send answer: Keine Internetverbindung');
      }
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Cloudflare] Send answer: $e');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Cloudflare Signaling] Send answer failed: $e');
      }
    }
  }

  /// Send ICE Candidate
  Future<void> sendIceCandidate(String targetUserId, Map<String, dynamic> candidate) async {
    try {
      final endpoint = '$_workerBaseUrl/voice/candidate';
      
      await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiToken',
        },
        body: jsonEncode({
          'roomId': _currentRoomId,
          'fromUserId': _currentUserId,
          'toUserId': targetUserId,
          'candidate': candidate['candidate'],
          'sdpMid': candidate['sdpMid'],
          'sdpMLineIndex': candidate['sdpMLineIndex'],
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Send-ICE Timeout (10s)');
        },
      );

      if (kDebugMode) {
        debugPrint('📤 [Cloudflare Signaling] Sent ICE candidate to $targetUserId');
      }
    } on SocketException {
      if (kDebugMode) {
        debugPrint('❌ [Cloudflare] Send ICE: Keine Internetverbindung');
      }
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Cloudflare] Send ICE: $e');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Cloudflare Signaling] Send ICE candidate failed: $e');
      }
    }
  }

  /// Start Polling for Signals
  void _startPolling() {
    _pollingTimer?.cancel();
    
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_currentRoomId == null || _currentUserId == null) {
        timer.cancel();
        return;
      }

      try {
        // Poll for new signals
        await _pollSignals();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ [Cloudflare Signaling] Polling error: $e');
        }
      }
    });
  }

  /// Poll for Signals
  Future<void> _pollSignals() async {
    try {
      final endpoint = '$_workerBaseUrl/voice/poll';
      
      final response = await http.get(
        Uri.parse('$endpoint?roomId=$_currentRoomId&userId=$_currentUserId'),
        headers: {
          'Authorization': 'Bearer $_apiToken',
        },
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw TimeoutException('Poll-Signals Timeout (8s)');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (kDebugMode) {
          debugPrint('📡 [Cloudflare Poll] Response: ${response.body}');
        }
        
        // Process offers
        if (data['offers'] != null && data['offers'] is List) {
          for (final offer in data['offers']) {
            _offersController.add({
              'senderId': offer['fromUserId'],
              'sdp': offer['sdp'],
              'type': offer['type'],
            });
          }
        }

        // Process answers
        if (data['answers'] != null && data['answers'] is List) {
          for (final answer in data['answers']) {
            _answersController.add({
              'receiverId': answer['fromUserId'],
              'sdp': answer['sdp'],
              'type': answer['type'],
            });
          }
        }

        // Process ICE candidates
        if (data['candidates'] != null && data['candidates'] is List) {
          for (final candidate in data['candidates']) {
            _candidatesController.add({
              'senderId': candidate['fromUserId'],
              'candidate': candidate['candidate'],
              'sdpMid': candidate['sdpMid'],
              'sdpMLineIndex': candidate['sdpMLineIndex'],
            });
          }
        }

        // Process participants
        if (data['participants'] != null && data['participants'] is List) {
          final workerParticipants = List<Map<String, dynamic>>.from(
            data['participants'].map((p) => Map<String, dynamic>.from(p))
          );
          
          if (kDebugMode) {
            debugPrint('👥 [Cloudflare Poll] Found ${workerParticipants.length} participants from worker');
          }
          
          // ✅ MERGE: Worker participants + Local participants
          for (var participant in workerParticipants) {
            final userId = participant['userId'];
            if (userId != null) {
              _localParticipants[userId] = participant;
            }
          }
          
          // ✅ Emit merged participants list
          final mergedParticipants = _localParticipants.values.toList();
          
          if (kDebugMode) {
            debugPrint('🔀 [Cloudflare Poll] Merged participants: ${mergedParticipants.length}');
            for (var p in mergedParticipants) {
              debugPrint('   👤 ${p['username']} (${p['userId']})');
            }
          }
          
          _participantsController.add(mergedParticipants);
        } else {
          if (kDebugMode) {
            debugPrint('⚠️ [Cloudflare Poll] No participants in response - using local only');
          }
          // ✅ Emit local participants even if worker returns empty
          _participantsController.add(_localParticipants.values.toList());
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ [Cloudflare Poll] Response status: ${response.statusCode}');
        }
      }
    } on SocketException {
      // Silent fail for polling (expected when offline)
      if (kDebugMode) {
        debugPrint('⚠️ [Cloudflare Poll] Keine Internetverbindung (non-critical)');
      }
    } on TimeoutException {
      if (kDebugMode) {
        debugPrint('⚠️ [Cloudflare Poll] Timeout (non-critical)');
      }
    } catch (e) {
      // Silent fail for polling errors (expected when offline)
      if (kDebugMode) {
        debugPrint('⚠️ [Cloudflare Signaling] Poll failed (non-critical): $e');
      }
    }
  }

  /// Leave Room
  Future<void> leaveRoom() async {
    try {
      _pollingTimer?.cancel();
      _pollingTimer = null;

      if (_currentRoomId != null && _currentUserId != null) {
        // Notify server about leaving
        final endpoint = '$_workerBaseUrl/voice/leave';
        
        await http.post(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiToken',
          },
          body: jsonEncode({
            'roomId': _currentRoomId,
            'userId': _currentUserId,
          }),
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Leave-Room Timeout (10s)');
          },
        );
      }

      // ✅ Clear local participants
      _localParticipants.clear();
      
      _currentRoomId = null;
      _currentUserId = null;
      _currentUsername = null;

      if (kDebugMode) {
        debugPrint('👋 [Cloudflare Signaling] Left room and cleared participants');
      }
    } on SocketException {
      if (kDebugMode) {
        debugPrint('❌ [Cloudflare] Leave room: Keine Internetverbindung');
      }
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Cloudflare] Leave room: $e');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Cloudflare Signaling] Leave room failed: $e');
      }
    }
  }

  /// Dispose
  void dispose() {
    leaveRoom();
    _offersController.close();
    _answersController.close();
    _candidatesController.close();
    _participantsController.close();
  }
}
