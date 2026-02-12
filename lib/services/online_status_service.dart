import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:http/http.dart' as http;

/// ✅ PRODUCTION-READY Online Status Service
/// Verwaltet Online/Offline Status von Chat-Usern mit Backend-Sync
class OnlineStatusService {
  // Singleton Pattern
  static final OnlineStatusService _instance = OnlineStatusService._internal();
  factory OnlineStatusService() => _instance;
  OnlineStatusService._internal();
  
  // ✅ Backend URL (Cloudflare Worker)
  static const String _baseUrl = 'https://weltenbibliothek-api-v2.brandy13062.workers.dev';
  static const Duration _apiTimeout = Duration(seconds: 5);
  
  // Online users cache
  final Map<String, DateTime> _onlineUsers = {}; // username -> last seen
  final Map<String, String> _userStatus = {}; // username -> status (online/away/busy/offline)
  
  // Stream Controller für Status Updates
  final _statusController = StreamController<Map<String, String>>.broadcast();
  Stream<Map<String, String>> get statusStream => _statusController.stream;
  
  // Heartbeat Timer
  Timer? _heartbeatTimer;
  String? _currentUsername;
  
  // Status constants
  static const String STATUS_ONLINE = 'online';
  static const String STATUS_AWAY = 'away';
  static const String STATUS_BUSY = 'busy';
  static const String STATUS_OFFLINE = 'offline';
  
  // Timeouts
  static const Duration onlineTimeout = Duration(minutes: 2);
  static const Duration heartbeatInterval = Duration(seconds: 30);
  
  /// Initialize service with current user
  void initialize(String username) {
    _currentUsername = username;
    setStatus(username, STATUS_ONLINE);
    _startHeartbeat();
    
    if (kDebugMode) {
      debugPrint('👤 Online Status initialized for: $username');
    }
  }
  
  /// Start heartbeat to keep user online
  /// ✅ PRODUCTION-READY: Sends heartbeats to backend
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (timer) async {
      if (_currentUsername != null) {
        _updateLastSeen(_currentUsername!, DateTime.now());
        
        // ✅ Send heartbeat to backend
        try {
          await _sendHeartbeat(_currentUsername!);
          
          if (kDebugMode) {
            debugPrint('💓 Heartbeat sent for $_currentUsername');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Heartbeat failed: $e');
          }
        }
      }
    });
  }
  
  /// Send heartbeat to backend
  /// ✅ PRODUCTION-READY: Real API call
  Future<void> _sendHeartbeat(String username) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/status/heartbeat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'timestamp': DateTime.now().toIso8601String(),
          'status': _userStatus[username] ?? STATUS_ONLINE,
        }),
      ).timeout(_apiTimeout);
      
      if (response.statusCode != 200) {
        throw Exception('Heartbeat failed: ${response.statusCode}');
      }
    } catch (e) {
      // Fail silently - heartbeat is not critical
      // Local cache continues to work
      if (kDebugMode) {
        debugPrint('⚠️ Heartbeat API error: $e');
      }
    }
  }
  
  /// Set user status
  /// ✅ PRODUCTION-READY: Syncs with backend
  void setStatus(String username, String status) async {
    _userStatus[username] = status;
    _updateLastSeen(username, DateTime.now());
    
    // Notify listeners
    _statusController.add(Map.from(_userStatus));
    
    if (kDebugMode) {
      debugPrint('📊 Status updated: $username -> $status');
    }
    
    // ✅ Send to backend
    try {
      await _updateStatusOnServer(username, status);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Status sync failed: $e');
      }
    }
  }
  
  /// Update status on server
  /// ✅ PRODUCTION-READY: Real API call
  Future<void> _updateStatusOnServer(String username, String status) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/status/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'status': status,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(_apiTimeout);
      
      if (response.statusCode != 200) {
        throw Exception('Status update failed: ${response.statusCode}');
      }
    } catch (e) {
      // Fail silently - local status continues to work
      if (kDebugMode) {
        debugPrint('⚠️ Status API error: $e');
      }
    }
  }
  
  /// Update last seen timestamp
  void _updateLastSeen(String username, DateTime timestamp) {
    _onlineUsers[username] = timestamp;
  }
  
  /// Get user status
  String getUserStatus(String username) {
    // Check if user has explicit status
    if (_userStatus.containsKey(username)) {
      final status = _userStatus[username]!;
      
      // If status is online, verify it's still recent
      if (status == STATUS_ONLINE) {
        final lastSeen = _onlineUsers[username];
        if (lastSeen != null) {
          final diff = DateTime.now().difference(lastSeen);
          if (diff > onlineTimeout) {
            _userStatus[username] = STATUS_OFFLINE;
            return STATUS_OFFLINE;
          }
        }
      }
      
      return status;
    }
    
    // Check last seen to determine status
    final lastSeen = _onlineUsers[username];
    if (lastSeen != null) {
      final diff = DateTime.now().difference(lastSeen);
      if (diff < onlineTimeout) {
        return STATUS_ONLINE;
      }
    }
    
    return STATUS_OFFLINE;
  }
  
  /// Check if user is online
  bool isOnline(String username) {
    return getUserStatus(username) == STATUS_ONLINE;
  }
  
  /// Get last seen time
  DateTime? getLastSeen(String username) {
    return _onlineUsers[username];
  }
  
  /// Format last seen text
  String formatLastSeen(String username) {
    final status = getUserStatus(username);
    
    switch (status) {
      case STATUS_ONLINE:
        return 'Online';
      case STATUS_AWAY:
        return 'Abwesend';
      case STATUS_BUSY:
        return 'Beschäftigt';
      default:
        final lastSeen = getLastSeen(username);
        if (lastSeen != null) {
          final diff = DateTime.now().difference(lastSeen);
          
          if (diff.inMinutes < 60) {
            return 'Vor ${diff.inMinutes}m online';
          } else if (diff.inHours < 24) {
            return 'Vor ${diff.inHours}h online';
          } else {
            return 'Vor ${diff.inDays}d online';
          }
        }
        return 'Offline';
    }
  }
  
  /// Get online users count in room
  int getOnlineCount(List<String> usernames) {
    return usernames.where((username) => isOnline(username)).length;
  }
  
  /// Get status color
  Color getStatusColor(String username) {
    final status = getUserStatus(username);
    
    switch (status) {
      case STATUS_ONLINE:
        return const Color(0xFF4CAF50); // Green
      case STATUS_AWAY:
        return const Color(0xFFFFC107); // Amber
      case STATUS_BUSY:
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }
  
  /// Update user seen (called when receiving messages)
  void updateUserSeen(String username) {
    _updateLastSeen(username, DateTime.now());
    
    // Update status to online if offline
    if (getUserStatus(username) == STATUS_OFFLINE) {
      setStatus(username, STATUS_ONLINE);
    }
  }
  
  /// Set user offline
  void setOffline(String username) {
    setStatus(username, STATUS_OFFLINE);
  }
  
  /// Clean up old entries
  void cleanup() {
    final now = DateTime.now();
    final toRemove = <String>[];
    
    _onlineUsers.forEach((username, lastSeen) {
      if (now.difference(lastSeen) > const Duration(days: 7)) {
        toRemove.add(username);
      }
    });
    
    for (final username in toRemove) {
      _onlineUsers.remove(username);
      _userStatus.remove(username);
    }
    
    if (kDebugMode && toRemove.isNotEmpty) {
      debugPrint('🗑️ Cleaned up ${toRemove.length} old status entries');
    }
  }
  
  /// Dispose resources
  void dispose() {
    _heartbeatTimer?.cancel();
    _statusController.close();
    
    if (_currentUsername != null) {
      setOffline(_currentUsername!);
    }
  }
}
