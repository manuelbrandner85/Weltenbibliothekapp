/// 📊 ACTIVE CALLS DASHBOARD
/// Real-time overview of active voice calls in a world
/// Features:
/// - Live call list with participant counts
/// - One-click admin join (observer mode)
/// - Call duration display
/// - Participant details
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/api_config.dart';
import '../../../core/storage/unified_storage_service.dart';
import '../../../screens/shared/modern_voice_chat_screen.dart';

/// Active Call Model
class ActiveCall {
  final String roomId;
  final String roomName;
  final int participantCount;
  final List<CallParticipant> participants;
  final DateTime startedAt;
  final int durationSeconds;

  ActiveCall({
    required this.roomId,
    required this.roomName,
    required this.participantCount,
    required this.participants,
    required this.startedAt,
    required this.durationSeconds,
  });

  factory ActiveCall.fromJson(Map<String, dynamic> json) {
    return ActiveCall(
      roomId: json['room_id'] as String,
      roomName: json['room_name'] as String,
      participantCount: json['participant_count'] as int,
      participants: (json['participants'] as List)
          .map((p) => CallParticipant.fromJson(p as Map<String, dynamic>))
          .toList(),
      startedAt: DateTime.parse(json['started_at'] as String),
      durationSeconds: json['duration_seconds'] as int,
    );
  }

  String get durationFormatted {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;
    
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}h';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}min';
  }
}

/// Call Participant Model
class CallParticipant {
  final String userId;
  final String username;
  final bool isMuted;
  final DateTime joinedAt;

  CallParticipant({
    required this.userId,
    required this.username,
    required this.isMuted,
    required this.joinedAt,
  });

  factory CallParticipant.fromJson(Map<String, dynamic> json) {
    return CallParticipant(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      isMuted: (json['is_muted'] as int? ?? 0) == 1,
      joinedAt: DateTime.fromMillisecondsSinceEpoch(json['joined_at'] as int),
    );
  }
}

/// Active Calls Provider
final activeCallsProvider = FutureProvider.family<List<ActiveCall>, String>((ref, world) async {
  final calls = await _getActiveVoiceCalls(world);
  return calls.map((json) => ActiveCall.fromJson(json)).toList();
});

/// Temporary local implementation until analyzer cache clears
Future<List<Map<String, dynamic>>> _getActiveVoiceCalls(String world) async {
  try {
    const token = 'y-Xiv3kKeiybDm2CV0yLFu7TSd22co6NBw3udn5Y';
    final url = Uri.parse('${ApiConfig.baseUrl}/api/admin/voice-calls/$world');
    
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['calls'] ?? []);
    }
    
    return [];
  } catch (e) {
    debugPrint('⚠️ Error fetching active calls: $e');
    return [];
  }
}

/// Active Calls Dashboard Screen
class ActiveCallsDashboard extends ConsumerStatefulWidget {
  final String world; // 'materie' or 'energie'

  const ActiveCallsDashboard({
    super.key,
    required this.world,
  });

  @override
  ConsumerState<ActiveCallsDashboard> createState() => _ActiveCallsDashboardState();
}

class _ActiveCallsDashboardState extends ConsumerState<ActiveCallsDashboard> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Auto-refresh every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      ref.invalidate(activeCallsProvider(widget.world));
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeCallsAsync = ref.watch(activeCallsProvider(widget.world));

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Row(
          children: [
            Icon(
              widget.world == 'materie' ? Icons.public : Icons.energy_savings_leaf,
              color: widget.world == 'materie' ? Colors.blue : Colors.green,
            ),
            const SizedBox(width: 12),
            Text(
              '${widget.world == 'materie' ? 'Materie' : 'Energie'} - Active Calls',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.invalidate(activeCallsProvider(widget.world));
            },
          ),
          // Auto-refresh indicator
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                children: [
                  Icon(Icons.sync, size: 16, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    'Auto 5s',
                    style: TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: activeCallsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.blue),
        ),
        error: (error, stack) => _buildErrorState(error),
        data: (calls) => calls.isEmpty
            ? _buildEmptyState()
            : _buildCallsList(calls),
      ),
    );
  }

  /// Build calls list
  Widget _buildCallsList(List<ActiveCall> calls) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(activeCallsProvider(widget.world));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: calls.length,
        itemBuilder: (context, index) {
          return _buildCallCard(calls[index]);
        },
      ),
    );
  }

  /// Build single call card
  Widget _buildCallCard(ActiveCall call) {
    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Room name + duration
            Row(
              children: [
                // Room icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.voice_chat,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Room name + duration
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        call.roomName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.timer,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            call.durationFormatted,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.people,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${call.participantCount} / 10',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Live indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: Color(0xFF2A2A2A)),
            const SizedBox(height: 12),

            // Participants list
            const Text(
              'Participants:',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...call.participants.map((participant) => 
              _buildParticipantTile(participant)
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _joinAsObserver(call),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Join as Observer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _endCall(call),
                  icon: const Icon(Icons.stop),
                  label: const Text('End Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build participant tile
  Widget _buildParticipantTile(CallParticipant participant) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[800],
            child: Text(
              participant.username[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Username
          Expanded(
            child: Text(
              participant.username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          // Mute status
          if (participant.isMuted)
            const Icon(
              Icons.mic_off,
              size: 16,
              color: Colors.red,
            ),
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.voice_chat,
            size: 80,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 24),
          Text(
            'No Active Calls',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All voice rooms are currently empty',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Failed to load active calls',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(activeCallsProvider(widget.world));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Join call as observer (admin)
  void _joinAsObserver(ActiveCall call) async {
    try {
      // Get admin username from storage
      final storage = UnifiedStorageService();
      final prefs = await SharedPreferences.getInstance();
      final adminUsername = prefs.getString('username') ?? 'Admin';
      
      // Navigate to voice chat screen as observer
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ModernVoiceChatScreen(
            roomId: call.roomId,
            roomName: call.roomId,  // ✅ ADD: roomName
            userId: 'admin_observer',  // ✅ ADD: userId
            username: '$adminUsername (Observer)',  // ✅ ADD: username
            world: widget.world,
            userName: '$adminUsername (Observer)',
            isObserverMode: true, // Admin observer mode
          ),
        ),
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Joined ${call.roomName} as observer'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to join call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// End call (admin action)
  void _endCall(ActiveCall call) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'End Call?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to end the call in "${call.roomName}"?\n\nThis will disconnect all ${call.participantCount} participants.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                // Call backend API to end the voice room
                final response = await http.post(
                  Uri.parse('${ApiConfig.voiceApiUrl}/end-room'),
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer ${ApiConfig.apiToken}',
                  },
                  body: jsonEncode({
                    'room_id': call.roomId,
                    'world': widget.world,
                    'reason': 'Admin terminated',
                  }),
                ).timeout(const Duration(seconds: 10));
                
                if (!mounted) return;
                
                if (response.statusCode == 200) {
                  // Reload calls list via provider refresh
                  ref.invalidate(activeCallsProvider(widget.world));
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Call in ${call.roomName} ended successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  throw Exception('API returned ${response.statusCode}');
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Failed to end call: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('End Call'),
          ),
        ],
      ),
    );
  }
}
